//
//  HealthKitManager.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 16/11/2024.
//

import Foundation
import HealthKit

class HealthKitManager {
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()
    
    init() {}
    
    func requestAuthorizationIfNeeded(completion: @escaping (Bool, Error?) -> Void) {
        let readTypes: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.workoutType()
        ]
        let writeTypes: Set<HKSampleType> = [
            HKObjectType.workoutType()
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
}
