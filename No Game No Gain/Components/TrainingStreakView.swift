//
//  TrainingStreakView.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 08/08/2024.
//

import SwiftUI

struct TrainingDay: Identifiable {
    var id = UUID()
    var day: String
    var dayNumber: Int
    var trainingDay: Bool
}
    
struct TrainingStreakView: View {
    var trainingDays: [TrainingDay] = [
        TrainingDay(day: "Mon", dayNumber: 2, trainingDay: true),
        TrainingDay(day: "Tue", dayNumber: 3, trainingDay: false),
        TrainingDay(day: "Wed", dayNumber: 4, trainingDay: true),
        TrainingDay(day: "Thu", dayNumber: 5, trainingDay: true),
        TrainingDay(day: "Fri", dayNumber: 6, trainingDay: false),
        TrainingDay(day: "Sat", dayNumber: 7, trainingDay: true),
        TrainingDay(day: "Sun", dayNumber: 8, trainingDay: false)
        ]
    let dayOfWeek: Int = 5 + 1
    let doneTrainingDay: [Int] = [2,4]
    
    
    
    var body: some View {
        VStack {
            Text("Regularność treningów")
                .font(.title)
                .padding()
            
            HStack {
                ForEach(trainingDays) { trainingDay in
                    VStack {
                        if trainingDay.trainingDay && trainingDay.dayNumber <= dayOfWeek {
                            ZStack{
                                Circle()
                                    .fill(doneTrainingDay.contains(trainingDay.dayNumber) ? Color.green : Color.red)
                                      .overlay(
                                        Image("dumbbell.fill")
                                        
                                    )
                                Circle().stroke(Color.black, lineWidth: 2)
                            }
                                
                        } else if (trainingDay.trainingDay) {
                            ZStack{
                                Image("dumbbell")

                                Circle()
                                    .stroke(Color.black, lineWidth: 2)
                            }
                                    
                        } else {
                            ZStack{
                                Circle()
                                    .fill(trainingDay.dayNumber < dayOfWeek ? Color.green : Color.white)
                                    
                                Circle().stroke(Color.black, lineWidth: 2)
                            }
                        }
                        
                        Text(trainingDay.day)
                    }
                    .padding(5)
                }
            }
            
        }
        .padding(5)
    }
}

#Preview {
    TrainingStreakView()
}
