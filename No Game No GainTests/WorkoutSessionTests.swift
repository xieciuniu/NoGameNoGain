//
//  WorkoutSessionTests.swift
//  No Game No GainTests
//
//  Created by Hubert Wojtowicz on 06/01/2025.
//

import Testing
@testable import No_Game_No_Gain
import Foundation

struct WorkoutSessionTests {
    
    @Test("Workout session should be properly initialized")
    func testWorkoutSessionInitialization() throws {
        let exercise = Exercise(name: "Bench Press", order: 1)
        let workout = Workout(name: "Test Workout", exercise: [exercise])
        let workoutSession = WorkoutSession(workout: workout, startTime: Date())
        
        #expect(workoutSession.workout.name == "Test Workout")
        #expect(workoutSession.doneSets.isEmpty)
        #expect(workoutSession.endTime == nil)
    }
    
    @Test("Adding completed set should update session data")
    func testAddingCompletedSet() throws {
        let exercise = Exercise(name: "Bench Press", order: 1)
        let workout = Workout(name: "Test Workout", exercise: [exercise])
        let workoutSession = WorkoutSession(workout: workout, startTime: Date())
        let initialSetsCount = workoutSession.doneSets.count
        
        // Symulacja dodania ukończonej serii
        let doneSet = DoneSets(
            id: UUID(),
            exerciseName: "Bench Press",
            numberOfSet: 1,
            weight: 100.0,
            reps: 5,
            restTime: 60,
            isDone: true,
            rpe: nil
        )
        workoutSession.doneSets.append(doneSet)
        
        #expect(workoutSession.doneSets.count == initialSetsCount + 1)
        #expect(workoutSession.doneSets.last?.weight == 100.0)
        #expect(workoutSession.doneSets.last?.reps == 5)
    }
    
    @Test("Total weight calculation should be correct")
    func testTotalWeightCalculation() throws {
        let exercise = Exercise(name: "Bench Press", order: 1)
        let workout = Workout(name: "Test Workout", exercise: [exercise])
        let workoutSession = WorkoutSession(workout: workout, startTime: Date())
        
        // Dodajemy dwie serie
        let set1 = DoneSets(
            id: UUID(),
            exerciseName: "Bench Press",
            numberOfSet: 1,
            weight: 100.0,
            reps: 5,
            restTime: 60,
            isDone: true,
            rpe: nil
        )
        let set2 = DoneSets(
            id: UUID(),
            exerciseName: "Bench Press",
            numberOfSet: 2,
            weight: 100.0,
            reps: 5,
            restTime: 60,
            isDone: true,
            rpe: nil
        )
        
        workoutSession.doneSets.append(set1)
        workoutSession.doneSets.append(set2)
        
        let totalWeight = workoutSession.totalWeight()
        #expect(totalWeight == 200.0)
    }
    
    @Test
    func testTotalWorkoutDurationCalculation() throws {
        let exercise = Exercise(name: "Bench Press", order: 1)
        let workout = Workout(name: "Test Workout", exercise: [exercise])
        let startTime = Date()
        let workoutSession = WorkoutSession(workout: workout, startTime: startTime)
        
        // Simulate ending the workout after 30 minutes
        let endTime = startTime.addingTimeInterval(1800)
        workoutSession.endTime = endTime
        workoutSession.duration = endTime.timeIntervalSince(startTime)
        
        #expect(workoutSession.duration == 1800)
    }
    
}
