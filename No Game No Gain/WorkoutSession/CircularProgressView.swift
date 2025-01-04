//
//  CircularProgressView.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 04/01/2025.
//

import SwiftUI

struct CircularProgressView: View {
    let progress: Double
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.green.opacity(0.5), lineWidth: 5)
            if progress <= 1{
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        Color.green,
                        style: StrokeStyle(
                            lineWidth: 5,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(Angle(degrees: -90))
                    .animation(.easeInOut(duration: 0.5), value: progress)
            } else {
                Circle()
                    .stroke(
                        Color.red,
                        style: StrokeStyle(
                            lineWidth: 5,
                            lineCap: .round
                        )
                    )
            }
        }
    }
}

#Preview {
    CircularProgressView(progress: 0.5)
}
