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
                for basal in basals {
                    path.addRect(basal)
                }
            }.fill(Color(.blue.withAlphaComponent(0.1)))
        }
    }
}

fileprivate func createRects(
    _ basal: [Basal],
    _ basalRects: inout [CGRect],
    _ startOfDay: Date,
    _ startDate: Date,
    _ xScale: Double,
    _ height: Double,
    _ yScale: Double,
    _ offset: Double) {
    for i in 0..<(basal.count - 1) {
        basalRects.append(CGRect(
            x: ((startOfDay - startDate) + basal[i].timeAsSeconds + offset) * xScale,
            y: height - basal[i].value * yScale,
            width: (basal[i + 1].timeAsSeconds - basal[i].timeAsSeconds) * xScale,
            height: basal[i].value * yScale))
    }
    
    let lastBasal = basal.last!
    basalRects.append(CGRect(
        x: ((startOfDay - startDate) + lastBasal.timeAsSeconds + offset) * xScale,
        y: height - lastBasal.value * yScale,
        width: (86400 - lastBasal.timeAsSeconds) * xScale,
        height: lastBasal.value * yScale))
}

fileprivate func estimateScheduledBasal(
    basal : [Basal],
    startDate : Date,
    xScale : Double,
    yScale : Double,
    width : Double,
    height : Double
) -> [CGRect] {

    let startOfDay = Calendar.current.startOfDay(for: startDate)
    var basalRects : [CGRect] = []
    
    createRects(basal, &basalRects, startOfDay, startDate, xScale, height, yScale, 0)
    createRects(basal, &basalRects, startOfDay, startDate, xScale, height, yScale, 86400)

    basalRects.removeAll(where: {$0.origin.x > width || $0.origin.x + $0.size.width <= 0})

    if let first = basalRects.first {
        if (first.origin.x < 0) {
            basalRects.removeFirst()
            basalRects.insert(
                CGRect(
                    x: 0,
                    y: first.origin.y,
                    width: first.size.width + first.origin.x,
                    height: first.size.height
                ),
                at: 0
            )
        }
    }
    
    if let last = basalRects.last {
        let delta = width - (last.origin.x + last.size.width)
        if (delta < 0) {
            basalRects.removeLast()
            basalRects.append(
                CGRect(
                    x: last.origin.x,
                    y: last.origin.y,
                    width: last.size.width + delta,
                    height: last.size.height
                ))
        }
    }

    return basalRects
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
            xMax: 25200)
        .previewInterfaceOrientation(.landscapeLeft)
    }
}
