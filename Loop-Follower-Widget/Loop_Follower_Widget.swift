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
            let now = Date.now

            do {
                let entry = try await fetchCurrentBG()

                // next CGM value is expected ~5 min after the last one, plus some buffer
                var nextUpdate = Calendar.current.date(
                    byAdding: .minute,
                    value: 5,
                    to: entry.timestamp
                )!

                // next update in the past, find the next in future
                while nextUpdate < now {
                    nextUpdate = Calendar.current.date(
                        byAdding: .minute,
                        value: 5,
                        to: nextUpdate
                    )!
                }

                // that's the buffer
                nextUpdate = Calendar.current.date(
                    byAdding: .second,
                    value: 15,
                    to: nextUpdate
                )!

                completion(
                    Timeline(
                        entries: [entry],
                        policy: .after(nextUpdate)
                    )
                )
            } catch {
                print("could not load current BG: \(error)")
                // always deliver a timeline, otherwise no further reload is scheduled
                let fallback = CurrentBGEntry(date: now, sgv: 0, timestamp: now, delta: nil)
                completion(
                    Timeline(
                        entries: [fallback],
                        policy: .after(now.addingTimeInterval(5 * 60))
                    )
                )
            }
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

    let requestString = "\(baseUrl)/api/v1/entries/sgv.json?token=\(token)&count=4"
    guard let url = URL(string: requestString) else {
        throw URLError(.badURL)
    }

    // Fetch JSON data (widget extensions only get a short runtime)
    let request = URLRequest(url: url, timeoutInterval: 15)
    let (data, _) = try await URLSession.shared.data(for: request)

    // Parse the JSON data
    let entries = filterEntries(try JSONDecoder().decode([Entry].self, from: data))
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
            Text(entry.timestamp, style: .offset)
                .font(.subheadline)
                .multilineTextAlignment(.center)
            Text("\(entry.sgv)")
                .font(.system(size: 64, weight: .bold))
                .foregroundColor(estimateColor(entry.sgv))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
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

func filterEntries(_ entries : [Entry]) -> [Entry] {
    guard entries.count > 1 else { return entries }

    let interval : TimeInterval = 100
    var clearedEntries = zip(entries, entries.dropFirst()).filter { (e1, e2) in
        return abs(e1.date - e2.date) > interval
    }.map { (e1, e2) in
        return e1
    }
    
    guard let last = entries.last, let clearedLast = clearedEntries.last else {
        return entries
    }
    if (clearedLast.id != last.id && abs(clearedLast.date - last.date) > interval) {
        clearedEntries.append(last)
    }
    
    return clearedEntries
}

func estimateColor(_ sgv: Int) -> Color {
    if sgv <= 55 {
        return .red
    } else if sgv < 70 {
        return .yellow
    } else if sgv <= 180 {
        return .green
    } else if sgv <= 260 {
        return .yellow
    } else {
        return .red
    }
}

extension Date {
    static func - (lhs: Date, rhs: Date) -> TimeInterval {
        return lhs.timeIntervalSinceReferenceDate - rhs.timeIntervalSinceReferenceDate
    }
}

#Preview(as: .systemSmall) {
    Loop_Follower_Widget()
} timeline: {
    CurrentBGEntry(date: .now, sgv: 100, timestamp: .now, delta: -10)
}
