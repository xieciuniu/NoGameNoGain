//
//  HealthKitTests.swift
//  No Game No GainTests
//
//  Created by Hubert Wojtowicz on 06/01/2025.
//

import Testing
import Foundation
import HealthKit
@testable import No_Game_No_Gain

struct HealthKitTests {
    
    @Test("HealthKit should be available on device")
    func testHealthKitAvailability() throws {
        let isHealthKitAvailable = HKHealthStore.isHealthDataAvailable()
        #expect(isHealthKitAvailable == true)
    }
    
    @Test("HealthKit manager should initialize properly")
    func testHealthKitManagerInitialization() throws {
        let healthKitManager = HealthKitManager()
        #expect(healthKitManager !== nil)
    }
    
    @Test("HealthKit should have correct data types configured")
    func testHealthKitDataTypes() throws {
        _ = HealthKitManager()
        
        // Sprawdzamy czy manager jest skonfigurowany do obsługi wymaganych typów danych
        let bodyMassType = HKObjectType.quantityType(forIdentifier: .bodyMass)
        let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount)
        let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)
        
        #expect(bodyMassType != nil, "Body mass type should be available")
        #expect(stepCountType != nil, "Step count type should be available")
        #expect(activeEnergyType != nil, "Active energy type should be available")
    }
    
    @Test("HealthKit units should be correctly configured")
    func testHealthKitUnits() throws {
        // Sprawdzamy czy jednostki są poprawnie zdefiniowane
        let kilogramUnit = HKUnit.gramUnit(with: .kilo)
        let stepUnit = HKUnit.count()
        let calorieUnit = HKUnit.kilocalorie()
        
        #expect(kilogramUnit.description == "kg", "Weight unit should be kilograms")
        #expect(stepUnit.description == "count", "Step unit should be count")
        #expect(calorieUnit.description == "kcal", "Energy unit should be kilocalories")
    }
}
