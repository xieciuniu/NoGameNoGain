//
//  SceneDelegate.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 12/10/2024.
//

import Foundation
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    var stopwatch = Stopwatch()  // Twój obiekt Stopwatch
    
    func sceneWillResignActive(_ scene: UIScene) {
        stopwatch.saveState()  // Zapisz stan stopera przed przejściem do tła
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        stopwatch.saveState()  // Zapisz stan stopera przed zamknięciem aplikacji
    }
}
