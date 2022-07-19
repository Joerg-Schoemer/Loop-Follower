//
//  GlucoseView.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 19.07.22.
//

import SwiftUI

struct GlucoseView: View {
    var entries : [Entry]
    var startDate : Date

    var xMax : TimeInterval
    var yMax : Double

    var critical : Double
    var upper : Double
    var lower : Double

    var body: some View {
        GeometryReader { geo in
            let area = CGRect(origin: CGPoint(x:0,y:0), size: geo.size)

            let criticalThreshold = (1 - critical / yMax) * geo.size.height
            let upperThreshold = (1 - upper / yMax) * geo.size.height
            let lowerThreshold = (1 - lower / yMax) * geo.size.height

            let sgvs : [CGRect] = entries.map {
                return CGRect(
                    x: ($0.date - startDate) / xMax * geo.size.width,
                    y: (1 - Double($0.sgv) / yMax) * geo.size.height,
                    width: CGFloat(4),
                    height: CGFloat(4)
                )
            }
            
            ForEach(sgvs, id: \.self) { sgv in
                Path { path in
                    if area.contains(sgv.origin) {
                        path.addEllipse(in: sgv)
                    }
                }.fill(
                    estimateColorBySgv(
                        sgv: sgv.origin.y,
                        lower: lowerThreshold,
                        upper: upperThreshold,
                        critical: criticalThreshold
                    ))
            }
        }
    }
}

func estimateColorBySgv(sgv : Double, lower: Double, upper : Double, critical : Double) -> Color {
    if sgv > lower || sgv <= critical {
        return .red
    }
    
    if sgv < upper {
        return .yellow
    }
    
    return .green
}

struct GlucoseView_Previews: PreviewProvider {
    static var previews: some View {
        GlucoseView(
            entries: [
                Entry(id: "schnurz", sgv: 54, dateString: "2022-07-19T00:00:00.000Z"),
                Entry(id: "schnurz", sgv: 70, dateString: "2022-07-19T00:05:00.000Z"),
                Entry(id: "schnurz", sgv: 75, dateString: "2022-07-19T00:10:00.000Z"),
                Entry(id: "schnurz", sgv: 90, dateString: "2022-07-19T00:15:00.000Z"),
                Entry(id: "schnurz", sgv: 120, dateString: "2022-07-19T00:20:00.000Z"),
                Entry(id: "schnurz", sgv: 180, dateString: "2022-07-19T00:25:00.000Z"),
                Entry(id: "schnurz", sgv: 210, dateString: "2022-07-19T00:30:00.000Z"),
                Entry(id: "schnurz", sgv: 250, dateString: "2022-07-19T00:35:00.000Z"),
                Entry(id: "schnurz", sgv: 252, dateString: "2022-07-19T00:40:00.000Z"),
                Entry(id: "schnurz", sgv: 205, dateString: "2022-07-19T00:45:00.000Z"),
                Entry(id: "schnurz", sgv: 185, dateString: "2022-07-19T00:50:00.000Z"),
                Entry(id: "schnurz", sgv: 150, dateString: "2022-07-19T00:55:00.000Z"),
                Entry(id: "schnurz", sgv: 100, dateString: "2022-07-19T01:00:00.000Z"),
            ],
            startDate: ISO8601DateFormatter().date(from: "2022-07-19T00:00:00Z")! - 14400,
            xMax: 25200,
            yMax: 260,
            critical: 250,
            upper: 180,
            lower: 70
        ).previewLayout(.sizeThatFits)
    }
}
