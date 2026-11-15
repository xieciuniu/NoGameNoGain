//
//  WorkoutView-ViewModel.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 8/28/24.
//

import Foundation
import UIKit
import SwiftUI
import _SwiftData_SwiftUI
import HealthKit

extension WorkoutView {
    @MainActor class WorkoutViewModel: ObservableObject {
        
        @Published var workoutSession: WorkoutSession
        let notificationManager: WorkoutNotificationManager
        private let completion = WorkoutCompletion()
        private var appliedWeight = 0.0
        private var appliedReps = 0
        private var appliedRPE = 5
        private var appliedExerciseNotes = ""
        
        @Published var userAccount: UserAccount = loadUserAccountFromFile() ?? UserAccount()
        
        // Number of current exercise to iterate on workout.exercise
        @Published var currentExercise = 0
        // TODO: turn off buttons if next/previouse exercise doesn't exist
        // Number of set to iterate on workout.exercise.set
        @Published var currentSet = 0
        
        var sortedExercises: [Exercise]
        
        var exerciseName: String = ""
        var exercise: Exercise = Exercise(name: "", order: 5)
        private(set) var totalVolume: Double = 0
        private(set) var completedSets: Int = 0
        
        @Published var exerciseNotes: String = ""
        
        
        @Published var currentWeight = 0.0
        @Published var currentWeightUnset = false
        @Published var currentReps: Int = 0
        var restTime: TimeInterval = 50
        
        // Create RPE mesure system
        @Published var rpe: Int = 5
        
        @Published var showingAddExercise = false
        
        init(workoutSession: WorkoutSession, notifications: WorkoutNotificationManager) {
            self.workoutSession = workoutSession
            self.sortedExercises = workoutSession.workout.exercises.sorted()
            self.notificationManager = notifications
        }
        
        func updateRestTimeNotification(elapsedTime: TimeInterval) {
            let remainingTime = restTime - elapsedTime
            if remainingTime > 0 {
                notificationManager.scheduleRest(after: remainingTime)
            }
        }
        
        func begin() {
            guard !sortedExercises.isEmpty else { return }
            let lastIndex = sortedExercises.count - 1
            let storedIndex = workoutSession.currentExerciseIndex
            let clamped = min(max(storedIndex, 0), lastIndex)
            currentExercise = clamped
            if clamped != storedIndex {
                workoutSession.currentExerciseIndex = clamped
                saveSession()
            }
            exerciseName = sortedExercises[currentExercise].name
            exercise = sortedExercises[currentExercise]
            exerciseNotes = exercise.exerciseNote
            appliedExerciseNotes = exerciseNotes
            restTime = exercise.restTime
        }
        
        func addExercise(_ exercise: Exercise, permanent: Bool) {
            for ex in workoutSession.workout.exercises where ex.order > currentExercise {
                ex.order += 1
            }
            
            workoutSession.workout.exercises.append(exercise)
            
            sortedExercises = workoutSession.workout.exercises.sorted()
            notificationManager.userDidAct()
        }
        
        func setWeightRepsSet() {
            let completed = workoutSession.doneSets.filter { $0.exerciseName == exerciseName }.count
            // Logging index stays the completed count, including failed sets.
            // The fields show the next planned set, or the last one once they are all logged.
            currentSet = completed
            if !exercise.sets.isEmpty {
                let fieldIndex = completed < exercise.sets.count ? completed : exercise.sets.count - 1
                currentReps = exercise.sets[fieldIndex].reps
                currentWeightUnset = exercise.sets[fieldIndex].weightUnset
                currentWeight = currentWeightUnset ? 0 : exercise.sets[fieldIndex].weight
            }
            appliedWeight = currentWeight
            appliedReps = currentReps
            appliedRPE = rpe
        }

        /// Ignores the value just written by `setWeightRepsSet` or `begin`.
        /// `onChange` runs after that write, so an equal value is not a user edit.
        func noteWeightEdit() {
            guard currentWeight != appliedWeight else { return }
            appliedWeight = currentWeight
            currentWeightUnset = false
            setCurrentPlanWeightUnset(false)
            notificationManager.userDidAct()
        }

        func toggleNoWeightYet() {
            let completed = workoutSession.doneSets.filter { $0.exerciseName == exerciseName }.count
            guard !exercise.sets.isEmpty else { return }
            let fieldIndex = completed < exercise.sets.count ? completed : exercise.sets.count - 1
            let unset = !exercise.sets[fieldIndex].weightUnset
            exercise.sets[fieldIndex].weightUnset = unset
            currentWeightUnset = unset
            if unset {
                currentWeight = 0
                appliedWeight = 0
            }
            notificationManager.userDidAct()
        }

        private func setCurrentPlanWeightUnset(_ unset: Bool) {
            let completed = workoutSession.doneSets.filter { $0.exerciseName == exerciseName }.count
            guard !exercise.sets.isEmpty else { return }
            let fieldIndex = completed < exercise.sets.count ? completed : exercise.sets.count - 1
            exercise.sets[fieldIndex].weightUnset = unset
        }

        func noteRepsEdit() {
            guard currentReps != appliedReps else { return }
            appliedReps = currentReps
            notificationManager.userDidAct()
        }

        func noteRPEEdit() {
            guard rpe != appliedRPE else { return }
            appliedRPE = rpe
            notificationManager.userDidAct()
        }

        func noteExerciseNotesEdit() {
            updateExerciseNotes()
            guard exerciseNotes != appliedExerciseNotes else { return }
            appliedExerciseNotes = exerciseNotes
            notificationManager.userDidAct()
        }

        func noteAccountNotesEdit() {
            saveUserAccountToFile(userAccount)
            notificationManager.userDidAct()
        }
        
        func setComplete(isDone: Bool, restTime: TimeInterval) {
            let metrics = SetMetrics(
                weight: currentWeightUnset ? 0 : currentWeight,
                reps: currentReps,
                restTime: restTime,
                rpe: rpe,
                weightUnset: currentWeightUnset
            )

            notificationManager.scheduleRest(after: self.restTime)
            notificationManager.userDidAct()
            completion.logSet(
                session: workoutSession,
                account: userAccount,
                exerciseName: exerciseName,
                setNumber: currentSet + 1,
                metrics: metrics,
                isDone: isDone
            )

            if isDone {
                totalVolume += metrics.weight * Double(metrics.reps)
                completedSets += 1
            }

            currentSet += 1
        }
        
        func percentOfDoneSets() -> Double {
            let doneSetsCount = workoutSession.doneSets.filter({$0.exerciseName == exerciseName}).count
            return Double(doneSetsCount)/Double(exercise.sets.count)
        }

        //MARK: Buttons
        // Sprawdzenie czy można bezpiecznie przejść do następnego/poprzedniego ćwiczenia
        func canMoveToNextExercise() -> Bool {
            return currentExercise < sortedExercises.count - 1
        }
        func canMoveToPreviousExercise() -> Bool {
            return currentExercise > 0
        }
        
        func nextExercise(elapsedTime: TimeInterval) {
            guard canMoveToNextExercise() else { print("Error: cannot move to next exercise"); return }
            currentExercise += 1
            storeCurrentExercise()
            updateCurrentExercise(elapsedTime: elapsedTime)
            notificationManager.userDidAct()
        }
        func previousExercise(elapsedTime: TimeInterval) {
            guard canMoveToPreviousExercise() else { return }
            currentExercise -= 1
            storeCurrentExercise()
            updateCurrentExercise(elapsedTime: elapsedTime)
            notificationManager.userDidAct()
        }

        private func storeCurrentExercise() {
            workoutSession.currentExerciseIndex = currentExercise
            saveSession()
        }

        private func saveSession() {
            if let context = workoutSession.modelContext {
                try? context.save()
            }
        }
        
        private func updateCurrentExercise(elapsedTime: TimeInterval) {
            exerciseName = sortedExercises[currentExercise].name
            exercise = sortedExercises[currentExercise]
            exerciseNotes = exercise.exerciseNote
            appliedExerciseNotes = exerciseNotes
            restTime = exercise.restTime
            
            updateRestTimeNotification(elapsedTime: elapsedTime)
        }
        
        func updateExerciseNotes() {
            if let thisExercise = workoutSession.workout.exercises.firstIndex(where: {$0.name == exerciseName}) {
                workoutSession.workout.exercises[thisExercise].exerciseNote = exerciseNotes
            }
        }
        
    }
}
