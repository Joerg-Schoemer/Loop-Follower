//
//  LoopData.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 13.07.22.
//

import Foundation

struct LoopData : Codable, Identifiable {
    enum CodingKeys: String, CodingKey {
        case id = "_id", loop, uploader, pump
    }

    let id : String
    let loop : Loop
    let uploader : Uploader
    let pump : Pump
    
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

struct Loop: Codable {
    let cob: Cob
    let iob: Iob
    let recommendedBolus : Double?
    let predicted: Predicted?
}

struct Predicted : Codable {
    let values: [Double]
    let startDate: String

    var date : Date {
        
        return ISO8601DateFormatter().date(from: startDate)!
    }
}

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

class UnitInsulin : Dimension {
    override class func baseUnit() -> Self {
        return self.insulin as! Self
    }
    
    static let insulin = UnitInsulin(symbol: NSLocalizedString("U", comment: "Unit of Insulin"), converter: UnitConverterLinear(coefficient: 1))
}
