//
//  WorkoutCompletion.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 24/10/2026.
//

import Foundation

struct SetMetrics {
    let weight: Double
    let reps: Int
    let restTime: TimeInterval
    let rpe: Int?
}

/// Stored-set, personal-record, load-progression, and experience rules.
/// The workout screen keeps the buttons and the clocks. Tests call this type directly.
struct WorkoutCompletion {
    var save: (UserAccount) -> Void = saveUserAccountToFile

    func logSet(
        session: WorkoutSession,
        account: UserAccount,
        exerciseName: String,
        setNumber: Int,
        metrics: SetMetrics,
        isDone: Bool
    ) {
        let setDone = DoneSets(
            exerciseName: exerciseName,
            numberOfSet: setNumber,
            weight: metrics.weight,
            reps: metrics.reps,
            restTime: metrics.restTime,
            isDone: isDone,
            rpe: metrics.rpe
        )
        session.doneSets.append(setDone)
        updatePersonalBests(session: session, account: account, exerciseName: exerciseName, metrics: metrics)
    }

    func finish(
        session: WorkoutSession,
        account: UserAccount,
        duration: TimeInterval
    ) {
        let experienceSystem = ExperienceSystem()
        var gainedExp = experienceSystem.calculateWorkoutXP(
            duration: duration,
            setCount: session.doneSets.count,
            newRecords: session.personalRecords
        )
        let expMultiplier = experienceSystem.calculateXPMultiplier(userAccount: account)
        gainedExp *= expMultiplier
        updateProgressWeight(session)
        account.exp += gainedExp
        save(account)
    }

    private func updatePersonalBests(
        session: WorkoutSession,
        account: UserAccount,
        exerciseName: String,
        metrics: SetMetrics
    ) {
        if let index = session.workout.exercises.firstIndex(where: { $0.name == exerciseName }) {
            if session.workout.exercises[index].personalBestWeight ?? 0 < metrics.weight {
                session.workout.exercises[index].personalBestWeight = metrics.weight
                session.workout.exercises[index].personalBestReps = metrics.reps
                session.personalRecords += 1
            }
        }

        if exerciseName == account.strengthGoalExercise &&
            account.goalProgress < metrics.weight {
            account.goalProgress = metrics.weight
        }
    }

    private func updateProgressWeight(_ session: WorkoutSession) {
        for exercise in session.workout.exercises {
            let exerciseSets = session.doneSets.filter { $0.exerciseName == exercise.name }
            let allSetsCompleted = exerciseSets.count == exercise.sets.count

            if allSetsCompleted {
                let allSetsWithProperWeight = exerciseSets.enumerated().allSatisfy { index, doneSet in
                    doneSet.isDone && doneSet.weight >= exercise.sets[index].weight
                }

                if allSetsWithProperWeight {
                    for (index, set) in exercise.sets.enumerated() where set.progress {
                        exercise.sets[index].weight += exercise.progressPerWorkout
                    }
                }
            }
        }
    }
}
