//
//  LevelRanks.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 02/11/2024.
//

import Foundation

struct Ranks: Identifiable {
    var id = UUID()
    var title: String
    var description: String
    let expStart: Double
    let expRange: Range<Double>
    let level: Int
}

var ranks: [Ranks] = [
    Ranks(title: "Rookie Lifter", description: "A beginner who is just getting to know the equipment\nUnlocks basic exercises", expStart: 0, expRange: (0 ..< 164), level: 1),
    Ranks(title: "Gym Newbie", description: "Learns correct technique\nBegins to attend the gym regularly", expStart: 164, expRange: 164..<271, level: 2),
    Ranks(title: "Gym Bro", description: "He knows the basic exercises\nTrains regularly and the first results are visible", expStart: 271, expRange: 271..<448, level: 3),
    Ranks(title: "Iron Warrior", description: "A solid training base\nGood knowledge of technique", expStart: 448, expRange: 448..<738, level: 4),
    Ranks(title: "Gains Master", description: "Expert in training planning\nImpressive physical form", expStart: 738, expRange: 738..<1218, level: 5),
    Ranks(title: "Swole Legend", description: "Inspiration for others\nExcellent technique and knowledge", expStart: 1218, expRange: 1218..<2008, level: 6),
    Ranks(title: "Gym Beast", description: "Elite level of knowledge and experience\nMentor to others", expStart: 2008, expRange: 2008..<3311, level: 7),
    Ranks(title: "Gains God", description: "The highest level possible\nComplete physical transformation\nAuthority in the community", expStart: 3311, expRange: 3311..<5459, level: 8),
    Ranks(title: "Ultimate Beast", description: "nothing right now", expStart: 5459, expRange: 5459..<9001, level: 9),
    Ranks(title: "Gym Legend", description: "nothing right now", expStart: 9001, expRange: 9001..<14841, level: 10),
    Ranks(title: "Fitness Deity", description: "nothing right now", expStart: 14841, expRange: 14841..<999999, level: 11)
]

