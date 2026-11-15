//
//  ActivityGoalTests.swift
//  No Game No GainTests
//

import Foundation
import Testing
@testable import No_Game_No_Gain

struct ActivityGoalTests {
    @Test("Sleep minutes read as a clock, and a fraction truncates toward zero")
    func testClock() {
        #expect(ActivityGoals.clock(minutes: 425) == "7:05")
        #expect(ActivityGoals.clock(minutes: 9) == "0:09")
        #expect(ActivityGoals.clock(minutes: 60) == "1:00")
        #expect(ActivityGoals.clock(minutes: 425.9) == "7:05")
        #expect(ActivityGoals.clock(minutes: 0) == "0:00")
    }

    @Test("A fresh account shows the step goal only")
    func testFreshAccountGoals() {
        let account = UserAccount()
        #expect(account.stepGoal == 18000)
        #expect(account.calorieGoal == nil)
        #expect(account.sleepGoalMinutes == nil)
        #expect(ActivityGoals.showsGoalLine(.steps, account: account))
        #expect(ActivityGoals.goalLabel(.steps, account: account) == "Goal: 18000")
        #expect(!ActivityGoals.showsGoalLine(.calories, account: account))
        #expect(ActivityGoals.goalLabel(.calories, account: account) == nil)
        #expect(!ActivityGoals.showsGoalLine(.sleep, account: account))
        #expect(ActivityGoals.goalLabel(.sleep, account: account) == nil)
    }

    @Test("Progress is current over goal, and a missing goal has none")
    func testProgressFraction() {
        #expect(ActivityGoals.progressFraction(current: 9000, goal: 18000) == 0.5)
        #expect(ActivityGoals.progressFraction(current: 100, goal: nil) == nil)
        #expect(ActivityGoals.progressFraction(current: 100, goal: 0) == nil)
        #expect(ActivityGoals.progressFraction(current: 20000, goal: 18000) == 1)
        #expect(ActivityGoals.progressFraction(current: -5, goal: 18000) == 0)
    }

    @Test("A saved calorie and sleep goal keep the name and experience")
    func testEncodeKeepsGoalsAndIdentity() throws {
        let account = UserAccount()
        account.name = "Ada"
        account.exp = 1200
        account.calorieGoal = 400
        account.sleepGoalMinutes = 425

        let decoded = try JSONDecoder().decode(UserAccount.self, from: JSONEncoder().encode(account))
        #expect(decoded.name == "Ada")
        #expect(decoded.exp == 1200)
        #expect(decoded.calorieGoal == 400)
        #expect(decoded.sleepGoalMinutes == 425)
        #expect(decoded.stepGoal == 18000)
        #expect(ActivityGoals.goalLabel(.sleep, account: decoded) == "Goal: 7:05")
        #expect(ActivityGoals.showsGoalLine(.calories, account: decoded))
        #expect(ActivityGoals.showsGoalLine(.sleep, account: decoded))
    }

    @Test("An account file from before activity goals still decodes")
    func testOldAccountJSON() throws {
        let json = #"{"name":"Ada","exp":42,"goal":"Weight Goal","goalProgress":3}"#
        let decoded = try JSONDecoder().decode(UserAccount.self, from: Data(json.utf8))
        #expect(decoded.name == "Ada")
        #expect(decoded.exp == 42)
        #expect(decoded.goal == "Weight Goal")
        #expect(decoded.goalProgress == 3)
        #expect(decoded.stepGoal == 18000)
        #expect(decoded.calorieGoal == nil)
        #expect(decoded.sleepGoalMinutes == nil)
        #expect(decoded.notes == "")
        #expect(decoded.expMultiplier == 1)
        #expect(decoded.weeklyWorkouts == [:])
    }

    @Test("Sleep goals accept hours and minutes or a clock")
    func testSleepEntry() {
        #expect(ActivityGoals.sleepEdit(hoursText: "7", minutesText: "05") == .value(425))
        #expect(ActivityGoals.sleepEdit(hoursText: "7:05", minutesText: "") == .value(425))
        #expect(ActivityGoals.sleepEdit(hoursText: "7:5", minutesText: "") == .value(425))
        #expect(ActivityGoals.sleepEdit(hoursText: "", minutesText: "") == .clear)
        #expect(ActivityGoals.minutes(fromClock: "0:09") == 9)
    }
}
