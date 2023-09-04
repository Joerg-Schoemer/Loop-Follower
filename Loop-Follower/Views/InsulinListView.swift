//
//  InsulinList.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 28.08.23.
//

import SwiftUI

struct InsulinListView: View {
    
    @EnvironmentObject var modelData : ModelData

    var body: some View {
        VStack{
            List(modelData.insulin, id: \.id) { insulin in
                InsulinItem(insulin: insulin)
            }
            Spacer()
            Label(
                sum.formatted(.measurement(width: .abbreviated, numberFormatStyle: .number.precision(.fractionLength(2)))),
                systemImage: "sum"
            ).font(.headline)
        }
        .navigationBarTitle("Insulin")
    }
    
    var sum : Measurement<UnitInsulin> {
        return Measurement<UnitInsulin>(value: modelData.insulin.map{ $0.insulin }.reduce(0, +), unit: .insulin)
    }
}

struct InsulinList_Previews: PreviewProvider {
    static var previews: some View {
        InsulinListView()
            .environmentObject(ModelData(test: true))
    }
}
