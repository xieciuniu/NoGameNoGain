//
//  NoGameNoGainUITests.swift
//  NoGameNoGainUITests
//
//  Created by Hubert Wojtowicz on 08/01/2025.
//

import XCTest
@testable import No_Game_No_Gain

final class NoGameNoGainUITests: XCTestCase {
    func testPerformanceMetrics() {
        measure(metrics: [
            XCTCPUMetric(),
            XCTMemoryMetric(),
            XCTStorageMetric(),
            XCTClockMetric()
        ]) {
            let app = XCUIApplication()
            app.launch()
        }
    }
    
    let app = XCUIApplication()
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }
    
    func testBasicNavigationFlow() throws {
        // Test głównej nawigacji aplikacji
        let workoutCreatorButton = app.buttons["Workout Creator"]
        XCTAssertTrue(workoutCreatorButton.exists)
        workoutCreatorButton.tap()
        
        let backButton = app.buttons["Back"]
        XCTAssertTrue(backButton.exists)
        backButton.tap()
        
        let startWorkoutButton = app.buttons["Start Workout"]
        XCTAssertTrue(startWorkoutButton.exists)
    }
    
    func testWorkoutCreation() throws {
        // Test tworzenia nowego treningu
        app.buttons["Workout Creator"].tap()
        app.buttons["Create Workout"].tap()
        
        let workoutNameField = app.textFields["of workout"]
        XCTAssertTrue(workoutNameField.exists)
        workoutNameField.tap()
        workoutNameField.typeText("Test Workout")
        
        app.buttons["Add Exercise"].tap()
        
        let exerciseNameField = app.textFields.element(boundBy: 0)
        exerciseNameField.tap()
        exerciseNameField.typeText("Bench Press")
        
        XCTAssertTrue(app.buttons["Add"].exists)
    }
    
    func testStartWorkout() throws {
        // Test rozpoczynania treningu
        app.buttons["Start Workout"].tap()
        
        // Sprawdź czy pojawił się widok wyboru treningu
        XCTAssertTrue(app.navigationBars["Select Workout"].exists)
        
        // Wróć do głównego ekranu
        app.buttons["Back"].tap()
    }
    
    func testBodyWeightInput() throws {
        // Test wprowadzania wagi ciała
        let weightElement = app.scrollViews.firstMatch
            .descendants(matching: .any)
            .element(matching: .any, identifier: "Body Weight")
        
        XCTAssertTrue(weightElement.exists)
        weightElement.tap()
        
        // Sprawdź czy pojawił się picker
        let picker = app.pickers.firstMatch
        XCTAssertTrue(picker.exists)
    }
    
    func testExperienceProgressBar() throws {
        // Test widoku paska postępu doświadczenia
        let progressBar = app.progressIndicators.firstMatch
        XCTAssertTrue(progressBar.exists)
        
        // Sprawdź czy można przejść do widoku rang
        progressBar.tap()
        XCTAssertTrue(app.scrollViews.containing(.staticText, identifier: "Rookie Lifter").element.exists)
    }
    
    func testChallengeView() throws {
        // Test widoku wyzwań
        let challengeView = app.scrollViews.firstMatch
            .descendants(matching: .any)
            .element(matching: .any, identifier: "Challenge")
        
        XCTAssertTrue(challengeView.exists)
        
        // Sprawdź elementy widoku wyzwań
        XCTAssertTrue(app.staticTexts["Challenge"].exists)
        XCTAssertTrue(app.progressIndicators.firstMatch.exists)
    }
    
    func testWorkoutTimer() throws {
        // Test timera treningowego
        app.buttons["Start Workout"].tap()
        
        // Sprawdź czy istnieją jakiekolwiek komórki
        XCTAssertTrue(app.buttons.count > 0, "No workout cells found")
        
        // Kliknij pierwszą komórkę jeśli istnieje
        let firstWorkout = app.cells.element(boundBy: 0)
        XCTAssertTrue(firstWorkout.exists, "First workout cell does not exist")
        firstWorkout.tap()
            
        // Sprawdź czy timer jest widoczny
        let timerText = app.staticTexts.matching(identifier: "00:00:00").firstMatch
        XCTAssertTrue(timerText.exists)
            
        // Sprawdź przyciski kontrolne
        XCTAssertTrue(app.buttons["Done"].exists)
        XCTAssertTrue(app.buttons["Failed"].exists)
            
        // Zakończ trening
        app.buttons["End Workout"].tap()
    }
    
    func testHealthKitIntegration() throws {
        // Sprawdź czy są wyświetlane podstawowe statystyki
        XCTAssertTrue(app.staticTexts["Steps"].exists)
        XCTAssertTrue(app.staticTexts["Calories"].exists)
        XCTAssertTrue(app.staticTexts["Sleep"].exists)
    }
    
    func testPersonalGoalSetting() throws {
        // Test ustawiania celów personalnych
        let goalView = app.scrollViews.firstMatch
            .descendants(matching: .any)
            .element(matching: .any, identifier: "Weight Goal")
        
        XCTAssertTrue(goalView.exists)
        goalView.tap()
        
        // Sprawdź czy są dostępne oba typy celów
        XCTAssertTrue(app.buttons["Weight Goal"].exists)
        XCTAssertTrue(app.buttons["Strength Goal"].exists)
    }
    
    func testNavigationPathFlow() throws {
        // Test przepływu nawigacji w aplikacji
        app.buttons["Workout Creator"].tap()
        XCTAssertTrue(app.navigationBars["Workout Creator"].exists)
        
        app.buttons["Create Workout"].tap()
        XCTAssertTrue(app.navigationBars.firstMatch.exists)
        
        app.buttons["Back"].tap()
        app.buttons["Back"].tap()
        
        // Sprawdź czy wróciliśmy do głównego ekranu
        XCTAssertTrue(app.buttons["Start Workout"].exists)
    }
}
