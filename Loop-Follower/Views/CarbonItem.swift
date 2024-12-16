//
//  CarbonItem.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 28.08.23.
//

import SwiftUI

struct CarbonItem: View {

    @EnvironmentObject var settings: SettingsStore

    var carb: CarbCorrection
    
    var profile: Profile
    
    var bgEntry: Entry?
    
    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 3) {
                Label(
                    carb.foodType ?? "",
                    systemImage: "fork.knife"
                )
                if let bgEntry = bgEntry {
                    Spacer()
                    Label(
                        bgEntry.sgv.formatted(.number),
                        systemImage: "drop"
                    )
                }
            }
            .font(.headline)
            HStack(spacing: 3) {
                Label(
                    carb.mass.formatted(),
                    systemImage: "scalemass"
                )
                .font(.headline)
                Spacer()
                Label(
                    carb.absorption.formatted(
                        .measurement(
                            width: .narrow,
                            numberFormatStyle: .number.precision(.fractionLength(1)))
                    ),
                    systemImage: "stopwatch"
                )
                .font(.subheadline)
            }
            HStack {
                Label(
                    carb.date.formatted(
                        date: .abbreviated,
                        time: .shortened
                    ),
                    systemImage: "clock"
                )
                if let ratio = findCarbRatio(profile: profile, carb: carb) {
                    Spacer()
                    Label(
                        Measurement<UnitInsulin>(
                            value: calculateInsulinNeeds(carbs: carb.mass.value, factor: ratio.value, pumpResolution: settings.pumpRes),
                            unit: .insulin
                        ).formatted(.measurement(width: .abbreviated, numberFormatStyle: .number.precision(.fractionLength(2)))),
                        systemImage: "syringe"
                    )
                }
            }
            .font(.subheadline)
        }
    }
}

func findCarbRatio(profile: Profile, carb: CarbCorrection) -> Target? {
    for c in profile.carbratio.reversed() {
        if (Calendar.current.startOfDay(for: carb.date) + c.timeAsSeconds <= carb.date) {
            return c
        }
    }

    return nil;
}

func calculateInsulinNeeds(carbs: Double, factor: Double, pumpResolution: Double) -> Double {
    let needs = Int(carbs / pumpResolution / factor)
    
    return Double(needs) * pumpResolution
}

struct CarbonItem_Previews: PreviewProvider {
    static var previews: some View {
        CarbonItem(
            carb: CarbCorrection(
                id: "x",
                foodType: "🌮",
                absorptionTime: 210,
                carbs: 12.0,
                timestamp: "2023-08-28T12:00:00Z",
                created_at: "2023-08-28T12:00:00.000Z"
            ),
            profile: Profile(
                basal: [],
                target_low: [],
                target_high: [],
                sens: [],
                carbratio: [
                    Target(value: 10, timeAsSeconds: 0)
                ]
            )
        )
        .environmentObject(SettingsStore())
    }
}
