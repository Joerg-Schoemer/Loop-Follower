//
//  ContentView.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 13.07.22.
//

import SwiftUI

struct ContentView: View {

    var body: some View {
        NavigationView {
            MonitorView()
                .toolbar {
                    ToolbarItem(placement: .bottomBar) {
                        NavigationLink(destination: {
                            NightScoutSettingsView()
                        }, label: {
                            Image(systemName: "gear")
                        })
                    }
                }
                .navigationBarHidden(true)
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
