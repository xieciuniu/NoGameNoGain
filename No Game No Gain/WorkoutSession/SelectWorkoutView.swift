//
//  SelectWorkoutView.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 06/10/2024.
//

import SwiftUI
import SwiftData
import AVFoundation

struct SelectWorkoutView: View {
    @Binding var isSession: Bool
    @Query var workouts: [Workout]
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack{
            List {
                ForEach(workouts) { workout in
                    Button(action: {
                        selectedWorkout(workout)
                    }) {
                        Text(workout.name)
                        Text(workout.id.uuidString)
                    }
                }
            }
            Spacer()
            
            Divider()
            
            Button(action: {
                dismiss()
                AudioServicesPlaySystemSound(1026)
            }) {
                Text("Back")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .navigationTitle("Select Workout")
        }
        .navigationBarBackButtonHidden(true)
    }
    
    func selectedWorkout(_ workout: Workout) {
        UserDefaults.standard.set(true , forKey: "isSession")
        isSession = true
        
        let workoutSession = WorkoutSession(workout: workout, startTime: Date())
        modelContext.insert(workoutSession)
    }
}

//#Preview {
//    SelectWorkoutView()
//}
