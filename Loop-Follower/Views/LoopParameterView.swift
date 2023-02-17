//
//  LoopParameterView.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 13.07.22.
//

import SwiftUI

struct LoopParameterView: View {
    
    let loopData : LoopData
    let cn : Measurement<UnitMass>
    let siteChanged : Date?
    let sensorChanged : Date?
    
    let insulinFormatStyle = Measurement<UnitInsulin>.FormatStyle(
        width: .abbreviated,
        usage: .asProvided,
        numberFormatStyle: .number.precision(.fractionLength(2))
    )
    
    let gramFormatStyle = Measurement<UnitMass>.FormatStyle (
        width: .abbreviated,
        usage: .asProvided,
        numberFormatStyle: .number.precision(.fractionLength(1))
    )
    
    var body : some View {

        VStack {
            Group {
                if let siteChanged = self.siteChanged {
                    LoopParameterValue(
                        label: NSLocalizedString("CAGE", comment: "Canula age"),
                        data: hoursBetween(start: siteChanged, end: Date.now))
                }
                if let sensorChanged = self.sensorChanged {
                    LoopParameterValue(
                        label: NSLocalizedString("SAGE", comment: "Canula age"),
                        data: hoursBetween(start: sensorChanged, end: Date.now))
                }
                Divider()
                LoopParameterValue(
                    label: NSLocalizedString("COB", comment: "Carbs on board"),
                    data: loopData.cob.formatted(gramFormatStyle))
                LoopParameterValue(
                    label: NSLocalizedString("Rec. Carbs", comment: "abbreviated recommended carbs"),
                    data: cn.formatted(gramFormatStyle))
                Divider()
            }
            Group {
                LoopParameterValue(
                    label: NSLocalizedString("IOB", comment: "Insulin on board"),
                    data: loopData.iob.formatted(insulinFormatStyle))
                LoopParameterValue(
                    label: NSLocalizedString("Rec. Bolus", comment: "abbreviated recommended bolus"),
                    data: recommendedBolus(self.loopData.recommendedBolus))
                LoopParameterValue(
                    label: NSLocalizedString("Pump Volume", comment: "Pump reservoir volume"),
                    data: pumpVolume(loopData.pumpVolume))
                Divider()
                LoopParameterValue(
                    label: NSLocalizedString("Min/Max/in 6h", comment: "Predicted [Min/Max/in 6h] sgv"),
                    data: predictedMinMax(loopData.loop.predicted?.values))
                Divider()
                LoopParameterBatteryView(
                    label: NSLocalizedString("Battery", comment: "Battery"),
                    percentage: loopData.uploader.battery)
                if loopData.override.active {
                    LoopParameterValue(
                        label: NSLocalizedString("Override", comment: "Override Name"),
                        data: loopData.override.activeName)
                }
            }
                
        }
        .font(.footnote)
    }
    
    func recommendedBolus(_ bolus : Measurement<UnitInsulin>?) -> String {
        if let bolus = bolus {
            return bolus.formatted(insulinFormatStyle)
        }
        
        return NSLocalizedString("None", comment: "no recommended Bolus")
    }
    
    func pumpVolume(_ value : Measurement<UnitInsulin>?) -> String {
        if let value =  value {
            return value.formatted(insulinFormatStyle)
        }
        
        return "> " + Measurement<UnitInsulin>(value: 50, unit: UnitInsulin.insulin).formatted(insulinFormatStyle)
    }
}

extension Date {
    static func - (lhs: Date, rhs: Date) -> TimeInterval {
        return lhs.timeIntervalSinceReferenceDate - rhs.timeIntervalSinceReferenceDate
    }
}

func predictedMinMax(_ values : [Double]?) -> String {
    
    if let values = values {
        let min = Int(values.min()!)
        let max = Int(values.max()!)
        let last = Int(values.last!)
        
        return "\(min)/\(max)/\(last)"
    }
    
    return "-"
}

func hoursBetween(start: Date, end: Date) -> String {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.day, .hour]
    formatter.unitsStyle = .abbreviated
    
    return formatter.string(from: start, to: end)!
}

struct LoopParameterView_Previews: PreviewProvider {
    static var previews: some View {
        LoopParameterView(
            loopData: LoopData(
                id: "",
                loop: Loop(
                    cob: Cob(cob: 1.1),
                    iob: Iob(iob: 0.05),
                    recommendedBolus: 0.1,
                    predicted: nil
                ),
                uploader: Uploader(battery: 75),
                pump: Pump(reservoir: nil),
                override: LoopOverride(
                    currentCorrectionRange: nil,
                    multiplier: nil,
                    name: "Sport",
                    symbol: "🏃🏻 ",
                    duration: nil,
                    active: true,
                    timestamp: "2022-12-06T05:06:06Z"
                )
            ),
            cn: Measurement<UnitMass>(value: 2.5, unit: UnitMass.grams),
            siteChanged: (Date.now - 86400.0),
            sensorChanged: (Date.now - 86400.0/2.0)
        )
        .previewLayout(.sizeThatFits)
    }
}
