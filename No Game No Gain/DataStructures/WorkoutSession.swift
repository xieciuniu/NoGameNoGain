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


@Model
class WorkoutSession {
    var id: UUID = UUID()
    var workout: Workout
    var startTime: Date
    var endTime: Date? = nil
    var doneSets: [DoneSets] = []
    /// Index into `workout.exercises` sorted by `order`. The set index stays derived from `doneSets`.
    var currentExerciseIndex: Int = 0
    var duration: TimeInterval = 0
    var personalRecords: Int = 0
    /// Session average and highest heart rate, in beats per minute. Nil when the Watch sent no samples.
    var averageHeartRateBPM: Double? = nil
    var maximumHeartRateBPM: Double? = nil
    
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
