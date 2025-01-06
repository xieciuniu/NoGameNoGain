//
//  StopwatchTests.swift
//  No Game No GainTests
//
//  Created by Hubert Wojtowicz on 06/01/2025.
//

import Testing
import Foundation
@testable import No_Game_No_Gain

struct StopwatchTests {
    
    @Test("Stopwatch should start from zero")
    func testInitialState() throws {
        let stopwatch = Stopwatch()
        
        stopwatch.stopFormattedTime()
        stopwatch.stopFormattedTimeMS()
        stopwatch.resetFormattedTime()
        stopwatch.resetFormattedTimeMS()
        
        #expect(stopwatch.timeElapsedHMS == 0)
        #expect(stopwatch.timeElapsedMSMs == 0)
        #expect(stopwatch.isRunning == false)
    }
    
    @Test("Stopwatch formatting should be correct")
    func testTimeFormatting() throws {
        let stopwatch = Stopwatch()
        
        // Ustawiamy konkretny czas do sprawdzenia formatowania
        stopwatch.timeElapsedHMS = 3661 // 1 godzina, 1 minuta, 1 sekunda
        #expect(stopwatch.formattedTime == "01:01:01")
        
        stopwatch.timeElapsedMSMs = 61.23 // 1 minuta, 1 sekunda, 23 setne
        #expect(stopwatch.formattedTimeMS == "01:01,23")
    }
    
    @Test("Stopwatch should properly handle start/stop operations")
    func testStartStopOperations() throws {
        let stopwatch = Stopwatch()
        
        stopwatch.stopFormattedTime()
        #expect(stopwatch.isRunning == false)
        
        stopwatch.startFormattedTime()
        #expect(stopwatch.isRunning == true)
        
        stopwatch.resetFormattedTime()
        #expect(stopwatch.timeElapsedHMS == 0)
    }
    
}
