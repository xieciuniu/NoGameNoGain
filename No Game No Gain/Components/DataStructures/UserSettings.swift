//
//  UserSettings.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 19/10/2024.
//

import Foundation
import SwiftData

@Model
class UserSettings {
    var notes = ""
    var nickName: String?
    var weightUnitKg: Bool = true
    
    init() {
        
    }
}
