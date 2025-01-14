//
//  WorkoutNotificationManager.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 14/01/2025.
//

import Foundation
import UserNotifications

class WorkoutNotificationManager: ObservableObject {
    private var notificationCenter: UNUserNotificationCenter
    private var settings: NotificationSettings
    private var currentNotificationId: String?
    
    init(settings: NotificationSettings) {
        self.settings = settings
        self.notificationCenter = UNUserNotificationCenter.current()
        requestAuthorization()
    }
    
    private func requestAuthorization() {
        notificationCenter.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Error requesting notification authorization: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleNotification(after timeInterval: TimeInterval) {
        // Anuluj poprzednie powiadomienie
        cancelCurrentNotification()
        
        let content = UNMutableNotificationContent()
        content.title = "Rest Time Over"
        content.body = "Time to start next set!"
        
        // Ustaw dźwięk na podstawie ustawień
        if settings.soundType == .custom, let soundURL = settings.customSoundURL {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: soundURL.lastPathComponent))
        } else {
            content.sound = UNNotificationSound.default
        }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let identifier = UUID().uuidString
        currentNotificationId = identifier
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    func cancelCurrentNotification() {
        if let id = currentNotificationId {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: [id])
            currentNotificationId = nil
        }
    }
}
