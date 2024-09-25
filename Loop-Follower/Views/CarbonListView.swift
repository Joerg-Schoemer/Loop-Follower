//
//  CarbonListView.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 28.08.23.
//

import SwiftUI

struct CarbonListView: View {

    @EnvironmentObject var modelData : ModelData

    var body: some View {
        List(modelData.carbs, id: \.id) { carb in
            CarbonItem(carb: carb, profile: modelData.profile!)
        }
        .navigationBarTitle("Carbs")
    }
}

struct CarbonListView_Previews: PreviewProvider {
    static var previews: some View {
        CarbonListView()
            .environmentObject(ModelData(test: true))
            .environmentObject(SettingsStore())
    }
}
