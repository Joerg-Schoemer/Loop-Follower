//
//  BloodGlucoseChart.swift
//  Loop-Follower
//
//  Created by Schömer, Jörg on 14.02.23.
//

import SwiftUI
import Charts

struct BloodGlucoseChart: View {

    @State var rawSelectedDate: Date?

    var selectedEntry: Entry? {
        guard let rawSelectedDate else { return nil }
        
        let p = predictedValues(
            startDate: prediction!.date,
            values: prediction!.values
        )

        let allEntries = entries.reversed() + p
        let f = allEntries.first(
            where: { $0.date >= rawSelectedDate }
        )
        
        if f != nil {
            print("f=\(f!)")
        }

        return f
    }

    let dashedLineStyle : [CGFloat] = [7, 3]
    let barWidth : Int = 3
    
    let currentDate : Date?
    
    let prediction: Predicted?
    let insulin : [CorrectionBolus]
    let carbs : [CarbCorrection]
    let entries : [Entry]
    let mbgs : [MbgEntry]
    let hourOfHistory : Int

    let criticalMin : Int
    let criticalMax : Int
    
    let rangeMin : Int
    let rangeMax : Int

    let series: KeyValuePairs<String, Color> = [
        "Blood Glucose": Color(.systemGray),
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
                    .lineStyle(StrokeStyle(lineWidth: 1))
                    .foregroundStyle(Color(.systemCyan).opacity(0.75))
                }

                ForEach(insulin.filter({ c in
                    if let currentDate = currentDate {
                        return c.date >= Calendar.current.date(byAdding: .hour, value: hourOfHistory, to: currentDate)!
                    }
                    return false
                })) { insulin in
                    PointMark(
                        x: .value("timestamp", insulin.date),
                        y: .value("insulin", 10)
                    )
                    .foregroundStyle(by: .value("category", "Insulin"))
                    .symbol {
                        Image(systemName: "syringe")
                            .foregroundColor(.orange)
                            .font(.system(size: 10))
                    }
                }
                ForEach(carbs.filter({ c in
                    if let currentDate = currentDate {
                        return c.date >= Calendar.current.date(byAdding: .hour, value: hourOfHistory, to: currentDate)!
                    }
                    return false
                })) { carb in
                    PointMark(
                        x: .value("timestamp", carb.date),
                        y: .value("carbs", 30)
                    )
                    .foregroundStyle(by: .value("category", "Carbs"))
                    .symbol {
                        Image(systemName: "fork.knife")
                            .foregroundColor(.green)
                            .font(.system(size: 10))
                    }
                }

                if let prediction = prediction {
                    RuleMark(
                        x: .value("prediction-start", prediction.date)
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
                        .foregroundStyle(by: .value("category", "Prediction"))
                        .lineStyle(StrokeStyle(dash: dashedLineStyle))
                        .interpolationMethod(.monotone)
                        .symbol {
                            if entry.sgv == 0 {
                                Circle()
                                    .fill(Color(.systemRed))
                                    .frame(width: 5)
                            }
                        }
                    }
                }

                ForEach(mbgs) { mbg in
                    PointMark(
                        x: .value("timestamp", mbg.date),
                        y: .value("BG", mbg.mbg)
                    )
                    .foregroundStyle(.red)
                }

                ForEach(entries) { entry in
                    LineMark(
                        x: .value("timestamp", entry.date),
                        y: .value("BG", max(entry.sgv, 40)),
                        series: .value("category", "Blood Glucose")
                    )
                    .symbol {
                        BasicChartSymbolShape
                            .circle
                            .stroke(estimateColorBySgv(entry.sgv), lineWidth: 1.5)
                            .frame(width: 5)
                    }
                    .foregroundStyle(by: .value("category", "Blood Glucose"))
                    .lineStyle(StrokeStyle(lineWidth: 3.0))
                    .interpolationMethod(.monotone)
                }

                if let selectedEntry {
                    RuleMark(
                        x: .value("Selected", selectedEntry.date, unit: .minute)
                    )
                    .foregroundStyle(Color.gray.opacity(0.3))
                    .offset(yStart: -10)
                    .zIndex(-1)
                    .annotation(
                        position: .top,
                        spacing: 0,
                        overflowResolution: .init(
                            x: .fit(to: .chart),
                            y: .disabled
                        )
                    ) {
                        BloodGlucoseCursorView(
                            sgv: selectedEntry.sgv,
                            date: selectedEntry.date
                        )
                    }
                }
            }
            .chartYScale(domain: 0...300)
            .chartXSelection(value: $rawSelectedDate)
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
            sgv: max(Int($0), 0),
            id: UUID().uuidString,
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
    let calendar: Calendar = Calendar.current
    return calendar.date(from: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date))!
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
            mbgs: data.mgbs,
            hourOfHistory: -6,
            criticalMin: 55,
            criticalMax: 260,
            rangeMin: 70,
            rangeMax: 180
        )
    }
}
