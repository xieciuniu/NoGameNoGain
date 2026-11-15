//
//  SelectWorkoutView.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 06/10/2024.
//

import SwiftUI
import SwiftData

struct SelectWorkoutView: View {
    @Environment(WorkoutCoordinator.self) private var coordinator
    @Query var workouts: [Workout]
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    @State private var showingAlert = false
    
    var body: some View {
        VStack{
            if workouts.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("You have no workouts yet.")
                        .padding(.horizontal)
                    Text("Set one up from a template.")
                        .padding(.horizontal)
                }
                List {
                    ForEach(WorkoutTemplates.catalog) { template in
                        NavigationLink(value: template) {
                            Text(template.name)
                        }
                    }
                }
            } else {
                List {
                    ForEach(workouts) { workout in
                        Button(action: {
                            if !workout.exercises.isEmpty {
                                selectedWorkout(workout)
                            } else {
                                showingAlert = true
                            }
                        }) {
                            Text(workout.name)
                        }
                    }
                }
            }
            Spacer()
            
            Divider()
            
            Button(action: {
                dismiss()
            }) {
                Text("Back")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .navigationTitle("Select Workout")
            .alert("This Workout is empty", isPresented: $showingAlert) {
                Button("OK", role: .cancel) {}
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    func selectedWorkout(_ workout: Workout) {
        coordinator.start(workout: workout, in: modelContext)
    }
}
