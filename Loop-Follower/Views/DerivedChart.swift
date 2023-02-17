//
//  DerivedChart.swift
//  Loop-Follower
//
//  Created by Schömer, Jörg on 14.02.23.
//

import SwiftUI
import Charts

struct DerivedChart: View {
    
    let currentDate : Date?
    let entries : [Entry]
    
    let series: KeyValuePairs<String, Color> = [
        "velocity": Color(.systemBlue),
        "acceleration": Color(.systemGreen)
    ]

    var body: some View {

        let velocity = derive(entries)
        let acceleration = derive(velocity)

        VStack {
            Text("Derived")
                .font(.callout)
                .foregroundStyle(.secondary)
            Chart {
                if let currentDate = currentDate {
                    RuleMark(
                        x: .value("now", currentDate)
                    )
                    .lineStyle(StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color(.systemGray))
                }
                ForEach(velocity) { velocity in
                    BarMark(
                        x: .value("timestamp", velocity.date),
                        y: .value("BG", velocity.sgv)
                    )
                    .foregroundStyle(by: .value("category", "velocity"))
                }
                ForEach(acceleration) { accelleration in
                    BarMark(
                        x: .value("timestamp", accelleration.date),
                        y: .value("BG", accelleration.sgv)
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
    }
}

struct DerivedChart_Previews: PreviewProvider {
    static var previews: some View {
        let entries = createEntries()
        DerivedChart(
            currentDate: entries.first!.date,
            entries: entries
        )
    }
    
    static func createEntries() -> [Entry] {
        var date = Date.now
        let cal = Calendar.current
        var entries : [Entry] = []
        let formatter = ISO8601DateFormatter(.withFractionalSeconds)
        
        for _ in 1...50 {
            entries.append(Entry(
                id: "",
                sgv: Int.random(in: 70...180),
                dateString: formatter.string(from: date))
            )
            date = cal.date(byAdding: .minute, value: 5, to: date)!
        }
        
        return entries
    }
}

func derive(_ values: [Entry]) -> [Entry] {
    let diffs = zip(values.dropFirst(), values).map {
        let difference = Int(Calendar.current.dateComponents([.minute], from: $1.date, to: $0.date).minute! / 5)
        
        return Entry(id: UUID().uuidString, sgv: Int(($1.sgv - $0.sgv) / (difference <= 0 ? 1 : difference)), dateString: $1.dateString)
    }

    return diffs
}

