//
//  StopwatchView.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 11/10/2024.
//

import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class Stopwatch {
    var timeElapsedHMS: TimeInterval = 0

    var isRunning = false
    var isRunningMSMs = false

    @ObservationIgnored private var timerHMS: DispatchSourceTimer?
    /// Invalidates a workout-clock tick that was already queued when the clock paused or reset.
    @ObservationIgnored private(set) var hmsGeneration = 0

    @ObservationIgnored private var startDate: Date?
    @ObservationIgnored private var startDateMSMs: Date?

    @ObservationIgnored private var accumulatedTimeHMS: TimeInterval = 0
    @ObservationIgnored private var accumulatedTimeMSMs: TimeInterval = 0

    @ObservationIgnored private let userDefaults: UserDefaults
    @ObservationIgnored var currentDate: () -> Date

    @ObservationIgnored private let startDateKey = "stopwatchStartDateFormattedTime"
    @ObservationIgnored private let accumulatedTimeHMSKey = "stopwatchAccumulatedTimeFormattedTime"
    @ObservationIgnored private let accumulatedTimeMSMsKey = "stopwatchAccumulatedTimeFormattedTimeMS"
    @ObservationIgnored private let isRunningKey = "stopwatchIsRunningFormattedTime"
    @ObservationIgnored private let startDateFormattedTimeMSKey = "stopwatchStartDateFormattedTimeMS"
    @ObservationIgnored private let isRunningFormattedTimeMSKey = "stopwatchIsRunningFormattedTimeMS"

    var formattedTime: String {
        let hours = Int(timeElapsedHMS) / 3600
        let minutes = (Int(timeElapsedHMS) % 3600) / 60
        let seconds = Int(timeElapsedHMS) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    /// Live rest elapsed. Button actions read this; the rest label does not publish it.
    var timeElapsedMSMs: TimeInterval {
        get { restElapsed(at: currentDate()) }
        set { replaceRestElapsed(newValue) }
    }

    var formattedTimeMS: String {
        Self.formatRestTime(timeElapsedMSMs)
    }

    /// Live workout duration, including the partial second since the last 1 Hz tick.
    var workoutElapsed: TimeInterval {
        guard isRunning, let startDate else { return accumulatedTimeHMS }
        return accumulatedTimeHMS + max(0, currentDate().timeIntervalSince(startDate))
    }

    init(userDefaults: UserDefaults = .standard, now: @escaping () -> Date = Date.init) {
        self.userDefaults = userDefaults
        self.currentDate = now
        loadState()
        restoreFromSavedState()
    }

    func restElapsed(at date: Date) -> TimeInterval {
        guard isRunningMSMs, let startDateMSMs else { return accumulatedTimeMSMs }
        return accumulatedTimeMSMs + max(0, date.timeIntervalSince(startDateMSMs))
    }

    static func formatRestTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        let hundredths = Int((time * 100).truncatingRemainder(dividingBy: 100))
        if hours <= 0 {
            return String(format: "%02d:%02d,%02d", minutes, seconds, hundredths)
        } else {
            return String(format: "%02d:%02d:%02d,%02d", hours, minutes, seconds, hundredths)
        }
    }

    /// Starts both clocks only for a new workout. A paused session stays paused, including after the screen is created again.
    func startIfNeeded() {
        guard !isRunning, !isRunningMSMs else { return }
        guard userDefaults.object(forKey: accumulatedTimeHMSKey) == nil,
              userDefaults.object(forKey: accumulatedTimeMSMsKey) == nil else { return }
        start()
    }

    // Metody dla licznika formattedTime (HH:mm:ss)
    func startFormattedTime() {
        guard !isRunning else { return }
        isRunning = true
        startDate = currentDate()
        timeElapsedHMS = accumulatedTimeHMS
        saveState()
        armHMSTimer()
    }

    func stopFormattedTime() {
        guard isRunning else { return }
        hmsGeneration &+= 1
        timerHMS?.cancel()
        timerHMS = nil

        if let startDate {
            accumulatedTimeHMS += max(0, currentDate().timeIntervalSince(startDate))
        }
        self.startDate = nil
        timeElapsedHMS = accumulatedTimeHMS
        isRunning = false
        saveState()
    }

    func resetFormattedTime() {
        hmsGeneration &+= 1
        timerHMS?.cancel()
        timerHMS = nil
        isRunning = false
        timeElapsedHMS = 0
        accumulatedTimeHMS = 0
        startDate = nil

        userDefaults.removeObject(forKey: startDateKey)
        userDefaults.removeObject(forKey: accumulatedTimeHMSKey)
        userDefaults.set(false, forKey: isRunningKey)
    }

    func handleHMSTick(generation: Int) {
        guard generation == hmsGeneration, isRunning, let startDate else { return }
        timeElapsedHMS = accumulatedTimeHMS + max(0, currentDate().timeIntervalSince(startDate))
    }

    // Metody dla licznika formattedTimeMS (mm:ss,xx)
    func startFormattedTimeMS() {
        guard !isRunningMSMs else { return }
        isRunningMSMs = true
        startDateMSMs = currentDate()
        saveState()
    }

    func stopFormattedTimeMS() {
        guard isRunningMSMs else { return }
        if let startDateMSMs {
            accumulatedTimeMSMs += max(0, currentDate().timeIntervalSince(startDateMSMs))
        }
        self.startDateMSMs = nil
        isRunningMSMs = false
        saveState()
    }

    func resetFormattedTimeMS() {
        isRunningMSMs = false
        accumulatedTimeMSMs = 0
        startDateMSMs = nil

        userDefaults.removeObject(forKey: startDateFormattedTimeMSKey)
        userDefaults.removeObject(forKey: accumulatedTimeMSMsKey)
        userDefaults.set(false, forKey: isRunningFormattedTimeMSKey)
    }

    func saveState() {
        if let startDate {
            userDefaults.set(startDate, forKey: startDateKey)
        } else {
            userDefaults.removeObject(forKey: startDateKey)
        }
        if let startDateMSMs {
            userDefaults.set(startDateMSMs, forKey: startDateFormattedTimeMSKey)
        } else {
            userDefaults.removeObject(forKey: startDateFormattedTimeMSKey)
        }
        userDefaults.set(accumulatedTimeHMS, forKey: accumulatedTimeHMSKey)
        userDefaults.set(accumulatedTimeMSMs, forKey: accumulatedTimeMSMsKey)
        userDefaults.set(isRunning, forKey: isRunningKey)
        userDefaults.set(isRunningMSMs, forKey: isRunningFormattedTimeMSKey)
    }

    func reset() {
        resetFormattedTime()
        resetFormattedTimeMS()
    }

    func resetMSMs() {
        resetFormattedTimeMS()
    }

    func start() {
        startFormattedTime()
        startFormattedTimeMS()
    }

    func stop() {
        stopFormattedTime()
        stopFormattedTimeMS()
    }

    private func armHMSTimer() {
        hmsGeneration &+= 1
        let generation = hmsGeneration
        timerHMS?.cancel()
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now(), repeating: 1.0)
        timer.setEventHandler { [weak self] in
            MainActor.assumeIsolated {
                self?.handleHMSTick(generation: generation)
            }
        }
        timer.resume()
        timerHMS = timer
    }

    private func restoreFromSavedState() {
        if isRunning, let startDate {
            timeElapsedHMS = accumulatedTimeHMS + max(0, currentDate().timeIntervalSince(startDate))
            armHMSTimer()
        } else {
            isRunning = false
            self.startDate = nil
            timeElapsedHMS = accumulatedTimeHMS
        }

        if !(isRunningMSMs && startDateMSMs != nil) {
            isRunningMSMs = false
            startDateMSMs = nil
        }
    }

    private func loadState() {
        accumulatedTimeHMS = userDefaults.double(forKey: accumulatedTimeHMSKey)
        accumulatedTimeMSMs = userDefaults.double(forKey: accumulatedTimeMSMsKey)
        isRunning = userDefaults.bool(forKey: isRunningKey)
        isRunningMSMs = userDefaults.bool(forKey: isRunningFormattedTimeMSKey)

        if let savedStartDate = userDefaults.object(forKey: startDateKey) as? Date {
            startDate = savedStartDate
        }
        if let savedStartDateMS = userDefaults.object(forKey: startDateFormattedTimeMSKey) as? Date {
            startDateMSMs = savedStartDateMS
        }
    }

    private func replaceRestElapsed(_ value: TimeInterval) {
        guard !isRunningMSMs else { return }
        accumulatedTimeMSMs = value
        startDateMSMs = nil
    }
}
