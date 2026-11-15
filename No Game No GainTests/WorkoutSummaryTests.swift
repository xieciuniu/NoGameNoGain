//
//  WorkoutSummaryTests.swift
//  No Game No GainTests
//

import Foundation
import SwiftData
import Testing
@testable import No_Game_No_Gain

@MainActor
struct WorkoutSummaryTests {
    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([Workout.self, Exercise.self, WorkoutSession.self])
        let configuration = ModelConfiguration(UUID().uuidString, schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private func makeSession(reps: Int = 5, ceiling: Int? = 8) throws -> (ModelContainer, WorkoutSession) {
        let container = try makeContainer()
        let context = container.mainContext
        let exercise = Exercise(name: "Bench Press", order: 1)
        exercise.progressPerWorkout = 2.5
        exercise.repFloor = 5
        exercise.repCeiling = ceiling
        exercise.sets = [OneSet(reps: reps, weight: 100, progress: true)]
        let workout = Workout(name: "Push", exercise: [exercise])
        context.insert(workout)
        let session = WorkoutSession(workout: workout, startTime: Date(timeIntervalSince1970: 1_700_000_000))
        context.insert(session)
        let completion = WorkoutCompletion(save: { _ in })
        completion.logSet(
            session: session,
            account: UserAccount(),
            exerciseName: "Bench Press",
            setNumber: 1,
            metrics: SetMetrics(weight: 100, reps: reps, restTime: 30, rpe: 8),
            isDone: true
        )
        completion.logSet(
            session: session,
            account: UserAccount(),
            exerciseName: "Bench Press",
            setNumber: 2,
            metrics: SetMetrics(weight: 90, reps: 3, restTime: 20, rpe: 9),
            isDone: false
        )
        return (container, session)
    }

    @Test("The preview shows the workout and does not save experience or the week")
    func testPreviewDoesNotSave() throws {
        let (container, session) = try makeSession()
        _ = container
        let account = UserAccount()
        account.exp = 10
        account.weeklyWorkouts = [:]
        let preview = WorkoutEndPreview.make(session: session, account: account, duration: 40 * 60)

        #expect(preview.workoutName == "Push")
        #expect(preview.exerciseNames == ["Bench Press"])
        #expect(preview.doneCount == 1)
        #expect(preview.failedCount == 1)
        #expect(preview.volume == 100 * 5 + 90 * 3)
        #expect(preview.personalRecords == 1)
        #expect(preview.experience > 0)
        #expect(preview.experience == preview.experience.rounded())
        #expect(preview.planLines == ["The plan did not change."])
        #expect(account.exp == 10)
        #expect(account.weeklyWorkouts == [:])
        #expect(session.endTime == nil)
        #expect(session.effort == nil)
    }

    @Test("A rep change is listed before it is saved")
    func testPreviewListsTheRepChange() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let exercise = Exercise(name: "Bench Press", order: 1)
        exercise.repFloor = 5
        exercise.repCeiling = 8
        exercise.sets = [OneSet(reps: 5, weight: 100, progress: true)]
        let workout = Workout(name: "Push", exercise: [exercise])
        context.insert(workout)
        let session = WorkoutSession(workout: workout, startTime: Date(timeIntervalSince1970: 1_700_000_000))
        context.insert(session)
        let completion = WorkoutCompletion(save: { _ in })
        completion.logSet(
            session: session,
            account: UserAccount(),
            exerciseName: "Bench Press",
            setNumber: 1,
            metrics: SetMetrics(weight: 100, reps: 5, restTime: 30, rpe: 8),
            isDone: true
        )

        let preview = WorkoutEndPreview.make(session: session, account: UserAccount(), duration: 60)
        #expect(preview.planLines == ["Bench Press: reps 5 → 6"])
        #expect(exercise.sets[0].reps == 5)
        #expect(exercise.sets[0].weight == 100)
    }

    @Test("Confirm stores effort and awards experience once")
    func testConfirmAwardsOnce() throws {
        let (container, session) = try makeSession(reps: 5, ceiling: nil)
        _ = container
        let account = UserAccount()
        let defaultsName = "WorkoutSummaryTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: defaultsName)!
        defaults.removePersistentDomain(forName: defaultsName)
        let clock = Date(timeIntervalSince1970: 1_700_000_000)
        let stopwatch = Stopwatch(userDefaults: defaults, now: { clock })
        let coordinator = WorkoutCoordinator(
            stopwatch: stopwatch,
            notifications: WorkoutNotificationManager(
                settings: NotificationSettings(),
                scheduler: RecordingNotificationScheduler(now: { clock })
            ),
            health: RecordingWorkoutHealthStore()
        )
        let preview = WorkoutEndPreview.make(session: session, account: account, duration: stopwatch.workoutElapsed)
        session.effort = 7
        let completion = WorkoutCompletion(save: { _ in })
        coordinator.end(session, account: account, completion: completion)

        #expect(session.effort == 7)
        #expect(session.endTime != nil)
        #expect(account.exp == preview.experience)

        let awarded = account.exp
        coordinator.end(session, account: account, completion: completion)
        #expect(account.exp == awarded)
        #expect(session.effort == 7)
    }

    @Test("Ending without the summary leaves effort empty")
    func testWatchEndLeavesEffortEmpty() throws {
        let (container, session) = try makeSession(reps: 5, ceiling: nil)
        _ = container
        let account = UserAccount()
        let defaultsName = "WorkoutSummaryTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: defaultsName)!
        defaults.removePersistentDomain(forName: defaultsName)
        let coordinator = WorkoutCoordinator(
            stopwatch: Stopwatch(userDefaults: defaults),
            notifications: WorkoutNotificationManager(
                settings: NotificationSettings(),
                scheduler: RecordingNotificationScheduler()
            ),
            health: RecordingWorkoutHealthStore()
        )
        coordinator.end(session, account: account, completion: WorkoutCompletion(save: { _ in }))
        #expect(session.endTime != nil)
        #expect(session.effort == nil)
        #expect(account.exp > 0)
        #expect(account.exp == account.exp.rounded())
    }

    @Test("The last effort is the newest ended session of the same workout")
    func testLastEffortForTheSameWorkout() {
        let older = endedSession(name: "Push", effort: 4, ended: Date(timeIntervalSince1970: 1_700_000_100))
        let newer = endedSession(name: "Push", effort: 8, ended: Date(timeIntervalSince1970: 1_700_000_500))
        let other = endedSession(name: "Pull", effort: 10, ended: Date(timeIntervalSince1970: 1_700_000_900))
        let open = endedSession(name: "Push", effort: 2, ended: nil)

        #expect(EffortLevel.lastEffort(in: [older, other, newer, open], workoutName: "Push") == 8)
        #expect(EffortLevel.all.count == 10)
        #expect(EffortLevel.all.allSatisfy { !$0.title.isEmpty && !$0.detail.isEmpty })
    }

    private func endedSession(name: String, effort: Int, ended: Date?) -> WorkoutSession {
        let exercise = Exercise(name: "Bench Press", order: 1)
        let workout = Workout(name: name, exercise: [exercise])
        let session = WorkoutSession(workout: workout, startTime: Date(timeIntervalSince1970: 1_700_000_000))
        session.endTime = ended
        session.effort = effort
        return session
    }
}
