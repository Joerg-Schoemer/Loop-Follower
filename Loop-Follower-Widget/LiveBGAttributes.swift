//
//  LiveBGAttributes.swift
//  Loop-Follower-Widget
//
//  Created by Jörg Schömer on 14.10.26.
//
//  Mirror of the app's `LiveBGAttributes`. The widget extension is a separate
//  module, so the ActivityAttributes type must be declared again here with the
//  exact same name and structure to render the activity started by the app.

import ActivityKit
import Foundation

/// Activity attributes (+ content state) for the current blood glucose Live Activity.
struct LiveBGAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        /// Latest blood glucose value in mg/dl.
        var sgv: Int

        /// Change of the last value against the previous one.
        var delta: Int?

        /// Trend arrow direction.
        var direction: Direction?

        /// Timestamp of the latest reading.
        var date: Date

        /// IOB (insulin on board) in units.
        var iob: Double?

        /// COB (carbs on board) in grams.
        var cob: Double?

        /// Current total basal rate in units/hour.
        var basal: Double?
    }

    /// Anchor date used to show how long ago the reading is.
    var startDate: Date
}
