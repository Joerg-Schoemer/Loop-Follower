//
//  BloodGlucoseChart.swift
//  Loop-Follower
//
//  Created by Schömer, Jörg on 14.02.23.
//

import SwiftUI
import Charts

struct BloodGlucoseChart: View {

    @EnvironmentObject var modelData : ModelData
    
    let dashedLineStyle : [CGFloat] = [5, 2]
    
    let criticalMin : Int
    let criticalMax : Int
    
    let rangeMin : Int
    let rangeMax : Int

    let series: KeyValuePairs<String, Color> = [
        "Blood Glucose": Color(.systemBlue),
        "Prediction": Color(.systemPurple),
        "Insulin": Color(.systemOrange),
        "Carbs": Color(.systemTeal),
    ]

    var body: some View {
        VStack {
            Text("Blood Glucose")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Chart {
                if let currentDate = modelData.currentDate {
                    RuleMark(
                        x: .value("now", currentDate)
                    )
                    .lineStyle(StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color(.systemGray))
                }
                
                // Zielbereich
                RuleMark(
                    y: .value("min", rangeMin)
                )
                .lineStyle(StrokeStyle(dash: dashedLineStyle))
                .foregroundStyle(.green)
                RuleMark(
                    y: .value("max", rangeMax)
                )
                .lineStyle(StrokeStyle(dash: dashedLineStyle))
                .foregroundStyle(.green)
                
                // Kritischer Bereich
                RuleMark(
                    y: .value("critical min", criticalMin)
                )
                .lineStyle(StrokeStyle(dash: dashedLineStyle))
                .foregroundStyle(.red)
                RuleMark(
                    y: .value("critical max", criticalMax)
                )
                .lineStyle(StrokeStyle(dash: dashedLineStyle))
                .foregroundStyle(.red)
                
                ForEach(modelData.insulin) { insulin in
                    BarMark(
                        x: .value("timestamp", insulin.date),
                        y: .value("insulin", insulin.insulin * 100)
                    )
                    .foregroundStyle(by: .value("category", "Insulin"))
                }
                ForEach(modelData.carbs) { carb in
                    BarMark(
                        x: .value("timestamp", carb.date),
                        y: .value("carbs", carb.carbs * 2)
                    )
                    .annotation(position: .topTrailing) {
                        Text(carb.description)
                            .font(.footnote)
                    }
                    .foregroundStyle(by: .value("category", "Carbs"))
                }
                
                let prediction = modelData.currentLoopData?.loop.predicted
                if let predictionDate = prediction?.date {
                    RuleMark(
                        x: .value("prediction", predictionDate)
                    )
                    .lineStyle(StrokeStyle(dash: dashedLineStyle, dashPhase: 3))
                    .foregroundStyle(Color(.systemPurple))
                    
                    ForEach(
                        predictedValues(
                            startDate: predictionDate,
                            values: (prediction?.values)!
                        )
                    ) { entry in
                        LineMark(
                            x: .value("timestamp", entry.date),
                            y: .value("BG", entry.sgv),
                            series: .value("category", "Prediction")
                        )
                        .foregroundStyle(Color(.systemPurple))
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(dash: [5, 2]))
                    }
                }
                
                ForEach(modelData.entries) { entry in
                    LineMark(
                        x: .value("timestamp", entry.date),
                        y: .value("BG", entry.sgv),
                        series: .value("category", "Blood Glucose")
                    )
                    .symbol {
                        Circle()
                            .fill(estimateColorBySgv(entry.sgv))
                            .frame(width: 5)
                    }
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartForegroundStyleScale(series)
            .chartLegend() {
                HStack {
                    ForEach(series, id: \.key) { key, value in
                        Circle()
                            .fill(value)
                            .frame(width: 9)
                        Text(NSLocalizedString(key, comment: "Legend of blood glucose chart"))
                            .font(.footnote)
                            .foregroundColor(Color(.systemGray))
                    }
                }
            }
        }
        .padding([.top, .bottom])
    }
    
    func estimateColorBySgv(_ sgv : Int) -> Color {
        if sgv < criticalMin || sgv >= criticalMax {
            return Color(.systemRed)
        }
        
        if sgv < rangeMin || sgv > rangeMax {
            return Color(.systemYellow)
        }
        
        return Color(.systemGreen)
    }
}

func predictedValues(startDate: Date, values: [Double]) -> [Entry] {
    var currentDate = startDate
    let formatter = ISO8601DateFormatter(.withFractionalSeconds)
    
    let predictions : [Entry] = values.map {
        let entry = Entry(id: UUID().description, sgv: Int($0), dateString: formatter.string(from: currentDate))
        currentDate = Calendar.current.date(byAdding: .minute, value: 5, to: currentDate)!
        return entry
    }
    
    if let lastIndex = predictions.firstIndex(
        where: {
            $0.date > Calendar.current.date(byAdding: .hour, value: 3, to: startDate)!
        }
    ) {
        return Array(predictions.prefix(lastIndex))
    }

    return predictions
}

struct BloodGlucoseChart_Previews: PreviewProvider {
    static var previews: some View {
        BloodGlucoseChart(
            criticalMin: 55,
            criticalMax: 260,
            rangeMin: 70,
            rangeMax: 180
        )
        .environmentObject(ModelData(test: true))
    }
}
