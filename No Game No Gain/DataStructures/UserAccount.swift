//
//  UserAccount.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 19/10/2024.
//

import Foundation

class UserAccount: Codable {
    var notes: String = ""
    var name: String = ""
    var exp: Double = 0
    var expMultiplier: Double = 1
    var weight: Double = 0
    var goal: String = "Weight Goal"
    var strengthGoalExercise: String? = nil
    var goalStart: Double = 0
    var goalEnd: Double = 0
    var goalProgress: Double = 65
    
}

func getDocumentsDirectory() -> URL {
    return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
}

func saveUserAccountToFile(_ userAccount: UserAccount) {
    let fileURL = getDocumentsDirectory().appendingPathComponent("userAccount.json")
    do {
        let data = try JSONEncoder().encode(userAccount)
        try data.write(to: fileURL)
        print("User account data saved successfully!")
    } catch {
        print("Failed to save user account data: \(error)")
    }
}

func loadUserAccountFromFile() -> UserAccount? {
    let fileURL = getDocumentsDirectory().appendingPathComponent("userAccount.json")
    do {
        let data = try Data(contentsOf: fileURL)
        let userAccount = try JSONDecoder().decode(UserAccount.self, from: data)
        return userAccount
    } catch {
        print("Failed to load user account data: \(error)")
        return nil
    }
}
