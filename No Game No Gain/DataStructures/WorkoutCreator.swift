//
//  WorkoutCreator.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 9/18/24.
//

import Foundation
import SwiftData

struct OneSet: Identifiable, Codable {
    var id = UUID()
    var numberOfSameSets: Int = 1
    var reps: Int
    var weight: Double
    var progress: Bool
    /// The set has no load yet. Progression skips it, and the weight stays empty.
    var weightUnset: Bool = false

    init(reps: Int, weight: Double, progress: Bool, numberOfSameSets: Int = 1, weightUnset: Bool = false) {
        self.reps = reps
        self.weight = weight
        self.progress = progress
        self.numberOfSameSets = numberOfSameSets
        self.weightUnset = weightUnset
    }

    enum CodingKeys: String, CodingKey {
        case id, numberOfSameSets, reps, weight, progress, weightUnset
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        numberOfSameSets = try container.decodeIfPresent(Int.self, forKey: .numberOfSameSets) ?? 1
        reps = try container.decode(Int.self, forKey: .reps)
        weight = try container.decodeIfPresent(Double.self, forKey: .weight) ?? 0
        progress = try container.decodeIfPresent(Bool.self, forKey: .progress) ?? false
        weightUnset = try container.decodeIfPresent(Bool.self, forKey: .weightUnset) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(numberOfSameSets, forKey: .numberOfSameSets)
        try container.encode(reps, forKey: .reps)
        try container.encode(weight, forKey: .weight)
        try container.encode(progress, forKey: .progress)
        try container.encode(weightUnset, forKey: .weightUnset)
    }
}

@Model
class Exercise: Comparable {
    var name: String
    var restTime: TimeInterval
    var numberOfSets: Int
    var progressPerWorkout: Double
    var sets: [OneSet]
    var muscleGroup: [String]
    var order: Int
    var exerciseNote: String = ""
    var personalBestWeight: Double? = nil
    var personalBestReps: Int? = nil
    /// Nil means each set’s current reps are both the floor and the ceiling.
    var repFloor: Int? = nil
    var repCeiling: Int? = nil
    
    init(name: String, order: Int) {
        self.name = name
        self.restTime = 90
        self.numberOfSets = 1
        self.progressPerWorkout = 2.5
        self.sets = [OneSet(reps: 5, weight: 60, progress: true)]
        self.muscleGroup = []
        self.order = order
    }
    
    static func <(lhs: Exercise, rhs: Exercise) -> Bool {
        return lhs.order < rhs.order
    }
}

@Model
class Workout: Hashable {
    var id = UUID()
    var name: String
    var exercises: [Exercise]
    
    init(name: String, exercise: [Exercise]) {
        self.name = name
        self.exercises = exercise
    }
}
