//
//  Loop_FollowerApp.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 13.07.22.
//

import SwiftUI

@main
struct Loop_FollowerApp: App {
    @StateObject private var modelData = ModelData()
    @StateObject private var settings = SettingsStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(modelData)
                .environmentObject(settings)
        }
    }
}
