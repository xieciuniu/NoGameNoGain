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
    var goal: String = "Weight Goal"
    var strengthGoalExercise: String? = nil
    var goalStart: Double = 0
    var goalEnd: Double = 0
    var goalProgress: Double = 65
    var weeklyWorkouts: [String: Int] = [:]
    
    func getWorkoutsInCurrentWeek() -> Int {
            let calendar = Calendar.current
            let date = Date()
            let year = calendar.component(.year, from: date)
            let week = calendar.component(.weekOfYear, from: date)
            let key = "\(year)-\(week)"
            
            return weeklyWorkouts[key] ?? 0
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
                let workouts = weeklyWorkouts[key] ?? 0
                
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
