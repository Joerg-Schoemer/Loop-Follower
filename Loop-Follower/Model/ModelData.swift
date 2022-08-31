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

    @Published var carbs : [CarbCorrection] = []

    @Published var profile : Profile?
    
    func loadSvg(completionHandler: @escaping ([Entry]) -> ()) {
        let baseUrl : String = UserDefaults.standard.object(forKey: SettingsStore.Keys.url) as? String ?? ""
        let token : String = UserDefaults.standard.object(forKey: SettingsStore.Keys.token) as? String ?? ""

        if baseUrl.isEmpty || token.isEmpty {
            completionHandler([])
            return
        }
        
        let date = Calendar.current.date(byAdding: .hour, value: -7, to: Date())!.timeIntervalSince1970 * 1000

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
    
    func loadInsulin(completionHandler: @escaping ([CorrectionBolus]) -> ()) {
        let baseUrl : String = UserDefaults.standard.object(forKey: SettingsStore.Keys.url) as? String ?? ""
        let token : String = UserDefaults.standard.object(forKey: SettingsStore.Keys.token) as? String ?? ""

        if baseUrl.isEmpty || token.isEmpty {
            completionHandler([])
            return
        }

        let format = ISO8601DateFormatter()
        format.formatOptions = [.withFullDate, .withFullTime, .withTimeZone]
        
        let startMillis = format.string(from: Calendar.current.date(byAdding: .hour, value: -7, to: Date())!)

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
    
    func loadCarbs(completionHandler: @escaping ([CarbCorrection]) -> ()) {
        let baseUrl : String = UserDefaults.standard.object(forKey: SettingsStore.Keys.url) as? String ?? ""
        let token : String = UserDefaults.standard.object(forKey: SettingsStore.Keys.token) as? String ?? ""

        if baseUrl.isEmpty || token.isEmpty {
            completionHandler([])
            return
        }

        let format = ISO8601DateFormatter()
        format.formatOptions = [.withFullDate, .withFullTime, .withTimeZone]
        
        let startMillis = format.string(from: Calendar.current.date(byAdding: .hour, value: -7, to: Date())!)

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
    
    func loadTempBasal(completionHandler: @escaping ([TempBasal]) -> ()) {
        let baseUrl : String = UserDefaults.standard.object(forKey: SettingsStore.Keys.url) as? String ?? ""
        let token : String = UserDefaults.standard.object(forKey: SettingsStore.Keys.token) as? String ?? ""

        if baseUrl.isEmpty || token.isEmpty {
            completionHandler([])
            return
        }

        let format = ISO8601DateFormatter()
        format.formatOptions = [.withFullDate, .withFullTime, .withTimeZone]
        
        let startMillis = format.string(from: Calendar.current.date(byAdding: .hour, value: -7, to: Date())!)

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
    
    func loadScheduledBasal(completionHandler: @escaping ([Treatment]) -> ()) {
        let baseUrl : String = UserDefaults.standard.object(forKey: SettingsStore.Keys.url) as? String ?? ""
        let token : String = UserDefaults.standard.object(forKey: SettingsStore.Keys.token) as? String ?? ""

        if baseUrl.isEmpty || token.isEmpty {
            completionHandler([])
            return
        }

        let format = ISO8601DateFormatter()
        format.formatOptions = [.withFullDate, .withFullTime, .withTimeZone]
        
        let startMillis = format.string(from: Calendar.current.date(byAdding: .hour, value: -7, to: Date())!)

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
                    let treatmentData = try! JSONDecoder().decode([Treatment].self, from: data)
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

    func loadDeviceStatus(completionHandler: @escaping ([LoopData]) -> ()) {
        let baseUrl : String = UserDefaults.standard.object(forKey: SettingsStore.Keys.url) as? String ?? ""
        let token : String = UserDefaults.standard.object(forKey: SettingsStore.Keys.token) as? String ?? ""

        if baseUrl.isEmpty || token.isEmpty {
            completionHandler([])
            return
        }

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
    
    func loadProfile(completionHandler: @escaping (Profile?) -> ()) {
        let baseUrl : String = UserDefaults.standard.object(forKey: SettingsStore.Keys.url) as? String ?? ""
        let token : String = UserDefaults.standard.object(forKey: SettingsStore.Keys.token) as? String ?? ""

        if baseUrl.isEmpty || token.isEmpty {
            completionHandler(nil)
            return
        }

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
                        completionHandler(activeProfile.store[activeProfile.defaultProfile]!)
                    }
                } else {
                    print("no data")
                    return
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
    }

    @objc func load() {
        loadSvg { entries in
            self.entries = entries
            self.lastEntry = entries.first
        }
        loadDeviceStatus { loopData in
            self.loopData = loopData
            self.currentLoopData = loopData.first
        }
        loadInsulin { treatments in
            self.insulin = treatments
        }
        loadCarbs { carbs in
            self.carbs = carbs
        }
        loadTempBasal { treatments in
            self.tempBasal = treatments
        }
        loadProfile { profile in
            self.profile = profile
        }
    }
    
    var cn : Measurement<UnitMass> {
        if self.profile == nil || self.lastEntry == nil || self.currentLoopData == nil {
            return Measurement(value: 0, unit: UnitMass.grams)
        }

        let now : Date = self.lastEntry!.date
        let start = Calendar.current.startOfDay(for: now)
        
        let currentSens = profile?.sens.last(where: {(start + $0.timeAsSeconds) < now})
        print("sens: \(currentSens.debugDescription)")
        let currentCarbratio = profile?.carbratio.last(where: {(start + $0.timeAsSeconds) < now})
        print("carbratio: \(currentCarbratio.debugDescription)")
        let currentTarget = profile?.target_low.last(where: {(start + $0.timeAsSeconds) < now})
        print("target: \(currentTarget.debugDescription)")
        
        let grams : Double = Double(((Double(lastEntry!.sgv) - max(currentLoopData!.iob.value,0) * currentSens!.value) - currentTarget!.value) / -currentSens!.value * currentCarbratio!.value)
        print("gramms: \(grams.debugDescription)")
        let rec_grams = currentLoopData!.cob.value - grams
        print("rec_grams: \(rec_grams.debugDescription)")

        return Measurement(
            value: max(rec_grams, 0),
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
