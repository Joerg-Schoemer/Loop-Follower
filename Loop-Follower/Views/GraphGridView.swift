//
//  GraphGridView.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 18.07.22.
//

import SwiftUI

struct GraphGridView: View {
    
    let critical : Double
    let upper : Double
    let lower : Double

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
            
            let criticalThreshold = (1 - critical / yMax) * height
            let upperThreshold = (1 - upper / yMax) * height
            let lowerThreshold = (1 - lower / yMax) * height

            // in range
            Rectangle()
                .offset(x: 0, y: upperThreshold)
                .size(width: width, height: (lowerThreshold - upperThreshold))
                .fill(.green.opacity(0.2))
            
            // critical threshold
            Path { path in
                path.move(to: CGPoint(x: 0, y: criticalThreshold))
                path.addLine(to: CGPoint(x: width, y: criticalThreshold))
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
            }.stroke(.red, lineWidth: 1)
            
            // current time
            Path { path in
                path.move(to: CGPoint(x: (now - startDate) / xMax * width, y: 0))
                path.addLine(to: CGPoint(x: (now - startDate) / xMax * width, y: height))
            }.stroke(.gray, lineWidth: 1)
            
            // previouse hours
            Path { path in
                var date = Calendar.current.date(byAdding: .hour, value: -1, to: now)!
                while date > startDate {
                    path.move(to: CGPoint(x: (date - startDate) / xMax * width, y: 0))
                    path.addLine(to: CGPoint(x: (date - startDate) / xMax * width, y: height))
                    date = Calendar.current.date(byAdding: .hour, value: -1, to: date)!
                }
            }.stroke(.teal, style: StrokeStyle(lineWidth: 1, dash: [4]))

            // next hours
            Path { path in
                var date = Calendar.current.date(byAdding: .hour, value: 1, to: now)!
                while date < startDate + xMax {
                    path.move(to: CGPoint(x: (date - startDate) / xMax * width, y: 0))
                    path.addLine(to: CGPoint(x: (date - startDate) / xMax * width, y: height))
                    date = Calendar.current.date(byAdding: .hour, value: 1, to: date)!
                }
            }.stroke(.purple, style: StrokeStyle(lineWidth: 1, dash: [4]))
        }
    }
}

struct GraphGridView_Previews: PreviewProvider {
    static var previews: some View {
        GraphGridView(
            critical: 250,
            upper: 180,
            lower: 70,
            now: Date(),
            startDate: Date() - 14400,
            xMax: 25200,
            yMax: 260
        )
            .previewLayout(.sizeThatFits)
    }
}
