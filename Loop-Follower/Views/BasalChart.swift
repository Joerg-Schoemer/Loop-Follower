//
//  BasalChart.swift
//  Loop-Follower
//
//  Created by Schömer, Jörg on 14.02.23.
//

import SwiftUI
import Charts

struct BasalChart: View {

    @Binding var currentDate: Date?
    let scheduledBasal : [TempBasal]
    let resultingBasal : [TempBasal]
    
    let dashedLine : [CGFloat] = [10, 4]

    var body: some View {
        
        VStack {
            Text("Basal")
                .font(.callout)
                .foregroundStyle(.secondary)

            Chart {
                ForEach(scheduledBasal) { basal in
                    LineMark(
                        x: .value("startDate", basal.startDate),
                        y: .value("rate", basal.rate)
                    )
                    .lineStyle(StrokeStyle(dash: dashedLine))
                    LineMark(
                        x: .value("endDate", basal.endDate),
                        y: .value("rate", basal.rate)
                    )
                    .lineStyle(StrokeStyle(dash: dashedLine))
                }

                ForEach(resultingBasal) { tempBasal in
                    AreaMark(
                        x: .value("startDate", tempBasal.startDate),
                        y: .value("rate", tempBasal.rate)
                    )
                    AreaMark(
                        x: .value("endDate", tempBasal.endDate - 1),
                        y: .value("rate", tempBasal.rate)
                    )
                }

                if currentDate != nil {
                    RuleMark(
                        x: .value("now", self.currentDate!)
                    )
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    .foregroundStyle(Color(.systemYellow))
                }
            }
        }
        .padding([.top, .bottom])
    }
}

struct BasalChart_Previews: PreviewProvider {
    static var previews: some View {
        let sb = [
            TempBasal(id: "", duration: 60, rate: 0.05, timestamp: "2023-02-14T23:00:00Z"),
            TempBasal(id: "", duration: 120, rate: 0.10, timestamp: "2023-02-15T00:00:00Z"),
            TempBasal(id: "", duration: 360, rate: 0.05, timestamp: "2023-02-15T02:00:00Z")
        ]
        let rb = [
            TempBasal(id: "", duration: 30, rate: 0.05, timestamp: "2023-02-14T23:00:00Z", type: "scheduled"),
            TempBasal(id: "", duration: 30, rate: 0.00, timestamp: "2023-02-14T23:30:00Z", type: "temporary"),
            TempBasal(id: "", duration: 100, rate: 0.10, timestamp: "2023-02-15T00:00:00Z", type: "scheduled"),
            TempBasal(id: "", duration: 30,  rate: 0.15, timestamp: "2023-02-15T01:40:00Z", type: "temporary"),
            TempBasal(id: "", duration: 50, rate: 0.00, timestamp:  "2023-02-15T02:10:00Z"),
            TempBasal(id: "", duration: 100, rate: 0.05, timestamp: "2023-02-15T03:00:00Z"),
            TempBasal(id: "", duration: 200, rate: 0.05, timestamp: "2023-02-15T04:40:00Z")
        ]

        BasalChart(
            currentDate: .constant(ISO8601DateFormatter().date(from: "2023-02-15T05:15:00Z")),
            scheduledBasal: sb,
            resultingBasal: rb
        )
    }
}
