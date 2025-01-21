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
    let levelTest = 5000.0
    var levelName: String {
        if let rank = ranks.first(where: {$0.expRange.contains(level)}) {
            return rank.title
        }
        else {
            return "Legend"
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
                            .blur(radius: levelTest >= rank.expStart ? 0 : 10)
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
