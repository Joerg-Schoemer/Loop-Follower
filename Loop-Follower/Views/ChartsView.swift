//
//  NewChartView.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 04.02.23.
//

import SwiftUI
import Charts

struct ChartsView: View {

    let criticalMin : Int
    let criticalMax : Int
    
    let rangeMin : Int
    let rangeMax : Int

    @Binding var selection : String
    
    @EnvironmentObject var modelData : ModelData
    
    var body: some View {
        GeometryReader { proxy in
            TabView(selection: $selection) {
                Group {
                    DerivedChart(
                        currentDate: modelData.currentDate,
                        entries: $modelData.entries
                    )
                    .tag("derived")

                    BloodGlucoseChart(
                        currentDate: modelData.currentDate,
                        prediction: modelData.currentLoopData?.loop.predicted,
                        insulin: modelData.insulin,
                        carbs: modelData.carbs,
                        entries: modelData.entries,
                        mbgs: modelData.mgbs,
                        hourOfHistory: modelData.hourOfHistory,
                        criticalMin: criticalMin,
                        criticalMax: criticalMax,
                        rangeMin: rangeMin,
                        rangeMax: rangeMax
                    )
                    .tag("BG")
                    
                    BasalChart(
                        currentDate: $modelData.currentDate,
                        scheduledBasal: modelData.scheduledBasal,
                        resultingBasal: modelData.resultingBasal
                    )
                    .tag("basal")
                }
                .rotationEffect(.degrees(-90))
                .frame(
                    width: proxy.size.width,
                    height: proxy.size.height
                )
            }
            .frame(
                width: proxy.size.height, // Height & width swap
                height: proxy.size.width
            )
            .rotationEffect(.degrees(90), anchor: .topLeading)
            .offset(x: proxy.size.width) // Offset back into screens bounds
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }
}

struct ChartsView_Previews: PreviewProvider {

    static var previews: some View {
        ChartsView(
            criticalMin: 55,
            criticalMax: 260,
            rangeMin: 70,
            rangeMax: 180,
            selection: .constant("BG")
        )
        .environmentObject(ModelData(test: true))
    }
}
