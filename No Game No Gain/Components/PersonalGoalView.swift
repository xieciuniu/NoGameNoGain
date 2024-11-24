//
//  PersonalGoalView.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 24/11/2024.
//

import SwiftUI

struct PersonalGoalView: View {
    private let possibleGoals = ["Weight Goal", "Strength Goal"]
    @State var userAccount: UserAccount = loadUserAccountFromFile() ?? UserAccount()
    var body: some View {
        VStack {
            Picker("", selection: $userAccount.goal) {
                ForEach(possibleGoals, id: \.self) { goal in
                    Text(goal)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

#Preview {
    PersonalGoalView()
        .preferredColorScheme(.dark)
}
