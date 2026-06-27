import SwiftUI
import Charts
import SwiftData

struct PDFReportView: View {
    let measurements: [BloodPressure]
    let language: Int // 0 = DE, 1 = EN
    let profileName: String
    let profileBirthdate: String
    
    // Berechnete Statistiken
    private var averageSys: Int {
        guard !measurements.isEmpty else { return 0 }
        return measurements.reduce(0) { $0 + $1.systole } / measurements.count
    }
    
    private var averageDia: Int {
        guard !measurements.isEmpty else { return 0 }
        return measurements.reduce(0) { $0 + $1.diastole } / measurements.count
    }
    
    // Sortierung für Graph (chronologisch aufsteigend)
    private var chronologicalMeasurements: [BloodPressure] {
        measurements.sorted(by: { $0.timestamp < $1.timestamp })
    }
    
    // Sortierung für Tabelle (neueste zuerst, limitiert auf die letzten 12 für eine DIN-A4-Seite)
    private var latestMeasurements: [BloodPressure] {
        Array(measurements.sorted(by: { $0.timestamp > $1.timestamp }).prefix(12))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            
            // --- KOPFZEILE (Dynamische Patientendaten) ---
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(profileName.isEmpty ? (language == 0 ? "Patient" : "Patient") : profileName)
                        .font(.title2)
                        .bold()
                    if !profileBirthdate.isEmpty {
                        Text("\(language == 0 ? "Geburtsdatum" : "Date of Birth"): \(profileBirthdate)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Text("\(language == 0 ? "Exportiert am" : "Exported on"): \(Date().formatted(Date.FormatStyle.dateTime.day().month().year()))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // --- TITEL & STATISTIK-ZEILE ---
            HStack(alignment: .firstTextBaseline) {
                Text(language == 0 ? "Blutdruckbericht" : "Blood Pressure Report")
                    .font(.title3)
                    .bold()
                Spacer()
                Text("\(language == 0 ? "Messungen insgesamt" : "Total Measurements"): \(measurements.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 40) {
                VStack(alignment: .leading) {
                    Text(language == 0 ? "Mittelwert (Ø)" : "Average (Ø)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(averageSys)/\(averageDia) mmHg")
                        .font(.title3)
                        .bold()
                        .foregroundColor(averageSys < 135 && averageDia < 85 ? .green : .red)
                }
                
                VStack(alignment: .leading) {
                    Text(language == 0 ? "Zielbereich" : "Target Range")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Sys < 135 | Dia < 85")
                        .font(.body)
                        .bold()
                }
                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            // --- 1. SCHAUBILD (DIAGRAMM) ---
            VStack(alignment: .leading, spacing: 6) {
                Text(language == 0 ? "Verlaufsgraph" : "Trend Chart")
                    .font(.caption)
                    .bold()
                    .foregroundColor(.secondary)
                
                Chart {
                    ForEach(chronologicalMeasurements) { entry in
                        // Systole
                        LineMark(
                            x: .value("Datum", entry.timestamp),
                            y: .value("Systole", entry.systole),
                            series: .value("Typ", "Systole")
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(Color.red.opacity(0.6))
                        
                        PointMark(
                            x: .value("Datum", entry.timestamp),
                            y: .value("Systole", entry.systole)
                        )
                        .foregroundStyle(entry.systole < 135 ? Color.green : Color.red)
                        
                        // Diastole
                        LineMark(
                            x: .value("Datum", entry.timestamp),
                            y: .value("Diastole", entry.diastole),
                            series: .value("Typ", "Diastole")
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(Color.blue.opacity(0.6))
                        
                        PointMark(
                            x: .value("Datum", entry.timestamp),
                            y: .value("Diastole", entry.diastole)
                        )
                        .foregroundStyle(entry.diastole < 85 ? Color.green : Color.blue)
                    }
                }
                .chartYScale(domain: 50...190)
                .chartXAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel(format: Date.FormatStyle.dateTime.day().month(.twoDigits))
                    }
                }
                .frame(height: 180)
            }
            .padding(.vertical, 5)
            
            // --- 2. TABELLE MIT EINZELMESSWERTEN ---
            VStack(spacing: 0) {
                HStack {
                    Text(language == 0 ? "DATUM / UHRZEIT" : "DATE / TIME").frame(maxWidth: .infinity, alignment: .leading)
                    Text(language == 0 ? "MESSWERT" : "VALUE").frame(maxWidth: .infinity, alignment: .center)
                    Text(language == 0 ? "BEMERKUNG" : "NOTES").frame(maxWidth: .infinity, alignment: .trailing)
                }
                .font(.caption)
                .bold()
                .foregroundColor(.secondary)
                .padding(.bottom, 6)
                
                Divider()
                
                // Statisches VStack ohne ScrollView für fehlerfreies PDF-Rendering
                VStack(spacing: 0) {
                    ForEach(latestMeasurements) { entry in
                        HStack {
                            Text(entry.timestamp.formatted(Date.FormatStyle.dateTime.day().month(.twoDigits).hour().minute()))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text("\(entry.systole)/\(entry.diastole) mmHg")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .bold()
                                .foregroundColor(entry.systole < 135 && entry.diastole < 85 ? .primary : .red)
                            
                            Text(entry.note ?? "-")
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        .padding(.vertical, 6)
                        
                        Divider()
                    }
                }
            }
            
            Spacer()
            
            // --- FOOTER ---
            HStack {
                Spacer()
                Text(language == 0 ? "Erstellt mit Blutdruck Pro App" : "Created with Blood Pressure Pro App")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding(40)
        .frame(width: 595, height: 842)
        .background(Color.white)
    }
}
