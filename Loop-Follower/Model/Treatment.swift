//
//  Treatment.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 18.07.22.
//

import Foundation

struct Treatment : Codable, Identifiable {
    enum CodingKeys: String, CodingKey {
        case id = "_id",
             type, programmed, insulinType, insulin, unabsorbed, automatic, eventType, duration, timestamp
    }

    let id: String
    let type: String
    let programmed: Double
    let insulinType: String
    let insulin: Double
    let unabsorbed: Double

    let automatic: Bool
    let eventType: String
    let duration: Double
    let timestamp: String
    
    var date : Date {
        return ISO8601DateFormatter().date(from: timestamp)!
    }
}
