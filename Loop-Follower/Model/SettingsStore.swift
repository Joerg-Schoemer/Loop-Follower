//
//  SettingsStore.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 18.07.22.
//

import Foundation
import Combine

class SettingsStore  : ObservableObject  {
    
    enum Keys {
        static let url = "url"
        static let token = "token"
        static let pumpRes = "pumpResolution"
        static let veryLowThreshold = "veryLowThreshold"
        static let lowThreshold = "lowThreshold"
        static let lowTime = "lowTime"
        static let highThreshold = "highThreshold"
        static let highTime = "highTime"
        static let veryHighThreshold = "veryHighThreshold"
    }
    
    private let cancellable: Cancellable
    private let defaults: UserDefaults
    
    let objectWillChange = PassthroughSubject<Void, Never>()
    
    init(defaults: UserDefaults = UserDefaults(suiteName: "group.loop.follower")!) {
        self.defaults = defaults
        
        defaults.register(defaults: [
            Keys.url: "",
            Keys.token: "",
            Keys.pumpRes: 0.05,
            Keys.veryLowThreshold: 55,
            Keys.lowThreshold: 70,
            Keys.lowTime: 10 * 60,
            Keys.highThreshold: 180,
            Keys.highTime: 15 * 60,
            Keys.veryHighThreshold: 260
        ])
        
        cancellable = NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification)
            .receive(on: DispatchQueue.main)
            .map { _ in () }
            .subscribe(objectWillChange)
    }

    var url: String {
        set { defaults.set(newValue, forKey: Keys.url) }
        get { defaults.string(forKey: Keys.url)! }
    }

    var token: String {
        set { defaults.set(newValue, forKey: Keys.token) }
        get { defaults.string(forKey: Keys.token)! }
    }
    
    var pumpRes: Double {
        set { defaults.set(newValue, forKey: Keys.pumpRes) }
        get { defaults.double(forKey: Keys.pumpRes) }
    }

    var veryLowThreshold: Int {
        set { defaults.set(newValue, forKey: Keys.veryLowThreshold) }
        get { defaults.integer(forKey: Keys.veryLowThreshold) }
    }

    var lowThreshold: Int {
        set { defaults.set(newValue, forKey: Keys.lowThreshold) }
        get { defaults.integer(forKey: Keys.lowThreshold) }
    }

    /// Time in seconds below ``lowThreshold`` before the low alarm fires.
    var lowTime: TimeInterval {
        set { defaults.set(newValue, forKey: Keys.lowTime) }
        get { defaults.double(forKey: Keys.lowTime) }
    }

    var highThreshold: Int {
        set { defaults.set(newValue, forKey: Keys.highThreshold) }
        get { defaults.integer(forKey: Keys.highThreshold) }
    }

    /// Time in seconds above ``highThreshold`` before the high alarm fires.
    var highTime: TimeInterval {
        set { defaults.set(newValue, forKey: Keys.highTime) }
        get { defaults.double(forKey: Keys.highTime) }
    }

    var veryHighThreshold: Int {
        set { defaults.set(newValue, forKey: Keys.veryHighThreshold) }
        get { defaults.integer(forKey: Keys.veryHighThreshold) }
    }
}

