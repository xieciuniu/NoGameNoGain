//
//  MyWorkoutsView.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 9/19/24.
//

import SwiftUI
import SwiftData

enum TrainingFrequency: String, CaseIterable, Identifiable {
    case dayOfWeek, everyXDays
    var id: Self { self }
}

struct MyWorkoutsView: View {
    @Binding var path: NavigationPath
    @Query var workouts: [Workout]
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    @State private var trainingFrequency: TrainingFrequency = .dayOfWeek
    
    var body: some View {
        VStack {
            VStack {
                
//                Picker("Select Workout frequency", selection: $trainingFrequency) {
//                    Text("Day of week").tag(TrainingFrequency.dayOfWeek)
//                    Text("Every X Days").tag(TrainingFrequency.everyXDays)
//                }
//                .pickerStyle(.segmented)
//                .padding()
                
                // TODO: ustawienie kolejnosc treningow
                
                HStack {
                    Text("Your Workouts")
                        .bold()
                        .font(.title2)
                    Spacer()
                }
                .padding(.leading)
                
                List{
                    ForEach(workouts) { workout in
                        Button(action: { path.append(workout)}) {
                            Text(workout.name)
                                .foregroundStyle(.white)
                                .bold()
                        }
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            let workoutToRemove = workouts[index]
                            modelContext.delete(workoutToRemove)
                        }
                    }
                }
                
                
                Spacer()
                Spacer()
                
                Divider()
                
                HStack {
                    
//                    Button(action: {dismiss()}) {
//                        Text("Back")
//                            .frame(maxWidth: .infinity)
//                            .padding(.vertical, 8)
//                            .foregroundStyle(.white)
//                    }
//                    
//                    Spacer()
//                    Divider()
//                        .frame(height: 35)
                    
                    Button(action: addWorkout) {
                        Text("Create Workout")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .foregroundStyle(.white)
                        
                    }
                }
            }
            .navigationTitle("Workout Creator")
//            .navigationDestination(for: Workout.self) { workout in
//                CreateWorkoutView(workout: workout, path: $path)
//            }
//            .navigationDestination(for: Exercise.self) { exercise in
//                CreateExerciseView(exercise: exercise)
//            }
            
        }
        .preferredColorScheme(.dark)
    }
    
    func addWorkout() {
        let newWorkout = Workout(name: "New Workout", exercise: [])
        modelContext.insert(newWorkout)
        path.append(newWorkout)
        
        print(newWorkout.name)
    }
}

//#Preview {
//    MyWorkoutsView()
//}
