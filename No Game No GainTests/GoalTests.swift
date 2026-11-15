//
//  GoalTests.swift
//  No Game No GainTests
//

import Foundation
import Testing
@testable import No_Game_No_Gain

struct GoalTests {
    @Test("A fresh account is not a goal and does not show 65")
    func testFreshAccountIsEmpty() {
        let account = UserAccount()
        #expect(account.goal == "")
        #expect(account.goalProgress == 0)
        #expect(!GoalProgress.hasActiveGoal(account))
        #expect(GoalProgress.displayedProgress(account) != 65)
        #expect(GoalProgress.displayedProgress(account) == 0)
    }

    @Test("The untouched weight default is not an active goal")
    func testLegacyDefaultIsNotShown() {
        let account = UserAccount()
        account.goal = "Weight Goal"
        account.goalStart = 0
        account.goalEnd = 0
        account.goalProgress = 65

        #expect(!GoalProgress.hasActiveGoal(account))
        #expect(GoalProgress.displayedProgress(account) != 65)
        #expect(GoalProgress.displayedProgress(account) == 0)

        account.goalProgress = 0
        #expect(!GoalProgress.hasActiveGoal(account))
        #expect(GoalProgress.displayedProgress(account) != 65)
    }

    @Test("A lower weight target reads as losing and the bar moves that way")
    func testLosingWeight() {
        #expect(GoalProgress.directionSentence(kind: .weight, start: 80, target: 77.5) == "Lose 2.5 kg")
        #expect(GoalProgress.barFraction(start: 80, current: 78.75, target: 77.5) == 0.5)
        #expect(!GoalProgress.isReached(start: 80, current: 78.75, target: 77.5))

        #expect(GoalProgress.barFraction(start: 80, current: 77.5, target: 77.5) == 1)
        #expect(GoalProgress.isReached(start: 80, current: 77.5, target: 77.5))
        #expect(GoalProgress.barFraction(start: 80, current: 70, target: 77.5) == 1)
        #expect(GoalProgress.isReached(start: 80, current: 70, target: 77.5))

        #expect(GoalProgress.barFraction(start: 80, current: 81, target: 77.5) == 0)
        #expect(!GoalProgress.isReached(start: 80, current: 81, target: 77.5))
    }

    @Test("A higher weight target reads as gaining and the bar moves that way")
    func testGainingWeight() {
        #expect(GoalProgress.directionSentence(kind: .weight, start: 70, target: 80) == "Gain 10 kg")
        #expect(GoalProgress.barFraction(start: 70, current: 75, target: 80) == 0.5)
        #expect(!GoalProgress.isReached(start: 70, current: 75, target: 80))

        #expect(GoalProgress.barFraction(start: 70, current: 80, target: 80) == 1)
        #expect(GoalProgress.isReached(start: 70, current: 80, target: 80))
        #expect(GoalProgress.barFraction(start: 70, current: 85, target: 80) == 1)
        #expect(GoalProgress.isReached(start: 70, current: 85, target: 80))

        #expect(GoalProgress.barFraction(start: 70, current: 65, target: 80) == 0)
        #expect(!GoalProgress.isReached(start: 70, current: 65, target: 80))
    }

    @Test("An equal weight target stays put")
    func testStayingAtWeight() {
        #expect(GoalProgress.directionSentence(kind: .weight, start: 80, target: 80) == "Stay at 80 kg")
        #expect(GoalProgress.barFraction(start: 80, current: 80, target: 80) == 1)
        #expect(GoalProgress.isReached(start: 80, current: 80, target: 80))
        #expect(GoalProgress.barFraction(start: 80, current: 79, target: 80) == 0)
    }

    @Test("A strength goal names the exercise and uses the stored best")
    func testStrengthSentenceUsesBest() {
        let account = UserAccount()
        GoalProgress.applySet(account, kind: .strength(exerciseName: "Bench Press"), current: 60, target: 80)

        #expect(account.goal == "Strength Goal")
        #expect(account.strengthGoalExercise == "Bench Press")
        #expect(account.goalStart == 60)
        #expect(account.goalProgress == 60)
        #expect(account.goalEnd == 80)
        #expect(GoalProgress.directionSentence(for: account) == "Bench Press to 80 kg")
        #expect(GoalProgress.directionSentence(kind: .strength(exerciseName: "Bench Press"), start: 60, target: 80) == "Bench Press to 80 kg")
        #expect(GoalProgress.barFraction(for: account) == 0)

        account.goalProgress = 70
        #expect(GoalProgress.displayedProgress(account) == 70)
        #expect(GoalProgress.barFraction(for: account) == 0.5)
        #expect(!GoalProgress.isReached(account))

        account.goalProgress = 80
        #expect(GoalProgress.barFraction(for: account) == 1)
        #expect(GoalProgress.isReached(account))
    }

    @Test("Setting, editing, and clearing a goal round-trip through JSON")
    func testSetEditAndClearRoundTrip() throws {
        let account = UserAccount()
        account.weight = 80
        account.strengthGoalExercise = "Squat"

        GoalProgress.applySet(account, kind: .weight, current: account.weight, target: 77.5)
        #expect(account.goal == "Weight Goal")
        #expect(account.strengthGoalExercise == nil)
        #expect(account.goalStart == 80)
        #expect(account.goalProgress == 80)
        #expect(account.goalEnd == 77.5)
        #expect(GoalProgress.hasActiveGoal(account))

        GoalProgress.applySet(account, kind: .weight, current: account.weight, target: 75)
        #expect(account.goalEnd == 75)
        #expect(account.goalStart == 80)
        #expect(GoalProgress.directionSentence(for: account) == "Lose 5 kg")

        let decoded = try JSONDecoder().decode(UserAccount.self, from: JSONEncoder().encode(account))
        #expect(decoded.goal == "Weight Goal")
        #expect(decoded.goalStart == 80)
        #expect(decoded.goalEnd == 75)
        #expect(decoded.goalProgress == 80)
        #expect(decoded.strengthGoalExercise == nil)
        #expect(GoalProgress.hasActiveGoal(decoded))

        GoalProgress.applyClear(decoded)
        let cleared = try JSONDecoder().decode(UserAccount.self, from: JSONEncoder().encode(decoded))
        #expect(cleared.goal == "")
        #expect(cleared.strengthGoalExercise == nil)
        #expect(cleared.goalStart == 0)
        #expect(cleared.goalEnd == 0)
        #expect(cleared.goalProgress == 0)
        #expect(!GoalProgress.hasActiveGoal(cleared))
        #expect(GoalProgress.displayedProgress(cleared) != 65)
    }

    @Test("A typed target accepts a comma or a dot")
    func testTargetParsing() {
        #expect(GoalProgress.parseTarget("77,5") == 77.5)
        #expect(GoalProgress.parseTarget("77.5") == 77.5)
        #expect(GoalProgress.parseTarget("80") == 80)
        #expect(GoalProgress.parseTarget(" 2.5 ") == 2.5)
        #expect(GoalProgress.parseTarget("") == nil)
        #expect(GoalProgress.parseTarget("nope") == nil)
    }

    @Test("Kilograms drop a trailing zero and keep one decimal")
    func testKilogramFormatting() {
        #expect(GoalProgress.formatKilograms(80) == "80")
        #expect(GoalProgress.formatKilograms(2.5) == "2.5")
        #expect(GoalProgress.formatKilograms(77.5) == "77.5")
        #expect(GoalProgress.formatKilograms(10) == "10")
    }
}
