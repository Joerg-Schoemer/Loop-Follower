//
//  CurrentValueView.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 13.07.22.
//

import SwiftUI

struct CurrentValueView: View {
    
    let currentEntry : Entry
    let delta : Int
    
    var dFormatter : RelativeDateTimeFormatter = RelativeDateTimeFormatter()
    
    fileprivate func formatDelta() -> String {
        if delta == 0 {
            return String(format: "±%d mg/dl", delta)
        }
        return String(format: "%+d mg/dl", delta)
    }
    
    var body: some View {
        let color = estimateFillColor(currentEntry.sgv)
        let textColor: Color = estimateTextColor(currentEntry.sgv)

        GeometryReader { geometry in
            let arrow = Path { path in
                let width : CGFloat = 50
                let height : CGFloat = 50
                let top : CGFloat = 2
                let up : CGFloat = 7

                let middle = geometry.size.width * 0.5

                path.addLines([
                    CGPoint(x: middle, y: top),
                    CGPoint(x: middle - width / 2, y: top + height),
                    CGPoint(x: middle, y: top + height - up),
                    CGPoint(x: middle + width / 2, y: top + height),
                    CGPoint(x: middle, y: top)
                ])
            }
            let length : CGFloat = 12
            ZStack {
                Circle()
                    .fill(color)
                Circle()
                    .strokeBorder(color, lineWidth: length)
                    .brightness(-0.38)
                    .shadow(radius: 8)

                ForEach(0..<7) { i in
                    Tick(length: length)
                        .rotation(.degrees(Double(30*i)))
                        .stroke(.black.opacity(0.7), lineWidth: 2)
                        .brightness(1.1)
                }.shadow(color: .black, radius: 2, x: 2, y: 2)
            }
            .padding(46)
            if currentEntry.direction != nil {
                ZStack {
                    arrow
                        .rotation(.degrees(currentEntry.directionDegree))
                        .fill(color)
                        .brightness(-0.15)
                        .shadow(radius: 2, x: 2, y: 2)
                    arrow
                        .rotation(.degrees(currentEntry.directionDegree))
                        .stroke(color, lineWidth: 2)
                        .brightness(-0.10)
                        
                }
            }
        }
        .frame(width: 300, height: 300)
        .overlay {
            VStack(spacing: -5.0) {
                Text(dFormatter.localizedString(fromTimeInterval: currentEntry.date - Date()))
                    .fontWeight(.light)
                Text(String(currentEntry.sgv))
                    .font(.system(size: 64, weight: .heavy, design: .default))
                Text(formatDelta())
                    .fontWeight(.bold)
            }
            .foregroundColor(textColor)
            .shadow(radius: 2, x: 5, y:5)
        }
    }
}

private func estimateFillColor(_ sgv : Int) -> Color {
    if (sgv < 70) {
        return .red
    }
    if (sgv >= 250) {
        return .red
    }
    if (sgv >= 180) {
        return .yellow
    }
    
    return .green
}

private func estimateTextColor(_ sgv : Int) -> Color {
    if (sgv < 70 || sgv >= 250) {
        return .white
    }
    
    return .black
}

struct Tick : Shape {
    
    let length : CGFloat
    let gap : CGFloat = 2
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY + gap))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY + length - gap))
        
        return path
    }
}

struct CurrentValueView_Previews: PreviewProvider {
    static var modelData = ModelData()
    static let df = ISO8601DateFormatter([.withFractionalSeconds])
    static let date = Date() + -120
    
    static var previews: some View {
        let sgvs = [ 50, 70, 101, 180, 202, 250, 303 ]
        let dirs = Direction.allCases
        VStack {
            CurrentValueView(
                currentEntry: Entry(
                    id: "wurscht",
                    sgv: 44,
                    direction: nil,
                    dateString: df.string(from: date)
                ),
                delta: Int.random(in: -10...10)
            )
            
            ForEach(0 ..< dirs.count, id: \.self) { i in
                let dir = dirs[i]
                let sgv = sgvs[i]
                let date = Date() + Double.random(in: -300 ... -10)
                CurrentValueView(
                    currentEntry: Entry(
                        id: "wurscht",
                        sgv: sgv,
                        direction: dir,
                        dateString: df.string(from: date)
                    ),
                    delta: Int.random(in: -10...10)
                )
            }
        }.previewLayout(.sizeThatFits)
    }
}
