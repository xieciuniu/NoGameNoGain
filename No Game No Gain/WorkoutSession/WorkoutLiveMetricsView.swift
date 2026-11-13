//
//  WorkoutLiveMetricsView.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 25/10/2026.
//

import SwiftUI

/// Heart rate and active energy while a Watch, AirPods, or Bluetooth monitor is tracking.
/// The workout screen leaves this out when no tracking device is present.
struct WorkoutLiveMetricsView: View {
    @Environment(WorkoutCoordinator.self) private var coordinator

    var body: some View {
        VStack(spacing: 2) {
            Text(heartRateText)
                .accessibilityLabel(heartRateAccessibility)
            Text(heartRateSummary)
                .accessibilityLabel(heartRateSummaryAccessibility)
            Text(energyText)
                .accessibilityLabel(energyAccessibility)
        }
        .font(.footnote)
        .foregroundStyle(.white)
    }

    private var heartRateText: String {
        guard let bpm = coordinator.heartRateBPM else { return "— bpm" }
        return "\(Int(bpm.rounded())) bpm"
    }

    private var energyText: String {
        guard let energy = coordinator.activeEnergyKilocalories else { return "— kcal" }
        return "\(Int(energy.rounded())) kcal"
    }

    private var heartRateSummary: String {
        "avg \(bpmText(coordinator.averageHeartRateBPM)) · max \(bpmText(coordinator.maximumHeartRateBPM))"
    }

    private var heartRateAccessibility: String {
        guard let bpm = coordinator.heartRateBPM else { return "Heart rate unavailable" }
        return "Heart rate \(Int(bpm.rounded())) beats per minute"
    }

    private var heartRateSummaryAccessibility: String {
        "Average heart rate \(spokenBPM(coordinator.averageHeartRateBPM)). Highest heart rate \(spokenBPM(coordinator.maximumHeartRateBPM))."
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
        guard let energy = coordinator.activeEnergyKilocalories else { return "Active energy unavailable" }
        return "Active energy \(Int(energy.rounded())) kilocalories"
    }
}
