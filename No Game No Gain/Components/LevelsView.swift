//
//  LevelsView.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 01/11/2024.
//

import SwiftUI

struct LevelsView: View {
    let levels = ranks
    @State var level: Double
    var levelName: String {
        switch level {
        case _ where level > 14841:
            return "Fitness Deity"
        case _ where level > 9001:
            return "Gym Legend"
        case _ where level > 5459:
            return "Ultimate Beast"
        case _ where level > 3311:
            return "Gains God"
        case _ where level > 2008:
            return "GymBeast"
        case _ where level > 1218:
            return "Swole Legend"
        case _ where level > 738:
            return "Gains Master"
        case _ where level > 448:
            return "Iron Warrior"
        case _ where level > 271:
            return "Gym Bro"
        case _ where level > 164:
            return "Gum Newbie"
        default:
            return "Rookie Lifter"
        }
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            VStack {
                    ScrollView{
                        ForEach(ranks.reversed()) { rank in
                            VStack {
                                HStack{
                                    Spacer()
                                    Text(rank.title)
                                        .font(.title)
                                        .fontWeight(.bold)
                                    Spacer()
                                }
                                .padding(.bottom, 10)
                                
                                HStack{
                                    Text(rank.description)
                                    Spacer()
                                }
                            }
                            .id(rank.title)
                            .blur(radius: level >= rank.levels ? 0 : 10)
                            Divider()
                        }
                    }

            }
            .padding()
            .preferredColorScheme(.dark)
            .onAppear {
                withAnimation {
                    proxy.scrollTo(levelName, anchor: .bottom)
                }
            }
        }
    }
}

#Preview {
    LevelsView(level: 400)
}
