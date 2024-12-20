//
//  InsulinItem.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 28.08.23.
//

import SwiftUI

struct InsulinItem: View {

    var insulin : CorrectionBolus
    
    let insulinFormatStyle = Measurement<UnitInsulin>.FormatStyle(
        width: .abbreviated,
        usage: .asProvided,
        numberFormatStyle: .number.precision(.fractionLength(2))
    )

    var body: some View {
        HStack(spacing: 3) {
            Label(
                insulin.date.formatted(
                    date: .abbreviated,
                    time: .shortened
                ),
                systemImage: "clock"
            )
            .font(.subheadline)
            Spacer()
            Label(
                insulin.amount.formatted(insulinFormatStyle),
                systemImage: "syringe"
            )
            .font(.headline)
        }
    }
}

struct InsulinItem_Previews: PreviewProvider {
    static var previews: some View {
        InsulinItem(
            insulin: CorrectionBolus(
                id: "x",
                insulin: 1.2,
                timestamp: "2023-08-28T12:00:00Z",
                created_at: "2023-08-28T12:00:00.000Z"
            )
        ).previewLayout(.fixed(width: 300, height: 70))
    }
}
