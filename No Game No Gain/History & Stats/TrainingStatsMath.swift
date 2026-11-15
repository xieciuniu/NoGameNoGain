//
//  TrainingStatsMath.swift
//  No Game No Gain
//

import Foundation

/// Finished-session stats. Volume is weight times reps, not a sum of loads.
enum TrainingStatsMath {
    enum Range: String, CaseIterable, Identifiable {
        case week
        case month
        case year

        var id: Self { self }

        var title: String {
            switch self {
            case .week: return "Week"
            case .month: return "Month"
            case .year: return "Year"
            }
        }
    }

    enum Metric: String, CaseIterable, Identifiable {
        case volume = "Volume"
        case sets = "Sets"
        case reps = "Reps"
        case duration = "Duration"

        var id: Self { self }

        var title: String { rawValue }

        var unit: String {
            switch self {
            case .volume: return "kg"
            case .sets: return "sets"
            case .reps: return "reps"
            case .duration: return "minutes"
            }
        }

        /// Duration stays in seconds on the point. The chart draws minutes.
        func plottedValue(of point: ChartPoint) -> Double {
            switch self {
            case .volume:
                return point.volume
            case .sets:
                return Double(point.setCount)
            case .reps:
                return Double(point.repCount)
            case .duration:
                return point.duration / 60
            }
        }
    }

    struct SetInput: Equatable {
        var weight: Double
        var reps: Int
    }

    struct SessionInput: Equatable {
        var workoutName: String
        var endTime: Date?
        var duration: TimeInterval
        var effort: Int?
        var sets: [SetInput]
    }

    struct ExerciseBest: Equatable {
        var name: String
        var personalBestWeight: Double?
        var personalBestReps: Int?
    }

    struct ChartPoint: Equatable, Identifiable {
        var id: Int
        var date: Date
        var volume: Double
        var setCount: Int
        var repCount: Int
        var duration: TimeInterval
    }

    struct Record: Equatable, Identifiable {
        var id: Int
        var exerciseName: String
        var weight: Double?
        var reps: Int?
    }

    struct EffortRow: Equatable, Identifiable {
        var id: Int
        var workoutName: String
        var effort: Int
    }

    /// Sum of weight times reps.
    static func volume(sets: [SetInput]) -> Double {
        sets.reduce(0) { $0 + $1.weight * Double($1.reps) }
    }

    static func volume(
        sessions: [SessionInput],
        range: Range,
        now: Date,
        calendar: Calendar
    ) -> Double {
        endedSessions(sessions, range: range, now: now, calendar: calendar)
            .reduce(0) { $0 + volume(sets: $1.sets) }
    }

    static func endedCount(
        sessions: [SessionInput],
        range: Range,
        now: Date,
        calendar: Calendar
    ) -> Int {
        endedSessions(sessions, range: range, now: now, calendar: calendar).count
    }

    static func chartPoints(
        sessions: [SessionInput],
        range: Range,
        now: Date,
        calendar: Calendar
    ) -> [ChartPoint] {
        var points: [ChartPoint] = []
        for session in endedSessions(sessions, range: range, now: now, calendar: calendar) {
            guard let date = session.endTime else { continue }
            let reps = session.sets.reduce(0) { $0 + $1.reps }
            points.append(
                ChartPoint(
                    id: points.count,
                    date: date,
                    volume: volume(sets: session.sets),
                    setCount: session.sets.count,
                    repCount: reps,
                    duration: session.duration
                )
            )
        }
        return points
    }

    /// Empty until some session has ended. Then each exercise that has a best weight or best reps.
    static func records(sessions: [SessionInput], exercises: [ExerciseBest]) -> [Record] {
        guard sessions.contains(where: { $0.endTime != nil }) else { return [] }
        var records: [Record] = []
        for exercise in exercises {
            let hasWeight = exercise.personalBestWeight != nil
            let hasReps = exercise.personalBestReps != nil
            guard hasWeight || hasReps else { continue }
            records.append(
                Record(
                    id: records.count,
                    exerciseName: exercise.name,
                    weight: exercise.personalBestWeight,
                    reps: exercise.personalBestReps
                )
            )
        }
        return records
    }

    static func effortRows(
        sessions: [SessionInput],
        range: Range,
        now: Date,
        calendar: Calendar
    ) -> [EffortRow] {
        var rows: [EffortRow] = []
        for session in endedSessions(sessions, range: range, now: now, calendar: calendar) {
            guard let effort = session.effort else { continue }
            rows.append(
                EffortRow(id: rows.count, workoutName: session.workoutName, effort: effort)
            )
        }
        return rows
    }

    /// Ended on or after the range start, and not after `now`. An open session is never inside.
    static func contains(_ endTime: Date?, range: Range, now: Date, calendar: Calendar) -> Bool {
        guard let endTime, let start = lowerBound(range: range, now: now, calendar: calendar) else {
            return false
        }
        return endTime >= start && endTime <= now
    }

    private static func endedSessions(
        _ sessions: [SessionInput],
        range: Range,
        now: Date,
        calendar: Calendar
    ) -> [SessionInput] {
        sessions
            .filter { contains($0.endTime, range: range, now: now, calendar: calendar) }
            .sorted { lhs, rhs in
                (lhs.endTime ?? .distantPast) < (rhs.endTime ?? .distantPast)
            }
    }

    private static func lowerBound(range: Range, now: Date, calendar: Calendar) -> Date? {
        switch range {
        case .week:
            return calendar.date(byAdding: .day, value: -7, to: now)
        case .month:
            return calendar.date(byAdding: .month, value: -1, to: now)
        case .year:
            return calendar.date(byAdding: .year, value: -1, to: now)
        }
    }
}
