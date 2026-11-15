//
//  TodayActivitiesView.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 07/08/2024.
//

import SwiftUI
import HealthKit

struct TodayActivitiesView: View {
    @Binding var userAccount: UserAccount

    private let healthKitManager = HealthKitManager.shared
    @State private var stepsToday: Double?
    @State private var burnedCalories: Double?
    @State private var sleepTime: Double?
    @State private var stepsFailed = false
    @State private var caloriesFailed = false
    @State private var sleepFailed = false

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            NavigationLink(value: ActivityKind.steps) {
                card(
                    kind: .steps,
                    value: readingText(value: stepsToday, failed: stepsFailed, kind: .steps),
                    icon: nil,
                    iconColor: .green
                )
            }
            .buttonStyle(.plain)

            NavigationLink(value: ActivityKind.calories) {
                card(
                    kind: .calories,
                    value: readingText(value: burnedCalories, failed: caloriesFailed, kind: .calories),
                    icon: "flame.fill",
                    iconColor: .red
                )
            }
            .buttonStyle(.plain)

            NavigationLink(value: ActivityKind.sleep) {
                card(
                    kind: .sleep,
                    value: readingText(value: sleepTime, failed: sleepFailed, kind: .sleep),
                    icon: "moon.fill",
                    iconColor: .blue
                )
            }
            .buttonStyle(.plain)
        }
        .onAppear(perform: fetchHealthData)
    }

    private func card(kind: ActivityKind, value: String, icon: String?, iconColor: Color) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .foregroundStyle(iconColor)
                }
                Text(value)
                    .font(.title3)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            Text(kind.title)
                .font(.headline)
                .lineLimit(1)
            if let goal = ActivityGoals.goalLabel(kind, account: userAccount) {
                Text(goal)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, minHeight: 150)
        .background(Color(red: 26/255, green: 26/255, blue: 26/255))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .foregroundStyle(.primary)
    }

    private func readingText(value: Double?, failed: Bool, kind: ActivityKind) -> String {
        guard let value, !failed else { return "—" }
        if kind == .sleep {
            return ActivityGoals.clock(minutes: value)
        }
        return ActivityGoals.numberText(value)
    }

    private func fetchHealthData() {
        guard HKHealthStore.isHealthDataAvailable() else {
            stepsToday = nil
            burnedCalories = nil
            sleepTime = nil
            stepsFailed = true
            caloriesFailed = true
            sleepFailed = true
            return
        }

        healthKitManager.fetchStepCount(date: Date()) { steps, error in
            DispatchQueue.main.async {
                if error != nil {
                    stepsFailed = true
                    stepsToday = nil
                } else {
                    stepsFailed = false
                    stepsToday = steps ?? 0
                }
            }
        }

        healthKitManager.fetchCaloriesBurned(date: Date.now) { calories, error in
            DispatchQueue.main.async {
                if error != nil {
                    caloriesFailed = true
                    burnedCalories = nil
                } else {
                    caloriesFailed = false
                    burnedCalories = calories ?? 0
                }
            }
        }

        Task {
            do {
                let minutes = try await healthKitManager.fetchLastSleepDuration()
                sleepFailed = false
                sleepTime = minutes
            } catch {
                sleepFailed = true
                sleepTime = nil
            }
        }
    }
}

#Preview {
    @Previewable @State var userAccount = UserAccount()
    NavigationStack {
        TodayActivitiesView(userAccount: $userAccount)
    }
    .preferredColorScheme(.dark)
}
