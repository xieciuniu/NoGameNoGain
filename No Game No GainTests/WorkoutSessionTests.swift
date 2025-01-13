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
    
    @Test("Session duration should be correctly calculated")
    func testSessionDuration() throws {
        let exercise = Exercise(name: "Squat", order: 1)
        let workout = Workout(name: "Leg Day", exercise: [exercise])
        
        // Tworzymy sesję z konkretną datą rozpoczęcia
        let startTime = Date()
        let workoutSession = WorkoutSession(workout: workout, startTime: startTime)
        
        // Symulujemy zakończenie treningu po 1 godzinie
        let endTime = startTime.addingTimeInterval(3600) // 1 godzina
        workoutSession.endTime = endTime
        workoutSession.duration = endTime.timeIntervalSince(startTime)
        
        #expect(workoutSession.duration == 3600)
    }

    @Test("Personal best weight should be updated")
    func testPersonalBestUpdate() throws {
        let exercise = Exercise(name: "Deadlift", order: 1)
        exercise.personalBestWeight = 140.0
        let workout = Workout(name: "Back Day", exercise: [exercise])
        let workoutSession = WorkoutSession(workout: workout, startTime: Date())
        
        // Dodajemy serię z nowym rekordem
        let newRecord = DoneSets(
            id: UUID(),
            exerciseName: "Deadlift",
            numberOfSet: 1,
            weight: 150.0,
            reps: 1,
            restTime: 180,
            isDone: true,
            rpe: nil
        )
        workoutSession.doneSets.append(newRecord)
        
        // Aktualizujemy rekord w ćwiczeniu
        if let exerciseIndex = workout.exercises.firstIndex(where: { $0.name == "Deadlift" }) {
            if workout.exercises[exerciseIndex].personalBestWeight ?? 0 < newRecord.weight {
                workout.exercises[exerciseIndex].personalBestWeight = newRecord.weight
            }
        }
        
        #expect(workout.exercises.first?.personalBestWeight == 150.0)
    }

    @Test("Failed sets should be properly marked")
    func testFailedSets() throws {
        let exercise = Exercise(name: "Military Press", order: 1)
        let workout = Workout(name: "Shoulder Day", exercise: [exercise])
        let workoutSession = WorkoutSession(workout: workout, startTime: Date())
        
        // Dodajemy nieudaną serię
        let failedSet = DoneSets(
            id: UUID(),
            exerciseName: "Military Press",
            numberOfSet: 1,
            weight: 60.0,
            reps: 3,
            restTime: 90,
            isDone: false,
            rpe: nil
        )
        workoutSession.doneSets.append(failedSet)
        
        #expect(workoutSession.doneSets.last?.isDone == false)
    }

    @Test("Multiple exercises tracking should work correctly")
    func testMultipleExercisesTracking() throws {
        let exercise1 = Exercise(name: "Bench Press", order: 1)
        let exercise2 = Exercise(name: "Rows", order: 2)
        let workout = Workout(name: "Upper Body", exercise: [exercise1, exercise2])
        let workoutSession = WorkoutSession(workout: workout, startTime: Date())
        
        // Dodajemy serie z różnych ćwiczeń
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
            exerciseName: "Rows",
            numberOfSet: 1,
            weight: 80.0,
            reps: 8,
            restTime: 60,
            isDone: true,
            rpe: nil
        )
        
        workoutSession.doneSets.append(set1)
        workoutSession.doneSets.append(set2)
        
        // Sprawdzamy czy serie są prawidłowo przypisane do ćwiczeń
        let benchPressSets = workoutSession.doneSets.filter { $0.exerciseName == "Bench Press" }
        let rowsSets = workoutSession.doneSets.filter { $0.exerciseName == "Rows" }
        
        #expect(benchPressSets.count == 1)
        #expect(rowsSets.count == 1)
        #expect(benchPressSets.first?.weight == 100.0)
        #expect(rowsSets.first?.weight == 80.0)
    }

    @Test("Rest time between sets should be tracked")
    func testRestTimeBetweenSets() throws {
        let exercise = Exercise(name: "Pull Ups", order: 1)
        let workout = Workout(name: "Back Training", exercise: [exercise])
        let workoutSession = WorkoutSession(workout: workout, startTime: Date())
        
        // Dodajemy dwie serie z określonym czasem odpoczynku
        let set1 = DoneSets(
            id: UUID(),
            exerciseName: "Pull Ups",
            numberOfSet: 1,
            weight: 0.0,
            reps: 10,
            restTime: 90,
            isDone: true,
            rpe: nil
        )
        let set2 = DoneSets(
            id: UUID(),
            exerciseName: "Pull Ups",
            numberOfSet: 2,
            weight: 0.0,
            reps: 8,
            restTime: 120,
            isDone: true,
            rpe: nil
        )
        
        workoutSession.doneSets.append(set1)
        workoutSession.doneSets.append(set2)
        
        #expect(workoutSession.doneSets[1].restTime == 120)
    }
    
}
