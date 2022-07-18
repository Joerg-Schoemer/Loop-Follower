//
//  ChartView.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 14.07.22.
//

import SwiftUI


struct ChartView: View {
    
    @EnvironmentObject var modelData : ModelData

    let lower = Double(70)
    let upper = Double(180)
    let critical = Double(250)

    var body: some View {
        GeometryReader { geo in
            ZStack {
                let now = Date()
                let startDate = Calendar.current.date(byAdding: .hour, value: -4, to: now)!
                let endDate = Calendar.current.date(byAdding: .hour, value: 3, to: now)!
                let maxWidth : TimeInterval = endDate - startDate

                let height = geo.size.height

                let maxSgv = calcMaxSgv(modelData)

                let lowerThreshold: Double = (1 - (lower / maxSgv)) * height
                let upperThreshold: Double = (1 - (upper / maxSgv)) * height
                let criticalThreshold: Double = (1 - (critical / maxSgv)) * height

                GraphGridView(
                    upperThreshold: upperThreshold,
                    lowerThreshold: lowerThreshold,
                    criticalThreshold: criticalThreshold,
                    now: now,
                    startDate: startDate,
                    maxWidth: maxWidth
                )
                
                if let currentLoop = modelData.currentLoopData {
                    PredictionView(
                        currentLoop: currentLoop,
                        startDate: startDate,
                        maxWidth: maxWidth,
                        maxSgv: maxSgv
                    )
                }

                InsulinView(insulins: modelData.insulin, startDate: startDate, maxWidth: maxWidth)

                GlucoseView(
                    entries: modelData.entries,
                    startDate: startDate,
                    maxWidth: maxWidth,
                    maxSgv: maxSgv,
                    lowerThreshold: lowerThreshold,
                    upperThreshold: upperThreshold,
                    criticalThreshold: criticalThreshold
                )
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

extension CGPoint: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
    }
}

extension CGRect: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(origin.x)
        hasher.combine(origin.y)
        hasher.combine(size.width)
        hasher.combine(size.height)
    }
}

struct ChartView_Previews: PreviewProvider {
    static var previews: some View {
        ChartView()
            .environmentObject(ModelData(test: true))
            .previewLayout(.sizeThatFits)
    }
}
