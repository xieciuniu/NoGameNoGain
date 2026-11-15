//
//  WorkoutHealthTests.swift
//  No Game No GainTests
//
//  Created by Hubert Wojtowicz on 25/10/2026.
//

import Foundation
import HealthKit
import SwiftData
import Testing
@testable import No_Game_No_Gain

final class RecordingWorkoutHealthStore: WorkoutHealthRecording {
    enum Launch {
        case fail
        case hold
        case succeed
        case succeedAndMirror
    }

    struct SavedWorkout: Equatable {
        var start: Date
        var duration: TimeInterval
    }

    var launch: Launch = .fail
    var recovered: RecoveredWorkoutSessionKind = .none
    var phoneSessionAvailable = false
    var phoneEndSaves = true
    private(set) var saved: [SavedWorkout] = []
    private(set) var configurations: [HKWorkoutConfiguration] = []
    private(set) var phoneConfigurations: [HKWorkoutConfiguration] = []
    private(set) var pauseCount = 0
    private(set) var resumeCount = 0
    private(set) var endCount = 0
    private(set) var phoneStartCount = 0
    private(set) var phonePauseCount = 0
    private(set) var phoneResumeCount = 0
    private(set) var phoneEndCount = 0
    private(set) var phoneDiscardCount = 0

    private var onMirrored: (() -> Void)?
    private var onEnded: (() -> Void)?
    private var onMetrics: ((WorkoutLiveMetrics) -> Void)?
    private var onRecovered: ((RecoveredWorkoutSessionKind) -> Void)?
    private var onPhoneFailed: (() -> Void)?
    private var heldCompletion: ((Bool) -> Void)?

    func requestAuthorizationIfNeeded(completion: @escaping (Bool, Error?) -> Void) {
        completion(true, nil)
    }

    func saveTraditionalStrengthWorkout(
        start: Date,
        duration: TimeInterval,
        completion: @escaping (Bool, Error?) -> Void
    ) {
        saved.append(SavedWorkout(start: start, duration: duration))
        completion(true, nil)
    }

    func installCompanion(
        onMirrored: @escaping () -> Void,
        onEnded: @escaping () -> Void,
        onMetrics: @escaping (WorkoutLiveMetrics) -> Void,
        onRecovered: @escaping (RecoveredWorkoutSessionKind) -> Void,
        onPhoneFailed: @escaping () -> Void
    ) {
        self.onMirrored = onMirrored
        self.onEnded = onEnded
        self.onMetrics = onMetrics
        self.onRecovered = onRecovered
        self.onPhoneFailed = onPhoneFailed
        onRecovered(recovered)
    }

    func startWatchApp(
        configuration: HKWorkoutConfiguration,
        completion: @escaping (Bool) -> Void
    ) {
        configurations.append(configuration)
        switch launch {
        case .fail:
            completion(false)
        case .hold:
            heldCompletion = completion
        case .succeed:
            completion(true)
        case .succeedAndMirror:
            completion(true)
            onMirrored?()
        }
    }

    func finishHeldLaunch(success: Bool, mirror: Bool) {
        heldCompletion?(success)
        heldCompletion = nil
        if success && mirror {
            onMirrored?()
        }
    }

    func deliverMetrics(
        heartRateBPM: Double?,
        averageHeartRateBPM: Double? = nil,
        maximumHeartRateBPM: Double? = nil,
        activeEnergyKilocalories: Double?
    ) {
        onMetrics?(WorkoutLiveMetrics(
            heartRateBPM: heartRateBPM,
            averageHeartRateBPM: averageHeartRateBPM,
            maximumHeartRateBPM: maximumHeartRateBPM,
            activeEnergyKilocalories: activeEnergyKilocalories
        ))
    }

    func deliverRemoteEnd() {
        onEnded?()
    }

    func deliverMirror() {
        onMirrored?()
    }

    func failPhoneSession() {
        onPhoneFailed?()
    }

    func pauseLiveSession() {
        pauseCount += 1
    }

    func resumeLiveSession() {
        resumeCount += 1
    }

    func endLiveSession() {
        endCount += 1
    }

    func startPhoneSession(
        configuration: HKWorkoutConfiguration,
        completion: @escaping (Bool) -> Void
    ) {
        phoneStartCount += 1
        phoneConfigurations.append(configuration)
        completion(phoneSessionAvailable)
    }

    func pausePhoneSession() {
        phonePauseCount += 1
    }

    func resumePhoneSession() {
        phoneResumeCount += 1
    }

    func endPhoneSession(completion: @escaping (Bool) -> Void) {
        phoneEndCount += 1
        completion(phoneEndSaves)
    }

    func discardPhoneSession() {
        phoneDiscardCount += 1
    }
}

@MainActor
struct WorkoutHealthTests {
    private final class DateClock {
        var date = Date(timeIntervalSince1970: 1_700_000_000)

        func advance(by interval: TimeInterval) {
            date = date.addingTimeInterval(interval)
        }
    }

    private func makeDefaults() -> UserDefaults {
        let name = "WorkoutHealthTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([Workout.self, Exercise.self, WorkoutSession.self])
        let configuration = ModelConfiguration(UUID().uuidString, schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private func makeCoordinator(
        clock: DateClock,
        health: RecordingWorkoutHealthStore
    ) -> WorkoutCoordinator {
        let notifications = WorkoutNotificationManager(
            settings: NotificationSettings(),
            scheduler: RecordingNotificationScheduler(now: { clock.date }),
            now: { clock.date }
        )
        return WorkoutCoordinator(
            stopwatch: Stopwatch(userDefaults: makeDefaults(), now: { clock.date }),
            notifications: notifications,
            health: health
        )
    }

    @Test("The saved workout is indoor traditional strength training")
    func testConfiguration() {
        let configuration = TraditionalStrengthWorkout.configuration()
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        #expect(configuration.activityType == .traditionalStrengthTraining)
        #expect(configuration.locationType == .indoor)
        #expect(TraditionalStrengthWorkout.endDate(start: start, duration: 12) == start.addingTimeInterval(12))
    }

    @Test("End saves one workout from the clock, including with no sets, and a second end does not save again")
    func testEndSavesOneWorkoutAndSecondEndDoesNot() throws {
        let clock = DateClock()
        let health = RecordingWorkoutHealthStore()
        let coordinator = makeCoordinator(clock: clock, health: health)
        defer { coordinator.stopwatch.reset() }
        let container = try makeContainer()
        let context = container.mainContext
        let workout = Workout(name: "Test Workout", exercise: [Exercise(name: "Bench Press", order: 1)])
        context.insert(workout)

        guard let session = coordinator.start(workout: workout, in: context) else {
            Issue.record("Start should insert a session")
            return
        }
        clock.advance(by: 10)
        coordinator.pause()
        clock.advance(by: 50)

        coordinator.end(session, account: UserAccount(), completion: WorkoutCompletion(save: { _ in }))

        #expect(session.doneSets.isEmpty)
        #expect(health.saved.count == 1)
        #expect(health.saved[0].start == session.startTime)
        #expect(abs(health.saved[0].duration - 10) < 0.001)

        coordinator.end(session, account: UserAccount(), completion: WorkoutCompletion(save: { _ in }))
        #expect(health.saved.count == 1)
    }

    @Test("Pause, rest, and an open session do not save a workout")
    func testPauseRestAndOpenSessionDoNotSave() throws {
        let clock = DateClock()
        let health = RecordingWorkoutHealthStore()
        let coordinator = makeCoordinator(clock: clock, health: health)
        defer { coordinator.stopwatch.reset() }
        let container = try makeContainer()
        let context = container.mainContext
        let workout = Workout(name: "Test Workout", exercise: [Exercise(name: "Bench Press", order: 1)])
        context.insert(workout)

        guard let session = coordinator.start(workout: workout, in: context) else {
            Issue.record("Start should insert a session")
            return
        }
        coordinator.pause()
        coordinator.notifications.scheduleRest(after: 90)
        coordinator.resume()
        #expect(health.saved.isEmpty)

        let recorder = WorkoutHealthRecorder(health: health)
        recorder.recordEndedSession(session)
        #expect(session.endTime == nil)
        #expect(health.saved.isEmpty)
    }

    @Test("The recorder writes one sample per ended session")
    func testRecorderWritesOneSamplePerSession() throws {
        let clock = DateClock()
        let health = RecordingWorkoutHealthStore()
        let coordinator = makeCoordinator(clock: clock, health: RecordingWorkoutHealthStore())
        defer { coordinator.stopwatch.reset() }
        let container = try makeContainer()
        let context = container.mainContext
        let workout = Workout(name: "Test Workout", exercise: [Exercise(name: "Bench Press", order: 1)])
        context.insert(workout)

        guard let session = coordinator.start(workout: workout, in: context) else {
            Issue.record("Start should insert a session")
            return
        }
        session.endTime = session.startTime.addingTimeInterval(40)
        session.duration = 10

        let recorder = WorkoutHealthRecorder(health: health)
        recorder.recordEndedSession(session)
        recorder.recordEndedSession(session)

        #expect(health.saved.count == 1)
        #expect(health.saved[0].start == session.startTime)
        #expect(health.saved[0].duration == 10)
    }

    @Test("A mirrored start asks for one indoor strength session and does not save yet")
    func testCompanionStartRequestsOneStrengthConfiguration() throws {
        let clock = DateClock()
        let health = RecordingWorkoutHealthStore()
        health.launch = .succeedAndMirror
        let coordinator = makeCoordinator(clock: clock, health: health)
        defer { coordinator.stopwatch.reset() }
        let container = try makeContainer()
        let context = container.mainContext
        let workout = Workout(name: "Test Workout", exercise: [Exercise(name: "Bench Press", order: 1)])
        context.insert(workout)

        guard let session = coordinator.start(workout: workout, in: context) else {
            Issue.record("Start should insert a session")
            return
        }
        #expect(health.configurations.count == 1)
        #expect(health.configurations[0].activityType == .traditionalStrengthTraining)
        #expect(health.configurations[0].locationType == .indoor)
        #expect(health.phoneStartCount == 0)
        #expect(coordinator.hasTrackingDevice)
        #expect(health.saved.isEmpty)
        #expect(session.endTime == nil)

        _ = coordinator.start(workout: workout, in: context)
        #expect(health.configurations.count == 1)
    }

    @Test("A failed Watch launch still saves one workout on end")
    func testFailedCompanionStartSavesOnEnd() throws {
        let clock = DateClock()
        let health = RecordingWorkoutHealthStore()
        health.launch = .fail
        let coordinator = makeCoordinator(clock: clock, health: health)
        defer { coordinator.stopwatch.reset() }
        let container = try makeContainer()
        let context = container.mainContext
        let workout = Workout(name: "Test Workout", exercise: [Exercise(name: "Bench Press", order: 1)])
        context.insert(workout)

        guard let session = coordinator.start(workout: workout, in: context) else {
            Issue.record("Start should insert a session")
            return
        }
        #expect(health.phoneStartCount == 1)
        #expect(coordinator.hasTrackingDevice == false)
        clock.advance(by: 10)
        coordinator.end(session, account: UserAccount(), completion: WorkoutCompletion(save: { _ in }))

        #expect(health.configurations.count == 1)
        #expect(health.endCount == 0)
        #expect(health.phoneEndCount == 0)
        #expect(health.saved.count == 1)
        #expect(health.saved[0].duration == 10)
    }

    @Test("Pause and resume reach the mirrored session, and rest does not")
    func testPauseAndResumeReachLiveSession() throws {
        let clock = DateClock()
        let health = RecordingWorkoutHealthStore()
        health.launch = .succeedAndMirror
        let coordinator = makeCoordinator(clock: clock, health: health)
        defer { coordinator.stopwatch.reset() }
        let container = try makeContainer()
        let context = container.mainContext
        let workout = Workout(name: "Test Workout", exercise: [Exercise(name: "Bench Press", order: 1)])
        context.insert(workout)

        guard coordinator.start(workout: workout, in: context) != nil else {
            Issue.record("Start should insert a session")
            return
        }
        coordinator.pause()
        coordinator.notifications.scheduleRest(after: 90)
        #expect(health.pauseCount == 1)
        coordinator.resume()
        #expect(health.resumeCount == 1)
        #expect(health.saved.isEmpty)
    }

    @Test("End while mirrored ends the session once and does not write the hand-built sample")
    func testEndWhileMirroredSkipsHandBuiltSave() throws {
        let clock = DateClock()
        let health = RecordingWorkoutHealthStore()
        health.launch = .succeedAndMirror
        let coordinator = makeCoordinator(clock: clock, health: health)
        defer { coordinator.stopwatch.reset() }
        let container = try makeContainer()
        let context = container.mainContext
        let workout = Workout(name: "Test Workout", exercise: [Exercise(name: "Bench Press", order: 1)])
        context.insert(workout)

        guard let session = coordinator.start(workout: workout, in: context) else {
            Issue.record("Start should insert a session")
            return
        }
        coordinator.end(session, account: UserAccount(), completion: WorkoutCompletion(save: { _ in }))
        coordinator.end(session, account: UserAccount(), completion: WorkoutCompletion(save: { _ in }))

        #expect(health.endCount == 1)
        #expect(health.saved.isEmpty)
        #expect(session.endTime != nil)
    }

    @Test("End during launch ends the session when the mirror attaches")
    func testEndDuringLaunchEndsWhenMirrorAttaches() throws {
        let clock = DateClock()
        let health = RecordingWorkoutHealthStore()
        health.launch = .hold
        let coordinator = makeCoordinator(clock: clock, health: health)
        defer { coordinator.stopwatch.reset() }
        let container = try makeContainer()
        let context = container.mainContext
        let workout = Workout(name: "Test Workout", exercise: [Exercise(name: "Bench Press", order: 1)])
        context.insert(workout)

        guard let session = coordinator.start(workout: workout, in: context) else {
            Issue.record("Start should insert a session")
            return
        }
        coordinator.end(session, account: UserAccount(), completion: WorkoutCompletion(save: { _ in }))
        #expect(health.saved.isEmpty)
        #expect(health.endCount == 0)

        health.finishHeldLaunch(success: true, mirror: true)
        #expect(health.endCount == 1)
        #expect(health.saved.isEmpty)
    }

    @Test("End during launch saves through the hand-built path when the Watch launch fails")
    func testEndDuringLaunchSavesWhenLaunchFails() throws {
        let clock = DateClock()
        let health = RecordingWorkoutHealthStore()
        health.launch = .hold
        let coordinator = makeCoordinator(clock: clock, health: health)
        defer { coordinator.stopwatch.reset() }
        let container = try makeContainer()
        let context = container.mainContext
        let workout = Workout(name: "Test Workout", exercise: [Exercise(name: "Bench Press", order: 1)])
        context.insert(workout)

        guard let session = coordinator.start(workout: workout, in: context) else {
            Issue.record("Start should insert a session")
            return
        }
        coordinator.end(session, account: UserAccount(), completion: WorkoutCompletion(save: { _ in }))
        health.finishHeldLaunch(success: false, mirror: false)

        #expect(health.endCount == 0)
        #expect(health.phoneStartCount == 1)
        #expect(health.phoneEndCount == 0)
        #expect(health.saved.count == 1)
        #expect(health.saved[0].start == session.startTime)
    }

    @Test("Recovery with an open session attaches and does not start the Watch again")
    func testRecoveryWithOpenSessionDoesNotStartWatch() throws {
        let clock = DateClock()
        let health = RecordingWorkoutHealthStore()
        health.recovered = .mirrored
        health.launch = .succeedAndMirror
        let coordinator = makeCoordinator(clock: clock, health: health)
        defer { coordinator.stopwatch.reset() }
        coordinator.resolveRecoveredCompanion(openWorkoutExists: true)

        let container = try makeContainer()
        let context = container.mainContext
        let workout = Workout(name: "Test Workout", exercise: [Exercise(name: "Bench Press", order: 1)])
        context.insert(workout)
        let existing = WorkoutSession(workout: workout, startTime: clock.date)
        context.insert(existing)

        let returned = coordinator.start(workout: workout, in: context)
        #expect(returned?.id == existing.id)
        #expect(health.configurations.isEmpty)
        #expect(health.endCount == 0)
    }

    @Test("Recovery without an open session does not insert one")
    func testRecoveryWithoutOpenSessionDoesNotInsert() throws {
        let clock = DateClock()
        let health = RecordingWorkoutHealthStore()
        health.recovered = .mirrored
        let coordinator = makeCoordinator(clock: clock, health: health)
        defer { coordinator.stopwatch.reset() }
        let container = try makeContainer()
        coordinator.resolveRecoveredCompanion(openWorkoutExists: false)

        let sessions = try container.mainContext.fetch(FetchDescriptor<WorkoutSession>())
        #expect(sessions.isEmpty)
        #expect(health.endCount == 1)
        #expect(health.configurations.isEmpty)
        #expect(health.saved.isEmpty)
    }

    @Test("Mirrored metrics and a remote end reach the coordinator")
    func testMetricsAndRemoteEnd() throws {
        let clock = DateClock()
        let health = RecordingWorkoutHealthStore()
        health.launch = .succeedAndMirror
        let coordinator = makeCoordinator(clock: clock, health: health)
        defer { coordinator.stopwatch.reset() }
        let container = try makeContainer()
        let context = container.mainContext
        let workout = Workout(name: "Test Workout", exercise: [Exercise(name: "Bench Press", order: 1)])
        context.insert(workout)

        guard let session = coordinator.start(workout: workout, in: context) else {
            Issue.record("Start should insert a session")
            return
        }
        health.deliverMetrics(
            heartRateBPM: 120,
            averageHeartRateBPM: 110,
            maximumHeartRateBPM: 150,
            activeEnergyKilocalories: 15
        )
        health.deliverMetrics(heartRateBPM: 130, activeEnergyKilocalories: nil)
        #expect(coordinator.heartRateBPM == 130)
        #expect(coordinator.averageHeartRateBPM == 110)
        #expect(coordinator.maximumHeartRateBPM == 150)
        #expect(coordinator.activeEnergyKilocalories == 15)

        health.deliverRemoteEnd()
        #expect(coordinator.companionEnded)
        coordinator.end(session, account: UserAccount(), completion: WorkoutCompletion(save: { _ in }))
        #expect(session.averageHeartRateBPM == 110)
        #expect(session.maximumHeartRateBPM == 150)
        #expect(coordinator.heartRateBPM == nil)
        #expect(coordinator.averageHeartRateBPM == nil)
        #expect(coordinator.maximumHeartRateBPM == nil)
        #expect(health.saved.isEmpty)
        #expect(health.endCount == 0)
    }

    @Test("The next workout can start a session after the previous one ended")
    func testSecondWorkoutStartsAgain() throws {
        let clock = DateClock()
        let health = RecordingWorkoutHealthStore()
        health.launch = .succeedAndMirror
        let coordinator = makeCoordinator(clock: clock, health: health)
        defer { coordinator.stopwatch.reset() }
        let container = try makeContainer()
        let context = container.mainContext
        let workout = Workout(name: "Test Workout", exercise: [Exercise(name: "Bench Press", order: 1)])
        context.insert(workout)

        guard let first = coordinator.start(workout: workout, in: context) else {
            Issue.record("Start should insert a session")
            return
        }
        coordinator.end(first, account: UserAccount(), completion: WorkoutCompletion(save: { _ in }))

        guard let second = coordinator.start(workout: workout, in: context) else {
            Issue.record("The next workout should insert a session")
            return
        }
        #expect(second.id != first.id)
        #expect(health.configurations.count == 2)
        #expect(health.phoneStartCount == 0)
    }

    @Test("The next workout starts after a Watch launch that never mirrors")
    func testSecondWorkoutAfterUnmirroredWatchLaunch() throws {
        let clock = DateClock()
        let health = RecordingWorkoutHealthStore()
        health.launch = .succeed
        let coordinator = makeCoordinator(clock: clock, health: health)
        defer { coordinator.stopwatch.reset() }
        let container = try makeContainer()
        let context = container.mainContext
        let workout = Workout(name: "Test Workout", exercise: [Exercise(name: "Bench Press", order: 1)])
        context.insert(workout)

        guard let first = coordinator.start(workout: workout, in: context) else {
            Issue.record("Start should insert a session")
            return
        }
        coordinator.end(first, account: UserAccount(), completion: WorkoutCompletion(save: { _ in }))

        guard coordinator.start(workout: workout, in: context) != nil else {
            Issue.record("The next workout should insert a session")
            return
        }
        #expect(health.configurations.count == 2)
        #expect(health.phoneStartCount == 0)
    }

    @Test("A phone session shows heart rate and saves through that session")
    func testPhoneSessionShowsHeartRateAndSkipsHandBuiltSave() throws {
        let clock = DateClock()
        let health = RecordingWorkoutHealthStore()
        health.launch = .fail
        health.phoneSessionAvailable = true
        let coordinator = makeCoordinator(clock: clock, health: health)
        defer { coordinator.stopwatch.reset() }
        let container = try makeContainer()
        let context = container.mainContext
        let workout = Workout(name: "Test Workout", exercise: [Exercise(name: "Bench Press", order: 1)])
        context.insert(workout)

        guard let session = coordinator.start(workout: workout, in: context) else {
            Issue.record("Start should insert a session")
            return
        }
        #expect(health.phoneStartCount == 1)
        #expect(health.phoneConfigurations[0].activityType == .traditionalStrengthTraining)
        #expect(health.phoneConfigurations[0].locationType == .indoor)
        #expect(coordinator.hasTrackingDevice == false)
        #expect(health.saved.isEmpty)

        health.deliverMetrics(heartRateBPM: nil, activeEnergyKilocalories: 12)
        #expect(coordinator.heartRateBPM == nil)
        #expect(coordinator.hasTrackingDevice == false)
        #expect(coordinator.activeEnergyKilocalories == 12)

        health.deliverMetrics(
            heartRateBPM: 118,
            averageHeartRateBPM: 110,
            maximumHeartRateBPM: 140,
            activeEnergyKilocalories: 20
        )
        #expect(coordinator.hasTrackingDevice)
        #expect(coordinator.heartRateBPM == 118)

        coordinator.pause()
        coordinator.notifications.scheduleRest(after: 90)
        coordinator.resume()
        #expect(health.phonePauseCount == 1)
        #expect(health.phoneResumeCount == 1)
        #expect(health.pauseCount == 0)

        clock.advance(by: 10)
        coordinator.end(session, account: UserAccount(), completion: WorkoutCompletion(save: { _ in }))
        coordinator.end(session, account: UserAccount(), completion: WorkoutCompletion(save: { _ in }))
        #expect(health.phoneEndCount == 1)
        #expect(health.endCount == 0)
        #expect(health.saved.isEmpty)
        #expect(coordinator.hasTrackingDevice == false)
        #expect(session.averageHeartRateBPM == 110)
        #expect(session.maximumHeartRateBPM == 140)
    }

    @Test("A phone session that fails to save falls back to one hand-built workout")
    func testPhoneSessionSaveFailureUsesHandBuiltPath() throws {
        let clock = DateClock()
        let health = RecordingWorkoutHealthStore()
        health.launch = .fail
        health.phoneSessionAvailable = true
        health.phoneEndSaves = false
        let coordinator = makeCoordinator(clock: clock, health: health)
        defer { coordinator.stopwatch.reset() }
        let container = try makeContainer()
        let context = container.mainContext
        let workout = Workout(name: "Test Workout", exercise: [Exercise(name: "Bench Press", order: 1)])
        context.insert(workout)

        guard let session = coordinator.start(workout: workout, in: context) else {
            Issue.record("Start should insert a session")
            return
        }
        clock.advance(by: 8)
        coordinator.end(session, account: UserAccount(), completion: WorkoutCompletion(save: { _ in }))

        #expect(health.phoneEndCount == 1)
        #expect(health.saved.count == 1)
        #expect(health.saved[0].duration == 8)
    }

    @Test("A Watch that appears after the phone session discards the phone session")
    func testMirrorReplacesPhoneSession() throws {
        let clock = DateClock()
        let health = RecordingWorkoutHealthStore()
        health.launch = .fail
        health.phoneSessionAvailable = true
        let coordinator = makeCoordinator(clock: clock, health: health)
        defer { coordinator.stopwatch.reset() }
        let container = try makeContainer()
        let context = container.mainContext
        let workout = Workout(name: "Test Workout", exercise: [Exercise(name: "Bench Press", order: 1)])
        context.insert(workout)

        guard let session = coordinator.start(workout: workout, in: context) else {
            Issue.record("Start should insert a session")
            return
        }
        health.deliverMirror()
        #expect(health.phoneDiscardCount == 1)
        #expect(coordinator.hasTrackingDevice)

        coordinator.end(session, account: UserAccount(), completion: WorkoutCompletion(save: { _ in }))
        #expect(health.endCount == 1)
        #expect(health.phoneEndCount == 0)
        #expect(health.saved.isEmpty)
    }

    @Test("Ending while the Watch launch fails saves through the phone session when that session starts")
    func testEndDuringFailedLaunchUsesPhoneSession() throws {
        let clock = DateClock()
        let health = RecordingWorkoutHealthStore()
        health.launch = .hold
        health.phoneSessionAvailable = true
        let coordinator = makeCoordinator(clock: clock, health: health)
        defer { coordinator.stopwatch.reset() }
        let container = try makeContainer()
        let context = container.mainContext
        let workout = Workout(name: "Test Workout", exercise: [Exercise(name: "Bench Press", order: 1)])
        context.insert(workout)

        guard let session = coordinator.start(workout: workout, in: context) else {
            Issue.record("Start should insert a session")
            return
        }
        coordinator.end(session, account: UserAccount(), completion: WorkoutCompletion(save: { _ in }))
        health.finishHeldLaunch(success: false, mirror: false)

        #expect(health.phoneEndCount == 1)
        #expect(health.saved.isEmpty)
    }

    @Test("A recovered phone session stays with the open workout and does not start the Watch")
    func testRecoveredPhoneSessionDoesNotStartWatch() throws {
        let clock = DateClock()
        let health = RecordingWorkoutHealthStore()
        health.recovered = .phone
        health.launch = .succeedAndMirror
        let coordinator = makeCoordinator(clock: clock, health: health)
        defer { coordinator.stopwatch.reset() }
        coordinator.resolveRecoveredCompanion(openWorkoutExists: true)

        let container = try makeContainer()
        let context = container.mainContext
        let workout = Workout(name: "Test Workout", exercise: [Exercise(name: "Bench Press", order: 1)])
        context.insert(workout)
        let existing = WorkoutSession(workout: workout, startTime: clock.date)
        context.insert(existing)

        let returned = coordinator.start(workout: workout, in: context)
        #expect(returned?.id == existing.id)
        #expect(health.configurations.isEmpty)
        #expect(health.phoneStartCount == 0)
        #expect(coordinator.hasTrackingDevice == false)

        health.deliverMetrics(heartRateBPM: 101, activeEnergyKilocalories: 4)
        #expect(coordinator.hasTrackingDevice)
        #expect(coordinator.heartRateBPM == 101)

        coordinator.end(existing, account: UserAccount(), completion: WorkoutCompletion(save: { _ in }))
        #expect(health.phoneEndCount == 1)
        #expect(health.endCount == 0)
        #expect(health.saved.isEmpty)
    }

    @Test("A recovered phone session with no open workout is discarded")
    func testRecoveredPhoneSessionWithoutWorkoutIsDiscarded() throws {
        let clock = DateClock()
        let health = RecordingWorkoutHealthStore()
        health.recovered = .phone
        let coordinator = makeCoordinator(clock: clock, health: health)
        defer { coordinator.stopwatch.reset() }
        coordinator.resolveRecoveredCompanion(openWorkoutExists: false)

        #expect(health.phoneDiscardCount == 1)
        #expect(health.endCount == 0)
        #expect(health.saved.isEmpty)
        #expect(health.configurations.isEmpty)
    }

    @Test("A phone session that fails mid-workout saves one hand-built workout on end")
    func testPhoneSessionFailureFallsBackOnEnd() throws {
        let clock = DateClock()
        let health = RecordingWorkoutHealthStore()
        health.launch = .fail
        health.phoneSessionAvailable = true
        let coordinator = makeCoordinator(clock: clock, health: health)
        defer { coordinator.stopwatch.reset() }
        let container = try makeContainer()
        let context = container.mainContext
        let workout = Workout(name: "Test Workout", exercise: [Exercise(name: "Bench Press", order: 1)])
        context.insert(workout)

        guard let session = coordinator.start(workout: workout, in: context) else {
            Issue.record("Start should insert a session")
            return
        }
        health.failPhoneSession()
        clock.advance(by: 6)
        coordinator.end(session, account: UserAccount(), completion: WorkoutCompletion(save: { _ in }))

        #expect(health.phoneEndCount == 0)
        #expect(health.saved.count == 1)
        #expect(health.saved[0].duration == 6)
    }

    @Test("A failed Watch launch starts one phone session and does not start another")
    func testFailedLaunchStartsPhoneSessionOnce() {
        let health = RecordingWorkoutHealthStore()
        health.launch = .fail
        health.phoneSessionAvailable = true
        let recorder = WorkoutHealthRecorder(health: health)
        recorder.prepare()
        recorder.startCompanion()

        #expect(health.phoneStartCount == 1)
        recorder.startCompanion()
        #expect(health.phoneStartCount == 1)
        #expect(health.configurations.count == 1)
    }

    @Test("The next workout starts after an end that landed before the Watch launch returned")
    func testNextStartAfterEndDuringUnmirroredLaunch() {
        let health = RecordingWorkoutHealthStore()
        health.launch = .hold
        let recorder = WorkoutHealthRecorder(health: health)
        recorder.prepare()
        recorder.startCompanion()

        let workout = Workout(name: "Test Workout", exercise: [Exercise(name: "Bench Press", order: 1)])
        let session = WorkoutSession(workout: workout, startTime: Date(timeIntervalSince1970: 1_700_000_000))
        session.endTime = Date(timeIntervalSince1970: 1_700_000_004)
        session.duration = 4
        recorder.recordEndedSession(session)
        health.finishHeldLaunch(success: true, mirror: false)

        #expect(health.saved.isEmpty)
        #expect(health.endCount == 0)
        recorder.startCompanion()
        #expect(health.configurations.count == 2)
        #expect(health.phoneStartCount == 0)
    }
}
