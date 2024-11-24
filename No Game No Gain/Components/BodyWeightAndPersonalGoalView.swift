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
    
    var body: some View {
//            VStack {
            NavigationStack {
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
                        NavigationLink(destination: {
                            PersonalGoalView()
                        } ){
                            VStack(alignment: .leading){
                                Text("Weight Goal")
                                    .font(.title2)
                                
                                Text("Lose 5kg")
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                
                                ProgressView(value: 10, total: 15)
        //                            .padding(.horizontal)
                                HStack {
                                    Text("85")
                                    Spacer()
                                    Text("80")
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                    .padding(.horizontal)
                    .frame(minWidth: 60, maxWidth: geometry.size.width * 2/3 + 3, minHeight: 150, maxHeight: 150)
    //                .frame(width: geometry.size.width * 2/3, height: 150)
                    .background(Color(red: 26/255, green: 26/255, blue: 26/255))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
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
                }
            }
        }
    }
    
    func addWeightRecord() {
        if bodyMass == Double(addWeight) / 10 + 10 { return }
        
        bodyMass = Double(addWeight) / 10 + 10
        
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
    BodyWeightAndPersonalGoalView()
        .preferredColorScheme(.dark)
}
