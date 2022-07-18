//
//  PredictionView.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 18.07.22.
//

import SwiftUI

struct PredictionView: View {
    var currentLoop : LoopData
    var startDate : Date
    var maxWidth : TimeInterval
    var maxSgv : Double

    var body: some View {
        GeometryReader { geo in
            let width : CGFloat = geo.size.width
            let height : CGFloat = geo.size.height
            let area : CGRect = CGRect(origin: CGPoint(x:0, y:0), size: geo.size)
            
            if let predicted = currentLoop.loop.predicted {
                if !predicted.values.isEmpty {
                    var date = predicted.date
                    let sgvs : [CGRect] = predicted.values.map {
                        let p = CGRect(
                            x: (date - startDate) / maxWidth * width,
                            y: height - Double($0) / maxSgv * height,
                            width: CGFloat(4),
                            height: CGFloat(4)
                        )
                        date = Calendar.current.date(byAdding: .minute, value: 5, to: date)!
                        return p
                    }

                    ForEach(sgvs, id: \.self) { sgv in
                        Path { path in
                            if area.contains(sgv.origin) {
                                path.addEllipse(in: sgv)
                            }
                        }.fill(.purple)
                    }
                }
            }
        }
    }
}

struct PredictionView_Previews: PreviewProvider {
    static var previews: some View {
        PredictionView(
            currentLoop:
                LoopData(
                    id: "",
                    loop: Loop(
                        cob: Cob(cob: 1),
                        iob: Iob(iob: 4),
                        recommendedBolus: 0,
                        predicted: Predicted(
                            values: [54, 62, 70, 75, 77, 78, 76, 75, 74, 72, 71, 69, 68, 67, 65, 63],
                            startDate: "2022-07-18T22:00:00Z"
                        )
                    ),
                    uploader: Uploader(battery: 10),
                    pump: Pump(reservoir: 45)
                ),
            startDate: formatter.date(from: "2022-07-18T22:00:00.000Z")! - 14400,
            maxWidth: 21600,
            maxSgv: 260
        )
        .previewLayout(.sizeThatFits)
    }
}
