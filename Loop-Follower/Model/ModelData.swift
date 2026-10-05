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
    
    let hourOfHistory : Int = -6
    
    private var tempBasal : [TempBasal] = []

    init() {
        // Start the first load asynchronously and yield first, so no @Published
        // change happens while the @StateObject is being created during a view update.
        Task { @MainActor in
            await Task.yield()
            _ = self.load()
        }
        Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { timer in
            Task { @MainActor in
                print("running timer event \(Date.now)")
                if let nextRun = self.load() {
                    print("rescheduling timer at: \(nextRun)")
                    timer.fireDate = nextRun
                } else {
                    print("invalidating timer")
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

    func loadSgv() async -> [Entry] {
        let date = Calendar.current.date(byAdding: .hour, value: -48, to: .now)!.timeIntervalSince1970 * 1000
        let queryItems = [
            URLQueryItem(name: "find[date][$gte]", value: date.description),
            URLQueryItem(name: "count", value: "2000")
        ]

        do {
            return try await NightScoutAPI.get(
                path: "/api/v1/entries/sgv.json",
                queryItems: queryItems
            )
        } catch {
            print("loadSgv: Error with fetching sgv: \(error)")
            return []
        }
    }

    func loadMbg() async -> [MbgEntry] {
        let date = Calendar.current.date(byAdding: .hour, value: hourOfHistory, to: .now)!.timeIntervalSince1970 * 1000
        let queryItems = [
            URLQueryItem(name: "find[date][$gte]", value: date.description),
            URLQueryItem(name: "count", value: "1000")
        ]

        do {
            return try await NightScoutAPI.get(
                path: "/api/v1/entries/mbg.json",
                queryItems: queryItems
            )
        } catch {
            print("loadMbg: Error with fetching mbg: \(error)")
            return []
        }
    }

    fileprivate func getStartTime() -> String {
        return formatter.string(from: Calendar.current.date(byAdding: .hour, value: hourOfHistory, to: .now)!)
    }

    fileprivate func getYesterday() -> String {
        return formatter.string(from: Calendar.current.date(byAdding: .hour, value: -48, to: .now)!)
    }
    
    func loadInsulin() async -> [CorrectionBolus] {

        do {
            return try await NightScoutAPI.get(
                path: "/api/v1/treatments.json",
                queryItems: [
                    URLQueryItem(name: "find[eventType]", value: "/Bolus|SMB|Correction%20Bolus/"),
                    URLQueryItem(name: "find[created_at][$gte]", value: getYesterday())
                ]
            )
        } catch {
            print("loadInsulin: Error fetching treatments: \(error)")
            return []
        }
    }
    
    func loadCarbs() async -> [CarbCorrection] {
        do {
            return try await NightScoutAPI.get(
                path: "/api/v1/treatments.json",
                queryItems: [
                    URLQueryItem(name: "find[eventType]", value: "Carb Correction"),
                    URLQueryItem(name: "find[created_at][$gte]", value: getYesterday())
                ]
            )
        } catch {
            print("loadCarbs: Error fetching treatments: \(error)")
            return []
        }
    }
    
    func loadTempBasal() async -> [TempBasal] {
        do {
            return try await NightScoutAPI.get(
                path: "/api/v1/treatments.json",
                queryItems: [
                    URLQueryItem(name: "find[eventType]", value: "Temp Basal"),
                    URLQueryItem(name: "find[created_at][$gte]", value: getStartTime())
                ]
            )
        } catch {
            print("loadTempBasal: Error fetching treatments: \(error)")
            return []
        }
    }
    
    func loadDeviceStatus() async -> LoopData? {
        do {
            let loopData: [LoopData] = try await NightScoutAPI.get(
                path: "/api/v1/devicestatus.json",
                queryItems: [
                    URLQueryItem(name: "find[created_at][$gte]", value: getStartTime()),
                    URLQueryItem(name: "count", value: "1")
                ]
            )
            return loopData.first
        } catch {
            print("loadDeviceStatus: Error with fetching devicestatus: \(error)")
            return nil
        }
    }
    
    func loadProfile() async -> Profiles? {
        do {
            let profiles: [Profiles] = try await NightScoutAPI.get(
                path: "/api/v1/profile.json",
                queryItems: []
            )
            return profiles.first
        } catch {
            print("loadProfile: Error with fetching profile: \(error)")
            return nil
        }
    }

    func loadEventType(eventType : String, days: Int) async -> Date? {
        let daysBackInTime : Date = Calendar.current.date(byAdding: .day, value: days, to: .now)!

        let queryItems = [
            URLQueryItem(name: "find[eventType]", value: eventType),
            URLQueryItem(name: "find[created_at][$gte]", value: formatter.string(from: daysBackInTime)),
            URLQueryItem(name: "count", value: "1")
        ]

        do {
            let treatments: [ChangeEvent] = try await NightScoutAPI.get(
                path: "/api/v1/treatments.json",
                queryItems: queryItems
            )
            if let first = treatments.first {
                print("loadEventType: treatment of type \"\(eventType)\" found with \(first.date)")
                return first.date
            }
        } catch {
            print("loadEventType: Error fetching treatments: \(String(describing: error))")
        }
        print("loadEventType: no treatment of type \"\(eventType)\" found")
        return nil
    }

    @objc func load() -> Date? {
        currentDate = Date.now

        if NightScoutAPI.baseUrl.isEmpty {
            // do nothing when not configured
            return nil
        }

        Task { @MainActor in
            let previousLastEntry = self.lastEntry
            let entries = await self.loadSgv()
            self.entries = filterEntries(entries)
            self.lastEntry = self.entries.first

            // only reload the widget when a new CGM value arrived, to save the widget's reload budget
            if let lastEntry = self.lastEntry, lastEntry.id != previousLastEntry?.id {
                print("reload Widget")
                WidgetCenter.shared.reloadTimelines(ofKind: "Loop_Follower_Widget")
            }
            let startOfTir = Calendar.current.date(byAdding: .hour, value: -24, to: self.currentDate)!
            self.timeInRange = calcTimeInRange(self.entries.filter { $0.date > startOfTir }, min: 70, max: 180)
        }
        Task { @MainActor in
            self.mgbs = await self.loadMbg()
            self.currentLoopData = await self.loadDeviceStatus()

            async let insulin = self.loadInsulin()
            async let carbs = self.loadCarbs()
            async let tempBasal = self.loadTempBasal()
            async let siteChanged = self.loadEventType(eventType: "Site Change", days: -5)
            async let sensorChanged = self.loadEventType(eventType: "/Sensor Start|Sensor Change/", days: -14)

            self.insulin = await insulin
            self.carbs = await carbs
            self.tempBasal = await tempBasal
            self.siteChanged = await siteChanged
            self.sensorChanged = await sensorChanged

            let profile = await self.loadProfile()
            if let profile = profile {
                let currentDate = Date.now
                let startDate = Calendar.current.date(byAdding: .hour, value: self.hourOfHistory, to: currentDate)!

                let endDate: Date
                if self.currentLoopData != nil {
                    endDate = Calendar.current.date(byAdding: .hour, value: 3, to: currentDate)!
                } else {
                    endDate = currentDate
                }

                self.profile = profile.store[profile.defaultProfile]!

                self.loopSettings = profile.loopSettings

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

        if let lastEntry = self.lastEntry {
            
            let calendar = Calendar.current
            let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: lastEntry.date)
            let nowComponents = calendar.dateComponents([.hour, .minute, .second], from: currentDate)
            let difference = calendar.dateComponents([.second], from: timeComponents, to: nowComponents).second!

            if difference > 300 {
                return Calendar.current.date(
                    byAdding: .second,
                    value: 10,
                    to: currentDate
                )!
            }
            
            var nextRun = Calendar.current.date(
                byAdding: .minute,
                value: 1,
                to: lastEntry.date
            )!

            while nextRun < currentDate {
                nextRun = Calendar.current.date(
                    byAdding: .minute,
                    value: 1,
                    to: nextRun
                )!
            }

            return Calendar.current.date(
                byAdding: .second,
                value: 10,
                to: nextRun)!
        }

        return Calendar.current.date(
            byAdding: .second,
            value: 10,
            to: currentDate
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

fileprivate func iso8601() -> ISO8601DateFormatter {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    
    return formatter
}

fileprivate let formatter : ISO8601DateFormatter = iso8601()

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
                type: "scheduled",
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
            type: "scheduled",
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

    tempBasal = tempBasal.filter({ $0.endDate > startDate && $0.startDate < endDate })

    if let first = tempBasal.first {
        if first.startDate < startDate {
            // replace with start of chart
            let newFirst = TempBasal(
                id: UUID().uuidString,
                duration: 0,
                rate: first.rate,
                created_at: formatter.string(from: startDate),
                type: "scheduled",
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
                type: "scheduled",
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
                        type: "scheduled",
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
                    type: "scheduled",
                    endDate: sb.endDate
                )
            )
        }
    }
    
    return tempBasalPoints.filter({ $0.startDate < endDate && $0.endDate > startDate })
}

func filterEntries(_ entries : [Entry]) -> [Entry] {
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

enum AlertType {
    case veryHigh, high, low, veryLow, data, none
}

struct Alert {
    let type: AlertType
}

struct AlertSettings {
    let veryLowThreshold : Int
    
    let lowThreshold : Int
    let lowTime : TimeInterval?
    
    let highThreshold : Int
    let highTime : TimeInterval?

    let veryHighThreshold : Int
}

struct AlertState {
    var veryLow : Entry?
    var low : Entry?
    var high : Entry?
    var veryHigh : Entry?
}

func processSgvForAlerts(_ entries: [Entry], alertSettings : AlertSettings) -> AlertType {
    
    if let first = entries.first {
        // on the first entry we decide which threshold to check
        if first.sgv < alertSettings.veryLowThreshold {
            return .veryLow
        } else if first.sgv < alertSettings.lowThreshold {
            if let firstAboveThresholdIndex = entries.firstIndex(where: { $0.sgv >= alertSettings.lowThreshold }) {
                let lastBelowThreshold = entries[firstAboveThresholdIndex - 1]
                let diff = lastBelowThreshold.date.distance(to: first.date).rounded(.toNearestOrAwayFromZero)
                if let lowTime = alertSettings.lowTime {
                    if diff > lowTime {
                        return .low
                    }
                } else {
                    return .none
                }
            } else if let lastBelowThreshold = entries.last {
                let diff = lastBelowThreshold.date.distance(to: first.date).rounded(.toNearestOrAwayFromZero)
                if let lowTime = alertSettings.lowTime {
                    if diff > lowTime {
                        return .low
                    }
                } else {
                    return .none
                }
            }
        } else if first.sgv > alertSettings.veryHighThreshold {
            return .veryHigh
        } else if first.sgv > alertSettings.highThreshold {
            if let firstBelowThresholdIndex = entries.firstIndex(where: { $0.sgv <= alertSettings.highThreshold }) {
                let lastAboveThreshold = entries[firstBelowThresholdIndex - 1]
                let diff = lastAboveThreshold.date.distance(to: first.date).rounded(.toNearestOrAwayFromZero)
                if let highTime = alertSettings.highTime {
                    if diff > highTime {
                        return .high
                    }
                } else {
                    return .none
                }
            } else if let lastAboveThreshold = entries.last {
                let diff = lastAboveThreshold.date.distance(to: first.date).rounded(.toNearestOrAwayFromZero)
                if let highTime = alertSettings.highTime {
                    if diff > highTime {
                        return .high
                    }
                } else {
                    return .none
                }
            }
        }
    } else {
        return .data
    }

    return .none
}

///
/// calculates the timeInRange in promill
///
func calcTimeInRange(_ entries: [Entry], min: Int, max: Int) -> Int {

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
               DecodingError.Context(codingPath: decoder.codingPath,
                                     debugDescription: "Invalid date"))
   }
}
