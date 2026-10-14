//
//  Loop_Follower_LiveActivity.swift
//  Loop-Follower-Widget
//
//  Created by Jörg Schömer on 14.10.26.
//

import ActivityKit
import SwiftUI
import WidgetKit

/// Renders the current blood glucose Live Activity on the lock screen, StandBy
/// and the Dynamic Island.
struct Loop_Follower_LiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveBGAttributes.self) { context in
            LiveBGLockScreenView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.5))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    SgvSummaryView(state: context.state)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    LiveBGExpandedTrailing(state: context.state)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    LiveBGExpandedBottom(state: context.state)
                }
            } compactLeading: {
                SgvCompactView(state: context.state)
            } compactTrailing: {
                DirectionCompactView(direction: context.state.direction)
            } minimal: {
                SgvCompactView(state: context.state)
            }
            .keylineTint(estimateColor(context.state.sgv))
        }
        .supplementalActivityFamilies([.small])
    }
}

/// Lock screen / StandBy layout of the Live Activity, also used for the
/// watchOS Smart Stack when rendered with the `.small` activity family.
private struct LiveBGLockScreenView: View {
    @Environment(\.activityFamily) private var activityFamily
    let context: ActivityViewContext<LiveBGAttributes>

    var body: some View {
        switch activityFamily {
        case .small:
            HStack(spacing: 8) {
                SgvCompactView(state: context.state)
                if let direction = context.state.direction {
                    Image(systemName: direction.systemImage)
                        .font(.caption.bold())
                }
                Text(formatDelta(context.state.delta))
                    .font(.caption2)
            }
            .padding(8)
        case .medium, _:
            HStack(spacing: 12) {
                SgvSummaryView(state: context.state)
                Spacer()
                LiveBGExpandedTrailing(state: context.state)
            }
            .padding(16)
        }
    }
}

/// Large glucose value with trend arrow and delta.
private struct SgvSummaryView: View {
    let state: LiveBGAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(state.sgv)")
                .font(.system(size: 42, weight: .bold))
                .foregroundColor(estimateColor(state.sgv))
                .minimumScaleFactor(0.6)
                .contentTransition(.numericText())

            HStack(spacing: 6) {
                if let direction = state.direction {
                    Image(systemName: direction.systemImage)
                        .font(.body.bold())
                }
                Text(formatDelta(state.delta))
                    .font(.subheadline)
                Text(state.date, style: .offset)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// Compact glucose value used in the Dynamic Island compact/minimal layouts.
private struct SgvCompactView: View {
    let state: LiveBGAttributes.ContentState

    var body: some View {
        Text("\(state.sgv)")
            .font(.system(.caption2, design: .rounded).bold())
            .foregroundColor(estimateColor(state.sgv))
            .contentTransition(.numericText())
    }
}

/// Trend arrow used in the Dynamic Island compact trailing region.
private struct DirectionCompactView: View {
    let direction: Direction?

    var body: some View {
        if let direction = direction {
            Image(systemName: direction.systemImage)
                .font(.system(.caption2).bold())
                .foregroundColor(.white)
        } else {
            Image(systemName: "minus")
                .font(.system(.caption2).bold())
                .foregroundColor(.white)
        }
    }
}

/// Right-hand column of the expanded layout: IOB, COB and basal.
private struct LiveBGExpandedTrailing: View {
    let state: LiveBGAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            MetricRow(symbol: "circle.dashed", value: state.iob.map { String(format: "%.1f U", $0) } ?? "?")
            MetricRow(symbol: "carrot", value: {
                if let cob = state.cob {
                    return String(format: "%.0f g", cob)
                }
                return "?"
            }())
            if let basal = state.basal {
                MetricRow(symbol: "syringe", value: String(format: "%.2f U/h", basal))
            }
        }
        .font(.footnote)
    }
}

/// Bottom region of the expanded Dynamic Island layout.
private struct LiveBGExpandedBottom: View {
    let state: LiveBGAttributes.ContentState

    var body: some View {
        HStack {
            Text("\(state.sgv) mg/dl \(formatDelta(state.delta))")
                .font(.footnote)
            Spacer()
            Text(state.date, style: .timer)
                .font(.caption2)
        }
        .foregroundColor(.white)
    }
}

/// A small labeled metric row used in the trailing region.
private struct MetricRow: View {
    let symbol: String
    let value: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
                .frame(width: 14)
            Text(value)
        }
    }
}

/// Formats the change of the value against the previous reading.
private func formatDelta(_ delta: Int?) -> String {
    guard let delta = delta else {
        return "? mg/dl"
    }
    if delta == 0 {
        return "±0 mg/dl"
    }
    return String(format: "%+d mg/dl", delta)
}

private extension Direction {
    /// SF Symbol describing the glucose trend.
    var systemImage: String {
        switch self {
        case .doubleUp:
            return "arrow.up"
        case .singleUp:
            return "arrow.up.right"
        case .fortyFiveUp:
            return "arrow.up.right"
        case .flat:
            return "arrow.right"
        case .fortyFiveDown:
            return "arrow.down.right"
        case .singleDown:
            return "arrow.down.right"
        case .doubleDown:
            return "arrow.down"
        default:
            return "minus"
        }
    }
}

#Preview("Lock Screen", as: .content, using: LiveBGAttributes(startDate: .now)) {
    Loop_Follower_LiveActivity()
} contentStates: {
    LiveBGAttributes.ContentState(sgv: 120, delta: -5, direction: .fortyFiveDown, date: .now, iob: 1.2, cob: 8, basal: 0.45)
}
