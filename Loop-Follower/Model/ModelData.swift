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
    
    @Published var insulin : [Treatment] = []
    
    func loadSvg(completionHandler: @escaping ([Entry]) -> ()) {
        let baseUrl : String = UserDefaults.standard.object(forKey: SettingsStore.Keys.url) as? String ?? ""
        let token : String = UserDefaults.standard.object(forKey: SettingsStore.Keys.token) as? String ?? ""

        if baseUrl.isEmpty || token.isEmpty {
            completionHandler([])
            return
        }

        if let url = URL(string: "\(baseUrl)/api/v1/entries/sgv.json?token=\(token)&count=60") {
            URLSession.shared.dataTask(with: url, completionHandler: { data, response, error in
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
    
    func loadInsulin(completionHandler: @escaping ([Treatment]) -> ()) {
        let baseUrl : String = UserDefaults.standard.object(forKey: SettingsStore.Keys.url) as? String ?? ""
        let token : String = UserDefaults.standard.object(forKey: SettingsStore.Keys.token) as? String ?? ""

        if baseUrl.isEmpty || token.isEmpty {
            completionHandler([])
            return
        }
        
        let format = ISO8601DateFormatter()
        format.formatOptions = [.withFullDate]
        
        let today = format.string(from: Date())

        if let url = URL(string: "\(baseUrl)/api/v1/treatments.json?token=\(token)&find[eventType]=Correction%20Bolus&find[timestamp][$gte]=\(today)") {
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
    
    func loadDevice(completionHandler: @escaping ([LoopData]) -> ()) {
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
    }

    @objc func load() {
        loadSvg { entries in
            self.entries = entries
            self.lastEntry = entries.first
        }
        loadDevice { loopData in
            self.loopData = loopData
            self.currentLoopData = loopData.first
        }
        loadInsulin { treatments in
            self.insulin = treatments
        }
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
