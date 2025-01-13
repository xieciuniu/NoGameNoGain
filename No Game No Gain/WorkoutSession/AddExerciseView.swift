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
    @State private var numberOfSets: Int = 3
    @State private var addPermanently: Bool = true
    @State private var weight: Double = 60
    @State private var reps: Int = 5
    @State private var progress: Bool = true
    
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
                    
                    Stepper("Sets: \(numberOfSets)", value: $numberOfSets, in: 1...10)
                }
                
                Section("Set Details") {
                    HStack {
                        Text("Weight:")
                        Spacer()
                        TextField("60", value: $weight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("kg")
                    }
                    
                    Stepper("Reps: \(reps)", value: $reps, in: 1...30)
                    
                    Toggle("Progressive Overload", isOn: $progress)
                }
                
//                Section {
//                    Toggle("Add to workout template", isOn: $addPermanently)
//                }
                
                Button("Add Exercise") {
                    let sets = [OneSet(reps: reps, weight: weight, progress: progress)]
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
}
