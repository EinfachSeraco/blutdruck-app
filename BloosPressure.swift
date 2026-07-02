import Foundation
import SwiftData

@Model
class BloodPressure {
    var systole: Int
    var diastole: Int
    var timestamp: Date
    var note: String? // NEU: Optionale Notiz für Kontext (Sport, Stress etc.)
    
    init(systole: Int, diastole: Int, timestamp: Date = Date(), note: String? = nil) {
        self.systole = systole
        self.diastole = diastole
        self.timestamp = timestamp
        self.note = note
    }
}
