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
    var weightUnset: Bool = false

    enum CodingKeys: String, CodingKey {
        case id, exerciseName, numberOfSet, weight, reps, restTime, isDone, rpe, weightUnset
    }

    init(
        id: UUID = UUID(),
        exerciseName: String,
        numberOfSet: Int,
        weight: Double,
        reps: Int,
        restTime: Double,
        isDone: Bool,
        rpe: Int?,
        weightUnset: Bool = false
    ) {
        self.id = id
        self.exerciseName = exerciseName
        self.numberOfSet = numberOfSet
        self.weight = weight
        self.reps = reps
        self.restTime = restTime
        self.isDone = isDone
        self.rpe = rpe
        self.weightUnset = weightUnset
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        exerciseName = try container.decode(String.self, forKey: .exerciseName)
        numberOfSet = try container.decode(Int.self, forKey: .numberOfSet)
        weight = try container.decode(Double.self, forKey: .weight)
        reps = try container.decode(Int.self, forKey: .reps)
        restTime = try container.decode(Double.self, forKey: .restTime)
        isDone = try container.decode(Bool.self, forKey: .isDone)
        rpe = try container.decodeIfPresent(Int.self, forKey: .rpe)
        weightUnset = try container.decodeIfPresent(Bool.self, forKey: .weightUnset) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(exerciseName, forKey: .exerciseName)
        try container.encode(numberOfSet, forKey: .numberOfSet)
        try container.encode(weight, forKey: .weight)
        try container.encode(reps, forKey: .reps)
        try container.encode(restTime, forKey: .restTime)
        try container.encode(isDone, forKey: .isDone)
        try container.encodeIfPresent(rpe, forKey: .rpe)
        try container.encode(weightUnset, forKey: .weightUnset)
    }

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
    /// Effort from 1 to 10 chosen on the phone summary. Nil when the Watch ends the session.
    var effort: Int? = nil
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
