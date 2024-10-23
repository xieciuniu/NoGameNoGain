//
//  StopwatchView.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 11/10/2024.
//

import SwiftUI

//struct StopwatchView: View {
//    @StateObject private var stopwatch = Stopwatch()
//    
//    var body: some View {
//        VStack(spacing: 20) {
//            Text(stopwatch.formattedTime)
//                .font(.system(size: 72, weight: .thin, design: .monospaced))
//                .padding()
//            
//            HStack(spacing: 20) {
//                Button(action: {
//                    stopwatch.reset()
//                }) {
//                    Text("Reset")
//                        .font(.title2)
//                        .foregroundColor(.red)
//                        .frame(width: 120, height: 60)
//                        .background(Color.gray.opacity(0.2))
//                        .cornerRadius(15)
//                }
//                
//                Button(action: {
//                    stopwatch.isRunning ? stopwatch.stop() : stopwatch.start()
//                }) {
//                    Text(stopwatch.isRunning ? "Stop" : "Start")
//                        .font(.title2)
//                        .foregroundColor(.green)
//                        .frame(width: 120, height: 60)
//                        .background(Color.gray.opacity(0.2))
//                        .cornerRadius(15)
//                }
//            }
//        }
//        .padding()
//    }
//}

//class Stopwatch: ObservableObject {
//    // Czas dla formatu HH:mm:ss
//    @Published var timeElapsedHMS: TimeInterval = 0
//    // Czas dla formatu mm:ss,ms
//    @Published var timeElapsedMSMs: TimeInterval = 0
//    
//    @Published var isRunning = true
//    
//    private var timerHMS: Timer?
//    private var timerMSMs: Timer?
//    
//    private var startDate: Date?
//    
//    private var accumulatedTimeHMS: TimeInterval = 0
//    private var accumulatedTimeMSMs: TimeInterval = 0
//    
//    private let userDefaults = UserDefaults.standard
//    private let startDateKey = "stopwatchStartDateFormattedTime"
//    private let accumulatedTimeHMSKey = "stopwatchAccumulatedTimeFormattedTime"
//    private let accumulatedTimeMSMsKey = "stopwatchAccumulatedTimeFormattedTimeMS"
//    private let isRunningKey = "stopwatchIsRunningFormattedTime"
//    
//    @Published var isRunningMSMs = true
//    private var startDateMSMs: Date?
//    private let startDateFormattedTimeMSKey = "stopwatchStartDateFormattedTimeMS"
//    private let isRunningFormattedTimeMSKey = "stopwatchIsRunningFormattedTimeMS"
//
//    
//    var formattedTime: String {
//        let hours = Int(timeElapsedHMS) / 3600
//        let minutes = (Int(timeElapsedHMS) % 3600) / 60
//        let seconds = Int(timeElapsedHMS) % 60
//        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
//    }
//    
//    var formattedTimeMS: String {
//        let hours = Int(timeElapsedMSMs) / 3600
//        let minutes = (Int(timeElapsedMSMs) % 3600) / 60
//        let seconds = Int(timeElapsedMSMs) % 60
//        let miliseconds = Int((timeElapsedMSMs * 100).truncatingRemainder(dividingBy: 100))
//        if hours <= 0 {
//            return String(format: "%02d:%02d,%02d", minutes, seconds, miliseconds)
//        } else {
//            return String(format: "%02d:%02d:%02d,%02d", hours, minutes, seconds, miliseconds)
//        }
//    }
//    
//    init() {
//        loadState()  // Wczytanie stanu przy inicjalizacji
//        
//        // Uruchomienie licznika dla formattedTime, jeśli był włączony
//        if isRunning, let startDate = self.startDate {
//            self.timeElapsedHMS = accumulatedTimeHMS + Date().timeIntervalSince(startDate)
//            stopFormattedTime()
//            startFormattedTime()
//        } else {
//            self.timeElapsedHMS = accumulatedTimeHMS
//            self.isRunning = false
//            stopFormattedTime()
//            startFormattedTime()
//        }
//        
//        // Uruchomienie licznika dla formattedTimeMS, jeśli był włączony
//        if isRunningMSMs, let startDate = self.startDateMSMs {
//            self.timeElapsedMSMs = accumulatedTimeMSMs + Date().timeIntervalSince(startDate)
//            stopFormattedTimeMS()
//            startFormattedTimeMS()
//        } else {
//            self.timeElapsedMSMs = accumulatedTimeMSMs
//            self.isRunningMSMs = false
//            stopFormattedTimeMS()
//            startFormattedTimeMS()
//        }
//    }
//    
//    // Metody dla licznika formattedTime (HH:mm:ss)
//    func startFormattedTime() {
//        guard !isRunning else { return }
//        isRunning = true
//        startDate = Date()
//        saveState()
//        
//        timerHMS = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
//            if let startDate = self.startDate {
//                self.timeElapsedHMS = self.accumulatedTimeHMS + Date().timeIntervalSince(startDate)
//            }
//        }
//    }
//    
//    func stopFormattedTime() {
//        guard isRunning else { return }
//        timerHMS?.invalidate()
//        isRunning = false
//        
//        if let startDate = startDate {
//            accumulatedTimeHMS += Date().timeIntervalSince(startDate)
//        }
//        saveState()
//    }
//    
//    func resetFormattedTime() {
//        timerHMS?.invalidate()
//        timeElapsedHMS = 0
//        accumulatedTimeHMS = 0
//        startDate = nil
//        
//        userDefaults.removeObject(forKey: startDateKey)
//        userDefaults.removeObject(forKey: accumulatedTimeHMSKey)
//        userDefaults.set(false, forKey: isRunningKey)
//    }
//    
//    // Metody dla licznika formattedTimeMS (mm:ss,ms)
//    func startFormattedTimeMS() {
//        guard !isRunningMSMs else { return }
//        isRunningMSMs = true
//        startDateMSMs = Date()
//        saveState()
//        
//        timerMSMs = Timer.scheduledTimer(withTimeInterval: 0.09, repeats: true) { _ in
//            if let startDate = self.startDateMSMs {
//                self.timeElapsedMSMs = self.accumulatedTimeMSMs + Date().timeIntervalSince(startDate)
//            }
//        }
//    }
//    
//    func stopFormattedTimeMS() {
//        guard isRunningMSMs else { return }
//        timerMSMs?.invalidate()
//        isRunningMSMs = false
//        
//        if let startDate = startDateMSMs {
//            accumulatedTimeMSMs += Date().timeIntervalSince(startDate)
//        }
//        saveState()
//    }
//    
//    func resetFormattedTimeMS() {
//        timerMSMs?.invalidate()
//        timeElapsedMSMs = 0
//        accumulatedTimeMSMs = 0
//        startDateMSMs = nil
//        
//        userDefaults.removeObject(forKey: startDateFormattedTimeMSKey)
//        userDefaults.removeObject(forKey: accumulatedTimeMSMsKey)
//        userDefaults.set(false, forKey: isRunningFormattedTimeMSKey)
//    }
//    
//    // Zapisuje stan licznika do UserDefaults
//    public func saveState() {
//        if let startDate = startDate {
//            userDefaults.set(startDate, forKey: startDateKey)
//        }
//        if let startDateMS = startDateMSMs {
//            userDefaults.set(startDateMS, forKey: startDateFormattedTimeMSKey)
//        }
//        userDefaults.set(accumulatedTimeHMS, forKey: accumulatedTimeHMSKey)
//        userDefaults.set(accumulatedTimeMSMs, forKey: accumulatedTimeMSMsKey)
//        userDefaults.set(isRunning, forKey: isRunningKey)
//        userDefaults.set(isRunningMSMs, forKey: isRunningFormattedTimeMSKey)
//    }
//    
//    // Ładuje stan licznika z UserDefaults
//    private func loadState() {
//        accumulatedTimeHMS = userDefaults.double(forKey: accumulatedTimeHMSKey)
//        accumulatedTimeMSMs = userDefaults.double(forKey: accumulatedTimeMSMsKey)
//        isRunning = userDefaults.bool(forKey: isRunningKey)
//        isRunningMSMs = userDefaults.bool(forKey: isRunningFormattedTimeMSKey)
//        
//        if let savedStartDate = userDefaults.object(forKey: startDateKey) as? Date {
//            startDate = savedStartDate
//        }
//        if let savedStartDateMS = userDefaults.object(forKey: startDateFormattedTimeMSKey) as? Date {
//            startDateMSMs = savedStartDateMS
//        }
//    }
//    
//    func reset() {
//        resetFormattedTime()
//        resetFormattedTimeMS()
//    }
//    
//    func resetMSMs() {
//        resetFormattedTimeMS()
//    }
//    
//    func start() {
//        startFormattedTime()
//        startFormattedTimeMS()
//    }
//    
//    func stop() {
//        stopFormattedTime()
//        stopFormattedTimeMS()
//    }
//}

class Stopwatch: ObservableObject {
    @Published var timeElapsedHMS: TimeInterval = 0
    @Published var timeElapsedMSMs: TimeInterval = 0
    
    @Published var isRunning = true
    @Published var isRunningMSMs = true
    
    private var timerHMS: DispatchSourceTimer?
    private var timerMSMs: DispatchSourceTimer?
    
    private var startDate: Date?
    private var startDateMSMs: Date?
    
    private var accumulatedTimeHMS: TimeInterval = 0
    private var accumulatedTimeMSMs: TimeInterval = 0
    
    private let userDefaults = UserDefaults.standard
    private let startDateKey = "stopwatchStartDateFormattedTime"
    private let accumulatedTimeHMSKey = "stopwatchAccumulatedTimeFormattedTime"
    private let accumulatedTimeMSMsKey = "stopwatchAccumulatedTimeFormattedTimeMS"
    private let isRunningKey = "stopwatchIsRunningFormattedTime"
    private let startDateFormattedTimeMSKey = "stopwatchStartDateFormattedTimeMS"
    private let isRunningFormattedTimeMSKey = "stopwatchIsRunningFormattedTimeMS"
    
    var formattedTime: String {
        let hours = Int(timeElapsedHMS) / 3600
        let minutes = (Int(timeElapsedHMS) % 3600) / 60
        let seconds = Int(timeElapsedHMS) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    var formattedTimeMS: String {
        let hours = Int(timeElapsedMSMs) / 3600
        let minutes = (Int(timeElapsedMSMs) % 3600) / 60
        let seconds = Int(timeElapsedMSMs) % 60
        let miliseconds = Int((timeElapsedMSMs * 100).truncatingRemainder(dividingBy: 100))
        if hours <= 0 {
            return String(format: "%02d:%02d,%02d", minutes, seconds, miliseconds)
        } else {
            return String(format: "%02d:%02d:%02d,%02d", hours, minutes, seconds, miliseconds)
        }
    }
    
    init() {
        loadState()
        
        if isRunning, let startDate = self.startDate {
            self.timeElapsedHMS = accumulatedTimeHMS + Date().timeIntervalSince(startDate)
            stopFormattedTime()
            startFormattedTime()
        } else {
            self.timeElapsedHMS = accumulatedTimeHMS
            self.isRunning = false
            stopFormattedTime()
            startFormattedTime()
        }
        
        if isRunningMSMs, let startDate = self.startDateMSMs {
            self.timeElapsedMSMs = accumulatedTimeMSMs + Date().timeIntervalSince(startDate)
            stopFormattedTimeMS()
            startFormattedTimeMS()
        } else {
            self.timeElapsedMSMs = accumulatedTimeMSMs
            self.isRunningMSMs = false
            stopFormattedTimeMS()
            startFormattedTimeMS()
        }
    }
    
    // Metody dla licznika formattedTime (HH:mm:ss)
    func startFormattedTime() {
        guard !isRunning else { return }
        isRunning = true
        startDate = Date()
        saveState()
        
        timerHMS = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
        timerHMS?.schedule(deadline: .now(), repeating: 1.0)
        timerHMS?.setEventHandler { [weak self] in
            guard let self = self, let startDate = self.startDate else { return }
            DispatchQueue.main.async {
                self.timeElapsedHMS = self.accumulatedTimeHMS + Date().timeIntervalSince(startDate)
            }
        }
        timerHMS?.resume()
    }
    
    func stopFormattedTime() {
        guard isRunning else { return }
        timerHMS?.cancel()
        isRunning = false
        
        if let startDate = startDate {
            accumulatedTimeHMS += Date().timeIntervalSince(startDate)
        }
        saveState()
    }
    
    func resetFormattedTime() {
        timerHMS?.cancel()
        timeElapsedHMS = 0
        accumulatedTimeHMS = 0
        startDate = nil
        
        userDefaults.removeObject(forKey: startDateKey)
        userDefaults.removeObject(forKey: accumulatedTimeHMSKey)
        userDefaults.set(false, forKey: isRunningKey)
    }
    
    // Metody dla licznika formattedTimeMS (mm:ss,ms)
    func startFormattedTimeMS() {
        guard !isRunningMSMs else { return }
        isRunningMSMs = true
        startDateMSMs = Date()
        saveState()
        
        timerMSMs = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
        timerMSMs?.schedule(deadline: .now(), repeating: 0.09)
        timerMSMs?.setEventHandler { [weak self] in
            guard let self = self, let startDateMSMs = self.startDateMSMs else { return }
            DispatchQueue.main.async {
                self.timeElapsedMSMs = self.accumulatedTimeMSMs + Date().timeIntervalSince(startDateMSMs)
            }
        }
        timerMSMs?.resume()
    }
    
    func stopFormattedTimeMS() {
        guard isRunningMSMs else { return }
        timerMSMs?.cancel()
        isRunningMSMs = false
        
        if let startDateMSMs = startDateMSMs {
            accumulatedTimeMSMs += Date().timeIntervalSince(startDateMSMs)
        }
        saveState()
    }
    
    func resetFormattedTimeMS() {
        timerMSMs?.cancel()
        timeElapsedMSMs = 0
        accumulatedTimeMSMs = 0
        startDateMSMs = nil
        
        userDefaults.removeObject(forKey: startDateFormattedTimeMSKey)
        userDefaults.removeObject(forKey: accumulatedTimeMSMsKey)
        userDefaults.set(false, forKey: isRunningFormattedTimeMSKey)
    }
    
    public func saveState() {
        if let startDate = startDate {
            userDefaults.set(startDate, forKey: startDateKey)
        }
        if let startDateMS = startDateMSMs {
            userDefaults.set(startDateMS, forKey: startDateFormattedTimeMSKey)
        }
        userDefaults.set(accumulatedTimeHMS, forKey: accumulatedTimeHMSKey)
        userDefaults.set(accumulatedTimeMSMs, forKey: accumulatedTimeMSMsKey)
        userDefaults.set(isRunning, forKey: isRunningKey)
        userDefaults.set(isRunningMSMs, forKey: isRunningFormattedTimeMSKey)
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
}
