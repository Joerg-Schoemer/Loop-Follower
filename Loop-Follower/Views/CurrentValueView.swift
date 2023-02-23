//
//  CurrentValueView.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 13.07.22.
//

import SwiftUI

struct CurrentValueView: View {
    
    @Binding var currentDate : Date?
    @Binding var currentEntry : Entry?

    @State private var progress = 0.0

    let delta : Int?

    let criticalMin : Int
    let criticalMax : Int

    let rangeMin : Int
    let rangeMax : Int
    
    fileprivate func formatDelta() -> String {
        if let delta = self.delta {
            if delta == 0 {
                return String(format: "±%d mg/dl", delta)
            }
            return String(format: "%+d mg/dl", delta)
        } else {
            return "? mg/dl"
        }
    }
    
    var body: some View {
        if let currentEntry = currentEntry {
            let color = estimateBackgroundColorBySgv(currentEntry, currentDate!)
            let textColor = estimateTextColorBySgv(currentEntry, currentDate!)
            
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
                
                Indicator(color: color)
                    .padding(46)
                
                if let directionDegree = currentEntry.directionDegree {
                    arrow
                        .rotation(.degrees(directionDegree))
                        .fill(color)
                        .brightness(-0.15)
                        .shadow(radius: 2, x: 2, y: 2)
                    arrow
                        .rotation(.degrees(directionDegree))
                        .stroke(color, lineWidth: 2)
                        .brightness(-0.10)
                }
            }
            .frame(width: 300, height: 300)
            .overlay {
                VStack {
                    Text(currentEntry.date.formatted(date: .omitted, time: .standard))
                    ProgressView(value: progress, total: 300) {
                        Text(String(currentEntry.sgv))
                            .frame(width: 150)
                    }
                    .font(.system(size: 72, weight: .bold, design: .default))
                    .onAppear {
                        progress = progressValue()
                        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
                            progress = progressValue()
                        }
                    }
                    .onChange(of: self.currentEntry!) { value in
                        progress = progressValue()
                    }
                    .frame(width: 150)
                    Text(formatDelta())
                }
                .font(.headline)
                .foregroundColor(textColor)
                .shadow(radius: 2, x: 5, y:5)
            }
        }
    }
    
    func estimateBackgroundColorBySgv(_ entry : Entry, _ date: Date) -> Color {
        if (Calendar.current.dateComponents([.minute], from: entry.date, to: date).minute! > 5) {
            return Color(.systemGray)
        }

        if entry.sgv < criticalMin || entry.sgv >= criticalMax {
            return Color(.systemRed)
        }
        
        if entry.sgv < rangeMin || entry.sgv > rangeMax {
            return Color(.systemYellow)
        }
        
        return Color(.systemGreen)
    }

    private func estimateTextColorBySgv(_ entry : Entry, _ date: Date) -> Color {
        if (entry.sgv < criticalMin || entry.sgv >= criticalMax || Calendar.current.dateComponents([.minute], from: entry.date, to: date).minute! > 6) {
            return .white
        }
        
        return .black
    }
    
    private func progressValue() -> Double {
        let diff = min(Date.now - currentEntry!.date, 300)
        return diff
    }
}


struct Indicator : View {
    let length : CGFloat = 10
    let color : Color

    var body: some View {
        Circle()
            .fill(color)
        Circle()
            .strokeBorder(color, lineWidth: length)
            .brightness(-0.38)
            .shadow(radius: 8)
        
        ForEach(0 ..< 7) { i in
            Tick(length: length)
                .rotation(.degrees(Double(30*i)))
                .stroke(.black.opacity(0.7), lineWidth: 2)
                .brightness(1.1)
        }
        .shadow(color: .black, radius: 2, x: 2, y: 2)
    }
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
    static let date = Date() + -720
    @State static var currentDate : Date? = Date.now
    
    static var previews: some View {
        let sgvs = [ 50, 70, 101, 180, 250, 202, 303, 100 ]
        let dirs = Direction.allCases

        ScrollView {
            CurrentValueView(
                currentDate: $currentDate,
                currentEntry: .constant(Entry(
                    id: "wurscht",
                    sgv: 44,
                    direction: nil,
                    dateString: df.string(from: date)
                )),
                delta: nil,
                criticalMin: 55,
                criticalMax: 260,
                rangeMin: 70,
                rangeMax: 180
            )
            
            ForEach(0 ..< dirs.count, id: \.self) { i in
                let dir = dirs[i]
                let sgv = sgvs[i]
                let date = Date() + Double.random(in: -300 ... -10)
                CurrentValueView(
                    currentDate: $currentDate,
                    currentEntry: .constant(Entry(
                        id: "wurscht",
                        sgv: sgv,
                        direction: dir,
                        dateString: df.string(from: date)
                    )),
                    delta: Int.random(in: -10...10),
                    criticalMin: 55,
                    criticalMax: 260,
                    rangeMin: 70,
                    rangeMax: 180
                )
            }
        }.previewLayout(.sizeThatFits)
    }
}
