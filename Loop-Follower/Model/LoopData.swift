//
//  LoopData.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 13.07.22.
//

import Foundation

struct LoopData : Codable, Identifiable {
    enum CodingKeys: String, CodingKey {
        case id = "_id", loop, uploader, pump, override
    }

    let id : String
    let loop : Loop
    let uploader : Uploader
    let pump : Pump
    let override : LoopOverride
    
    var cob : Measurement<UnitMass> {
        return Measurement<UnitMass>(value: self.loop.cob.cob, unit: UnitMass.grams)
    }
    
    var iob : Measurement<UnitInsulin> {
        return Measurement<UnitInsulin>(value: self.loop.iob.iob, unit: .insulin)
    }
    
    var recommendedBolus : Measurement<UnitInsulin>? {
        if let bolus = self.loop.recommendedBolus {
            return Measurement<UnitInsulin>(value: bolus, unit: .insulin)
        }
        return nil
    }
    
    var pumpVolume : Measurement<UnitInsulin>? {
        if let reservoir = self.pump.reservoir {
            return Measurement<UnitInsulin>(value: reservoir, unit: .insulin)
        }
        return nil
    }
}

enum LoopState {
    case error,
         warning,
         enacted,
         looping,
         recommendation
}

struct Loop: Codable {
    let cob: Cob
    let iob: Iob
    let timestamp: String
    let recommendedBolus: Double?
    let predicted: Predicted?
    let enacted: Enacted?
    let failureReason: String?

    var date: Date {
        return formatter.date(from: timestamp)!
    }
    
    var state: LoopState {
        guard failureReason == nil else {
            return .error
        }

        let diff = Calendar.current.dateComponents([.minute], from: date, to: Date.now).minute!

        if let enacted = enacted {
            if !enacted.received {
                return .error
            }
            
            if diff < 15 {
                return .enacted
            }
        }
        
        if diff < 15 {
            return .looping
        }

        return .warning
    }
}

struct Enacted: Codable {
    let rate: Double
    let bolusVolume: Double
    let duration: TimeInterval
    let received: Bool
    let timestamp: String

    var date: Date {
        return formatter.date(from: timestamp)!
    }
}

struct Predicted : Codable {
    let values: [Double]
    let startDate: String

    var date : Date {
        
        return formatter.date(from: startDate)!
    }
}

fileprivate let formatter = ISO8601DateFormatter()

struct Cob: Codable {
    let cob : Double
}

struct Iob : Codable {
    let iob : Double
}

struct Uploader : Codable {
    let battery : Int
}

struct Pump : Codable {
    let reservoir : Double?
}

struct LoopOverride : Codable {
    let currentCorrectionRange : CorrectionRange?
    let multiplier : Double?
    let name : String?
    let symbol : String?
    let duration : TimeInterval?
    let active : Bool
    let timestamp : String
    
    var activeName : String {
        var activeName : String = ""
        if symbol != nil {
            activeName += symbol!
        }
        if name != nil {
            if !activeName.isEmpty && activeName.last != " " {
                activeName += " "
            }
            activeName += name!
        }
        if activeName.isEmpty {
            return "custom"
        }
        
        return activeName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct CorrectionRange : Codable {
    let minValue : Double
    let maxValue : Double
}

class UnitInsulin : Dimension {
    override class func baseUnit() -> Self {
        return self.insulin as! Self
    }
    
    static let insulin = UnitInsulin(symbol: NSLocalizedString("U", comment: "Unit of Insulin"), converter: UnitConverterLinear(coefficient: 1))
}
