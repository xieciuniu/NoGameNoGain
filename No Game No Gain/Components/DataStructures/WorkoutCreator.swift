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
class Workout {
    var id = UUID()
    var name: String
    var exercises: [Exercise]
    
    init(name: String, exercise: [Exercise]) {
        self.name = name
        self.exercises = exercise
    }
}
