//
//  LoopData.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 13.07.22.
//

import Foundation

struct LoopData: Codable, Identifiable {
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case loop, openaps, uploader, pump, override
    }

    let id: String
    let loop: Loop?
    let openaps: OpenAPS?
    let uploader: Uploader
    let pump: Pump
    let override: LoopOverride?

    var cob: Measurement<UnitMass> {
        if let loop = self.loop {
            return Measurement<UnitMass>(
                value: loop.cob.cob,
                unit: UnitMass.grams
            )
        } else if let openAps = self.openaps {
            return Measurement<UnitMass>(
                value: openAps.suggested.COB!,
                unit: UnitMass.grams
            )
        }

        return Measurement<UnitMass>(value: 0, unit: UnitMass.grams)
    }

    var iob: Measurement<UnitInsulin> {
        if let loop = self.loop {
            return Measurement<UnitInsulin>(
                value: loop.iob.iob,
                unit: .insulin
            )
        } else if let openAps = self.openaps {
            return Measurement<UnitInsulin>(
                value: openAps.suggested.IOB!,
                unit: .insulin
            )
        }

        return Measurement<UnitInsulin>(value: 0, unit: .insulin)
    }

    var recommendedBolus: Measurement<UnitInsulin>? {
        if let loop = self.loop {
            if let bolus = loop.recommendedBolus {
                return Measurement<UnitInsulin>(value: bolus, unit: .insulin)
            }
            return nil
        } else if let openAps = self.openaps {
            return Measurement<UnitInsulin>(
                value: openAps.recommendedBolus!,
                unit: .insulin
            )
        }

        return nil

    }

    var pumpVolume: Measurement<UnitInsulin>? {
        if let reservoir = self.pump.reservoir {
            return Measurement<UnitInsulin>(value: reservoir, unit: .insulin)
        }
        return nil
    }

    var predicted: [Entry]? {
        if let openaps = self.openaps {
            if let predBGs = openaps.suggested.predBGs {
                return predictedValuesAps(startDate: openaps.suggested.date, values: predBGs.IOB!)
            }
        } else if let loop = self.loop {
            if let predicted = loop.predicted {
                return predictedValues(startDate: predicted.date, values: predicted.values)
            }
        }
        
        return nil
    }
}

fileprivate func predictedValuesAps(startDate: Date, values: [Int]) -> [Entry] {
    var currentDate = startDate
    let endDate = Calendar.current.date(
        byAdding: .hour,
        value: 3,
        to: startDate
    )!

    let predictions: [Entry] = values.map {
        let entry = Entry(
            sgv: max($0, 0),
            id: UUID().uuidString,
            dateString: formatterWithMillis.string(from: currentDate)
        )
        currentDate = Calendar.current.date(
            byAdding: .minute,
            value: 5,
            to: currentDate
        )!
        return entry
    }

    return Array(
        predictions.prefix(
            while: { $0.date <= endDate }
        )
    )

}

fileprivate func predictedValues(startDate: Date, values: [Double]) -> [Entry] {
    var currentDate = startDate
    let endDate = Calendar.current.date(byAdding: .hour, value: 3, to: startDate)!

    let predictions : [Entry] = values.map {
        let entry = Entry(
            sgv: max(Int($0), 0),
            id: UUID().uuidString,
            dateString: formatterWithMillis.string(from: currentDate)
        )
        currentDate = Calendar.current.date(byAdding: .minute, value: 5, to: currentDate)!
        return entry
    }

    return Array(
        predictions.prefix(
            while: { $0.date <= endDate}
        )
    )
}


enum LoopState {
    case error,
        warning,
        enacted,
        looping,
        recommendation
}

struct OpenAPS: Codable {
    let recommendedBolus: Double?
    let suggested: EnactedAps
}

struct PredBG: Codable {
    let IOB: [Int]?
    let COB: [Int]?
    let ZT: [Int]?
}

struct EnactedAps: Codable {
    let timestamp: String
    let eventualBG: Double?
    let IOB: Double?
    let COB: Double?
    let ISF: Int?
    let reason: String?
    let predBGs: PredBG?
    
    var date: Date {
        return formatterWithMillis.date(from: timestamp)!
    }
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

        let diff = Calendar.current.dateComponents(
            [.minute],
            from: date,
            to: Date.now
        ).minute!

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

struct Predicted: Codable {
    let values: [Double]
    let startDate: String

    var date: Date {

        return formatter.date(from: startDate)!
    }
}

private let formatter = ISO8601DateFormatter()

struct Cob: Codable {
    let cob: Double
}

struct Iob: Codable {
    let iob: Double
}

struct Uploader: Codable {
    let battery: Int
    let isCharging: Bool?
}

struct Pump: Codable {
    let reservoir: Double?
}

struct LoopOverride: Codable {
    let currentCorrectionRange: CorrectionRange?
    let multiplier: Double?
    let name: String?
    let symbol: String?
    let duration: TimeInterval?
    let active: Bool
    let timestamp: String

    var activeName: String {
        var activeName: String = ""
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

        if let multiplier = multiplier {
            activeName += " (\(Int(multiplier * 100))%)"
        }

        return activeName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var date: Date {
        return formatter.date(from: timestamp)!
    }

}

struct CorrectionRange: Codable {
    let minValue: Double
    let maxValue: Double
}

class UnitInsulin: Dimension, @unchecked Sendable {
    override class func baseUnit() -> Self {
        return self.insulin as! Self
    }

    static let insulin = UnitInsulin(
        symbol: NSLocalizedString("U", comment: "Unit of Insulin"),
        converter: UnitConverterLinear(coefficient: 1)
    )
}

fileprivate func iso8601WithMillis() -> ISO8601DateFormatter {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    
    return formatter
}

fileprivate let formatterWithMillis : ISO8601DateFormatter = iso8601WithMillis()
