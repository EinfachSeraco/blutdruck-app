import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ContentView: View {
    @Query var measurements: [BloodPressure]
    @Environment(\.modelContext) private var modelContext
    
    @State private var sysInput = ""
    @State private var diaInput = ""
    @State private var noteInput = ""
    @State private var statusMessage = ""
    
    @State private var isMenuOpen = false
    
    // Steuerungs-Zustände für Import, Reset-Warnung und das Einstellungs-Untermenü
    @State private var isImporting = false
    @State private var showResetAlert = false
    @State private var isSettingsOpen = false
    
    // Gespeicherte Einstellungen (Farbschema, Sprache & Berichtszeitraum)
    @AppStorage("selectedColorScheme") private var selectedColorScheme = 0
    @AppStorage("selectedLanguage") private var selectedLanguage = 0
    @AppStorage("reportPeriodDays") private var reportPeriodDays = 7 // Standardmäßig 7 Tage
    
    // Optionen für den Berichtszeitraum Picker
    let periodOptions = [3, 5, 7, 14, 30, 90]
    
    // Dauerhaft gespeicherte Profil-Metadaten für das PDF
    @AppStorage("profileName") private var profileName = ""
    @AppStorage("profileBirthdate") private var profileBirthdate = ""
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    private var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (Build \(build))"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // --- 1. HAUPTANSICHT (Eingabemaske) ---
                VStack(spacing: 24) {
                    Spacer()
                        .frame(height: 10)
                    
                    Text(selectedLanguage == 0 ? "Neue Messung" : "New Measurement")
                        .font(.title)
                        .bold()
                    
                    TextField(selectedLanguage == 0 ? "Systole" : "Systole", text: $sysInput)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField(selectedLanguage == 0 ? "Diastole" : "Diastole", text: $diaInput)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField(selectedLanguage == 0 ? "Bemerkung (z.B. Nach dem Sport...)" : "Notes (e.g. After sports...)", text: $noteInput)
                        .textFieldStyle(.roundedBorder)
                    
                    Button(action: {
                        saveMeasurement()
                    }) {
                        Text(selectedLanguage == 0 ? "Speichern" : "Save")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(10)
                    }
                    
                    if !statusMessage.isEmpty {
                        Text(statusMessage)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    Spacer()
                }
                .padding()
                .blur(radius: isMenuOpen ? 4 : 0)
                .disabled(isMenuOpen)
                
                // --- 2. HINTERGRUND-ABDECKUNG ---
                if isMenuOpen {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut) {
                                isMenuOpen = false
                                isSettingsOpen = false
                            }
                        }
                }
                
                // --- 3. SEITENMENÜ & EINSTELLUNGEN ---
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        ZStack {
                            // ==========================================
                            // HAUPTMENÜ-EBENE (Bürgermenu)
                            // ==========================================
                            VStack(alignment: .leading, spacing: 24) {
                                Text(selectedLanguage == 0 ? "Menü" : "Menu")
                                    .font(.title)
                                    .bold()
                                    .padding(.top, 60)
                                
                                Divider()
                                
                                NavigationLink(destination: HistoryView().onAppear { isMenuOpen = false }) {
                                    Label(selectedLanguage == 0 ? "Verlauf" : "History", systemImage: "list.bullet.clipboard")
                                        .font(.headline)
                                        .foregroundColor(.red)
                                }
                                
                                NavigationLink(destination: GraphView().onAppear { isMenuOpen = false }) {
                                    Label(selectedLanguage == 0 ? "Graph" : "Chart", systemImage: "chart.xyaxis.line")
                                        .font(.headline)
                                        .foregroundColor(.red)
                                }
                                
                                // PDF Export im Hauptmenü
                                if !measurements.isEmpty {
                                    ShareLink(item: generatePDFReport()) {
                                        Label(selectedLanguage == 0 ? "PDF Bericht erstellen" : "Generate PDF Report", systemImage: "doc.text.image")
                                            .font(.headline)
                                            .foregroundColor(.red)
                                    }
                                } else {
                                    Label(selectedLanguage == 0 ? "PDF Bericht (Keine Daten)" : "PDF Report (No Data)", systemImage: "doc.text")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Divider()
                                
                                Button(action: {
                                    withAnimation(.easeInOut) {
                                        isSettingsOpen = true
                                    }
                                }) {
                                    Label(selectedLanguage == 0 ? "Einstellungen" : "Settings", systemImage: "gearshape")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }
                                
                                Spacer()
                                
                                Text(appVersionString)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.bottom, 20)
                            }
                            .padding()
                            
                            // ==========================================
                            // EINSTELLUNGEN-EBENE (Untermenü)
                            // ==========================================
                            if isSettingsOpen {
                                ScrollView {
                                    VStack(alignment: .leading, spacing: 24) {
                                        Button(action: {
                                            withAnimation(.easeInOut) {
                                                isSettingsOpen = false
                                            }
                                        }) {
                                            HStack {
                                                Image(systemName: "chevron.left")
                                                Text(selectedLanguage == 0 ? "Zurück" : "Back")
                                            }
                                            .font(.headline)
                                            .foregroundColor(.red)
                                        }
                                        .padding(.top, 60)
                                        
                                        Text(selectedLanguage == 0 ? "Einstellungen" : "Settings")
                                            .font(.title)
                                            .bold()
                                        
                                        Divider()
                                        
                                        // Profilbearbeitung
                                        VStack(spacing: 12) {
                                            TextField(selectedLanguage == 0 ? "Name" : "Name", text: $profileName)
                                                .textFieldStyle(.roundedBorder)
                                            TextField(selectedLanguage == 0 ? "Geburtsdatum (z.B. 10. Aug. 1990)" : "Birthdate (e.g. Aug 10, 1990)", text: $profileBirthdate)
                                                .textFieldStyle(.roundedBorder)
                                        }
                                        
                                        Divider()
                                        
                                        // NEU: Berichtszeitraum für den Arzt
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(selectedLanguage == 0 ? "Berichtszeitraum (Standard)" : "Report Period (Default)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            
                                            Picker("Zeitraum", selection: $reportPeriodDays) {
                                                ForEach(periodOptions, id: \.self) { days in
                                                    Text("\(days) \(selectedLanguage == 0 ? "Tage" : "Days")")
                                                        .tag(days)
                                                }
                                            }
                                            .pickerStyle(.menu)
                                            .labelsHidden()
                                            
                                            Text(selectedLanguage == 0 ? "Bestimmt die Dauer des Protokolls im Graphen, Verlauf und PDF-Export." : "Determines the protocol length in chart, history, and PDF export.")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Divider()
                                        
                                        // App-Sprache
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(selectedLanguage == 0 ? "App-Sprache" : "App Language")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            
                                            Picker("Sprache", selection: $selectedLanguage) {
                                                Text("Deutsch 🇩🇪").tag(0)
                                                Text("English 🇺🇸").tag(1)
                                            }
                                            .pickerStyle(.segmented)
                                        }
                                        
                                        Divider()
                                        
                                        // Datenaustausch
                                        Text(selectedLanguage == 0 ? "Datenaustausch" : "Data Transfer")
                                            .font(.subheadline)
                                            .bold()
                                            .foregroundColor(.secondary)
                                        
                                        VStack(alignment: .leading, spacing: 16) {
                                            if !measurements.isEmpty {
                                                ShareLink(item: generateCSVFile()) {
                                                    Label(selectedLanguage == 0 ? "CSV Exportieren" : "Export CSV", systemImage: "doc.plaintext")
                                                        .font(.headline)
                                                        .foregroundColor(.blue)
                                                }
                                            } else {
                                                Label(selectedLanguage == 0 ? "Keine Daten" : "No Data", systemImage: "doc.text")
                                                    .font(.headline)
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            Divider()
                                            
                                            Button(action: {
                                                isMenuOpen = false
                                                isSettingsOpen = false
                                                isImporting = true
                                            }) {
                                                Label(selectedLanguage == 0 ? "CSV Daten importieren" : "Import CSV Data", systemImage: "square.and.arrow.down")
                                                    .font(.headline)
                                                    .foregroundColor(.green)
                                            }
                                        }
                                        
                                        Divider()
                                        
                                        // Ausklappbarer Datenschutz-Bereich
                                        DisclosureGroup(
                                            content: {
                                                VStack(alignment: .leading, spacing: 10) {
                                                    Text(selectedLanguage == 0 ? "1. Lokale Speicherung" : "1. Local Storage")
                                                        .font(.subheadline).bold()
                                                    Text(selectedLanguage == 0 ? "Alle von Ihnen eingegebenen Blutdruck-Messwerte sowie Ihre optionalen Profildaten (Name und Geburtsdatum) werden ausschließlich lokal im gesicherten Sandboxed-Speicher Ihres Endgeräts über das Apple SwiftData Framework gesichert." : "All entered blood pressure measurements and optional profile details (name and birthdate) are stored exclusively in your device's secure sandboxed storage using Apple's SwiftData framework.")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                    
                                                    Text(selectedLanguage == 0 ? "2. Keine Cloud-Übertragung" : "2. No Cloud Transmission")
                                                        .font(.subheadline).bold()
                                                    Text(selectedLanguage == 0 ? "Diese App verfügt über keine externe Server-Anbindung. Es findet zu keinem Zeitpunkt eine Übermittlung, Analyse oder Verwertung Ihrer Gesundheitsdaten durch den Entwickler oder Dritte statt." : "This app does not connect to external servers. Your health data is never transmitted, analyzed, or processed by the developer or any third party.")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                    
                                                    Text(selectedLanguage == 0 ? "3. Volle Datenkontrolle" : "3. Data Control")
                                                        .font(.subheadline).bold()
                                                    Text(selectedLanguage == 0 ? "Über die Funktionen 'CSV Exportieren' und 'Daten zurücksetzen' behalten Sie jederzeit die volle Kontrolle über Ihre exportierten Protokolle sowie die Möglichkeit, alle Daten unwiderruflich vom Gerät zu löschen." : "Using 'Export CSV' and 'Reset Data', you retain full control over your exported records, including the option to permanently wipe all information from your device.")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                                .padding(.top, 6)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            },
                                            label: {
                                                Label(selectedLanguage == 0 ? "Datenschutzbericht" : "Privacy Policy", systemImage: "lock.shield")
                                                    .font(.headline)
                                                    .foregroundColor(.primary)
                                            }
                                        )
                                        
                                        Divider()
                                        
                                        Button(action: {
                                            isMenuOpen = false
                                            isSettingsOpen = false
                                            showResetAlert = true
                                        }) {
                                            Label(selectedLanguage == 0 ? "Daten zurücksetzen" : "Reset Data", systemImage: "trash")
                                                .font(.headline)
                                                .foregroundColor(.red)
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding()
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                .background(Color(.systemBackground))
                                .transition(.move(edge: .trailing))
                            }
                        }
                        .frame(width: geometry.size.width * 0.75)
                        .background(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 5, y: 0)
                        
                        Spacer()
                    }
                    .offset(x: isMenuOpen ? 0 : -geometry.size.width)
                }
            }
            .navigationTitle(selectedLanguage == 0 ? "Blutdruck" : "Blood Pressure")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        withAnimation(.easeInOut) {
                            isMenuOpen.toggle()
                            if !isMenuOpen { isSettingsOpen = false }
                        }
                    }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        withAnimation(.easeInOut) {
                            selectedColorScheme = (selectedColorScheme + 1) % 3
                        }
                    }) {
                        Image(systemName: selectedColorScheme == 1 ? "sun.max.fill" : (selectedColorScheme == 2 ? "moon.fill" : "circle.lefthalf.striped.horizontal"))
                            .font(.title3)
                            .foregroundColor(.red)
                    }
                }
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.commaSeparatedText],
                allowsMultipleSelection: false
            ) { result in
                importCSVFile(from: result)
            }
            .alert(isPresented: $showResetAlert) {
                Alert(
                    title: Text(selectedLanguage == 0 ? "Daten löschen?" : "Delete data?"),
                    message: Text(selectedLanguage == 0 ? "Möchtest du wirklich alle aufgezeichneten Messwerte unwiderruflich löschen?" : "Are you sure you want to permanently delete all recorded measurements?"),
                    primaryButton: .destructive(Text(selectedLanguage == 0 ? "Löschen" : "Delete")) {
                        resetAllData()
                    },
                    secondaryButton: .cancel()
                )
            }
            // Onboarding-Sheet
            .sheet(isPresented: .init(get: { !hasCompletedOnboarding }, set: { hasCompletedOnboarding = !$0 })) {
                VStack(spacing: 24) {
                    Text(selectedLanguage == 0 ? "Willkommen!" : "Welcome!")
                        .font(.largeTitle)
                        .bold()
                        .padding(.top, 40)
                    
                    Text(selectedLanguage == 0 ? "Für deinen PDF-Arztbericht kannst du hier deine Profildaten kontrollieren oder anpassen:" : "For your PDF report, verify or adjust your optional profile details here:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(selectedLanguage == 0 ? "Name" : "Name")
                            .font(.caption).bold().foregroundColor(.secondary)
                        TextField("Z.B. Max Mustermann", text: $profileName)
                            .textFieldStyle(.roundedBorder)
                        
                        Text(selectedLanguage == 0 ? "Geburtsdatum (Optional)" : "Date of Birth (Optional)")
                            .font(.caption).bold().foregroundColor(.secondary)
                            .padding(.top, 10)
                        
                        TextField("Z.B. 10. Aug. 1990", text: $profileBirthdate)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding()
                    
                    Spacer()
                    
                    Button(action: {
                        hasCompletedOnboarding = true
                    }) {
                        Text(selectedLanguage == 0 ? "App starten" : "Get Started")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(10)
                    }
                    .padding()
                }
                .onAppear {
                    setupInitialProfileName()
                }
                .interactiveDismissDisabled()
            }
        }
        .preferredColorScheme(selectedColorScheme == 1 ? .light : (selectedColorScheme == 2 ? .dark : nil))
        .environment(\.locale, selectedLanguage == 0 ? Locale(identifier: "de") : Locale(identifier: "en"))
    }
    
    // --- FUNCTIONS ---
    
    private func setupInitialProfileName() {
        guard profileName.isEmpty else { return }
        let deviceName = UIDevice.current.name
        let cleanName = deviceName
            .replacingOccurrences(of: "iPhone von ", with: "")
            .replacingOccurrences(of: "s iPhone", with: "")
            .replacingOccurrences(of: "iPhone", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        self.profileName = cleanName.isEmpty ? "Patient" : cleanName
    }
    
    @MainActor
    private func generatePDFReport() -> URL {
        // Berechne den gefilterten Zeitraum für den Arztbericht
        let calendar = Calendar.current
        let filterStartDate = calendar.date(byAdding: .day, value: -reportPeriodDays, to: Date()) ?? Date()
        let filteredMeasurements = measurements.filter { $0.timestamp >= filterStartDate }
        
        let reportView = PDFReportView(measurements: filteredMeasurements, language: selectedLanguage, profileName: profileName, profileBirthdate: profileBirthdate)
        let renderer = ImageRenderer(content: reportView)
        let path = FileManager.default.temporaryDirectory.appendingPathComponent("Blutdruck_Bericht.pdf")
        
        renderer.render { size, context in
            var box = CGRect(origin: .zero, size: size)
            guard let pdfContext = CGContext(path as CFURL, mediaBox: &box, nil) else { return }
            
            pdfContext.beginPDFPage(nil)
            context(pdfContext)
            pdfContext.endPDFPage()
            pdfContext.closePDF()
        }
        return path
    }
    
    private func generateCSVFile() -> URL {
        var csvString = ""
        if selectedLanguage == 0 {
            csvString = "Datum;Morgens_1_SYS;Morgens_1_DIA;Morgens_2_SYS;Morgens_2_DIA;Abends_1_SYS;Abends_1_DIA;Abends_2_SYS;Abends_2_DIA\n"
        } else {
            csvString = "Date;Morning_1_SYS;Morning_1_DIA;Morning_2_SYS;Morning_2_DIA;Evening_1_SYS;Evening_1_DIA;Evening_2_SYS;Evening_2_DIA\n"
        }
        
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let sortedMeasurements = measurements.sorted { $0.timestamp < $1.timestamp }
        let groupedByDay = Dictionary(grouping: sortedMeasurements) { dateFormatter.string(from: $0.timestamp) }
        let sortedDays = groupedByDay.keys.sorted()
        
        for day in sortedDays {
            guard let dayMeasurements = groupedByDay[day] else { continue }
            
            let morningEntries = dayMeasurements.filter { calendar.component(.hour, from: $0.timestamp) < 12 }
            let eveningEntries = dayMeasurements.filter { calendar.component(.hour, from: $0.timestamp) >= 12 }
            
            let m1_sys = morningEntries.count > 0 ? "\(morningEntries[0].systole)" : ""
            let m1_dia = morningEntries.count > 0 ? "\(morningEntries[0].diastole)" : ""
            let m2_sys = morningEntries.count > 1 ? "\(morningEntries[1].systole)" : ""
            let m2_dia = morningEntries.count > 1 ? "\(morningEntries[1].diastole)" : ""
            
            let e1_sys = eveningEntries.count > 0 ? "\(eveningEntries[0].systole)" : ""
            let e1_dia = eveningEntries.count > 0 ? "\(eveningEntries[0].diastole)" : ""
            let e2_sys = eveningEntries.count > 1 ? "\(eveningEntries[1].systole)" : ""
            let e2_dia = eveningEntries.count > 1 ? "\(eveningEntries[1].diastole)" : ""
            
            let row = "\(day);\(m1_sys);\(m1_dia);\(m2_sys);\(m2_dia);\(e1_sys);\(e1_dia);\(e2_sys);\(e2_dia)\n"
            csvString.append(row)
        }
        
        let path = FileManager.default.temporaryDirectory.appendingPathComponent("Blutdruck_Protokoll.csv")
        do {
            try csvString.write(to: path, atomically: true, encoding: .utf8)
        } catch {
            print("Fehler beim Erstellen der CSV-Datei: \(error)")
        }
        return path
    }
    
    private func importCSVFile(from result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let selectedURL = urls.first else { return }
            guard selectedURL.startAccessingSecurityScopedResource() else { return }
            defer { selectedURL.stopAccessingSecurityScopedResource() }
            
            do {
                let content = try String(contentsOf: selectedURL, encoding: .utf8)
                let lines = content.components(separatedBy: .newlines)
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
                
                var importCount = 0
                
                for i in 1..<lines.count {
                    let line = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
                    if line.isEmpty { continue }
                    
                    let columns = line.components(separatedBy: ";")
                    if columns.count >= 4 {
                        let fullDateStr = "\(columns[0]) \(columns[1])"
                        guard let date = dateFormatter.date(from: fullDateStr),
                              let sys = Int(columns[2]),
                              let dia = Int(columns[3]) else { continue }
                        
                        let note = columns.count > 4 ? (columns[4].isEmpty ? nil : columns[4]) : nil
                        
                        let entry = BloodPressure(systole: sys, diastole: dia, timestamp: date, note: note)
                        modelContext.insert(entry)
                        importCount += 1
                    }
                }
                statusMessage = selectedLanguage == 0 ? "Erfolgreich \(importCount) Werte importiert!" : "Successfully imported \(importCount) values!"
            } catch {
                statusMessage = selectedLanguage == 0 ? "Fehler beim Lesen der Datei" : "Error reading file"
            }
        case .failure(let error):
            statusMessage = "Import Error: \(error.localizedDescription)"
        }
    }
    
    private func resetAllData() {
        do {
            try modelContext.delete(model: BloodPressure.self)
            statusMessage = selectedLanguage == 0 ? "Alle Daten gelöscht!" : "All data deleted!"
        } catch {
            statusMessage = "Error: \(error.localizedDescription)"
        }
    }
    
    private func saveMeasurement() {
        guard let sys = Int(sysInput), let dia = Int(diaInput) else {
            statusMessage = selectedLanguage == 0 ? "Bitte Zahlen eingeben!" : "Please enter numbers!"
            return
        }
        
        let cleanNote = noteInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let noteToSave = cleanNote.isEmpty ? nil : cleanNote
        
        let entry = BloodPressure(systole: sys, diastole: dia, note: noteToSave)
        modelContext.insert(entry)
        
        sysInput = ""
        diaInput = ""
        noteInput = ""
        
        let totalSys = measurements.reduce(0) { $0 + $1.systole } + sys
        let totalDia = measurements.reduce(0) { $0 + $1.diastole } + dia
        let count = measurements.count + 1
        
        if selectedLanguage == 0 {
            statusMessage = "Gespeichert!\nAnzahl: \(count) | Ø: \(totalSys / count)/\(totalDia / count) mmHg"
        } else {
            statusMessage = "Saved!\nTotal: \(count) | Avg: \(totalSys / count)/\(totalDia / count) mmHg"
        }
    }
}
