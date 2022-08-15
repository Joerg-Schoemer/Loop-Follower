//
//  ChartView.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 14.07.22.
//

import SwiftUI


struct ChartView: View {
    
    @EnvironmentObject var modelData : ModelData

    let criticalLow = 50.0
    let lower = 70.0
    let upper = 180.0
    let criticalHigh = 250.0

    var now = Date()

    var body: some View {
        GeometryReader { geo in
            let startDate = Calendar.current.date(byAdding: .hour, value: -4, to: now)!
            let endDate = Calendar.current.date(byAdding: .hour, value: 3, to: now)!
            
            let xMax : TimeInterval = endDate - startDate
            let yMax = estimateYMax(modelData)
            
            GraphGridView(
                criticalHigh: criticalHigh,
                upper: upper,
                lower: lower,
                criticalLow: criticalLow,
                now: now,
                startDate: startDate,
                xMax: xMax,
                yMax: yMax
            )
            
            if let predicted = modelData.currentLoopData?.loop.predicted {
                PredictionView(
                    predicted: predicted,
                    startDate: startDate,
                    xMax: xMax,
                    yMax: yMax
                )
            }
            
            if let basal = modelData.profile?.basal {
                ScheduledBasalView(
                    basal: basal,
                    startDate: startDate,
                    xMax: xMax
                )
                if let tempBasal = modelData.tempBasal {
                    TempBasalView(
                        tempBasal: tempBasal,
                        basal: basal,
                        startDate: startDate,
                        xMax: xMax
                    )
                }
            }

            CarbView(
                carbs: modelData.carbs,
                startDate: startDate,
                xMax: xMax
            )

            InsulinView(
                insulins: modelData.insulin,
                startDate: startDate,
                xMax: xMax
            )
            
            GlucoseView(
                entries: modelData.entries,
                startDate: startDate,
                xMax: xMax,
                yMax: yMax,
                critical: criticalHigh,
                upper: upper,
                lower: lower,
                criticalLow: criticalLow
            )
        }
    }
}

func estimateYMax(_ data: ModelData) -> Double {
    var yMax : Double = 250
    if let v = data.currentLoopData?.loop.predicted?.values {
        yMax = max(yMax, v.max()!)
    }
    if data.entries.count > 0 {
        yMax = max(yMax, data.entries.map { Double($0.sgv) }.max()!)
    }
    
    return yMax + 10
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
        ChartView(
            now: ISO8601DateFormatter().date(from: "2022-07-19T06:37:55Z")!
        )
        .environmentObject(ModelData(test: true))
        .previewLayout(.sizeThatFits)
    }
}
