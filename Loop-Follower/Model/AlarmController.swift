//
//  AlarmController.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 06.10.26.
//

import Foundation
import AudioToolbox
import UserNotifications

enum AlertType {
    case veryHigh, high, low, veryLow, data, none
}

struct Alert {
    let type: AlertType
}

struct AlertSettings {
    let veryLowThreshold : Int
    
    let lowThreshold : Int
    let lowTime : TimeInterval?
    
    let highThreshold : Int
    let highTime : TimeInterval?

    let veryHighThreshold : Int
}

struct AlertState {
    var veryLow : Entry?
    var low : Entry?
    var high : Entry?
    var veryHigh : Entry?
}

/// Estimates the current alarm state from the latest glucose readings.
///
/// - Returns: `.none` while within range, `.data` when there are no readings,
///   and `.low`/`.high` once the glucose has been outside the corresponding
///   threshold for the configured minimum duration, or `.veryLow`/`.veryHigh`
///   when it is outside the critical thresholds immediately.
fileprivate func processSgvForAlerts(_ entries: [Entry], alertSettings : AlertSettings) -> AlertType {
    
    if let first = entries.first {
        // on the first entry we decide which threshold to check
        if first.sgv < alertSettings.veryLowThreshold {
            return .veryLow
        } else if first.sgv < alertSettings.lowThreshold {
            if let firstAboveThresholdIndex = entries.firstIndex(where: { $0.sgv >= alertSettings.lowThreshold }) {
                let lastBelowThreshold = entries[firstAboveThresholdIndex - 1]
                let diff = lastBelowThreshold.date.distance(to: first.date).rounded(.toNearestOrAwayFromZero)
                if let lowTime = alertSettings.lowTime {
                    if diff > lowTime {
                        return .low
                    }
                } else {
                    return .none
                }
            } else if let lastBelowThreshold = entries.last {
                let diff = lastBelowThreshold.date.distance(to: first.date).rounded(.toNearestOrAwayFromZero)
                if let lowTime = alertSettings.lowTime {
                    if diff > lowTime {
                        return .low
                    }
                } else {
                    return .none
                }
            }
        } else if first.sgv > alertSettings.veryHighThreshold {
            return .veryHigh
        } else if first.sgv > alertSettings.highThreshold {
            if let firstBelowThresholdIndex = entries.firstIndex(where: { $0.sgv <= alertSettings.highThreshold }) {
                let lastAboveThreshold = entries[firstBelowThresholdIndex - 1]
                let diff = lastAboveThreshold.date.distance(to: first.date).rounded(.toNearestOrAwayFromZero)
                if let highTime = alertSettings.highTime {
                    if diff > highTime {
                        return .high
                    }
                } else {
                    return .none
                }
            } else if let lastAboveThreshold = entries.last {
                let diff = lastAboveThreshold.date.distance(to: first.date).rounded(.toNearestOrAwayFromZero)
                if let highTime = alertSettings.highTime {
                    if diff > highTime {
                        return .high
                    }
                } else {
                    return .none
                }
            }
        }
    } else {
        return .data
    }

    return .none
}

/// Drives a repeating acoustic alarm when the latest blood glucose reading is
/// outside the critical range (see ``criticalMin``/``criticalMax``).
///
/// The alarm keeps ringing until the user explicitly acknowledges it. It is
/// re-armed as soon as the glucose returns to the safe range, so a later
/// critical episode can trigger a new alarm.
@MainActor
final class AlarmController: ObservableObject {

    static let shared = AlarmController()

    /// True while the alarm is ringing and has not been acknowledged yet.
    @Published private(set) var isActive = false

    /// The current blood glucose value that triggered the alarm, if any.
    @Published private(set) var activeSgv: Int?

    /// The most recently estimated alarm state.
    @Published private(set) var alertType: AlertType?

    /// Thresholds used to derive the alarm state from the glucose readings.
    private var alertSettings: AlertSettings = AlertSettings(
        veryLowThreshold: 55,
        lowThreshold: 70,
        lowTime: 10 * 60,
        highThreshold: 180,
        highTime: 15 * 60,
        veryHighThreshold: 260
    )

    /// Updates the alarm thresholds from the persisted user settings.
    func updateSettings(from store: SettingsStore) {
        alertSettings = AlertSettings(
            veryLowThreshold: store.veryLowThreshold,
            lowThreshold: store.lowThreshold,
            lowTime: store.lowTime,
            highThreshold: store.highThreshold,
            highTime: store.highTime,
            veryHighThreshold: store.veryHighThreshold
        )
        alertType = nil
    }

    /// System sound used for the alarm (old car horn). Played repeatedly until acknowledged.
    private var soundID: SystemSoundID = 1050

    private var shouldContinue = false

    /// Until when the alarm stays silent after the user acknowledged the current
    /// episode. After this date the alarm rings again if the glucose is still critical.
    private var acknowledgedUntil: Date?

    private init() {}

    /// Called after every data reload with the newest glucose values.
    /// Estimates the alarm state via ``processSgvForAlerts(_:alertSettings:)``
    /// and activates the alarm for a low/high episode until acknowledged.
    /// After an acknowledgment the alarm stays silent for two hours, then
    /// re-activates if the glucose is still outside the range.
    func evaluate(entries: [Entry]) {
        let type = processSgvForAlerts(entries, alertSettings: alertSettings)
        alertType = type

        let latestSgv = entries.first?.sgv
        let isAlarm = type == .veryLow || type == .low || type == .high || type == .veryHigh

        guard isAlarm, let latestSgv else {
            // Back in the safe range: reset the acknowledgment, a new episode can alert immediately.
            acknowledgedUntil = nil
            activeSgv = nil
            deactivate()
            return
        }

        activeSgv = latestSgv

        // Stay silent while an acknowledgment from the last two hours is still valid.
        if let acknowledgedUntil, Date.now < acknowledgedUntil {
            deactivate()
            return
        }

        if !isActive {
            activate()
        }
    }

    /// Stops the alarm and re-arms it after two hours if the glucose is still critical.
    func acknowledge() {
        acknowledgedUntil = Date.now.addingTimeInterval(2 * 60 * 60)
        deactivate()
        removePendingAlarmNotification()
    }

    private func activate() {
        isActive = true
        shouldContinue = true
        scheduleAlarmNotification()
        play()
    }

    private func deactivate() {
        isActive = false
        shouldContinue = false
    }

    private func play() {
        guard shouldContinue, isActive else { return }
        AudioServicesPlaySystemSoundWithCompletion(soundID) { [weak self] in
            Task { @MainActor in
                // pause between repetitions so the alarm plays as distinct beeps
                try? await Task.sleep(for: .seconds(3))
                self?.play()
            }
        }
    }

    /// Identifier used for the pending alarm notification, so it can be removed on acknowledge.
    private let notificationIdentifier = "LoopFollower.Alarm"

    /// Schedules a local notification so the alarm also shows while the app is in the background.
    private func scheduleAlarmNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Loop-Follower Alarm"
        content.body = alarmNotificationBody()
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: notificationIdentifier,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    /// Removes the pending alarm notification once the user acknowledged the alarm.
    private func removePendingAlarmNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [notificationIdentifier]
        )
    }

    /// Builds the notification body text from the current alarm state and glucose value.
    private func alarmNotificationBody() -> String {
        let sgvText = activeSgv.map { "\($0) mg/dL" } ?? "–"
        switch alertType {
        case .veryLow:
            return "Kritisch niedriger Blutzucker: \(sgvText)"
        case .low:
            return "Niedriger Blutzucker: \(sgvText)"
        case .high:
            return "Hoher Blutzucker: \(sgvText)"
        case .veryHigh:
            return "Kritisch hoher Blutzucker: \(sgvText)"
        default:
            return "Alarm: Blutzucker \(sgvText)"
        }
    }
}
