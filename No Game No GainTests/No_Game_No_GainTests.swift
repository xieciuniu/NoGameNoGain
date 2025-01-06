//
//  No_Game_No_GainTests.swift
//  No Game No GainTests
//
//  Created by Hubert Wojtowicz on 06/01/2025.
//

import Testing
@testable import No_Game_No_Gain

struct No_Game_No_GainTests {
    
    let userAccount = UserAccount()
    
    @Test("New user should start with 0 experience")
    func testInitialExperience() throws {
        #expect(userAccount.exp == 0)
    }
    
    @Test("User should have correct rank progression")
    func testRankProgression() async throws {
        let initialRank = ranks.first(where: { $0.expRange.contains(userAccount.exp) })
        #expect(initialRank?.title == "Rookie Lifter")
        
        userAccount.exp += 164
        let newRank = ranks.first(where: { $0.expRange.contains(userAccount.exp)})
        #expect(newRank?.title == "Gym Newbie")
    }
    
    @Test("Experience multiplier should work correctly")
    func testExpMultiplier() throws {
        // Sprawdzamy czy mnożnik exp działa prawidłowo
        userAccount.expMultiplier = 2.0
        let baseExp = 100.0
        let expectedExp = baseExp * userAccount.expMultiplier
        
        #expect(expectedExp == 200.0)
    }
    
    
    
}
