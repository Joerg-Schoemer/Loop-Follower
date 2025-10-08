//
//  CarbonDetails.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 12.12.24.
//

import SwiftUI

struct CarbonDetails: View {
    
    @EnvironmentObject var modelData : ModelData
    @EnvironmentObject var settings: SettingsStore
    
    var carb : Node<CarbCorrection>
    let insulinFormatStyle = Measurement<UnitInsulin>.FormatStyle(
        width: .abbreviated,
        usage: .asProvided,
        numberFormatStyle: .number.precision(.fractionLength(2))
    )

    var body: some View {
        VStack(spacing: 0) {
            List(carbs) { carb in
                CarbonItem(carb: carb.item, profile: modelData.profile!, bgEntry: findBgEntry(carb.item))
            }
            Spacer()
            HStack {
                Label(
                    Measurement<UnitMass>(value: carbs.map{ $0.item.carbs }.reduce(0, +), unit: .grams).formatted(),
                    systemImage: "scalemass"
                )
                Spacer()
                Label(
                    Measurement<UnitInsulin>(
                        value: carbs.map {
                            calculateInsulinNeeds(
                                carbs: $0.item.carbs,
                                factor: findCarbRatio(profile: modelData.profile!, carb: $0.item)!.value,
                                pumpResolution: settings.pumpRes
                            )
                        }.reduce(0, +),
                        unit: .insulin
                    ).formatted(insulinFormatStyle),
                    systemImage: "syringe"
                )
            }
            .padding(.horizontal, 20)
            .font(.subheadline)
            if let override = modelData.currentLoopData?.override {
                if override.active {
                    Spacer()
                    HStack {
                        Label(override.activeName, systemImage: "suit.heart")
                        Spacer()
                        Label(
                            Measurement<UnitInsulin>(
                                value: carbs.map {
                                    calculateInsulinNeeds(
                                        carbs: $0.item.carbs,
                                        factor: findCarbRatio(profile: modelData.profile!, carb: $0.item)!.value / (override.multiplier ?? 1.0),
                                        pumpResolution: settings.pumpRes
                                    )
                                }.reduce(0, +),
                                unit: .insulin
                            ).formatted(insulinFormatStyle),
                            systemImage: "syringe"
                        )
                    }
                    .padding(.horizontal, 20)
                    .font(.subheadline)
                }
            }

            Spacer()
            List(insulin) { insulin in
                InsulinItem(insulin: insulin)
            }
            Spacer()
            HStack() {
                Spacer()
                Label(
                    Measurement(value: insulin.map{ $0.insulin }.reduce(0, +), unit: .insulin).formatted(insulinFormatStyle),
                    systemImage: "syringe"
                )
            }
            .padding(.horizontal, 20)
            .font(.subheadline)
        }
    }
    
    var carbs : [Node<CarbCorrection>] {
        var items : [Node<CarbCorrection>] = []
        items.append(carb)

        let endOfAbsorption = carb.item.endOfHalfAbsorption
        
        var next = carb.next
        while (next != nil) {
            if next!.item.date < endOfAbsorption {
                items.append(next!)
                next = next?.next
            } else {
                break
            }
        }
        
        return items
    }
    
    var insulin : [CorrectionBolus] {
        let minutesBefore = -30

        let startDate = Calendar.current.date(byAdding: .minute, value: minutesBefore, to: carb.item.date)!
        
        let endOfAbsorption = carbs.map { $0.item.endOfAbsorption }.max()!

        let startOfNextMeal = if let nextMeal = carbs.last?.next {
            Calendar.current.date(byAdding: .minute, value: minutesBefore, to: nextMeal.item.date)
        } else {
            nil as Date?
        }

        let endDate = if startOfNextMeal != nil {
            min(endOfAbsorption, startOfNextMeal!)
        } else {
            endOfAbsorption
        }

        return  modelData.insulin.filter { item in
            item.date >= startDate && item.date <= endDate
        }.reversed()
    }
    
    func findBgEntry(_ carb: CarbCorrection) -> Entry? {
        return modelData.entries.first(where: { $0.date < carb.date })
    }
}

#Preview {
    CarbonDetails(
        carb: Node(
            item: CarbCorrection(
                id: "x",
                foodType: "🌮",
                absorptionTime: 180,
                carbs: 12.0,
                timestamp: "2023-08-28T12:00:00Z",
                created_at: "2023-08-28T12:00:00.000Z"
            ),
            next: Node(
                item: CarbCorrection(
                    id: "y",
                    foodType: "🌮",
                    absorptionTime: 180,
                    carbs: 12.0,
                    timestamp: "2023-08-28T15:00:00Z",
                    created_at: "2023-08-28T15:00:00.000Z"
                ),
                next: nil
            ))
    )
    .environmentObject(ModelData(test: true))
    .environmentObject(SettingsStore())
}
