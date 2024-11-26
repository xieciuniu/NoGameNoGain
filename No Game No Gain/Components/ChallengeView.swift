//
//  ChallengeView.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 25/11/2024.
//

import SwiftUI

struct ChallengeView: View {
    var body: some View {
        VStack {
            HStack {
                Text("Challenge")
                    .font(.title)
                Spacer()
                
                Text(Image(systemName: "timer")).font(.caption)
                +
                Text(" 5d 4h")
                    .font(.caption)
            }
            
            HStack{
                
                Image("badge")
                    .resizable()
                    .scaledToFit()
                    .clipShape(Circle())
                VStack(alignment: .leading) {
                    Text("Lift a total of 5t")
                        .foregroundStyle(.secondary)
                    
                    ProgressView(value: 3000, total: 5000)
                    HStack {
                        Text("0")
                        Spacer()
                        Text("5t")
                    }
                    .foregroundStyle(.secondary)
                    
                }
            }
        }
        .padding()
        .frame(height: 150)
        .background(Color(red: 26/255, green: 26/255, blue: 26/255))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    ChallengeView()
        .preferredColorScheme(.dark)
}
