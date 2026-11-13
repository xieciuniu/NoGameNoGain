//
//  WorkoutCoordinatorTests.swift
//  No Game No GainTests
//
//  Created by Hubert Wojtowicz on 24/10/2026.
//

import Foundation
import SwiftData
import Testing
@testable import No_Game_No_Gain

@MainActor
struct WorkoutCoordinatorTests {
    private final class DateClock {
        var date = Date(timeIntervalSince1970: 1_700_000_000)

        func advance(by interval: TimeInterval) {
            date = date.addingTimeInterval(interval)
        }
    }

    private func makeDefaults() -> UserDefaults {
        let name = "WorkoutCoordinatorTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([Workout.self, Exercise.self, WorkoutSession.self])
        let configuration = ModelConfiguration(UUID().uuidString, schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private func makeCoordinator(clock: DateClock, defaults: UserDefaults) -> WorkoutCoordinator {
        let notifications = WorkoutNotificationManager(
            settings: NotificationSettings(),
            scheduler: RecordingNotificationScheduler(now: { clock.date }),
            now: { clock.date }
        )
        return WorkoutCoordinator(
            stopwatch: Stopwatch(userDefaults: defaults, now: { clock.date }),
            notifications: notifications,
            health: RecordingWorkoutHealthStore()
        )
    }

    private func makeWorkout(in context: ModelContext, exercises: [Exercise]) -> Workout {
        let workout = Workout(name: "Test Workout", exercise: exercises)
        context.insert(workout)
        return workout
    }

    private func openSessions(in context: ModelContext) throws -> [WorkoutSession] {
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate<WorkoutSession> { session in
                session.endTime == nil
            }
        )
        return try context.fetch(descriptor)
    }

    @Test("Start inserts one open session and starts both clocks")
    func testStartInsertsOneOpenSession() throws {
        let clock = DateClock()
        let coordinator = makeCoordinator(clock: clock, defaults: makeDefaults())
        defer { coordinator.stopwatch.reset() }
        let container = try makeContainer()
        let context = container.mainContext
        let workout = makeWorkout(in: context, exercises: [Exercise(name: "Bench Press", order: 1)])

        guard let session = coordinator.start(workout: workout, in: context) else {
            Issue.record("Start should insert a session")
            return
        }

        #expect(session.endTime == nil)
        #expect(session.startTime == clock.date)
        #expect(try openSessions(in: context).count == 1)
        #expect(coordinator.stopwatch.isRunning == true)
        #expect(coordinator.stopwatch.isRunningMSMs == true)
    }

    @Test("An empty plan does not insert a session")
    func testEmptyWorkoutDoesNotStart() throws {
        let clock = DateClock()
        let coordinator = makeCoordinator(clock: clock, defaults: makeDefaults())
        defer { coordinator.stopwatch.reset() }
        let container = try makeContainer()
        let context = container.mainContext
        let workout = makeWorkout(in: context, exercises: [])

        #expect(coordinator.start(workout: workout, in: context) == nil)
        #expect(try openSessions(in: context).isEmpty)
        #expect(coordinator.stopwatch.isRunning == false)
        #expect(coordinator.stopwatch.isRunningMSMs == false)
    }

    @Test("Start again returns the open session and leaves a pause in place")
    func testStartAgainDoesNotInsertAnotherSession() throws {
        let clock = DateClock()
        let coordinator = makeCoordinator(clock: clock, defaults: makeDefaults())
        defer { coordinator.stopwatch.reset() }
        let container = try makeContainer()
        let context = container.mainContext
        let workout = makeWorkout(in: context, exercises: [Exercise(name: "Bench Press", order: 1)])

        guard let first = coordinator.start(workout: workout, in: context) else {
            Issue.record("Start should insert a session")
            return
        }
        clock.advance(by: 4)
        coordinator.pause()

        guard let second = coordinator.start(workout: workout, in: context) else {
            Issue.record("Start should return the open session")
            return
        }

        #expect(second.id == first.id)
        #expect(try context.fetch(FetchDescriptor<WorkoutSession>()).count == 1)
        #expect(coordinator.stopwatch.isRunning == false)
        #expect(coordinator.stopwatch.isRunningMSMs == false)
        #expect(abs(coordinator.stopwatch.workoutElapsed - 4) < 0.001)
    }

    @Test("Pause freezes both clocks and resume continues them")
    func testPauseAndResume() throws {
        let clock = DateClock()
        let coordinator = makeCoordinator(clock: clock, defaults: makeDefaults())
        defer { coordinator.stopwatch.reset() }
        let container = try makeContainer()
        let context = container.mainContext
        let workout = makeWorkout(in: context, exercises: [Exercise(name: "Bench Press", order: 1)])
        _ = coordinator.start(workout: workout, in: context)

        clock.advance(by: 10)
        coordinator.pause()
        #expect(coordinator.stopwatch.isRunning == false)
        #expect(coordinator.stopwatch.isRunningMSMs == false)
        #expect(abs(coordinator.stopwatch.workoutElapsed - 10) < 0.001)
        #expect(abs(coordinator.stopwatch.timeElapsedMSMs - 10) < 0.001)

        clock.advance(by: 25)
        #expect(abs(coordinator.stopwatch.workoutElapsed - 10) < 0.001)
        #expect(abs(coordinator.stopwatch.timeElapsedMSMs - 10) < 0.001)

        coordinator.resume()
        clock.advance(by: 4)
        #expect(coordinator.stopwatch.isRunning == true)
        #expect(coordinator.stopwatch.isRunningMSMs == true)
        #expect(abs(coordinator.stopwatch.workoutElapsed - 14) < 0.001)
        #expect(abs(coordinator.stopwatch.timeElapsedMSMs - 14) < 0.001)
    }

    @Test("End sets end time and duration from the workout clock, then clears it")
    func testEndStampsSessionAndClearsClock() throws {
        let clock = DateClock()
        let coordinator = makeCoordinator(clock: clock, defaults: makeDefaults())
        defer { coordinator.stopwatch.reset() }
        let container = try makeContainer()
        let context = container.mainContext
        let workout = makeWorkout(in: context, exercises: [Exercise(name: "Bench Press", order: 1)])

        guard let session = coordinator.start(workout: workout, in: context) else {
            Issue.record("Start should insert a session")
            return
        }
        clock.advance(by: 10)

        let account = UserAccount()
        var saves = 0
        coordinator.end(
            session,
            account: account,
            completion: WorkoutCompletion(save: { _ in saves += 1 })
        )

        #expect(session.endTime == clock.date)
        #expect(abs(session.duration - 10) < 0.001)
        #expect(saves == 1)
        #expect(account.getWorkoutsInCurrentWeek() == 1)
        #expect(try openSessions(in: context).isEmpty)
        #expect(coordinator.stopwatch.timeElapsedHMS == 0)
        #expect(coordinator.stopwatch.timeElapsedMSMs == 0)
        #expect(coordinator.stopwatch.isRunning == false)
        #expect(coordinator.stopwatch.isRunningMSMs == false)
    }

    @Test("End after a pause ignores the paused gap and a second end does not rewrite it")
    func testEndAfterPauseIgnoresGap() throws {
        let clock = DateClock()
        let coordinator = makeCoordinator(clock: clock, defaults: makeDefaults())
        defer { coordinator.stopwatch.reset() }
        let container = try makeContainer()
        let context = container.mainContext
        let workout = makeWorkout(in: context, exercises: [Exercise(name: "Bench Press", order: 1)])

        guard let session = coordinator.start(workout: workout, in: context) else {
            Issue.record("Start should insert a session")
            return
        }
        clock.advance(by: 10)
        coordinator.pause()
        clock.advance(by: 50)

        let account = UserAccount()
        var saves = 0
        let completion = WorkoutCompletion(save: { _ in saves += 1 })
        coordinator.end(session, account: account, completion: completion)
        let endTime = session.endTime
        let duration = session.duration

        #expect(abs(duration - 10) < 0.001)
        #expect(account.getWorkoutsInCurrentWeek() == 1)
        #expect(saves == 1)

        clock.advance(by: 30)
        coordinator.end(session, account: account, completion: completion)

        #expect(saves == 1)
        #expect(account.getWorkoutsInCurrentWeek() == 1)
        #expect(session.endTime == endTime)
        #expect(abs(session.duration - 10) < 0.001)
        #expect(session.duration == duration)
        #expect(try openSessions(in: context).isEmpty)
    }

    @Test("A paused relaunch stays paused and the session stays open")
    func testPausedRelaunchStaysPaused() throws {
        let clock = DateClock()
        let defaults = makeDefaults()
        let coordinator = makeCoordinator(clock: clock, defaults: defaults)
        let container = try makeContainer()
        let context = container.mainContext
        let workout = makeWorkout(in: context, exercises: [Exercise(name: "Bench Press", order: 1)])

        guard let session = coordinator.start(workout: workout, in: context) else {
            Issue.record("Start should insert a session")
            return
        }
        clock.advance(by: 6)
        coordinator.pause()

        let restored = makeCoordinator(clock: clock, defaults: defaults)
        defer {
            coordinator.stopwatch.reset()
            restored.stopwatch.reset()
        }

        #expect(session.endTime == nil)
        #expect(restored.stopwatch.isRunning == false)
        #expect(restored.stopwatch.isRunningMSMs == false)
        #expect(abs(restored.stopwatch.timeElapsedHMS - 6) < 0.001)
        #expect(abs(restored.stopwatch.timeElapsedMSMs - 6) < 0.001)

        clock.advance(by: 20)
        #expect(abs(restored.stopwatch.workoutElapsed - 6) < 0.001)
        #expect(abs(restored.stopwatch.timeElapsedMSMs - 6) < 0.001)
        #expect(try openSessions(in: context).count == 1)
    }

    @Test("A running relaunch keeps wall-clock elapsed time")
    func testRunningRelaunchKeepsElapsedTime() throws {
        let clock = DateClock()
        let defaults = makeDefaults()
        let coordinator = makeCoordinator(clock: clock, defaults: defaults)
        let container = try makeContainer()
        let context = container.mainContext
        let workout = makeWorkout(in: context, exercises: [Exercise(name: "Bench Press", order: 1)])

        guard coordinator.start(workout: workout, in: context) != nil else {
            Issue.record("Start should insert a session")
            return
        }
        clock.advance(by: 10)

        let restored = makeCoordinator(clock: clock, defaults: defaults)
        defer {
            coordinator.stopwatch.reset()
            restored.stopwatch.reset()
        }

        #expect(restored.stopwatch.isRunning == true)
        #expect(restored.stopwatch.isRunningMSMs == true)
        #expect(abs(restored.stopwatch.workoutElapsed - 10) < 0.001)
        #expect(abs(restored.stopwatch.timeElapsedMSMs - 10) < 0.001)
        #expect(abs(restored.stopwatch.timeElapsedHMS - 10) < 0.001)

        clock.advance(by: 5)
        #expect(abs(restored.stopwatch.workoutElapsed - 15) < 0.001)
        #expect(abs(restored.stopwatch.timeElapsedMSMs - 15) < 0.001)
    }
}
