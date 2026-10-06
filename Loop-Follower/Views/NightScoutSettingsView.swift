//
//  NightScoutSettingsView.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 18.07.22.
//

import SwiftUI

struct NightScoutSettingsView: View {
    
    @EnvironmentObject var settings: SettingsStore
    
    var body: some View {
        Form {
            Section(header: Text("Nightscout")) {
                HStack {
                    Text("URL").font(.callout)
                    TextField(
                        "your Nightscout URL",
                        text: $settings.url
                    )
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .keyboardType(.URL)
                    .textContentType(.URL)
                }
                HStack {
                    Text("Token").font(.callout)
                    TextField(
                        "your Nightscout token",
                        text: $settings.token
                    )
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                }
            }
            
            Section(header: Text("Pump Settings")) {
                HStack {
                    Text("Resolution")
                    TextField(
                        "Resolution",
                        value: $settings.pumpRes,
                        format: .number.precision(.fractionLength(3))
                    )
                }
            }
            
            Section(header: Text("Alarm Settings")) {
                Stepper(
                    "Very Low: \(settings.veryLowThreshold) mg/dL",
                    value: thresholdBinding(
                        get: { settings.veryLowThreshold },
                        set: { settings.veryLowThreshold = $0 }
                    ),
                    in: 20...settings.lowThreshold - 1
                )
                Stepper(
                    "Low: \(settings.lowThreshold) mg/dL",
                    value: thresholdBinding(
                        get: { settings.lowThreshold },
                        set: { settings.lowThreshold = $0 }
                    ),
                    in: settings.veryLowThreshold + 1...settings.highThreshold - 1
                )
                Stepper(
                    "Low alarm after \(Int(settings.lowTime) / 60) min",
                    value: timeBinding(
                        get: { settings.lowTime },
                        set: { settings.lowTime = $0 }
                    ),
                    in: 1...120,
                    step: 1
                )
                Stepper(
                    "High: \(settings.highThreshold) mg/dL",
                    value: thresholdBinding(
                        get: { settings.highThreshold },
                        set: { settings.highThreshold = $0 }
                    ),
                    in: settings.lowThreshold + 1...settings.veryHighThreshold - 1
                )
                Stepper(
                    "High alarm after \(Int(settings.highTime) / 60) min",
                    value: timeBinding(
                        get: { settings.highTime },
                        set: { settings.highTime = $0 }
                    ),
                    in: 1...120,
                    step: 1
                )
                Stepper(
                    "Very High: \(settings.veryHighThreshold) mg/dL",
                    value: thresholdBinding(
                        get: { settings.veryHighThreshold },
                        set: { settings.veryHighThreshold = $0 }
                    ),
                    in: settings.highThreshold + 1...600
                )
            }
            
        }.navigationTitle("Settings")
        .onAppear {
            AlarmController.shared.updateSettings(from: settings)
        }
    }

    /// Binds a threshold value and forwards changes to the alarm controller.
    private func thresholdBinding(
        get: @escaping () -> Int,
        set: @escaping (Int) -> Void
    ) -> Binding<Int> {
        Binding(
            get: get,
            set: { newValue in
                set(newValue)
                AlarmController.shared.updateSettings(from: settings)
            }
        )
    }

    /// Binds a time value in seconds (displayed in minutes) and forwards changes.
    private func timeBinding(
        get: @escaping () -> TimeInterval,
        set: @escaping (TimeInterval) -> Void
    ) -> Binding<Int> {
        Binding(
            get: { Int(get()) / 60 },
            set: { set(TimeInterval($0) * 60); AlarmController.shared.updateSettings(from: settings) }
        )
    }
}

struct NightScoutSettingsView_Previews: PreviewProvider {
    
    static var previews: some View {
        Group {
            NightScoutSettingsView()
                .environmentObject(SettingsStore())
        }.previewLayout(.sizeThatFits)
    }
}
