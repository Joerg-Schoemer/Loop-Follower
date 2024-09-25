//
//  Loop_Follower_Widget.swift
//  Loop-Follower-Widget
//
//  Created by Jörg Schömer on 16.11.23.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    typealias Entry = CurrentBGEntry
    
    func placeholder(in context: Context) -> CurrentBGEntry {
        return CurrentBGEntry(date: .now, sgv: 101, timestamp: .now, delta: 10)
    }

    func getSnapshot(in context: Context, completion: @escaping (CurrentBGEntry) -> Void) {
        completion(CurrentBGEntry(date: .now, sgv: 100, timestamp: .now, delta: 0))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<CurrentBGEntry>) -> Void) {

        Task {
            guard let entry = try? await fetchCurrentBG() else {
                print("could not load current BG :-(")
                return
            }
            
            var nextUpdate = Calendar.current.date(
                byAdding: DateComponents(minute: 1),
                to: entry.timestamp
            )!

            while nextUpdate < .now {
                nextUpdate = Calendar.current.date(byAdding: .second, value: 30, to: nextUpdate)!
            }

            completion(Timeline(
                entries: [entry],
                policy: .after(nextUpdate)
            ))
        }
    }
}

struct CurrentBGEntry: TimelineEntry {
    let date: Date
    let sgv: Int
    let timestamp: Date
    let delta: Int?
    
    fileprivate func formatDelta() -> String {
        if let delta = self.delta {
            if delta == 0 {
                return String(format: "±%d mg/dl", delta)
            }
            return String(format: "%+d mg/dl", delta)
        } else {
            return "? mg/dl"
        }
    }
}

func fetchCurrentBG() async throws -> CurrentBGEntry {
    let store = SettingsStore()
    let baseUrl = store.url
    let token = store.token

    let requestString = "\(baseUrl)/api/v1/entries/sgv.json?token=\(token)&count=2"
    let url = URL(string: requestString)!

    // Fetch JSON data
    let (data, _) = try await URLSession.shared.data(from: url)

    // Parse the JSON data
    let entries = try! JSONDecoder().decode([Entry].self, from: data)
    if let entry = entries.first {
        print("entry = \(entry)")

        var delta : Int? = nil
        if (entries.count > 1) {
            let prevEntry = entries[1]
            print("prevEntry = \(prevEntry)")

            delta = entry.sgv - prevEntry.sgv
        }

        return CurrentBGEntry(date: .now, sgv: entry.sgv, timestamp: entry.date, delta: delta)
    }

    return CurrentBGEntry(date: .now, sgv: 0, timestamp: .now, delta: 0)
}

struct Loop_Follower_WidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            Text("\(entry.timestamp.formatted(date: .omitted, time: .standard))")
                .font(.subheadline)
            Text("\(entry.sgv)")
                .font(.title)
            Text("\(entry.formatDelta())")
                .font(.subheadline)
        }
    }
}

struct Loop_Follower_Widget: Widget {
    let kind: String = "Loop_Follower_Widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: Provider()
        ) { entry in
            Loop_Follower_WidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Loop Follower Widget")
        .description("Loop Follower Widget showing current BG")
        .supportedFamilies([.systemSmall, .accessoryCircular])
    }
}

#Preview(as: .systemSmall) {
    Loop_Follower_Widget()
} timeline: {
    CurrentBGEntry(date: .now, sgv: 100, timestamp: .now, delta: -10)
}
