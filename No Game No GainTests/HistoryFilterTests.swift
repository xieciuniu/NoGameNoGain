//
//  HistoryFilterTests.swift
//  No Game No GainTests
//

import Foundation
import Testing
@testable import No_Game_No_Gain

struct HistoryFilterTests {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func daysAgo(_ days: Int) -> Date {
        calendar.date(byAdding: .day, value: -days, to: now)!
    }

    private func session(name: String, endTime: Date?) -> HistorySession {
        HistorySession(workoutName: name, endTime: endTime)
    }

    @Test("An open session is excluded even when the range is all and the name matches")
    func testOpenSessionExcluded() {
        let open = session(name: "Push", endTime: nil)
        let ended = session(name: "Push", endTime: daysAgo(1))

        let result = HistoryFilter.filtered(
            sessions: [open, ended],
            name: "Push",
            range: .all,
            now: now,
            calendar: calendar
        )

        #expect(result == [ended])
    }

    @Test("A workout name hides other workouts, and clearing it shows every ended session")
    func testNameFilter() {
        let push = session(name: "Push", endTime: daysAgo(1))
        let pull = session(name: "Pull", endTime: daysAgo(2))
        let open = session(name: "Push", endTime: nil)
        let sessions = [push, pull, open]

        let named = HistoryFilter.filtered(
            sessions: sessions,
            name: "Push",
            range: .all,
            now: now,
            calendar: calendar
        )
        #expect(named == [push])

        let cleared = HistoryFilter.filtered(
            sessions: sessions,
            name: nil,
            range: .all,
            now: now,
            calendar: calendar
        )
        #expect(cleared == [push, pull])
    }

    @Test("Week hides a session that ended 8 days ago and keeps one from 1 day ago")
    func testWeek() {
        let recent = session(name: "Push", endTime: daysAgo(1))
        let eightDays = session(name: "Push", endTime: daysAgo(8))

        let result = HistoryFilter.filtered(
            sessions: [eightDays, recent],
            name: nil,
            range: .week,
            now: now,
            calendar: calendar
        )

        #expect(result == [recent])
    }

    @Test("All keeps a session from 8 days ago and a session from 400 days ago")
    func testAllKeepsOldSessions() {
        let eightDays = session(name: "Push", endTime: daysAgo(8))
        let fourHundred = session(name: "Pull", endTime: daysAgo(400))

        let result = HistoryFilter.filtered(
            sessions: [fourHundred, eightDays],
            name: nil,
            range: .all,
            now: now,
            calendar: calendar
        )

        #expect(result == [fourHundred, eightDays])
    }

    @Test("Month hides a session that ended 40 days ago")
    func testMonth() {
        let recent = session(name: "Push", endTime: daysAgo(1))
        let fortyDays = session(name: "Push", endTime: daysAgo(40))

        let result = HistoryFilter.filtered(
            sessions: [fortyDays, recent],
            name: nil,
            range: .month,
            now: now,
            calendar: calendar
        )

        #expect(result == [recent])
    }

    @Test("Year uses the stats year bound")
    func testYear() {
        let fortyDays = session(name: "Push", endTime: daysAgo(40))
        let fourHundred = session(name: "Push", endTime: daysAgo(400))

        let result = HistoryFilter.filtered(
            sessions: [fourHundred, fortyDays],
            name: nil,
            range: .year,
            now: now,
            calendar: calendar
        )

        #expect(result == [fortyDays])
    }

    @Test("Name and week hide an old Push, and clearing the range shows that Push but not Pull")
    func testNameAndRange() {
        let oldPush = session(name: "Push", endTime: daysAgo(8))
        let pull = session(name: "Pull", endTime: daysAgo(1))
        let sessions = [oldPush, pull]

        let week = HistoryFilter.filtered(
            sessions: sessions,
            name: "Push",
            range: .week,
            now: now,
            calendar: calendar
        )
        #expect(week.isEmpty)

        let all = HistoryFilter.filtered(
            sessions: sessions,
            name: "Push",
            range: .all,
            now: now,
            calendar: calendar
        )
        #expect(all == [oldPush])
    }

    @Test("Week, month, and year agree with training stats")
    func testRangesAgreeWithStats() {
        let ends = [1, 7, 8, 31, 32, 40, 400].map { daysAgo($0) }
        let ranges: [(HistoryRange, TrainingStatsMath.Range)] = [
            (.week, .week),
            (.month, .month),
            (.year, .year)
        ]

        for end in ends {
            let row = [session(name: "Push", endTime: end)]
            for (historyRange, statsRange) in ranges {
                let kept = HistoryFilter.filtered(
                    sessions: row,
                    name: nil,
                    range: historyRange,
                    now: now,
                    calendar: calendar
                )
                let statsKeeps = TrainingStatsMath.contains(
                    end,
                    range: statsRange,
                    now: now,
                    calendar: calendar
                )
                #expect(kept.isEmpty != statsKeeps)
            }
        }
    }
}
