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
                TextField(
                    text: $settings.url,
                    prompt: Text("https://nightscout.example.com")
                ) {
                    Text("URL")
                }
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .keyboardType(.URL)
                .textContentType(.URL)

                TextField(
                    text: $settings.token,
                    prompt: Text("your nightscout token")) {
                        Text("Token")
                    }.autocapitalization(.none)
                    .disableAutocorrection(true)
            }
        }
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
