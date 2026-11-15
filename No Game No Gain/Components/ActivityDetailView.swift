//
//  ActivityDetailView.swift
//  No Game No Gain
//

import SwiftUI
import Charts
import HealthKit

struct ActivityDetailView: View {
    let kind: ActivityKind
    @Binding var userAccount: UserAccount

    private let healthKitManager = HealthKitManager.shared

    @State private var today: Double?
    @State private var todayFailed = false
    @State private var todayLoaded = false
    @State private var bars: [(date: Date, value: Double)] = []
    @State private var barsFailed = false
    @State private var barsLoaded = false
    @State private var goalNumber = ""
    @State private var sleepHours = ""
    @State private var sleepMinutes = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                todaySection
                goalSection
                if let fraction = barFraction, let today, let goal = ActivityGoals.storedGoal(kind, account: userAccount) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Progress")
                            .font(.headline)
                        ProgressView(value: fraction)
                        Text(progressCaption(current: today, goal: goal))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                chartSection
            }
            .padding()
        }
        .navigationTitle(kind.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadGoalFields()
            loadHealth()
        }
    }

    private var barFraction: Double? {
        guard let today, todayLoaded, !todayFailed else { return nil }
        return ActivityGoals.progressFraction(
            current: today,
            goal: ActivityGoals.storedGoal(kind, account: userAccount)
        )
    }

    @ViewBuilder
    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today")
                .font(.headline)
            if !HKHealthStore.isHealthDataAvailable() || todayFailed {
                Text("Health data is not available.")
            } else if let today {
                Text(todayText(today))
                    .font(.title)
            } else {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var goalSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Goal")
                .font(.headline)
            switch kind {
            case .steps, .calories:
                TextField(kind == .steps ? "18000" : "Calories", text: $goalNumber)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
            case .sleep:
                HStack {
                    TextField("Hours", text: $sleepHours)
                        .keyboardType(.numbersAndPunctuation)
                        .textFieldStyle(.roundedBorder)
                    TextField("Minutes", text: $sleepMinutes)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                }
                Text("Hours and minutes, or a clock such as 7:05.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack {
                Button("Save", action: saveGoal)
                if kind != .steps {
                    Button("Clear", role: .destructive, action: clearGoal)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent")
                .font(.headline)
            if !HKHealthStore.isHealthDataAvailable() || barsFailed {
                Text("Health data is not available.")
            } else if !barsLoaded {
                ProgressView()
            } else if bars.isEmpty {
                Text(todayFailed ? "Health data is not available." : "No recent data.")
            } else {
                Chart {
                    ForEach(Array(bars.enumerated()), id: \.offset) { _, bar in
                        BarMark(
                            x: .value("Date", bar.date, unit: .day),
                            y: .value(chartValueName, bar.value)
                        )
                    }
                }
                .foregroundStyle(chartColor)
                .frame(height: 200)
                // Sleep bars from fetchSleepDataForChart are hours, not minutes.
                if kind == .sleep {
                    Text("Hours")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var chartValueName: String {
        switch kind {
        case .steps: "Steps"
        case .calories: "Calories"
        case .sleep: "Hours"
        }
    }

    private var chartColor: Color {
        switch kind {
        case .steps: .green
        case .calories: .red
        case .sleep: .blue
        }
    }

    private func todayText(_ value: Double) -> String {
        if kind == .sleep {
            return ActivityGoals.clock(minutes: value)
        }
        return ActivityGoals.numberText(value)
    }

    private func progressCaption(current: Double, goal: Double) -> String {
        switch kind {
        case .sleep:
            return "\(ActivityGoals.clock(minutes: current)) of \(ActivityGoals.clock(minutes: goal))"
        case .steps, .calories:
            return "\(ActivityGoals.numberText(current)) of \(ActivityGoals.numberText(goal))"
        }
    }

    private func loadGoalFields() {
        switch kind {
        case .steps:
            goalNumber = ActivityGoals.numberText(userAccount.stepGoal)
        case .calories:
            goalNumber = userAccount.calorieGoal.map(ActivityGoals.numberText) ?? ""
        case .sleep:
            if let goal = userAccount.sleepGoalMinutes {
                let fields = ActivityGoals.hourMinuteFields(minutes: goal)
                sleepHours = fields.hours
                sleepMinutes = fields.minutes
            } else {
                sleepHours = ""
                sleepMinutes = ""
            }
        }
    }

    private func saveGoal() {
        switch kind {
        case .steps:
            guard case .value(let value) = ActivityGoals.numberEdit(goalNumber, emptyClears: false) else {
                loadGoalFields()
                return
            }
            userAccount.stepGoal = value
        case .calories:
            switch ActivityGoals.numberEdit(goalNumber, emptyClears: true) {
            case .value(let value):
                userAccount.calorieGoal = value
            case .clear:
                userAccount.calorieGoal = nil
            case .invalid:
                loadGoalFields()
                return
            }
        case .sleep:
            switch ActivityGoals.sleepEdit(hoursText: sleepHours, minutesText: sleepMinutes) {
            case .value(let minutes):
                userAccount.sleepGoalMinutes = minutes
            case .clear:
                userAccount.sleepGoalMinutes = nil
            case .invalid:
                loadGoalFields()
                return
            }
        }
        persistAccount()
    }

    private func clearGoal() {
        switch kind {
        case .calories:
            userAccount.calorieGoal = nil
        case .sleep:
            userAccount.sleepGoalMinutes = nil
        case .steps:
            return
        }
        persistAccount()
    }

    private func persistAccount() {
        saveUserAccountToFile(userAccount)
        if let saved = loadUserAccountFromFile() {
            userAccount = saved
        }
        loadGoalFields()
    }

    private func loadHealth() {
        today = nil
        todayFailed = false
        todayLoaded = false
        bars = []
        barsFailed = false
        barsLoaded = false

        guard HKHealthStore.isHealthDataAvailable() else {
            todayFailed = true
            todayLoaded = true
            barsFailed = true
            barsLoaded = true
            return
        }

        switch kind {
        case .steps:
            healthKitManager.fetchStepCount(date: Date()) { steps, error in
                DispatchQueue.main.async {
                    applyToday(steps, error: error)
                }
            }
            healthKitManager.fetchDataForChart(title: "", type: .stepCount) { data, error in
                DispatchQueue.main.async {
                    applyBars(data, error: error)
                }
            }
        case .calories:
            healthKitManager.fetchCaloriesBurned(date: Date.now) { calories, error in
                DispatchQueue.main.async {
                    applyToday(calories, error: error)
                }
            }
            healthKitManager.fetchDataForChart(title: "", type: .activeEnergyBurned) { data, error in
                DispatchQueue.main.async {
                    applyBars(data, error: error)
                }
            }
        case .sleep:
            Task {
                do {
                    let minutes = try await healthKitManager.fetchLastSleepDuration()
                    todayFailed = false
                    today = minutes
                } catch {
                    todayFailed = true
                    today = nil
                }
                todayLoaded = true
            }
            healthKitManager.fetchSleepDataForChart { data, error in
                DispatchQueue.main.async {
                    applyBars(data, error: error)
                }
            }
        }
    }

    private func applyToday(_ value: Double?, error: Error?) {
        todayLoaded = true
        if error != nil {
            todayFailed = true
            today = nil
        } else {
            todayFailed = false
            today = value ?? 0
        }
    }

    private func applyBars(_ data: [(Date, Double)], error: Error?) {
        barsLoaded = true
        if error != nil {
            barsFailed = true
            bars = []
            return
        }
        barsFailed = false
        bars = data.map { (date: $0.0, value: $0.1) }.sorted { $0.date < $1.date }
    }
}

#Preview {
    @Previewable @State var userAccount = UserAccount()
    NavigationStack {
        ActivityDetailView(kind: .steps, userAccount: $userAccount)
    }
    .preferredColorScheme(.dark)
}
