import SwiftUI
import Charts
import SwiftData

struct GraphView: View {
    @Query(sort: \BloodPressure.timestamp, order: .forward) var measurements: [BloodPressure]
    
    // Holt sich die Spracheinstellung, um Achsen und Texte zu übersetzen
    @AppStorage("selectedLanguage") private var selectedLanguage = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            // --- TITEL & INFO ---
            VStack(alignment: .leading, spacing: 4) {
                Text(selectedLanguage == 0 ? "Analyse" : "Analysis")
                    .font(.title)
                    .bold()
                
                Text(selectedLanguage == 0 ? "Zielbereich: Sys < 135 | Dia < 85 mmHg" : "Target: Sys < 135 | Dia < 85 mmHg")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding([.top, .horizontal])
            
            if measurements.isEmpty {
                Spacer()
                ContentUnavailableView(
                    selectedLanguage == 0 ? "Keine Daten verfügbar" : "No Data Available",
                    systemImage: "chart.xyaxis.line",
                    description: Text(selectedLanguage == 0 ? "Trage zuerst Messungen in der Hauptansicht ein." : "Please enter measurements on the main screen first.")
                )
                Spacer()
            } else {
                // --- DER GRAPH ---
                Chart {
                    // 1. GRÜNER ZIELBEREICH IM HINTERGRUND
                    if let firstDate = measurements.first?.timestamp,
                       let lastDate = measurements.last?.timestamp {
                        
                        // Zielbereich für die Systole (90 bis 134 mmHg)
                        RectangleMark(
                            xStart: .value("Start", firstDate),
                            xEnd: .value("End", lastDate),
                            yStart: .value("Sys Min", 90),
                            yEnd: .value("Sys Max", 134)
                        )
                        .foregroundStyle(Color.green.opacity(0.08))
                        
                        // Zielbereich für die Diastole (60 bis 84 mmHg)
                        RectangleMark(
                            xStart: .value("Start", firstDate),
                            xEnd: .value("End", lastDate),
                            yStart: .value("Dia Min", 60),
                            yEnd: .value("Dia Max", 84)
                        )
                        .foregroundStyle(Color.green.opacity(0.08))
                    }
                    
                    // 2. DATENLINIEN UND PUNKTE ZEICHNEN
                    ForEach(measurements) { entry in
                        // --- SYSTOLE (Obere Linie) ---
                        LineMark(
                            x: .value("Datum", entry.timestamp),
                            y: .value("Systole", entry.systole),
                            series: .value("Typ", "Systole")
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(Color.red.opacity(0.7))
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        
                        PointMark(
                            x: .value("Datum", entry.timestamp),
                            y: .value("Systole", entry.systole)
                        )
                        .foregroundStyle(entry.systole < 135 ? Color.green : Color.red)
                        .annotation(position: .top) {
                            Text("\(Int(entry.systole))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        // --- DIASTOLE (Untere Linie) ---
                        LineMark(
                            x: .value("Datum", entry.timestamp),
                            y: .value("Diastole", entry.diastole),
                            series: .value("Typ", "Diastole")
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(Color.blue.opacity(0.7))
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        
                        PointMark(
                            x: .value("Datum", entry.timestamp),
                            y: .value("Diastole", entry.diastole)
                        )
                        .foregroundStyle(entry.diastole < 85 ? Color.green : Color.blue)
                        .annotation(position: .bottom) {
                            Text("\(Int(entry.diastole))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .chartYScale(domain: 50...190)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.day(.twoDigits).month(.twoDigits))
                    }
                }
                .padding()
                
                // --- LEGENDE ---
                HStack(spacing: 20) {
                    Spacer()
                    HStack(spacing: 4) {
                        Circle().fill(Color.red).frame(width: 8, height: 8)
                        Text(selectedLanguage == 0 ? "Systole" : "Systole").font(.caption)
                    }
                    HStack(spacing: 4) {
                        Circle().fill(Color.blue).frame(width: 8, height: 8)
                        Text(selectedLanguage == 0 ? "Diastole" : "Diastole").font(.caption)
                    }
                    HStack(spacing: 4) {
                        Circle().fill(Color.green).frame(width: 8, height: 8)
                        Text(selectedLanguage == 0 ? "Im Zielbereich" : "In Target").font(.caption)
                    }
                    Spacer()
                }
                .padding(.bottom, 30)
            }
        }
        .navigationTitle(selectedLanguage == 0 ? "Verlaufsgraph" : "Trends")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    // Verwendung einer anonymen Funktion, um Setup-Logik sauber auszuführen
    let container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: BloodPressure.self, configurations: config)
        
        let today = Date()
        let sampleData = [
            BloodPressure(systole: 120, diastole: 80, timestamp: today.addingTimeInterval(-86400 * 2), note: nil),
            BloodPressure(systole: 140, diastole: 88, timestamp: today.addingTimeInterval(-86400 * 1), note: nil),
            BloodPressure(systole: 130, diastole: 84, timestamp: today, note: nil)
        ]
        
        for sample in sampleData {
            container.mainContext.insert(sample)
        }
        return container
    }()
    
    NavigationStack {
        GraphView()
            .modelContainer(container)
    }
}
