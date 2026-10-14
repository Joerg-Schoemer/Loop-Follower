//
//  BackgroundRefreshManager.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 14.10.26.
//

import BackgroundTasks
import UIKit

/// Bundle-identifier scoped identifier for the app's background refresh task.
/// It must match the value in the `BGTaskSchedulerPermittedIdentifiers`
/// entry of the Info.plist.
enum BackgroundRefresh {
    static let taskIdentifier = "joerg-schoemer.de.Loop-Follower.refresh"
}

/// App delegate that registers the `BGAppRefreshTask` launch handler so the
/// app gets woken up by the system now and then to fetch fresh values even
/// while it is suspended in the background.
final class AppDelegate: NSObject, UIApplicationDelegate {

    /// Registers a closure that the system calls whenever it decides it is a
    /// good time to let the app refresh its data in the background.
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: BackgroundRefresh.taskIdentifier,
            using: nil
        ) { task in
            BackgroundRefreshManager.handleRefresh(task)
        }
        return true
    }
}

/// Schedules and coordinates the app's background data refresh.
enum BackgroundRefreshManager {

    /// Reference to the shared data model, assigned when the app's UI appears
    /// so the background handler can reach it without a dependency cycle.
    static weak var sharedModelData: ModelData?

    /// Invoked by the system when the background refresh task fires. Performs
    /// a data refresh, schedules the next one, and marks the task complete.
    static func handleRefresh(_ task: BGTask) {
        // Schedule the next refresh before doing the work so the app is always
        // queued for another wake-up even if this run is interrupted.
        schedule()

        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        Task { @MainActor in
            guard let modelData = sharedModelData else {
                task.setTaskCompleted(success: true)
                return
            }
            await modelData.reloadData()
            task.setTaskCompleted(success: true)
        }
    }

    /// Queues a `BGAppRefreshTask` with the system. The system decides when to
    /// actually run it (usually no sooner than 15 minutes apart).
    static func schedule() {
        guard !NightScoutAPI.baseUrl.isEmpty else {
            // Nothing to do while the Nightscout server is not configured.
            return
        }

        let request = BGAppRefreshTaskRequest(identifier: BackgroundRefresh.taskIdentifier)
        // Ask for the earliest sensible refresh: one CGM interval, so new
        // readings are picked up as soon as the system allows.
        request.earliestBeginDate = Date(timeIntervalSinceNow: 5 * 60)

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("BackgroundRefresh: Failed to schedule refresh: \(error)")
        }
    }
}
