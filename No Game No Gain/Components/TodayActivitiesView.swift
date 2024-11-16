//
//  TodayActivitiesView.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 07/08/2024.
//

import SwiftUI
import HealthKit

struct TodayActivitiesView: View {
    let healthStore = HKHealthStore()
    @State var stepsToday: Double?
    
    var body: some View {
        VStack{
            Text("Today steps: \((stepsToday ?? 0.0 ).formatted())")
        }
        .onAppear {
            fetchSteps()
        }
    }
    
    func fetchSteps() {
        HealthKitManager().fetchStepCount { steps, error in
            if let error = error {
                print("Błąd podczas pobierania liczby kroków: \(error)")
                return
            }
            stepsToday = steps ?? 0
        }
    }
}

#Preview {
    TodayActivitiesView()
}
