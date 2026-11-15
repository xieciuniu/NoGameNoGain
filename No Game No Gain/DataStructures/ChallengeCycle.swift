//
//  ChallengeCycle.swift
//  No Game No Gain
//

import Foundation

struct ChallengeState: Codable, Equatable {
    var previousGoal: Double
    var windowStart: Date
}

/// One home challenge. The shown target is 1.4 times the stored previous goal.
enum ChallengeCycle {
    static let windowLength: TimeInterval = 7 * 24 * 60 * 60
    static let fallbackPreviousGoal: Double = 5000
    static let maxRolloverSteps = 520

    struct SetVolume {
        var weight: Double
        var reps: Int
    }

    struct SessionVolume {
        var endTime: Date?
        var sets: [SetVolume]
    }

    /// Active goal target when that goal is active and its end is positive. Otherwise 5000 kg.
    static func previousGoalSeed(for account: UserAccount) -> Double {
        if GoalProgress.hasActiveGoal(account), account.goalEnd > 0 {
            return account.goalEnd
        }
        return fallbackPreviousGoal
    }

    static func seededState(for account: UserAccount, now: Date) -> ChallengeState {
        ChallengeState(previousGoal: previousGoalSeed(for: account), windowStart: now)
    }

    /// 1.4×, rounded to one decimal: `(value * 14).rounded() / 10`.
    static func shownTarget(previousGoal: Double) -> Double {
        (previousGoal * 14).rounded() / 10
    }

    static func windowEnd(for windowStart: Date) -> Date {
        windowStart.addingTimeInterval(windowLength)
    }

    static func rolledForward(_ state: ChallengeState, now: Date) -> ChallengeState {
        var next = state
        var steps = 0
        while steps < maxRolloverSteps, now >= windowEnd(for: next.windowStart) {
            next.previousGoal = shownTarget(previousGoal: next.previousGoal)
            next.windowStart = windowEnd(for: next.windowStart)
            steps += 1
        }
        return next
    }

    static func countdown(windowStart: Date, now: Date) -> String {
        let remaining = max(0, windowEnd(for: windowStart).timeIntervalSince(now))
        let wholeSeconds = Int(remaining)
        let days = wholeSeconds / 86_400
        let hours = (wholeSeconds % 86_400) / 3_600
        if days > 0 {
            return "\(days)d \(hours)h"
        }
        let minutes = (wholeSeconds % 3_600) / 60
        return "\(hours)h \(minutes)m"
    }

    /// Weight times reps for sessions that ended inside `[windowStart, windowStart + 7 days)`.
    static func volume(sessions: [SessionVolume], windowStart: Date) -> Double {
        let end = windowEnd(for: windowStart)
        var total = 0.0
        for session in sessions {
            guard let ended = session.endTime, ended >= windowStart, ended < end else { continue }
            for set in session.sets {
                total += set.weight * Double(set.reps)
            }
        }
        return total
    }
}

func loadChallengeState() -> ChallengeState? {
    let fileURL = getDocumentsDirectory().appendingPathComponent("challenge.json")
    guard let data = try? Data(contentsOf: fileURL) else { return nil }
    return try? JSONDecoder().decode(ChallengeState.self, from: data)
}

func saveChallengeState(_ state: ChallengeState) {
    let fileURL = getDocumentsDirectory().appendingPathComponent("challenge.json")
    do {
        let data = try JSONEncoder().encode(state)
        try data.write(to: fileURL)
    } catch {
        print("Failed to save challenge: \(error)")
    }
}
