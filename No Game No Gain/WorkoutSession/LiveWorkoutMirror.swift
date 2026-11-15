//
//  LiveWorkoutMirror.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 25/10/2026.
//

import Foundation
import HealthKit

/// The Watch sends this JSON on the mirrored session. The same property names are encoded on watchOS.
struct LiveWorkoutMetricsMessage: Codable {
    var heartRateBPM: Double?
    var averageHeartRateBPM: Double?
    var maximumHeartRateBPM: Double?
    var activeEnergyKilocalories: Double?
}

/// One live sample from the Watch. Missing numbers stay nil so the screen can show a dash.
struct WorkoutLiveMetrics {
    var heartRateBPM: Double?
    var averageHeartRateBPM: Double?
    var maximumHeartRateBPM: Double?
    var activeEnergyKilocalories: Double?
}

/// Holds a workout session mirrored from the Watch. The phone-owned session lives in `PhoneWorkoutSession`.
final class LiveWorkoutMirror: NSObject, HKWorkoutSessionDelegate {
    private let healthStore: HKHealthStore
    private var session: HKWorkoutSession?
    private var metricsCollector: AnyObject?
    private var onMirrored: (() -> Void)?
    private var onEnded: (() -> Void)?
    private var onMetrics: ((WorkoutLiveMetrics) -> Void)?
    private var onRecovered: ((Bool) -> Void)?
    private var onPrimary: ((HKWorkoutSession) -> Void)?
    private var didInstall = false

    init(healthStore: HKHealthStore) {
        self.healthStore = healthStore
    }

    func install(
        onMirrored: @escaping () -> Void,
        onEnded: @escaping () -> Void,
        onMetrics: @escaping (WorkoutLiveMetrics) -> Void,
        onRecovered: @escaping (Bool) -> Void,
        onPrimary: @escaping (HKWorkoutSession) -> Void
    ) {
        self.onMirrored = onMirrored
        self.onEnded = onEnded
        self.onMetrics = onMetrics
        self.onRecovered = onRecovered
        self.onPrimary = onPrimary
        guard !didInstall else { return }
        didInstall = true

        installMirroringHandler()

        // recoverActiveWorkoutSession is iOS 26 in this SDK. Older phones reattach when mirroring starts.
        if #available(iOS 26, *) {
            healthStore.recoverActiveWorkoutSession { [weak self] recovered, _ in
                self?.onMain {
                    if let recovered {
                        if recovered.type == .primary {
                            self?.onPrimary?(recovered)
                        } else {
                            self?.attach(recovered)
                            self?.onRecovered?(true)
                        }
                    } else {
                        self?.onRecovered?(false)
                    }
                }
            }
        } else {
            onMain { self.onRecovered?(false) }
        }
    }

    func startWatchApp(
        configuration: HKWorkoutConfiguration,
        completion: @escaping (Bool) -> Void
    ) {
        installMirroringHandler()
        Task {
            do {
                try await healthStore.startWatchApp(toHandle: configuration)
                onMain { completion(true) }
            } catch {
                onMain { completion(false) }
            }
        }
    }

    func pause() {
        session?.pause()
    }

    func resume() {
        session?.resume()
    }

    func end() {
        session?.end()
    }

    func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        guard toState == .ended else { return }
        onMain { [weak self] in
            self?.onEnded?()
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
    }

    func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didReceiveDataFromRemoteWorkoutSession data: [Data]
    ) {
        for payload in data {
            guard let message = try? JSONDecoder().decode(LiveWorkoutMetricsMessage.self, from: payload) else { continue }
            onMain { [weak self] in
                guard let self else { return }
                self.onMetrics?(WorkoutLiveMetrics(
                    heartRateBPM: message.heartRateBPM,
                    averageHeartRateBPM: message.averageHeartRateBPM,
                    maximumHeartRateBPM: message.maximumHeartRateBPM,
                    activeEnergyKilocalories: message.activeEnergyKilocalories
                ))
            }
        }
    }

    /// The system delivers the mirrored session on a background queue. The delegate has to be in place before that block returns, or the first samples are dropped.
    private func installMirroringHandler() {
        healthStore.workoutSessionMirroringStartHandler = { [weak self] mirrored in
            guard let self else { return }
            guard mirrored.type != .primary else { return }
            mirrored.delegate = self
            self.onMain {
                self.attach(mirrored)
                self.onMirrored?()
            }
        }
    }

    private func attach(_ mirrored: HKWorkoutSession) {
        session = mirrored
        mirrored.delegate = self
        if #available(iOS 26, *) {
            let collector = LiveWorkoutMetricsCollector(session: mirrored, healthStore: healthStore) { [weak self] metrics in
                self?.onMain {
                    guard let self else { return }
                    self.onMetrics?(metrics)
                }
            }
            metricsCollector = collector
            collector.activate()
        }
    }

    private func onMain(_ work: @escaping @MainActor () -> Void) {
        Task { @MainActor in
            work()
        }
    }
}

@available(iOS 26.0, *)
private final class LiveWorkoutMetricsCollector: NSObject, HKLiveWorkoutBuilderDelegate {
    private let builder: HKLiveWorkoutBuilder
    private let healthStore: HKHealthStore
    private let configuration: HKWorkoutConfiguration
    private let onMetrics: (WorkoutLiveMetrics) -> Void
    private var pollTask: Task<Void, Never>?

    init(session: HKWorkoutSession, healthStore: HKHealthStore, onMetrics: @escaping (WorkoutLiveMetrics) -> Void) {
        builder = session.associatedWorkoutBuilder()
        self.healthStore = healthStore
        configuration = session.workoutConfiguration
        self.onMetrics = onMetrics
        super.init()
        builder.delegate = self
    }

    deinit {
        pollTask?.cancel()
    }

    /// The Watch already started collection. Beginning it again on the phone replaces that stream with an empty one.
    func activate() {
        if builder.dataSource == nil {
            let source = HKLiveWorkoutDataSource(
                healthStore: healthStore,
                workoutConfiguration: configuration
            )
            if let heartRate = HKQuantityType.quantityType(forIdentifier: .heartRate) {
                source.enableCollection(for: heartRate, predicate: nil)
            }
            if let energy = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
                source.enableCollection(for: energy, predicate: nil)
            }
            builder.dataSource = source
        }
        publish()
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                self?.publish()
            }
        }
    }

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        publish()
    }

    private func publish() {
        let heartType = HKQuantityType.quantityType(forIdentifier: .heartRate)
        let heart = Self.heartRates(heartType.flatMap { builder.statistics(for: $0) })
        var energy: Double?
        if let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
           let quantity = builder.statistics(for: type)?.sumQuantity() {
            energy = quantity.doubleValue(for: .kilocalorie())
        }
        let metrics = WorkoutLiveMetrics(
            heartRateBPM: heart.current,
            averageHeartRateBPM: heart.average,
            maximumHeartRateBPM: heart.maximum,
            activeEnergyKilocalories: energy
        )
        guard metrics.heartRateBPM != nil
            || metrics.averageHeartRateBPM != nil
            || metrics.maximumHeartRateBPM != nil
            || metrics.activeEnergyKilocalories != nil else { return }
        onMetrics(metrics)
    }

    private static func heartRates(_ statistics: HKStatistics?) -> (current: Double?, average: Double?, maximum: Double?) {
        let unit = HKUnit.count().unitDivided(by: .minute())
        return (
            statistics?.mostRecentQuantity()?.doubleValue(for: unit),
            statistics?.averageQuantity()?.doubleValue(for: unit),
            statistics?.maximumQuantity()?.doubleValue(for: unit)
        )
    }

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
    }
}
