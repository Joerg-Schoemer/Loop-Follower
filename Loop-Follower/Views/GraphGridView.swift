//
//  GraphGridView.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 18.07.22.
//

import SwiftUI

struct GraphGridView: View {
    
    let upperThreshold : CGFloat
    let lowerThreshold : CGFloat
    let criticalThreshold : CGFloat
    let now : Date
    let startDate : Date

    let maxWidth : CGFloat
    
    var body: some View {
        GeometryReader { geo in
            Rectangle()
                .stroke(.gray, lineWidth: 1)
            let width = geo.size.width
            let height = geo.size.height

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
            }.stroke(.yellow, lineWidth: 3)
            
            // lower threshold
            Path { path in
                path.move(to: CGPoint(x: 0, y: lowerThreshold))
                path.addLine(to: CGPoint(x: width, y: lowerThreshold))
            }.stroke(.red, lineWidth: 3)
            
            // current time
            Path { path in
                path.move(to: CGPoint(x: (now - startDate) / maxWidth * width, y: 0))
                path.addLine(to: CGPoint(x: (now - startDate) / maxWidth * width, y: height))
            }.stroke(.gray, lineWidth: 1)
            
            // previouse hours
            Path { path in
                for h in 1 ... 3 {
                    let date = Calendar.current.date(byAdding: .hour, value: -h, to: now)!
                    path.move(to: CGPoint(x: (date - startDate) / maxWidth * width, y: 0))
                    path.addLine(to: CGPoint(x: (date - startDate) / maxWidth * width, y: height))
                }
            }.stroke(.teal, style: StrokeStyle(lineWidth: 1, dash: [4]))

            // next hours
            Path { path in
                for h in 1 ... 1 {
                    let date = Calendar.current.date(byAdding: .hour, value: h, to: now)!
                    
                    path.move(to: CGPoint(x: (date - startDate) / maxWidth * width, y: 0))
                    path.addLine(to: CGPoint(x: (date - startDate) / maxWidth * width, y: height))
                    
                }
            }.stroke(.purple, style: StrokeStyle(lineWidth: 1, dash: [4]))
            
        }
    }
}

struct GraphGridView_Previews: PreviewProvider {
    static var previews: some View {
        GraphGridView(upperThreshold: 180, lowerThreshold: 70, criticalThreshold: 250, now: Date(), startDate: Date() + -100, maxWidth: 120)
            .previewLayout(.sizeThatFits)
    }
}
