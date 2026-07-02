import SwiftUI
import Charts
import SwiftData

struct PDFReportView: View {
    let measurements: [BloodPressure]
    let language: Int // 0 = DE, 1 = EN
    let profileName: String
    let profileBirthdate: String
    let krankenkasse: String // NEU: Übergabe der Krankenkasse
    
    // Datenstruktur für einen zusammengefassten Kalendertag in der Tabelle
    struct DayRow: Identifiable {
        let id = UUID()
        let dateString: String
        var morningText: String = "-"
        var morningNote: String? = nil
        var eveningText: String = "-"
        var eveningNote: String? = nil
    }
    
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
    
    // Verarbeitet die Tabellenzeilen (Mittelwert & Zeilen-Gruppierung nach Tag)
    private var processedTableRows: [DayRow] {
        let calendar = Calendar.current
        
        // Gruppieren nach Kalendertag
        let groupedByDay = Dictionary(grouping: measurements) { entry in
            calendar.startOfDay(for: entry.timestamp)
        }
        
        var rows: [DayRow] = []
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "dd.MM.yyyy"
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        // Sortiert nach Datum absteigend (neueste Tage zuerst)
        for day in groupedByDay.keys.sorted(by: >) {
            guard let dayEntries = groupedByDay[day] else { continue }
            
            // Aufteilen in Vormittag (vor 12 Uhr) und Nachmittag/Abend (ab 12 Uhr)
            let morningEntries = dayEntries.filter { calendar.component(.hour, from: $0.timestamp) < 12 }
                .sorted { $0.timestamp < $1.timestamp }
            let eveningEntries = dayEntries.filter { calendar.component(.hour, from: $0.timestamp) >= 12 }
                .sorted { $0.timestamp < $1.timestamp }
            
            var row = DayRow(dateString: displayFormatter.string(from: day))
            
            // --- MORGENS-BLOCK ---
            if !morningEntries.isEmpty {
                let aggregated = aggregateEntries(morningEntries, calendar: calendar)
                if let firstTimestamp = morningEntries.first?.timestamp {
                    let timeStr = timeFormatter.string(from: firstTimestamp)
                    row.morningText = "\(Int(aggregated.sys))/\(Int(aggregated.dia)) mmHg (\(timeStr))"
                    row.morningNote = aggregated.note
                }
            }
            
            // --- ABENDS-BLOCK ---
            if !eveningEntries.isEmpty {
                let aggregated = aggregateEntries(eveningEntries, calendar: calendar)
                if let firstTimestamp = eveningEntries.first?.timestamp {
                    let timeStr = timeFormatter.string(from: firstTimestamp)
                    row.eveningText = "\(Int(aggregated.sys))/\(Int(aggregated.dia)) mmHg (\(timeStr))"
                    row.eveningNote = aggregated.note
                }
            }
            
            rows.append(row)
        }
        
        // Limitiert auf die neuesten 12 Tage, damit es garantiert auf eine DIN-A4-Seite passt
        return Array(rows.prefix(12))
    }
    
    // Hilfsfunktion: Berechnet den Mittelwert, wenn Werte maximal 30 Minuten auseinander liegen
    private func aggregateEntries(_ entries: [BloodPressure], calendar: Calendar) -> (sys: Double, dia: Double, note: String?) {
        guard !entries.isEmpty else { return (0, 0, nil) }
        if entries.count == 1 {
            return (Double(entries[0].systole), Double(entries[0].diastole), entries[0].note)
        }
        
        var totalSys = 0.0
        var totalDia = 0.0
        var count = 0.0
        var notes: [String] = []
        
        let baseEntry = entries[0]
        totalSys += Double(baseEntry.systole)
        totalDia += Double(baseEntry.diastole)
        count += 1
        if let note = baseEntry.note, !note.isEmpty { notes.append(note) }
        
        for i in 1..<entries.count {
            let nextEntry = entries[i]
            let diffInSeconds = nextEntry.timestamp.timeIntervalSince(baseEntry.timestamp)
            
            if diffInSeconds <= 1800 { // 1800 Sekunden = 30 Minuten
                totalSys += Double(nextEntry.systole)
                totalDia += Double(nextEntry.diastole)
                count += 1
                if let note = nextEntry.note, !note.isEmpty { notes.append(note) }
            } else {
                break
            }
        }
        
        let avgSys = (totalSys / count).rounded()
        let avgDia = (totalDia / count).rounded()
        let combinedNote = notes.isEmpty ? nil : notes.joined(separator: ", ")
        
        return (avgSys, avgDia, combinedNote)
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
                    
                    // NEU: Krankenkasse wird direkt darunter gedruckt, sofern eingetragen
                    if !krankenkasse.isEmpty {
                        Text("\(language == 0 ? "Krankenkasse" : "Health Insurance"): \(krankenkasse)")
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
            
            // --- 2. TABELLE PRO ZEILE (Morgens / Abends aufgeteilt) ---
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Text(language == 0 ? "DATUM" : "DATE")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)
                        .frame(width: 75, alignment: .leading)
                    
                    Text(language == 0 ? "MORGENS (< 12 Uhr)" : "MORNING (< 12 PM)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)
                        .frame(width: 220, alignment: .leading)
                    
                    Text(language == 0 ? "ABENDS (≥ 12 Uhr)" : "EVENING (≥ 12 PM)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)
                        .frame(width: 220, alignment: .leading)
                }
                .padding(.bottom, 6)
                
                Divider()
                
                VStack(spacing: 0) {
                    ForEach(processedTableRows) { row in
                        HStack(spacing: 0) {
                            Text(row.dateString)
                                .font(.system(size: 9, weight: .medium))
                                .frame(width: 75, alignment: .leading)
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text(row.morningText)
                                    .font(.system(size: 9))
                                if let note = row.morningNote {
                                    Text("📝 \(note)")
                                        .font(.system(size: 7))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            .frame(width: 220, alignment: .leading)
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text(row.eveningText)
                                    .font(.system(size: 9))
                                if let note = row.eveningNote {
                                    Text("📝 \(note)")
                                        .font(.system(size: 7))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            .frame(width: 220, alignment: .leading)
                        }
                        .padding(.vertical, 5)
                        
                        Divider()
                    }
                }
            }
            
            Spacer()
            
            // --- FOOTER ---
            HStack {
                Spacer()
                Text(language == 0 ? "Erstellt mit Blutdruck Pro App von Marco Sergio" : "Created with Blood Pressure Pro App von Marco Sergio")
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
