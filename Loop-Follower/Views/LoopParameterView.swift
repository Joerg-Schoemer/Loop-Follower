//
//  LoopParameterView.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 13.07.22.
//

import SwiftUI

struct LoopParameterView: View {
    
    let loopData : LoopData
    
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
            LoopParameterValue(
                label: NSLocalizedString("COB", comment: "Carbs on board"),
                data: loopData.cob.formatted(gramFormatStyle))
            Divider()
            LoopParameterValue(
                label: NSLocalizedString("IOB", comment: "Insulin on board"),
                data: loopData.iob.formatted(insulinFormatStyle))
            LoopParameterValue(
                label: NSLocalizedString("Rec. Bolus", comment: "abbreviated recommended bolus"),
                data: recommendedBolus(loopData.recommendedBolus))
            LoopParameterValue(
                label: NSLocalizedString("Pump Volume", comment: "Pump reservoir volume"),
                data: pumpVolume(loopData.pumpVolume))
            Divider()
            LoopParameterBatteryView(
                label: NSLocalizedString("Battery", comment: "Battery"),
                percentage: loopData.uploader.battery)
        }
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

struct LoopParameterView_Previews: PreviewProvider {
    static var previews: some View {
        LoopParameterView(loopData: LoopData(
            id: "",
            loop: Loop(
                cob: Cob(cob: 1.1),
                iob: Iob(iob: 0.05),
                recommendedBolus: 0.0,
                predicted: nil
            ),
            uploader: Uploader(battery: 75),
            pump: Pump(reservoir: nil)))
        .previewLayout(.sizeThatFits)
    }
}
