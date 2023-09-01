//
//  Profile.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 09.08.22.
//

import Foundation

struct Profiles : Codable, Identifiable {
    enum CodingKeys: String, CodingKey {
        case id = "_id",
             startDate, store, defaultProfile, loopSettings
    }

    let id : String
    let startDate : String
    let store : [String : Profile]
    let defaultProfile : String
    let loopSettings : LoopSettings
    
    var date : Date {
        return formatter.date(from: startDate)!
    }
}

struct Profile : Codable {
    let basal : [Basal]
    let target_low : [Target]
    let target_high : [Target]
    let sens : [Target]
    let carbratio : [Target]
}

struct Basal : Codable {
    let value : Double
    let timeAsSeconds : Double
}

struct Target : Codable {
    let value : Double
    let timeAsSeconds : Double
    
    var time : Date {
        return Calendar.current.startOfDay(for: Date()) + timeAsSeconds
    }
}

struct LoopSettings : Codable {
    let scheduleOverride : Override?
    let dosingStrategy : String

    enum CodingKeys: String, CodingKey {
        case scheduleOverride
        case dosingStrategy
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        dosingStrategy = try values.decode(String.self, forKey: .dosingStrategy)
        if let scheduleOverride = try values.decodeIfPresent(Override.self, forKey: .scheduleOverride) {
            self.scheduleOverride = scheduleOverride
        } else {
            self.scheduleOverride = nil
        }
    }
}

struct Override : Codable {
    let name : String?
    let symbol : String?
    let insulinNeedsScaleFactor : Double
    let duration : TimeInterval
    let targetRange : [Double]?
    
    enum CodingKeys: String, CodingKey {
        case name
        case symbol
        case insulinNeedsScaleFactor
        case duration
        case targetRange
    }
        
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        name = try values.decodeIfPresent(String.self, forKey: .name)
        symbol = try values.decodeIfPresent(String.self, forKey: .symbol)
        insulinNeedsScaleFactor = try values.decodeIfPresent(Double.self, forKey: .insulinNeedsScaleFactor) ?? 1.0
        duration = try values.decode(TimeInterval.self, forKey: .duration)

        if let targetRange = try values.decodeIfPresent([Double].self, forKey: .targetRange) {
            self.targetRange = targetRange
        } else {
            self.targetRange = nil
        }
    }
   
}

fileprivate let formatter = ISO8601DateFormatter()
