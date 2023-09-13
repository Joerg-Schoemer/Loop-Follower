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
                TabView {
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
                    }
                    .tag("carbs")

                    List {
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
                    .tag("ISF")

                    List {
                        Section(header: Text("basal")) {
                            ForEach(profile.basal, id: \.timeAsSeconds) { basal in
                                HStack {
                                    Text(basal.time.formatted(date: .omitted, time: .shortened))
                                    Spacer()
                                    Text(basal.value.formatted(.number.precision(.fractionLength(2))))
                                }
                            }
                        }
                    }
                    .tag("basal")

                    List {
                        Section(header: Text("correction target")) {
                            ForEach(profile.targets, id: \.low.timeAsSeconds) { targets in
                                HStack {
                                    Text(targets.low.time.formatted(date: .omitted, time: .shortened))
                                    Spacer()
                                    Text(
                                        targets.low.value.formatted(.number.precision(.fractionLength(1)))
                                        + " - " +
                                        targets.high.value.formatted(.number.precision(.fractionLength(1))))
                                    
                                }
                            }
                        }
                    }
                    .tag("target")
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always))
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
