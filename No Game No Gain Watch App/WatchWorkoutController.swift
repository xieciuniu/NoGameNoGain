//
//  WatchWorkoutController.swift
//  No Game No Gain Watch App
//
//  Created by Hubert Wojtowicz on 25/10/2026.
//

import Foundation
import HealthKit
import Observation

struct LiveWorkoutMetricsMessage: Codable {
    var heartRateBPM: Double?
    var averageHeartRateBPM: Double?
    var maximumHeartRateBPM: Double?
    var activeEnergyKilocalories: Double?
}

/// The primary Health workout. Set logging and the account file stay on the phone.
@MainActor
@Observable
final class WatchWorkoutController: NSObject, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    private(set) var heartRateBPM: Double?
    private(set) var averageHeartRateBPM: Double?
    private(set) var maximumHeartRateBPM: Double?
    private(set) var activeEnergyKilocalories: Double?
    private(set) var isPaused = false
    private(set) var isSessionActive = false

    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var didRequestFinish = false
    private var isStartingSession = false
    private var isMirroring = false
    private var relayTask: Task<Void, Never>?
    private var elapsedAnchor: TimeInterval = 0
    private var elapsedAnchorDate: Date?
    private let phoneLink = WatchPhoneLink()
    private var phoneElapsed: TimeInterval?
    private var phoneElapsedDate: Date?
    private var phoneRunning = false
    private var phoneRest: TimeInterval?
    private var phoneRestDate: Date?
    private var phoneRestRunning = false
    private(set) var restTarget: TimeInterval = 0
    private var phoneWorkoutID: String?
    private var phoneCommandSeq = 0
    private var phoneRequestsEnd = false
    /// False after this Watch session has ended. A new `beginCollection` turns it back on.
    private var acceptsLiveSamples = false

    override init() {
        super.init()
        phoneLink.controller = self
        phoneLink.activate()
        WatchAlertCenter.shared.prepare()
    }

    func displayedElapsed(at now: Date) -> TimeInterval {
        if let phoneElapsed, let phoneElapsedDate {
            guard phoneRunning else { return max(0, phoneElapsed) }
            return max(0, phoneElapsed + now.timeIntervalSince(phoneElapsedDate))
        }
        guard let elapsedAnchorDate, !isPaused else { return elapsedAnchor }
        return max(0, elapsedAnchor + now.timeIntervalSince(elapsedAnchorDate))
    }

    var isRestClockRunning: Bool { phoneRestRunning }

    /// Time since the last set, in the same `mm:ss,xx` form as the phone's large clock.
    func restLabel(at now: Date) -> String {
        Self.formatRest(displayedRest(at: now))
    }

    func restAccessibility(at now: Date) -> String {
        let total = Int(displayedRest(at: now))
        let minutes = total / 60
        let seconds = total % 60
        let paused = phoneRestRunning ? "" : ", paused"
        return "Time since last set \(minutes) minutes \(seconds) seconds\(paused)"
    }

    var restTargetLabel: String {
        "Rest \(Self.formatClock(restTarget))"
    }

    var restTargetAccessibility: String {
        let total = Int(restTarget.rounded())
        let minutes = total / 60
        let seconds = total % 60
        return "Rest \(minutes) minutes \(seconds) seconds"
    }

    func displayedRest(at now: Date) -> TimeInterval {
        guard let phoneRest, let phoneRestDate else { return 0 }
        guard phoneRestRunning else { return max(0, phoneRest) }
        return max(0, phoneRest + now.timeIntervalSince(phoneRestDate))
    }

    private static func formatRest(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        let hundredths = Int((time * 100).truncatingRemainder(dividingBy: 100))
        if hours <= 0 {
            return String(format: "%02d:%02d,%02d", minutes, seconds, hundredths)
        }
        return String(format: "%02d:%02d:%02d,%02d", hours, minutes, seconds, hundredths)
    }

    private static func formatClock(_ time: TimeInterval) -> String {
        let total = max(0, Int(time.rounded()))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func start(_ configuration: HKWorkoutConfiguration) async {
        guard session == nil || session?.state == .ended || session?.state == .stopped else { return }
        phoneRequestsEnd = false
        await authorize()
        let created: HKWorkoutSession
        do {
            created = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
        } catch {
            return
        }
        let liveBuilder = created.associatedWorkoutBuilder()
        liveBuilder.dataSource = makeDataSource(configuration: configuration)
        created.delegate = self
        liveBuilder.delegate = self
        session = created
        builder = liveBuilder
        didRequestFinish = false
        isMirroring = false
        isSessionActive = true
        created.prepare()
        await waitUntilReadyToMirror()
        if phoneElapsed == nil && !phoneRequestsEnd {
            for _ in 0..<10 {
                pullPhoneClock()
                if phoneElapsed != nil || phoneRequestsEnd { break }
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
        }
        if phoneRequestsEnd {
            endFromPhone()
            startMetricRelay()
            return
        }
        await mirrorIfNeeded()
        let activityStart = Date()
        let syncedElapsed = phoneElapsed ?? 0
        let holdForPhone = phoneElapsed != nil && !phoneRunning
        resetElapsed(to: syncedElapsed, at: activityStart, paused: holdForPhone)
        isPaused = holdForPhone
        created.startActivity(with: activityStart)
        try? await liveBuilder.beginCollection(at: activityStart)
        acceptsLiveSamples = true
        await mirrorIfNeeded()
        startMetricRelay()
        if phoneRequestsEnd {
            endFromPhone()
        } else if phoneElapsed != nil {
            syncHealthSession(running: phoneRunning)
        }
    }

    func recover() async {
        let recovered: HKWorkoutSession? = await withCheckedContinuation { continuation in
            healthStore.recoverActiveWorkoutSession { session, _ in
                continuation.resume(returning: session)
            }
        }
        guard let recovered else { return }
        guard recovered.state == .running || recovered.state == .paused else {
            recovered.end()
            return
        }
        let liveBuilder = recovered.associatedWorkoutBuilder()
        liveBuilder.dataSource = makeDataSource(configuration: recovered.workoutConfiguration)
        recovered.delegate = self
        liveBuilder.delegate = self
        session = recovered
        builder = liveBuilder
        didRequestFinish = false
        isSessionActive = true
        isMirroring = false
        acceptsLiveSamples = true
        let paused = recovered.state == .paused
        isPaused = paused
        resetElapsed(to: liveBuilder.elapsedTime, at: Date(), paused: paused)
        await mirrorIfNeeded()
        startMetricRelay()
        pullPhoneClock()
        if phoneRequestsEnd {
            endFromPhone()
        } else if phoneElapsed != nil {
            syncHealthSession(running: phoneRunning)
        }
    }

    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        Task { @MainActor in
            switch toState {
            case .paused:
                captureElapsed(at: date, paused: true)
                if phoneElapsed != nil && phoneRunning {
                    workoutSession.resume()
                } else {
                    isPaused = true
                }
            case .running:
                if phoneRequestsEnd {
                    captureElapsed(at: date, paused: true)
                    endFromPhone()
                    break
                }
                let holdForPhone = phoneElapsed != nil && !phoneRunning
                captureElapsed(at: date, paused: holdForPhone)
                isPaused = holdForPhone
                isSessionActive = true
                if holdForPhone {
                    workoutSession.pause()
                }
            case .stopped, .ended:
                isPaused = false
                isSessionActive = false
                heartRateBPM = nil
                averageHeartRateBPM = nil
                maximumHeartRateBPM = nil
                activeEnergyKilocalories = nil
                finish(at: date, alreadyEnded: toState == .ended)
            default:
                break
            }
        }
    }

    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
    }

    nonisolated func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        let heart = Self.heartRates(from: workoutBuilder)
        var energy: Double?
        if let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
           collectedTypes.contains(type),
           let sum = workoutBuilder.statistics(for: type)?.sumQuantity() {
            energy = sum.doubleValue(for: .kilocalorie())
        }
        let payloadHeart = heart
        let payloadEnergy = energy
        Task { @MainActor in
            guard self.acceptsLiveSamples, !self.phoneRequestsEnd else { return }
            if let current = payloadHeart.current {
                heartRateBPM = current
            }
            if let average = payloadHeart.average {
                averageHeartRateBPM = average
            }
            if let maximum = payloadHeart.maximum {
                maximumHeartRateBPM = maximum
            }
            if let payloadEnergy {
                activeEnergyKilocalories = payloadEnergy
            }
            sendMetrics()
        }
    }

    /// The phone owns pause, resume, and end. Keep offering the mirrored session until that link is up.
    private func waitUntilReadyToMirror() async {
        for _ in 0..<30 {
            pullPhoneClock()
            if phoneRequestsEnd { return }
            let state = session?.state
            if state == .prepared || state == .running || state == .paused { return }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
    }

    private func mirrorIfNeeded() async {
        guard let session, !isMirroring else { return }
        guard session.state != .ended, session.state != .stopped else { return }
        do {
            try await session.startMirroringToCompanionDevice()
            isMirroring = true
            sendMetrics()
        } catch {
            isMirroring = false
        }
    }

    private func startMetricRelay() {
        relayTask?.cancel()
        relayTask = Task { @MainActor in
            while !Task.isCancelled {
                pullPhoneClock()
                if phoneRequestsEnd {
                    endFromPhone()
                    let state = session?.state
                    if session == nil || state == .ended || state == .stopped { return }
                } else if let session, session.state != .ended, session.state != .stopped {
                    if !isMirroring {
                        await mirrorIfNeeded()
                    }
                    sendMetrics()
                } else {
                    return
                }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }

    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        let elapsed = workoutBuilder.elapsedTime
        Task { @MainActor in
            guard self.phoneElapsed == nil else { return }
            self.resetElapsed(to: elapsed, at: Date(), paused: self.isPaused)
        }
    }

    private func finish(at date: Date, alreadyEnded: Bool) {
        guard !didRequestFinish else {
            if !alreadyEnded {
                session?.end()
            }
            return
        }
        didRequestFinish = true
        relayTask?.cancel()
        relayTask = nil
        isMirroring = false
        let liveBuilder = builder
        let liveSession = session
        Task {
            try? await liveBuilder?.endCollection(at: date)
            _ = try? await liveBuilder?.finishWorkout()
            if liveSession?.state != .ended {
                liveSession?.end()
            }
        }
    }

    private func authorize() async {
        let share: Set<HKSampleType> = [HKObjectType.workoutType()]
        var read: Set<HKObjectType> = [HKObjectType.workoutType()]
        if let heartRate = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            read.insert(heartRate)
        }
        if let energy = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            read.insert(energy)
        }
        try? await healthStore.requestAuthorization(toShare: share, read: read)
    }

    private func makeDataSource(configuration: HKWorkoutConfiguration) -> HKLiveWorkoutDataSource {
        let source = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
        if let heartRate = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            source.enableCollection(for: heartRate, predicate: nil)
        }
        if let energy = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            source.enableCollection(for: energy, predicate: nil)
        }
        return source
    }

    /// The phone clock is the timer. Pause and end from that clock apply to this Health session.
    func applyPhone(_ message: [String: Any]) {
        guard (message["kind"] as? String) == "clock" else { return }
        guard let id = message["id"] as? String else { return }
        guard let sequence = Self.intValue(message["seq"]) else { return }
        let ended = Self.boolValue(message["ended"])
        if let phoneWorkoutID, id != phoneWorkoutID {
            if ended { return }
            self.phoneWorkoutID = id
            phoneCommandSeq = 0
            phoneRequestsEnd = false
            // Forget the previous workout's last sample so the relay does not publish it under this id.
            // A session that is still collecting sends the next sensor callback as usual.
            clearLiveMetrics()
            if session == nil || session?.state == .ended || session?.state == .stopped {
                acceptsLiveSamples = false
            }
        }
        if phoneWorkoutID == nil {
            phoneWorkoutID = id
        }
        guard id == phoneWorkoutID, sequence > phoneCommandSeq else { return }
        phoneCommandSeq = sequence
        let elapsed = Self.doubleValue(message["elapsed"]) ?? 0
        let running = Self.boolValue(message["running"])
        phoneElapsed = max(0, elapsed)
        phoneElapsedDate = Date()
        phoneRunning = ended ? false : running
        isPaused = !phoneRunning
        if let rest = Self.doubleValue(message["rest"]) {
            phoneRest = max(0, rest)
            phoneRestDate = Date()
            phoneRestRunning = ended ? false : Self.boolValue(message["restRun"])
        }
        if let target = Self.doubleValue(message["restSet"]) {
            restTarget = max(0, target)
        }
        if ended {
            endFromPhone()
            return
        }
        isSessionActive = true
        if hasLiveSession {
            syncHealthSession(running: running)
        } else {
            startSessionForOpenPhoneWorkout()
        }
    }

    private var hasLiveSession: Bool {
        guard let session else { return false }
        switch session.state {
        case .ended, .stopped:
            return false
        default:
            return true
        }
    }

    /// The phone workout is already running. Opening this app, or a later clock, still needs a session.
    private func startSessionForOpenPhoneWorkout() {
        guard !isStartingSession, !hasLiveSession else { return }
        isStartingSession = true
        phoneRequestsEnd = false
        didRequestFinish = false
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .traditionalStrengthTraining
        configuration.locationType = .indoor
        Task { [weak self] in
            await self?.start(configuration)
            self?.isStartingSession = false
        }
    }

    private static func boolValue(_ value: Any?) -> Bool {
        if let value = value as? Bool { return value }
        if let value = value as? NSNumber { return value.boolValue }
        return false
    }

    private static func intValue(_ value: Any?) -> Int? {
        if let value = value as? Int { return value }
        if let value = value as? NSNumber { return value.intValue }
        return nil
    }

    private static func doubleValue(_ value: Any?) -> Double? {
        if let value = value as? Double { return value }
        if let value = value as? NSNumber { return value.doubleValue }
        return nil
    }

    func applyAlert(_ message: [String: Any]) {
        WatchAlertCenter.shared.handle(message)
    }

    func pullPhoneClock() {
        let context = phoneLink.latestPhoneContext()
        guard !context.isEmpty else { return }
        applyPhone(context)
    }

    func pushMetricsToPhone() {
        sendMetrics()
    }

    private func syncHealthSession(running: Bool) {
        guard !phoneRequestsEnd, let session else { return }
        if running {
            if session.state == .paused {
                session.resume()
            }
        } else if session.state == .running {
            session.pause()
        }
    }

    private func endFromPhone() {
        phoneRunning = false
        isPaused = true
        phoneRequestsEnd = true
        isSessionActive = false
        heartRateBPM = nil
        averageHeartRateBPM = nil
        maximumHeartRateBPM = nil
        activeEnergyKilocalories = nil
        guard let session else { return }
        switch session.state {
        case .ended, .stopped:
            return
        default:
            session.end()
        }
    }

    private func clearLiveMetrics() {
        heartRateBPM = nil
        averageHeartRateBPM = nil
        maximumHeartRateBPM = nil
        activeEnergyKilocalories = nil
    }

    private func sendMetrics() {
        guard acceptsLiveSamples, !phoneRequestsEnd, let workoutID = phoneWorkoutID else { return }
        phoneLink.sendMetrics(
            workoutID: workoutID,
            heartRateBPM: heartRateBPM,
            averageHeartRateBPM: averageHeartRateBPM,
            maximumHeartRateBPM: maximumHeartRateBPM,
            activeEnergyKilocalories: activeEnergyKilocalories
        )
        guard isMirroring,
              heartRateBPM != nil || averageHeartRateBPM != nil || maximumHeartRateBPM != nil || activeEnergyKilocalories != nil else { return }
        let message = LiveWorkoutMetricsMessage(
            heartRateBPM: heartRateBPM,
            averageHeartRateBPM: averageHeartRateBPM,
            maximumHeartRateBPM: maximumHeartRateBPM,
            activeEnergyKilocalories: activeEnergyKilocalories
        )
        guard let data = try? JSONEncoder().encode(message), let session else { return }
        session.sendToRemoteWorkoutSession(data: data) { _, _ in }
    }

    private nonisolated static func heartRates(from builder: HKLiveWorkoutBuilder) -> (current: Double?, average: Double?, maximum: Double?) {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate),
              let statistics = builder.statistics(for: type) else {
            return (nil, nil, nil)
        }
        let unit = HKUnit.count().unitDivided(by: .minute())
        return (
            statistics.mostRecentQuantity()?.doubleValue(for: unit),
            statistics.averageQuantity()?.doubleValue(for: unit),
            statistics.maximumQuantity()?.doubleValue(for: unit)
        )
    }

    private func captureElapsed(at date: Date, paused: Bool) {
        let current = displayedElapsed(at: date)
        resetElapsed(to: current, at: date, paused: paused)
    }

    private func resetElapsed(to elapsed: TimeInterval, at date: Date, paused: Bool) {
        elapsedAnchor = max(0, elapsed)
        elapsedAnchorDate = paused ? nil : date
    }
}
