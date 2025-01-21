//
//  HomeScreenView.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 07/08/2024.
//

import SwiftUI
import SwiftData
import HealthKit

struct HomeScreenView: View {
    @State var path = NavigationPath()
    @Binding var isSession: Bool
    @Query var workouts: [WorkoutSession]
    
    @State private var totalWorkouts: Int = 0
    @State private var totalDuration: String = ""
    @State private var totalLifted: Double = 0.0
    
    @State var userAccount: UserAccount = loadUserAccountFromFile() ?? UserAccount()
    
    @State var expToTextUI: Double = 400
    
    @Environment(\.modelContext) var modelContext
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                VStack{

                    ScrollView{
                        ProgressBarView(exp: expToTextUI)
                            .padding([.horizontal, .bottom])
                            .onTapGesture {
                                path.append("LevelsView")
                            }
                                    
                        Spacer()
                        
                        if HKHealthStore.isHealthDataAvailable() {
                            TodayActivitiesView()
                                .padding([.bottom])
                                .padding(.horizontal)
                        }
                        
                        ChallengeView()
                            .padding([.horizontal, .bottom])
                        
                        BodyWeightAndPersonalGoalView(path: $path, userAccount: $userAccount )
                            .padding([.horizontal, .bottom])
                            .onAppear(perform: {
                                userAccount = loadUserAccountFromFile() ?? UserAccount()
                            })
                            .onTapGesture {
                                userAccount = loadUserAccountFromFile() ?? UserAccount()
                            }
                        
                        
                        
//                        Text("End Goal: \(userAccount.goalEnd.formatted())")
//                        Text("Progress: \(userAccount.goalProgress.formatted())")
//                        Text("User weight: \(userAccount.weight.formatted())")
//                            .padding(.bottom, 25)
                        
                        
                        
//                        Section ("placeholder"){
//                            Section("Workout Data") {
//                                HStack {
//                                    Text("Total workouts: \(totalWorkouts)")
//                                    Spacer()
//                                    Text("Total duration: " + totalDuration)
//                                    Spacer()
//                                    Text("Total lifted weight: \(totalLifted.formatted())kg")
//                                }
//                            }
//                            .padding([.leading, .trailing])
//                            .onAppear(){
//                                getData()
//                            }
//                            
//                            Button("Add 100 exp") {
//                                expToTextUI += 100
//                                userAccount.exp += 100
//                                saveUserAccountToFile(userAccount)
//                            }
//                            
//                            Button("Minus 100 exp") {
//                                expToTextUI -= 100
//                                userAccount.exp -= 100
//                                saveUserAccountToFile(userAccount)
//                            }
//                            
//                            //                    NavigationLink(
//                            
//                            Button(action: { deleteSessions() } ) { Text("Delete all sessions")}
//                            
//                            Text(workouts.count.description)
//                            
//                            List {
//                                ForEach(workouts){ session in
//                                    HStack {
//                                        Text(session.workout.name)
//                                        Text(session.duration.formatted())
//                                    }
//                                    
//                                }
//                                .onDelete(perform: { offsets in
//                                    for index in offsets {
//                                        let sesseionToRemove = workouts[index]
//                                        modelContext.delete(sesseionToRemove)
//                                    }
//                                    
//                                })
//                            }
//                        }
                        
                        LastWorkoutAndStatsView(path: $path)
                            .padding([.horizontal, .bottom])

                    }
                    
                    
                    
                    Divider()
                    
                    HStack {
                        Button(action: {
                            userAccount.exp += 100
                            path.append("StatsView")} ) {
                            Text("Settings")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        Spacer()
                        Divider()
                            .frame(height: 35)
                        
                        Button(action: { path.append("MyWorkoutsView")}) {
                            Text("Workout Creator")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        Spacer()
                        Divider()
                            .frame(height: 35)
                        
                        Button(action: { path.append("SelectWorkoutView")}) {
                            Text("Start Workout")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    
                }
            }
            .onAppear(perform: {
                HealthKitManager.shared.requestAuthorizationIfNeeded { success, error in
                    if success {
                        print("Authorization gained")
                    } else {
                        print("Error: \(String(describing: error))")
                    }
                }
            })
            .navigationDestination(for: String.self) { destination in
                switch destination {
                case "MyWorkoutsView":
                    MyWorkoutsView(path: $path)
                case "SelectWorkoutView":
                    SelectWorkoutView(isSession: $isSession)
                case "StatsView":
                    //History(endedSession: workouts)
                    TrainingStatsView()
                case "LevelsView":
                    LevelsView(level: userAccount.exp)
                case "PersonalGoalView":
                    PersonalGoalView(userAccount: $userAccount)
                case "WorkoutHistory":
                    WorkoutHistoryView()
                case "WorkoutStats":
                    TrainingStatsView()
                default:
                    Text("Some kind of error")
                    
                }
            }
            .navigationDestination(for: Workout.self) { workout in
                CreateWorkoutView(workout: workout, path: $path)
            }
            .navigationDestination(for: Exercise.self) { exercise in
                CreateExerciseView(exercise: exercise)
            }
        }
    }
    func deleteSessions() {
        do {
            try modelContext.delete(model: WorkoutSession.self)
        } catch {
            print("error deleting sessions")
        }
    }
    func getData() {
        totalLifted = workouts.reduce(0) { $0 + $1.totalWeight() }
        totalWorkouts = workouts.count
        let totaltime = workouts.reduce(0) { $0 + $1.duration }
        let hours = Int(totaltime) / 3600
        let minutes = (Int(totaltime) % 3600) / 60
        let seconds = Int(totaltime) % 60
        totalDuration = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
}

//#Preview {
//    HomeScreenView()
//}
