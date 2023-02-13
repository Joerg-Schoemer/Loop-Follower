//
//  CurvatureView.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 12.01.23.
//

import SwiftUI

struct CurvatureView: View {
    
    let values : [Entry]
    let startDate : Date
    let xMax : Double
    let baseLine : Double
    let color : UIColor

    var body: some View {
        GeometryReader { geo in
            let area = CGRect(origin: CGPoint(x:0,y:0), size: geo.size)

            let xScale = geo.size.width / xMax
            let yScale : CGFloat = 2

            ForEach(values, id: \.self) { entry in
                let carb = CGRect(
                    x: (entry.date - startDate) * xScale,
                    y: baseLine,
                    width: 5,
                    height: min(yScale * -Double(entry.sgv), geo.size.height - baseLine)
                )

                if area.contains(carb.origin) {
                    Path { path in
                        path.addRect(carb)
                    }.fill(Color(color.withAlphaComponent(0.65)))
                }
            }
        }

    }
}

func estimateFillColor(_ entry : Entry, _ posColor : UIColor, _ negColor : UIColor) -> UIColor {
    if entry.sgv < 0 {
        return negColor
    }
    
    return posColor
}

struct CurvatureView_Previews: PreviewProvider {
    static var previews: some View {
        CurvatureView(
            values: [
                Entry(id: "-", sgv: 10, dateString: "2022-08-09T08:00:00.000Z"),
                Entry(id: "-", sgv: -10, dateString: "2022-08-09T08:05:00.000Z"),
                Entry(id: "-", sgv: 50, dateString: "2022-08-09T08:10:00.000Z"),
                Entry(id: "-", sgv: -50, dateString: "2022-08-09T08:15:00.000Z"),
                Entry(id: "-", sgv: -100, dateString: "2022-08-09T08:20:00.000Z"),
                Entry(id: "-", sgv: -150, dateString: "2022-08-09T08:25:00.000Z")
            ],
            startDate: ISO8601DateFormatter().date(from: "2022-08-09T04:00:00Z")!,
            xMax: 21600,
            baseLine: 550,
            color: .systemRed
        )
    }
}
