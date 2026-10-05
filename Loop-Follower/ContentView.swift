//
//  ContentView.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 13.07.22.
//

import SwiftUI

struct ContentView: View {

    var body: some View {
        NavigationStack {
            MonitorView()
                .toolbar {
                    bottomToolbar
                }
        }
        .navigationBarHidden(true)
        .navigationTitle("Overview")
    }

    var bottomToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            NavigationLink(
                destination: {
                    InsulinListView()
                },
                label: {
                    Image(systemName: "syringe")
                }
            )
            NavigationLink(
                destination: {
                    CarbonListView()
                },
                label: {
                    Image(systemName: "fork.knife")
                }
            )
            NavigationLink(
                destination: {
                    ProfileView()
                },
                label: {
                    Image(systemName: "slider.horizontal.3")
                }
            )
            Spacer()
            NavigationLink(
                destination: {
                    NightScoutSettingsView()
                },
                label: {
                    Image(systemName: "gear")
                }
            )
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(ModelData(test:true))
            .environmentObject(SettingsStore())
    }
}
