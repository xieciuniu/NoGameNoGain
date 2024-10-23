//
//  WorkoutTimer.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 8/28/24.
//

import Foundation
import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var countdownLabel: UILabel!

    var timer: Timer?
    var targetDate: Date?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Ustaw datę początkową, od której ma być liczony czas
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        targetDate = dateFormatter.date(from: "2023/01/01 00:00:00")

        // Uruchom timer, który będzie odświeżał licznik co sekundę
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateCountdown), userInfo: nil, repeats: true)
    }

    @objc func updateCountdown() {
        guard let targetDate = targetDate else { return }

        // Oblicz różnicę czasu pomiędzy datą początkową a obecną
        let currentDate = Date()
        let timeInterval = currentDate.timeIntervalSince(targetDate)

        // Przekształć czas w godziny, minuty i sekundy
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        let seconds = Int(timeInterval) % 60

        // Zaktualizuj label
        countdownLabel.text = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Zatrzymaj timer, gdy widok znika
        timer?.invalidate()
    }
}
