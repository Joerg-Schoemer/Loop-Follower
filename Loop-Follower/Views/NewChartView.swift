//
//  NewChartView.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 04.02.23.
//

import SwiftUI
import Charts

struct NewChartView: View {
    
    @EnvironmentObject var modelData : ModelData
    
    var body: some View {
        
        let dashedLineStyle : [CGFloat] = [10, 4]
        let velocity = derive(modelData.entries)
        let accelleration = derive(velocity)

        TabView {
            Chart {
                if let currentDate = modelData.currentDate {
                    RuleMark(
                        x: .value("now", currentDate)
                    )
                    .lineStyle(StrokeStyle(
                        lineWidth: 0.5,
                        dash: [4])
                    )
                    .foregroundStyle(Color(.systemGray))
                }
                
                // Zielbereich
                RuleMark(
                    y: .value("min", 70)
                )
                .lineStyle(StrokeStyle(dash: dashedLineStyle))
                .foregroundStyle(.green)
                RuleMark(
                    y: .value("max", 180)
                )
                .lineStyle(StrokeStyle(dash: dashedLineStyle))
                .foregroundStyle(.green)
                
                // Kritischer Bereich
                RuleMark(
                    y: .value("critical min", 55)
                )
                .lineStyle(StrokeStyle(dash: dashedLineStyle))
                .foregroundStyle(.red)
                RuleMark(
                    y: .value("critical max", 260)
                )
                .lineStyle(StrokeStyle(dash: dashedLineStyle))
                .foregroundStyle(.red)
                
                ForEach(modelData.insulin) { insulin in
                    BarMark(
                        x: .value("timestamp", insulin.date),
                        y: .value("insulin", insulin.insulin * 100)
                    )
                    .foregroundStyle(by: .value("category", "insulin"))
                }
                ForEach(modelData.carbs) { carb in
                    BarMark(
                        x: .value("timestamp", carb.date),
                        y: .value("carbs", carb.carbs * 2)
                    )
                    .foregroundStyle(by: .value("category", "carbs"))
                }
                
                let prediction = modelData.currentLoopData?.loop.predicted
                if let predictionDate = prediction?.date {
                    RuleMark(
                        x: .value("prediction", predictionDate)
                    )
                    .lineStyle(StrokeStyle(dash: [4]))
                    .foregroundStyle(Color(.systemPurple))
                    
                    ForEach(predicted(startDate: predictionDate, values: (prediction?.values)!)) { entry in
                        LineMark(
                            x: .value("timestamp", entry.date),
                            y: .value("BZ", entry.sgv),
                            series: .value("category", "predicted")
                        )
                        .symbol {
                            Circle()
                                .fill(Color(.systemPurple))
                                .frame(width: 5)
                        }
                        .foregroundStyle(Color(.systemPurple))
                        .interpolationMethod(.monotone)
                        .lineStyle(StrokeStyle(lineWidth: 0.5))
                    }
                }
                
                ForEach(modelData.entries) { entry in
                    LineMark(
                        x: .value("timestamp", entry.date),
                        y: .value("BZ", entry.sgv),
                        series: .value("category", "bloodglucose")
                    )
                    .symbol {
                        Circle()
                            .fill(estimateColorBySgv(entry.sgv))
                            .frame(width: 5)
                    }
                    .interpolationMethod(.monotone)
                }
            }
            .chartForegroundStyleScale([
                "bloodglucose": Color(.systemBlue),
                "predicted": Color(.systemPurple),
                "insulin": Color(.systemOrange),
                "carbs": Color(.systemTeal),
            ])

            Chart {
                ForEach(modelData.scheduledBasal) { basal in
                    LineMark(
                        x: .value("startDate", basal.startDate),
                        y: .value("rate", basal.rate)
                    ).lineStyle(
                        StrokeStyle(
                            lineWidth: 0.5,
                            dash: [4]
                        )
                    )
                    LineMark(
                        x: .value("endDate", basal.endDate),
                        y: .value("rate", basal.rate)
                    )
                    /*
                    RuleMark(
                        xStart: .value("start", basal.startDate),
                        xEnd: .value("end", basal.endDate),
                        y: .value("rate", basal.rate)
                    )
                     */
                }
                ForEach(modelData.tempBasal.reversed()) { tempBasal in
                    AreaMark(
                        xStart: .value("startDate", tempBasal.startDate),
                        xEnd: .value("endDate", tempBasal.endDate),
                        y: .value("rate", tempBasal.rate)
                    )
                }
            }
            Chart {
                ForEach(velocity) { velocity in
                    BarMark(
                        x: .value("timestamp", velocity.date),
                        y: .value("velocity", velocity.sgv)
                    )
                    .foregroundStyle(by: .value("category", "velocity"))
                }
                ForEach(accelleration) { accelleration in
                    BarMark(
                        x: .value("timestamp", accelleration.date),
                        y: .value("accelleration", accelleration.sgv)
                    )
                    .foregroundStyle(by: .value("category", "accelleration"))
                }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }
}

func estimateColorBySgv(_ sgv : Int) -> Color {
    if sgv < 50 || sgv >= 260 {
        return Color(.systemRed)
    }
    
    if sgv < 70 || sgv > 180 {
        return Color(.systemYellow)
    }
    
    return Color(.systemGreen)
}

func predicted(startDate: Date, values: [Double]) -> [Entry] {
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

struct NewChartView_Previews: PreviewProvider {
    static var previews: some View {
        NewChartView()
            .environmentObject(ModelData(test: true))
    }
}


/*
fileprivate func estimatePoints(
    tempBasal : [TempBasal],
    scheduledBasal : [TempBasal]
) -> [TempBasal] {

    var tempBasalPoints : [TempBasal] = []
    for b in scheduledBasal {
        var lastTempEndDate : Date = b.startDate
        for t in tempBasal.filter({
            (b.startDate ... b.endDate).contains($0.endDate)
            || (b.startDate ... b.endDate).contains($0.startDate)
        }).sorted(by: {$0.startDate < $1.startDate}) {
            if (t.startDate < b.startDate) {
                tempBasalPoints.append(
                    TempBasal(
                        id: "",
                        duration: Double(Calendar.current.dateComponents([.minute], from: t.startDate, to: b.startDate).minute!),
                        rate: t.rate,
                        timestamp: t.startDate.formatted(ISO8601DateFormatter())!
                    )
                )
                lastTempEndDate = t.endDate
            } else {
                if lastTempEndDate < t.startDate {
                    let newBasalElement = TempBasal(
                        id: UUID().uuidString,
                        duration: Double(Calendar.current.dateComponents([.minute], from: lastTempEndDate, to: t.startDate).minute!),
                        rate: b.rate,
                        timestamp: t.startDate.formatted(ISO8601DateFormatter())!
                    )

                    tempBasalPoints.append(newBasalElement)
                    /*
                    tempBasalPoints.append(CGPoint(
                        x: (lastEndDate - startDate) * xScale,
                        y: height - b.rate * yScale
                    ))
                    tempBasalPoints.append(CGPoint(
                        x: (t.startDate - startDate) * xScale,
                        y: height - b.rate * yScale
                    ))
                     */
                }
                tempBasalPoints.append(t)
                /*
                tempBasalPoints.append(CGPoint(
                    x: (t.startDate - startDate) * xScale,
                    y: height - t.rate * yScale
                ))
                tempBasalPoints.append(CGPoint(
                    x: (t.endDate - startDate) * xScale,
                    y: height - t.rate * yScale
                ))
                 */
                lastTempEndDate = t.endDate
            }
        }

        if lastTempEndDate < b.endDate {
            /*
            tempBasalPoints.append(CGPoint(
                x: (lastEndDate - startDate) * xScale,
                y: height - b.rate * yScale
            ))
            tempBasalPoints.append(CGPoint(
                x: (b.endDate - startDate) * xScale,
                y: height - b.rate * yScale
            ))
             */
        }
    }
    
    return tempBasalPoints
}
*/
