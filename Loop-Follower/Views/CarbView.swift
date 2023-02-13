//
//  CarbView.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 10.08.22.
//

import SwiftUI

struct CarbView: View {
    let carbs : [CarbCorrection]
    let startDate : Date
    let xMax : Double

    var body: some View {
        GeometryReader { geo in
            let area = CGRect(origin: CGPoint(x:0,y:0), size: geo.size)

            let xScale = geo.size.width / xMax
            let yScale : CGFloat = 5

            let carbs = self.carbs.map {
                return CGRect(
                    x: ($0.date - startDate) * xScale,
                    y: 0,
                    width: 5,
                    height: min(yScale * $0.carbs, geo.size.height)
                )
            }
            
            ForEach(carbs, id: \.self) { carb in
                if area.contains(carb.origin) {
                    Path { path in
                        path.addRect(carb)
                    }.fill(Color(.systemGreen.withAlphaComponent(0.5)))
                }
            }
        }
    }
}

struct CarbView_Previews: PreviewProvider {
    static var previews: some View {
        CarbView(
            carbs: [
                CarbCorrection(
                    id: "",
                    carbs: 4,
                    timestamp: "2022-08-09T08:00:00Z"
                ),
                CarbCorrection(
                    id: "",
                    carbs: 62,
                    timestamp: "2022-08-09T05:00:00Z"
                ),
            ],
            startDate: ISO8601DateFormatter().date(from: "2022-08-09T04:00:00Z")!,
            xMax: 21600
        )
        .previewInterfaceOrientation(.portrait)
    }
}
