//
//  WorkoutSession.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 9/18/24.W
//

import Foundation
import SwiftData

struct DoneSets: Codable, Comparable, Identifiable {
    var id = UUID()
    var exerciseName: String
    var numberOfSet: Int
    var weight: Double
    var reps: Int
    var restTime: Double
    var isDone: Bool
    var rpe: Int?
    
    static func < (lhs: DoneSets, rhs: DoneSets) -> Bool {
        return (lhs.exerciseName, lhs.numberOfSet) < (rhs.exerciseName, rhs.numberOfSet)
    }
}

struct DoneExercise {
    
}

@Model
class WorkoutSession {
    var id: UUID = UUID()
    var workout: Workout
    var startTime: Date
    var endTime: Date? = nil
    var doneSets: [DoneSets] = []
    var duration: TimeInterval = 0
    
    init(workout: Workout, startTime: Date) {
        self.workout = workout
        self.startTime = startTime
    }
}

extension WorkoutSession {
    func totalWeight() -> Double {
        return doneSets.reduce(0) { $0 + $1.weight }
    }
}
