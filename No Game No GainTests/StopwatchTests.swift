//
//  StopwatchTests.swift
//  No Game No GainTests
//
//  Created by Hubert Wojtowicz on 06/01/2025.
//

import Foundation
import Testing
@testable import No_Game_No_Gain

@MainActor
struct StopwatchTests {
    private final class DateClock {
        var date = Date()

        func advance(by interval: TimeInterval) {
            date = date.addingTimeInterval(interval)
        }
    }

    private func makeDefaults() -> UserDefaults {
        let name = "StopwatchTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    private func makeStopwatch(clock: DateClock? = nil) -> Stopwatch {
        let now = clock.map { clock in { clock.date } } ?? Date.init
        return Stopwatch(userDefaults: makeDefaults(), now: now)
    }

    @Test("Stopwatch should start from zero")
    func testInitialState() {
        let stopwatch = makeStopwatch()

        stopwatch.stopFormattedTime()
        stopwatch.stopFormattedTimeMS()
        stopwatch.resetFormattedTime()
        stopwatch.resetFormattedTimeMS()

        #expect(stopwatch.timeElapsedHMS == 0)
        #expect(stopwatch.timeElapsedMSMs == 0)
        #expect(stopwatch.isRunning == false)
        #expect(stopwatch.isRunningMSMs == false)
    }

    @Test("Stopwatch formatting should be correct")
    func testTimeFormatting() {
        let stopwatch = makeStopwatch()

        stopwatch.timeElapsedHMS = 3661 // 1 godzina, 1 minuta, 1 sekunda
        #expect(stopwatch.formattedTime == "01:01:01")

        stopwatch.timeElapsedMSMs = 61.23 // 1 minuta, 1 sekunda, 23 setne
        #expect(stopwatch.formattedTimeMS == "01:01,23")
    }

    @Test("Stopwatch should properly handle start/stop operations")
    func testStartStopOperations() {
        let stopwatch = makeStopwatch()

        stopwatch.stopFormattedTime()
        #expect(stopwatch.isRunning == false)

        stopwatch.startFormattedTime()
        #expect(stopwatch.isRunning == true)

        stopwatch.resetFormattedTime()
        #expect(stopwatch.timeElapsedHMS == 0)
        #expect(stopwatch.isRunning == false)
        stopwatch.reset()
    }

    @Test("Pause freezes both clocks and resume adds only the new segment")
    func testPauseDoesNotCountPausedTime() {
        let clock = DateClock()
        let stopwatch = makeStopwatch(clock: clock)
        defer { stopwatch.reset() }

        stopwatch.start()
        clock.advance(by: 10)
        #expect(abs(stopwatch.timeElapsedMSMs - 10) < 0.001)
        #expect(abs(stopwatch.workoutElapsed - 10) < 0.001)

        stopwatch.stop()
        #expect(stopwatch.isRunning == false)
        #expect(stopwatch.isRunningMSMs == false)
        #expect(abs(stopwatch.timeElapsedHMS - 10) < 0.001)
        #expect(abs(stopwatch.timeElapsedMSMs - 10) < 0.001)

        clock.advance(by: 25)
        #expect(abs(stopwatch.timeElapsedHMS - 10) < 0.001)
        #expect(abs(stopwatch.timeElapsedMSMs - 10) < 0.001)
        #expect(abs(stopwatch.workoutElapsed - 10) < 0.001)

        stopwatch.start()
        clock.advance(by: 4)
        stopwatch.handleHMSTick(generation: stopwatch.hmsGeneration)
        #expect(abs(stopwatch.timeElapsedHMS - 14) < 0.001)
        #expect(abs(stopwatch.timeElapsedMSMs - 14) < 0.001)
    }

    @Test("A queued workout tick cannot move a paused or reset clock")
    func testStaleWorkoutTickIsIgnored() {
        let clock = DateClock()
        let stopwatch = makeStopwatch(clock: clock)
        defer { stopwatch.reset() }

        stopwatch.startFormattedTime()
        let generation = stopwatch.hmsGeneration
        clock.advance(by: 8)
        stopwatch.stopFormattedTime()

        clock.advance(by: 30)
        stopwatch.handleHMSTick(generation: generation)
        #expect(abs(stopwatch.timeElapsedHMS - 8) < 0.001)

        stopwatch.startFormattedTime()
        let runningGeneration = stopwatch.hmsGeneration
        clock.advance(by: 3)
        stopwatch.resetFormattedTime()
        stopwatch.handleHMSTick(generation: runningGeneration)
        #expect(stopwatch.timeElapsedHMS == 0)
        #expect(stopwatch.isRunning == false)
    }

    @Test("Restoring a paused session stays paused")
    func testPausedSessionStaysPaused() {
        let clock = DateClock()
        let defaults = makeDefaults()
        let running = Stopwatch(userDefaults: defaults, now: { clock.date })
        running.start()
        clock.advance(by: 6)
        running.stop()

        let restored = Stopwatch(userDefaults: defaults, now: { clock.date })
        defer {
            running.reset()
            restored.reset()
        }

        #expect(restored.isRunning == false)
        #expect(restored.isRunningMSMs == false)
        #expect(abs(restored.timeElapsedHMS - 6) < 0.001)
        #expect(abs(restored.timeElapsedMSMs - 6) < 0.001)

        clock.advance(by: 20)
        restored.startIfNeeded()
        #expect(restored.isRunning == false)
        #expect(restored.isRunningMSMs == false)
        #expect(abs(restored.timeElapsedHMS - 6) < 0.001)
        #expect(abs(restored.timeElapsedMSMs - 6) < 0.001)
    }

    @Test("Restoring a running session keeps wall-clock time")
    func testRunningSessionRestoresElapsedTime() {
        let clock = DateClock()
        let defaults = makeDefaults()
        let running = Stopwatch(userDefaults: defaults, now: { clock.date })
        defer { running.reset() }
        running.start()
        clock.advance(by: 10)

        let restored = Stopwatch(userDefaults: defaults, now: { clock.date })
        defer { restored.reset() }

        #expect(restored.isRunning == true)
        #expect(restored.isRunningMSMs == true)
        #expect(abs(restored.timeElapsedHMS - 10) < 0.001)
        #expect(abs(restored.timeElapsedMSMs - 10) < 0.001)

        clock.advance(by: 5)
        #expect(abs(restored.timeElapsedMSMs - 15) < 0.001)
        restored.handleHMSTick(generation: restored.hmsGeneration)
        #expect(abs(restored.timeElapsedHMS - 15) < 0.001)
    }

    @Test("A fresh clock starts from the workout screen")
    func testFreshClockStarts() {
        let stopwatch = makeStopwatch()
        defer { stopwatch.reset() }

        stopwatch.startIfNeeded()
        #expect(stopwatch.isRunning == true)
        #expect(stopwatch.isRunningMSMs == true)
    }
}
