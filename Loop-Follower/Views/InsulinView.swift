//
//  InsulinView.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 18.07.22.
//

import SwiftUI

struct InsulinView: View {

    var insulins : [CorrectionBolus]
    var startDate : Date
    var xMax : TimeInterval
    
    var body: some View {
        GeometryReader { geo in
            let area = CGRect(origin: CGPoint(x:0,y:0), size: geo.size)

            let insulins = self.insulins.map {
                return CGRect(
                    x: ($0.date - startDate) / xMax * geo.size.width,
                    y: 0,
                    width: 5,
                    height: min(80 * $0.insulin, geo.size.height)
                )
            }
            
            let fillColor = Color(.systemOrange.withAlphaComponent(0.5))

            ForEach(insulins, id: \.self) { insulin in
                if area.contains(insulin.origin) {
                    Path { path in
                        path.addRect(insulin)
                    }.fill(fillColor)
                }
            }
        }
    }
}

struct InsulinView_Previews: PreviewProvider {
    static var previews: some View {
        InsulinView(
            insulins: [
                CorrectionBolus(
                    id: "",
                    insulin: 0.05,
                    timestamp: "2022-07-19T03:00:00Z"
                ),
                CorrectionBolus(
                    id: "",
                    insulin: 2.9,
                    timestamp: "2022-07-19T03:15:00Z"
                )
            ],
            startDate: ISO8601DateFormatter().date(from: "2022-07-19T00:00:00Z")!,
            xMax: 21600)
        .previewLayout(.sizeThatFits)
    }
}
