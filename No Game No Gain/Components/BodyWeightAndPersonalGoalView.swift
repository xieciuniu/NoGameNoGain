//
//  BodyWeightAndPersonalGoalView.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 24/11/2024.
//

import SwiftUI
import HealthKit

struct BodyWeightAndPersonalGoalView: View {
    private let healthKitManager = HealthKitManager.shared
    @State var bodyMass: Double = 0.0
    @State var changeWeight: Bool = false
    @State var addWeight: Int = 500
    @Binding var path: NavigationPath
    @Binding var userAccount: UserAccount

    var body: some View {
        VStack {
            GeometryReader { geometry in
                HStack(alignment: .center, spacing: 10) {
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
                            .simultaneousGesture(
                                TapGesture()
                                    .onEnded {
                                        changeWeight.toggle()
                                        addWeightRecord()
                                    }
                            )
                            .padding(.bottom, 0)
                        }

                        Text("Body Weight")
                            .padding(changeWeight ? .bottom : .horizontal, 1)
                            .font(.subheadline)
                    }
                    .frame(minWidth: 40, maxWidth: geometry.size.width * 1/3 - 7, minHeight: 150, maxHeight: 150)
                    .background(Color(red: 26/255, green: 26/255, blue: 26/255))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    goalCard
                        .padding(.horizontal)
                        .frame(minWidth: 60, maxWidth: geometry.size.width * 2/3 + 3, minHeight: 150, maxHeight: 150)
                        .background(Color(red: 26/255, green: 26/255, blue: 26/255))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .contentShape(RoundedRectangle(cornerRadius: 8))
                        .accessibilityElement(children: .combine)
                        .accessibilityIdentifier("Personal Goal")
                        .accessibilityAddTraits(.isButton)
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

    @ViewBuilder
    private var goalCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            if GoalProgress.hasActiveGoal(userAccount) {
                Text(GoalProgress.directionSentence(for: userAccount))
                    .font(.headline)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                ProgressView(value: GoalProgress.barFraction(for: userAccount))

                Text("\(GoalProgress.formatKilograms(GoalProgress.displayedProgress(userAccount))) kg")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if GoalProgress.isReached(userAccount) {
                    Text("Done. Set the next target.")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            } else {
                Text("Set a goal")
                    .font(.title3)
            }
        }
        .foregroundStyle(.primary)
        .frame(maxWidth: .infinity, alignment: .leading)
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
        guard bodyMass != Double(addWeight) / 10 + 10 else {
            return
        }

        bodyMass = Double(addWeight) / 10 + 10
        userAccount.weight = bodyMass

        if userAccount.goal == "Weight Goal" {
            userAccount.goalProgress = bodyMass
        }
        saveUserAccountToFile(userAccount)
        if let saved = loadUserAccountFromFile() {
            userAccount = saved
        }

        guard HKHealthStore.isHealthDataAvailable() else {
            return
        }
        healthKitManager.addBodyMassToHealthKit(weightInKilograms: bodyMass) { result, error in
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
