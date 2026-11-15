//
//  HealthKitManager.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 16/11/2024.
//

import Foundation
import HealthKit

enum RecoveredWorkoutSessionKind {
    case none
    case mirrored
    case phone
}

/// Authorization and the finished-workout save for the live session.
/// Chart screens keep calling `HealthKitManager` directly.
/// Companion callbacks are invoked on the main thread.
protocol WorkoutHealthRecording: AnyObject {
    func requestAuthorizationIfNeeded(completion: @escaping (Bool, Error?) -> Void)
    func saveTraditionalStrengthWorkout(
        start: Date,
        duration: TimeInterval,
        completion: @escaping (Bool, Error?) -> Void
    )
    func installCompanion(
        onMirrored: @escaping () -> Void,
        onEnded: @escaping () -> Void,
        onMetrics: @escaping (_ metrics: WorkoutLiveMetrics) -> Void,
        onRecovered: @escaping (_ kind: RecoveredWorkoutSessionKind) -> Void,
        onPhoneFailed: @escaping () -> Void
    )
    func startWatchApp(
        configuration: HKWorkoutConfiguration,
        completion: @escaping (Bool) -> Void
    )
    func pauseLiveSession()
    func resumeLiveSession()
    func endLiveSession()
    /// Starts the phone session when the Watch did not. The completion runs on the main thread.
    /// It is false on iOS 17 and 18, and when the session cannot be created.
    func startPhoneSession(
        configuration: HKWorkoutConfiguration,
        completion: @escaping (Bool) -> Void
    )
    func pausePhoneSession()
    func resumePhoneSession()
    /// Ends the phone session. True means that session's builder saved the workout.
    func endPhoneSession(completion: @escaping (Bool) -> Void)
    func discardPhoneSession()
}

class HealthKitManager: WorkoutHealthRecording {
    static let shared = HealthKitManager()
    private let healthStore: HKHealthStore
    private let liveMirror: LiveWorkoutMirror
    private let phoneSessions: PhoneWorkoutSessionHost
    
    init() {
        let store = HKHealthStore()
        healthStore = store
        liveMirror = LiveWorkoutMirror(healthStore: store)
        phoneSessions = PhoneWorkoutSessionHost(healthStore: store)
    }

    func installCompanion(
        onMirrored: @escaping () -> Void,
        onEnded: @escaping () -> Void,
        onMetrics: @escaping (WorkoutLiveMetrics) -> Void,
        onRecovered: @escaping (RecoveredWorkoutSessionKind) -> Void,
        onPhoneFailed: @escaping () -> Void
    ) {
        phoneSessions.onMetrics = onMetrics
        phoneSessions.onFailed = onPhoneFailed
        liveMirror.install(
            onMirrored: onMirrored,
            onEnded: onEnded,
            onMetrics: onMetrics,
            onRecovered: { found in
                onRecovered(found ? .mirrored : .none)
            },
            onPrimary: { [weak self] session in
                self?.phoneSessions.adopt(session)
                onRecovered(.phone)
            }
        )
    }

    func startWatchApp(
        configuration: HKWorkoutConfiguration,
        completion: @escaping (Bool) -> Void
    ) {
        liveMirror.startWatchApp(configuration: configuration, completion: completion)
    }

    func pauseLiveSession() {
        liveMirror.pause()
    }

    func resumeLiveSession() {
        liveMirror.resume()
    }

    func endLiveSession() {
        liveMirror.end()
    }

    func startPhoneSession(
        configuration: HKWorkoutConfiguration,
        completion: @escaping (Bool) -> Void
    ) {
        phoneSessions.start(configuration: configuration, completion: completion)
    }

    func pausePhoneSession() {
        phoneSessions.pause()
    }

    func resumePhoneSession() {
        phoneSessions.resume()
    }

    func endPhoneSession(completion: @escaping (Bool) -> Void) {
        phoneSessions.end(completion: completion)
    }

    func discardPhoneSession() {
        phoneSessions.discard()
    }

    func requestAuthorizationIfNeeded(completion: @escaping (Bool, Error?) -> Void) {
        let readTypes: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.workoutType()
        ]
        let writeTypes: Set<HKSampleType> = [
            HKObjectType.workoutType(),
            HKSampleType.quantityType(forIdentifier: .bodyMass)!,
        ]
        
        healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }
    
    func fetchStepCount(date: Date, completion: @escaping (Double?, Error?) -> Void) {
        guard let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            completion(nil, NSError(domain: "com.example.HealthKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "type step count not found"]))
            return
        }
        
        let startDate = Calendar.current.startOfDay(for: date)
        let endDate = date
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepCountType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                completion(nil, error)
                return
            }
            
            let step = sum.doubleValue(for: HKUnit.count())
            completion(step, nil)
        }
        
        healthStore.execute(query)
    }
    
    func fetchCaloriesBurned(date: Date, completion: @escaping (Double?, Error?)->Void) {
        guard let activeEnergyBurnedType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            completion(nil, NSError(domain: "com.example.HealthKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "type active energy burned not found"]))
            return
        }
        
        let startDate = Calendar.current.startOfDay(for: date)
        let endDate = date
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: activeEnergyBurnedType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, error in
                if let error = error {
                    completion(nil, error)
                    return
                }

                guard let sum = statistics?.sumQuantity() else {
                    completion(0, nil) // Brak danych = 0 kalorii
                    return
                }

                let caloriesBurned = sum.doubleValue(for: .kilocalorie())
            completion(caloriesBurned, nil)
            }

            healthStore.execute(query)
        
    }
    
    func fetchLastSleepDuration() async throws -> Double {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
                throw NSError(domain: "com.example.HealthKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "Typ danych dotyczących snu jest niedostępny"])
            }
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.startOfDay(for: Date()), end: Date(), options: .strictEndDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, results, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let sleepResults = results as? [HKCategorySample], !sleepResults.isEmpty else {
                    continuation.resume(returning: 0) // Brak danych = 0 minut snu
                    return
                }
                
                var totalSleepMinutes: Double = 0
                var lastSleepStartDate: Date?
                var lastSleepEndDate: Date?
                
                for sample in sleepResults {
                    if sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue {
                        if lastSleepStartDate == nil || sample.startDate < lastSleepStartDate! {
                            lastSleepStartDate = sample.startDate
                            lastSleepEndDate = sample.endDate
                        }
                    }
                }
                
                if let start = lastSleepStartDate, let end = lastSleepEndDate {
                    let sleepDuration = end.timeIntervalSince(start) / 60 // Konwersja na minuty
                    totalSleepMinutes += sleepDuration
                }
                
                continuation.resume(returning: totalSleepMinutes)
            }
            
            healthStore.execute(query)
        }
    }
    
    func fetchCaloriesBurnedForLastMonth(completion: @escaping ([(Date, Double)], Error?) -> Void) {
        guard let calorieType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            completion([], NSError(domain: "com.example.HealthKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "Typ danych aktywnej energii spalanej jest niedostępny"]))
            return
        }

        let now = Date()
        let calendar = Calendar.current
        guard let startOfMonth = calendar.date(byAdding: .month, value: -1, to: now) else {
            completion([], NSError(domain: "com.example.HealthKit", code: 2, userInfo: [NSLocalizedDescriptionKey: "Błąd obliczania początku miesiąca"]))
            return
        }

        var caloriesData: [(Date, Double)] = []

        var currentDate = startOfMonth
        let group = DispatchGroup() // Do synchronizacji asynchronicznych zapytań

        while currentDate <= now {
            let startOfDay = calendar.startOfDay(for: currentDate)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

            let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)

            let query = HKStatisticsQuery(quantityType: calorieType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, error in
                defer {
                    group.leave()
                }

                if let error = error {
                    print("Błąd podczas zapytania o dane kalorii: \(error.localizedDescription)")
                    return
                }

                if let statistics = statistics, let sum = statistics.sumQuantity()?.doubleValue(for: .kilocalorie()) {
                    caloriesData.append((startOfDay, sum))
                } else {
                    print("Brak danych dla dnia: \(currentDate)")
                }
            }

            healthStore.execute(query)
            group.enter()

            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        // Po zakończeniu wszystkich zapytań
        group.notify(queue: .main) {
            completion(caloriesData, nil)
        }
    }
    
    func fetchHealthDataForLastMonth(dataType: HKQuantityTypeIdentifier, chartTitle: String, completion: @escaping ([(Date, Double)], Error?) -> Void) {
        guard let healthDataType = HKObjectType.quantityType(forIdentifier: dataType) else {
            completion([], NSError(domain: "com.example.HealthKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "Nieprawidłowy typ danych"]))
            return
        }

        let now = Date()
        let calendar = Calendar.current
        guard let startOfMonth = calendar.date(byAdding: .month, value: -1, to: now) else {
            completion([], NSError(domain: "com.example.HealthKit", code: 2, userInfo: [NSLocalizedDescriptionKey: "Błąd obliczania początku miesiąca"]))
            return
        }

        var healthData: [(Date, Double)] = []

        var currentDate = startOfMonth
        let group = DispatchGroup()

        // Pętla do pobierania danych przez ostatni miesiąc
        while currentDate <= now {
            let startOfDay = calendar.startOfDay(for: currentDate)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

            let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)

            let query = HKStatisticsQuery(quantityType: healthDataType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, error in
                defer {
                    group.leave()
                }

                if let error = error {
                    print("Błąd podczas zapytania o dane: \(error.localizedDescription)")
                    return
                }

                if let statistics = statistics, let sum = statistics.sumQuantity()?.doubleValue(for: .kilocalorie()) {
                    // Dostosowanie w zależności od typu danych
                    let value: Double
                    switch dataType {
                    case .activeEnergyBurned:
                        value = sum // Dla kalorii
                    case .stepCount:
                        value = sum // Dla liczby kroków
//                    case .sleepAnalysis:
//                        // Zakładając, że sleepAnalysis zwraca czas w minutach
//                        value = sum
                    default:
                        value = 0.0
                    }

                    healthData.append((startOfDay, value))
                } else {
                    print("Brak danych dla dnia: \(currentDate)")
                }
            }

            healthStore.execute(query)
            group.enter()

            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        // Po zakończeniu wszystkich zapytań
        group.notify(queue: .main) {
            print("Dane dla wykresu \(chartTitle): \(healthData)")
            completion(healthData, nil)
        }
    }
    
    enum HealthDataUnit {
        case kilocalories
        case steps
        case distanceMeters

        // Metoda zwracająca odpowiednią jednostkę dla HealthKit
        func unit() -> HKUnit {
            switch self {
            case .kilocalories:
                return .kilocalorie()
            case .steps:
                return .count()
            case .distanceMeters:
                return .meter()
            }
        }
    }
    
    func fetchDataForChart(title: String, type: HKQuantityTypeIdentifier, completion: @escaping ([(Date, Double)], Error?) -> Void) {
        guard let dataType = HKObjectType.quantityType(forIdentifier: type) else {
            completion([], NSError(domain: "com.example.HealthKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "Typ danych \(type) jest niedostępny"]))
            return
        }
        
        var unit: HKUnit {
            switch type {
            case .activeEnergyBurned:
                .kilocalorie()
            case .stepCount:
                    .count()
            default:
                    .count()
            }
        }

        let now = Date()
        let calendar = Calendar.current
        guard let startOfMonth = calendar.date(byAdding: .month, value: -1, to: now) else {
            completion([], NSError(domain: "com.example.HealthKit", code: 2, userInfo: [NSLocalizedDescriptionKey: "Błąd obliczania początku miesiąca"]))
            return
        }

        var chartData: [(Date, Double)] = []

        var currentDate = startOfMonth
        let group = DispatchGroup() // Do synchronizacji asynchronicznych zapytań

        while currentDate <= now {
            let startOfDay = calendar.startOfDay(for: currentDate)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

            let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)

            let query = HKStatisticsQuery(quantityType: dataType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, error in
                defer {
                    group.leave()
                }

                if let error = error {
                    print("Błąd podczas zapytania o dane dla \(type): \(error.localizedDescription)")
                    return
                }

                if let statistics = statistics, let sum = statistics.sumQuantity()?.doubleValue(for: unit) {
                    chartData.append((startOfDay, sum))
                } else {
                    print("Brak danych dla dnia: \(currentDate) i typu \(type)")
                }
            }

            healthStore.execute(query)
            group.enter()

            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        // Po zakończeniu wszystkich zapytań
        group.notify(queue: .main) {
            completion(chartData, nil)
        }
    }
    
    func fetchSleepDataForChart(completion: @escaping ([(Date, Double)], Error?) -> Void) {
        let healthStore = HKHealthStore()
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let calendar = Calendar.current
        
        // Oblicz daty początkową i końcową (ostatnie 30 dni)
        guard let startDate = calendar.date(byAdding: .day, value: -30, to: Date()) else {
            completion([], NSError(domain: "DateError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to calculate start date"]))
            return
        }
        let endDate = Date()
        
        // Tworzenie zakresu dni z przesunięciem dnia snu na 15:00
        var dateRange: [Date] = []
        var currentDate = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: startDate)!
        while currentDate < endDate {
            dateRange.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        var sleepData: [Date: Double] = [:] // Wynikowe dane z mapowaniem daty na czas snu
        let group = DispatchGroup() // Kontrola zadań
        
        for day in dateRange {
            group.enter()
            
            let nextDay = calendar.date(byAdding: .day, value: 1, to: day)!
            let predicate = HKQuery.predicateForSamples(withStart: day, end: nextDay, options: .strictStartDate)
            
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, results, error in
                guard error == nil else {
                    completion([], error)
                    return
                }
                
                // Sumowanie czasu snu z wielu rekordów dla tej samej daty
                if let samples = results as? [HKCategorySample] {
                    let totalSleep = samples
                        .filter { $0.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue }
                        .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) } / 3600 // Konwersja na godziny
                    
                    sleepData[day, default: 0.0] += totalSleep
                } else {
                    sleepData[day, default: 0.0] += 0 // Brak danych = 0
                }
                
                group.leave()
            }
            
            healthStore.execute(query)
        }
        
        // Zakończenie zadań
        group.notify(queue: .main) {
            let sortedData = sleepData
                .map { ($0.key, $0.value) }
                .sorted(by: { $0.0 < $1.0 }) // Sortowanie według daty
            completion(sortedData, nil)
        }
    }
    
    func fetchBodyMassData(completion: @escaping (Double, Error?) -> Void) {
        guard let bodyMassType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            completion(0, NSError(domain: "com.example.HealthKit", code: 2, userInfo: [NSLocalizedDescriptionKey: "Błąd pobrania wagi użytkownika"]))
            return
        }
        let query = HKSampleQuery(sampleType: bodyMassType, predicate: nil, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { query, results, error in
            if let sample = results?.first as? HKQuantitySample {
                let bodyMass = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                completion(bodyMass, nil)
            } else if let error = error {
                print("Error fetching body mass: \(error)")
                completion(0, error)
            }
        }
        healthStore.execute(query)
    }
    
    func addBodyMassToHealthKit(weightInKilograms: Double, completion: @escaping(Bool, Error?) -> Void) {
        guard let bodyMassType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
                completion(false, NSError(domain: "HealthKit", code: 2, userInfo: [NSLocalizedDescriptionKey: "Body mass type is not available."]))
                return
            }
        
        let weightQuantity = HKQuantity(unit: HKUnit.gramUnit(with: .kilo), doubleValue: weightInKilograms)
        
        let now = Date()
        
        let bodyMassSample = HKQuantitySample(type: bodyMassType, quantity: weightQuantity, start: now, end: now)
        
        healthStore.save(bodyMassSample) { success, error in
            completion(success, error)
        }
    }

    func saveTraditionalStrengthWorkout(
        start: Date,
        duration: TimeInterval,
        completion: @escaping (Bool, Error?) -> Void
    ) {
        let end = TraditionalStrengthWorkout.endDate(start: start, duration: duration)
        let builder = HKWorkoutBuilder(
            healthStore: healthStore,
            configuration: TraditionalStrengthWorkout.configuration(),
            device: .local()
        )
        Task {
            do {
                try await builder.beginCollection(at: start)
                try await builder.endCollection(at: end)
            } catch {
                builder.discardWorkout()
                await MainActor.run { completion(false, error) }
                return
            }
            do {
                _ = try await builder.finishWorkout()
                await MainActor.run { completion(true, nil) }
            } catch {
                await MainActor.run { completion(false, error) }
            }
        }
    }
}
