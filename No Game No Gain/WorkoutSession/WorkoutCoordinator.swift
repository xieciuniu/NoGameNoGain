//
//  WorkoutCoordinator.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 24/10/2026.
//

import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class WorkoutCoordinator {
    private(set) var stopwatch: Stopwatch
    let notifications: WorkoutNotificationManager
    private let healthRecorder: WorkoutHealthRecorder
    private let watchLink = WorkoutWatchLink()
    private var restTarget: TimeInterval = 0
    private(set) var heartRateBPM: Double?
    private(set) var averageHeartRateBPM: Double?
    private(set) var maximumHeartRateBPM: Double?
    private(set) var activeEnergyKilocalories: Double?
    /// A Watch is in this workout, or a heart-rate sample has arrived from AirPods or a monitor.
    private(set) var hasTrackingDevice = false
    private(set) var companionEnded = false

    init(
        notifications: WorkoutNotificationManager,
        health: any WorkoutHealthRecording = HealthKitManager.shared
    ) {
        self.stopwatch = Stopwatch()
        self.notifications = notifications
        self.healthRecorder = WorkoutHealthRecorder(health: health)
        connectHealthRecorder()
    }

    init(
        stopwatch: Stopwatch,
        notifications: WorkoutNotificationManager,
        health: any WorkoutHealthRecording = HealthKitManager.shared
    ) {
        self.stopwatch = stopwatch
        self.notifications = notifications
        self.healthRecorder = WorkoutHealthRecorder(health: health)
        connectHealthRecorder()
    }

    convenience init() {
        self.init(notifications: WorkoutNotificationManager(settings: NotificationSettings()))
    }

    /// Inserts one open session and starts both clocks.
    /// An empty plan inserts nothing. A session that is already open is returned as it is.
    @discardableResult
    func start(workout: Workout, in context: ModelContext) -> WorkoutSession? {
        guard !workout.exercises.isEmpty else { return nil }
        if let open = openSession(in: context) {
            return open
        }

        companionEnded = false
        heartRateBPM = nil
        averageHeartRateBPM = nil
        maximumHeartRateBPM = nil
        activeEnergyKilocalories = nil
        hasTrackingDevice = false
        let session = WorkoutSession(workout: workout, startTime: stopwatch.currentDate())
        context.insert(session)
        save(context)
        stopwatch.start()
        notifications.userDidAct()
        keepWatchClockSynced()
        healthRecorder.startCompanion()
        return session
    }

    /// Keeps the Watch timer on this phone clock while an open workout is on screen.
    func keepWatchClockSynced() {
        watchLink.begin { [weak self] in
            guard let self else { return (0, false, 0, false, 0) }
            return (
                self.stopwatch.workoutElapsed,
                self.stopwatch.isRunning,
                self.stopwatch.restElapsed(at: self.stopwatch.currentDate()),
                self.stopwatch.isRunningMSMs,
                self.restTarget
            )
        }
    }

    /// The Watch shows this exercise's rest setting under the time since the last set.
    func setWatchRestTarget(_ seconds: TimeInterval) {
        restTarget = max(0, seconds)
        watchLink.publishNow()
    }

    func pause() {
        stopwatch.stop()
        notifications.userDidAct()
        healthRecorder.pauseCompanion()
        watchLink.publishNow()
    }

    func resume() {
        stopwatch.start()
        notifications.userDidAct()
        healthRecorder.resumeCompanion()
        watchLink.publishNow()
    }

    /// Attaches a Watch session recovered at launch when an open workout is still on the phone.
    func resolveRecoveredCompanion(openWorkoutExists: Bool) {
        healthRecorder.resolveRecovery(openWorkoutExists: openWorkoutExists)
    }

    /// Stamps the session from the workout clock, then clears that clock.
    /// Experience and load progression run before the stamp, and only on the first end.
    func end(
        _ session: WorkoutSession,
        account: UserAccount,
        completion: WorkoutCompletion = WorkoutCompletion()
    ) {
        // A second tap must not rewrite duration after the clock is cleared.
        guard session.endTime == nil else { return }
        let duration = stopwatch.workoutElapsed
        watchLink.end(elapsed: duration)
        completion.finish(session: session, account: account, duration: duration)
        session.endTime = stopwatch.currentDate()
        session.duration = duration
        session.averageHeartRateBPM = averageHeartRateBPM
        session.maximumHeartRateBPM = maximumHeartRateBPM
        heartRateBPM = nil
        averageHeartRateBPM = nil
        maximumHeartRateBPM = nil
        activeEnergyKilocalories = nil
        hasTrackingDevice = false
        if let context = session.modelContext {
            save(context)
        }
        healthRecorder.recordEndedSession(session)
        stopwatch.reset()
        notifications.clearScheduled()
    }

    private func connectHealthRecorder() {
        let applyMetrics: (WorkoutLiveMetrics) -> Void = { [weak self] metrics in
            if let heartRate = metrics.heartRateBPM {
                self?.heartRateBPM = heartRate
            }
            if let average = metrics.averageHeartRateBPM {
                self?.averageHeartRateBPM = average
            }
            if let maximum = metrics.maximumHeartRateBPM {
                self?.maximumHeartRateBPM = maximum
            }
            if metrics.heartRateBPM != nil || metrics.averageHeartRateBPM != nil || metrics.maximumHeartRateBPM != nil {
                self?.hasTrackingDevice = true
            }
            if let energy = metrics.activeEnergyKilocalories {
                self?.activeEnergyKilocalories = energy
            }
        }
        healthRecorder.onMetrics = applyMetrics
        healthRecorder.onTrackingDevice = { [weak self] in
            self?.hasTrackingDevice = true
        }
        watchLink.onMetrics = applyMetrics
        healthRecorder.onCompanionEnded = { [weak self] in
            self?.companionEnded = true
        }
        healthRecorder.prepare()
        watchLink.warmUp()
        notifications.onWatchAlert = { [weak self] alert in
            self?.watchLink.mirrorAlert(alert)
        }
        notifications.onClearWatchAlerts = { [weak self] identifiers in
            self?.watchLink.clearMirroredAlerts(identifiers)
        }
    }

    private func openSession(in context: ModelContext) -> WorkoutSession? {
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate<WorkoutSession> { session in
                session.endTime == nil
            }
        )
        return try? context.fetch(descriptor).first
    }

    private func save(_ context: ModelContext) {
        try? context.save()
    }
}
