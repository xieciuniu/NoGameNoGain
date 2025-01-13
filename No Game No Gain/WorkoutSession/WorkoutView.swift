//
//  WorkoutView.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 8/21/24.
//

import SwiftUI
import SwiftData
import AVFoundation

struct WorkoutView: View {
    
    @StateObject private var viewModel: WorkoutViewModel
    
    
    @State private var showEnded = true
    
    @Binding var isSession: Bool
    
    @StateObject private var stopwatch = Stopwatch()
    
    init(isSession: Binding<Bool>, workoutSession: WorkoutSession) {
        _viewModel = StateObject(wrappedValue: WorkoutViewModel(workoutSession: workoutSession))
        self._isSession = isSession
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                    .onTapGesture {
                        self.hideKeyboard()
                    }
                
                VStack {
                    // timer of whole workout and note button
                    ZStack {
                        
                        VStack{
                            Text(viewModel.workoutSession.workout.name)
                            Text(stopwatch.formattedTime)
                                .onAppear {
                                   stopwatch.startFormattedTime()
                                   stopwatch.startFormattedTimeMS()
                                    viewModel.setWeightRepsSet()
                                }
                                .font(.title2)
                        }
                        
                        
                        HStack{
                            
                            Button(action: {
                                viewModel.showingAddExercise = true
                            }) {
                                Image(systemName: "plus.circle")
                                    .resizable()
                                    .frame(width: 25, height: 25)
                                    .foregroundStyle(Color.white)
                            }
                            .sheet(isPresented: $viewModel.showingAddExercise) {
                                AddExerciseView(
                                    isPresented: $viewModel.showingAddExercise,
                                    currentOrder: viewModel.currentExercise,
                                    workout: viewModel.workoutSession.workout
                                ) { exercise, permanent in
                                    viewModel.addExercise(exercise, permanent: permanent)
                                }
                            }

                            .padding(.leading)
                            
                            Spacer()
                            
                            NavigationLink {
                                VStack{
                                    
                                    TextField("Additional info about exercise", text: $viewModel.exerciseNotes, axis: .vertical)
                                        .textFieldStyle(.roundedBorder)
                                        .padding()
                                    
                                    TextField("Your notes", text: $viewModel.userAccount.notes , axis: .vertical)
                                        .textFieldStyle(.roundedBorder)
                                        .padding()
                                    
                                    Spacer()
                                }
                            } label: {
                                Image(systemName: "pencil.and.list.clipboard")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .foregroundStyle(Color.white)
                            }
                            .padding(.trailing)
                        }
                    }
                      
                        ZStack{
                            VStack {
                                Spacer()
                                // time between rests, put on clock
                                
                                Text(stopwatch.formattedTimeMS)
                                    .font(.system(size: stopwatch.timeElapsedMSMs > 3600 ? 72 : 92, weight: .ultraLight))
                                    .monospacedDigit()
                                Spacer()
                            }

                    }
                    
                    
                    
                    HStack {
                        Button(action: {
                            viewModel.setComplete(isDone: false, restTime: stopwatch.timeElapsedMSMs)
                            stopwatch.resetFormattedTimeMS()
                            stopwatch.stopFormattedTimeMS()
                            stopwatch.startFormattedTimeMS()
                            stopwatch.startFormattedTime()
                            print("failed")
                            
                        }) {
                            Circle()
                                .fill(Color.red.opacity(0.25))
                                .overlay(
                                    Text("Failed")
                                        .foregroundStyle(Color.red)
                                )
                                .frame(width: 80)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            viewModel.setComplete(isDone: true, restTime: stopwatch.timeElapsedMSMs)
                            
                            stopwatch.resetFormattedTimeMS()
                            stopwatch.stopFormattedTimeMS()
                            stopwatch.startFormattedTimeMS()
                            stopwatch.startFormattedTime()
                            print("done")
                        }) {
                            Circle()
                                .fill(Color.green.opacity(0.25))
                                .overlay(
                                    Text("Done")
                                        .foregroundStyle(Color.green)
                                )
                                .frame(width: 80)
                        }
                    }
                    .padding([.leading, .trailing], 15)
                    .padding(.top, -40)
                    
                    Spacer()
                    
                    VStack {
                        // następna seria
                        HStack {
                            
                            Text(viewModel.exerciseName)
                                .padding(.leading)
                            
                            Spacer()
                            
                            
                            
                            Text("Weight:")
                            TextField("Weight", value: $viewModel.currentWeight, format: .number)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.decimalPad)
                                .frame(width: 60)
                            //                        .padding(.trailing)
                            
                            Text("Reps:")
                            TextField("Reps", value: $viewModel.currentReps, format: .number)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                                .frame(width: 60)
                                .padding(.trailing)
                        }
                        
                        // TODO: create memory storage for notes
                        HStack {
                            Text(viewModel.exercise.exerciseNote)
                                .padding(.leading)
                            Spacer()
                            
                            HStack{
                                CircularProgressView(progress: viewModel.percentOfDoneSets())
                                    .frame(height: 15)
                                    .padding(.trailing)
                                
                                Button(action: { showEnded.toggle() }) {
                                    Image(systemName: showEnded ? "arrowshape.down" : "arrowshape.up" )
                                        .foregroundStyle(.white)
                                        .padding(.bottom)
                                }
                            }
                            .padding(.trailing)
                        }
                        
                        if showEnded {
                            ScrollView {
                                
                                ForEach(viewModel.workoutSession.doneSets.filter({ $0.exerciseName == viewModel.exerciseName }).sorted(by: { $0.numberOfSet > $1.numberOfSet })) { doneSet in
                                    HStack {
                                        var time: String {
                                            let minutes = Int(doneSet.restTime) / 60
                                            let seconds = Int(doneSet.restTime) % 60
                                            return String(format: "%02d:%02d", minutes, seconds)
                                        }
                                        Text("\(doneSet.numberOfSet).")
                                        Spacer()
                                        Text("Weight: \(doneSet.weight.formatted())")
                                        Text("Reps: \(doneSet.reps)")
                                        Text("Time: " + time)
//                                        Text("RPE: ")
                                    }
                                    Divider()
                                }
                                .padding([.leading, .trailing])
                                
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Divider()
                    
                    HStack {
                        
                        Button(action: {
                            print("previous")
                            viewModel.previousExercise()
                        }) {
                            Text("Previous Exercise")
                                .font(.subheadline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .foregroundColor(viewModel.currentExercise == 0 ? .gray : .white)
                                .cornerRadius(12)
                                .shadow(radius: 5)
                        }
                        .disabled(!viewModel.canMoveToPreviousExercise() )
                        
                        Spacer()
                        
                        Divider()
                            .frame(maxHeight: 60)
                        
                        Button(action: {
                            print("end")
                            stopwatch.resetFormattedTime()
                            stopwatch.resetFormattedTimeMS()
                            viewModel.workoutEnded(workoutDuration: stopwatch.timeElapsedHMS)
                            isSession = false
                            UserDefaults.standard.set(false, forKey: "isSession")
                            
                        }) {
                            Text("End Workout")
                                .font(.subheadline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)

                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        Spacer()
                        
                        Divider()
                            .bold()
                            .frame(maxHeight: 60)
                        
                        if stopwatch.isRunning {
                            Button(action: {
                                print("pause")
                                UserDefaults.standard.set(false, forKey: "isRunning")
                                stopwatch.stopFormattedTimeMS()
                                stopwatch.stopFormattedTime()                                
                            }) {
                                Text("Pause Workout")
                                    .font(.subheadline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        } else {
                            Button(action: {
                                print("resume")
                                UserDefaults.standard.set(true, forKey: "isRunning")
                               stopwatch.startFormattedTime()
                               stopwatch.startFormattedTimeMS()
                            }) {
                                Text("Resume Workout")
                                    .font(.subheadline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        
                        
                        Spacer()
                        
                        Divider()
                            .frame(maxHeight: 60)
                        
                        Button(action: {
                            viewModel.nextExercise()
                        }) {
                            Text("Next Exercise")
                                .font(.subheadline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                            //                                .background(Color.blue)
                                .foregroundStyle(viewModel.currentExercise == viewModel.workoutSession.workout.exercises.count - 1 ? .gray : .white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(!viewModel.canMoveToNextExercise() )
                    }
                    .padding([.leading, .trailing])
                    .onAppear(perform: {
                        viewModel.setWeightRepsSet()
                        viewModel.begin()
                    })
                    Spacer()
                }
                
            }
            
        }
        .onChange(of: viewModel.currentSet) {
            viewModel.setWeightRepsSet()
        }
        .onChange(of: viewModel.currentExercise) {
            viewModel.setWeightRepsSet()
        }
        .onChange(of: viewModel.exerciseNotes) {
            viewModel.updateExerciseNotes()
        }
        .onChange(of: stopwatch.timeElapsedMSMs) {old, new in
            if new >= viewModel.restTime && old <= viewModel.restTime {
                AudioServicesPlaySystemSound(1026)
            }
        }
        .onChange(of: viewModel.userAccount.notes) {
            saveUserAccountToFile(viewModel.userAccount)
        }
    }
}

struct HandView: View {
    var length: CGFloat
    var thickness: CGFloat
    var angle: Angle
    
    var body: some View {
        Rectangle()
            .fill(Color.white)
            .frame(width: thickness, height: length)
            .offset(y: -length / 2)
            .rotationEffect(angle)
    }
}

//#Preview {
//    WorkoutView(workoutStart: Date(timeIntervalSince1970: 1724827600))
//        .preferredColorScheme(.dark)
//}
