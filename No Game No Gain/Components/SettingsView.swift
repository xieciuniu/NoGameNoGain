//
//  SettingsView.swift
//  No Game No Gain
//

import SwiftUI

struct SettingsView: View {
    @State private var account: UserAccount
    @State private var name: String

    init() {
        let account = loadUserAccountFromFile() ?? UserAccount()
        _account = State(initialValue: account)
        _name = State(initialValue: account.name)
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
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func saveName() {
        account.name = name
        saveUserAccountToFile(account)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
