//
//  PersonalGoalView.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 24/11/2024.
//

import SwiftUI
import SwiftData

struct PersonalGoalView: View {
    private let possibleGoals = ["Weight Goal", "Strength Goal"]
    @Binding var userAccount: UserAccount
    @Query var exercises: [Exercise]

    @State private var goal = "Weight Goal"
    @State private var chosenExercise: Exercise?
    @State private var targetText = ""
    @State private var didRestore = false

    var body: some View {
        VStack {
            Picker("Choose goal", selection: $goal) {
                ForEach(possibleGoals, id: \.self) { goal in
                    Text(goal)
                }
            }
            .pickerStyle(.segmented)
            .padding(.bottom)

            Form {
                if GoalProgress.hasActiveGoal(userAccount) && GoalProgress.isReached(userAccount) {
                    Text("Done. Set the next target.")
                }

                if goal == "Weight Goal" {
                    HStack {
                        Text("Current weight")
                        Spacer()
                        Text("\(GoalProgress.formatKilograms(userAccount.weight)) kg")
                    }
                    targetSection(start: userAccount.weight, kind: .weight)
                } else if goal == "Strength Goal" {
                    HStack {
                        Text("Choose exercise")
                        Spacer()
                        Picker("", selection: $chosenExercise) {
                            Text("").tag(nil as Exercise?)
                            ForEach(exercises) { exercise in
                                Text(exercise.name).tag(exercise as Exercise?)
                            }
                        }
                    }
                    .padding(.vertical, 5)

                    if let exercise = chosenExercise {
                        HStack {
                            Text("Exercise best")
                            Spacer()
                            Text("\(GoalProgress.formatKilograms(exercise.personalBestWeight ?? 0)) kg")
                        }
                        targetSection(
                            start: exercise.personalBestWeight ?? 0,
                            kind: .strength(exerciseName: exercise.name)
                        )
                    }
                }

                Button("Set goal") {
                    setGoal()
                }

                if GoalProgress.hasActiveGoal(userAccount) {
                    Button("Clear goal", role: .destructive) {
                        clearGoal()
                    }
                }
            }

            Spacer()
        }
        .onAppear(perform: restoreEditor)
        .onChange(of: exercises.count) {
            restoreEditor()
        }
    }

    @ViewBuilder
    private func targetSection(start: Double, kind: GoalKind) -> some View {
        Section("Target") {
            TextField("Target", text: $targetText)
                .keyboardType(.decimalPad)
        }
        if let target = GoalProgress.parseTarget(targetText) {
            Text(GoalProgress.directionSentence(kind: kind, start: start, target: target))
        }
    }

    private func restoreEditor() {
        if !didRestore {
            if userAccount.goal == "Strength Goal" {
                goal = "Strength Goal"
            }
            if GoalProgress.hasActiveGoal(userAccount) {
                targetText = GoalProgress.formatKilograms(userAccount.goalEnd)
            }
            didRestore = true
        }
        if chosenExercise == nil {
            chosenExercise = exercises.first { $0.name == userAccount.strengthGoalExercise }
        }
    }

    private func setGoal() {
        guard let target = GoalProgress.parseTarget(targetText) else { return }
        if goal == "Strength Goal" {
            guard let exercise = chosenExercise else { return }
            GoalProgress.applySet(
                userAccount,
                kind: .strength(exerciseName: exercise.name),
                current: exercise.personalBestWeight ?? 0,
                target: target
            )
        } else {
            GoalProgress.applySet(
                userAccount,
                kind: .weight,
                current: userAccount.weight,
                target: target
            )
        }
        saveAccount()
    }

    private func clearGoal() {
        GoalProgress.applyClear(userAccount)
        targetText = ""
        saveAccount()
    }

    private func saveAccount() {
        saveUserAccountToFile(userAccount)
        if let saved = loadUserAccountFromFile() {
            userAccount = saved
        }
    }
}

#Preview {
    @Previewable @State var userAccount = UserAccount()
    PersonalGoalView(userAccount: $userAccount)
        .preferredColorScheme(.dark)
}
