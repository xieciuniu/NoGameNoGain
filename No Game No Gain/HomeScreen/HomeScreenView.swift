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
    
    @State var expToTextUI: Double = 10
    
    @Environment(\.modelContext) var modelContext
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                VStack{
                    
                    //                    ProgressBarView()
                    
                    //                        ProgressBarView(exp: userAccount.exp)
                    //                            .foregroundStyle(.white)
                    //                            .onTapGesture {
                    //                                path.append("LevelsView")
                    //                            }
                    ScrollView{
                        ProgressBarView(exp: expToTextUI)
                        //                            .foregroundStyle(.white)
                            .padding([.horizontal, .bottom])
                            .onTapGesture {
                                path.append("LevelsView")
                            }
                        //                    }
                        
                        
                        
                        Spacer()
                        
                        if HKHealthStore.isHealthDataAvailable() {
                            TodayActivitiesView()
                                .padding([.horizontal, .bottom])
                        }
                        
                        BodyWeightAndPersonalGoalView()
                            .padding([.horizontal])
//                            .padding(.bottom, 25)
                        
                        Section("Workout Data") {
                            HStack {
                                Text("Total workouts: \(totalWorkouts)")
                                Spacer()
                                Text("Total duration: " + totalDuration)
                                Spacer()
                                Text("Total lifted weight: \(totalLifted.formatted())kg")
                            }
                        }
                        .padding([.leading, .trailing])
                        .onAppear(){
                            getData()
                        }
                        
                        Button("Add 100 exp") {
                            expToTextUI += 100
                            userAccount.exp += 100
                            saveUserAccountToFile(userAccount)
                        }
                        
                        Button("Minus 100 exp") {
                            expToTextUI -= 100
                            userAccount.exp -= 100
                            saveUserAccountToFile(userAccount)
                        }
                        
                        //                    NavigationLink(
                        
                        Button(action: { deleteSessions() } ) { Text("Delete all sessions")}
                        
                        Text(workouts.count.description)
                        
                        List {
                            ForEach(workouts){ session in
                                HStack {
                                    Text(session.workout.name)
                                    Text(session.duration.formatted())
                                }
                                
                            }
                            .onDelete(perform: { offsets in
                                for index in offsets {
                                    let sesseionToRemove = workouts[index]
                                    modelContext.delete(sesseionToRemove)
                                }
                                
                            })
                        }
                    }
                    
                    
                    
                    Divider()
                    
                    HStack {
                        Button(action: { path.append("StatsView")} ) {
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
                    Text("Hello, World!")
                case "LevelsView":
                    LevelsView(level: userAccount.exp)
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
        //        let allSets = workouts.reduce(0) { $0 + $1.weight }
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
