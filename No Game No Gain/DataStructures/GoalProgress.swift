//
//  GoalProgress.swift
//  No Game No Gain
//

import Foundation

enum GoalKind: Equatable {
    case weight
    case strength(exerciseName: String)
}

/// Pure goal rules. Views save the account after these mutate it.
enum GoalProgress {
    static func hasActiveGoal(_ account: UserAccount) -> Bool {
        if account.goal.isEmpty || isLegacyUntouched(account) {
            return false
        }
        if account.goal == "Strength Goal" {
            let name = account.strengthGoalExercise?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return !name.isEmpty && hasTarget(start: account.goalStart, end: account.goalEnd)
        }
        if account.goal == "Weight Goal" {
            return account.goalStart != 0 || account.goalEnd != 0
        }
        return false
    }

    /// Progress to show. An empty or untouched account is never 65.
    static func displayedProgress(_ account: UserAccount) -> Double {
        guard hasActiveGoal(account) else { return 0 }
        return account.goalProgress
    }

    static func directionSentence(kind: GoalKind, start: Double, target: Double) -> String {
        switch kind {
        case .weight:
            if target < start {
                return "Lose \(formatKilograms(start - target)) kg"
            }
            if target > start {
                return "Gain \(formatKilograms(target - start)) kg"
            }
            return "Stay at \(formatKilograms(start)) kg"
        case .strength(let exerciseName):
            return "\(exerciseName) to \(formatKilograms(target)) kg"
        }
    }

    static func directionSentence(for account: UserAccount) -> String {
        if account.goal == "Strength Goal" {
            return directionSentence(
                kind: .strength(exerciseName: account.strengthGoalExercise ?? ""),
                start: account.goalStart,
                target: account.goalEnd
            )
        }
        return directionSentence(kind: .weight, start: account.goalStart, target: account.goalEnd)
    }

    /// 0 at the start, 1 at the target. Movement away from the target stays at 0.
    static func barFraction(start: Double, current: Double, target: Double) -> Double {
        if target == start {
            return current == target ? 1 : 0
        }
        let fraction: Double
        if target < start {
            fraction = (start - current) / (start - target)
        } else {
            fraction = (current - start) / (target - start)
        }
        return min(1, max(0, fraction))
    }

    static func barFraction(for account: UserAccount) -> Double {
        barFraction(start: account.goalStart, current: account.goalProgress, target: account.goalEnd)
    }

    static func isReached(start: Double, current: Double, target: Double) -> Bool {
        if target < start {
            return current <= target
        }
        if target > start {
            return current >= target
        }
        return current == target
    }

    static func isReached(_ account: UserAccount) -> Bool {
        isReached(start: account.goalStart, current: account.goalProgress, target: account.goalEnd)
    }

    static func applySet(_ account: UserAccount, kind: GoalKind, current: Double, target: Double) {
        switch kind {
        case .weight:
            account.goal = "Weight Goal"
            account.strengthGoalExercise = nil
        case .strength(let exerciseName):
            account.goal = "Strength Goal"
            account.strengthGoalExercise = exerciseName
        }
        account.goalStart = current
        account.goalProgress = current
        account.goalEnd = target
    }

    static func applyClear(_ account: UserAccount) {
        account.goal = ""
        account.strengthGoalExercise = nil
        account.goalStart = 0
        account.goalEnd = 0
        account.goalProgress = 0
    }

    /// Accepts "." or "," as the decimal separator.
    static func parseTarget(_ text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let normalized = trimmed.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(normalized), value.isFinite else { return nil }
        return value
    }

    static func formatKilograms(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        formatter.decimalSeparator = "."
        let rounded = (value * 10).rounded() / 10
        return formatter.string(from: NSNumber(value: rounded)) ?? "0"
    }

    private static func isLegacyUntouched(_ account: UserAccount) -> Bool {
        account.goal == "Weight Goal"
            && account.goalStart == 0
            && account.goalEnd == 0
            && (account.goalProgress == 65 || account.goalProgress == 0)
    }

    private static func hasTarget(start: Double, end: Double) -> Bool {
        start != 0 || end != 0
    }
}
