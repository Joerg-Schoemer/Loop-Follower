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
             duration,
             created_at,
             rate
    }

    let id : String

    let duration : Double
    let rate : Double
    let created_at : String

    var type : String = "temporary"
    var endDate : Date = Date()
        
    var startDate : Date {
        return formatter.date(from: created_at)!
    }
}

struct CorrectionBolus : Codable, Identifiable {
    enum CodingKeys: String, CodingKey {
        case id = "_id",
             insulin,
             duration,
             eventType,
             timestamp,
             created_at
    }

    let id: String
    let insulin: Double
    let duration : Double?
    let timestamp: String?
    let created_at: String
    let eventType: String
    
    var date : Date {
        return formatter.date(from: created_at)!
    }
    
    var amount : Measurement<UnitInsulin> {
        return Measurement<UnitInsulin>(value: insulin, unit: .insulin)
    }
    
    var type : String {
        if let duration = self.duration {
            return switch Int(duration) {
            case 0: "Automatic Bolus"
            case 1: "Bolus"
            default: eventType
            }
        }
        
        return eventType
    }
}

struct CarbCorrection : Codable, Identifiable {
    enum CodingKeys: String, CodingKey {
        case id = "_id",
             carbs, timestamp, foodType, absorptionTime, created_at
    }

    let id: String
    let foodType: String?
    let absorptionTime: Int?
    let carbs: Double
    let timestamp: String?
    let created_at: String
    
    var date : Date {
        return formatter.date(from: created_at)!
    }
    
    var mass : Measurement<UnitMass> {
        return Measurement(value: carbs, unit: .grams)
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
                foodTypeString = {
                    switch (timeInHours) {
                    case
                        numberFormatter.string(from: 0.5),
                        numberFormatter.string(from: 1.0):
                        return "🍭";
                    case
                        numberFormatter.string(from: 1.5),
                        numberFormatter.string(from: 2.0),
                        numberFormatter.string(from: 2.5),
                        numberFormatter.string(from: 3.0),
                        numberFormatter.string(from: 3.5),
                        numberFormatter.string(from: 4.0),
                        numberFormatter.string(from: 4.5):
                        return "🌮";
                    case
                        numberFormatter.string(from: 5.0),
                        numberFormatter.string(from: 5.5):
                        return "🍕";
                    case numberFormatter.string(from: 6.0):
                        return "🥣";
                    default:
                        return "🍽"
                    }
                }()
            }
        } else {
            timeInHours = ""
        }

        var descriptionString = ""
        descriptionString.append(foodTypeString)
        if !descriptionString.isEmpty {
            descriptionString.append(" ")
        }
        descriptionString.append(numberFormatter.string(from: NSNumber.init(value: self.carbs))! + "g ")
        if !timeInHours.isEmpty {
            descriptionString.append(self.absorption.formatted(
                .measurement(
                    width: .narrow,
                    numberFormatStyle: .number.precision(.fractionLength(1...1)))
                )
            )
        }

        return descriptionString
    }

    var absorption : Measurement<UnitDuration> {
        var timeInHours : Measurement<UnitDuration> = Measurement<UnitDuration>(value: Double(3), unit: .hours)

        if let time = absorptionTime {
            timeInHours = Measurement<UnitDuration>(value: Double(time), unit: .minutes)
        }

        return timeInHours.converted(to: .hours)
    }
    
    var endOfAbsorption : Date {
        return Calendar.current.date(byAdding: .minute, value: self.absorptionTime ?? 180, to: self.date)!
    }
    
    var endOfHalfAbsorption : Date {
        return Calendar.current.date(byAdding: .minute, value: (self.absorptionTime ?? 180) / 2, to: self.date)!
    }
}

struct Treatment : Codable, Identifiable {
    enum CodingKeys: String, CodingKey {
        case id = "_id",
             type, insulinType, insulin, eventType, duration, timestamp, rate, created_at
    }

    let id: String
    let type: String?
    let insulinType: String
    let insulin: Double?

    let eventType: String
    let duration: Double
    let rate : Double?
    let timestamp: String?
    let created_at: String
    
    var date : Date {
        return formatter.date(from: created_at)!
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
        return formatter.date(from: created_at)!
    }
}

fileprivate let formatter = ISO8601DateFormatter([.withInternetDateTime, .withFractionalSeconds])
