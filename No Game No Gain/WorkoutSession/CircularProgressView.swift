//
//  CircularProgressView.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 04/01/2025.
//

import SwiftUI

struct CircularProgressView: View {
    let progress: Double
    var color: Color {
        switch progress {
        case 0.0 ..< 0.5:
            return .yellow
        case 0.5 ..< 1:
            return .green
        case 1:
            return .blue
        default:
            return .red
        }
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.5), lineWidth: 5)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(
                            lineWidth: 5,
                            lineCap: .round
                    )
                )
                .rotationEffect(Angle(degrees: -90))
                .animation(.easeInOut(duration: 0.5), value: progress)
        }
    }
}

#Preview {
    CircularProgressView(progress: 0.5)
}
