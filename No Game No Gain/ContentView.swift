//
//  ContentView.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 31/07/2024.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var coordinator: WorkoutCoordinator
    @Query var workouts : [Workout]
    @Query(filter: #Predicate<WorkoutSession>{ session in
        session.endTime == nil
    }) var sessions : [WorkoutSession]
    @Environment(\.modelContext) var modelContext

    init() {
        let settings = NotificationSettings()
        let notifications = WorkoutNotificationManager(settings: settings)
        _coordinator = State(initialValue: WorkoutCoordinator(notifications: notifications))
    }
    
    var body: some View {
        Group {
            if let activeSession = sessions.first {
                WorkoutView(workoutSession: activeSession, notifications: coordinator.notifications)
            } else {
                HomeScreenView()
            }
        }
        .environment(coordinator)
        .onAppear {
            coordinator.notifications.installForegroundPresentation()
        }
        .onChange(of: sessions.map(\.persistentModelID)) {
            if !sessions.isEmpty {
                coordinator.resolveRecoveredCompanion(openWorkoutExists: true)
            }
        }
        .task(id: sessions.map(\.persistentModelID)) {
            await Task.yield()
            guard !Task.isCancelled else { return }
            coordinator.resolveRecoveredCompanion(openWorkoutExists: !sessions.isEmpty)
        }
    }
}

#Preview {
    ContentView()
}
