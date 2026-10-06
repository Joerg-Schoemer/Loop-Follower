//
//  AlarmBanner.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 06.10.26.
//

import SwiftUI

/// Full-width, persistent banner shown while the critical glucose alarm rings.
/// It keeps the alarm visible until the user acknowledges it.
struct AlarmBanner: View {

    let sgv: Int?
    let onAcknowledge: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Label(
                NSLocalizedString("ALARM", comment: "Critical glucose alarm title"),
                systemImage: "exclamationmark.triangle.fill"
            )
            .font(.headline)

            if let sgv {
                Text("\(sgv) mg/dl")
                    .font(.largeTitle.bold())
            }

            Button(action: onAcknowledge) {
                Text(NSLocalizedString("Acknowledge", comment: "Confirm the alarm"))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.white)
            .foregroundColor(.black)
        }
        .foregroundColor(.white)
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.red)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding([.leading, .trailing, .top])
        .shadow(radius: 4)
    }
}

#Preview {
    AlarmBanner(sgv: 300, onAcknowledge: {})
}
