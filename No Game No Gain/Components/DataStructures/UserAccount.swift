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
    var exp = 0
    var level = 0
    var levelName: String {
        switch exp {
        case _ where exp > 14841:
            level = 10
            return "Fitness Deity"
        case _ where exp > 9001:
            level = 9
            return "Gym Legend"
        case _ where exp > 5459:
            level = 8
            return "Ultimate Beast"
        case _ where exp > 3311:
            level = 7
            return "Gains God"
        case _ where exp > 2008:
            level = 6
            return "GymBeast"
        case _ where exp > 1218:
            level = 5
            return "Swole Legend"
        case _ where exp > 738:
            level = 4
            return "Gains Master"
        case _ where exp > 448:
            level = 3
            return "Iron Warrior"
        case _ where exp > 271:
            level = 2
            return "Gym Bro"
        case _ where exp > 164:
            level = 1
            return "Gum Newbie"
        default:
            return "Rookie Lifter"
        }
    }
    
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
