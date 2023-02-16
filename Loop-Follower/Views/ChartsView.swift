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

    @State private var selection : String = "BG"
    
    @EnvironmentObject var modelData : ModelData
    
    var body: some View {
        
        TabView(selection: $selection) {
            BloodGlucoseChart(
                criticalMin: criticalMin,
                criticalMax: criticalMax,
                rangeMin: rangeMin,
                rangeMax: rangeMax
            )
                .tag("BG")

            BasalChart(
                scheduledBasal: modelData.scheduledBasal,
                resultingBasal: modelData.resultingBasal,
                currentDate: modelData.currentDate
            )
                .tag("basal")
            
            DerivedChart()
                .tag("derived")
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }
}

struct NewChartView_Previews: PreviewProvider {
   
    static var previews: some View {
        ChartsView(
            criticalMin: 55,
            criticalMax: 260,
            rangeMin: 70,
            rangeMax: 180
        )
            .environmentObject(ModelData(test: true))
    }
}


