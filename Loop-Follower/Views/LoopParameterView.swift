//
//  LoopParameterView.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 13.07.22.
//

import SwiftUI

struct LoopParameterView: View {

    @EnvironmentObject var modelData : ModelData

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
                Spacer()
                if let siteChanged = self.modelData.siteChanged {
                    LoopParameterValue(
                        label: NSLocalizedString("CAGE", comment: "Canula age"),
                        data: hoursBetween(start: siteChanged, end: Date.now))
                }
                if let sensorChanged = self.modelData.sensorChanged {
                    LoopParameterValue(
                        label: NSLocalizedString("SAGE", comment: "Canula age"),
                        data: hoursBetween(start: sensorChanged, end: Date.now))
                }
                if let loopData = self.modelData.currentLoopData {
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
                    LoopParameterValue(
                        label: NSLocalizedString("COB", comment: "Carbs on board"),
                        data: loopData.cob.formatted(gramFormatStyle))
                    LoopParameterValue(
                        label: NSLocalizedString("Rec. Carbs", comment: "abbreviated recommended carbs"),
                        data: self.modelData.cn.formatted(gramFormatStyle))
                    if let loop = loopData.loop {
                        Divider()
                        LoopParameterValue(
                            label: NSLocalizedString("Loop state", comment: "loop state label"),
                            data: loopState(state: loop.state))
                        LoopParameterValue(
                            label: NSLocalizedString("Min/Max/in 6h", comment: "Predicted [Min/Max/in 6h] sgv"),
                            data: predictedMinMax(loop.predicted?.values))
                    }
                    Spacer()
                    Divider()
                    LoopParameterBatteryView(
                        label: NSLocalizedString("Battery", comment: "Battery"),
                        uploader: loopData.uploader
                    )
                    if let override = loopData.override, override.active {
                        Divider()
                        LoopParameterValue(
                            label: NSLocalizedString("Override", comment: "Override Name"),
                            data: override.activeName)
                    }
                }
                Divider()
                LoopParameterValue(
                    label: NSLocalizedString("TIR last 24h", comment: "Time In Range"),
                    data: (
                        Double(
                            calcTimeInRange(
                                modelData.entries.filter{ entry in
                                    entry.date > Calendar.current.date(byAdding: .hour, value: -24, to: self.modelData.currentDate)!
                                },
                                min: 70,
                                max: 180
                            )
                        ) / 1000
                    ).formatted(.percent.precision(.fractionLength(1...1)))
                )
                Spacer()
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

func loopState(state: LoopState?) -> String {
    if let state = state {
        switch (state) {
        case .looping:
            return "🔄"
        case .error:
            return "❌"
        case .enacted:
            return "⚡️"
        case .warning:
            return "⚠️"
        case .recommendation:
            return "💉"
        }
    }

    return ""
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
        LoopParameterView()
        .environmentObject(ModelData(test: true))
        .previewLayout(.sizeThatFits)
    }
}

///
/// calculates the timeInRange in promill
///
fileprivate func calcTimeInRange(_ entries: [Entry], min: Int, max: Int) -> Int {
    if entries.isEmpty {
        return 0;
    }

    let aboveOrBelowCount = entries.filter { e in
        e.sgv > max || e.sgv < min
    }.count

    return (entries.count - aboveOrBelowCount) * 1000 / entries.count
}

