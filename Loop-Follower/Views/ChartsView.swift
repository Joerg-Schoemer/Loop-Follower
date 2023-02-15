//
//  NewChartView.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 04.02.23.
//

import SwiftUI
import Charts

struct ChartsView: View {
    
    @EnvironmentObject var modelData : ModelData
    
    var body: some View {
        
        TabView {
            BloodGlucoseChart()

            BasalChart(
                scheduledBasal: modelData.scheduledBasal,
                resultingBasal: modelData.resultingBasal,
                currentDate: modelData.currentDate
            )
            
            DerivedChart()
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }
}

struct NewChartView_Previews: PreviewProvider {
    static var previews: some View {
        ChartsView()
            .environmentObject(ModelData(test: true))
    }
}


