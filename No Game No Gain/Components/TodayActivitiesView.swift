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
    @State private var chartColor: Color = .red
    @State private var chartData: [(date: Date, data: Double)] = []
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
                    Text("Goal: 18000")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    
                }
                .frame(minWidth: 60, maxWidth: .infinity,minHeight: 150, maxHeight: 160)
                .background(Color(red: 26/255, green: 26/255, blue: 26/255))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onTapGesture {
                    showChart = true
                    loadChartData(type: .stepCount)
                    chartName = "Steps"
                    chartColor = .green
                }
                
                
                VStack{
                    Text("Calories")
                        .font(.headline)
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.red)
                        Text("\(burnedCalories, specifier: "%.0f")")
                    }
                }
                .frame(minWidth: 60, maxWidth: .infinity, minHeight: 150, maxHeight: 160)
                .background(Color(red: 26/255, green: 26/255, blue: 26/255))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onTapGesture {
                    showChart = true
                    loadChartData(type: .activeEnergyBurned)
                    chartName = "Calories"
                    chartColor = .red
                }
                
                VStack{
                    Text("Sleep")
                    HStack{
                        Image(systemName: "moon.fill")
                        Text("\(sleepTimeFormatted(minutes: sleepTime))")
                    }
                }
                .frame(minWidth: 60, maxWidth: .infinity)
                .frame(height: 150)
                .background(Color(red: 26/255, green: 26/255, blue: 26/255))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onTapGesture {
                    chartName = "Sleep duration"
                    loadChartDataSleep()
                    showChart = true
                    chartColor = .blue
                }
            }
            .frame(height: 150)
            .onAppear {
                fetchHealthData()
            }
        } else {
            VStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .frame(height: 150)
                } else {
                    VStack{
                        Text(chartName)
                            .font(.title)
                            .padding(.vertical, -8)
                        Chart {
                            ForEach(chartData, id: \.date) { data in
                                BarMark(
                                    x: .value("Date", data.date, unit: .day),
                                    y: .value("Data", data.data)
                                )
                            }
                            if let average = calculateAverage(for: chartData) {
                                RuleMark(y: .value("Average", average))
                                    .foregroundStyle(.white)
                                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                                    .annotation(position: .top, alignment: .leading) {
                                        Text("Average: \(chartName == "Sleep duration" ? sleepTimeFormattedHours(hours: average)  : "\(Int(average))")")
                                            .font(.caption)
                                            .foregroundColor(.primary)
                                    }
                            }
                        }
                        .foregroundColor(chartColor)
                    }
                    .padding(4)
                    .frame(height: 150)
                    .background(Color(red: 26/255, green: 26/255, blue: 26/255))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
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
        }
        
        Task {
            //            burnedCalories = burned
            sleepTime = try await HealthKitManager().fetchLastSleepDuration()
            //            sleepTime = sleepTimeMin
        }
        
//        print("kroki: \(stepsToday), kcal: \(burnedCalories.formatted()), sleep: \(sleepTime.formatted())")
    }
    
    func sleepTimeFormatted(minutes: Double) -> String {
        let hours = Int(minutes / 60)
        let minute = Int(Int(minutes) % 60)
        return "\(hours):\(minute)"
    }
    func sleepTimeFormattedHours(hours: Double) -> String {
        let hour = Int(hours)
        var minute: Int {
            return Int((hours - Double(hour)) * 60)
        }
        return "\(hour):\(minute)"
    }
    
    func loadChartData(type: HKQuantityTypeIdentifier) {
        isLoading = true
//        healthKitManager.fetchCaloriesBurnedForLastMonth { data, error in
        healthKitManager.fetchDataForChart(title: "", type: type) { data, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    print("Błąd podczas pobierania danych: \(error.localizedDescription)")
                } else  {
                    self.chartData = data.map { (date, data) in
                        return (date: date, data: data)
                    }
                }
            }
        }
    }
    
    func loadChartDataSleep() {
        healthKitManager.fetchSleepDataForChart { data, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    print("Błąd podczas pobierania danych: \(error.localizedDescription)")
                } else  {
                    self.chartData = data.map { (date, data) in
                        return (date: date, data: data)
                    }
                }
            }
        }
    }
    
    private func calculateAverage(for data: [(Date, Double)]) -> Double? {
        guard !data.isEmpty else { return nil }
        let total = data.reduce(0) { $0 + $1.1 }
        return total / Double(data.count)
    }
}

#Preview {
    TodayActivitiesView()
        .preferredColorScheme(.dark)
}
