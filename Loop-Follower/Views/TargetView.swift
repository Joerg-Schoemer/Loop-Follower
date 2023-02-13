//
//  TargetView.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 25.08.22.
//

import SwiftUI

struct TargetView: View {
    let profile : Profile
    let startDate : Date
    let xMax : Double
    let yMax : Double
    
    var body: some View {
        GeometryReader { geo in

            let xScale : CGFloat = geo.size.width / xMax
            let yScale : CGFloat = geo.size.height / yMax
            
            let targets = convertTargets(
                profile,
                startDate,
                xScale,
                yScale,
                geo.size
            )
            
            Path { path in
                for target in targets {
                    path.addRect(target)
                }
            }.fill(Color(.systemBlue.withAlphaComponent(0.5)))
        }
    }
}

func convert(_ profile : Profile ,_ startDate : Date, _ offset : Double) -> [TargetMM] {
    var targets : [TargetMM] = []
    
    var prevTargetHigh : Target = profile.target_high.first!
    var prevTargetLow : Target = profile.target_low.first!
    
    let startOfDay = Calendar.current.startOfDay(for: startDate)

    for i in 1..<profile.target_low.count {
        let currentLow = profile.target_low[i]
        let currentHigh = profile.target_high[i]

        targets.append(TargetMM(minValue: prevTargetLow.value, maxValue: prevTargetHigh.value, start: startOfDay + prevTargetLow.timeAsSeconds + offset, end: startOfDay + currentLow.timeAsSeconds + offset))
        
        prevTargetLow = currentLow
        prevTargetHigh = currentHigh
    }

    targets.append(
        TargetMM(
            minValue: prevTargetLow.value,
            maxValue: prevTargetHigh.value,
            start: startOfDay + prevTargetLow.timeAsSeconds + offset,
            end: startOfDay + 86400 + offset
        )
    )
    
    return targets
}

func convertTargets(
    _ profile : Profile,
    _ startDate : Date,
    _ xScale : Double,
    _ yScale : Double,
    _ size : CGSize
) -> [CGRect] {
    var points : [CGRect] = []

    for t in convert(profile, startDate, 0) {
        points.append(
            CGRect(
                x: (t.start - startDate) * xScale,
                y: size.height - t.maxValue * yScale,
                width: (t.end - t.start) * xScale,
                height: (t.maxValue - t.minValue) * yScale
            )
        )
    }
    for t in convert(profile, startDate, 86400) {
        points.append(
            CGRect(
                x: (t.start - startDate) * xScale,
                y: size.height - t.maxValue * yScale,
                width: (t.end - t.start) * xScale,
                height: (t.maxValue - t.minValue) * yScale
            )
        )
    }

    points.removeAll(
        where: {
            $0.origin.x + $0.size.width < 0 || $0.origin.x > size.width
        }
    )
    if let first = points.first {
        if first.origin.x < 0 {
            points.removeFirst()
            points.insert(
                CGRect(
                    x: 0,
                    y: first.origin.y,
                    width: (first.size.width + first.origin.x),
                    height: first.size.height
                ),
                at: 0
            )
        }
    }

    if let last = points.last {
        if last.origin.x + last.size.width > size.width {
            points.removeLast()
            points.append(CGRect(
                x: last.origin.x,
                y: last.origin.y,
                width: size.width - last.origin.x,
                height: last.size.height
            ))
        }
    }

    return points
}

struct TargetMM {
    let minValue : Double
    let maxValue : Double
    let start : Date
    let end : Date
}

struct TargetView_Previews: PreviewProvider {
    static var previews: some View {
        TargetView(
            profile: Profile(
                basal: [],
                target_low: [
                    Target(value: 110, timeAsSeconds: 0),
                    Target(value: 125, timeAsSeconds: 46800),
                    Target(value: 110, timeAsSeconds: 61200),
                ],
                target_high: [
                    Target(value: 125, timeAsSeconds: 0),
                    Target(value: 140, timeAsSeconds: 46800),
                    Target(value: 125, timeAsSeconds: 61200),
                ],
                sens: [],
                carbratio: []
            ),
            startDate: ISO8601DateFormatter().date(from: "2022-08-25T08:00:00Z")!,
            xMax: 32400,
            yMax: 260
        )
        .previewInterfaceOrientation(.portrait)
    }
}
