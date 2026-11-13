//
//  NoGameNoGainWatchApp.swift
//  No Game No Gain Watch App
//
//  Created by Hubert Wojtowicz on 25/10/2026.
//

import SwiftUI

@main
struct NoGameNoGainWatchApp: App {
    @WKApplicationDelegateAdaptor(WatchExtensionDelegate.self) private var delegate

    var body: some Scene {
        WindowGroup {
            WatchWorkoutView(controller: delegate.controller)
        }
    }
}
