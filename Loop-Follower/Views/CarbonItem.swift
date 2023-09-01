//
//  CarbonItem.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 28.08.23.
//

import SwiftUI

struct CarbonItem: View {
    
    var carb : CarbCorrection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Label(
                carb.foodType!,
                systemImage: "fork.knife"
            )
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
                            width: .abbreviated,
                            numberFormatStyle: .number.precision(.fractionLength(1)))
                    ),
                    systemImage: "stopwatch"
                )
                .font(.subheadline)
            }
            Label(
                carb.date.formatted(
                    date: .abbreviated,
                    time: .shortened
                ),
                systemImage: "clock"
            ).font(.subheadline)
        }
    }
}

struct CarbonItem_Previews: PreviewProvider {
    static var previews: some View {
        CarbonItem(
            carb: CarbCorrection(
                id: "x",
                foodType: "🌮",
                absorptionTime: 180,
                carbs: 12.0,
                timestamp: "2023-08-28T12:00:00Z"
            )
        )
    }
}
