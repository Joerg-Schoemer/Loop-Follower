//
//  ModelData.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 13.07.22.
//

import Foundation
import Combine

class ModelData : ObservableObject {

    @Published var entries : [Entry] = []
    
    @Published var lastEntry : Entry?
    
    @Published var loopData : [LoopData] = []
    
    @Published var currentLoopData : LoopData?
    
    @Published var insulin : [CorrectionBolus] = []

    @Published var tempBasal : [TempBasal] = []

    @Published var scheduledBasal : [TempBasal] = []

    @Published var carbs : [CarbCorrection] = []

    @Published var profile : Profile?
    
    @Published var loopSettings : LoopSettings?
    
    @Published var siteChanged : Date?

    @Published var sensorChanged : Date?
    
    @Published var currentDate : Date?
    
    let hourOfHistory : Int = -6;

    func loadSgv(baseUrl : String, token : String, completionHandler: @escaping ([Entry]) -> ()) {
        let date = Calendar.current.date(byAdding: .hour, value: hourOfHistory, to: Date.now)!.timeIntervalSince1970 * 1000

        if let url = URL(string: "\(baseUrl)/api/v1/entries/sgv.json?token=\(token)&find[date][$gte]=\(date)&count=288") {
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
        if let url = URL(string: "\(baseUrl)/api/v1/treatments.json?token=\(token)&find[eventType]=Site%20Change&count=1") {
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
        if let url = URL(string: "\(baseUrl)/api/v1/treatments.json?token=\(token)&find[eventType]=Sensor%20Change&count=1") {
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

    init() {
        load()
        Timer.scheduledTimer(timeInterval: 20, target: self, selector: #selector(load), userInfo: nil, repeats: true)
    }
    
    init(test: Bool) {
        self.entries = initLoad("sgvData.json")
        self.lastEntry = entries.first

        self.loopData = initLoad("deviceData.json")
        self.currentLoopData = loopData.first
        
        self.insulin = initLoad("treatments.json")
        
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
        
        self.currentDate = Calendar.current.date(byAdding: .minute, value: 5, to: entries.first!.date)
    }

    @objc func load() {
        let baseUrl : String = UserDefaults.standard.object(forKey: SettingsStore.Keys.url) as? String ?? ""
        let token : String = UserDefaults.standard.object(forKey: SettingsStore.Keys.token) as? String ?? ""

        if baseUrl.isEmpty || token.isEmpty {
            // do nothing when not configured
            return
        }

        loadSgv(
            baseUrl: baseUrl,
            token: token,
            completionHandler: { entries in
                self.entries = entries
                self.lastEntry = entries.first
            }
        )
        loadDeviceStatus(
            baseUrl: baseUrl,
            token: token,
            completionHandler: { loopData in
                self.loopData = loopData
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
                let date = Calendar.current.date(byAdding: .hour, value: self.hourOfHistory, to: Date.now)!

                self.profile = profiles!.store[profiles!.defaultProfile]!
                self.loopSettings = profiles!.loopSettings
                self.scheduledBasal = calculateTempBasal(basals: self.profile!.basal, startDate: date)
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
