//
//  ExperienceSystem.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 02/03/2025.
//

import Foundation

class ExperienceSystem {
    // Oblicz XP za trening
    func calculateWorkoutXP(duration: TimeInterval, setCount: Int, newRecords: Int) -> Double {
        var baseXP: Double = 0
        var setsXP: Double = 0
        var recordsXP: Double = 0
        
        // XP za czas treningu
        let durationMinutes = duration / 60
        if durationMinutes >= 30 && durationMinutes < 50 {
            baseXP = 80
        } else if durationMinutes >= 50 && durationMinutes <= 70 {
            baseXP = 150
        } else if durationMinutes > 70 {
            let extraMinutes = min(durationMinutes - 70, 30)
            baseXP = 150 + extraMinutes
        }
        
        // XP za serie
        if setCount <= 15 {
            setsXP = Double(setCount) * 5
        } else if setCount <= 25 {
            setsXP = 15 * 5 + Double(setCount - 15) * 3
        } else {
            setsXP = 15 * 5 + 10 * 3 + Double(setCount - 25)
        }
        setsXP = min(setsXP, 150) // Limit na XP z serii
        
        // XP za rekordy
        recordsXP = Double(newRecords) * 30
        
        return baseXP + setsXP + recordsXP
    }
    
    // Oblicz mnożnik XP na podstawie regularności
    func calculateXPMultiplier(weeklyWorkouts: Int, streakWeeks: Int) -> Double {
        var frequencyMultiplier: Double = 1.0
        var streakMultiplier: Double = 1.0
        
        // Mnożnik za tygodniową częstotliwość
        if weeklyWorkouts == 3 {
            frequencyMultiplier = 1.15
        } else if weeklyWorkouts == 4 {
            frequencyMultiplier = 1.2
        } else if weeklyWorkouts >= 5 {
            frequencyMultiplier = 1.25
        }
        
        // Mnożnik za streak
        if streakWeeks >= 12 {
            streakMultiplier = 1.2
        } else if streakWeeks >= 8 {
            streakMultiplier = 1.15
        } else if streakWeeks >= 4 {
            streakMultiplier = 1.1
        } else if streakWeeks >= 2 {
            streakMultiplier = 1.05
        }
        
        return frequencyMultiplier * streakMultiplier
    }
    
    // Generuj wyzwanie tygodniowe dostosowane do poziomu użytkownika
    func generateWeeklyChallenge(userLevel: Int) -> Challenge {
        let requiredSets = 20 + 2 * userLevel
        let requiredWeight = 500 * userLevel
        
        return Challenge(
            title: "Weekly Challenge",
            description: "Complete \(requiredSets) sets and lift a total of \(requiredWeight)kg",
            rewardXP: 250,
            deadline: Date().addingTimeInterval(7 * 24 * 3600)
        )
    }
}

struct Challenge {
    let title: String
    let description: String
    let rewardXP: Double
    let deadline: Date
}
