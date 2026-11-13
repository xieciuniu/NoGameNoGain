//
//  WatchWorkoutView.swift
//  No Game No Gain Watch App
//
//  Created by Hubert Wojtowicz on 25/10/2026.
//

import SwiftUI

struct WatchWorkoutView: View {
    let controller: WatchWorkoutController

    var body: some View {
        VStack(spacing: 8) {
            if controller.isSessionActive {
                restClock
                Text(controller.restTargetLabel)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(controller.restTargetAccessibility)
            } else {
                Text("Waiting for workout")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
            }
            Text(heartRateText)
                .font(.title3)
                .accessibilityLabel(heartRateAccessibility)
            Text(heartRateSummary)
                .font(.caption)
                .accessibilityLabel(heartRateSummaryAccessibility)
            Text(energyText)
                .font(.footnote)
                .accessibilityLabel(energyAccessibility)
        }
        .padding()
    }

    private var restClock: some View {
        TimelineView(.animation(minimumInterval: 0.01, paused: !controller.isRestClockRunning)) { context in
            Text(controller.restLabel(at: context.date))
                .font(.largeTitle)
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .accessibilityLabel(controller.restAccessibility(at: context.date))
                .accessibilityAddTraits(.updatesFrequently)
        }
    }

    private var heartRateText: String {
        guard let bpm = controller.heartRateBPM else { return "— bpm" }
        return "\(Int(bpm.rounded())) bpm"
    }

    private var energyText: String {
        guard let energy = controller.activeEnergyKilocalories else { return "— kcal" }
        return "\(Int(energy.rounded())) kcal"
    }

    private var heartRateSummary: String {
        "avg \(bpmText(controller.averageHeartRateBPM)) · max \(bpmText(controller.maximumHeartRateBPM))"
    }

    private var heartRateAccessibility: String {
        guard let bpm = controller.heartRateBPM else { return "Heart rate unavailable" }
        return "Heart rate \(Int(bpm.rounded())) beats per minute"
    }

    private var heartRateSummaryAccessibility: String {
        "Average heart rate \(spokenBPM(controller.averageHeartRateBPM)). Highest heart rate \(spokenBPM(controller.maximumHeartRateBPM))."
    }

    private func bpmText(_ value: Double?) -> String {
        guard let value else { return "—" }
        return "\(Int(value.rounded()))"
    }

    private func spokenBPM(_ value: Double?) -> String {
        guard let value else { return "unavailable" }
        return "\(Int(value.rounded())) beats per minute"
    }

    private var energyAccessibility: String {
        guard let energy = controller.activeEnergyKilocalories else { return "Active energy unavailable" }
        return "Active energy \(Int(energy.rounded())) kilocalories"
    }
}
