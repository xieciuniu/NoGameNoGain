//
//  ContentView.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 31/07/2024.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var isSession = UserDefaults.standard.bool(forKey: "isSession")
    @Query var workouts : [Workout]
    @Query(filter: #Predicate<WorkoutSession>{ session in
        session.endTime == nil
    }) var sessions : [WorkoutSession]
    @Environment(\.modelContext) var modelContext
    
    var body: some View {
        if let activeSession = sessions.first, isSession {
            WorkoutView(isSession: $isSession, workoutSession: activeSession)
        } else {
            HomeScreenView(isSession: $isSession)
        }
    }
}

#Preview {
    ContentView()
}
