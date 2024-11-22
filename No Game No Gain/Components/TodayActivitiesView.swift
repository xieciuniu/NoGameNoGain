//
//  TodayActivitiesView.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 07/08/2024.
//

import SwiftUI
import Charts
import HealthKit

struct TodayActivitiesView: View {
    let healthStore = HKHealthStore()
    let healthKitManager = HealthKitManager()
    @State private var stepsToday: Double = 0
    @State private var burnedCalories: Double = 0
    @State private var sleepTime: Double = 0
    
    @State private var showChart: Bool = false
    @State private var chartName: String = ""
    @State private var caloriesData: [(date: Date, calories: Double)] = []
    @State private var isLoading = false
    var body: some View {
        if !showChart{
            HStack(alignment: .center, spacing: 10) {

                    VStack {
                        Text("\(stepsToday.formatted())")
                            .font(.title3)
                            .padding(.vertical)
                            .lineLimit(1)
                        Text("Steps")
                            .font(.headline)
                        Text("Goal: 8000")
                            .font(.subheadline)
                        
                    }
                    .padding(20)
                    .frame(minWidth: 60, maxWidth: .infinity,minHeight: 150, maxHeight: 160)
                    .background(Color(red: 26/255, green: 26/255, blue: 26/255))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    

                    VStack{
                        Text("Calories")
                            .font(.headline)
                        HStack {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(.red)
                            Text("\(burnedCalories, specifier: "%.0f")")
                        }
                    }
                    .padding(20)
                    .frame(minWidth: 60, maxWidth: .infinity, minHeight: 150, maxHeight: 160)
                    .background(Color(red: 26/255, green: 26/255, blue: 26/255))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                        .onTapGesture {
                            showChart = true
                            loadCaloriesData()
                        }

                    VStack{
                        Text("Sleep")
                        HStack{
                            Image(systemName: "moon.fill")
                            Text("\(sleepTimeFormatted(minutes: sleepTime))")
                        }
                    }
                    .padding(20)
                    .frame(minWidth: 60, maxWidth: .infinity,minHeight: 150, maxHeight: 160)
                    .background(Color(red: 26/255, green: 26/255, blue: 26/255))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            .frame(height: 150)
//            .padding(.horizontal, 10)
//            .background(.red.gradient)
            .onAppear {
                //Designing purpose
                fetchHealthData()
            }
        } else {
            VStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Chart {
                        ForEach(caloriesData, id: \.date) { data in
                            BarMark(
                                x: .value("Date", data.date, unit: .day),
                                y: .value("Calories", data.calories)
                            )
                        }
                    }
                    .padding()
                    .frame(height: 300)
                    .foregroundColor(.blue)
                }
            }
            .onTapGesture {
                showChart = false
            }
        }
    }
    
    func fetchHealthData() {
        HealthKitManager().fetchStepCount(date: Date()) { steps, error in
            if let error = error {
                print("Błąd podczas pobierania liczby kroków: \(error)")
                return
            }
            stepsToday = steps ?? 0
        }
        
        HealthKitManager().fetchCaloriesBurned(date: Date.now) { calories, error in
            if let error = error {
                print("Błąd podczas pobierania liczby kalorii: \(error)")
                return
            }
            burnedCalories = calories ?? 0
            print("Kalorie: \(calories?.formatted() ?? "error")")
        }
        
        Task {
//            burnedCalories = burned
            sleepTime = try await HealthKitManager().fetchLastSleepDuration()
//            sleepTime = sleepTimeMin
        }
        
        print("kroki: \(stepsToday), kcal: \(burnedCalories.formatted()), sleep: \(sleepTime.formatted())")
    }
    
    func sleepTimeFormatted(minutes: Double) -> String {
        let hours = Int(minutes / 60)
        let minute = Int(Int(minutes) % 60)
//        if minute == 0 { return "\(hours)h"}
        return "\(hours):\(minute)"
    }
    
    func loadCaloriesData() {
        isLoading = true
        healthKitManager.fetchCaloriesBurnedForLastMonth { data, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    print("Błąd podczas pobierania danych o kaloriach: \(error.localizedDescription)")
                } else  {
                    self.caloriesData = data.map { (date, calories) in
                        return (date: date, calories: calories)
                    }
                }
            }
        }
        for calorie in caloriesData {
            print("\(calorie.date): \(calorie.calories) kcal")
        }
    }
}

#Preview {
    TodayActivitiesView()
        .preferredColorScheme(.dark)
}
