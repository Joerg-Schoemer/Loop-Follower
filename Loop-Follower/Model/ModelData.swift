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
        _ = load()
        Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { timer in
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

    func loadSgv(baseUrl : String, token : String, completionHandler: @escaping ([Entry]) -> ()) {
        guard var components = URLComponents(string: "\(baseUrl)/api/v1/entries/sgv.json")
        else { return }

        let date = Calendar.current.date(byAdding: .hour, value: -48, to: .now)!.timeIntervalSince1970 * 1000
        components.queryItems = []
        if !token.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "token", value: token))
        }
        components.queryItems?.append(URLQueryItem(name: "find[date][$gte]", value: date.description))
        components.queryItems?.append(URLQueryItem(name: "count", value: "2000"))
        if let url = components.url {
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

    func loadMbg(baseUrl : String, token : String, completionHandler: @escaping ([MbgEntry]) -> ()) {
        guard var components = URLComponents(string: "\(baseUrl)/api/v1/entries/mbg.json")
        else { return }

        let date = Calendar.current.date(byAdding: .hour, value: hourOfHistory, to: .now)!.timeIntervalSince1970 * 1000
        components.queryItems = []
        if !token.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "token", value: token))
        }
        components.queryItems?.append(URLQueryItem(name: "find[date][$gte]", value: date.description))
        components.queryItems?.append(URLQueryItem(name: "count", value: "1000"))
        if let url = components.url {
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
                        let entries = try! JSONDecoder().decode([MbgEntry].self, from: data)
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

    fileprivate func getStartTime() -> String {
        return formatter.string(from: Calendar.current.date(byAdding: .hour, value: hourOfHistory, to: .now)!)
    }

    fileprivate func getYesterday() -> String {
        return formatter.string(from: Calendar.current.date(byAdding: .hour, value: -48, to: .now)!)
    }
    
    func loadInsulin(baseUrl : String, token: String, completionHandler: @escaping ([CorrectionBolus]) -> ()) {
        guard var components = URLComponents(string: "\(baseUrl)/api/v1/treatments.json")
        else { return }

        components.queryItems = []
        if !token.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "token", value: token))
        }
        components.queryItems?.append(URLQueryItem(name: "find[eventType]", value: "Correction Bolus"))
        components.queryItems?.append(URLQueryItem(name: "find[created_at][$gte]", value: getYesterday()))

        if let url = components.url {
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
        guard var components = URLComponents(string: "\(baseUrl)/api/v1/treatments.json")
        else { return }
       
        components.queryItems = []

        if !token.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "token", value: token))
        }
        
        components.queryItems?.append(URLQueryItem(name: "find[eventType]", value: "Carb Correction"))
        components.queryItems?.append(URLQueryItem(name: "find[created_at][$gte]", value: getYesterday()))
        
        if let url = components.url {
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
        guard var components = URLComponents(string: "\(baseUrl)/api/v1/treatments.json")
        else { return }
        
        components.queryItems = []
        if !token.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "token", value: token))
        }
        components.queryItems?.append(URLQueryItem(name: "find[eventType]", value: "Temp Basal"))
        components.queryItems?.append(URLQueryItem(name: "find[created_at][$gte]", value: getStartTime()))

        if let url = components.url {
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
    
    func loadDeviceStatus(baseUrl:String, token: String, completionHandler: @escaping (LoopData?) -> ()) {
        guard var components = URLComponents(string: "\(baseUrl)/api/v1/devicestatus.json")
        else { return }
        
        components.queryItems = []

        if !token.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "token", value: token))
        }
        components.queryItems?.append(URLQueryItem(name: "count", value: "1"))
        components.queryItems?.append(URLQueryItem(name: "find[created_at][$gte]", value: getStartTime()))

        if let url = components.url {
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
                        completionHandler(loopData.first)
                    }
                } else {
                    print("no data")
                    return
                }
            }).resume()
        }
    }
    
    func loadProfile(baseUrl : String,token : String, completionHandler: @escaping (Profiles?) -> ()) {
        guard var components = URLComponents(string: "\(baseUrl)/api/v1/profile.json")
        else { return }
        
        components.queryItems = []
        if !token.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "token", value: token))
        }

        if let url = components.url {
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
                    print("data: ")
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
        guard var components = URLComponents(string: "\(baseUrl)/api/v1/treatments.json")
        else { return }
        
        let daysBackInTime : Date = Calendar.current.date(byAdding: .day, value: -5, to: Date())!

        components.queryItems = []
        if !token.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "token", value: token))
        }
        components.queryItems?.append(URLQueryItem(name: "find[eventType]", value: "Site Change"))
        components.queryItems?.append(URLQueryItem(name: "find[created_at][$gte]", value: formatter.string(from: daysBackInTime)))
        components.queryItems?.append(URLQueryItem(name: "count", value: "1"))
        
        if let url = components.url {
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
        guard var components = URLComponents(string: "\(baseUrl)/api/v1/treatments.json")
        else { return }

        let daysBackInTime : Date = Calendar.current.date(byAdding: .day, value: -14, to: .now)!

        components.queryItems = []
        if !token.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "token", value: token))
        }
        components.queryItems?.append(URLQueryItem(name: "find[eventType]", value: "Sensor Start"))
        components.queryItems?.append(URLQueryItem(name: "find[created_at][$gte]", value: formatter.string(from: daysBackInTime)))
        components.queryItems?.append(URLQueryItem(name: "count", value: "1"))

        if let url = components.url {
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
        let store = UserDefaults(suiteName: "group.loop.follower")!
        let baseUrl : String = store.object(forKey: SettingsStore.Keys.url) as? String ?? ""
        let token : String = store.object(forKey: SettingsStore.Keys.token) as? String ?? ""
        currentDate = Date.now

        if baseUrl.isEmpty {
            // do nothing when not configured
            return nil
        }
        
        loadSgv(
            baseUrl: baseUrl,
            token: token,
            completionHandler: { entries in
                self.entries = entries
                self.lastEntry = entries.first

                let startOfTir = Calendar.current.date(byAdding: .hour, value: -24, to: self.currentDate)!
                self.timeInRange = calcTimeInRange(entries.filter { $0.date > startOfTir }, min: 70, max: 180)
                let alert = processSgvForAlerts(
                    entries,
                    alertSettings: AlertSettings(
                        veryLowThreshold: 55,
                        lowThreshold: 70,
                        lowTime: 290.0,
                        highThreshold: 180,
                        highTime: 3570.0,
                        veryHighThreshold: 260
                    )
                )
                print("alert=\(alert)")
            }
        )
        loadMbg(baseUrl: baseUrl, token: token, completionHandler: { entries in
            self.mgbs = entries
        })
        loadDeviceStatus(
            baseUrl: baseUrl,
            token: token,
            completionHandler: { loopData in
                self.currentLoopData = loopData
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

fileprivate func iso8601() -> ISO8601DateFormatter {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withFullDate, .withFullTime, .withTimeZone]
    
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
