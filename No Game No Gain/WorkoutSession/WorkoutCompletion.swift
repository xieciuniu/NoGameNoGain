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
    var weightUnset: Bool = false
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
            rpe: metrics.rpe,
            weightUnset: metrics.weightUnset
        )
        session.doneSets.append(setDone)
        if !metrics.weightUnset {
            updatePersonalBests(session: session, account: account, exerciseName: exerciseName, metrics: metrics)
        }
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
            let logged = session.doneSets.filter { $0.exerciseName == exercise.name }
            guard logged.count == exercise.sets.count else { continue }

            let required = exercise.sets.enumerated().filter { _, set in
                set.progress && !set.weightUnset
            }
            let succeeded = required.allSatisfy { index, set in
                let done = logged[index]
                return done.isDone
                    && !done.weightUnset
                    && done.weight >= set.weight
                    && done.reps >= set.reps
            }
            guard succeeded else { continue }

            for (index, set) in required {
                let floor = exercise.repFloor ?? set.reps
                let ceiling = exercise.repCeiling ?? set.reps
                if set.reps < ceiling {
                    exercise.sets[index].reps += 1
                } else {
                    exercise.sets[index].weight += exercise.progressPerWorkout
                    exercise.sets[index].reps = floor
                }
            }
        }
    }
}
