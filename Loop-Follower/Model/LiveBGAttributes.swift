//
//  LiveBGAttributes.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 14.10.26.
//

import ActivityKit
import Foundation

/// Activity attributes (+ content state) for the current blood glucose Live Activity.
///
/// This type must be identical in the widget extension target so that the
/// activity started from the app is rendered by the extension's widget.
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
