//
//  WorkoutSummary.swift
//  No Game No Gain
//

import SwiftUI

struct WorkoutEndPreview: Equatable {
    var workoutName: String
    var duration: TimeInterval
    var exerciseNames: [String]
    var doneCount: Int
    var failedCount: Int
    var volume: Double
    var personalRecords: Int
    var experience: Double
    var planLines: [String]

    static func make(
        session: WorkoutSession,
        account: UserAccount,
        duration: TimeInterval
    ) -> WorkoutEndPreview {
        let experienceSystem = ExperienceSystem()
        let base = experienceSystem.calculateWorkoutXP(
            duration: duration,
            setCount: session.doneSets.count,
            newRecords: session.personalRecords
        )
        let savedWeek = account.weeklyWorkouts
        let multiplier = experienceSystem.calculateXPMultiplier(userAccount: account)
        account.weeklyWorkouts = savedWeek
        let changes = WorkoutCompletion().progressionChanges(for: session)
        let lines = changes.isEmpty ? ["The plan did not change."] : changes.map(\.line)
        return WorkoutEndPreview(
            workoutName: session.workout.name,
            duration: duration,
            exerciseNames: session.workout.exercises.map(\.name),
            doneCount: session.doneSets.filter(\.isDone).count,
            failedCount: session.doneSets.filter { !$0.isDone }.count,
            volume: session.doneSets.reduce(0) { $0 + $1.weight * Double($1.reps) },
            personalRecords: session.personalRecords,
            experience: base * multiplier,
            planLines: lines
        )
    }
}

struct WorkoutSummaryView: View {
    let preview: WorkoutEndPreview
    @Binding var effort: Int
    var confirm: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(preview.workoutName)
                    Text(durationText)
                    Text("Volume \(preview.volume.formatted())")
                    Text("Personal records \(preview.personalRecords)")
                    Text("Experience \(preview.experience.formatted())")
                }
                Section("Exercises") {
                    ForEach(preview.exerciseNames, id: \.self) { name in
                        Text(name)
                    }
                    Text("Done \(preview.doneCount)")
                    Text("Failed \(preview.failedCount)")
                }
                Section("Plan") {
                    ForEach(preview.planLines, id: \.self) { line in
                        Text(line)
                    }
                }
                Section("Effort") {
                    Picker("Effort", selection: $effort) {
                        ForEach(1...10, id: \.self) { value in
                            Text("\(value)").tag(value)
                        }
                    }
                }
            }
            .navigationTitle("Summary")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Dismiss", action: dismiss.callAsFunction)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm", action: confirm)
                }
            }
        }
    }

    private var durationText: String {
        let minutes = Int(preview.duration) / 60
        let seconds = Int(preview.duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
