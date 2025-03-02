//
//  No_Game_No_GainApp.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 31/07/2024.
//

import SwiftUI
import SwiftData

@main
struct No_Game_No_GainApp: App {
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
            
        }
        .modelContainer(for: [Workout.self, WorkoutSession.self])
    }
}
