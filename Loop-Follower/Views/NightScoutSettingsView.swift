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
            
        }.navigationBarTitle("Settings")
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
