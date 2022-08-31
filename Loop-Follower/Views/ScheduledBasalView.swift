//
//  ScheduledBasal.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 09.08.22.
//

import SwiftUI

struct ScheduledBasalView: View {
    let basal : [Basal]
    let startDate : Date
    let xMax : TimeInterval
    
    var body: some View {
        GeometryReader { geo in

            let xScale = geo.size.width / xMax
            let yScale : CGFloat = 320

            let basals = estimateScheduledBasal(
                basal: basal,
                startDate: startDate,
                xScale: xScale,
                yScale: yScale,
                width: geo.size.width,
                height: geo.size.height
            )
            
            Path { path in
                path.move(to: basals.first!)
                for basal in basals[1...] {
                    path.addLine(to: basal)
                }
            }.stroke(.blue, style: StrokeStyle(dash: [4]))
        }
    }
}

fileprivate func estimateScheduledBasal(
    basal : [Basal],
    startDate : Date,
    xScale : Double,
    yScale : Double,
    width : Double,
    height : Double
) -> [CGPoint] {
    var basalPoints : [CGPoint] = []
    
    let basals = calculateTempBasal(basals: basal, startDate: startDate)
    for b in basals {
        basalPoints.append(CGPoint(
            x: (b.startDate - startDate) * xScale,
            y: height - b.rate * yScale
        ))
        basalPoints.append(CGPoint(
            x: (b.endDate - startDate) * xScale,
            y: height - b.rate * yScale
        ))
    }

    return reduceToView(basalPoints, width, height)
}

struct ScheduledBasal_Previews: PreviewProvider {
    static var previews: some View {
        ScheduledBasalView(
            basal: [
                Basal(value: 0.05, timeAsSeconds: 0),
                Basal(value: 0.10, timeAsSeconds: 14400),
                Basal(value: 0.05, timeAsSeconds: 25200),
                Basal(value: 0.10, timeAsSeconds: 61200),
                Basal(value: 0.05, timeAsSeconds: 64800),
            ],
            startDate: ISO8601DateFormatter().date(from: "2022-07-19T00:00:00Z")!,
            xMax: 32400)
        .previewInterfaceOrientation(.portrait)
    }
}
