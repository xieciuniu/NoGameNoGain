//
//  HistorySets.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 12/01/2025.
//

import SwiftUI

struct HistorySets: View {
    let session: WorkoutSession
    var body: some View {
        ForEach(session.doneSets) { set in
            HStack{
                Text("\(set.numberOfSet)")
                Text(set.exerciseName)
                Text("\(set.weight.formatted())kg x \(set.reps)")
            }
        }
    }
}

#Preview {
    let session = WorkoutSession(workout: Workout(name: "Test", exercise: []), startTime: Date.now)
    HistorySets(session: session)
}
