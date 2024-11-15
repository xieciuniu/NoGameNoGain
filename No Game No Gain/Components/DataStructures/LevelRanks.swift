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
    let levels: Double
}

var ranks: [Ranks] = [
    Ranks(title: "Rookie Lifter", description: "A beginner who is just getting to know the equipment\nUnlocks basic exercises", levels: 0),
    Ranks(title: "Gym Newbie", description: "Learns correct technique\nBegins to attend the gym regularly", levels: 164),
    Ranks(title: "Gym Bro", description: "He knows the basic exercises\nTrains regularly and the first results are visible", levels: 271),
    Ranks(title: "Iron Warrior", description: "A solid training base\nGood knowledge of technique", levels: 448),
    Ranks(title: "Gains Master", description: "Expert in training planning\nImpressive physical form", levels: 738),
    Ranks(title: "Swole Legend", description: "Inspiration for others\nExcellent technique and knowledge", levels: 1218),
    Ranks(title: "Gym Beast", description: "Elite level of knowledge and experience\nMentor to others", levels: 2008),
    Ranks(title: "Gains God", description: "The highest level possible\nComplete physical transformation\nAuthority in the community", levels: 3311),
    Ranks(title: "Ultimate Beast", description: "nothing right now", levels: 5459),
    Ranks(title: "Gym Legend", description: "nothing right now", levels: 9001),
    Ranks(title: "Fitness Deity", description: "nothing right now", levels: 14841)
]

