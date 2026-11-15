//
//  WorkoutHealthRecorder.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 25/10/2026.
//

import Foundation
import HealthKit

enum TraditionalStrengthWorkout {
    static func configuration() -> HKWorkoutConfiguration {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .traditionalStrengthTraining
        configuration.locationType = .indoor
        return configuration
    }

    static func endDate(start: Date, duration: TimeInterval) -> Date {
        start.addingTimeInterval(duration)
    }
}

/// Writes one finished Traditional Strength Training workout for an ended session.
/// A mirrored Watch session saves its own builder sample.
/// On iOS 26, a phone session does the same when the Watch does not launch.
/// Pause, rest, and a still-open session do not come through here.
@MainActor
final class WorkoutHealthRecorder {
    private let health: any WorkoutHealthRecording
    private var savedSessionIDs: Set<UUID> = []
    private var link: CompanionLink = .idle
    private var didPrepare = false
    private var userDidStartCompanion = false
    private var didEndOrphan = false
    private var recoveryKind: RecoveredWorkoutSessionKind?
    private var openWorkoutExists: Bool?
    private var recoveryApplied = false
    private var pauseWhenMirrored = false
    private var deferredSave: (start: Date, duration: TimeInterval)?
    /// `startWatchApp` already returned. End must not leave the link waiting for that result.
    private var watchLaunchSucceeded = false

    var onMetrics: ((WorkoutLiveMetrics) -> Void)?
    var onCompanionEnded: (() -> Void)?
    var onTrackingDevice: (() -> Void)?

    init(health: any WorkoutHealthRecording) {
        self.health = health
    }

    func prepare() {
        guard !didPrepare else { return }
        didPrepare = true
        health.installCompanion(
            onMirrored: { [weak self] in self?.handleMirrored() },
            onEnded: { [weak self] in self?.handleRemoteEnded() },
            onMetrics: { [weak self] metrics in self?.onMetrics?(metrics) },
            onRecovered: { [weak self] kind in self?.handleRecovered(kind) },
            onPhoneFailed: { [weak self] in self?.handlePhoneFailed() }
        )
    }

    /// Asks the Watch to open one indoor strength session. A session that is already mirrored is left alone.
    /// A finished session can start again for the next workout.
    func startCompanion() {
        switch link {
        case .idle, .unavailable, .ended:
            break
        case .endWhileLaunching:
            // The launch already succeeded and the mirror never arrived. The next workout can start.
            guard watchLaunchSucceeded else { return }
            link = .ended
            deferredSave = nil
        case .launching, .mirrored, .phone:
            return
        }
        didEndOrphan = false
        pauseWhenMirrored = false
        watchLaunchSucceeded = false
        userDidStartCompanion = true
        link = .launching
        health.requestAuthorizationIfNeeded { [weak self] _, _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                guard self.link == .launching || self.link == .endWhileLaunching else { return }
                self.health.startWatchApp(configuration: TraditionalStrengthWorkout.configuration()) { success in
                    MainActor.assumeIsolated {
                        self.handleLaunch(success)
                    }
                }
            }
        }
    }

    func pauseCompanion() {
        switch link {
        case .mirrored:
            health.pauseLiveSession()
        case .phone:
            health.pausePhoneSession()
        case .launching, .endWhileLaunching:
            pauseWhenMirrored = true
        case .idle, .unavailable, .ended:
            break
        }
    }

    func resumeCompanion() {
        pauseWhenMirrored = false
        switch link {
        case .mirrored:
            health.resumeLiveSession()
        case .phone:
            health.resumePhoneSession()
        case .idle, .launching, .unavailable, .endWhileLaunching, .ended:
            break
        }
    }

    func recordEndedSession(_ session: WorkoutSession) {
        guard session.endTime != nil else { return }
        guard savedSessionIDs.insert(session.id).inserted else { return }
        switch link {
        case .mirrored:
            link = .ended
            deferredSave = nil
            health.endLiveSession()
        case .phone:
            link = .ended
            let start = session.startTime
            let duration = session.duration
            health.endPhoneSession { [weak self] saved in
                MainActor.assumeIsolated {
                    guard let self, !saved else { return }
                    self.save(start: start, duration: duration)
                }
            }
        case .launching:
            if watchLaunchSucceeded {
                link = .ended
                deferredSave = nil
            } else {
                link = .endWhileLaunching
                deferredSave = (session.startTime, session.duration)
            }
        case .endWhileLaunching, .ended:
            break
        case .idle, .unavailable:
            save(start: session.startTime, duration: session.duration)
        }
    }

    /// Keeps a recovered Watch or phone session only while this phone still has an open workout.
    /// A later `true` wins over an earlier `false`.
    func resolveRecovery(openWorkoutExists: Bool) {
        if openWorkoutExists {
            self.openWorkoutExists = true
        } else if self.openWorkoutExists == true {
            return
        } else {
            self.openWorkoutExists = false
        }
        applyRecovery()
    }

    private func handleLaunch(_ success: Bool) {
        switch link {
        case .launching:
            if success {
                watchLaunchSucceeded = true
                onTrackingDevice?()
            } else {
                startPhoneSessionAfterWatchFailure()
            }
        case .endWhileLaunching:
            if success {
                watchLaunchSucceeded = true
            } else {
                startPhoneSessionAfterWatchFailure()
            }
        case .idle, .mirrored, .phone, .unavailable, .ended:
            break
        }
    }

    private func startPhoneSessionAfterWatchFailure() {
        guard link == .launching || link == .endWhileLaunching else { return }
        health.startPhoneSession(configuration: TraditionalStrengthWorkout.configuration()) { [weak self] started in
            MainActor.assumeIsolated {
                guard let self else { return }
                switch self.link {
                case .launching:
                    if started {
                        self.link = .phone
                        if self.pauseWhenMirrored {
                            self.pauseWhenMirrored = false
                            self.health.pausePhoneSession()
                        }
                    } else {
                        self.link = .unavailable
                    }
                case .endWhileLaunching:
                    if started {
                        self.link = .ended
                        self.health.endPhoneSession { saved in
                            MainActor.assumeIsolated {
                                if saved {
                                    self.deferredSave = nil
                                } else {
                                    self.saveDeferred()
                                }
                            }
                        }
                    } else {
                        self.link = .unavailable
                        self.saveDeferred()
                    }
                case .idle, .mirrored, .phone, .unavailable, .ended:
                    if started {
                        self.health.discardPhoneSession()
                    }
                }
            }
        }
    }

    private func handleMirrored() {
        if didEndOrphan { return }
        switch link {
        case .endWhileLaunching:
            link = .ended
            deferredSave = nil
            health.endLiveSession()
        case .ended:
            break
        case .idle, .launching, .mirrored, .phone, .unavailable:
            if link == .phone {
                health.discardPhoneSession()
            }
            link = .mirrored
            onTrackingDevice?()
            if pauseWhenMirrored {
                pauseWhenMirrored = false
                health.pauseLiveSession()
            }
        }
    }

    private func handleRemoteEnded() {
        guard link == .mirrored || link == .launching || link == .endWhileLaunching else { return }
        link = .ended
        deferredSave = nil
        onCompanionEnded?()
    }

    private func handlePhoneFailed() {
        guard link == .phone else { return }
        link = .unavailable
    }

    private func handleRecovered(_ kind: RecoveredWorkoutSessionKind) {
        recoveryKind = kind
        applyRecovery()
    }

    private func applyRecovery() {
        guard !recoveryApplied, let kind = recoveryKind, let open = openWorkoutExists else { return }
        if userDidStartCompanion {
            recoveryApplied = true
            return
        }
        recoveryApplied = true
        switch kind {
        case .none:
            return
        case .mirrored:
            if open {
                link = .mirrored
                onTrackingDevice?()
            } else {
                didEndOrphan = true
                link = .idle
                health.endLiveSession()
            }
        case .phone:
            if open {
                link = .phone
            } else {
                didEndOrphan = true
                link = .idle
                health.discardPhoneSession()
            }
        }
    }

    private func saveDeferred() {
        guard let deferredSave else { return }
        self.deferredSave = nil
        save(start: deferredSave.start, duration: deferredSave.duration)
    }

    private func save(start: Date, duration: TimeInterval) {
        health.saveTraditionalStrengthWorkout(start: start, duration: duration) { _, _ in }
    }
}

private enum CompanionLink {
    case idle
    case launching
    case mirrored
    case phone
    case unavailable
    case endWhileLaunching
    case ended
}
