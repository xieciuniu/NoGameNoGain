//
//  HistoryFilter.swift
//  No Game No Gain
//

import Foundation

enum HistoryRange: CaseIterable, Hashable, Identifiable {
    case week
    case month
    case year
    case all

    var id: Self { self }

    var title: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .year: return "Year"
        case .all: return "All"
        }
    }
}

struct HistorySession: Equatable {
    var workoutName: String
    var endTime: Date?
}

enum HistoryFilter {
    /// Ended sessions only. A nil or empty name keeps every name. Week, month, and year use the stats bounds.
    static func filtered(
        sessions: [HistorySession],
        name: String?,
        range: HistoryRange,
        now: Date,
        calendar: Calendar
    ) -> [HistorySession] {
        sessions.filter { session in
            guard session.endTime != nil else { return false }
            if let name, !name.isEmpty, session.workoutName != name {
                return false
            }
            guard let statsRange = statsRange(for: range) else { return true }
            return TrainingStatsMath.contains(
                session.endTime,
                range: statsRange,
                now: now,
                calendar: calendar
            )
        }
    }

    private static func statsRange(for range: HistoryRange) -> TrainingStatsMath.Range? {
        switch range {
        case .week: return .week
        case .month: return .month
        case .year: return .year
        case .all: return nil
        }
    }
}
