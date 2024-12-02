//
//  CarbonListView.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 28.08.23.
//

import SwiftUI

struct CarbonListView: View {

    @EnvironmentObject var modelData : ModelData
    @EnvironmentObject var settings: SettingsStore

    var body: some View {

        VStack{
            
            List(modelData.carbs, id: \.id) { carb in
                CarbonItem(carb: carb, profile: modelData.profile!)
            }
            
            Spacer()

            ForEach(sumByDay.sorted(by: >), id: \.key) { key, value in
                HStack {
                    Label(
                        key.formatted(date: .numeric, time: .omitted),
                        systemImage: "calendar"
                    )
                    Spacer()
                    Label(
                        value.formatted(.measurement(width: .abbreviated, numberFormatStyle: .number.precision(.fractionLength(2)))),
                        systemImage: "sum"
                    )
                }
            }
        }
        .navigationBarTitle("Carbs")
    }
    
    var sumByDay : Dictionary<Date,Measurement<UnitInsulin>> {
        
        let groupedByDay = Dictionary(grouping: modelData.carbs) {
            Calendar.current.startOfDay(for: $0.date)
        }
        
        var x = Dictionary<Date,Measurement<UnitInsulin>>()
        for (day, carbs) in groupedByDay {
            x[day] = Measurement<UnitInsulin>(
                value: carbs.map {
                    calculateInsulinNeeds(
                        carbs: $0.carbs,
                        factor: findCarbRatio(profile: modelData.profile!, carb: $0)!.value,
                        pumpResolution: settings.pumpRes
                    )
                }.map{ $0 }.reduce(0, +),
                unit: .insulin
            )
        }

        return x
    }
}

struct CarbonListView_Previews: PreviewProvider {
    static var previews: some View {
        CarbonListView()
            .environmentObject(ModelData(test: true))
            .environmentObject(SettingsStore())
    }
}
