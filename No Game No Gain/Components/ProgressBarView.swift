//
//  ProgressBarView.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 07/08/2024.
//

import SwiftUI

struct ProgressBarView: View {
    var expCurrent: Double
    var level: Int
    var expToStartLevel: Double
    var expToNextLevel: Double
    var userRank: String
    
    var value: Double {
        return expCurrent - expToStartLevel
    }
    var total: Double {
        return expToNextLevel - expToStartLevel
    }
    
    var body: some View {
        VStack {
            // Ranga
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.orange, Color.red]), startPoint: .top, endPoint: .bottomTrailing)
                    .cornerRadius(15)
                    .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 5)
                
                Text(userRank)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black, radius: 2, x: 1, y: 1)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 150, height: 50) // Dostosowana wielkość ramki
            
            HStack {
                ZStack {
                    LinearGradient(gradient: Gradient(colors: [Color.purple, Color.blue]), startPoint: .center, endPoint: .bottomTrailing)
                        .cornerRadius(20)
                        .shadow(color: .black, radius: 10, x: 0, y: 10)
                    
                    VStack {
                        Text(String(level))
                            .font(.system(size: 30, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: .black, radius: 2, x: 2, y: 2)
                        
                        Text("Level")
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                    }
                }
                .frame(width: 80, height: 80)
                
                VStack {
                    Spacer()
                    ProgressView(value: value, total: total)
                        .progressViewStyle(LinearProgressViewStyle())
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                    Spacer()
                    
                    HStack {
                        Spacer()
                        Text("\(value.formatted()) / \(total.formatted()) XP")
                    }
                    Spacer()
                }
                .padding()
            }
            .frame(height: 100)
            .padding(.leading)
        }
    }
    init(exp: Double) {
        self.expCurrent = exp
        switch expCurrent {
        case _ where expCurrent > 14841:
            self.level = 11
            self.expToNextLevel = 99999
            expToStartLevel = 14841
            userRank = "Fitness Deity"
        case _ where expCurrent > 9001:
            self.level = 10
            self.expToNextLevel = 14841
            expToStartLevel = 9001
            userRank = "Gym Legend"
        case _ where expCurrent > 5459:
            self.level = 9
            self.expToNextLevel = 9001
            expToStartLevel = 5459
            userRank = "Ultimate Beast"
        case _ where expCurrent > 3311:
            self.level = 8
            self.expToNextLevel = 5459
            expToStartLevel = 3311
            userRank = "Gains God"
        case _ where expCurrent > 2008:
            self.level = 7
            self.expToNextLevel = 3311
            expToStartLevel = 2008
            userRank = "GymBeast"
        case _ where expCurrent > 1218:
            self.level = 6
            self.expToNextLevel = 2008
            expToStartLevel = 1218
            userRank = "Swole Legend"
        case _ where expCurrent > 738:
            self.level = 5
            self.expToNextLevel = 1218
            expToStartLevel = 738
            userRank = "Gains Master"
        case _ where expCurrent > 448:
            self.level = 4
            self.expToNextLevel = 738
            expToStartLevel = 488
            userRank = "Iron Warrior"
        case _ where expCurrent > 271:
            self.level = 3
            self.expToNextLevel = 488
            expToStartLevel = 271
            userRank = "Gym Bro"
        case _ where expCurrent > 164:
            self.level = 2
            self.expToNextLevel = 271
            expToStartLevel = 164
            userRank = "Gum Newbie"
        default:
            self.level = 1
            self.expToNextLevel = 164
            expToStartLevel = 0
            userRank = "Rookie Lifter"
        }
    }
}

#Preview {
    ProgressBarView(exp: 0.0)
}
