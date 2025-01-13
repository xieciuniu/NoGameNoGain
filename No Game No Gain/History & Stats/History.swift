//
//  History.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 12/01/2025.
//

import SwiftUI

struct History: View {
    let endedSession: [WorkoutSession]
    var body: some View {
        Form {
            ForEach(endedSession.sorted(by: { $0.startTime > $1.startTime })) { session in
                Section (header: Text("\(session.workout.name) - \(session.startTime.formatted())")) {
                    
                    HistorySets(session: session)
                }
            }
        }
    }
}

#Preview {
    let workoutSession: WorkoutSession = WorkoutSession(workout: Workout(name: "test", exercise: []), startTime: Date.now)
    History(endedSession: [workoutSession])
}
