import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \BloodPressure.timestamp, order: .reverse) var allMeasurements: [BloodPressure]
    @Environment(\.modelContext) private var modelContext

    // Holt sich den dynamischen Zeitraum und die Sprache aus dem AppStorage
    @AppStorage("reportPeriodDays") private var reportPeriodDays = 7
    @AppStorage("selectedLanguage") private var selectedLanguage = 0

    // Berechnet das Startdatum für die Filterung (z.B. vor 7 Tagen)
    private var filterStartDate: Date {
        Calendar.current.date(byAdding: .day, value: -reportPeriodDays, to: Date()) ?? Date()
    }

    // Filtert die Messwerte dynamisch für die Liste
    private var filteredMeasurements: [BloodPressure] {
        allMeasurements.filter { $0.timestamp >= filterStartDate }
    }

    var body: some View {
        List {
            if filteredMeasurements.isEmpty {
                ContentUnavailableView(
                    selectedLanguage == 0 ? "Keine Daten" : "No Data",
                    systemImage: "heart.text.square",
                    description: Text(selectedLanguage == 0
                                      ? "Im ausgewählten Zeitraum (\(reportPeriodDays) Tage) wurden keine Blutdruckwerte gespeichert."
                                      : "No blood pressure values recorded in the selected period (\(reportPeriodDays) days).")
                )
            } else {
                // Ein kleiner Header, der dem Nutzer anzeigt, welcher Zeitraum gerade aktiv ist
                Section(header: Text(selectedLanguage == 0 ? "Letzte \(reportPeriodDays) Tage" : "Last \(reportPeriodDays) Days")) {
                    ForEach(filteredMeasurements) { entry in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(Int(entry.systole)) / \(Int(entry.diastole)) mmHg")
                                    .font(.headline)
                                
                                Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                if let note = entry.note {
                                    Text("📝 \(note)")
                                        .font(.caption)
                                        .italic()
                                        .foregroundColor(.primary.opacity(0.8))
                                        .padding(.top, 2)
                                }
                            }
                            Spacer()
                            
                            Circle()
                                .fill(entry.systole > 140 || entry.diastole > 90 ? Color.red : Color.green)
                                .frame(width: 12, height: 12)
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
            }
        }
        .navigationTitle(selectedLanguage == 0 ? "Verlauf" : "History")
    }

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let itemToDelete = filteredMeasurements[index]
            modelContext.delete(itemToDelete)
        }
    }
}

#Preview {
    // Verwendung einer anonymen Funktion, um Setup-Logik sauber auszuführen
    let container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: BloodPressure.self, configurations: config)
        
        let today = Date()
        container.mainContext.insert(BloodPressure(systole: 120, diastole: 80, timestamp: today, note: "Alles super"))
        container.mainContext.insert(BloodPressure(systole: 145, diastole: 95, timestamp: today.addingTimeInterval(-86400 * 3), note: "Nach Kaffee"))
        
        return container
    }()
    
    NavigationStack {
        HistoryView()
            .modelContainer(container)
    }
}
