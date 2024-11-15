//
//  CreateExerciseView.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 9/19/24.
//

import SwiftUI

struct CreateExerciseView: View {
    @Environment(\.dismiss) var dismiss
    @Bindable var exercise: Exercise
    
    @State private var exerciseName = ""
    @State private var restTime: Int = 100
    @State private var progressPerWorkout: Double = 2.5
    @State private var numberOfSets: Int = 1
    
    @State private var sets: [OneSet] = [OneSet(reps: 5, weight: 60.6, progress: true)]
    
    // TODO: Muscle Groups
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                ZStack {
                    Color.black
                        .ignoresSafeArea()
                        .onTapGesture(perform: {
                            self.hideKeyboard()
                        })
                    
                    VStack {
                        HStack {
                            Text("Name:")
                            
                            TextField("", text: $exerciseName)
                                .textFieldStyle(.roundedBorder)
                                .padding(.leading)
                                .keyboardType(.default)
                        }
                        .padding([.leading, .trailing])
                        
                        HStack {
                            Text("Rest time (s): ")
                            TextField("", value: $exercise.restTime, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.numberPad)
                                .padding(.leading)
                        }
                        .padding([.leading, .trailing])
                        
                        HStack {
                            Text("Progress per workout: ")
                            
                            TextField("", value: $exercise.progressPerWorkout, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.decimalPad)
                            //                        .padding(.leading)
                        }
                        .padding([.leading, .trailing])
                        
                        Stepper("Number of different sets: \(exercise.numberOfSets)", value: $exercise.numberOfSets, in: 1...100, onEditingChanged: { _ in
                            updateSeries()
                        })
                        .padding([.leading, .trailing])
                        
                        
                        
                        VStack{
                            ForEach($exercise.sets) {$oneSet in
                                Section(header: Text("Set")) {
                                    Stepper("Number of reps: \(oneSet.reps)", value: $oneSet.reps, in: 1...1000)
                                    
                                    HStack {
                                        Text("Weight: ")
                                        Spacer()
                                        
//                                        TextField("", value: $oneSet.weight, format: .number)
//                                            .keyboardType(.decimalPad)
                                        DecimalTextField(value: $oneSet.weight)
                                        
                                    }
                                    
                                    Toggle(isOn: $oneSet.progress, label: {
                                        Text("Weekly progress")
                                    })
                                    
                                    Stepper("Sets like this: \(oneSet.numberOfSameSets)", value: $oneSet.numberOfSameSets, in: 1...1000)
                                }
                                .padding([.leading, .trailing])
                                
                            }
                        }
                        
                        Spacer()
                        Spacer()
                        
                        Divider()
                        Button(action: { 
                            dismiss()
                        }) {
                            Text("Add")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .foregroundStyle(.white)
                        }
                    }
                }
                .preferredColorScheme(.dark)
                .frame(minHeight: geometry.size.height)
                .onChange(of: exerciseName) {_, name in
                    exercise.name = name
                }
                .onAppear() {
                    exerciseName = exercise.name
                }
            }
            .navigationTitle(exercise.name)
        }
        .navigationBarBackButtonHidden()
    }
    
    private func updateSeries() {
        if exercise.numberOfSets > exercise.sets.count {
            //dodaj nowe serie
            for _ in exercise.sets.count..<exercise.numberOfSets {
                exercise.sets.append(OneSet(reps: exercise.sets.last?.reps ?? 5 , weight: exercise.sets.last?.weight ?? 60, progress: exercise.sets.last?.progress ?? true))
            }
        } else if exercise.numberOfSets < exercise.sets.count {
            exercise.sets.removeLast(exercise.sets.count - exercise.numberOfSets)
        }
    }
}

struct DecimalTextField: View {
    @Binding var value: Double
    @State private var textValue: String = ""

    var body: some View {
        TextField("", text: $textValue)
            .keyboardType(.decimalPad)
            .textFieldStyle(RoundedBorderTextFieldStyle())
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

//#Preview {
//    CreateExerciseView()
//}
