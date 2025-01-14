//
//  NotificationSettings.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 14/01/2025.
//

import Foundation

class NotificationSettings: ObservableObject {
    enum SoundType: String, Codable {
        case `default` = "default"
        case custom = "custom"
    }
    
    @Published var soundType: SoundType = .default
    @Published var customSoundURL: URL?
    
    private let userDefaults = UserDefaults.standard
    
    init() {
        loadSettings()
    }
    
    func saveSettings() {
        if let encoded = try? JSONEncoder().encode(soundType) {
            userDefaults.set(encoded, forKey: "notificationSoundType")
        }
        if let url = customSoundURL {
            userDefaults.set(url.path, forKey: "customSoundPath")
        }
    }
    
    private func loadSettings() {
        if let data = userDefaults.data(forKey: "notificationSoundType"),
           let decoded = try? JSONDecoder().decode(SoundType.self, from: data) {
            soundType = decoded
        }
        
        if let path = userDefaults.string(forKey: "customSoundPath") {
            customSoundURL = URL(fileURLWithPath: path)
        }
    }
}
