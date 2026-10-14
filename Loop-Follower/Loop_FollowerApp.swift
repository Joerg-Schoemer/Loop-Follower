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
    @Environment(\.scenePhase) private var scenePhase
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var modelData = ModelData()
    @StateObject private var settings = SettingsStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(modelData)
                .environmentObject(settings)
                .task {
                    // Give the background refresh handler access to the shared
                    // data model so it can trigger a reload when the app is
                    // woken up while suspended.
                    BackgroundRefreshManager.sharedModelData = modelData
                    await requestNotificationPermission()
                    AlarmController.shared.updateSettings(from: settings)
                }
                .onChange(of: scenePhase) { _, newPhase in
                    switch newPhase {
                    case .active:
                        // Refresh immediately on foregrounding and keep a
                        // background refresh task queued for the next time the
                        // app is suspended.
                        BackgroundRefreshManager.schedule()
                        Task {
                            await modelData.refresh()
                        }
                    case .background:
                        // Queue one more background refresh before suspending.
                        BackgroundRefreshManager.schedule()
                    default:
                        break
                    }
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
