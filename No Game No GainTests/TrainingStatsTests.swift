//
//  TrainingStatsTests.swift
//  No Game No GainTests
//

import Foundation
import Testing
@testable import No_Game_No_Gain

struct TrainingStatsTests {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func daysAgo(_ days: Int) -> Date {
        calendar.date(byAdding: .day, value: -days, to: now)!
    }

    private func session(
        name: String = "Push",
        endTime: Date?,
        duration: TimeInterval = 1_800,
        effort: Int? = nil,
        sets: [TrainingStatsMath.SetInput]
    ) -> TrainingStatsMath.SessionInput {
        TrainingStatsMath.SessionInput(
            workoutName: name,
            endTime: endTime,
            duration: duration,
            effort: effort,
            sets: sets
        )
    }

    @Test("No ended sessions means no chart points and no records")
    func testEmptyHistory() {
        let bench = TrainingStatsMath.ExerciseBest(
            name: "Bench",
            personalBestWeight: 100,
            personalBestReps: 5
        )
        let open = session(
            endTime: nil,
            effort: 9,
            sets: [TrainingStatsMath.SetInput(weight: 100, reps: 5)]
        )

        #expect(TrainingStatsMath.chartPoints(sessions: [], range: .week, now: now, calendar: calendar).isEmpty)
        #expect(TrainingStatsMath.chartPoints(sessions: [open], range: .year, now: now, calendar: calendar).isEmpty)
        #expect(TrainingStatsMath.records(sessions: [], exercises: [bench]).isEmpty)
        #expect(TrainingStatsMath.records(sessions: [open], exercises: [bench]).isEmpty)
        #expect(TrainingStatsMath.volume(sessions: [open], range: .month, now: now, calendar: calendar) == 0)
    }

    @Test("Ending a session adds a chart point and reveals the exercise best")
    func testEndedSessionRevealsRecord() {
        let bench = TrainingStatsMath.ExerciseBest(
            name: "Bench",
            personalBestWeight: 100,
            personalBestReps: 8
        )
        let row = TrainingStatsMath.ExerciseBest(
            name: "Row",
            personalBestWeight: 60,
            personalBestReps: nil
        )
        let curl = TrainingStatsMath.ExerciseBest(
            name: "Curl",
            personalBestWeight: nil,
            personalBestReps: nil
        )
        let exercises = [bench, row, curl]
        let ended = session(
            endTime: daysAgo(1),
            sets: [TrainingStatsMath.SetInput(weight: 100, reps: 5)]
        )

        #expect(TrainingStatsMath.records(sessions: [], exercises: exercises).isEmpty)

        let records = TrainingStatsMath.records(sessions: [ended], exercises: exercises)
        #expect(records.map(\.exerciseName) == ["Bench", "Row"])
        #expect(records[0].weight == 100)
        #expect(records[0].reps == 8)
        #expect(records[1].weight == 60)
        #expect(records[1].reps == nil)

        let points = TrainingStatsMath.chartPoints(
            sessions: [ended],
            range: .week,
            now: now,
            calendar: calendar
        )
        #expect(points.count == 1)
        #expect(points[0].date == daysAgo(1))
        #expect(points[0].volume == 500)
        #expect(points[0].setCount == 1)
        #expect(points[0].repCount == 5)
    }

    @Test("Volume is weight times reps, with set and rep counts")
    func testVolumeSetsAndReps() {
        let ended = session(
            endTime: now,
            duration: 1_800,
            sets: [
                TrainingStatsMath.SetInput(weight: 100, reps: 5),
                TrainingStatsMath.SetInput(weight: 40, reps: 10)
            ]
        )
        let points = TrainingStatsMath.chartPoints(
            sessions: [ended],
            range: .week,
            now: now,
            calendar: calendar
        )

        #expect(points.count == 1)
        #expect(points[0].volume == 900)
        #expect(points[0].setCount == 2)
        #expect(points[0].repCount == 15)
        #expect(points[0].duration == 1_800)
        #expect(TrainingStatsMath.volume(sessions: [ended], range: .month, now: now, calendar: calendar) == 900)
        #expect(TrainingStatsMath.Metric.duration.plottedValue(of: points[0]) == 30)
        #expect(TrainingStatsMath.Metric.volume.unit == "kg")
        #expect(TrainingStatsMath.Metric.sets.unit == "sets")
        #expect(TrainingStatsMath.Metric.reps.unit == "reps")
        #expect(TrainingStatsMath.Metric.duration.unit == "minutes")
        #expect(points[0].volume != 140)
    }

    @Test("Week, month, and year drop sessions outside that range")
    func testRanges() {
        let recent = session(name: "Recent", endTime: daysAgo(1), sets: [.init(weight: 10, reps: 1)])
        let eightDays = session(name: "Eight", endTime: daysAgo(8), sets: [.init(weight: 10, reps: 1)])
        let fortyDays = session(name: "Forty", endTime: daysAgo(40), sets: [.init(weight: 10, reps: 1)])
        let fourHundred = session(name: "Old", endTime: daysAgo(400), sets: [.init(weight: 10, reps: 1)])
        let future = session(
            name: "Future",
            endTime: calendar.date(byAdding: .day, value: 1, to: now),
            sets: [.init(weight: 10, reps: 1)]
        )
        let sessions = [fourHundred, fortyDays, eightDays, recent, future]

        let week = TrainingStatsMath.chartPoints(sessions: sessions, range: .week, now: now, calendar: calendar)
        #expect(week.map(\.date) == [daysAgo(1)])

        let month = TrainingStatsMath.chartPoints(sessions: sessions, range: .month, now: now, calendar: calendar)
        #expect(month.map(\.date) == [daysAgo(8), daysAgo(1)])

        let year = TrainingStatsMath.chartPoints(sessions: sessions, range: .year, now: now, calendar: calendar)
        #expect(year.map(\.date) == [daysAgo(40), daysAgo(8), daysAgo(1)])

        let edge = session(
            name: "Edge",
            endTime: calendar.date(byAdding: .day, value: -7, to: now),
            sets: [.init(weight: 1, reps: 1)]
        )
        #expect(
            TrainingStatsMath.chartPoints(sessions: [edge], range: .week, now: now, calendar: calendar).count == 1
        )
    }

    @Test("An open session is excluded from points, volume, and effort")
    func testOpenSessionExcluded() {
        let open = session(
            name: "Open",
            endTime: nil,
            effort: 9,
            sets: [TrainingStatsMath.SetInput(weight: 100, reps: 10)]
        )
        let ended = session(
            name: "Done",
            endTime: daysAgo(1),
            effort: 7,
            sets: [TrainingStatsMath.SetInput(weight: 20, reps: 2)]
        )

        let points = TrainingStatsMath.chartPoints(
            sessions: [open, ended],
            range: .week,
            now: now,
            calendar: calendar
        )
        #expect(points.count == 1)
        #expect(points[0].volume == 40)
        #expect(TrainingStatsMath.volume(sessions: [open, ended], range: .month, now: now, calendar: calendar) == 40)
        #expect(TrainingStatsMath.endedCount(sessions: [open, ended], range: .week, now: now, calendar: calendar) == 1)

        let effort = TrainingStatsMath.effortRows(
            sessions: [open, ended],
            range: .week,
            now: now,
            calendar: calendar
        )
        #expect(effort.map(\.effort) == [7])
        #expect(effort.map(\.workoutName) == ["Done"])
    }

    @Test("Effort 7 is listed and a missing effort is not")
    func testEffort() {
        let rated = session(
            name: "Push",
            endTime: daysAgo(1),
            effort: 7,
            sets: [TrainingStatsMath.SetInput(weight: 10, reps: 1)]
        )
        let unrated = session(
            name: "Pull",
            endTime: daysAgo(1),
            effort: nil,
            sets: [TrainingStatsMath.SetInput(weight: 10, reps: 1)]
        )
        let outsideWeek = session(
            name: "Old",
            endTime: daysAgo(40),
            effort: 4,
            sets: [TrainingStatsMath.SetInput(weight: 10, reps: 1)]
        )

        let week = TrainingStatsMath.effortRows(
            sessions: [rated, unrated, outsideWeek],
            range: .week,
            now: now,
            calendar: calendar
        )
        #expect(week.count == 1)
        #expect(week[0].workoutName == "Push")
        #expect(week[0].effort == 7)

        let year = TrainingStatsMath.effortRows(
            sessions: [rated, unrated, outsideWeek],
            range: .year,
            now: now,
            calendar: calendar
        )
        #expect(year.map(\.workoutName) == ["Old", "Push"])
        #expect(year.map(\.effort) == [4, 7])
    }
}
