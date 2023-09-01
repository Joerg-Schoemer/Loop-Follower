//
//  CarbrationView.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 28.08.23.
//

import SwiftUI

struct ProfileView: View {

    @EnvironmentObject var modelData : ModelData

    var body: some View {
        VStack {
            if let profile = modelData.profile {
                
                List {
                    Section(header: Text("Carbohydrate ratios")) {
                        ForEach(profile.carbratio, id: \.timeAsSeconds) { ratio in
                            HStack {
                                Text(ratio.time.formatted(date: .omitted, time: .shortened))
                                Spacer()
                                Text(ratio.value.formatted(.number.precision(.fractionLength(1))))
                            }
                        }
                    }

                    Section(header: Text("Insulin Sensitivity Factors")) {
                        ForEach(profile.sens, id: \.timeAsSeconds) { sens in
                            HStack {
                                Text(sens.time.formatted(date: .omitted, time: .shortened))
                                Spacer()
                                Text(sens.value.formatted(.number.precision(.fractionLength(1))))
                            }
                        }
                    }
                }
            }
        }
        .navigationBarTitle("Profile")
    }
}

struct CarbrationView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(ModelData(test: true))
    }
}
