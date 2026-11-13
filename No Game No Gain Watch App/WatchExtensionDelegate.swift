//
//  WatchExtensionDelegate.swift
//  No Game No Gain Watch App
//
//  Created by Hubert Wojtowicz on 25/10/2026.
//

import HealthKit
import WatchKit

final class WatchExtensionDelegate: NSObject, WKApplicationDelegate {
    let controller = WatchWorkoutController()

    func handle(_ workoutConfiguration: HKWorkoutConfiguration) {
        let configuration = workoutConfiguration
        Task { @MainActor in
            await controller.start(configuration)
        }
    }

    func handleActiveWorkoutRecovery() {
        Task { @MainActor in
            await controller.recover()
        }
    }
}
