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
    var maxWidth : TimeInterval

    var maxSgv : Double
    var lowerThreshold : Double
    var upperThreshold : Double
    var criticalThreshold : Double

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let area = CGRect(origin: CGPoint(x:0,y:0), size: geo.size)

            let sgvs : [CGRect] = entries.map {
                return CGRect(
                    x: ($0.date - startDate) / maxWidth * width,
                    y: (1 - (Double($0.sgv) / maxSgv)) * height,
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
    if sgv >= lower || sgv <= critical {
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
                Entry(id: "schnurz", sgv: 174, dateString: "2022-07-19T00:00:00.000Z"),
                Entry(id: "schnurz", sgv: 190, dateString: "2022-07-19T00:05:00.000Z"),
                Entry(id: "schnurz", sgv: 200, dateString: "2022-07-19T00:10:00.000Z"),
                Entry(id: "schnurz", sgv: 205, dateString: "2022-07-19T00:15:00.000Z"),
                Entry(id: "schnurz", sgv: 203, dateString: "2022-07-19T00:20:00.000Z"),
                Entry(id: "schnurz", sgv: 193, dateString: "2022-07-19T00:25:00.000Z"),
                Entry(id: "schnurz", sgv: 153, dateString: "2022-07-19T00:30:00.000Z"),
            ],
            startDate: formatter.date(from: "2022-07-19T00:00:00.000Z")! - 14400,
            maxWidth: 21600,
            maxSgv: 260,
            lowerThreshold: 400 - 70,
            upperThreshold: 400 - 180,
            criticalThreshold: 400 - 250
        ).previewLayout(.sizeThatFits)
    }
}
