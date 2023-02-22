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
             carbs, timestamp, foodType, absorptionTime
    }

    let id: String
    let foodType: String?
    let absorptionTime: Int?
    let carbs: Double
    let timestamp: String
    
    var date : Date {
        return formatter.date(from: timestamp)!
    }
    
    var description : String {
        var foodTypeString : String = ""
        var timeInHours : String = ""
        let numberFormatter = NumberFormatter()
        numberFormatter.minimumFractionDigits = 1
        numberFormatter.maximumFractionDigits = 1
        numberFormatter.roundingMode = .halfUp

        if let foodType = foodType {
            foodTypeString = foodType
        }

        if let absorptionTime = absorptionTime {

            let time = (Double(absorptionTime) / 60)
            timeInHours = numberFormatter.string(from: NSNumber.init(value: time))!

            if foodTypeString.isEmpty {
                foodTypeString = {switch (timeInHours) {
                case numberFormatter.string(from: 0.5):
                    return "🍭";
                case numberFormatter.string(from: 3.0):
                    return "🌮";
                case numberFormatter.string(from: 5.0):
                    return "🍕";
                default:
                    return "🍽"
                }}()
            }
        } else {
            timeInHours = ""
        }

        var descriptionString = ""
        descriptionString.append(foodTypeString)
        if !descriptionString.isEmpty {
            descriptionString.append(" ")
        }
        descriptionString.append(numberFormatter.string(from: NSNumber.init(value: self.carbs))! + "g")
        if !timeInHours.isEmpty {
            descriptionString.append(" \(timeInHours)h")
        }

        return descriptionString
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
