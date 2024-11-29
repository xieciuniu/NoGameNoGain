//
//  PersonalGoalView.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 24/11/2024.
//

import SwiftUI
import SwiftData

struct PersonalGoalView: View {
    private let possibleGoals = ["Weight Goal", "Strength Goal"]
    @State var goal: String = "Weight Goal"
    @Binding var userAccount: UserAccount
    //= loadUserAccountFromFile() ?? UserAccount()
    @State var goalWeight: Double = 82
    
    @Query var exercises: [Exercise]
    @State var chosenExercise: Exercise?
    @State var strengthGoal: Double = 0
    @State var strengthGoalInt: Int = 0
    let strengthGoalPicker = Array(stride(from: 0, through: 10000, by: 25)) + [610]
    
    var body: some View {
        VStack {
            Picker("", selection: $goal) {
                ForEach(possibleGoals, id: \.self) { goal in
                    Text(goal)
                }
            }
            .pickerStyle(.segmented)
            .padding(.bottom)
//            .onTapGesture(perform: { print(userAccount.goal)})
            List {
                if goal == "Weight Goal" {
                    HStack {
                        Text("Current weight:")
                        Spacer()
                        Text("\(userAccount.weight.formatted(.number))")
                    }
                    Text("Aimed weight: ")
                    
                } else if goal == "Strength Goal"{
                    HStack {
                        Text("Choose exercise")
                        Spacer()
                        
                        Picker("", selection: $chosenExercise) {
                            Text("").tag(nil as Exercise?)
                            ForEach(exercises) { exercise in
                                Text(exercise.name).tag(exercise as Exercise?)
                            }
                        }
                    }
                    .padding(.vertical, 5)
                    
                    if let exercise = chosenExercise {
                        HStack {
                            Text("Exercise best:")
                            Spacer()
                            Text("\((exercise.personalBestWeight ?? 0).formatted())kg")
                        }
                        
                        Text("Goal")
                        Picker("kg", selection: $strengthGoalInt) {
                            ForEach(strengthGoalPicker.sorted(), id: \.self) {
                                Text("\((Double($0)/10).formatted())")
                            }
                        }
                        .pickerStyle(.wheel)
                        
                        Text("New goal: \(strengthGoal.formatted())kg")
                        
                    }
                    
                    Button("Set goal") {
                        setGoal()
                    }
                }
            }
            
            Spacer()
        }
        .onAppear(perform: {
            goal = userAccount.goal
            chosenExercise = exercises.first(where: {$0.name == userAccount.strengthGoalExercise })
            strengthGoalInt = Int((chosenExercise?.personalBestWeight ?? 0) * 10)
        })
        .onChange(of: goal) { oldGoal, newGoal in
            userAccount.goal = newGoal
        }
        .onChange(of: chosenExercise) {
            userAccount.strengthGoalExercise = chosenExercise?.name
            saveUserAccountToFile(userAccount)
        }
        .onChange(of: strengthGoalInt) {old, new in
            strengthGoal = Double(new) / 10
        }
    }
    
    func setGoal() {
        if goal == "Strength Goal" {
            userAccount.goalStart = chosenExercise?.personalBestWeight ?? 0
            userAccount.goalProgress = chosenExercise?.personalBestWeight ?? 0
            userAccount.goalEnd = strengthGoal
        } else if goal == "Weight Goal" {
            userAccount.goalStart = userAccount.weight
            userAccount.goalEnd = goalWeight
        }
        
        saveUserAccountToFile(userAccount)
    }
}

#Preview {
    @Previewable @State var userAccount = UserAccount()
    PersonalGoalView(userAccount: $userAccount)
        .preferredColorScheme(.dark)
}
