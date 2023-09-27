//
//  ModelData.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 13.07.22.
//

import Foundation
import Combine

public class ModelData : ObservableObject {

    @Published var entries : [Entry] = []
    
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
    
    @Published var currentDate : Date?
    
    private let hourOfHistory : Int = -6;
    
    private var tempBasal : [TempBasal] = []

    init() {
        _ = load()
        Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { timer in
            print("running timer event...")
            if let nextRun = self.load() {
                print("rescheduling timer at: \(nextRun)")
                timer.fireDate = nextRun
            } else {
                print("invalidating timer")
                timer.invalidate()
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
        
        self.currentDate = Calendar.current.date(byAdding: .minute, value: 5, to: (lastEntry?.date)!)
    }

    func loadSgv(baseUrl : String, token : String, completionHandler: @escaping ([Entry]) -> ()) {
        let date = Calendar.current.date(byAdding: .hour, value: hourOfHistory, to: Date.now)!.timeIntervalSince1970 * 1000

        if let url = URL(string: "\(baseUrl)/api/v1/entries/sgv.json?token=\(token)&find[date][$gte]=\(date)&count=1000") {
            URLSession.shared.dataTask(
                with: url,
                completionHandler: { data, response, error in
                    if let error = error {
                        print("Error with fetching sgv: \(error)")
                        return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse,
                          (200...299).contains(httpResponse.statusCode) else {
                        print("Error with the response, unexpected status code: \(String(describing: response))")
                        return
                    }
                    
                    if let data = data {
                        let entries = try! JSONDecoder().decode([Entry].self, from: data)
                        DispatchQueue.main.async {
                            completionHandler(entries)
                        }
                    } else {
                        print("no data")
                        return
                    }
                }
            ).resume()
        } else {
            completionHandler([])
        }
    }
    
    func loadInsulin(baseUrl : String, token: String, completionHandler: @escaping ([CorrectionBolus]) -> ()) {
        let format = ISO8601DateFormatter()
        format.formatOptions = [.withFullDate, .withFullTime, .withTimeZone]
        
        let startMillis = format.string(from: Calendar.current.date(byAdding: .hour, value: hourOfHistory, to: Date())!)

        if let url = URL(string: "\(baseUrl)/api/v1/treatments.json?token=\(token)&find[eventType]=Correction%20Bolus&find[timestamp][$gte]=\(startMillis)") {
            URLSession.shared.dataTask(with: url, completionHandler: { data, response, error in

                if let error = error {
                    print("Error fetching treatments: \(error)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    print("Error response, unexpected status code: \(String(describing: response))")
                    return
                }

                if let data = data {
                    let treatmentData = try! JSONDecoder().decode([CorrectionBolus].self, from: data)
                    DispatchQueue.main.async {
                        completionHandler(treatmentData)
                    }
                } else {
                    print("no data")
                    return
                }
            }).resume()
        }
    }
    
    func loadCarbs(baseUrl : String, token : String, completionHandler: @escaping ([CarbCorrection]) -> ()) {
        let format = ISO8601DateFormatter()
        format.formatOptions = [.withFullDate, .withFullTime, .withTimeZone]
        
        let startMillis = format.string(from: Calendar.current.date(byAdding: .hour, value: hourOfHistory, to: Date())!)

        if let url = URL(string: "\(baseUrl)/api/v1/treatments.json?token=\(token)&find[eventType]=Carb%20Correction&find[timestamp][$gte]=\(startMillis)") {
            URLSession.shared.dataTask(with: url, completionHandler: { data, response, error in

                if let error = error {
                    print("Error fetching treatments: \(error)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    print("Error response, unexpected status code: \(String(describing: response))")
                    return
                }

                if let data = data {
                    let treatmentData = try! JSONDecoder().decode([CarbCorrection].self, from: data)
                    DispatchQueue.main.async {
                        completionHandler(treatmentData)
                    }
                } else {
                    print("no data")
                    return
                }
            }).resume()
        }
    }
    
    func loadTempBasal(baseUrl : String, token : String, completionHandler: @escaping ([TempBasal]) -> ()) {
        let format = ISO8601DateFormatter()
        format.formatOptions = [.withFullDate, .withFullTime, .withTimeZone]
        
        let startMillis = format.string(from: Calendar.current.date(byAdding: .hour, value: hourOfHistory, to: Date())!)

        if let url = URL(string: "\(baseUrl)/api/v1/treatments.json?token=\(token)&find[eventType]=Temp%20Basal&find[timestamp][$gte]=\(startMillis)") {
            URLSession.shared.dataTask(with: url, completionHandler: { data, response, error in

                if let error = error {
                    print("Error fetching treatments: \(error)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    print("Error response, unexpected status code: \(String(describing: response))")
                    return
                }

                if let data = data {
                    let treatmentData = try! JSONDecoder().decode([TempBasal].self, from: data)
                    DispatchQueue.main.async {
                        completionHandler(treatmentData)
                    }
                } else {
                    print("no data")
                    return
                }
            }).resume()
        }
    }
    
    func loadDeviceStatus(baseUrl:String, token: String, completionHandler: @escaping ([LoopData]) -> ()) {
        if let url = URL(string: "\(baseUrl)/api/v1/devicestatus.json?token=\(token)&count=1") {
            URLSession.shared.dataTask(with: url, completionHandler: { data, response, error in

                if let error = error {
                    print("Error with fetching devicestatus: \(error)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    print("Error with the response, unexpected status code: \(String(describing: response))")
                    return
                }

                if let data = data {
                    let loopData = try! JSONDecoder().decode([LoopData].self, from: data)
                    DispatchQueue.main.async {
                        completionHandler(loopData)
                    }
                } else {
                    print("no data")
                    return
                }
            }).resume()
        }
    }
    
    func loadProfile(baseUrl : String,token : String, completionHandler: @escaping (Profiles?) -> ()) {
        if let url = URL(string: "\(baseUrl)/api/v1/profile.json?token=\(token)") {
            URLSession.shared.dataTask(with: url, completionHandler: { data, response, error in

                if let error = error {
                    print("Error with fetching devicestatus: \(error)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    print("Error with the response, unexpected status code: \(String(describing: response))")
                    return
                }

                if let data = data {
                    let profiles = try! JSONDecoder().decode([Profiles].self, from: data)
                    let activeProfile = profiles.first!
                    DispatchQueue.main.async {
                        completionHandler(activeProfile)
                    }
                } else {
                    print("no data")
                    return
                }
            }).resume()
        }
    }
    
    func loadSiteChange(baseUrl:String, token : String, completionHandler: @escaping (Date?) -> ()) {
        if let url = URL(string: "\(baseUrl)/api/v1/treatments.json?token=\(token)&find[eventType]=Site Change&count=1&find[created_at][$gte]=0") {
            URLSession.shared.dataTask(with: url, completionHandler: { data, response, error in

                if let error = error {
                    print("Error fetching treatments: \(error)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    print("Error response, unexpected status code: \(String(describing: response))")
                    return
                }
                
                if httpResponse.statusCode == 304 {
                    return
                }

                if let data = data {
                    let treatmentData = (try! JSONDecoder().decode([ChangeEvent].self, from: data)).first
                    
                    if treatmentData == nil {
                        return
                    }

                    DispatchQueue.main.async {
                        completionHandler(treatmentData!.date)
                    }
                } else {
                    print("no data")
                    completionHandler(nil)
                }
            }).resume()
        }
    }

    func loadSensorChange(baseUrl : String, token : String, completionHandler: @escaping (Date?) -> ()) {
        if let url = URL(string: "\(baseUrl)/api/v1/treatments.json?token=\(token)&find[eventType]=Sensor Change&count=1&find[created_at][$gte]=0") {
            URLSession.shared.dataTask(with: url, completionHandler: { data, response, error in

                if let error = error {
                    print("Error fetching treatments: \(error)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    print("Error response, unexpected status code: \(String(describing: response))")
                    return
                }
                
                if httpResponse.statusCode == 304 {
                    return
                }

                if let data = data {
                    let treatmentData = (try! JSONDecoder().decode([ChangeEvent].self, from: data)).first
                    
                    if treatmentData == nil {
                        return
                    }
                    
                    DispatchQueue.main.async {
                        completionHandler(treatmentData!.date)
                    }
                } else {
                    print("no data")
                    completionHandler(nil)
                }
            }).resume()
        }
    }

    @objc func load() -> Date? {
        let baseUrl : String = UserDefaults.standard.object(forKey: SettingsStore.Keys.url) as? String ?? ""
        let token : String = UserDefaults.standard.object(forKey: SettingsStore.Keys.token) as? String ?? ""

        if baseUrl.isEmpty || token.isEmpty {
            // do nothing when not configured
            return nil
        }
        
        loadSgv(
            baseUrl: baseUrl,
            token: token,
            completionHandler: { entries in
                self.entries = entries
                self.lastEntry = entries.first
                
                let alert = processSgvForAlerts(
                    entries,
                    alertSettings: AlertSettings(
                        veryLowThreshold: 55,
                        lowThreshold: 70,
                        lowTime: 300.0,
                        highThreshold: 180,
                        highTime: 3600.0,
                        veryHighThreshold: 260
                    )
                )
                
                print(alert)
            }
        )
        loadDeviceStatus(
            baseUrl: baseUrl,
            token: token,
            completionHandler: { loopData in
                let loopData: [LoopData] = loopData
                self.currentLoopData = loopData.first
            }
        )
        loadInsulin(
            baseUrl: baseUrl,
            token: token,
            completionHandler: { correctionBolus in
                self.insulin = correctionBolus
            }
        )
        loadCarbs(
            baseUrl: baseUrl,
            token: token,
            completionHandler:  { carbCorrections in
                self.carbs = carbCorrections
            }
        )
        loadTempBasal(
            baseUrl: baseUrl,
            token: token,
            completionHandler:  { tempBasal in
                self.tempBasal = tempBasal
            }
        )
        loadProfile(
            baseUrl: baseUrl,
            token: token,
            completionHandler: { profiles in
                let startDate = Calendar.current.date(byAdding: .hour, value: self.hourOfHistory, to: Date.now)!
                let endDate = Calendar.current.date(byAdding: .hour, value: 3, to: Date.now)!

                self.profile = profiles!.store[profiles!.defaultProfile]!
                self.loopSettings = profiles!.loopSettings
                
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
        )
        loadSiteChange(
            baseUrl: baseUrl,
            token: token,
            completionHandler: { date in
                self.siteChanged = date
            }
        )
        loadSensorChange(
            baseUrl: baseUrl,
            token: token,
            completionHandler: { date in
                self.sensorChanged = date
            }
        )
        currentDate = Date.now
        
        var nextRun : Date? = nil
        if let lastEntry = self.lastEntry {
            nextRun = Calendar.current.date(
                byAdding: .minute,
                value: 5,
                to: lastEntry.date
            )!
            nextRun = Calendar.current.date(
                byAdding: .second,
                value: 10,
                to: nextRun!)!
            let oneMinuteInFuture = Calendar.current.date(byAdding: .minute, value: 1, to: currentDate!)!
            while nextRun! > oneMinuteInFuture {
                nextRun = Calendar.current.date(byAdding: .minute, value: -1, to: nextRun!)
            }
        }

        if nextRun == nil || nextRun! < currentDate! {
            nextRun = Calendar.current.date(
                byAdding: .second,
                value: 10,
                to: currentDate!
            )!
        }

        return nextRun
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
        if (loopData.override.active) {
            if let multiplier = loopData.override.multiplier {
                factor = multiplier
            }
            if let targetRange = loopData.override.currentCorrectionRange {
                currentTarget = Target(value: targetRange.minValue, timeAsSeconds: 0)
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
    _ startOfDay: Date,
    _ offset: Double
) -> [TempBasal] {
    var tempBasal : [TempBasal] = []
    for i in 0..<(basals.count - 1) {
        let currentBasal = basals[i]
        let nextBasal = basals[i + 1]
        tempBasal.append(
            TempBasal(
                id: UUID().uuidString,
                duration: (nextBasal.timeAsSeconds - currentBasal.timeAsSeconds) / 60,
                rate: currentBasal.value,
                timestamp: ISO8601DateFormatter().string(from: startOfDay + currentBasal.timeAsSeconds + offset),
                type: "scheduled"
            )
        )
    }
    let lastBasal = basals.last!
    tempBasal.append(
        TempBasal(
            id: UUID().uuidString,
            duration: (86400 - lastBasal.timeAsSeconds) / 60,
            rate: lastBasal.value,
            timestamp: ISO8601DateFormatter().string(from: startOfDay + lastBasal.timeAsSeconds + offset),
            type: "scheduled"
        )
    )
    
    return tempBasal
}

func calculateTempBasal(
    basals : [Basal],
    startDate: Date,
    endDate: Date
) -> [TempBasal] {

    let startOfDay = Calendar.current.startOfDay(for: startDate)
    var tempBasal : [TempBasal] = []

    // first day
    tempBasal.append(contentsOf: convertBasalToTempBasal(basals, startOfDay, 0))
    // second day
    tempBasal.append(contentsOf: convertBasalToTempBasal(basals, startOfDay, 86400))

    tempBasal = tempBasal.filter({ $0.endDate > startDate && $0.startDate < endDate })

    if let first = tempBasal.first {
        if first.startDate < startDate {
            // replace with start of chart
            let newFirst = TempBasal(
                id: UUID().uuidString,
                duration: Double(Calendar.current.dateComponents([.second], from: startDate, to: first.endDate).second!) / 60,
                rate: first.rate,
                timestamp: ISO8601DateFormatter().string(from: startDate),
                type: "scheduled"
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
                duration: Double(Calendar.current.dateComponents([.second], from: last.startDate, to: endDate).second!) / 60,
                rate: last.rate,
                timestamp: last.timestamp,
                type: "scheduled"
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
    
    let formatter = ISO8601DateFormatter()
    
    var tempBasalPoints : [TempBasal] = []
    for sb in scheduledBasal {
        
        let tempWithinCurrentSchedule = tempBasal.filter({
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
                        duration: Double(Calendar.current.dateComponents([.second], from: sb.startDate, to: tb.endDate).second!) / 60,
                        rate: tb.rate,
                        timestamp: formatter.string(from: sb.startDate)
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
                        duration: (tb.startDate - lastTempEndDate) / 60.0,
                        rate: sb.rate,
                        timestamp: formatter.string(from: lastTempEndDate),
                        type: "scheduled"
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
                        duration: Double(Calendar.current.dateComponents([.second], from: tb.startDate, to: sb.endDate).second!) / 60,
                        rate: tb.rate,
                        timestamp: formatter.string(from: tb.startDate)
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
                    duration: Double(Calendar.current.dateComponents([.second], from: lastTempEndDate, to: sb.endDate).second!) / 60,
                    rate: sb.rate,
                    timestamp: formatter.string(from: lastTempEndDate),
                    type: "scheduled"
                )
            )
        }
    }
    
    return tempBasalPoints.filter({ $0.startDate < endDate && $0.endDate > startDate })
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
        // on first we decide which threshold to check
        if first.sgv < alertSettings.veryLowThreshold {
            return .veryLow
        } else if first.sgv < alertSettings.lowThreshold {
            if let firstAboveThresholdIndex = entries.firstIndex(where: { $0.sgv >= alertSettings.lowThreshold }) {
                let lastBelowThreshold = entries[firstAboveThresholdIndex - 1]
                let diff = lastBelowThreshold.date.distance(to: first.date)
                if let lowTime = alertSettings.lowTime {
                    if diff > lowTime {
                        return .low
                    }
                } else {
                    return .none
                }
            } else {
                return .low
            }
        } else if first.sgv > alertSettings.veryHighThreshold {
            return .veryHigh
        } else if first.sgv > alertSettings.highThreshold {
            if let firstBelowThresholdIndex = entries.firstIndex(where: { $0.sgv <= alertSettings.highThreshold }) {
                let lastAboveThreshold = entries[firstBelowThresholdIndex - 1]
                let diff = lastAboveThreshold.date.distance(to: first.date)
                print("diff=\(diff),\nlastAboveThreshold=\(lastAboveThreshold),\nfirst=\(first)")
                if let highTime = alertSettings.highTime {
                    if diff > highTime {
                        return .high
                    }
                } else {
                    return .none
                }
            } else {
                return .high
            }
        }
    } else {
        return .data
    }

    return .none
}
