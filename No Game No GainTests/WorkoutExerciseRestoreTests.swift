//
//  WorkoutExerciseRestoreTests.swift
//  No Game No GainTests
//
//  Created by Hubert Wojtowicz on 24/10/2026.
//

import Foundation
import SwiftData
import Testing
@testable import No_Game_No_Gain

@MainActor
struct WorkoutExerciseRestoreTests {
    private func makeManager() -> WorkoutNotificationManager {
        WorkoutNotificationManager(
            settings: NotificationSettings(),
            scheduler: RecordingNotificationScheduler()
        )
    }

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([Workout.self, Exercise.self, WorkoutSession.self])
        let configuration = ModelConfiguration(UUID().uuidString, schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private func makeExercise(name: String, order: Int, sets: [(reps: Int, weight: Double)]) -> Exercise {
        let exercise = Exercise(name: name, order: order)
        exercise.sets = sets.map { planned in
            OneSet(reps: planned.reps, weight: planned.weight, progress: true)
        }
        return exercise
    }

    private func makeSession(in context: ModelContext) throws -> WorkoutSession {
        let squat = makeExercise(name: "Squat", order: 0, sets: [(reps: 5, weight: 100), (reps: 3, weight: 110)])
        let bench = makeExercise(name: "Bench", order: 1, sets: [(reps: 8, weight: 60), (reps: 6, weight: 70)])
        let workout = Workout(name: "Test Workout", exercise: [squat, bench])
        context.insert(workout)
        let session = WorkoutSession(workout: workout, startTime: Date(timeIntervalSince1970: 1_700_000_000))
        context.insert(session)
        try context.save()
        return session
    }

    private func makeViewModel(_ session: WorkoutSession) -> WorkoutView.WorkoutViewModel {
        WorkoutView.WorkoutViewModel(workoutSession: session, notifications: makeManager())
    }

    private func refetch(_ session: WorkoutSession, in context: ModelContext) throws -> WorkoutSession {
        let stored = try context.fetch(FetchDescriptor<WorkoutSession>())
        guard let match = stored.first(where: { $0.id == session.id }) else {
            Issue.record("Session should still be stored")
            throw RestoreTestError.missingSession
        }
        return match
    }

    private enum RestoreTestError: Error {
        case missingSession
    }

    @Test("A new workout starts at the first exercise and its first planned set")
    func testNewWorkoutStartsAtFirstExercise() throws {
        let container = try makeContainer()
        let session = try makeSession(in: container.mainContext)
        let viewModel = makeViewModel(session)

        #expect(session.currentExerciseIndex == 0)
        viewModel.begin()
        viewModel.setWeightRepsSet()

        #expect(viewModel.currentExercise == 0)
        #expect(viewModel.exerciseName == "Squat")
        #expect(viewModel.currentSet == 0)
        #expect(viewModel.currentWeight == 100)
        #expect(viewModel.currentReps == 5)
    }

    @Test("Relaunch restores the exercise and the next planned set")
    func testRestoreLaterExerciseAndNextSet() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let session = try makeSession(in: context)
        let logging = makeViewModel(session)
        logging.begin()
        logging.setWeightRepsSet()
        logging.nextExercise(elapsedTime: 0)
        logging.setWeightRepsSet()
        logging.setComplete(isDone: true, restTime: 45)
        try context.save()

        let restoredSession = try refetch(session, in: context)
        let restored = makeViewModel(restoredSession)
        restored.begin()
        restored.setWeightRepsSet()

        #expect(restored.currentExercise == 1)
        #expect(restoredSession.currentExerciseIndex == 1)
        #expect(restored.exerciseName == "Bench")
        #expect(restoredSession.doneSets.count == 1)
        #expect(restoredSession.doneSets[0].exerciseName == "Bench")
        #expect(restoredSession.doneSets[0].weight == 60)
        #expect(restoredSession.doneSets[0].reps == 8)
        #expect(restoredSession.doneSets[0].isDone == true)
        #expect(restored.currentSet == 1)
        #expect(restored.currentWeight == 70)
        #expect(restored.currentReps == 6)
    }

    @Test("Done on the restored exercise logs the next planned set and stays put")
    func testDoneOnRestoredExerciseLogsNextSet() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let session = try makeSession(in: context)
        let logging = makeViewModel(session)
        logging.begin()
        logging.nextExercise(elapsedTime: 0)
        logging.setWeightRepsSet()
        logging.setComplete(isDone: true, restTime: 45)
        try context.save()

        let restored = makeViewModel(try refetch(session, in: context))
        restored.begin()
        restored.setWeightRepsSet()
        restored.setComplete(isDone: true, restTime: 30)

        #expect(restored.workoutSession.currentExerciseIndex == 1)
        #expect(restored.exerciseName == "Bench")
        #expect(restored.workoutSession.doneSets.count == 2)
        let logged = restored.workoutSession.doneSets[1]
        #expect(logged.exerciseName == "Bench")
        #expect(logged.numberOfSet == 2)
        #expect(logged.weight == 70)
        #expect(logged.reps == 6)
        #expect(logged.isDone == true)
    }

    @Test("All logged sets show the last planned set and keep the logging index")
    func testAllLoggedSetsShowLastPlannedSet() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let session = try makeSession(in: context)
        session.currentExerciseIndex = 1
        session.doneSets = [
            DoneSets(exerciseName: "Bench", numberOfSet: 1, weight: 60, reps: 8, restTime: 40, isDone: true, rpe: 7),
            DoneSets(exerciseName: "Bench", numberOfSet: 2, weight: 70, reps: 6, restTime: 50, isDone: true, rpe: 8)
        ]
        try context.save()

        let restored = makeViewModel(try refetch(session, in: context))
        restored.begin()
        restored.setWeightRepsSet()

        #expect(restored.exerciseName == "Bench")
        #expect(restored.currentSet == 2)
        #expect(restored.currentWeight == 70)
        #expect(restored.currentReps == 6)
        #expect(restored.workoutSession.doneSets.count == 2)
    }

    @Test("Previous and Next stay inside the plan and store the index")
    func testPreviousAndNextStoreTheIndex() throws {
        let container = try makeContainer()
        let session = try makeSession(in: container.mainContext)
        let viewModel = makeViewModel(session)
        viewModel.begin()

        viewModel.previousExercise(elapsedTime: 0)
        #expect(viewModel.currentExercise == 0)
        #expect(session.currentExerciseIndex == 0)

        viewModel.nextExercise(elapsedTime: 0)
        #expect(viewModel.currentExercise == 1)
        #expect(viewModel.exerciseName == "Bench")
        #expect(session.currentExerciseIndex == 1)

        viewModel.nextExercise(elapsedTime: 0)
        #expect(viewModel.currentExercise == 1)
        #expect(session.currentExerciseIndex == 1)

        viewModel.previousExercise(elapsedTime: 0)
        #expect(viewModel.currentExercise == 0)
        #expect(viewModel.exerciseName == "Squat")
        #expect(session.currentExerciseIndex == 0)
    }

    @Test("Done and Failed stay on the exercise and advance the planned set")
    func testDoneAndFailedStayOnTheExercise() throws {
        let container = try makeContainer()
        let session = try makeSession(in: container.mainContext)
        let viewModel = makeViewModel(session)
        viewModel.begin()
        viewModel.setWeightRepsSet()

        viewModel.setComplete(isDone: true, restTime: 20)
        viewModel.setWeightRepsSet()

        #expect(session.currentExerciseIndex == 0)
        #expect(viewModel.exerciseName == "Squat")
        #expect(session.doneSets.count == 1)
        #expect(session.doneSets[0].isDone == true)
        #expect(session.doneSets[0].weight == 100)
        #expect(session.doneSets[0].reps == 5)
        #expect(viewModel.currentSet == 1)
        #expect(viewModel.currentWeight == 110)
        #expect(viewModel.currentReps == 3)

        viewModel.setComplete(isDone: false, restTime: 15)
        viewModel.setWeightRepsSet()

        #expect(session.currentExerciseIndex == 0)
        #expect(viewModel.currentExercise == 0)
        #expect(session.doneSets.count == 2)
        #expect(session.doneSets[1].isDone == false)
        #expect(session.doneSets[1].exerciseName == "Squat")
        #expect(session.doneSets[1].numberOfSet == 2)
        #expect(viewModel.currentSet == 2)
        #expect(viewModel.currentWeight == 110)
        #expect(viewModel.currentReps == 3)
    }

    @Test("An out of range stored index clamps onto the last exercise")
    func testOutOfRangeIndexClamps() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let session = try makeSession(in: context)
        session.currentExerciseIndex = 9
        try context.save()

        let restored = makeViewModel(try refetch(session, in: context))
        restored.begin()

        #expect(restored.currentExercise == 1)
        #expect(restored.exerciseName == "Bench")
        #expect(restored.workoutSession.currentExerciseIndex == 1)
    }

    @Test("begin does nothing when the plan has no exercises")
    func testBeginOnEmptyPlan() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let workout = Workout(name: "Empty", exercise: [])
        context.insert(workout)
        let session = WorkoutSession(workout: workout, startTime: Date(timeIntervalSince1970: 1_700_000_000))
        session.currentExerciseIndex = 4
        context.insert(session)

        let viewModel = makeViewModel(session)
        viewModel.begin()

        #expect(viewModel.exerciseName == "")
        #expect(viewModel.currentExercise == 0)
        #expect(session.currentExerciseIndex == 4)
    }
}
