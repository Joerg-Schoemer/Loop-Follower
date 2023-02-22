//
//  DerivedChart.swift
//  Loop-Follower
//
//  Created by Schömer, Jörg on 14.02.23.
//

import SwiftUI
import Charts

struct DerivedChart: View {
    
    @Binding var currentDate : Date?
    @Binding var entries : [Entry]

    @State var orientation = UIDevice.current.orientation
    @State var prevOrientation = UIDevice.current.orientation

    @State var width : MarkDimension = estimateBarWidth(prev: UIDevice.current.orientation, current: UIDevice.current.orientation)
    
    let orientationChanged = NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
        .makeConnectable()
        .autoconnect()
    
    let series: KeyValuePairs<String, Color> = [
        "velocity": Color(.systemBlue),
        "acceleration": Color(.systemGreen)
    ]

    var body: some View {

        let velocity = derive(entries, "veloc")
        let acceleration = derive(velocity, "accel")

        VStack {
            Text("Derived")
                .font(.callout)
                .foregroundStyle(.secondary)
            Chart {
                if let currentDate = currentDate {
                    RuleMark(
                        x: .value("now", currentDate)
                    )
                    .foregroundStyle(Color(.systemGray))
                    RuleMark(
                        x: .value("future", Calendar.current.date(byAdding: .hour, value: 3, to: currentDate)!)
                    )
                    .foregroundStyle(Color(.systemFill))
                }
                ForEach(velocity) { velocity in
                    BarMark(
                        x: .value("timestamp", velocity.date),
                        y: .value("BG", velocity.sgv),
                        width: width
                    )
                    .foregroundStyle(by: .value("category", "velocity"))
                }
                ForEach(acceleration) { acceleration in
                    BarMark(
                        x: .value("timestamp", acceleration.date),
                        y: .value("BG", acceleration.sgv),
                        width: width
                    )
                    .foregroundStyle(by: .value("category", "acceleration"))
                }
            }
            .chartLegend(position: .overlay, alignment: .topLeading) {
                HStack {
                    ForEach(series, id: \.key) { key, value in
                        Circle()
                            .fill(value)
                            .frame(width: 9)
                        Text(NSLocalizedString(key, comment: "Legend of blood glucose chart"))
                            .font(.footnote)
                            .foregroundColor(Color(.systemGray))
                    }
                }
            }
        }
        .padding([.top, .bottom])
        .onReceive(orientationChanged) { _ in
            self.prevOrientation = self.orientation
            self.orientation = UIDevice.current.orientation
            width = estimateBarWidth(prev: prevOrientation, current: orientation)
        }
    }

}

fileprivate func estimateBarWidth(prev: UIDeviceOrientation, current:  UIDeviceOrientation)  -> MarkDimension {
    return current.isLandscape || prev.isLandscape && current.isFlat ? 5 : 2
}

struct DerivedChart_Previews: PreviewProvider {
    @State static var entries = createEntries()
    @State static var currentDate : Date? = entries.first!.date

    static var previews: some View {
        DerivedChart(
            currentDate: $currentDate,
            entries: $entries
        )
    }
    
    static func createEntries() -> [Entry] {
        var date = Date.now
        let cal = Calendar.current
        var entries : [Entry] = []
        let formatter = ISO8601DateFormatter(.withFractionalSeconds)
        
        for i in 0...72 {
            entries.append(
                Entry(
                    id: UUID().uuidString,
                    sgv: Int((sin(Double.pi * Double(-i) / 36.0) * 800.0 + 1500.0).nextUp.rounded()),
                    dateString: formatter.string(from: date)
                )
            )
            date = cal.date(byAdding: .minute, value: -5, to: date)!
        }
        
        return entries
    }

}

func derive(_ values: [Entry], _ name: String) -> [Entry] {
    let diffs = zip(values.dropFirst(), values).map {
        let dateDifference = Calendar.current.dateComponents([.second], from: $0.date, to: $1.date).second!
        
        let entry = Entry(
            id: UUID().uuidString,
            sgv: Int(
                (Double(($1.sgv - $0.sgv) * 300) /
                Double(dateDifference <= 0 ? 1 : dateDifference)
                ).nextUp.rounded()
            ),
            dateString: $1.dateString
        )

        return entry
    }

    return diffs
}

