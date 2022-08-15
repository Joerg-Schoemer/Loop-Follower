//
//  GraphGridView.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 18.07.22.
//

import SwiftUI

struct GraphGridView: View {
    
    let criticalHigh : Double
    let upper : Double
    let lower : Double
    let criticalLow : Double

    let now : Date
    let startDate : Date

    let xMax : TimeInterval
    let yMax : Double

    var body: some View {
        GeometryReader { geo in
            Rectangle()
                .stroke(.gray, lineWidth: 1)
            let width = geo.size.width
            let height = geo.size.height
            let xScale = width / xMax
            
            let criticalHighThreshold = (1 - criticalHigh / yMax) * height
            let upperThreshold = (1 - upper / yMax) * height
            let lowerThreshold = (1 - lower / yMax) * height
            let criticalLowThreshold = (1 - criticalLow / yMax) * height

            // in range
            Rectangle()
                .offset(x: 0, y: upperThreshold)
                .size(width: width, height: (lowerThreshold - upperThreshold))
                .fill(.green.opacity(0.2))
            
            // critical threshold
            Path { path in
                path.move(to: CGPoint(x: 0, y: criticalHighThreshold))
                path.addLine(to: CGPoint(x: width, y: criticalHighThreshold))
            }.stroke(.red, style: StrokeStyle(lineWidth: 1, dash: [4]))
            
            // upper threshold
            Path { path in
                path.move(to: CGPoint(x: 0, y: upperThreshold))
                path.addLine(to: CGPoint(x: width, y: upperThreshold))
            }.stroke(.yellow, lineWidth: 1)
            
            // lower threshold
            Path { path in
                path.move(to: CGPoint(x: 0, y: lowerThreshold))
                path.addLine(to: CGPoint(x: width, y: lowerThreshold))
            }.stroke(.yellow, lineWidth: 1)
            
            // critical lower threshold
            Path { path in
                path.move(to: CGPoint(x: 0, y: criticalLowThreshold))
                path.addLine(to: CGPoint(x: width, y: criticalLowThreshold))
            }.stroke(.red, style: StrokeStyle(lineWidth: 1, dash: [4]))
            
            // current time
            Path { path in
                path.move(to: CGPoint(x: (now - startDate) * xScale, y: 0))
                path.addLine(to: CGPoint(x: (now - startDate) * xScale, y: height))
            }.stroke(.gray, lineWidth: 1)
            
            // previouse hours
            Path { path in
                var date = Calendar.current.date(byAdding: .hour, value: -1, to: now)!
                while date > startDate {
                    path.move(to: CGPoint(x: (date - startDate) * xScale, y: 0))
                    path.addLine(to: CGPoint(x: (date - startDate) * xScale, y: height))
                    date = Calendar.current.date(byAdding: .hour, value: -1, to: date)!
                }
            }.stroke(.teal, style: StrokeStyle(lineWidth: 1, dash: [4]))

            // next hours
            Path { path in
                var date = Calendar.current.date(byAdding: .hour, value: 1, to: now)!
                while date < startDate + xMax {
                    path.move(to: CGPoint(x: (date - startDate) * xScale, y: 0))
                    path.addLine(to: CGPoint(x: (date - startDate) * xScale, y: height))
                    date = Calendar.current.date(byAdding: .hour, value: 1, to: date)!
                }
            }.stroke(.purple, style: StrokeStyle(lineWidth: 1, dash: [4]))
        }
    }
}

struct GraphGridView_Previews: PreviewProvider {
    static var previews: some View {
        GraphGridView(
            criticalHigh: 250,
            upper: 180,
            lower: 70,
            criticalLow: 50,
            now: Date(),
            startDate: Date() - 14400,
            xMax: 25200,
            yMax: 260
        )
            .previewLayout(.sizeThatFits)
    }
}
