//
//  WorkoutNotificationTests.swift
//  No Game No GainTests
//
//  Created by Hubert Wojtowicz on 24/10/2026.
//

import Foundation
import SwiftData
import Testing
import UserNotifications
@testable import No_Game_No_Gain

@MainActor
final class RecordingNotificationScheduler: WorkoutNotificationScheduling {
    struct Scheduled {
        let request: UNNotificationRequest
        let addedAt: Date
    }

    var pending: [String: Scheduled] = [:]
    private(set) var removals: [[String]] = []
    private(set) var addCount = 0
    var now: () -> Date

    init(now: @escaping () -> Date = Date.init) {
        self.now = now
    }

    func add(_ request: UNNotificationRequest) {
        addCount += 1
        pending[request.identifier] = Scheduled(request: request, addedAt: now())
    }

    func removePending(identifiers: [String]) {
        removals.append(identifiers)
        for identifier in identifiers {
            pending.removeValue(forKey: identifier)
        }
    }
}

@MainActor
struct WorkoutNotificationTests {
    private final class DateClock {
        var date = Date(timeIntervalSince1970: 1_700_000_000)

        func advance(by interval: TimeInterval) {
            date = date.addingTimeInterval(interval)
        }
    }

    private func makeSettings(sound: NotificationSettings.SoundType = .default, fileName: String? = nil) -> NotificationSettings {
        let settings = NotificationSettings()
        settings.soundType = sound
        if let fileName {
            settings.customSoundURL = URL(fileURLWithPath: "/tmp/sounds/\(fileName)")
        }
        return settings
    }

    private func makeStack(
        clock: DateClock,
        settings: NotificationSettings? = nil
    ) -> (RecordingNotificationScheduler, WorkoutNotificationManager) {
        let recorder = RecordingNotificationScheduler(now: { clock.date })
        let manager = WorkoutNotificationManager(
            settings: settings ?? makeSettings(),
            scheduler: recorder,
            now: { clock.date }
        )
        return (recorder, manager)
    }

    private func makeCoordinator(
        clock: DateClock,
        manager: WorkoutNotificationManager
    ) -> WorkoutCoordinator {
        let name = "WorkoutNotificationTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return WorkoutCoordinator(
            stopwatch: Stopwatch(userDefaults: defaults, now: { clock.date }),
            notifications: manager,
            health: RecordingWorkoutHealthStore()
        )
    }

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([Workout.self, Exercise.self, WorkoutSession.self])
        let configuration = ModelConfiguration(UUID().uuidString, schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private func makeWorkout(in context: ModelContext, exercises: [Exercise]) -> Workout {
        let workout = Workout(name: "Test Workout", exercise: exercises)
        context.insert(workout)
        return workout
    }

    private func trigger(
        _ identifier: String,
        recorder: RecordingNotificationScheduler
    ) -> UNTimeIntervalNotificationTrigger? {
        recorder.pending[identifier]?.request.trigger as? UNTimeIntervalNotificationTrigger
    }

    @Test("Rest uses a stable id, the existing copy, and the default sound")
    func testRestRequest() {
        let clock = DateClock()
        let (recorder, manager) = makeStack(clock: clock)

        manager.scheduleRest(after: 30)

        let scheduled = recorder.pending[WorkoutNotificationManager.restIdentifier]
        #expect(scheduled != nil)
        #expect(scheduled?.request.content.title == "Rest Time Over")
        #expect(scheduled?.request.content.body == "Time to start next set!")
        #expect(scheduled?.request.content.sound != nil)
        #expect(WorkoutNotificationManager.soundName(for: makeSettings()) == nil)
        #expect(trigger(WorkoutNotificationManager.restIdentifier, recorder: recorder)?.timeInterval == 30)
        #expect(trigger(WorkoutNotificationManager.restIdentifier, recorder: recorder)?.repeats == false)
        #expect(scheduled?.addedAt == clock.date)
    }

    @Test("A custom sound contributes the file name")
    func testCustomSoundName() {
        let settings = makeSettings(sound: .custom, fileName: "bell.caf")
        #expect(WorkoutNotificationManager.soundName(for: settings) == "bell.caf")

        let clock = DateClock()
        let (recorder, manager) = makeStack(clock: clock, settings: settings)
        manager.scheduleRest(after: 15)
        #expect(recorder.pending[WorkoutNotificationManager.restIdentifier]?.request.content.sound != nil)
    }

    @Test("A new rest alert replaces the previous one and leaves inactivity alone")
    func testRestReplacesPreviousAndDoesNotResetInactivity() {
        let clock = DateClock()
        let (recorder, manager) = makeStack(clock: clock)
        manager.userDidAct()
        let inactivityStamp = recorder.pending[WorkoutNotificationManager.inactivityIdentifier]?.addedAt
        let addsAfterAct = recorder.addCount

        manager.scheduleRest(after: 30)
        clock.advance(by: 4)
        manager.scheduleRest(after: 12)

        #expect(recorder.pending[WorkoutNotificationManager.restIdentifier] != nil)
        #expect(trigger(WorkoutNotificationManager.restIdentifier, recorder: recorder)?.timeInterval == 12)
        #expect(recorder.pending.keys.filter { $0 == WorkoutNotificationManager.restIdentifier }.count == 1)
        #expect(recorder.pending[WorkoutNotificationManager.inactivityIdentifier]?.addedAt == inactivityStamp)
        #expect(recorder.addCount == addsAfterAct + 2)
    }

    @Test("A non-positive rest interval is not scheduled")
    func testRestSkipsNonPositiveInterval() {
        let clock = DateClock()
        let (recorder, manager) = makeStack(clock: clock)
        manager.scheduleRest(after: 0)
        manager.scheduleRest(after: -5)
        #expect(recorder.addCount == 0)
        #expect(recorder.pending.isEmpty)
    }

    @Test("Foreground presentation includes banner, list, and sound")
    func testPresentationOptions() {
        let expected: UNNotificationPresentationOptions = [.banner, .list, .sound]
        #expect(WorkoutNotificationManager.presentationOptions(for: WorkoutNotificationManager.restIdentifier) == expected)
        #expect(WorkoutNotificationManager.presentationOptions(for: WorkoutNotificationManager.inactivityIdentifier) == expected)
        #expect(WorkoutNotificationManager.presentationOptions(for: "other") == expected)
    }

    @Test("An action schedules a repeating 7 minute reminder and a later action replaces it")
    func testInactivityReset() {
        let clock = DateClock()
        let (recorder, manager) = makeStack(clock: clock)

        manager.userDidAct()

        let first = recorder.pending[WorkoutNotificationManager.inactivityIdentifier]
        #expect(first?.request.content.title == "Workout Still in Progress")
        #expect(first?.request.content.body == "You have not done anything in this workout for 7 minutes.")
        #expect(first?.addedAt == clock.date)
        #expect(first?.request.content.userInfo[WorkoutNotificationManager.scheduledAtKey] as? TimeInterval == clock.date.timeIntervalSince1970)
        #expect(trigger(WorkoutNotificationManager.inactivityIdentifier, recorder: recorder)?.timeInterval == WorkoutNotificationManager.inactivityInterval)
        #expect(trigger(WorkoutNotificationManager.inactivityIdentifier, recorder: recorder)?.repeats == true)
        #expect(recorder.removals == [[WorkoutNotificationManager.inactivityIdentifier]])

        clock.advance(by: 50)
        manager.userDidAct()

        let second = recorder.pending[WorkoutNotificationManager.inactivityIdentifier]
        #expect(second?.addedAt == clock.date)
        #expect(second?.request.content.userInfo[WorkoutNotificationManager.scheduledAtKey] as? TimeInterval == clock.date.timeIntervalSince1970)
        #expect(recorder.pending.count == 1)
        #expect(recorder.removals == [
            [WorkoutNotificationManager.inactivityIdentifier],
            [WorkoutNotificationManager.inactivityIdentifier]
        ])
        #expect(trigger(WorkoutNotificationManager.inactivityIdentifier, recorder: recorder)?.repeats == true)
    }

    @Test("Clearing removes both requests and does not schedule another")
    func testClearScheduled() {
        let clock = DateClock()
        let (recorder, manager) = makeStack(clock: clock)
        manager.userDidAct()
        manager.scheduleRest(after: 10)
        let adds = recorder.addCount

        manager.clearScheduled()

        #expect(recorder.pending.isEmpty)
        #expect(recorder.removals.last == [
            WorkoutNotificationManager.restIdentifier,
            WorkoutNotificationManager.inactivityIdentifier
        ])
        #expect(recorder.addCount == adds)

        manager.clearScheduled()
        #expect(recorder.addCount == adds)
        #expect(recorder.pending.isEmpty)
    }

    @Test("Start arms the reminder once, and an empty plan or a second start does not")
    func testStartArmsInactivityOnce() throws {
        let clock = DateClock()
        let (recorder, manager) = makeStack(clock: clock)
        let coordinator = makeCoordinator(clock: clock, manager: manager)
        defer { coordinator.stopwatch.reset() }
        let container = try makeContainer()
        let context = container.mainContext

        let empty = makeWorkout(in: context, exercises: [])
        #expect(coordinator.start(workout: empty, in: context) == nil)
        #expect(recorder.addCount == 0)

        let workout = makeWorkout(in: context, exercises: [Exercise(name: "Bench Press", order: 1)])
        #expect(coordinator.start(workout: workout, in: context) != nil)
        let stamped = recorder.pending[WorkoutNotificationManager.inactivityIdentifier]?.addedAt
        let adds = recorder.addCount
        #expect(stamped == clock.date)
        #expect(trigger(WorkoutNotificationManager.inactivityIdentifier, recorder: recorder)?.timeInterval == WorkoutNotificationManager.inactivityInterval)

        clock.advance(by: 12)
        #expect(coordinator.start(workout: workout, in: context) != nil)
        #expect(recorder.pending[WorkoutNotificationManager.inactivityIdentifier]?.addedAt == stamped)
        #expect(recorder.addCount == adds)
    }

    @Test("Pause and resume replace the inactivity reminder and leave the rest alert pending")
    func testPauseAndResumeKeepRestAndResetInactivity() throws {
        let clock = DateClock()
        let (recorder, manager) = makeStack(clock: clock)
        let coordinator = makeCoordinator(clock: clock, manager: manager)
        defer { coordinator.stopwatch.reset() }
        let container = try makeContainer()
        let context = container.mainContext
        let workout = makeWorkout(in: context, exercises: [Exercise(name: "Bench Press", order: 1)])
        #expect(coordinator.start(workout: workout, in: context) != nil)

        manager.scheduleRest(after: 45)
        let restStamp = recorder.pending[WorkoutNotificationManager.restIdentifier]?.addedAt

        clock.advance(by: 9)
        coordinator.pause()

        #expect(recorder.pending[WorkoutNotificationManager.restIdentifier]?.addedAt == restStamp)
        #expect(trigger(WorkoutNotificationManager.restIdentifier, recorder: recorder)?.timeInterval == 45)
        #expect(recorder.pending[WorkoutNotificationManager.inactivityIdentifier]?.addedAt == clock.date)
        #expect(trigger(WorkoutNotificationManager.inactivityIdentifier, recorder: recorder)?.repeats == true)
        #expect(recorder.removals.last == [WorkoutNotificationManager.inactivityIdentifier])

        clock.advance(by: 3)
        coordinator.resume()

        #expect(recorder.pending[WorkoutNotificationManager.restIdentifier]?.addedAt == restStamp)
        #expect(recorder.pending[WorkoutNotificationManager.inactivityIdentifier]?.addedAt == clock.date)
    }

    @Test("The first end removes both requests and a second end does not")
    func testEndClearsBothOnce() throws {
        let clock = DateClock()
        let (recorder, manager) = makeStack(clock: clock)
        let coordinator = makeCoordinator(clock: clock, manager: manager)
        defer { coordinator.stopwatch.reset() }
        let container = try makeContainer()
        let context = container.mainContext
        let workout = makeWorkout(in: context, exercises: [Exercise(name: "Bench Press", order: 1)])
        guard let session = coordinator.start(workout: workout, in: context) else {
            Issue.record("Start should insert a session")
            return
        }
        manager.scheduleRest(after: 20)
        let adds = recorder.addCount
        let removalsBeforeEnd = recorder.removals.count

        coordinator.end(session, account: UserAccount(), completion: WorkoutCompletion(save: { _ in }))
        #expect(recorder.pending.isEmpty)
        #expect(recorder.addCount == adds)
        #expect(recorder.removals.count == removalsBeforeEnd + 1)
        #expect(recorder.removals.last == [
            WorkoutNotificationManager.restIdentifier,
            WorkoutNotificationManager.inactivityIdentifier
        ])

        coordinator.end(session, account: UserAccount(), completion: WorkoutCompletion(save: { _ in }))
        #expect(recorder.addCount == adds)
        #expect(recorder.removals.count == removalsBeforeEnd + 1)
    }

    @Test("Refreshing the rest alert and applying stored set fields do not reset the wait")
    func testRestRefreshAndStoredFieldsDoNotResetWait() throws {
        let clock = DateClock()
        let (recorder, manager) = makeStack(clock: clock)
        let container = try makeContainer()
        let context = container.mainContext
        let exercise = Exercise(name: "Bench Press", order: 1)
        exercise.exerciseNote = "Feet planted"
        let workout = makeWorkout(in: context, exercises: [exercise])
        let session = WorkoutSession(workout: workout, startTime: clock.date)
        context.insert(session)

        let viewModel = WorkoutView.WorkoutViewModel(workoutSession: session, notifications: manager)
        viewModel.begin()
        viewModel.setWeightRepsSet()
        manager.userDidAct()
        let stamped = recorder.pending[WorkoutNotificationManager.inactivityIdentifier]?.addedAt
        let adds = recorder.addCount

        viewModel.updateRestTimeNotification(elapsedTime: 10)
        viewModel.noteWeightEdit()
        viewModel.noteRepsEdit()
        viewModel.noteRPEEdit()
        viewModel.noteExerciseNotesEdit()

        #expect(trigger(WorkoutNotificationManager.restIdentifier, recorder: recorder)?.timeInterval == 80)
        #expect(recorder.pending[WorkoutNotificationManager.inactivityIdentifier]?.addedAt == stamped)
        #expect(recorder.addCount == adds + 1)

        clock.advance(by: 5)
        viewModel.currentWeight = 80
        viewModel.noteWeightEdit()
        viewModel.currentReps = 8
        viewModel.noteRepsEdit()
        viewModel.rpe = 9
        viewModel.noteRPEEdit()
        viewModel.exerciseNotes = "Wider grip"
        viewModel.noteExerciseNotesEdit()

        #expect(recorder.pending[WorkoutNotificationManager.inactivityIdentifier]?.addedAt == clock.date)
        #expect(exercise.exerciseNote == "Wider grip")
    }
}
