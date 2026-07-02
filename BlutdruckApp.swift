import SwiftUI
import SwiftData

@main
struct BlutdruckApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // Hier wird die lokale Datenbank für die App initialisiert
        .modelContainer(for: BloodPressure.self)
    }
}
