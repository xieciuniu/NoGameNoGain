//
//  BodyWeightAndPersonalGoalView.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 24/11/2024.
//

import SwiftUI
import HealthKit

struct BodyWeightAndPersonalGoalView: View {
    private let healthKitManager = HealthKitManager()
    @State var bodyMass: Double = 0.0
    @State var changeWeight: Bool = false
    @State var addWeight: Int = 500
    @Binding var path: NavigationPath
    @Binding var userAccount: UserAccount
    var start: Double { return userAccount.goalStart }
    var end: Double { return userAccount.goalEnd }
    var progress: Double { return userAccount.goalProgress }
    
    
    var body: some View {
//            VStack {
        VStack {
                GeometryReader { geometry in
                    HStack(alignment: .center, spacing: 10){
                    VStack {
                        if !changeWeight {
                            Text("\(bodyMass, specifier: "%.1f") kg")
                                .font(.title2)
                                .onTapGesture {
                                    changeWeight.toggle()
                                }
                        } else {
                            Picker("", selection: $addWeight) {
                                ForEach(100..<2000) {
                                    Text("\(Double(Double($0)/10), specifier: "%.1f")")
                                }
                            }
                            .pickerStyle(.wheel)
                            .padding(.horizontal)
                            .onTapGesture {
                                changeWeight.toggle()
                                addWeightRecord()
                            }
                            .padding(.bottom, 0)
                        }
                        
                        Text("Body Weight")
                            .padding(changeWeight ? .bottom : .horizontal, 1)
                            .font(.subheadline)
                    }
                    .frame(minWidth: 40, maxWidth: geometry.size.width * 1/3 - 7, minHeight: 150, maxHeight: 150)
    //                .frame(width: /*geometry.size.width * 1/3*/, height: 150)
                    .background(Color(red: 26/255, green: 26/255, blue: 26/255))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
//                    .padding(.trailing)
                    
                    
                    
                    VStack {
                            VStack(alignment: .leading){
                                Text(userAccount.goal)
                                    .font(.title2)
                                
                                Text("Lose 5kg")
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                
                                if userAccount.goal == "Strength Goal"{
                                    if progress < end {
                                        ProgressView(value: progress - start, total: end - start )
                                    } else if progress == end{
                                        ProgressView(value: 1, total: 1, label: { Text("Congrats, you achieve your goal!\nNow it's time for new").font(.caption2)})
                                            .tint(.green)
                                    } else {
                                        ProgressView(value: 1, total: 1, label: { Text("Set new goal!")})
                                            .tint(.red)
                                    }
                                } else if userAccount.goal == "Weight Goal" {
                                    if start > end {
                                        if progress > start {
                                            ProgressView(value: 0, total: 1)
                                                .background(Color.red)
                                        } else if progress > end {
                                            ProgressView(value: userAccount.goalStart - userAccount.goalProgress, total: userAccount.goalStart - userAccount.goalEnd )
                                        } else if progress == end {
                                            ProgressView(value: 1, total: 1, label: { Text("Congrats, you achieve your goal!\nNow it's time for new").font(.caption2)})
                                                .tint(.green)
                                        } else {
                                            ProgressView(value: 1, total: 1, label: { Text("Set new goal!")})
                                                .tint(.red)
                                        }
                                    } else if start < end {
                                        if progress < start {
                                            ProgressView(value: 0, total: 1)
                                                
                                        } else if progress < end {
                                            ProgressView(value: progress - start, total: end - start )
                                        } else if progress == end {
                                            ProgressView(value: 1, total: 1, label: { Text("Congrats, you achieve your goal!\nNow it's time for new").font(.caption2)})
                                                .tint(.green)
                                        } else {
                                            ProgressView(value: 1, total: 1, label: { Text("Set new goal!")})
                                                .tint(.red)
                                        }
                                    }
                                }
                                
        //                            .padding(.horizontal)
                                HStack {
                                    Text("\(userAccount.goalStart.formatted())")
                                    Spacer()
                                    Text("\(userAccount.goalEnd.formatted())")
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                Text("\(userAccount.goalProgress.formatted())")
                        }
                        .foregroundStyle(.primary)
                    }
                    .padding(.horizontal)
                    .frame(minWidth: 60, maxWidth: geometry.size.width * 2/3 + 3, minHeight: 150, maxHeight: 150)
    //                .frame(width: geometry.size.width * 2/3, height: 150)
                    .background(Color(red: 26/255, green: 26/255, blue: 26/255))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .onTapGesture {
                        path.append("PersonalGoalView")
                    }
                }
            }
            .frame(height: 150)
            .onAppear {
                fetchBodyMass()
            }
        }
    }
    
    func fetchBodyMass() {
        healthKitManager.fetchBodyMassData { result, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Błąd podczas pobierania danych o wadze ciała: \(error)")
                } else {
                    self.bodyMass = result
                    self.addWeight = Int(result * 10 - 100)
                    userAccount.weight = result
                }
            }
        }
    }
    
    func addWeightRecord() {
        guard bodyMass != Double(addWeight) / 10 + 10 else  {
            return
        }
        
        bodyMass = Double(addWeight) / 10 + 10
        userAccount.weight = bodyMass
        
        if userAccount.goal == "Weight Goal" {
            userAccount.goalProgress = bodyMass
        }
        saveUserAccountToFile(userAccount)
        
        guard HKHealthStore.isHealthDataAvailable() else {
            return
        }
        healthKitManager.addBodyMassToHealthKit(weightInKilograms: bodyMass){ result, error in
            if result {
                print("Pomyślne dodanie danych o wadze ciała")
            } else if let error = error {
                print("Błąd podczas dodawania danych o wadze ciała: \(error)")
            }
        }
    }
}

#Preview {
    @Previewable @State var path: NavigationPath = NavigationPath()
    @Previewable @State var userAccount = UserAccount()
    BodyWeightAndPersonalGoalView(path: $path, userAccount: $userAccount)
        .preferredColorScheme(.dark)
}
