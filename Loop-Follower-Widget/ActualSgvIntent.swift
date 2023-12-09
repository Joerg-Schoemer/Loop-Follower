//
//  AppIntent.swift
//  Loop-Follower-Widget
//
//  Created by Jörg Schömer on 16.11.23.
//

import WidgetKit
import AppIntents

struct ActualSgvIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configuration"

    @Parameter(title: "blood glucose value")
    var sgv: Int
    
    @Parameter(title: "timestamp of sgv")
    var timestamp: Date
    
    init(sgv: Int, timestamp: Date) {
        self.sgv = sgv
        self.timestamp = timestamp
    }
    
    init() {
        self.sgv = 0
        self.timestamp = Date.now
    }
}
