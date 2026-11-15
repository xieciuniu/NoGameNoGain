//
//  SettingsView.swift
//  No Game No Gain
//

import SwiftUI

struct SettingsView: View {
    @State private var account: UserAccount
    @State private var name: String
    @State private var experienceDraft: Int

    init() {
        let account = loadUserAccountFromFile() ?? UserAccount()
        _account = State(initialValue: account)
        _name = State(initialValue: account.name)
        _experienceDraft = State(initialValue: Int(account.exp.rounded()))
    }

    var body: some View {
        Form {
            Section("Display name") {
                TextField("Name", text: $name)
                    .onChange(of: name) {
                        saveName()
                    }
            }
            NotificationSettingsView()
            #if DEBUG
            Section("Development") {
                Text("Stored experience \(Int(account.exp.rounded()))")
                TextField("Experience", value: $experienceDraft, format: .number)
                    .keyboardType(.numberPad)
                Button("Set experience", action: saveExperience)
                Button("Reset experience", action: resetExperience)
            }
            #endif
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func saveName() {
        account.name = name
        saveUserAccountToFile(account)
    }

    private func saveExperience() {
        account.exp = Double(max(0, experienceDraft))
        saveUserAccountToFile(account)
    }

    private func resetExperience() {
        experienceDraft = 0
        saveExperience()
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
