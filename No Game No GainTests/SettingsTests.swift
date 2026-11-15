//
//  SettingsTests.swift
//  No Game No GainTests
//

import Foundation
import Testing
@testable import No_Game_No_Gain

struct SettingsTests {
    @Test("A saved display name survives a reload and does not change XP")
    func testNameSurvivesReload() throws {
        let url = getDocumentsDirectory().appendingPathComponent("userAccount.json")
        let backup = try? Data(contentsOf: url)
        defer {
            if let backup {
                try? backup.write(to: url)
            } else {
                try? FileManager.default.removeItem(at: url)
            }
        }

        let account = loadUserAccountFromFile() ?? UserAccount()
        let exp = account.exp
        account.name = "Ada"
        saveUserAccountToFile(account)

        let loaded = try #require(loadUserAccountFromFile())
        #expect(loaded.name == "Ada")
        #expect(loaded.exp == exp)
    }

    @Test("The notification sound survives a new settings object")
    func testSoundSurvivesReload() {
        let suite = "f2-settings-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)

        let settings = NotificationSettings(userDefaults: defaults)
        settings.soundType = .custom
        settings.customSoundURL = URL(fileURLWithPath: "/tmp/bell.caf")
        settings.saveSettings()

        let loaded = NotificationSettings(userDefaults: defaults)
        #expect(loaded.soundType == .custom)
        #expect(loaded.customSoundURL?.lastPathComponent == "bell.caf")
        defaults.removePersistentDomain(forName: suite)
    }
}
