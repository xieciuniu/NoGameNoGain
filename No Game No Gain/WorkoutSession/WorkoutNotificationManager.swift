//
//  WorkoutNotificationManager.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 14/01/2025.
//

import Foundation
import UserNotifications

@MainActor
protocol WorkoutNotificationScheduling: AnyObject {
    func add(_ request: UNNotificationRequest)
    func removePending(identifiers: [String])
    func installForegroundPresentation()
}

extension WorkoutNotificationScheduling {
    func installForegroundPresentation() {}
}

/// Presents workout alerts while the app is open and talks to the system center.
/// The center keeps this object as a weak delegate, so the manager retains it.
@MainActor
final class SystemWorkoutNotificationScheduler: NSObject, WorkoutNotificationScheduling, UNUserNotificationCenterDelegate {
    private let center: UNUserNotificationCenter
    private var didRequestAuthorization = false

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func installForegroundPresentation() {
        center.delegate = self
    }

    func add(_ request: UNNotificationRequest) {
        installForegroundPresentation()
        requestAuthorizationIfNeeded()
        center.add(request) { error in
            if let error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }

    func removePending(identifiers: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler(WorkoutNotificationManager.presentationOptions(for: notification.request.identifier))
    }

    private func requestAuthorizationIfNeeded() {
        guard !didRequestAuthorization else { return }
        didRequestAuthorization = true
        center.requestAuthorization(options: [.alert, .sound]) { _, error in
            if let error {
                print("Error requesting notification authorization: \(error.localizedDescription)")
            }
        }
    }
}

struct WorkoutWatchAlert {
    var identifier: String
    var title: String
    var body: String
    var interval: TimeInterval
    var repeats: Bool
}

@MainActor
final class WorkoutNotificationManager: ObservableObject {
    nonisolated static let restIdentifier = "workout.rest"
    nonisolated static let inactivityIdentifier = "workout.inactivity"
    nonisolated static let inactivityInterval: TimeInterval = 7 * 60
    nonisolated static let scheduledAtKey = "scheduledAt"

    /// Forwards a scheduled alert to the Watch. A workout session hides mirrored phone banners.
    var onWatchAlert: ((WorkoutWatchAlert) -> Void)?
    var onClearWatchAlerts: (([String]) -> Void)?

    private let scheduler: WorkoutNotificationScheduling
    private let settings: NotificationSettings
    private let now: () -> Date

    init(
        settings: NotificationSettings,
        scheduler: WorkoutNotificationScheduling,
        now: @escaping () -> Date = Date.init
    ) {
        self.settings = settings
        self.scheduler = scheduler
        self.now = now
    }

    convenience init(settings: NotificationSettings) {
        self.init(settings: settings, scheduler: SystemWorkoutNotificationScheduler())
    }

    func installForegroundPresentation() {
        scheduler.installForegroundPresentation()
    }

    /// Replaces any pending rest alert. Does not reset the inactivity wait.
    func scheduleRest(after interval: TimeInterval) {
        guard interval > 0 else { return }
        let request = UNNotificationRequest(
            identifier: Self.restIdentifier,
            content: makeContent(title: "Rest Time Over", body: "Time to start next set!"),
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        )
        scheduler.add(request)
        onWatchAlert?(WorkoutWatchAlert(
            identifier: Self.restIdentifier,
            title: "Rest Time Over",
            body: "Time to start next set!",
            interval: interval,
            repeats: false
        ))
    }

    /// Cancels the pending inactivity reminder and starts a new 7 minute wait.
    /// The trigger repeats so the next reminder is due 7 minutes after each one.
    func userDidAct() {
        scheduler.removePending(identifiers: [Self.inactivityIdentifier])
        let request = UNNotificationRequest(
            identifier: Self.inactivityIdentifier,
            content: makeContent(
                title: "Workout Still in Progress",
                body: "You have not done anything in this workout for 7 minutes."
            ),
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: Self.inactivityInterval, repeats: true)
        )
        scheduler.add(request)
        onWatchAlert?(WorkoutWatchAlert(
            identifier: Self.inactivityIdentifier,
            title: "Workout Still in Progress",
            body: "You have not done anything in this workout for 7 minutes.",
            interval: Self.inactivityInterval,
            repeats: true
        ))
    }

    func clearScheduled() {
        let identifiers = [Self.restIdentifier, Self.inactivityIdentifier]
        scheduler.removePending(identifiers: identifiers)
        onClearWatchAlerts?(identifiers)
    }

    /// Options used while the workout screen is open. Unknown ids are still presented.
    nonisolated static func presentationOptions(for identifier: String) -> UNNotificationPresentationOptions {
        switch identifier {
        case restIdentifier, inactivityIdentifier:
            return [.banner, .list, .sound]
        default:
            return [.banner, .list, .sound]
        }
    }

    /// `nil` means the system default sound. A custom file contributes its last path component.
    nonisolated static func soundName(for settings: NotificationSettings) -> String? {
        guard settings.soundType == .custom, let soundURL = settings.customSoundURL else { return nil }
        return soundURL.lastPathComponent
    }

    private func makeContent(title: String, body: String) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.userInfo = [Self.scheduledAtKey: now().timeIntervalSince1970]
        if let name = Self.soundName(for: settings) {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: name))
        } else {
            content.sound = .default
        }
        return content
    }
}
