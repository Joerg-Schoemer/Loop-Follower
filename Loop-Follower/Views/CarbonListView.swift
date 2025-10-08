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

        VStack() {
            List(carbs) { carb in
                NavigationLink() {
                    CarbonDetails(carb: carb)
                } label: {
                    CarbonItem(carb: carb.item, profile: modelData.profile!)
                }
            }
            
            Spacer()
            
            ForEach(sumByDay.sorted(by: >), id: \.key) { key, value in
                HStack(spacing: 5) {
                    Label(
                        key.formatted(date: .numeric, time: .omitted),
                        systemImage: "calendar"
                    )
                    Spacer()
                    Label(
                        value.formatted(.measurement(width: .abbreviated, numberFormatStyle: .number.precision(.fractionLength(2)))),
                        systemImage: "sum"
                    )
                }.padding(.horizontal, 20)
            }
        }
        .navigationBarTitle("Carbs")
    }
    
    var carbs : [Node<CarbCorrection>] {
        var nodes : [Node<CarbCorrection>] = []
        let carbs = Array(modelData.carbs)

        if carbs.count > 0 {
            var prevNode = Node<CarbCorrection>(item: carbs.first!, next: nil)
            nodes.append(prevNode)

            var idx : Int = 0
            while idx < carbs.count - 1 {
                idx += 1
                prevNode = Node<CarbCorrection>(item: carbs[idx], next: prevNode)
                nodes.append(prevNode)
            }
        }
        
        return nodes
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

class Node<T> : Identifiable {
    
    public var item : T
    public var next : Node<T>?

    
    public init(item : T, next : Node<T>?) {
        self.item = item
        self.next = next
    }
}
