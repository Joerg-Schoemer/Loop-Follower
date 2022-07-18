//
//  ChartView.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 14.07.22.
//

import SwiftUI


struct ChartView: View {
    
    @EnvironmentObject var modelData : ModelData
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                let now = Date()
                let startDate = Calendar.current.date(byAdding: .hour, value: -4, to: now)!
                let endDate = Calendar.current.date(byAdding: .hour, value: 2, to: now)!
                let maxWidth : TimeInterval = endDate - startDate
                let width = geo.size.width
                let height = geo.size.height
                let lower = Double(70)
                let upper = Double(180)
                let critical = Double(250)
                
                let maxSgv = calcMaxSgv(modelData)
                
                let criticalThreshold: Double = height - (critical / maxSgv) * height
                let upperThreshold: Double = height - (upper / maxSgv) * height
                let lowerThreshold: Double = height - (lower / maxSgv) * height

                GraphGridView(
                    upperThreshold: upperThreshold,
                    lowerThreshold: lowerThreshold,
                    criticalThreshold: criticalThreshold,
                    now: now,
                    startDate: startDate,
                    maxWidth: maxWidth)
                
                if let currentLoop = modelData.currentLoopData {
                    if let predicted = currentLoop.loop.predicted {
                        if !predicted.values.isEmpty {
                            
                            let maxSgv = calcMaxSgv(modelData)
                            
                            var date = predicted.date
                            let sgvs : [CGPoint] = predicted.values.map {
                                let p = CGPoint(
                                    x: (date - startDate) / maxWidth * width,
                                    y: height - (Double($0) / maxSgv) * height
                                )
                                date = Calendar.current.date(byAdding: .minute, value: 5, to: date)!
                                return p
                            }
                            ForEach(sgvs, id: \.self) { sgv in
                                Path { path in
                                    if 0 < sgv.x && sgv.x < width {
                                        path.addEllipse(in: CGRect(x: sgv.x, y: sgv.y, width: 6, height: 6))
                                    }
                                }.fill(.purple)
                            }
                        }
                    }
                }

                if !modelData.entries.isEmpty {
                    
                    let sgvs : [CGPoint] = modelData.entries.map {
                        return CGPoint(
                            x: ($0.date - startDate) / maxWidth * width,
                            y: height - (Double($0.sgv) / maxSgv) * height
                        )
                    }
                    
                    ForEach(sgvs, id: \.self) { sgv in
                        Path { path in
                            if 0 < sgv.x && sgv.x < width {
                                path.addEllipse(in: CGRect(x: sgv.x, y: sgv.y, width: 6, height: 6))
                            }
                        }.fill(
                            estimateColorBySgv(
                                sgv: sgv.y,
                                lower: lowerThreshold,
                                upper: upperThreshold,
                                critical: criticalThreshold
                            ))
                    }
                }
            }
        }
    }
}

func calcMaxSgv(_ data: ModelData) -> Double {
    var maxSgv : Double = 0
    if let v = data.currentLoopData?.loop.predicted?.values {
        maxSgv = v.max()! + 10
    }
    if data.entries.count > 0 {
        maxSgv = max(maxSgv, data.entries.map { Double($0.sgv) }.max()! + 10)
    }
    
    return max(maxSgv, 260)
}

func estimateColorBySgv(sgv : Double, lower: Double, upper : Double, critical : Double) -> Color {
    if sgv >= lower || sgv <= critical {
        return .red
    }
    
    if sgv < upper {
        return .yellow
    }
    
    return .green
}

extension CGPoint: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
    }
}

struct ChartView_Previews: PreviewProvider {
    static var previews: some View {
        ChartView()
            .environmentObject(ModelData(test: true))
            .previewLayout(.sizeThatFits)
    }
}
