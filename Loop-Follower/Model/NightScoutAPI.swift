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
}
