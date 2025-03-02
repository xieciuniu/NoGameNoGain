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
import HealthKit

enum WorkoutState {
    case inProgress
    case paused
}

struct SetMetrics {
    let weight: Double
    let reps: Int
    let restTime: TimeInterval
    let rpe: Int?
}

extension WorkoutView {
    @MainActor class WorkoutViewModel: ObservableObject {
        
        @Published var workoutSession: WorkoutSession
        @Published var workoutState: WorkoutState = .inProgress
        @Published var notificationManager: WorkoutNotificationManager
        
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
        @Published var currentReps: Int = 0
        var restTime: TimeInterval = 50
        
        // Create RPE mesure system
        @Published var rpe: Int = 5
        
        @Published var showingAddExercise = false
        
        init(workoutSession: WorkoutSession, settings: NotificationSettings) {
            self.workoutSession = workoutSession
            self.sortedExercises = workoutSession.workout.exercises.sorted()
            self.notificationManager = WorkoutNotificationManager(settings: settings)
        }
        
        func updateRestTimeNotification(elapsedTime: TimeInterval) {
            let remainingTime = restTime - elapsedTime
            if remainingTime > 0 {
                notificationManager.scheduleNotification(after: remainingTime)
            }
        }
        
        func begin() {
            exerciseName = sortedExercises[currentExercise].name
            exercise = sortedExercises[currentExercise]
            exerciseNotes = exercise.exerciseNote
            restTime = exercise.restTime
        }
        
        func addExercise(_ exercise: Exercise, permanent: Bool) {
            for ex in workoutSession.workout.exercises where ex.order > currentExercise {
                ex.order += 1
            }
            
            workoutSession.workout.exercises.append(exercise)
            
            sortedExercises = workoutSession.workout.exercises.sorted()
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
            let metrics = SetMetrics(
                weight: currentWeight,
                reps: currentReps,
                restTime: restTime,
                rpe: rpe
            )
            
            notificationManager.scheduleNotification(after: self.restTime)
            handleSetCompletion(isDone: isDone, metrics: metrics)
        }
        
        private func handleSetCompletion(isDone: Bool, metrics: SetMetrics) {
            //tworzenie DoneSets
            let setDone = DoneSets(
                exerciseName: exerciseName,
                numberOfSet: currentSet + 1,
                weight: metrics.weight,
                reps: metrics.reps,
                restTime: metrics.restTime,
                isDone: isDone,
                rpe: metrics.rpe
            )
            
            // Dodanie do sesji
            workoutSession.doneSets.append(setDone)
            
            //aktualizacja metryk
            if isDone {
                totalVolume += metrics.weight * Double(metrics.reps)
                completedSets += 1
            }
            
            // Aktualizacja osobistych rekordów
            updatePersonalBests(metrics)
            
            // Przejście do następnej serii
            currentSet += 1
        }
        
        private func updatePersonalBests(_ metrics: SetMetrics) {
            if let index = workoutSession.workout.exercises.firstIndex(where: { $0.name == exerciseName}) {
                if workoutSession.workout.exercises[index].personalBestWeight ?? 0 < metrics.weight {
                    workoutSession.workout.exercises[index].personalBestWeight = metrics.weight
                    workoutSession.workout.exercises[index].personalBestReps = metrics.reps
                    workoutSession.personalRecords += 1                    
                }
            }
            
            
            if exerciseName == userAccount.strengthGoalExercise &&
                userAccount.goalProgress < metrics.weight {
                userAccount.goalProgress = metrics.weight
            }
        }
        
        func percentOfDoneSets() -> Double {
            let doneSetsCount = workoutSession.doneSets.filter({$0.exerciseName == exerciseName}).count
            return Double(doneSetsCount)/Double(exercise.sets.count)
        }

        //MARK: Buttons
        func togglePause() {
            workoutState = workoutState == .inProgress ? .paused : .inProgress
        }
        
        
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
            updateCurrentExercise(elapsedTime: elapsedTime)
        }
        func previousExercise(elapsedTime: TimeInterval) {
            guard canMoveToPreviousExercise() else { return }
            currentExercise -= 1
            updateCurrentExercise(elapsedTime: elapsedTime)
        }
        
        private func updateCurrentExercise(elapsedTime: TimeInterval) {
            exerciseName = sortedExercises[currentExercise].name
            exercise = sortedExercises[currentExercise]
            exerciseNotes = exercise.exerciseNote
            restTime = exercise.restTime
            
            updateRestTimeNotification(elapsedTime: elapsedTime)
        }
        
        func updateExerciseNotes() {
            if let thisExercise = workoutSession.workout.exercises.firstIndex(where: {$0.name == exerciseName}) {
                workoutSession.workout.exercises[thisExercise].exerciseNote = exerciseNotes
            }
        }
        
        //MARK: Workout Ended
        func workoutEnded(workoutDuration: TimeInterval) {
            var gainedExp: Double = 0
            let experienceSystem = ExperienceSystem()
            
            gainedExp = experienceSystem.calculateWorkoutXP(duration: workoutDuration, setCount: workoutSession.doneSets.count, newRecords: workoutSession.personalRecords)
            
            // Oblicz mnożnik na podstawie historii treningów - ta funkcja teraz również aktualizuje weeklyWorkouts
            let expMultiplier = experienceSystem.calculateXPMultiplier(userAccount: userAccount)
            
            // Zastosuj mnożnik do doświadczenia
            gainedExp *= expMultiplier
            
            updateProgressWeight()
            workoutSession.endTime = Date()
            workoutSession.duration = workoutDuration
            
            userAccount.exp += gainedExp
            saveUserAccountToFile(userAccount)
        }
        
        func updateProgressWeight() {
            // Sprawdź każde ćwiczenie
            for exercise in workoutSession.workout.exercises {
                let exerciseSets = workoutSession.doneSets.filter { $0.exerciseName == exercise.name }
                let allSetsCompleted = exerciseSets.count == exercise.sets.count
                
                if allSetsCompleted {
                    // Sprawdź czy wszystkie serie były wykonane z odpowiednim ciężarem
                    let allSetsWithProperWeight = exerciseSets.enumerated().allSatisfy { index, doneSet in
                        doneSet.isDone && doneSet.weight >= exercise.sets[index].weight
                    }
                    
                    if allSetsWithProperWeight {
                        // Zwiększ ciężar we wszystkich seriach z włączonym progresem
                        for (index, set) in exercise.sets.enumerated() where set.progress {
                            exercise.sets[index].weight += exercise.progressPerWorkout
                        }
                    }
                }
            }
        }
        
    }
}
