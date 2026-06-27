import SwiftUI

struct SettingsView: View {
    // Speichert die Anzahl der Tage dauerhaft auf dem iPhone. Standard ist 7.
    @AppStorage("reportPeriodDays") private var reportPeriodDays: Int = 7
    
    // Die Optionen, die der Nutzer im Menü auswählen kann
    let periodOptions = [3, 5, 7, 14, 30, 90]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(
                    header: Text("Berichtszeitraum"),
                    footer: Text("Bestimmt, wie viele Tage standardmäßig im Verlauf, in der Grafik und beim PDF-Arztexport berücksichtigt werden.")
                ) {
                    Picker("Zeitraum für Arzt", selection: $reportPeriodDays) {
                        ForEach(periodOptions, id: \.self) { days in
                            Text("\(days) Tage")
                                .tag(days)
                        }
                    }
                    .pickerStyle(.navigationLink) // Sieht auf iOS extrem nativ und schick aus
                }
            }
            .navigationTitle("Einstellungen")
        }
    }
}

#Preview {
    SettingsView()
}
