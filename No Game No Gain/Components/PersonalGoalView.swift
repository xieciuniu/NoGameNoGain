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
    
    @Query var exercises: [Exercise]
    @State var chosenExercise: Exercise?
    @State var strengthGoal: Double = 0
    @State var strengthGoalInt: Int = 0
    @State var strengthGoalPicker: [Int] = []
    @State var weightGoalPicker = Array(stride(from: 300, through: 2000, by: 1))
    @State var weightGoalInt: Int = 20
    @State var weightGoal: Double = 0
    
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
            Form {
                if goal == "Weight Goal" {
                    HStack {
                        Text("Current weight:")
                        Spacer()
                        Text("\(userAccount.weight.formatted())")
                    }
                        
                    Section("Goal"){
                        Picker("Goal", selection: $weightGoalInt) {
                            ForEach(weightGoalPicker, id: \.self) {
                                Text("\((Double($0)/10).formatted())")
                            }
                        }
                        .pickerStyle(.wheel)
                    }
                    Text("\(weightGoal.formatted())")
                    Button("Set goal") {
                        setGoal()
                    }
                    
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
                        
                        Section("Goal"){
                            Picker("", selection: $strengthGoalInt) {
                                ForEach(strengthGoalPicker.sorted(), id: \.self) {
                                    Text("\((Double($0)/10).formatted())")
                                }
                            }
                            .pickerStyle(.wheel)
                        }
                        
                        //Testing
//                        Text("New goal: \(strengthGoal.formatted())kg")
                        
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
            strengthGoalPicker = Array(stride(from: 0 , through: 10000, by: 25)).filter({ $0 > strengthGoalInt})
            weightGoalInt = Int((userAccount.weight) * 10)
            
        })
        .onChange(of: chosenExercise) {
            userAccount.strengthGoalExercise = chosenExercise?.name
            strengthGoalInt = Int((chosenExercise?.personalBestWeight ?? 0) * 10)
            strengthGoalPicker = Array(stride(from: 0 , through: 10000, by: 25)).filter({ $0 > strengthGoalInt})
        }
        .onChange(of: strengthGoalInt) {old, new in
            strengthGoal = Double(new) / 10
        }
        .onChange(of: weightGoalInt) { old, new in
            weightGoal = Double(new) / 10
        }
    }
    
    func setGoal() {
        if goal == "Strength Goal" {
            userAccount.goalStart = chosenExercise?.personalBestWeight ?? 0
            userAccount.goalProgress = chosenExercise?.personalBestWeight ?? 0
            userAccount.goalEnd = strengthGoal
        } else if goal == "Weight Goal" {
            userAccount.goalStart = userAccount.weight
            userAccount.goalEnd = weightGoal
            userAccount.goalProgress = userAccount.weight
        }
        userAccount.goal = goal
        saveUserAccountToFile(userAccount)
    }
}

#Preview {
    @Previewable @State var userAccount = UserAccount()
    PersonalGoalView(userAccount: $userAccount)
        .preferredColorScheme(.dark)
}
