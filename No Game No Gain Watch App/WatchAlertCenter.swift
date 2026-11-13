//
//  WatchAlertCenter.swift
//  No Game No Gain Watch App
//
//  Created by Hubert Wojtowicz on 07/11/2026.
//

import Foundation
import UserNotifications
import WatchKit

/// Shows the phone's rest and inactivity alerts on the Watch.
/// A running workout session hides the banners the phone would otherwise forward.
@MainActor
final class WatchAlertCenter: NSObject, UNUserNotificationCenterDelegate {
    static let shared = WatchAlertCenter()

    private var didRequestAuthorization = false
    private var seenSequence: [String: Int] = [:]

    func prepare() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        guard !didRequestAuthorization else { return }
        didRequestAuthorization = true
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func handle(_ message: [String: Any]) {
        let sequence = Self.intValue(message["seq"]) ?? 0
        let kind = message["kind"] as? String
        if kind == "alertClear" {
            let identifiers = (message["ids"] as? String)?
                .split(separator: ",")
                .map(String.init) ?? []
            var accepted: [String] = []
            for identifier in identifiers where sequence > (seenSequence[identifier] ?? 0) {
                seenSequence[identifier] = sequence
                accepted.append(identifier)
            }
            guard !accepted.isEmpty else { return }
            clear(accepted)
            return
        }
        guard kind == "alert", let identifier = message["id"] as? String else { return }
        guard sequence > (seenSequence[identifier] ?? 0) else { return }
        seenSequence[identifier] = sequence
        let after = Self.doubleValue(message["after"]) ?? 1
        schedule(
            identifier: identifier,
            title: message["title"] as? String ?? "",
            body: message["body"] as? String ?? "",
            after: after,
            repeats: Self.boolValue(message["repeats"])
        )
    }

    private func schedule(
        identifier: String,
        title: String,
        body: String,
        after: TimeInterval,
        repeats: Bool
    ) {
        prepare()
        let interval = repeats ? max(60, after) : max(1, after)
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: repeats)
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func clear(_ identifiers: [String]) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        Task { @MainActor in
            WKInterfaceDevice.current().play(.notification)
        }
        completionHandler([.banner, .list, .sound])
    }

    private static func boolValue(_ value: Any?) -> Bool {
        if let value = value as? Bool { return value }
        if let value = value as? NSNumber { return value.boolValue }
        return false
    }

    private static func intValue(_ value: Any?) -> Int? {
        if let value = value as? Int { return value }
        if let value = value as? NSNumber { return value.intValue }
        return nil
    }

    private static func doubleValue(_ value: Any?) -> Double? {
        if let value = value as? Double { return value }
        if let value = value as? NSNumber { return value.doubleValue }
        return nil
    }
}
