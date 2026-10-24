//
//  RestClockView.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 21/10/2026.
//

import SwiftUI

/// Rest clock. Updates with the display, capped at 0.01s, without rebuilding the workout screen.
struct RestClockView: View {
    var stopwatch: Stopwatch

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.01, paused: !stopwatch.isRunningMSMs)) { context in
            let elapsed = stopwatch.restElapsed(at: context.date)
            Text(Stopwatch.formatRestTime(elapsed))
                .font(.system(size: elapsed > 3600 ? 72 : 92, weight: .ultraLight))
                .monospacedDigit()
                .accessibilityAddTraits(.updatesFrequently)
        }
    }
}
