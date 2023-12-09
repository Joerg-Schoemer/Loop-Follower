//
//  InsulinList.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 28.08.23.
//

import SwiftUI

struct InsulinListView: View {
    
    @EnvironmentObject var modelData : ModelData

    @State private var multiSelection = Set<String>()

    @State private var editMode : EditMode = .inactive

    var body: some View {
        VStack{
            List(modelData.insulin, id: \.id, selection: $multiSelection) { insulin in
                InsulinItem(insulin: insulin)
            }
            .toolbar { EditButton() }
            .environment(\.editMode, $editMode)
            .onChange(of: editMode) { oldValue, newValue in
                if newValue == .active {
                    multiSelection.formUnion(modelData.insulin.map{ cb in cb.id })
                } else {
                    multiSelection.removeAll()
                }
            }

            Spacer()

            Label(
                sum.formatted(.measurement(width: .abbreviated, numberFormatStyle: .number.precision(.fractionLength(2)))),
                systemImage: "sum"
            )
            .font(.headline)
        }
        .navigationBarTitle("Insulin")
    }

    var sum : Measurement<UnitInsulin> {
        let selectedItems = modelData.insulin.filter { insulin in multiSelection.contains(insulin.id) || editMode == .inactive }

        return Measurement<UnitInsulin>(value: selectedItems.map{ $0.insulin }.reduce(0, +), unit: .insulin)
    }
}

struct InsulinList_Previews: PreviewProvider {
    static var previews: some View {
        InsulinListView()
            .environmentObject(ModelData(test: true))
    }
}
