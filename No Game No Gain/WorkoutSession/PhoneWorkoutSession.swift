//
//  PhoneWorkoutSession.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 07/11/2026.
//

import Foundation
import HealthKit

/// Owns the iPhone workout session used when the Watch does not take the workout.
/// iOS 17 and 18 report that no session started, and the recorder keeps the save-on-end path.
/// Heart rate arrives through HealthKit from AirPods or a Bluetooth monitor. This type does not read those devices itself.
final class PhoneWorkoutSessionHost {
    private let healthStore: HKHealthStore
    private var runner: AnyObject?
    var onMetrics: ((WorkoutLiveMetrics) -> Void)?
    var onFailed: (() -> Void)?

    init(healthStore: HKHealthStore) {
        self.healthStore = healthStore
    }

    func start(configuration: HKWorkoutConfiguration, completion: @escaping (Bool) -> Void) {
        guard #available(iOS 26, *) else {
            completion(false)
            return
        }
        current().start(configuration: configuration, completion: completion)
    }

    func adopt(_ session: HKWorkoutSession) {
        guard #available(iOS 26, *) else { return }
        current().adopt(session)
    }

    func pause() {
        guard #available(iOS 26, *) else { return }
        (runner as? PhoneWorkoutSession)?.pause()
    }

    func resume() {
        guard #available(iOS 26, *) else { return }
        (runner as? PhoneWorkoutSession)?.resume()
    }

    func end(completion: @escaping (Bool) -> Void) {
        guard #available(iOS 26, *), let session = runner as? PhoneWorkoutSession else {
            completion(false)
            return
        }
        session.end(completion: completion)
    }

    func discard() {
        guard #available(iOS 26, *) else { return }
        (runner as? PhoneWorkoutSession)?.discard()
    }

    @available(iOS 26, *)
    private func current() -> PhoneWorkoutSession {
        if let session = runner as? PhoneWorkoutSession {
            return session
        }
        let session = PhoneWorkoutSession(healthStore: healthStore) { [weak self] metrics in
            self?.onMetrics?(metrics)
        } onFailed: { [weak self] in
            self?.onFailed?()
        }
        runner = session
        return session
    }
}

/// Primary session for this phone. `beginCollection` belongs here.
/// The mirrored Watch builder must not begin collection; that path stays in `LiveWorkoutMirror`.
@available(iOS 26.0, *)
private final class PhoneWorkoutSession: NSObject, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    private let healthStore: HKHealthStore
    private let onMetrics: (WorkoutLiveMetrics) -> Void
    private let onFailed: () -> Void
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var pollTask: Task<Void, Never>?
    private var finishOnEnd = true
    private var didFinish = false
    private var acceptsMetrics = false
    private var didBeginActivity = false
    private var startCompletion: ((Bool) -> Void)?
    private var endCompletion: ((Bool) -> Void)?

    init(
        healthStore: HKHealthStore,
        onMetrics: @escaping (WorkoutLiveMetrics) -> Void,
        onFailed: @escaping () -> Void
    ) {
        self.healthStore = healthStore
        self.onMetrics = onMetrics
        self.onFailed = onFailed
    }

    deinit {
        pollTask?.cancel()
    }

    func start(configuration: HKWorkoutConfiguration, completion: @escaping (Bool) -> Void) {
        if let session, session.state != .ended, session.state != .stopped {
            completion(true)
            return
        }
        let created: HKWorkoutSession
        do {
            created = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
        } catch {
            completion(false)
            return
        }
        let liveBuilder = created.associatedWorkoutBuilder()
        created.delegate = self
        liveBuilder.delegate = self
        liveBuilder.dataSource = Self.makeSource(healthStore: healthStore, configuration: configuration)
        session = created
        builder = liveBuilder
        didFinish = false
        finishOnEnd = true
        acceptsMetrics = true
        didBeginActivity = false
        startCompletion = completion
        // Prepare first so AirPods or a Bluetooth monitor can attach before the activity starts.
        created.prepare()
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            self?.onMain { self?.beginActivityIfNeeded() }
        }
    }

    /// Starts the activity once, either when the session is prepared or after the prepare wait.
    private func beginActivityIfNeeded() {
        guard !didBeginActivity, let session, let liveBuilder = builder else { return }
        didBeginActivity = true
        let start = Date()
        if session.state != .running && session.state != .paused {
            session.startActivity(with: start)
        }
        let completion = startCompletion
        startCompletion = nil
        Task { [weak self] in
            do {
                try await liveBuilder.beginCollection(at: start)
                self?.onMain {
                    self?.startPolling()
                    completion?(true)
                }
            } catch {
                self?.onMain {
                    self?.finishOnEnd = false
                    self?.acceptsMetrics = false
                    session.end()
                    completion?(false)
                }
            }
        }
    }

    /// A recovered phone session is already collecting. Do not call `beginCollection` again.
    func adopt(_ recovered: HKWorkoutSession) {
        session = recovered
        let liveBuilder = recovered.associatedWorkoutBuilder()
        recovered.delegate = self
        liveBuilder.delegate = self
        if liveBuilder.dataSource == nil {
            liveBuilder.dataSource = Self.makeSource(
                healthStore: healthStore,
                configuration: recovered.workoutConfiguration
            )
        }
        builder = liveBuilder
        didFinish = false
        finishOnEnd = true
        acceptsMetrics = true
        didBeginActivity = true
        startPolling()
        publish()
    }

    func pause() {
        session?.pause()
    }

    func resume() {
        session?.resume()
    }

    func end(completion: @escaping (Bool) -> Void) {
        stopPolling()
        guard let session else {
            completion(false)
            return
        }
        endCompletion = completion
        finishOnEnd = true
        if session.state == .ended {
            finish(at: session.endDate ?? Date())
            return
        }
        session.end()
    }

    func discard() {
        stopPolling()
        finishOnEnd = false
        endCompletion = nil
        guard let session else {
            builder?.discardWorkout()
            builder = nil
            return
        }
        if session.state == .ended {
            builder?.discardWorkout()
            self.session = nil
            builder = nil
            return
        }
        session.end()
    }

    func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        onMain { [weak self] in
            guard let self, workoutSession === self.session else { return }
            if toState == .prepared || toState == .running {
                self.beginActivityIfNeeded()
            }
            guard toState == .ended else { return }
            self.finish(at: date)
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        onMain { [weak self] in
            guard let self else { return }
            self.finishOnEnd = false
            self.stopPolling()
            self.onFailed()
        }
    }

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        onMain { [weak self] in
            self?.publish()
        }
    }

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
    }

    private func finish(at date: Date) {
        guard !didFinish else { return }
        didFinish = true
        stopPolling()
        let liveBuilder = builder
        let completion = endCompletion
        endCompletion = nil
        session = nil
        builder = nil
        guard finishOnEnd else {
            liveBuilder?.discardWorkout()
            completion?(false)
            return
        }
        Task { [weak self] in
            do {
                try await liveBuilder?.endCollection(at: date)
                _ = try await liveBuilder?.finishWorkout()
                self?.onMain { completion?(true) }
            } catch {
                liveBuilder?.discardWorkout()
                self?.onMain { completion?(false) }
            }
        }
    }

    private func startPolling() {
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                self?.onMain { self?.publish() }
            }
        }
    }

    private func stopPolling() {
        acceptsMetrics = false
        pollTask?.cancel()
        pollTask = nil
    }

    private func publish() {
        guard acceptsMetrics, let builder else { return }
        let unit = HKUnit.count().unitDivided(by: .minute())
        let heart = HKQuantityType.quantityType(forIdentifier: .heartRate).flatMap { builder.statistics(for: $0) }
        var energy: Double?
        if let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
           let quantity = builder.statistics(for: type)?.sumQuantity() {
            energy = quantity.doubleValue(for: .kilocalorie())
        }
        let metrics = WorkoutLiveMetrics(
            heartRateBPM: heart?.mostRecentQuantity()?.doubleValue(for: unit),
            averageHeartRateBPM: heart?.averageQuantity()?.doubleValue(for: unit),
            maximumHeartRateBPM: heart?.maximumQuantity()?.doubleValue(for: unit),
            activeEnergyKilocalories: energy
        )
        guard metrics.heartRateBPM != nil
            || metrics.averageHeartRateBPM != nil
            || metrics.maximumHeartRateBPM != nil
            || metrics.activeEnergyKilocalories != nil else { return }
        onMetrics(metrics)
    }

    private static func makeSource(
        healthStore: HKHealthStore,
        configuration: HKWorkoutConfiguration
    ) -> HKLiveWorkoutDataSource {
        let source = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
        if let heartRate = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            source.enableCollection(for: heartRate, predicate: nil)
        }
        if let energy = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            source.enableCollection(for: energy, predicate: nil)
        }
        return source
    }

    private func onMain(_ work: @escaping @MainActor () -> Void) {
        Task { @MainActor in
            work()
        }
    }
}
