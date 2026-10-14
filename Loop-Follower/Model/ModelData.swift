//
//  ModelData.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 13.07.22.
//

import Foundation
import Combine
import WidgetKit

@MainActor
public class ModelData : ObservableObject {

    @Published var entries : [Entry] = []
    
    @Published var mgbs : [MbgEntry] = []
    
    @Published var lastEntry : Entry?
    
    @Published var currentLoopData : LoopData?
    
    @Published var insulin : [CorrectionBolus] = []

    @Published var scheduledBasal : [TempBasal] = []
    
    @Published var resultingBasal : [TempBasal] = []

    @Published var carbs : [CarbCorrection] = []

    @Published var profile : Profile?
    
    @Published var loopSettings : LoopSettings?
    
    @Published var siteChanged : Date?

    @Published var sensorChanged : Date?
    
    @Published var currentDate : Date = Date.now
    
    @Published var totalBasal : Double?
    
    @Published var timeInRange : Int?
    
    private var tempBasal : [TempBasal] = []
    
    private var isReloading = false

    init() {
        Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { timer in
            Task { @MainActor in
                if let nextRun = self.load() {
                    print("rescheduling timer at: \(nextRun)")
                    timer.fireDate = nextRun
                } else {
                    timer.invalidate()
                }
            }
        }
    }
    
    init(test: Bool) {
        self.entries = initLoad("sgvData.json")
        self.lastEntry = entries.first

        let loopData: [LoopData] = initLoad("deviceData.json")
        self.currentLoopData = loopData.first
        
        self.insulin = initLoad("CorrectionBolus.json")
        self.carbs = initLoad("CarbCorrection.json")

        self.profile = Profile(
            basal: [
                Basal(value: 0.05, timeAsSeconds: 0),
                Basal(value: 0.15, timeAsSeconds: 10800),
                Basal(value: 0.05, timeAsSeconds: 14400),
                Basal(value: 0.10, timeAsSeconds: 61200),
                Basal(value: 0.05, timeAsSeconds: 64800),
            ],
            target_low: [
                Target(value: 110, timeAsSeconds: 0),
            ],
            target_high: [
                Target(value: 125, timeAsSeconds: 0),
            ],
            sens: [
                Target(value: 270, timeAsSeconds: 0),
                Target(value: 213, timeAsSeconds: 18000),
                Target(value: 270, timeAsSeconds: 75600),
            ],
            carbratio: [
                Target(value: 24, timeAsSeconds: 0),
                Target(value: 16, timeAsSeconds: 21600),
                Target(value: 24, timeAsSeconds: 32400),
            ]
        )
        self.scheduledBasal = calculateTempBasal(basals: (self.profile?.basal)!, startDate: (entries.last?.date)!, endDate: (lastEntry?.date)!)
        
        self.currentDate = Calendar.current.date(byAdding: .minute, value: 5, to: (lastEntry?.date)!)!
        self.siteChanged = Calendar.current.date(byAdding: .hour, value: -26, to: Date.now)!
        self.sensorChanged = Calendar.current.date(byAdding: .hour, value: -96, to: Date.now)!
    }

    @MainActor
    func reloadData() async {
        guard !isReloading else { return }
        isReloading = true
        defer { isReloading = false }

        let previousLastEntry = self.lastEntry
        self.currentDate = Date.now
        
        async let unfilteredEntries = NightScoutAPI.loadSgv()

        async let deviceStatus = NightScoutAPI.loadDeviceStatus()
        async let tempBasal = NightScoutAPI.loadTempBasal()
        async let siteChanged = NightScoutAPI.ageOf(eventType: "Site Change", days: -5)
        async let sensorStart = NightScoutAPI.ageOf(eventType: "/Sensor Start|Sensor Change/", days: -14)
        async let insulin = NightScoutAPI.loadInsulin()
        async let carbs = NightScoutAPI.loadCarbs()
        async let mbgs = NightScoutAPI.loadMbg()
        async let profiles = NightScoutAPI.loadProfile()

        self.siteChanged = await siteChanged
        self.sensorChanged = await sensorStart
        self.mgbs = await mbgs
        self.insulin = await insulin
        self.carbs = await carbs

        if let entries = await unfilteredEntries {
            self.entries = filterEntries(entries)
            self.lastEntry = self.entries.first
            
            Task {
                // check the latest value against the critical alarm thresholds
                AlarmController.shared.evaluate(self.entries)
            }
            
            Task {
                let startOfTir = Calendar.current.date(byAdding: .hour, value: -24, to: self.currentDate)!
                async let tir = calcTimeInRange(self.entries.filter { enrtry in enrtry.date > startOfTir }, min: 70, max: 180)
                self.timeInRange = await tir
            }
            
            // only reload the widget when a new CGM value arrived, to save the widget's reload budget
            if let le = self.lastEntry, let ple = previousLastEntry, le.id != ple.id {
                WidgetCenter.shared.reloadTimelines(ofKind: "Loop_Follower_Widget")
            }
        }

        self.currentLoopData = await deviceStatus
        self.tempBasal = await tempBasal

        // Keep a Live Activity in sync with the freshest CGM reading.
        if let lastEntry = self.lastEntry {
            let delta = self.entries.count > 1
                ? self.entries[0].sgv - self.entries[1].sgv
                : nil
            LiveBGActivityManager.shared.update(
                sgv: lastEntry.sgv,
                delta: delta,
                direction: lastEntry.direction,
                date: lastEntry.date,
                iob: self.currentLoopData?.iob.value,
                cob: self.currentLoopData?.cob.value,
                basal: nil
            )
        } else {
            LiveBGActivityManager.shared.stopIfStale(maxAge: 10 * 60)
        }

        if let profile = await profiles {
            let startDate = Calendar.current.date(byAdding: .hour, value: NightScoutAPI.hourOfHistory, to: self.currentDate)!

            let endDate: Date
            if self.currentLoopData != nil {
                endDate = Calendar.current.date(byAdding: .hour, value: 3, to: self.currentDate)!
            } else {
                endDate = self.currentDate
            }

            self.profile = profile.store[profile.defaultProfile]!
            self.loopSettings = profile.loopSettings

            Task {
                self.scheduledBasal = calculateTempBasal(
                    basals: self.profile!.basal,
                    startDate: startDate,
                    endDate: endDate
                )
                self.resultingBasal = calculateResultingBasal(
                    tempBasal: self.tempBasal,
                    scheduledBasal: self.scheduledBasal,
                    startDate: startDate,
                    endDate: endDate
                ).sorted(by: {$0.startDate < $1.startDate})
            }
        }
    }

    func refresh() async {
        // Run the load in an unstructured @MainActor task so that cancellation
        // of the calling (refreshable) task does not cancel the underlying
        // network requests (which would surface as NSURLErrorCancelled / -999).
        await withUnsafeContinuation { (continuation: UnsafeContinuation<Void, Never>) in
            Task { @MainActor in
                await reloadData()
                continuation.resume()
            }
        }
    }

    @objc func load() -> Date? {
        if NightScoutAPI.baseUrl.isEmpty {
            // do nothing when not configured
            return nil
        }

        Task { @MainActor in
            await reloadData()
        }

        let now = Date.now

        if let lastEntry = self.lastEntry {
            
            let calendar = Calendar.current
            let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: lastEntry.date)
            let nowComponents = calendar.dateComponents([.hour, .minute, .second], from: now)
            let difference = calendar.dateComponents([.second], from: timeComponents, to: nowComponents).second!

            // letzter Wert länger als 5 Minuten her
            if difference > 300 {
                // dann in 10 Sekunden nochmal laden.
                return Calendar.current.date(
                    byAdding: .second,
                    value: 10,
                    to: now
                )!
            }
            
            // vom letzten Wert an eine Minute weiter
            var nextRun = Calendar.current.date(
                byAdding: .minute,
                value: 1,
                to: lastEntry.date
            )!

            // wenn der nächste Lauf noch kleiner als jetzt ist, dann eine Minute dazu bis wir in der Zukunft sind.
            while nextRun < now {
                nextRun = Calendar.current.date(
                    byAdding: .minute,
                    value: 1,
                    to: nextRun
                )!
            }

            // am Ende noch einen 10 Sekunden Puffer dazu.
            return Calendar.current.date(
                byAdding: .second,
                value: 10,
                to: nextRun)!
        }

        // noch keinen Wert geladen, wir versuchen es in 10 Sekunden nocheinmal.
        return Calendar.current.date(
            byAdding: .second,
            value: 10,
            to: now
        )!
    }
    
    var cn : Measurement<UnitMass> {
        if self.profile == nil || self.lastEntry == nil || self.currentLoopData == nil {
            return Measurement(value: 0, unit: UnitMass.grams)
        }
        
        let entry = self.lastEntry!
        let loopData = self.currentLoopData!
        let now : Date = entry.date
        let start = Calendar.current.startOfDay(for: now)
        let currentSens = profile!.sens.last(where: {(start + $0.timeAsSeconds) < now})!
        let currentCarbratio = profile!.carbratio.last(where: {(start + $0.timeAsSeconds) < now})!
        var currentTarget = profile!.target_low.last(where: {(start + $0.timeAsSeconds) < now})!
        
        var factor = 1.0;
        if let override = loopData.override {
            if (override.active) {
                if let multiplier = override.multiplier {
                    factor = multiplier
                }
                if let targetRange = override.currentCorrectionRange {
                    currentTarget = Target(value: targetRange.minValue, timeAsSeconds: 0)
                }
            }
        }
        
        let grams : Double = Double(((Double(entry.sgv) - max(loopData.iob.value, 0) * currentSens.value / factor) - currentTarget.value) / -currentSens.value * currentCarbratio.value)
        let rec_grams = grams - loopData.cob.value

        return Measurement(
            value: max(ceil(rec_grams), 0),
            unit: UnitMass.grams
        )
    }
}

func initLoad<T: Decodable>(_ filename: String) -> T {
    let data: Data

    guard let file = Bundle.main.url(forResource: filename, withExtension: nil)
    else {
        fatalError("Couldn't find \(filename) in main bundle.")
    }

    do {
        data = try Data(contentsOf: file)
    } catch {
        fatalError("Couldn't load \(filename) from main bundle:\n\(error)")
    }

    do {
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    } catch {
        fatalError("Couldn't parse \(filename) as \(T.self):\n\(error)")
    }
}

func convertBasalToTempBasal(
    _ basals: [Basal],
    _ startOfDay: Date
) -> [TempBasal] {
    var tempBasal : [TempBasal] = []
    for i in 0..<(basals.count - 1) {
        let currentBasal = basals[i]
        let nextBasal = basals[i + 1]
        let startDate = startOfDay + currentBasal.timeAsSeconds
        tempBasal.append(
            TempBasal(
                id: UUID().uuidString,
                duration: (nextBasal.timeAsSeconds - currentBasal.timeAsSeconds) / 60,
                rate: currentBasal.value,
                created_at: formatter.string(from: startDate),
                type: .scheduled,
                endDate: startDate + (nextBasal.timeAsSeconds - currentBasal.timeAsSeconds)
            )
        )
    }
    let lastBasal = basals.last!
    let startDate = startOfDay + lastBasal.timeAsSeconds
    tempBasal.append(
        TempBasal(
            id: UUID().uuidString,
            duration: (86400 - lastBasal.timeAsSeconds) / 60,
            rate: lastBasal.value,
            created_at: formatter.string(from: startDate),
            type: .scheduled,
            endDate: startDate + (86400 - lastBasal.timeAsSeconds)
        )
    )
    
    return tempBasal
}

func calculateTempBasal(
    basals : [Basal],
    startDate: Date,
    endDate: Date
) -> [TempBasal] {

    var tempBasal : [TempBasal] = []

    // first day
    let startOfDayOne = Calendar.current.startOfDay(for: startDate)
    tempBasal.append(contentsOf: convertBasalToTempBasal(basals, startOfDayOne))

    // second day
    let startOfDayTwo = Calendar.current.date(byAdding: .day, value: 1, to: startOfDayOne)!
    tempBasal.append(contentsOf: convertBasalToTempBasal(basals, startOfDayTwo))

    tempBasal = tempBasal.filter { basal in basal.endDate > startDate && basal.startDate < endDate }

    if let first = tempBasal.first {
        if first.startDate < startDate {
            // replace with start of chart
            let newFirst = TempBasal(
                id: UUID().uuidString,
                duration: 0,
                rate: first.rate,
                created_at: formatter.string(from: startDate),
                type: .scheduled,
                endDate: first.endDate
            )
            tempBasal.remove(at: 0)
            tempBasal.insert(newFirst, at: 0)
        }
    }
    
    if let last = tempBasal.last {
        if last.endDate > endDate {
            // replace with end of chart
            let newLast = TempBasal(
                id: UUID().uuidString,
                duration: 0,
                rate: last.rate,
                created_at: formatter.string(from: last.startDate),
                type: .scheduled,
                endDate: endDate
            )
            tempBasal.remove(at: tempBasal.count - 1)
            tempBasal.append(newLast)
        }
    }

    return tempBasal
}

func calculateResultingBasal(
    tempBasal: [TempBasal],
    scheduledBasal: [TempBasal],
    startDate: Date,
    endDate: Date
) -> [TempBasal] {
    
    // Without any temp basals there is nothing to combine, the result is
    // simply the scheduled basal. Avoid force-unwrapping on empty arrays.
    guard !tempBasal.isEmpty else {
        return scheduledBasal
    }
    
    var tempBaselWithEndDate = zip(tempBasal.dropFirst(), tempBasal).map { (a: TempBasal, b: TempBasal) in
        return TempBasal(
            id: a.id,
            duration: a.duration,
            rate: a.rate,
            created_at: a.created_at,
            endDate: min(a.startDate + a.duration * 60, b.startDate)
        )
        
    }
    let first = tempBasal.first!
    tempBaselWithEndDate.insert(
        TempBasal(
            id: first.id,
            duration: first.duration,
            rate: first.rate,
            created_at: first.created_at,
            endDate: first.startDate + first.duration * 60
        ),
        at: 0
    )

    var tempBasalPoints : [TempBasal] = []
    for sb in scheduledBasal {
        
        let tempWithinCurrentSchedule = tempBaselWithEndDate.filter({
            (sb.startDate ... sb.endDate).contains($0.endDate)
            || (sb.startDate ..< sb.endDate).contains($0.startDate)
        }).sorted(by: {$0.startDate < $1.startDate})
        
        if tempWithinCurrentSchedule.isEmpty {
            // keine temp-basal einträge während scheduled, kann so übernommen werden
            tempBasalPoints.append(sb)
            continue
        }
        
        var lastTempEndDate : Date = sb.startDate
        for tb in tempWithinCurrentSchedule {
            if tb.startDate < sb.startDate {
                // startet ausserhalb
                // wird am Anfang gekürzt
                tempBasalPoints.append(
                    TempBasal(
                        id: UUID().uuidString,
                        duration: 0,
                        rate: tb.rate,
                        created_at: formatter.string(from: sb.startDate),
                        endDate: tb.endDate
                    )
                )
                lastTempEndDate = tb.endDate
                continue
            }
            
            if lastTempEndDate < tb.startDate {
                // Lücke muss gefüllt werden mit scheduled rate
                tempBasalPoints.append(
                    TempBasal(
                        id: UUID().uuidString,
                        duration: 0,
                        rate: sb.rate,
                        created_at: formatter.string(from: lastTempEndDate),
                        type: .scheduled,
                        endDate: tb.startDate
                    )
                )
            }
            
            if tb.endDate < sb.endDate {
                // liegt komplett drin
                tempBasalPoints.append(tb)
                lastTempEndDate = tb.endDate
            } else {
                // endet ausserhalb
                // wird am Ende gekürzt
                tempBasalPoints.append(
                    TempBasal(
                        id: UUID().uuidString,
                        duration: 0,
                        rate: tb.rate,
                        created_at: formatter.string(from: tb.startDate),
                        endDate: sb.endDate
                    )
                )
                lastTempEndDate = sb.endDate
            }
        }
        if lastTempEndDate < sb.endDate {
            // der Rest muss mit dem scheduled aufgefüllt werden.
            tempBasalPoints.append(
                TempBasal(
                    id: UUID().uuidString,
                    duration: 0,
                    rate: sb.rate,
                    created_at: formatter.string(from: lastTempEndDate),
                    type: .scheduled,
                    endDate: sb.endDate
                )
            )
        }
    }
    
    return tempBasalPoints.filter({ $0.startDate < endDate && $0.endDate > startDate })
}

func filterEntries(_ entries : [Entry]) -> [Entry] {
    if entries.isEmpty {
        return entries
    }
    
    let interval : TimeInterval = 100
    var clearedEntries = zip(entries, entries.dropFirst()).filter { (e1, e2) in
        return abs(e1.date - e2.date) > interval
    }.map { (e1, e2) in
        return e1
    }
    
    let last = entries.last!
    let clearedLast = clearedEntries.last!
    if (clearedLast.id != last.id && abs(clearedLast.date - last.date) > interval) {
        clearedEntries.append(last)
    }
    
    return clearedEntries
}

///
/// calculates the timeInRange in promill
///
func calcTimeInRange(_ entries: [Entry], min: Int, max: Int) async -> Int {
    if entries.isEmpty {
        return 0;
    }

    let aboveOrBelowCount = entries.filter { e in
        e.sgv > max || e.sgv < min
    }.count

    return (entries.count - aboveOrBelowCount) * 1000 / entries.count
}

extension Date {
    static func - (lhs: Date, rhs: Date) -> TimeInterval {
        return lhs.timeIntervalSinceReferenceDate - rhs.timeIntervalSinceReferenceDate
    }
}

extension Formatter {
   static var customISO8601DateFormatter: ISO8601DateFormatter = {
      let formatter = ISO8601DateFormatter()
      formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
      return formatter
   }()
}

extension JSONDecoder.DateDecodingStrategy {
    static var iso8601WithFractionalSeconds = custom { decoder in
        let dateStr = try decoder.singleValueContainer().decode(String.self)
        let customIsoFormatter = Formatter.customISO8601DateFormatter
        if let date = customIsoFormatter.date(from: dateStr) {
            return date
        }
        throw DecodingError.dataCorrupted(
            DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Invalid date"
            )
        )
    }
}

fileprivate func iso8601() -> ISO8601DateFormatter {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    
    return formatter
}

fileprivate let formatter : ISO8601DateFormatter = iso8601()

