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
                    .annotation(position: .top) {
                        Text("\(carb.carbs, specifier: "%.0f") g")
                            .font(.footnote)
                    }
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
            .padding([.top, .bottom])

            Chart {
                ForEach(modelData.scheduledBasal) { basal in
                    LineMark(
                        x: .value("startDate", basal.startDate),
                        y: .value("rate", basal.rate)
                    ).lineStyle(
                        StrokeStyle(
                            dash: [4]
                        )
                    )
                    LineMark(
                        x: .value("endDate", basal.endDate),
                        y: .value("rate", basal.rate)
                    ).lineStyle(
                        StrokeStyle(
                            dash: [4]
                        )
                    )
                }
                ForEach(
                    calculateResultingBasal(
                        tempBasal: modelData.tempBasal,
                        scheduledBasal: modelData.scheduledBasal,
                        startDate: Calendar.current.date(byAdding: .hour, value: -6, to: Date.now)!,
                        endDate: Calendar.current.date(byAdding: .hour, value: 3, to: Date.now)!
                    ).sorted(by: {$0.startDate < $1.startDate})
                ) { tempBasal in
                    AreaMark(
                        x: .value("startDate", tempBasal.startDate),
                        y: .value("rate", tempBasal.rate)
                    )
                    AreaMark(
                        x: .value("endDate", tempBasal.endDate),
                        y: .value("rate", tempBasal.rate)
                    )
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
                }
            }
            .padding([.top, .bottom])

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
            .padding([.top, .bottom])
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

fileprivate func calculateResultingBasal(
    tempBasal: [TempBasal],
    scheduledBasal: [TempBasal],
    startDate: Date,
    endDate: Date
) -> [TempBasal] {
    
    let formatter = ISO8601DateFormatter()
    
    var tempBasalPoints : [TempBasal] = []
    for sb in scheduledBasal {
        
        let tempWithinCurrentSchedule = tempBasal.filter({
            (sb.startDate ... sb.endDate).contains($0.endDate)
            || (sb.startDate ... sb.endDate).contains($0.startDate)
        }).sorted(by: {$0.startDate < $1.startDate})
        
        if tempWithinCurrentSchedule.isEmpty {
            // keine temp-basal einträge während scheduled, kann so übernommen werden
            tempBasalPoints.append(sb)
            continue
        }
        
        var lastTempEndDate : Date = sb.startDate
        for tb in tempWithinCurrentSchedule {
            if tb.startDate <= sb.startDate {
                // startet ausserhalb
                // wird am Anfang gekürzt
                tempBasalPoints.append(
                    TempBasal(
                        id: UUID().uuidString,
                        duration: Double(Calendar.current.dateComponents([.second], from: sb.startDate, to: tb.endDate).second!) / 60,
                        rate: tb.rate,
                        timestamp: formatter.string(from: sb.startDate)
                    )
                )
                lastTempEndDate = tb.endDate
                continue
            }
            
            if lastTempEndDate < tb.startDate {
                // Lücke muss gefüllt werden mit scheduled rate
                tempBasalPoints.append(
                    TempBasal(
                        id: UUID().uuidString,
                        duration: Double(Calendar.current.dateComponents([.second], from: lastTempEndDate, to: tb.startDate).second!) / 60,
                        rate: sb.rate,
                        timestamp: formatter.string(from: lastTempEndDate)
                    )
                )
            }
            
            if tb.endDate < sb.endDate {
                // liegt komplett drin
                tempBasalPoints.append(tb)
                lastTempEndDate = tb.endDate
            } else {
                // endet ausserhalb
                // wird am Ende gekürzt
                tempBasalPoints.append(
                    TempBasal(
                        id: UUID().uuidString,
                        duration: Double(Calendar.current.dateComponents([.second], from: tb.startDate, to: sb.endDate).second!) / 60,
                        rate: tb.rate,
                        timestamp: formatter.string(from: tb.startDate)
                    )
                )
            }
        }
        if lastTempEndDate < sb.endDate {
            tempBasalPoints.append(
                TempBasal(
                    id: UUID().uuidString,
                    duration: Double(Calendar.current.dateComponents([.second], from: lastTempEndDate, to: sb.endDate).second!) / 60,
                    rate: sb.rate,
                    timestamp: formatter.string(from: lastTempEndDate)
                )
            )
        }
    }
    
    return tempBasalPoints.filter({ $0.startDate < endDate && $0.endDate > startDate })
}

func derive(_ values: [Entry]) -> [Entry] {
    let diffs = zip(values.dropFirst(), values).map {
        let difference = Int(Calendar.current.dateComponents([.minute], from: $1.date, to: $0.date).minute! / 5)
        
        return Entry(id: "-", sgv: Int(($1.sgv - $0.sgv) / (difference <= 0 ? 1 : difference)), dateString: $1.dateString)
    }

    return diffs
}

