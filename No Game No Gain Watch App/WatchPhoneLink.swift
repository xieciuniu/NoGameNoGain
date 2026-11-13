//
//  WatchPhoneLink.swift
//  No Game No Gain Watch App
//
//  Created by Hubert Wojtowicz on 04/11/2026.
//

import Foundation
import WatchConnectivity

/// Receives the phone workout clock and sends heart rate and energy back.
/// WorkoutWatchLink on the phone writes the same keys.
@MainActor
final class WatchPhoneLink: NSObject, WCSessionDelegate {
    weak var controller: WatchWorkoutController?

    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        if session.activationState == .notActivated {
            session.activate()
        } else if !session.receivedApplicationContext.isEmpty {
            controller?.applyPhone(session.receivedApplicationContext)
        }
    }

    func latestPhoneContext() -> [String: Any] {
        guard WCSession.isSupported() else { return [:] }
        let session = WCSession.default
        guard session.activationState == .activated else { return [:] }
        return session.receivedApplicationContext
    }

    func sendMetrics(
        heartRateBPM: Double?,
        averageHeartRateBPM: Double?,
        maximumHeartRateBPM: Double?,
        activeEnergyKilocalories: Double?
    ) {
        guard heartRateBPM != nil || averageHeartRateBPM != nil || maximumHeartRateBPM != nil || activeEnergyKilocalories != nil else { return }
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        var message: [String: Any] = ["kind": "metrics"]
        if let heartRateBPM {
            message["hr"] = heartRateBPM
        }
        if let averageHeartRateBPM {
            message["hrAvg"] = averageHeartRateBPM
        }
        if let maximumHeartRateBPM {
            message["hrMax"] = maximumHeartRateBPM
        }
        if let activeEnergyKilocalories {
            message["kcal"] = activeEnergyKilocalories
        }
        try? session.updateApplicationContext(message)
        guard session.isReachable else { return }
        session.sendMessage(message, replyHandler: nil, errorHandler: nil)
    }

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        guard activationState == .activated else { return }
        let context = session.receivedApplicationContext
        Task { @MainActor in
            if !context.isEmpty {
                self.controller?.applyPhone(context)
            }
            self.controller?.pushMetricsToPhone()
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        let context = applicationContext
        Task { @MainActor in
            self.controller?.applyPhone(context)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        let message = message
        Task { @MainActor in
            self.deliver(message)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        let info = userInfo
        Task { @MainActor in
            self.deliver(info)
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        let context = session.receivedApplicationContext
        Task { @MainActor in
            if !context.isEmpty {
                self.controller?.applyPhone(context)
            }
            self.controller?.pushMetricsToPhone()
        }
    }

    private func deliver(_ message: [String: Any]) {
        let kind = message["kind"] as? String
        if kind == "alert" || kind == "alertClear" {
            controller?.applyAlert(message)
        } else {
            controller?.applyPhone(message)
        }
    }
}
