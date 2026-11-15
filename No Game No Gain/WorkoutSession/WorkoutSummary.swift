//
//  WorkoutSummary.swift
//  No Game No Gain
//

import SwiftData
import SwiftUI

struct EffortLevel: Identifiable, Equatable {
    let value: Int
    let title: String
    let detail: String
    var id: Int { value }

    static let all: [EffortLevel] = [
        EffortLevel(value: 1, title: "Rest", detail: "Almost no exertion. Breathing stays normal."),
        EffortLevel(value: 2, title: "Easy", detail: "You could keep going for a long time."),
        EffortLevel(value: 3, title: "Light", detail: "Comfortable. A full conversation is easy."),
        EffortLevel(value: 4, title: "Moderate", detail: "You are working, and you can still talk in sentences."),
        EffortLevel(value: 5, title: "Steady", detail: "A solid session. Talking takes a little effort."),
        EffortLevel(value: 6, title: "Challenging", detail: "Hard to hold a conversation. You are pushing."),
        EffortLevel(value: 7, title: "Hard", detail: "Only a few words at a time. This was a hard session."),
        EffortLevel(value: 8, title: "Very hard", detail: "Close to your limit. Another set would be a struggle."),
        EffortLevel(value: 9, title: "Near max", detail: "Almost everything you had. One more effort might fail."),
        EffortLevel(value: 10, title: "Maximum", detail: "Nothing left. This was an all-out session.")
    ]

    static func level(_ value: Int) -> EffortLevel {
        all.first { $0.value == value } ?? all[4]
    }

    static func lastEffort(in sessions: [WorkoutSession], workoutName: String) -> Int? {
        sessions
            .filter { $0.endTime != nil && $0.effort != nil && $0.workout.name == workoutName }
            .max { ($0.endTime ?? .distantPast) < ($1.endTime ?? .distantPast) }?
            .effort
    }
}

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
            experience: (base * multiplier).rounded(),
            planLines: lines
        )
    }
}

struct WorkoutSummaryView: View {
    let preview: WorkoutEndPreview
    @Binding var effort: Int
    var confirm: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Query private var sessions: [WorkoutSession]

    private var selected: EffortLevel { EffortLevel.level(effort) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("How hard was this?")
                        .font(.title2)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                        ForEach(EffortLevel.all) { level in
                            Button {
                                effort = level.value
                            } label: {
                                Text("\(level.value)")
                                    .font(.title2)
                                    .frame(maxWidth: .infinity)
                                    .frame(minHeight: 44)
                                    .background(
                                        effort == level.value ? Color.white : Color(red: 26 / 255, green: 26 / 255, blue: 26 / 255),
                                        in: RoundedRectangle(cornerRadius: 8)
                                    )
                                    .foregroundStyle(effort == level.value ? Color.black : Color.white)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Effort \(level.value), \(level.title). \(level.detail)")
                        }
                    }
                    Text(selected.title)
                        .font(.headline)
                    Text(selected.detail)
                        .foregroundStyle(.secondary)
                    if let previous = EffortLevel.lastEffort(in: sessions, workoutName: preview.workoutName) {
                        let previousLevel = EffortLevel.level(previous)
                        Text("Last time this workout was \(previousLevel.value) — \(previousLevel.title)")
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    Text(preview.workoutName)
                        .font(.title3)
                    LabeledContent("Duration", value: durationText)
                    LabeledContent("Volume", value: preview.volume.formatted())
                    LabeledContent("Done sets", value: "\(preview.doneCount)")
                    LabeledContent("Failed sets", value: "\(preview.failedCount)")
                    LabeledContent("Personal records", value: "\(preview.personalRecords)")
                    LabeledContent("Experience", value: "\(Int(preview.experience.rounded()))")
                    LabeledContent("Exercises", value: preview.exerciseNames.joined(separator: ", "))
                    ForEach(preview.planLines, id: \.self) { line in
                        Text(line)
                    }
                }
                .padding()
            }
            .navigationTitle("Summary")
            .navigationBarTitleDisplayMode(.inline)
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
