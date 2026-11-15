//
//  WorkoutWatchLinkTests.swift
//  No Game No GainTests
//

import Foundation
import Testing
@testable import No_Game_No_Gain

struct WorkoutWatchLinkTests {
    @Test("A metrics payload is shown only for the current workout")
    func testMetricsRequireCurrentWorkoutID() {
        let current = UUID().uuidString
        let live = WatchLinkMetrics.liveMetrics(
            from: [
                "kind": "metrics",
                "id": current,
                "hr": 90,
                "hrAvg": 80,
                "hrMax": 100,
                "kcal": 12
            ],
            workoutID: current
        )
        #expect(live?.heartRateBPM == 90)
        #expect(live?.averageHeartRateBPM == 80)
        #expect(live?.maximumHeartRateBPM == 100)
        #expect(live?.activeEnergyKilocalories == 12)

        let previous = WatchLinkMetrics.liveMetrics(
            from: [
                "kind": "metrics",
                "hr": 167,
                "hrAvg": 129,
                "hrMax": 173,
                "kcal": 360
            ],
            workoutID: current
        )
        #expect(previous == nil)

        let otherWorkout = WatchLinkMetrics.liveMetrics(
            from: [
                "kind": "metrics",
                "id": UUID().uuidString,
                "hr": NSNumber(value: 167),
                "hrAvg": NSNumber(value: 129),
                "hrMax": NSNumber(value: 173),
                "kcal": NSNumber(value: 360)
            ],
            workoutID: current
        )
        #expect(otherWorkout == nil)

        let clock = WatchLinkMetrics.liveMetrics(
            from: ["kind": "clock", "id": current, "hr": 90],
            workoutID: current
        )
        #expect(clock == nil)
    }
}
