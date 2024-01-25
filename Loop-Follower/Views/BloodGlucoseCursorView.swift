//
//  GlucoseCursorView.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 24.01.24.
//

import SwiftUI

struct BloodGlucoseCursorView: View {
    
    let sgv : Int
    let date : Date

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7)
                .fill(Color(.systemGray6))
                .zIndex(-1)
                .shadow(radius: 5)
            HStack(spacing: 5) {
                Text("\(sgv)")
                    .bold()
                Text("\(date.formatted(date: .omitted, time: .shortened))")
            }
            .font(.caption)
            .padding(4)
        }
    }
}

#Preview {
    BloodGlucoseCursorView(sgv: 100, date: .now)
}
