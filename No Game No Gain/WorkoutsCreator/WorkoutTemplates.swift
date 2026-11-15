//
//  WorkoutTemplates.swift
//  No Game No Gain
//

import Foundation

enum TemplateWeightAnswer: Equatable {
    case weight(Double)
    case noWeightYet
}

struct ExerciseTemplate: Identifiable, Hashable {
    let name: String
    let numberOfSets: Int
    let repFloor: Int
    let repCeiling: Int
    let restTime: TimeInterval
    let progressPerWorkout: Double

    var id: String { name }
}

struct WorkoutTemplate: Identifiable, Hashable {
    let name: String
    let exercises: [ExerciseTemplate]

    var id: String { name }
}

enum WorkoutTemplates {
    /// Built-in plans. Nothing here is stored until onboarding saves a copy.
    static let catalog: [WorkoutTemplate] = [
        WorkoutTemplate(name: "Full Body", exercises: [
            exercise("Back Squat", sets: 3, reps: 5...8, rest: 180),
            exercise("Bench Press", sets: 3, reps: 5...8, rest: 180),
            exercise("Bent-Over Row", sets: 3, reps: 6...10, rest: 120),
            exercise("Romanian Deadlift", sets: 3, reps: 6...10, rest: 120),
        ]),
        WorkoutTemplate(name: "Push", exercises: [
            exercise("Bench Press", sets: 4, reps: 5...8, rest: 180),
            exercise("Overhead Press", sets: 3, reps: 5...8, rest: 150),
            exercise("Incline Dumbbell Press", sets: 3, reps: 8...12, rest: 90),
            exercise("Lateral Raise", sets: 3, reps: 10...15, rest: 60),
            exercise("Triceps Pushdown", sets: 3, reps: 8...12, rest: 60),
        ]),
        WorkoutTemplate(name: "Pull", exercises: [
            exercise("Deadlift", sets: 3, reps: 3...5, rest: 180),
            exercise("Pull-Up", sets: 3, reps: 5...8, rest: 120),
            exercise("Barbell Row", sets: 3, reps: 6...10, rest: 120),
            exercise("Face Pull", sets: 3, reps: 12...15, rest: 60),
            exercise("Barbell Curl", sets: 3, reps: 8...12, rest: 60),
        ]),
    ]

    /// One answer per exercise, in catalog order. Does not insert a session.
    static func makeWorkout(from template: WorkoutTemplate, answers: [TemplateWeightAnswer]) -> Workout {
        let exercises = template.exercises.enumerated().map { index, spec in
            let answer = answers.indices.contains(index) ? answers[index] : .noWeightYet
            return makeExercise(spec, order: index, answer: answer)
        }
        return Workout(name: template.name, exercise: exercises)
    }

    private static func exercise(
        _ name: String,
        sets: Int,
        reps: ClosedRange<Int>,
        rest: TimeInterval,
        progress: Double = 2.5
    ) -> ExerciseTemplate {
        ExerciseTemplate(
            name: name,
            numberOfSets: sets,
            repFloor: reps.lowerBound,
            repCeiling: reps.upperBound,
            restTime: rest,
            progressPerWorkout: progress
        )
    }

    private static func makeExercise(
        _ spec: ExerciseTemplate,
        order: Int,
        answer: TemplateWeightAnswer
    ) -> Exercise {
        let exercise = Exercise(name: spec.name, order: order)
        exercise.restTime = spec.restTime
        exercise.numberOfSets = spec.numberOfSets
        exercise.progressPerWorkout = spec.progressPerWorkout
        exercise.repFloor = spec.repFloor
        exercise.repCeiling = spec.repCeiling
        exercise.order = order
        exercise.sets = (0..<spec.numberOfSets).map { _ in
            switch answer {
            case .weight(let kilograms):
                OneSet(reps: spec.repFloor, weight: kilograms, progress: true, weightUnset: false)
            case .noWeightYet:
                OneSet(reps: spec.repFloor, weight: 0, progress: true, weightUnset: true)
            }
        }
        return exercise
    }
}
