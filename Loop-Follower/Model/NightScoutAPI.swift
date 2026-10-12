//
//  NightScoutAPI.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 05.10.26.
//

import Foundation

/// Small async/await networking helper for the Nightscout REST API.
///
/// It keeps the same query-parameter building the completion-handler based code
/// used, but removes the per-request boilerplate (status checks, decoding,
/// main-thread hopping).
///
/// The base URL and access token are read from the shared app group defaults
/// (see ``SettingsStore``), so the rest of the app does not need to pass the
/// configuration around.
struct NightScoutAPI {

    static let hourOfHistory : Int = -6

    /// The shared UserDefaults suite used to store the Nightscout configuration.
    static let suiteName = "group.loop.follower"

    /// Configuration values are re-read on every request so that changes made
    /// in the settings UI take effect immediately.
    static var baseUrl: String {
        UserDefaults(suiteName: suiteName)?.string(forKey: SettingsStore.Keys.url) ?? ""
    }

    static var token: String {
        UserDefaults(suiteName: suiteName)?.string(forKey: SettingsStore.Keys.token) ?? ""
    }

    /// Generic GET helper: builds a URL from a relative API path and query
    /// items, performs the request async, and decodes the JSON body into `T`.
    static func get<T: Decodable>(
        path: String,
        queryItems: [URLQueryItem],
        decoder: JSONDecoder? = nil
    ) async throws -> T {
        guard var components = URLComponents(string: "\(baseUrl)\(path)") else {
            throw URLError(.badURL)
        }

        var items = queryItems
        if !token.isEmpty {
            items.append(URLQueryItem(name: "token", value: token))
        }
        components.queryItems = items

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let usedDecoder = decoder ?? JSONDecoder()
        return try usedDecoder.decode(T.self, from: data)
    }
    
    static func treatments<T: Decodable>(
        _ type : String,
        _ startDate : String
    ) async throws -> T {
        return try await NightScoutAPI.get(
            path: "/api/v1/treatments.json",
            queryItems: [
                URLQueryItem(name: "find[eventType]", value: type),
                URLQueryItem(name: "find[created_at][$gte]", value: startDate)
            ]
        )
    }

    static func ageOf(eventType : String, days: Int) async -> Date? {
        let daysBackInTime : Date = Calendar.current.date(byAdding: .day, value: days, to: .now)!

        do {
            let treatments: [ChangeEvent] = try await NightScoutAPI.get(
                path: "/api/v1/treatments.json",
                queryItems: [
                    URLQueryItem(name: "find[eventType]", value: eventType),
                    URLQueryItem(name: "find[created_at][$gte]", value: formatter.string(from: daysBackInTime)),
                    URLQueryItem(name: "count", value: "1")
                ]
            )
            if let first = treatments.first {
                return first.date
            }

            print("loadEventType: no treatment of type \"\(eventType)\" found")
            return nil
        } catch {
            print("loadEventType: Error fetching treatments: \(String(describing: error))")
            return nil
        }
    }
    static func loadSgv() async -> [Entry] {
        let date = Calendar.current.date(byAdding: .hour, value: -48, to: .now)!.timeIntervalSince1970 * 1000

        do {
            return try await NightScoutAPI.get(
                path: "/api/v1/entries/sgv.json",
                queryItems: [
                    URLQueryItem(name: "find[date][$gte]", value: date.description),
                    URLQueryItem(name: "count", value: "2000")
                ]
            )
        } catch {
            print("loadSgv: Error with fetching sgv: \(error)")
            return []
        }
    }

    static func loadMbg() async -> [MbgEntry] {
        let date = Calendar.current.date(byAdding: .hour, value: hourOfHistory, to: .now)!.timeIntervalSince1970 * 1000

        do {
            return try await NightScoutAPI.get(
                path: "/api/v1/entries/mbg.json",
                queryItems: [
                    URLQueryItem(name: "find[date][$gte]", value: date.description),
                    URLQueryItem(name: "count", value: "1000")
                ]
            )
        } catch {
            print("loadMbg: Error with fetching mbg: \(error)")
            return []
        }
    }

    static func loadInsulin() async -> [CorrectionBolus] {
        do {
            return try await NightScoutAPI.treatments("/Bolus|SMB|Correction%20Bolus/", getYesterday())
        } catch {
            print("loadInsulin: Error fetching treatments: \(error)")
            return []
        }
    }
    
    static func loadCarbs() async -> [CarbCorrection] {
        do {
            return try await NightScoutAPI.treatments("Carb Correction", getYesterday())
        } catch {
            print("loadCarbs: Error fetching treatments: \(error)")
            return []
        }
    }
    
    static func loadTempBasal() async -> [TempBasal] {
        do {
            return try await NightScoutAPI.treatments("Temp Basal", getStartTime())
        } catch {
            print("loadTempBasal: Error fetching treatments: \(error)")
            return []
        }
    }
    
    static func loadDeviceStatus() async -> LoopData? {
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
    
    static func loadProfile() async -> Profiles? {
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

    fileprivate static func getStartTime() -> String {
        return formatter.string(from: Calendar.current.date(byAdding: .hour, value: hourOfHistory, to: .now)!)
    }

    fileprivate static func getYesterday() -> String {
        return formatter.string(from: Calendar.current.date(byAdding: .hour, value: -48, to: .now)!)
    }

}

fileprivate func iso8601() -> ISO8601DateFormatter {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    
    return formatter
}

fileprivate let formatter : ISO8601DateFormatter = iso8601()
