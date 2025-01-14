//
//  NotificationSettingsView.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 14/01/2025.
//

import SwiftUI

struct NotificationSettingsView: View {
    @StateObject private var settings = NotificationSettings()
    @State private var showingDocumentPicker = false
    
    var body: some View {
        Form {
            Section(header: Text("Sound Settings")) {
                Picker("Sound Type", selection: $settings.soundType) {
                    Text("Default").tag(NotificationSettings.SoundType.default)
                    Text("Custom").tag(NotificationSettings.SoundType.custom)
                }
                
                if settings.soundType == .custom {
                    Button(action: {
                        showingDocumentPicker = true
                    }) {
                        HStack {
                            Text("Select Sound File")
                            Spacer()
                            if settings.customSoundURL != nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }
        }
        .fileImporter(
            isPresented: $showingDocumentPicker,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    settings.customSoundURL = url
                    settings.saveSettings()
                }
            case .failure(let error):
                print("Error selecting file: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    NotificationSettingsView()
}
