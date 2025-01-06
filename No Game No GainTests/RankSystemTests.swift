//
//  RankSystemTests.swift
//  No Game No GainTests
//
//  Created by Hubert Wojtowicz on 06/01/2025.
//

import Testing
import Foundation
@testable import No_Game_No_Gain

struct RankSystemTests {
    
    @Test("Ranks should be properly ordered")
    func testRankOrdering() throws {
        // Sprawdzanie czy rangi są ułożone we właściwej kolejności
        for i in 0..<(ranks.count - 1) {
            #expect(ranks[i].expStart < ranks[i + 1].expStart,
                    "Każda kolejna ranga powinna mieć wyższy próg doświadczenia")
            #expect(ranks[i].level < ranks[i + 1].level,
                    "Każda kolejna ranga powinna mieć wyższy poziom")
        }
    }
    
    @Test("Rank ranges should not overlap")
    func testRankRanges() throws {
        // Sprawdzanie czy zakresy rang nie nachodzą na siebie
        for i in 0..<(ranks.count - 1) {
            let currentRangeEnd = ranks[i].expRange.upperBound
            let nextRangeStart = ranks[i + 1].expRange.lowerBound
            
            #expect(currentRangeEnd == nextRangeStart,
                    "Zakresy rang powinny być ciągłe")
        }
    }
    
    @Test("Each rank should have valid description")
    func testRankDescriptions() throws {
        // Sprawdzanie czy każda ranga ma poprawny opis
        for rank in ranks {
            #expect(!rank.title.isEmpty, "Tytuł rangi nie może być pusty")
            #expect(!rank.description.isEmpty, "Opis rangi nie może być pusty")
            #expect(rank.expStart >= 0, "Początek zakresu musi być nieujemny")
        }
    }
    
    @Test("First rank should start from zero")
    func testFirstRank() throws {
        let firstRank = ranks.first
        #expect(firstRank?.expStart == 0, "Pierwsza ranga powinna zaczynać się od 0 exp")
        #expect(firstRank?.title == "Rookie Lifter", "Pierwsza ranga powinna być 'Rookie Lifter'")
        #expect(firstRank?.level == 1, "Pierwsza ranga powinna być poziomem 1")
    }
    
}
