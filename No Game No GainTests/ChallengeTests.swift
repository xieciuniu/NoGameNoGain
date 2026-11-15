//
//  ChallengeTests.swift
//  No Game No GainTests
//

import Foundation
import Testing
@testable import No_Game_No_Gain

struct ChallengeTests {
    private let week: TimeInterval = 7 * 24 * 60 * 60

    @Test("No active goal seeds 5000 and the shown target is 7000")
    func testSeedWithoutGoal() {
        let account = UserAccount()
        #expect(!GoalProgress.hasActiveGoal(account))
        #expect(ChallengeCycle.previousGoalSeed(for: account) == 5000)
        #expect(ChallengeCycle.shownTarget(previousGoal: 5000) == 7000)
        #expect(ChallengeCycle.shownTarget(previousGoal: 80) == 112)
        #expect(ChallengeCycle.shownTarget(previousGoal: 2.5) == 3.5)
        #expect(ChallengeCycle.windowLength == week)
    }

    @Test("An active goal seeds its target and shows 1.4 times that")
    func testSeedFromActiveGoal() {
        let account = UserAccount()
        GoalProgress.applySet(account, kind: .weight, current: 80, target: 100)
        #expect(GoalProgress.hasActiveGoal(account))
        #expect(account.goalEnd == 100)
        #expect(ChallengeCycle.previousGoalSeed(for: account) == 100)
        #expect(ChallengeCycle.shownTarget(previousGoal: 100) == 140)

        GoalProgress.applySet(account, kind: .weight, current: 80, target: 0)
        #expect(GoalProgress.hasActiveGoal(account))
        #expect(ChallengeCycle.previousGoalSeed(for: account) == 5000)
    }

    @Test("A legacy empty weight goal seeds 5000, not 0")
    func testLegacyEmptyGoalSeedsFallback() {
        let account = UserAccount()
        account.goal = "Weight Goal"
        account.goalStart = 0
        account.goalEnd = 0
        account.goalProgress = 65

        #expect(!GoalProgress.hasActiveGoal(account))
        #expect(ChallengeCycle.previousGoalSeed(for: account) == 5000)
        #expect(ChallengeCycle.previousGoalSeed(for: account) != 0)
        #expect(ChallengeCycle.shownTarget(previousGoal: ChallengeCycle.previousGoalSeed(for: account)) == 7000)
    }

    @Test("An elapsed window steps the finished target by 1.4")
    func testRollover() {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let state = ChallengeState(previousGoal: 5000, windowStart: start)

        let stillOpen = ChallengeCycle.rolledForward(state, now: start.addingTimeInterval(week - 1))
        #expect(stillOpen.previousGoal == 5000)
        #expect(stillOpen.windowStart == start)
        #expect(ChallengeCycle.shownTarget(previousGoal: stillOpen.previousGoal) == 7000)

        let once = ChallengeCycle.rolledForward(state, now: start.addingTimeInterval(week))
        #expect(once.previousGoal == 7000)
        #expect(ChallengeCycle.shownTarget(previousGoal: once.previousGoal) == 9800)
        #expect(once.windowStart == start.addingTimeInterval(week))

        let twice = ChallengeCycle.rolledForward(state, now: start.addingTimeInterval(week * 2))
        #expect(twice.previousGoal == 9800)
        #expect(ChallengeCycle.shownTarget(previousGoal: twice.previousGoal) == 13720)
        #expect(twice.windowStart == start.addingTimeInterval(week * 2))
    }

    @Test("Countdown is the time left in the window")
    func testCountdown() {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let sixDaysFourHours = (6 * 24 * 60 * 60) + (4 * 60 * 60)
        let longRemainder = start.addingTimeInterval(week - TimeInterval(sixDaysFourHours))
        #expect(ChallengeCycle.countdown(windowStart: start, now: longRemainder) == "6d 4h")

        let fourHoursLeft = start.addingTimeInterval(week - (4 * 60 * 60))
        let shorter = ChallengeCycle.countdown(windowStart: start, now: fourHoursLeft)
        #expect(shorter == "4h 0m")
        #expect(shorter != "6d 4h")
    }

    @Test("Volume counts weight times reps only for sessions ended inside the window")
    func testWindowVolume() {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let sessions = [
            ChallengeCycle.SessionVolume(
                endTime: start.addingTimeInterval(3_600),
                sets: [
                    ChallengeCycle.SetVolume(weight: 100, reps: 5),
                    ChallengeCycle.SetVolume(weight: 40, reps: 10)
                ]
            ),
            ChallengeCycle.SessionVolume(
                endTime: nil,
                sets: [ChallengeCycle.SetVolume(weight: 500, reps: 10)]
            ),
            ChallengeCycle.SessionVolume(
                endTime: start.addingTimeInterval(-60),
                sets: [ChallengeCycle.SetVolume(weight: 80, reps: 8)]
            ),
            ChallengeCycle.SessionVolume(
                endTime: start.addingTimeInterval(week),
                sets: [ChallengeCycle.SetVolume(weight: 10, reps: 10)]
            )
        ]
        #expect(ChallengeCycle.volume(sessions: sessions, windowStart: start) == 900)
    }

    @Test("Challenge state encodes the previous goal and the window start")
    func testChallengeStateRoundTrip() throws {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let state = ChallengeState(previousGoal: 5000, windowStart: start)
        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(ChallengeState.self, from: data)
        #expect(decoded.previousGoal == state.previousGoal)
        #expect(decoded.windowStart == state.windowStart)
    }
}
