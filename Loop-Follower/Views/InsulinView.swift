//
//  InsulinView.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 18.07.22.
//

import SwiftUI

struct InsulinView: View {

    var insulins : [Treatment]
    var startDate : Date
    var xMax : TimeInterval
    
    var body: some View {
        GeometryReader { geo in
            let area = CGRect(origin: CGPoint(x:0,y:0), size: geo.size)

            let insulins = self.insulins.map {
                return CGRect(
                    x: ($0.date - startDate) / xMax * geo.size.width,
                    y: 0,
                    width: CGFloat(3),
                    height: min(CGFloat(80 * $0.insulin), geo.size.height)
                )
            }

            ForEach(insulins, id: \.self) { insulin in
                Path { path in
                    if area.contains(insulin.origin) {
                        path.addRect(insulin)
                    }
                }.fill(.blue)
            }
        }
    }
}

struct InsulinView_Previews: PreviewProvider {
    static var previews: some View {
        InsulinView(
            insulins: [
                Treatment(
                    id: "",
                    type: "",
                    programmed: 0,
                    insulinType: "",
                    insulin: 0.05,
                    unabsorbed: 0,
                    automatic: true,
                    eventType: "",
                    duration: 0,
                    timestamp: "2022-07-19T03:00:00Z"
                ),
                Treatment(
                    id: "",
                    type: "",
                    programmed: 0,
                    insulinType: "",
                    insulin: 2.9,
                    unabsorbed: 0,
                    automatic: true,
                    eventType: "",
                    duration: 0,
                    timestamp: "2022-07-19T03:15:00Z"
                )
            ],
            startDate: ISO8601DateFormatter().date(from: "2022-07-19T00:00:00Z")!,
            xMax: 21600)
        .previewLayout(.sizeThatFits)
    }
}
