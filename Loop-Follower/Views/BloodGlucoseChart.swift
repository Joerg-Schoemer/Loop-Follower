//
//  BloodGlucoseChart.swift
//  Loop-Follower
//
//  Created by Schömer, Jörg on 14.02.23.
//

import SwiftUI
import Charts

struct BloodGlucoseChart: View {

    let dashedLineStyle : [CGFloat] = [7, 3]
    let barWidth : Int = 3
    
    let currentDate : Date?
    
    let prediction: Predicted?
    let insulin : [CorrectionBolus]
    let carbs : [CarbCorrection]
    let entries : [Entry]
    
    let criticalMin : Int
    let criticalMax : Int
    
    let rangeMin : Int
    let rangeMax : Int

    let series: KeyValuePairs<String, Color> = [
        "Blood Glucose": Color(.systemBlue),
        "Prediction": Color(.systemPurple),
        "Insulin": Color(.systemOrange),
        "Carbs": Color(.systemGreen),
    ]

    var body: some View {
        VStack {
            Text("Blood Glucose")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Chart {
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
                
                if let currentDate = currentDate {
                    RuleMark(
                        x: .value("now", currentDate)
                    )
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    .foregroundStyle(Color(.systemYellow).opacity(0.75))
                }

                ForEach(insulin) { insulin in
                    BarMark(
                        x: .value("timestamp", truncateMinutes(date: insulin.date)),
                        y: .value("insulin", insulin.insulin * 100),
                        width: MarkDimension(integerLiteral: barWidth)
                    )
                    .foregroundStyle(by: .value("category", "Insulin"))
                    .cornerRadius(0)
                    .position(by: .value("category", "Insulin"))
                }
                ForEach(carbs) { carb in
                    BarMark(
                        x: .value("timestamp", truncateMinutes(date: carb.date)),
                        y: .value("carbs", carb.carbs * 2),
                        width: MarkDimension(integerLiteral: barWidth)
                    )
                    .foregroundStyle(by: .value("category", "Carbs"))
                    .cornerRadius(0)
                    .position(by: .value("category", "Carbs"))
                }

                if let prediction = prediction {
                    RuleMark(
                        x: .value("prediction", prediction.date)
                    )
                    .lineStyle(StrokeStyle(dash: dashedLineStyle, dashPhase: 3))
                    .foregroundStyle(Color(.systemPurple))
                    
                    ForEach(
                        predictedValues(
                            startDate: prediction.date,
                            values: prediction.values
                        )
                    ) { entry in
                        LineMark(
                            x: .value("timestamp", entry.date),
                            y: .value("BG", entry.sgv),
                            series: .value("category", "Prediction")
                        )
                        .foregroundStyle(Color(.systemPurple))
                        .lineStyle(StrokeStyle(dash: dashedLineStyle))
                        .interpolationMethod(.monotone)
                    }
                }
                ForEach(entries) { entry in
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
                    .interpolationMethod(.monotone)
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
                            .foregroundColor(Color(.secondaryLabel))
                    }
                }
            }
        }
        .padding([.top, .bottom])
    }
    
    func estimateColorBySgv(_ sgv : Int) -> Color {
        if sgv < criticalMin || sgv > criticalMax {
            return Color(.systemRed)
        }
        
        if sgv < rangeMin || sgv > rangeMax {
            return Color(.systemYellow)
        }
        
        return Color(.systemGreen)
    }
}

fileprivate let formatter = ISO8601DateFormatter(.withFractionalSeconds)

func predictedValues(startDate: Date, values: [Double]) -> [Entry] {
    var currentDate = startDate
    let endDate = Calendar.current.date(byAdding: .hour, value: 3, to: startDate)!
    
    let predictions : [Entry] = values.map {
        let entry = Entry(
            id: UUID().uuidString,
            sgv: Int($0),
            dateString: formatter.string(from: currentDate)
        )
        currentDate = Calendar.current.date(byAdding: .minute, value: 5, to: currentDate)!
        return entry
    }

    return Array(
        predictions.prefix(
            while: { $0.date <= endDate}
        )
    )
}

func truncateMinutes(date: Date) -> Date {
    return Calendar.current.date(from: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date))!
}

struct BloodGlucoseChart_Previews: PreviewProvider {
    static var previews: some View {
        let data = ModelData(test: true)
        BloodGlucoseChart(
            currentDate: data.currentDate,
            prediction: data.currentLoopData?.loop.predicted,
            insulin: data.insulin,
            carbs: data.carbs,
            entries: data.entries,
            criticalMin: 55,
            criticalMax: 260,
            rangeMin: 70,
            rangeMax: 180
        )
    }
}
