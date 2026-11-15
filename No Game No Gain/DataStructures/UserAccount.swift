//
//  UserAccount.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 19/10/2024.
//

import Foundation

class UserAccount: Codable {
    var notes: String = ""
    var name: String = ""
    var exp: Double = 0
    var expMultiplier: Double = 1 // To usunąć
    var weight: Double = 0
    var goal: String = ""
    var strengthGoalExercise: String? = nil
    var goalStart: Double = 0
    var goalEnd: Double = 0
    var goalProgress: Double = 0
    var weeklyWorkouts: [String: Int]? = [:]
    var stepGoal: Double = 18000
    var calorieGoal: Double? = nil
    var sleepGoalMinutes: Double? = nil

    init() {}

    enum CodingKeys: String, CodingKey {
        case notes, name, exp, expMultiplier, weight, goal, strengthGoalExercise
        case goalStart, goalEnd, goalProgress, weeklyWorkouts
        case stepGoal, calorieGoal, sleepGoalMinutes
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        exp = try container.decodeIfPresent(Double.self, forKey: .exp) ?? 0
        expMultiplier = try container.decodeIfPresent(Double.self, forKey: .expMultiplier) ?? 1
        weight = try container.decodeIfPresent(Double.self, forKey: .weight) ?? 0
        goal = try container.decodeIfPresent(String.self, forKey: .goal) ?? ""
        strengthGoalExercise = try container.decodeIfPresent(String.self, forKey: .strengthGoalExercise)
        goalStart = try container.decodeIfPresent(Double.self, forKey: .goalStart) ?? 0
        goalEnd = try container.decodeIfPresent(Double.self, forKey: .goalEnd) ?? 0
        goalProgress = try container.decodeIfPresent(Double.self, forKey: .goalProgress) ?? 0
        weeklyWorkouts = try container.decodeIfPresent([String: Int].self, forKey: .weeklyWorkouts) ?? [:]
        stepGoal = try container.decodeIfPresent(Double.self, forKey: .stepGoal) ?? 18000
        calorieGoal = try container.decodeIfPresent(Double.self, forKey: .calorieGoal)
        sleepGoalMinutes = try container.decodeIfPresent(Double.self, forKey: .sleepGoalMinutes)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(notes, forKey: .notes)
        try container.encode(name, forKey: .name)
        try container.encode(exp, forKey: .exp)
        try container.encode(expMultiplier, forKey: .expMultiplier)
        try container.encode(weight, forKey: .weight)
        try container.encode(goal, forKey: .goal)
        try container.encodeIfPresent(strengthGoalExercise, forKey: .strengthGoalExercise)
        try container.encode(goalStart, forKey: .goalStart)
        try container.encode(goalEnd, forKey: .goalEnd)
        try container.encode(goalProgress, forKey: .goalProgress)
        try container.encode(weeklyWorkouts ?? [:], forKey: .weeklyWorkouts)
        try container.encode(stepGoal, forKey: .stepGoal)
        try container.encodeIfPresent(calorieGoal, forKey: .calorieGoal)
        try container.encodeIfPresent(sleepGoalMinutes, forKey: .sleepGoalMinutes)
    }

    func getWorkoutsInCurrentWeek() -> Int {
            let calendar = Calendar.current
            let date = Date()
            let year = calendar.component(.year, from: date)
            let week = calendar.component(.weekOfYear, from: date)
            let key = "\(year)-\(week)"
            
        return weeklyWorkouts?[key] ?? 0
        }
        
        // Oblicza liczbę tygodni z treningami pod rząd (streak)
        func getWorkoutStreakWeeks() -> Int {
            let calendar = Calendar.current
            let currentDate = Date()
            let currentYear = calendar.component(.year, from: currentDate)
            let currentWeek = calendar.component(.weekOfYear, from: currentDate)
            
            var streakWeeks = 0
            var weekToCheck = currentWeek
            var yearToCheck = currentYear
            
            // Sprawdzamy wstecz, czy każdy tydzień miał co najmniej jeden trening
            while true {
                let key = "\(yearToCheck)-\(weekToCheck)"
                let workouts = weeklyWorkouts?[key] ?? 0
                
                if workouts > 0 {
                    streakWeeks += 1
                    
                    // Przejdź do poprzedniego tygodnia
                    weekToCheck -= 1
                    if weekToCheck <= 0 {
                        // Jeśli przekraczamy początek roku, cofamy się do ostatniego tygodnia poprzedniego roku
                        yearToCheck -= 1
                        let weeksInPreviousYear = calendar.range(of: .weekOfYear, in: .year, for: calendar.date(from: DateComponents(year: yearToCheck, month: 12, day: 31))!)!.count
                        weekToCheck = weeksInPreviousYear
                    }
                } else {
                    // Jeśli w którymś tygodniu nie było treningu, przerywamy
                    break
                }
            }
            
            return streakWeeks
        }
}

func getDocumentsDirectory() -> URL {
    return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
}

func saveUserAccountToFile(_ userAccount: UserAccount) {
    let fileURL = getDocumentsDirectory().appendingPathComponent("userAccount.json")
    do {
        let data = try JSONEncoder().encode(userAccount)
        try data.write(to: fileURL)
        print("User account data saved successfully!")
    } catch {
        print("Failed to save user account data: \(error)")
    }
}

func loadUserAccountFromFile() -> UserAccount? {
    let fileURL = getDocumentsDirectory().appendingPathComponent("userAccount.json")
    do {
        let data = try Data(contentsOf: fileURL)
        let userAccount = try JSONDecoder().decode(UserAccount.self, from: data)
        return userAccount
    } catch {
        print("Failed to load user account data: \(error)")
        return nil
    }
    
}
