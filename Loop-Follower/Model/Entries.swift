//
//  Entries.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 13.07.22.
//

import Foundation

enum Direction : String, Codable, CaseIterable {
    case doubleUp = "DoubleUp"
    case singleUp = "SingleUp"
    case fortyFiveUp = "FortyFiveUp"
    case flat = "Flat"
    case fortyFiveDown = "FortyFiveDown"
    case singleDown = "SingleDown"
    case doubleDown = "DoubleDown"
    case unknown = "NOT COMPUTABLE"
}

struct Entry: Hashable, Decodable, Identifiable {
    enum CodingKeys: String, CodingKey {
        case id = "_id", sgv, direction, dateString
    }

    var id : String
    var sgv : Int
    var direction : Direction?
    var delta : Int?
    
    var directionDegree : Double? {
        if let direction = self.direction {
            switch direction {
                
            case .doubleUp:
                return 0
                
            case .singleUp:
                return 30
                
            case .fortyFiveUp:
                return 60
                
            case .flat:
                return 90
                
            case .fortyFiveDown:
                return 120
                
            case .singleDown:
                return 150
                
            case .doubleDown:
                return 180
                
            default:
                return nil
            }
        }
        
        return nil
    }
    
    var dateString : String

    var date : Date {
        return  formatter.date(from: dateString)!
    }
}

fileprivate let formatter = ISO8601DateFormatter(.withFractionalSeconds)

extension ISO8601DateFormatter {
    convenience init(_ formatOptions: Options) {
        self.init()
        self.formatOptions.insert(formatOptions)
    }
}
