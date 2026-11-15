//
//  WorkoutCompletionTests.swift
//  No Game No GainTests
//
//  Created by Hubert Wojtowicz on 24/10/2026.
//

import Foundation
import SwiftData
import Testing
@testable import No_Game_No_Gain

@MainActor
struct WorkoutCompletionTests {
    private final class DateClock {
        var date = Date(timeIntervalSince1970: 1_700_000_000)

        func advance(by interval: TimeInterval) {
            date = date.addingTimeInterval(interval)
        }
    }

    private func makeDefaults() -> UserDefaults {
        let name = "WorkoutCompletionTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([Workout.self, Exercise.self, WorkoutSession.self])
        let configuration = ModelConfiguration(UUID().uuidString, schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private func makeExercise(
        name: String = "Bench",
        weights: [Double],
        progress: [Bool],
        progressPerWorkout: Double = 2.5,
        personalBestWeight: Double? = nil,
        personalBestReps: Int? = nil
    ) -> Exercise {
        let exercise = Exercise(name: name, order: 1)
        exercise.progressPerWorkout = progressPerWorkout
        exercise.personalBestWeight = personalBestWeight
        exercise.personalBestReps = personalBestReps
        exercise.sets = zip(weights, progress).map { weight, progresses in
            OneSet(reps: 5, weight: weight, progress: progresses)
        }
        return exercise
    }

    private func makeSession(_ exercise: Exercise) throws -> (ModelContainer, WorkoutSession) {
        let container = try makeContainer()
        let context = container.mainContext
        let workout = Workout(name: "Test Workout", exercise: [exercise])
        context.insert(workout)
        let session = WorkoutSession(workout: workout, startTime: Date(timeIntervalSince1970: 1_700_000_000))
        context.insert(session)
        try context.save()
        return (container, session)
    }

    private func log(
        _ session: WorkoutSession,
        account: UserAccount,
        completion: WorkoutCompletion,
        exerciseName: String = "Bench",
        setNumber: Int,
        weight: Double,
        reps: Int = 5,
        rest: TimeInterval = 40,
        rpe: Int? = 8,
        isDone: Bool,
        weightUnset: Bool = false
    ) {
        completion.logSet(
            session: session,
            account: account,
            exerciseName: exerciseName,
            setNumber: setNumber,
            metrics: SetMetrics(
                weight: weightUnset ? 0 : weight,
                reps: reps,
                restTime: rest,
                rpe: rpe,
                weightUnset: weightUnset
            ),
            isDone: isDone
        )
    }

    private func plannedReps(_ session: WorkoutSession, name: String = "Bench") -> [Int] {
        session.workout.exercises.first { $0.name == name }?.sets.map(\.reps) ?? []
    }

    private func plannedWeights(_ session: WorkoutSession, name: String = "Bench") -> [Double] {
        session.workout.exercises.first { $0.name == name }?.sets.map(\.weight) ?? []
    }

    @Test("A completed set stores weight, reps, rest, RPE, and is done")
    func testCompletedSetStoresTheLoggedFields() throws {
        let exercise = makeExercise(weights: [100, 80], progress: [false, false])
        let (container, session) = try makeSession(exercise)
        _ = container
        let account = UserAccount()
        let completion = WorkoutCompletion(save: { _ in })

        log(session, account: account, completion: completion, setNumber: 1, weight: 100, reps: 8, rest: 42, rpe: 7, isDone: true)
        log(session, account: account, completion: completion, setNumber: 2, weight: 80, reps: 6, rest: 15, rpe: 9, isDone: true)

        #expect(session.doneSets.count == 2)
        let first = session.doneSets[0]
        #expect(first.exerciseName == "Bench")
        #expect(first.numberOfSet == 1)
        #expect(first.weight == 100)
        #expect(first.reps == 8)
        #expect(first.restTime == 42)
        #expect(first.rpe == 7)
        #expect(first.isDone == true)
        #expect(session.totalWeight() == 180)
    }

    @Test("A failed set is stored and does not increase the planned load")
    func testFailedSetDoesNotIncreaseLoad() throws {
        let exercise = makeExercise(weights: [100, 100], progress: [true, true])
        let (container, session) = try makeSession(exercise)
        _ = container
        let account = UserAccount()
        account.strengthGoalExercise = "Bench"
        account.goalProgress = 50
        var saves = 0
        let completion = WorkoutCompletion(save: { _ in saves += 1 })

        log(session, account: account, completion: completion, setNumber: 1, weight: 100, reps: 5, rest: 30, rpe: 9, isDone: true)
        log(session, account: account, completion: completion, setNumber: 2, weight: 100, reps: 3, rest: 20, rpe: 10, isDone: false)

        let failed = session.doneSets[1]
        #expect(failed.isDone == false)
        #expect(failed.weight == 100)
        #expect(failed.reps == 3)
        #expect(failed.restTime == 20)
        #expect(failed.rpe == 10)
        #expect(plannedWeights(session) == [100, 100])
        #expect(saves == 0)

        completion.finish(session: session, account: account, duration: 40 * 60)
        #expect(plannedWeights(session) == [100, 100])
        #expect(account.goalProgress == 100)
    }

    @Test("Load increases only when every planned set was done at or above the planned weight")
    func testLoadProgressionRules() throws {
        let progressed = makeExercise(name: "Progressed", weights: [100, 100], progress: [true, false])
        let light = makeExercise(name: "Light", weights: [100, 100], progress: [true, true])
        let missing = makeExercise(name: "Missing", weights: [100, 100], progress: [true, true])
        let extra = makeExercise(name: "Extra", weights: [100, 100], progress: [true, true])
        let container = try makeContainer()
        let context = container.mainContext
        let workout = Workout(name: "Test Workout", exercise: [progressed, light, missing, extra])
        context.insert(workout)
        let session = WorkoutSession(workout: workout, startTime: Date(timeIntervalSince1970: 1_700_000_000))
        context.insert(session)
        try context.save()

        let account = UserAccount()
        let completion = WorkoutCompletion(save: { _ in })

        log(session, account: account, completion: completion, exerciseName: "Progressed", setNumber: 1, weight: 100, isDone: true)
        log(session, account: account, completion: completion, exerciseName: "Progressed", setNumber: 2, weight: 100, isDone: true)
        log(session, account: account, completion: completion, exerciseName: "Light", setNumber: 1, weight: 100, isDone: true)
        log(session, account: account, completion: completion, exerciseName: "Light", setNumber: 2, weight: 90, isDone: true)
        log(session, account: account, completion: completion, exerciseName: "Missing", setNumber: 1, weight: 100, isDone: true)
        log(session, account: account, completion: completion, exerciseName: "Extra", setNumber: 1, weight: 100, isDone: true)
        log(session, account: account, completion: completion, exerciseName: "Extra", setNumber: 2, weight: 100, isDone: true)
        log(session, account: account, completion: completion, exerciseName: "Extra", setNumber: 3, weight: 100, isDone: true)

        completion.finish(session: session, account: account, duration: 40 * 60)

        #expect(plannedWeights(session, name: "Progressed") == [102.5, 100])
        #expect(plannedWeights(session, name: "Light") == [100, 100])
        #expect(plannedWeights(session, name: "Missing") == [100, 100])
        #expect(plannedWeights(session, name: "Extra") == [100, 100])
    }

    @Test("A heavier set updates the personal best once, and a later heavier set counts again")
    func testPersonalRecords() throws {
        let exercise = makeExercise(
            weights: [60],
            progress: [false],
            personalBestWeight: 80,
            personalBestReps: 4
        )
        let (container, session) = try makeSession(exercise)
        _ = container
        let account = UserAccount()
        let completion = WorkoutCompletion(save: { _ in })
        let stored = { session.workout.exercises.first }

        log(session, account: account, completion: completion, setNumber: 1, weight: 70, reps: 3, isDone: true)
        #expect(stored()?.personalBestWeight == 80)
        #expect(stored()?.personalBestReps == 4)
        #expect(session.personalRecords == 0)

        log(session, account: account, completion: completion, setNumber: 2, weight: 80, reps: 2, isDone: true)
        #expect(stored()?.personalBestWeight == 80)
        #expect(stored()?.personalBestReps == 4)
        #expect(session.personalRecords == 0)

        log(session, account: account, completion: completion, setNumber: 3, weight: 90, reps: 1, isDone: true)
        #expect(stored()?.personalBestWeight == 90)
        #expect(stored()?.personalBestReps == 1)
        #expect(session.personalRecords == 1)

        log(session, account: account, completion: completion, setNumber: 4, weight: 95, reps: 1, isDone: false)
        #expect(stored()?.personalBestWeight == 95)
        #expect(stored()?.personalBestReps == 1)
        #expect(session.personalRecords == 2)
    }

    @Test("Logging a set raises the strength goal and does not save the account")
    func testStrengthGoalUpdatesWithoutSaving() throws {
        let exercise = makeExercise(weights: [60], progress: [false], personalBestWeight: 200)
        let (container, session) = try makeSession(exercise)
        _ = container
        let account = UserAccount()
        account.strengthGoalExercise = "Bench"
        account.goalProgress = 60
        var saves = 0
        let completion = WorkoutCompletion(save: { _ in saves += 1 })

        log(session, account: account, completion: completion, setNumber: 1, weight: 80, isDone: true)
        #expect(account.goalProgress == 80)
        #expect(session.personalRecords == 0)
        #expect(saves == 0)

        log(session, account: account, completion: completion, exerciseName: "Row", setNumber: 1, weight: 120, isDone: true)
        #expect(account.goalProgress == 80)

        log(session, account: account, completion: completion, setNumber: 2, weight: 70, isDone: true)
        #expect(account.goalProgress == 80)
    }

    @Test("End stamps the clock and applies experience once")
    func testEndAppliesExperienceOnce() throws {
        let clock = DateClock()
        let defaults = makeDefaults()
        let notifications = WorkoutNotificationManager(
            settings: NotificationSettings(),
            scheduler: RecordingNotificationScheduler(now: { clock.date }),
            now: { clock.date }
        )
        let coordinator = WorkoutCoordinator(
            stopwatch: Stopwatch(userDefaults: defaults, now: { clock.date }),
            notifications: notifications,
            health: RecordingWorkoutHealthStore()
        )
        defer { coordinator.stopwatch.reset() }

        let exercise = makeExercise(weights: [60], progress: [false])
        let container = try makeContainer()
        let context = container.mainContext
        let workout = Workout(name: "Test Workout", exercise: [exercise])
        context.insert(workout)

        guard let session = coordinator.start(workout: workout, in: context) else {
            Issue.record("Start should insert a session")
            return
        }
        clock.advance(by: 40 * 60)

        let account = UserAccount()
        var saves = 0
        let completion = WorkoutCompletion(save: { _ in saves += 1 })
        log(session, account: account, completion: completion, setNumber: 1, weight: 80, reps: 5, rest: 45, rpe: 8, isDone: true)

        let elapsed = coordinator.stopwatch.workoutElapsed
        let expected = ExperienceSystem().calculateWorkoutXP(
            duration: elapsed,
            setCount: session.doneSets.count,
            newRecords: session.personalRecords
        )
        coordinator.end(session, account: account, completion: completion)

        let calendar = Calendar.current
        let key = "\(calendar.component(.year, from: Date()))-\(calendar.component(.weekOfYear, from: Date()))"
        #expect(session.endTime == clock.date)
        #expect(abs(session.duration - elapsed) < 0.001)
        #expect(session.personalRecords == 1)
        #expect(account.exp == expected)
        #expect(account.weeklyWorkouts?[key] == 1)
        #expect(saves == 1)
        #expect(session.totalWeight() == 80)

        let endTime = session.endTime
        let duration = session.duration
        clock.advance(by: 30)
        coordinator.end(session, account: account, completion: completion)

        #expect(account.exp == expected)
        #expect(account.weeklyWorkouts?[key] == 1)
        #expect(saves == 1)
        #expect(session.endTime == endTime)
        #expect(session.duration == duration)
    }

    @Test("Success below the rep ceiling adds one rep and leaves the weight")
    func testRepsIncreaseBelowTheCeiling() throws {
        let exercise = makeExercise(weights: [100], progress: [true])
        exercise.repFloor = 5
        exercise.repCeiling = 8
        let (container, session) = try makeSession(exercise)
        _ = container
        let completion = WorkoutCompletion(save: { _ in })

        log(session, account: UserAccount(), completion: completion, setNumber: 1, weight: 100, reps: 5, isDone: true)
        completion.finish(session: session, account: UserAccount(), duration: 60)

        #expect(plannedWeights(session) == [100])
        #expect(plannedReps(session) == [6])
    }

    @Test("Success at the rep ceiling adds weight and resets reps to the floor")
    func testWeightIncreasesAtTheCeiling() throws {
        let exercise = makeExercise(weights: [100], progress: [true])
        exercise.sets[0].reps = 8
        exercise.repFloor = 5
        exercise.repCeiling = 8
        let (container, session) = try makeSession(exercise)
        _ = container
        let completion = WorkoutCompletion(save: { _ in })

        log(session, account: UserAccount(), completion: completion, setNumber: 1, weight: 100, reps: 8, isDone: true)
        completion.finish(session: session, account: UserAccount(), duration: 60)

        #expect(plannedWeights(session) == [102.5])
        #expect(plannedReps(session) == [5])
    }

    @Test("A set under the planned reps does not change the plan")
    func testShortSetDoesNotProgress() throws {
        let exercise = makeExercise(weights: [100], progress: [true])
        exercise.repFloor = 5
        exercise.repCeiling = 8
        let (container, session) = try makeSession(exercise)
        _ = container
        let completion = WorkoutCompletion(save: { _ in })

        log(session, account: UserAccount(), completion: completion, setNumber: 1, weight: 100, reps: 4, isDone: true)
        completion.finish(session: session, account: UserAccount(), duration: 60)

        #expect(plannedWeights(session) == [100])
        #expect(plannedReps(session) == [5])
    }

    @Test("A plan with no stored rep range still adds weight after the planned reps")
    func testMissingRangeStillAddsWeight() throws {
        let exercise = makeExercise(weights: [80], progress: [true])
        let (container, session) = try makeSession(exercise)
        _ = container
        let completion = WorkoutCompletion(save: { _ in })

        log(session, account: UserAccount(), completion: completion, setNumber: 1, weight: 80, reps: 5, isDone: true)
        completion.finish(session: session, account: UserAccount(), duration: 60)

        #expect(exercise.repFloor == nil)
        #expect(exercise.repCeiling == nil)
        #expect(plannedWeights(session) == [82.5])
        #expect(plannedReps(session) == [5])
    }

    @Test("A set with no weight yet stays empty and does not progress")
    func testNoWeightYetStaysEmpty() throws {
        let exercise = makeExercise(weights: [60, 100], progress: [true, true])
        exercise.sets[0].weightUnset = true
        exercise.repFloor = 5
        exercise.repCeiling = 8
        let (container, session) = try makeSession(exercise)
        _ = container
        let account = UserAccount()
        account.strengthGoalExercise = "Bench"
        account.goalProgress = 40
        let completion = WorkoutCompletion(save: { _ in })

        log(session, account: account, completion: completion, setNumber: 1, weight: 0, reps: 5, isDone: true, weightUnset: true)
        log(session, account: account, completion: completion, setNumber: 2, weight: 100, reps: 5, isDone: true)
        completion.finish(session: session, account: account, duration: 60)

        #expect(exercise.sets[0].weightUnset == true)
        #expect(exercise.sets[0].weight == 60)
        #expect(exercise.sets[0].reps == 5)
        #expect(plannedWeights(session) == [60, 100])
        #expect(plannedReps(session) == [5, 6])
        #expect(session.doneSets[0].weightUnset == true)
        #expect(session.doneSets[0].weight == 0)
        #expect(session.totalWeight() == 100)
        #expect(account.goalProgress == 100)
        #expect(exercise.personalBestWeight == 100)
    }
}
