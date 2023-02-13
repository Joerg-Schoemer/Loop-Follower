//
//  TempBasalView.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 10.08.22.
//

import SwiftUI

struct TempBasalView: View {
    
    let tempBasal : [TempBasal]
    let basal : [Basal]
    let startDate : Date
    let xMax : Double

    var body: some View {
        GeometryReader { geo in
            let xScale = geo.size.width / xMax
            let yScale : CGFloat = 320
            
            let points = estimatePoints(
                tempBasal: tempBasal,
                basal: basal,
                startDate: startDate,
                xScale: xScale,
                yScale: yScale,
                width: geo.size.width,
                height: geo.size.height
            )

            Path { path in
                path.move(to: points.first!)
                for point in points[1...] {
                    path.addLine(to: point)
                }
            }.fill(Color(.systemBlue.withAlphaComponent(0.6)))
        }
    }
}

func convertBasalToTempBasal(
    _ basals: [Basal],
    _ startOfDay: Date,
    _ offset: Double
) -> [TempBasal] {
    var tempBasal : [TempBasal] = []
    for i in 0..<(basals.count - 1) {
        let currentBasal = basals[i]
        let nextBasal = basals[i + 1]
        tempBasal.append(
            TempBasal(
                id: "",
                duration: (nextBasal.timeAsSeconds - currentBasal.timeAsSeconds) / 60,
                rate: currentBasal.value,
                timestamp: ISO8601DateFormatter().string(from: startOfDay + currentBasal.timeAsSeconds + offset)
            )
        )
    }
    let lastBasal = basals.last!
    tempBasal.append(
        TempBasal(
            id: "",
            duration: (86400 - lastBasal.timeAsSeconds) / 60,
            rate: lastBasal.value,
            timestamp: ISO8601DateFormatter().string(from: startOfDay + lastBasal.timeAsSeconds + offset)
        )
    )
    
    return tempBasal
}

func calculateTempBasal(basals : [Basal], startDate: Date) -> [TempBasal] {

    let startOfDay = Calendar.current.startOfDay(for: startDate)
    var tempBasal : [TempBasal] = []

    // first day
    tempBasal.append(contentsOf: convertBasalToTempBasal(basals, startOfDay, 0))
    // second day
    tempBasal.append(contentsOf: convertBasalToTempBasal(basals, startOfDay, 86400))

    return tempBasal
}

func reduceToView(_ points: [CGPoint], _ width: Double, _ height: Double, _ close : Bool = false) -> [CGPoint] {
    var startIndex = points.firstIndex(where: {$0.x >= 0})!
    if startIndex > 0 {
        startIndex -= 1
    }
    
    let endIndex = points.firstIndex(where: {$0.x >= width})!
    
    // get slice
    var a : [CGPoint] = Array(points[startIndex ... endIndex])
    
    // adjust first to 0
    if a.first!.x < 0 {
        let first = a.removeFirst()
        a.insert(CGPoint(x:0, y: first.y), at: 0)
        if first.y < height && close {
            a.insert(CGPoint(x:0, y: height), at: 0)
        }
    }
    
    // adjust last to width
    if a.last!.x > width {
        let last = a.removeLast()
        a.append(CGPoint(x: width, y: last.y))
        if last.y < height && close {
            a.append(CGPoint(x: width, y: height))
        }
    }
    
    return a
}

fileprivate func estimatePoints(
    tempBasal : [TempBasal],
    basal : [Basal],
    startDate : Date,
    xScale : Double,
    yScale : Double,
    width : Double,
    height : Double
) -> [CGPoint] {

    let basalAsTempBasal = calculateTempBasal(basals: basal, startDate: startDate)

    var tempBasalPoints : [CGPoint] = []
    for b in basalAsTempBasal {
        var lastEndDate : Date = b.startDate
        for t in tempBasal.filter({
            (b.startDate ... b.endDate).contains($0.endDate)
            || (b.startDate ... b.endDate).contains($0.startDate)
        }).sorted(by: {$0.startDate < $1.startDate}) {
            if (t.startDate < b.startDate) {
                tempBasalPoints.append(CGPoint(
                    x: (t.startDate - startDate) * xScale,
                    y: height - t.rate * yScale
                ))
                tempBasalPoints.append(CGPoint(
                    x: (t.endDate - startDate) * xScale,
                    y: height - t.rate * yScale
                ))
                lastEndDate = t.endDate
            } else {
                if lastEndDate < t.startDate {
                    tempBasalPoints.append(CGPoint(
                        x: (lastEndDate - startDate) * xScale,
                        y: height - b.rate * yScale
                    ))
                    tempBasalPoints.append(CGPoint(
                        x: (t.startDate - startDate) * xScale,
                        y: height - b.rate * yScale
                    ))
                }
                tempBasalPoints.append(CGPoint(
                    x: (t.startDate - startDate) * xScale,
                    y: height - t.rate * yScale
                ))
                tempBasalPoints.append(CGPoint(
                    x: (t.endDate - startDate) * xScale,
                    y: height - t.rate * yScale
                ))
                lastEndDate = t.endDate
            }
        }

        if lastEndDate < b.endDate {
            tempBasalPoints.append(CGPoint(
                x: (lastEndDate - startDate) * xScale,
                y: height - b.rate * yScale
            ))
            tempBasalPoints.append(CGPoint(
                x: (b.endDate - startDate) * xScale,
                y: height - b.rate * yScale
            ))
        }
    }
    
    return reduceToView(tempBasalPoints, width, height, true)
}

struct TempBasalView_Previews: PreviewProvider {
    static var previews: some View {
        TempBasalView(
            tempBasal: [
                TempBasal(
                    id: "",
                    duration: 20,
                    rate: 0.15,
                    timestamp: "2022-08-08T23:50:00Z"),
                TempBasal(
                    id: "",
                    duration: 20,
                    rate: 0.1,
                    timestamp: "2022-08-09T01:10:00Z"),
                TempBasal(
                    id: "",
                    duration: 20,
                    rate: 0.15,
                    timestamp: "2022-08-09T01:30:00Z"),
                TempBasal(
                    id: "",
                    duration: 20,
                    rate: 0,
                    timestamp: "2022-08-09T02:50:00Z"),
                TempBasal(
                    id: "",
                    duration: 20,
                    rate: 0,
                    timestamp: "2022-08-09T04:50:00Z"),
            ],
            basal: [
                Basal(value: 0.05, timeAsSeconds: 0),
                Basal(value: 0.10, timeAsSeconds: 14400),
                Basal(value: 0.05, timeAsSeconds: 25200),
                Basal(value: 0.10, timeAsSeconds: 61200),
                Basal(value: 0.05, timeAsSeconds: 64800),
            ],
            startDate: ISO8601DateFormatter().date(from: "2022-08-09T00:00:00Z")!,
            xMax: 25200
        )
        .previewInterfaceOrientation(.portrait)
    }
}
