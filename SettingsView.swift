import SwiftUI

struct SettingsView: View {
    // --- PERSISTENTE SPEICHERUNG VIA APPSTORAGE ---
    @AppStorage("reportPeriodDays") private var reportPeriodDays: Int = 7
    @AppStorage("profileName") private var profileName: String = ""
    @AppStorage("profileBirthdate") private var profileBirthdate: String = ""
    @AppStorage("appLanguage") private var appLanguage: Int = 0 // 0 = DE, 1 = EN
    
    // SPEICHERUNG FÜR DIE KRANKENKASSE (synchronisiert mit Onboarding)
    @AppStorage("krankenkasse") private var krankenkasse: String = ""
    
    // --- SPEICHERUNG FÜR DAS ERSCHEINUNGSBILD ---
    // 0 = System, 1 = Hell, 2 = Dunkel
    @AppStorage("appColorScheme") private var appColorScheme: Int = 0
    
    // Optionen für den Berichtszeitraum
    let periodOptions = [3, 5, 7, 14, 30, 90]
    
    var body: some View {
        NavigationStack {
            Form {
                // --- SEKTION 1: PROFIL ---
                Section(header: Text("Persönliche Daten")) {
                    HStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.title3)
                            .foregroundColor(.red)
                            .frame(width: 24)
                        
                        TextField("Name", text: $profileName)
                            .textInputAutocapitalization(.words)
                    }
                    
                    HStack(spacing: 12) {
                        Image(systemName: "calendar")
                            .font(.title3)
                            .foregroundColor(.red)
                            .frame(width: 24)
                        
                        TextField("Geburtsdatum (z.B. 10.08.1990)", text: $profileBirthdate)
                            .keyboardType(.numbersAndPunctuation)
                    }
                    
                    // Optimiertes Feld für die Krankenkasse
                    HStack(spacing: 12) {
                        Image(systemName: "shield.hospital.fill")
                            .font(.title3)
                            .foregroundColor(.red)
                            .frame(width: 24)
                        
                        Text("Krankenkasse")
                        
                        Spacer()
                        
                        TextField("z.B. TK, AOK", text: $krankenkasse)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.secondary)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                    }
                }
                
                // --- SEKTION 2: ANZEIGE & DESIGN ---
                Section(
                    header: Text("Anzeige & Design"),
                    footer: Text("Bestimmt, wie viele Tage standardmäßig im Verlauf, in der Grafik und beim PDF-Arztexport berücksichtigt werden.")
                ) {
                    // Berichtszeitraum
                    HStack(spacing: 12) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.title3)
                            .foregroundColor(.red)
                            .frame(width: 24)
                        
                        Picker("Zeitraum für Arzt", selection: $reportPeriodDays) {
                            ForEach(periodOptions, id: \.self) { days in
                                Text("\(days) Tage").tag(days)
                            }
                        }
                        .pickerStyle(.navigationLink)
                    }
                    
                    // Farbschema / Darkmode Picker
                    HStack(spacing: 12) {
                        Image(systemName: appColorScheme == 2 ? "moon.fill" : (appColorScheme == 1 ? "sun.max.fill" : "circle.dashed.inset.filled"))
                            .font(.title3)
                            .foregroundColor(.red)
                            .frame(width: 24)
                        
                        Picker("Erscheinungsbild", selection: $appColorScheme) {
                            Text("System").tag(0)
                            Text("Hell").tag(1)
                            Text("Dunkel").tag(2)
                        }
                        .pickerStyle(.menu)
                    }
                }
                
                // --- SEKTION 3: SPRACHE ---
                Section(header: Text("Sprache")) {
                    HStack(spacing: 12) {
                        Image(systemName: "globe")
                            .font(.title3)
                            .foregroundColor(.red)
                            .frame(width: 24)
                        
                        Picker("App-Sprache", selection: $appLanguage) {
                            Text("Deutsch 🇩🇪").tag(0)
                            Text("English 🇺🇸").tag(1)
                        }
                        .pickerStyle(.menu)
                    }
                }
                
                // --- SEKTION 4: DATENAUSTAUSCH ---
                Section(header: Text("Datenaustausch")) {
                    Button(action: {
                        // CSV Export Logik hier aufrufen
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "doc.arrow.up.fill")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            Text("CSV exportieren")
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Button(action: {
                        // CSV Import Logik hier aufrufen
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "doc.arrow.down.fill")
                                .foregroundColor(.green)
                                .frame(width: 24)
                            Text("CSV Daten importieren")
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            .navigationTitle("Einstellungen")
        }
    }
}

#Preview {
    SettingsView()
}
