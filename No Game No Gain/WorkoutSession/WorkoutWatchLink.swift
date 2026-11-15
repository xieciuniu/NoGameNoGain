//
//  WorkoutWatchLink.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 04/11/2026.
//

import Foundation
import WatchConnectivity

/// A Watch heart-rate payload for one phone workout.
/// `WCSession` keeps the last application context until the Watch replaces it, so a payload
/// without this workout's id is the previous session and must not be shown.
enum WatchLinkMetrics {
    static func liveMetrics(from message: [String: Any], workoutID: String) -> WorkoutLiveMetrics? {
        guard (message["kind"] as? String) == "metrics" else { return nil }
        guard (message["id"] as? String) == workoutID else { return nil }
        let metrics = WorkoutLiveMetrics(
            heartRateBPM: number(message["hr"]),
            averageHeartRateBPM: number(message["hrAvg"]),
            maximumHeartRateBPM: number(message["hrMax"]),
            activeEnergyKilocalories: number(message["kcal"])
        )
        guard metrics.heartRateBPM != nil
            || metrics.averageHeartRateBPM != nil
            || metrics.maximumHeartRateBPM != nil
            || metrics.activeEnergyKilocalories != nil else { return nil }
        return metrics
    }

    static func number(_ value: Any?) -> Double? {
        if let value = value as? Double { return value }
        if let value = value as? NSNumber { return value.doubleValue }
        return nil
    }
}

/// Sends the phone workout clock to the Watch and receives live heart rate and energy.
/// The Watch app reads the same keys in WatchPhoneLink.
@MainActor
final class WorkoutWatchLink: NSObject, WCSessionDelegate {
    var onMetrics: ((WorkoutLiveMetrics) -> Void)?

    private var workoutID = UUID()
    private var sequence = 0
    private var ended = false
    private var didQueueEndTransfer = false
    private var relay: Task<Void, Never>?
    private var readClock: (@MainActor () -> (elapsed: TimeInterval, running: Bool, rest: TimeInterval, restRunning: Bool, restTarget: TimeInterval))?
    private var latest: [String: Any]?
    private var alertSequence = 0
    private var pendingAlerts: [[String: Any]] = []

    /// Activates the session early so the first clock update is not dropped.
    func warmUp() {
        activate()
    }

    func begin(readClock: @escaping @MainActor () -> (elapsed: TimeInterval, running: Bool, rest: TimeInterval, restRunning: Bool, restTarget: TimeInterval)) {
        if relay != nil, !ended {
            self.readClock = readClock
            publishNow()
            return
        }
        relay?.cancel()
        relay = nil
        didQueueEndTransfer = false
        workoutID = UUID()
        sequence = 0
        ended = false
        self.readClock = readClock
        activate()
        publishNow()
        relay = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { return }
                publishNow()
            }
        }
    }

    func publishNow() {
        guard !ended, let readClock else { return }
        let clock = readClock()
        send(
            elapsed: clock.elapsed,
            running: clock.running,
            rest: clock.rest,
            restRunning: clock.restRunning,
            restTarget: clock.restTarget,
            ended: false
        )
    }

    func end(elapsed: TimeInterval) {
        let clock = readClock?()
        ended = true
        relay?.cancel()
        relay = nil
        readClock = nil
        activate()
        send(
            elapsed: elapsed,
            running: false,
            rest: clock?.rest ?? 0,
            restRunning: false,
            restTarget: clock?.restTarget ?? 0,
            ended: true
        )
        // One update can be dropped while the Watch is still launching. Keep the ended clock current.
        relay = Task { @MainActor in
            for _ in 0..<30 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { return }
                flush()
            }
        }
    }

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        guard activationState == .activated else { return }
        deliverMetrics(session.receivedApplicationContext)
        Task { @MainActor in
            self.flush()
            self.flushPendingAlerts()
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
    }

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        Task { @MainActor in
            self.activate()
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        deliverMetrics(session.receivedApplicationContext)
        guard session.isReachable else { return }
        Task { @MainActor in
            self.flush()
            self.flushPendingAlerts()
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        deliverMetrics(message)
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        deliverMetrics(applicationContext)
    }

    nonisolated private func deliverMetrics(_ message: [String: Any]) {
        Task { @MainActor in
            guard !self.ended, self.readClock != nil else { return }
            guard let metrics = WatchLinkMetrics.liveMetrics(from: message, workoutID: self.workoutID.uuidString) else { return }
            self.onMetrics?(metrics)
        }
    }

    private var canReachWatch: Bool {
        let environment = ProcessInfo.processInfo.environment
        let underTest = environment["XCTestConfigurationFilePath"] != nil
            || environment["XCTestBundlePath"] != nil
            || environment["XCTestSessionIdentifier"] != nil
        return !underTest && WCSession.isSupported()
    }

    private func activate() {
        guard canReachWatch else { return }
        let session = WCSession.default
        session.delegate = self
        if session.activationState == .notActivated {
            session.activate()
        }
    }

    private func send(
        elapsed: TimeInterval,
        running: Bool,
        rest: TimeInterval,
        restRunning: Bool,
        restTarget: TimeInterval,
        ended: Bool
    ) {
        sequence += 1
        latest = [
            "kind": "clock",
            "id": workoutID.uuidString,
            "seq": sequence,
            "elapsed": elapsed,
            "running": running,
            "rest": rest,
            "restRun": restRunning,
            "restSet": restTarget,
            "ended": ended
        ]
        flush()
    }

    private func flush() {
        ingestQueuedMetrics()
        guard let latest else { return }
        guard canReachWatch else { return }
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        try? session.updateApplicationContext(latest)
        if ended, !didQueueEndTransfer {
            didQueueEndTransfer = true
            session.transferUserInfo(latest)
        }
        guard session.isReachable else { return }
        session.sendMessage(latest, replyHandler: nil) { _ in }
    }

    /// Rest and inactivity alerts. These stay off the clock context so a timer update cannot erase them.
    func mirrorAlert(_ alert: WorkoutWatchAlert) {
        postAlert([
            "kind": "alert",
            "id": alert.identifier,
            "title": alert.title,
            "body": alert.body,
            "after": alert.interval,
            "repeats": alert.repeats
        ])
    }

    func clearMirroredAlerts(_ identifiers: [String]) {
        postAlert([
            "kind": "alertClear",
            "ids": identifiers.joined(separator: ",")
        ])
    }

    private func postAlert(_ payload: [String: Any]) {
        guard canReachWatch else { return }
        activate()
        alertSequence += 1
        var message = payload
        message["seq"] = alertSequence
        let session = WCSession.default
        guard session.activationState == .activated else {
            pendingAlerts.append(message)
            return
        }
        sendAlertNow(message, session: session)
    }

    private func flushPendingAlerts() {
        guard canReachWatch else { return }
        let session = WCSession.default
        guard session.activationState == .activated, !pendingAlerts.isEmpty else { return }
        let queued = pendingAlerts
        pendingAlerts.removeAll()
        for message in queued {
            sendAlertNow(message, session: session)
        }
    }

    private func sendAlertNow(_ message: [String: Any], session: WCSession) {
        session.transferUserInfo(message)
        guard session.isReachable else { return }
        session.sendMessage(message, replyHandler: nil) { _ in }
    }

    /// The Watch keeps the newest heart-rate sample in its application context. Read it even if the delegate call was missed.
    private func ingestQueuedMetrics() {
        guard canReachWatch else { return }
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        let context = session.receivedApplicationContext
        guard !context.isEmpty else { return }
        deliverMetrics(context)
    }
}
