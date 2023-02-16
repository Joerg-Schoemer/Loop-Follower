//
//  Treatment.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 18.07.22.
//

import Foundation

struct TempBasal : Codable, Identifiable {
    enum CodingKeys: String, CodingKey {
        case id = "_id",
             duration, timestamp, rate
    }

    let id : String

    let duration : Double
    let rate : Double
    let timestamp : String
    var type : String = "temporary"
        
    var startDate : Date {
        return formatter.date(from: timestamp)!
    }

    var endDate : Date {
        return startDate + (duration * 60)
    }
}

struct CorrectionBolus : Codable, Identifiable {
    enum CodingKeys: String, CodingKey {
        case id = "_id",
             insulin, timestamp
    }

    let id: String
    let insulin: Double
    let timestamp: String
    
    var date : Date {
        return formatter.date(from: timestamp)!
    }
}

struct CarbCorrection : Codable, Identifiable {
    enum CodingKeys: String, CodingKey {
        case id = "_id",
             carbs, timestamp, foodType
    }

    let id: String
    let foodType: String?
    let carbs: Double
    let timestamp: String
    
    var date : Date {
        return formatter.date(from: timestamp)!
    }
    
    var description : String {
        if let footType = foodType {
            return footType + String(format: " %.0f g", carbs)
        }

        return String(format: "%.0f g", carbs)
    }
}

struct Treatment : Codable, Identifiable {
    enum CodingKeys: String, CodingKey {
        case id = "_id",
             type, insulinType, insulin, eventType, duration, timestamp, rate
    }

    let id: String
    let type: String?
    let insulinType: String
    let insulin: Double?

    let eventType: String
    let duration: Double
    let rate : Double?
    let timestamp: String
    
    var date : Date {
        return formatter.date(from: timestamp)!
    }
}

struct ChangeEvent : Codable, Identifiable {
    enum CodingKeys: String, CodingKey {
        case id = "_id",
             eventType, created_at
    }

    let id: String
    let eventType: String
    let created_at: String

    var date : Date {
        return ISO8601DateFormatter([.withInternetDateTime, .withFractionalSeconds]).date(from: created_at)!
    }
}

fileprivate let formatter = ISO8601DateFormatter()
