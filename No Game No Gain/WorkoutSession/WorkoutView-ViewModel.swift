//
//  WorkoutView-ViewModel.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 8/28/24.
//

import Foundation
import UIKit
import SwiftUICore
import _SwiftData_SwiftUI

extension WorkoutView {
    @MainActor class WorkoutViewModel: ObservableObject {
        
        @Published var workoutSession: WorkoutSession

        @Published var userAccount: UserAccount = loadUserAccountFromFile() ?? UserAccount()
        
        // Number of current exercise to iterate on workout.exercise
        @Published var currentExercise = 0
        // TODO: turn off buttons if next/previouse exercise doesn't exist
        // Number of set to iterate on workout.exercise.set
        @Published var currentSet = 0
        
        let sortedExercises: [Exercise]
        
        var exerciseName: String = ""
        var exercise: Exercise = Exercise(name: "", order: 5)
        
        @Published var exerciseNotes: String = ""


        @Published var currentWeight = 0.0
        @Published var currentReps: Int = 0
        var restTime: TimeInterval = 50
        
        // Create RPE mesure system
        @Published var rpe: Int = 5
        
        
        init(workoutSession: WorkoutSession) {
            self.workoutSession = workoutSession
            self.sortedExercises = workoutSession.workout.exercises.sorted()
        }
        
        func begin() {
            exerciseName = sortedExercises[currentExercise].name
            exercise = sortedExercises[currentExercise]
            exerciseNotes = exercise.exerciseNote
            restTime = exercise.restTime
        }
        
        func setWeightRepsSet() {
            if !workoutSession.doneSets.filter({$0.exerciseName == exerciseName}).isEmpty {
                currentSet = workoutSession.doneSets.filter({$0.exerciseName == exerciseName}).count
            } else {
                currentSet = 0
            }
            if currentSet < exercise.sets.count {
                currentReps = exercise.sets[currentSet].reps
                currentWeight = exercise.sets[currentSet].weight
            }
        }
        
        func setComplete(isDone: Bool, restTime: TimeInterval) {
            let setDone = DoneSets(exerciseName: exerciseName, numberOfSet: currentSet + 1, weight: currentWeight, reps: currentReps, restTime: restTime, isDone: isDone, rpe: nil)
            workoutSession.doneSets.append(setDone)
            currentSet += 1
        }
        
        func previousExercise() {
            currentExercise -= 1
            exerciseName = sortedExercises[currentExercise].name
            exercise = sortedExercises[currentExercise]
            exerciseNotes = exercise.exerciseNote
            restTime = exercise.restTime
        }
        
        func nextExercise() {
            currentExercise += 1
            exerciseName = sortedExercises[currentExercise].name
            exercise = sortedExercises[currentExercise]
            exerciseNotes = exercise.exerciseNote
            restTime = exercise.restTime
        }
        
        func updateExerciseNotes() {
            if let thisExercise = workoutSession.workout.exercises.firstIndex(where: {$0.name == exerciseName}) {
                workoutSession.workout.exercises[thisExercise].exerciseNote = exerciseNotes
            }
        }

    }
}
