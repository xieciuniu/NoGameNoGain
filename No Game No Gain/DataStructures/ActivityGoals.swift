//
//  ActivityGoals.swift
//  No Game No Gain
//

import Foundation

enum ActivityKind: String, Codable, Hashable {
    case steps
    case calories
    case sleep

    var title: String {
        switch self {
        case .steps: "Steps"
        case .calories: "Calories"
        case .sleep: "Sleep"
        }
    }
}

enum GoalEdit: Equatable {
    case value(Double)
    case clear
    case invalid
}

/// Step, calorie, and sleep goals. Sleep on screen is a clock, not a raw minute count.
enum ActivityGoals {
    /// Hours and zero-padded minutes. Fractional minutes truncate toward zero.
    static func clock(minutes: Double) -> String {
        guard minutes.isFinite else { return "0:00" }
        let total = max(0, Int(minutes.rounded(.towardZero)))
        let hours = total / 60
        let minute = total % 60
        return String(format: "%d:%02d", hours, minute)
    }

    /// `current / goal`, clamped to 0...1. No goal, or a goal of 0, has no fraction.
    static func progressFraction(current: Double, goal: Double?) -> Double? {
        guard let goal, goal != 0, current.isFinite, goal.isFinite else { return nil }
        return min(1, max(0, current / goal))
    }

    static func showsGoalLine(_ kind: ActivityKind, account: UserAccount) -> Bool {
        switch kind {
        case .steps:
            return true
        case .calories:
            return account.calorieGoal != nil
        case .sleep:
            return account.sleepGoalMinutes != nil
        }
    }

    static func storedGoal(_ kind: ActivityKind, account: UserAccount) -> Double? {
        switch kind {
        case .steps:
            return account.stepGoal
        case .calories:
            return account.calorieGoal
        case .sleep:
            return account.sleepGoalMinutes
        }
    }

    static func goalLabel(_ kind: ActivityKind, account: UserAccount) -> String? {
        guard showsGoalLine(kind, account: account), let goal = storedGoal(kind, account: account) else {
            return nil
        }
        switch kind {
        case .steps, .calories:
            return "Goal: \(numberText(goal))"
        case .sleep:
            return "Goal: \(clock(minutes: goal))"
        }
    }

    static func numberText(_ value: Double) -> String {
        guard value.isFinite else { return "0" }
        let format = value.rounded() == value ? "%.0f" : "%.1f"
        return String(format: format, locale: Locale(identifier: "en_US_POSIX"), value)
    }

    static func hourMinuteFields(minutes: Double) -> (hours: String, minutes: String) {
        guard minutes.isFinite else { return ("0", "00") }
        let total = max(0, Int(minutes.rounded(.towardZero)))
        return (String(total / 60), String(format: "%02d", total % 60))
    }

    static func numberEdit(_ text: String, emptyClears: Bool) -> GoalEdit {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return emptyClears ? .clear : .invalid
        }
        let normalized = trimmed.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(normalized), value >= 0, value.isFinite else { return .invalid }
        return .value(value)
    }

    /// Hours and minutes, or one clock field such as `7:05` or `7:5`. Empty clears the goal.
    static func sleepEdit(hoursText: String, minutesText: String) -> GoalEdit {
        let hoursText = hoursText.trimmingCharacters(in: .whitespacesAndNewlines)
        let minutesText = minutesText.trimmingCharacters(in: .whitespacesAndNewlines)
        if hoursText.isEmpty && minutesText.isEmpty {
            return .clear
        }
        if hoursText.contains(":") || minutesText.contains(":") {
            let clockText = hoursText.contains(":") ? hoursText : minutesText
            let other = hoursText.contains(":") ? minutesText : hoursText
            guard other.isEmpty, let minutes = minutes(fromClock: clockText) else { return .invalid }
            return .value(minutes)
        }
        let hours = hoursText.isEmpty ? 0 : Int(hoursText)
        let minutes = minutesText.isEmpty ? 0 : Int(minutesText)
        guard let hours, let minutes, hours >= 0, minutes >= 0 else { return .invalid }
        return .value(Double(hours * 60 + minutes))
    }

    static func minutes(fromClock text: String) -> Double? {
        let parts = text.split(separator: ":", omittingEmptySubsequences: false)
        guard parts.count == 2, let hours = Int(parts[0]), let minute = Int(parts[1]) else { return nil }
        guard hours >= 0, minute >= 0, minute < 60 else { return nil }
        return Double(hours * 60 + minute)
    }
}
