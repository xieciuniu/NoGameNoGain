//
//  AddExerciseView.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 13/01/2025.
//

import SwiftUI

struct AddExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var isPresented: Bool
    
    let currentOrder: Int
    let workout: Workout
    
    @State private var exerciseName: String = ""
    @State private var restTime: Double = 90
    @State private var numberOfSets: Int = 1
    @State private var addPermanently: Bool = false
    @State private var sets: [OneSet] = [OneSet(reps: 5, weight: 60, progress: false)]
    
    let onAdd: (Exercise, Bool) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section("Exercise Details") {
                    TextField("Exercise Name", text: $exerciseName)
                    
                    HStack {
                        Text("Rest Time:")
                        Spacer()
                        TextField("90", value: $restTime, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("seconds")
                    }
                    
                    Stepper("Number of different sets: \(numberOfSets)",
                           value: $numberOfSets,
                           in: 1...10,
                           onEditingChanged: { _ in
                        updateSeries()
                    })
                }
                
                Section("Sets Configuration") {
                    ForEach($sets) { $oneSet in
                        VStack(alignment: .leading, spacing: 10) {
                            Stepper("Number of reps: \(oneSet.reps)",
                                   value: $oneSet.reps,
                                   in: 1...30)
                            
                            HStack {
                                Text("Weight:")
                                Spacer()
                                DecimalTextFieldBonus(value: $oneSet.weight)
                                Text("kg")
                            }
                            
                            Toggle("Progressive Overload", isOn: $oneSet.progress)
                            
                            Stepper("Sets like this: \(oneSet.numberOfSameSets)",
                                   value: $oneSet.numberOfSameSets,
                                   in: 1...10)
                        }
                    }
                }
                
//                Section {
//                    Toggle("Add to workout template", isOn: $addPermanently)
//                }
                
                Button("Add Exercise") {
                    let exercise = Exercise(name: exerciseName, order: currentOrder + 1)
                    exercise.restTime = restTime
                    exercise.numberOfSets = numberOfSets
                    exercise.sets = sets
                    
                    onAdd(exercise, addPermanently)
                    dismiss()
                }
                .disabled(exerciseName.isEmpty)
            }
            .navigationTitle("Add Exercise")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
        }
    }
    
    private func updateSeries() {
        if numberOfSets > sets.count {
            // Dodaj nowe serie
            for _ in sets.count..<numberOfSets {
                sets.append(OneSet(
                    reps: sets.last?.reps ?? 5,
                    weight: sets.last?.weight ?? 60,
                    progress: sets.last?.progress ?? true
                ))
            }
        } else if numberOfSets < sets.count {
            sets.removeLast(sets.count - numberOfSets)
        }
    }
}

struct DecimalTextFieldBonus: View {
    @Binding var value: Double
    @State private var textValue: String = ""

    var body: some View {
        TextField("", text: $textValue)
//            .background(Color.gray)
            .keyboardType(.decimalPad)
            .textFieldStyle(.automatic)
            .onChange(of: textValue) { oldValue, newValue in
                            let filtered = newValue.replacingOccurrences(of: ",", with: ".")
                            if let number = Double(filtered) {
                                value = number
                            }
                        }
            .onAppear {
                // Ustaw początkowy tekst na wartość początkową Double
                textValue = String(value).replacingOccurrences(of: ".", with: ",")
            }
    }
}
