//
//  TemplateOnboardingView.swift
//  No Game No Gain
//

import SwiftData
import SwiftUI

struct TemplateOnboardingView: View {
    let template: WorkoutTemplate

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(WorkoutCoordinator.self) private var coordinator

    @State private var weights: [String]
    @State private var noWeight: [Bool]
    @State private var savedWorkout: Workout?

    init(template: WorkoutTemplate) {
        self.template = template
        _weights = State(initialValue: Array(repeating: "", count: template.exercises.count))
        _noWeight = State(initialValue: Array(repeating: false, count: template.exercises.count))
    }

    var body: some View {
        Group {
            if savedWorkout != nil {
                savedChoices
            } else {
                questions
            }
        }
        .navigationTitle(template.name)
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }

    private var questions: some View {
        VStack {
            List {
                ForEach(template.exercises.indices, id: \.self) { index in
                    Section {
                        TextField("Weight in kg", text: $weights[index])
                            .keyboardType(.decimalPad)
                            .onChange(of: weights[index]) { _, newValue in
                                let clean = sanitize(newValue)
                                if clean != newValue {
                                    weights[index] = clean
                                    return
                                }
                                if !clean.isEmpty {
                                    noWeight[index] = false
                                }
                            }
                        Button {
                            noWeight[index] = true
                            weights[index] = ""
                        } label: {
                            HStack {
                                Text("No weight yet")
                                Spacer()
                                if noWeight[index] {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        .buttonStyle(.borderless)
                    } header: {
                        Text("Step \(index + 1). \(template.exercises[index].name)")
                            .textCase(nil)
                    }
                }
            }

            Divider()

            Button(action: confirm) {
                Text("Confirm")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .foregroundStyle(.white)
            }
            .disabled(!canSave)
        }
    }

    private var savedChoices: some View {
        VStack(spacing: 16) {
            Text("\(template.name) is in your workouts.")
                .padding()
            Button(action: startSaved) {
                Text("Start")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .foregroundStyle(.white)
            }
            Button(action: { dismiss() }) {
                Text("Leave it in the list")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .foregroundStyle(.white)
            }
            Spacer()
        }
    }

    private var canSave: Bool {
        template.exercises.indices.allSatisfy { index in
            noWeight[index] || weight(from: weights[index]) != nil
        }
    }

    private func confirm() {
        let answers: [TemplateWeightAnswer] = template.exercises.indices.map { index in
            if noWeight[index] {
                return .noWeightYet
            }
            return .weight(weight(from: weights[index]) ?? 0)
        }
        let workout = WorkoutTemplates.makeWorkout(from: template, answers: answers)
        modelContext.insert(workout)
        savedWorkout = workout
    }

    private func startSaved() {
        guard let savedWorkout else { return }
        coordinator.start(workout: savedWorkout, in: modelContext)
    }

    private func sanitize(_ raw: String) -> String {
        var result = ""
        var separator = false
        for character in raw {
            if character.isNumber {
                result.append(character)
            } else if (character == "." || character == ",") && !separator {
                result.append(character)
                separator = true
            }
        }
        return result
    }

    private func weight(from text: String) -> Double? {
        var normalized = text.replacingOccurrences(of: ",", with: ".")
        if normalized.hasSuffix(".") {
            normalized.removeLast()
        }
        guard let value = Double(normalized), value.isFinite, value >= 0 else { return nil }
        return value
    }
}
