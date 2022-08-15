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
             startDate, store, defaultProfile
    }

    let id : String
    let startDate : String
    let store : [String : Profile]
    let defaultProfile : String
    
    var date : Date {
        return formatter.date(from: startDate)!
    }
}

struct Profile : Codable {
    let basal : [Basal]
    let target_low : [Target]
    let target_high : [Target]
}

struct Basal : Codable {
    let value : Double
    let timeAsSeconds : Double
}

struct Target : Codable {
    let value : Double
    let timeAsSeconds : Double
}

fileprivate let formatter = ISO8601DateFormatter()
