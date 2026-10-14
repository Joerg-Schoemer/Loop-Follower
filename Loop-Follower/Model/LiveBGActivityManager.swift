//
//  LiveBGActivityManager.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 14.10.26.
//

import ActivityKit
import Foundation

/// Starts, updates and ends the current blood glucose Live Activity.
///
/// The activity mirrors the single most recent CGM reading onto the lock screen
/// and Dynamic Island. It is kept in lockstep with the app's data refreshes
/// (see ``ModelData``); a new activity is created on the first reading and
/// every subsequent refresh pushes a new ``LiveBGAttributes/ContentState``.
@MainActor
final class LiveBGActivityManager {

    static let shared = LiveBGActivityManager()

    private init() {}

    /// True while a Live Activity is currently running.
    var isActive: Bool {
        !Activity<LiveBGAttributes>.activities.isEmpty
    }

    /// Starts a new Live Activity for the given reading, or updates the running
    /// one if it already exists.
    ///
    /// - Parameters:
    ///   - sgv: Current blood glucose in mg/dl.
    ///   - delta: Change against the previous reading.
    ///   - direction: Trend direction of the current reading.
    ///   - date: Timestamp of the current reading.
    ///   - iob: Insulin on board in units, if available.
    ///   - cob: Carbs on board in grams, if available.
    ///   - basal: Current total basal rate, if available.
    func update(
        sgv: Int,
        delta: Int?,
        direction: Direction?,
        date: Date,
        iob: Double?,
        cob: Double?,
        basal: Double?
    ) {
        let contentState = LiveBGAttributes.ContentState(
            sgv: sgv,
            delta: delta,
            direction: direction,
            date: date,
            iob: iob,
            cob: cob,
            basal: basal
        )

        if let activity = Activity<LiveBGAttributes>.activities.first {
            let content = ActivityContent(
                state: contentState,
                staleDate: Calendar.current.date(byAdding: .minute, value: 8, to: date)
            )
            Task {
                await activity.update(content)
            }
        } else {
            let attributes = LiveBGAttributes(startDate: date)
            let content = ActivityContent(
                state: contentState,
                staleDate: Calendar.current.date(byAdding: .minute, value: 8, to: date)
            )
            Task {
                _ = try? Activity<LiveBGAttributes>.request(
                    attributes: attributes,
                    content: content,
                    pushType: nil
                )
            }
        }
    }

    /// Ends the currently running Live Activity, if any.
    func stop() {
        guard let activity = Activity<LiveBGAttributes>.activities.first else {
            return
        }
        let finalState = activity.content.state
        Task {
            await activity.end(
                ActivityContent(
                    state: finalState,
                    staleDate: nil
                ),
                dismissalPolicy: .default
            )
        }
    }

    /// Ends the Live Activity once the data becomes stale (reading older than the
    /// given threshold).
    func stopIfStale(maxAge: TimeInterval) {
        guard let activity = Activity<LiveBGAttributes>.activities.first else {
            return
        }
        if Date.now.timeIntervalSince(activity.content.state.date) > maxAge {
            stop()
        }
    }
}
