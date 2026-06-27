import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \BloodPressure.timestamp, order: .reverse) var measurements: [BloodPressure]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List {
            if measurements.isEmpty {
                ContentUnavailableView("Keine Daten",
                                       systemImage: "heart.text.square",
                                       description: Text("Es wurden noch keine Blutdruckwerte gespeichert."))
            } else {
                ForEach(measurements) { entry in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(entry.systole) / \(entry.diastole) mmHg")
                                .font(.headline)
                            
                            Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            // NEU: Falls eine Bemerkung vorhanden ist, hier anzeigen
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
        .navigationTitle("Verlauf")
    }

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(measurements[index])
        }
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: BloodPressure.self, inMemory: true)
}
