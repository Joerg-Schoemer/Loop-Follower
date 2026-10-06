//
//  Loop_FollowerApp.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 13.07.22.
//

import SwiftUI
import UserNotifications

@main
struct Loop_FollowerApp: App {
    @StateObject private var modelData = ModelData()
    @StateObject private var settings = SettingsStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(modelData)
                .environmentObject(settings)
                .task {
                    await requestNotificationPermission()
                    AlarmController.shared.updateSettings(from: settings)
                }
        }
    }

    /// Asks the user for permission to show local notifications for the alarm.
    private func requestNotificationPermission() async {
        let center = UNUserNotificationCenter.current()
        do {
            try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            // Ignore permission errors; the alarm continues to work via sound.
        }
    }
}
