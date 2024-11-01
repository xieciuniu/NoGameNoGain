//
//  LevelsView.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 01/11/2024.
//

import SwiftUI

struct LevelsView: View {
    var body: some View {
        Form {
            VStack {
                HStack{
                    Text("Level 1")
                    Spacer()
                }
                    
                
                HStack{
                    Spacer()
                    Text("Gym Rat")
                        .font(.title)
                        .fontWeight(.bold)
                    Spacer()
                }
                
                HStack{
                    Text("he own gym")
                    Spacer()
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    LevelsView()
}
