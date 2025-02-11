//
//  CreateWorkoutView.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 9/19/24.
//

import SwiftUI

struct CreateWorkoutView: View {
    @Environment(\.dismiss) var dismiss
    @Bindable var workout: Workout
    @Binding var path: NavigationPath
    @Environment(\.modelContext) var modelContext
    
    @State private var name = ""
    
    var body: some View {
        VStack {
            VStack{
                
                HStack {
                    Text("Name:")
                    
                    TextField("of workout", text: $name)
                        .textFieldStyle(.roundedBorder)
                }
                .padding()
                
                HStack {
                    Text("Exercises")
                        .bold()
                        .font(.title2)
                    Spacer()
                }
                .padding([.leading])
                
                List {
                    ForEach(workout.exercises.sorted()){ exercise in
                        
                        HStack{
                            Text(exercise.name /*+ " | \(exercise.order)"*/)
                                .foregroundStyle(.white)
                            Spacer()
                            Image(systemName: "line.3.horizontal")
                        }
//                        .padding([.leading, .trailing])
                        .onTapGesture {
                            path.append(exercise)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let exerciseToRemove = workout.exercises.sorted(by: { $0.order < $1.order })[index]
                            modelContext.delete(exerciseToRemove)
                            if let removeIndex = workout.exercises.firstIndex(of: exerciseToRemove) {
                                workout.exercises.remove(at: removeIndex)
                            }
                        }
                    }
                    .onMove(perform: move)
                }
                
//                Divider()
//                
//                Button(action: addExercise) {
//                    Text("Add Exercise")
//                        .foregroundStyle(.white)
//                        .frame(maxWidth: .infinity)
//                        .padding(.vertical, 8)
//                }
                
                Spacer()
                
                Divider()
                
                HStack {
//                    Button(action: {dismiss()}) {
//                        Text("Back")
//                            .frame(maxWidth: .infinity)
//                            .padding(.vertical, 8)
//                            .foregroundStyle(.white)
//                            .clipShape(RoundedRectangle(cornerRadius: 12))
//                    }
//                    
//                    Spacer()
//                    Divider()
//                        .frame(height: 35)
                    
                    Button(action: addExercise) {
                        Text("Add Exercise")
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                
            }
            .navigationTitle(workout.name)
//            self.navigationBar.tintColor = Color.white
        }
        .preferredColorScheme(.dark)
        .onChange(of: name){_, name in
            workout.name = name
        }
        .onAppear(perform: {
            name = workout.name
        })
    }
    
    func addExercise() {
        let newExercise = Exercise(name: "", order: (workout.exercises.sorted().last?.order ?? -1) + 1 )
        modelContext.insert(newExercise)
        workout.exercises.append(newExercise)
        path.append(newExercise)
    }
    
    func move(from source: IndexSet, to destination: Int) {
        var s = workout.exercises.sorted(by: { $0.order < $1.order})
        s.move(fromOffsets: source, toOffset: destination)
        
        for (index, item) in s.enumerated() {
            item.order = index
        }
        try? self.modelContext.save()
    }
}

//#Preview {
//    CreateWorkoutView()
//}
