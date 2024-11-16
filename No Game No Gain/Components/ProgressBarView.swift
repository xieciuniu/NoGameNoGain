//
//  ProgressBarView.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 07/08/2024.
//

import SwiftUI

struct ProgressBarView: View {
    //let allRanks = ranks
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
        let allRanks = ranks
        if let rank = allRanks.first(where: {$0.expRange.contains(exp)}) {
            self.level = rank.level
            self.expToStartLevel = rank.expStart
            self.expToNextLevel = rank.expRange.upperBound
            self.userRank = rank.title
        }
        else {
            self.level = 0
            self.expToStartLevel = 0
            self.expToNextLevel = 0
            self.userRank = "Unknown"
        }
    }
}

#Preview {
    ProgressBarView(exp: 5)
}
