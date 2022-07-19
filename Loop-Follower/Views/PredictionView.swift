//
//  PredictionView.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 18.07.22.
//

import SwiftUI

struct PredictionView: View {
    var predicted : Predicted
    var startDate : Date
    var xMax : TimeInterval
    var yMax : Double

    var body: some View {
        GeometryReader { geo in
            let area : CGRect = CGRect(origin: CGPoint(x:0, y:0), size: geo.size)

            var date = predicted.date
            let dots : [CGRect] = predicted.values.map {
                let p = CGRect(
                    x: (date - startDate) / xMax * geo.size.width,
                    y: (1 - $0 / yMax) * geo.size.height,
                    width: CGFloat(4),
                    height: CGFloat(4)
                )
                date = Calendar.current.date(byAdding: .minute, value: 5, to: date)!
                return p
            }
            
            ForEach(dots, id: \.self) { dot in
                Path { path in
                    if area.contains(dot.origin) {
                        path.addEllipse(in: dot)
                    }
                }.fill(.purple)
            }
        }
    }
}

struct PredictionView_Previews: PreviewProvider {
    static var previews: some View {
        PredictionView(
            predicted: Predicted(
                values: [ 75,
                          68.20, 62.12, 56.74, 52.06, 48.08, 44.78, 42.17, 40.22, 38.92, 38.28, 38.29, 38.94,
                          39.58, 40.20, 40.81, 41.40, 41.97, 42.52, 43.05, 43.57, 44.06, 44.52, 44.97, 45.40
                        ],
                startDate: "2022-07-18T04:00:00Z"
            ),
            startDate: ISO8601DateFormatter().date(from: "2022-07-18T04:00:00Z")! - 14400,
            xMax: 21600,
            yMax: 260
        )
        .previewLayout(.sizeThatFits)
    }
}
