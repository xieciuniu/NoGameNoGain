//
//  ChallengeView.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 25/11/2024.
//

import SwiftData
import SwiftUI

struct ChallengeView: View {
    var userAccount: UserAccount

    @Query private var sessions: [WorkoutSession]
    @State private var challenge: ChallengeState?

    private var displayed: ChallengeState {
        challenge ?? ChallengeCycle.seededState(for: userAccount, now: Date())
    }

    private var target: Double {
        ChallengeCycle.shownTarget(previousGoal: displayed.previousGoal)
    }

    private var volume: Double {
        let inputs = sessions.map { session in
            ChallengeCycle.SessionVolume(
                endTime: session.endTime,
                sets: session.doneSets.map { ChallengeCycle.SetVolume(weight: $0.weight, reps: $0.reps) }
            )
        }
        return ChallengeCycle.volume(sessions: inputs, windowStart: displayed.windowStart)
    }

    var body: some View {
        VStack {
            HStack {
                Text("Challenge")
                    .font(.title)
                Spacer()

                Text(Image(systemName: "timer")).font(.caption)
                +
                Text(" \(ChallengeCycle.countdown(windowStart: displayed.windowStart, now: Date()))")
                    .font(.caption)
            }

            HStack {
                Image("badge")
                    .resizable()
                    .scaledToFit()
                    .clipShape(Circle())
                VStack(alignment: .leading) {
                    Text("Lift \(GoalProgress.formatKilograms(target)) kg")
                        .foregroundStyle(.secondary)

                    ProgressView(value: volume, total: target > 0 ? target : 1)
                    HStack {
                        Text(GoalProgress.formatKilograms(volume))
                        Spacer()
                        Text(GoalProgress.formatKilograms(target))
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .frame(height: 150)
        .background(Color(red: 26/255, green: 26/255, blue: 26/255))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onAppear(perform: refreshChallenge)
    }

    private func refreshChallenge() {
        let now = Date()
        var state = loadChallengeState() ?? ChallengeCycle.seededState(for: userAccount, now: now)
        state = ChallengeCycle.rolledForward(state, now: now)
        saveChallengeState(state)
        challenge = state
    }
}

#Preview {
    ChallengeView(userAccount: UserAccount())
        .modelContainer(for: [Workout.self, WorkoutSession.self], inMemory: true)
        .preferredColorScheme(.dark)
}
