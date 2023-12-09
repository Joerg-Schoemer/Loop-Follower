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
    }
    
    private let cancellable: Cancellable
    private let defaults: UserDefaults
    
    let objectWillChange = PassthroughSubject<Void, Never>()
    
    init(defaults: UserDefaults = UserDefaults(suiteName: "group.loop.follower")!) {
        self.defaults = defaults
        
        defaults.register(defaults: [
            Keys.url: "",
            Keys.token: "",
            Keys.pumpRes: 0.05
        ])
        
        cancellable = NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification)
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
}

