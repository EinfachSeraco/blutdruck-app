# Blood Pressure Tracker (Blutdruck App)

A clean, native iOS application built with SwiftUI to log, visualize, and export daily blood pressure and pulse readings. Designed with focus on clarity, privacy, and ease of use.

---

## Features

- **Quick & Intuitive Logging**: Record systolic, diastolic pressure, and pulse values in seconds.
- **Visual Trends & Graphs**: Interactive charts (`GraphView`) to spot long-term patterns, averages, and blood pressure spikes.
- **Comprehensive History**: Full log of all previous measurements (`HistoryView`) with clear timestamps and status indicators.
- **PDF Report Generation**: Export formatted medical-style summary reports (`PDFReportView`) ready to share with doctors or save locally.
- **Customizable Settings**: Configure measurement targets, units, and appearance directly in the app.
- **Privacy-First**: All sensitive health data remains stored locally on your device.

---

## Tech Stack & Architecture

- **Language**: Swift
- **UI Framework**: SwiftUI
- **Target Platform**: iOS 17+
- **Reporting**: Core Graphics / PDFKit for generating printable health reports

---

## Project Structure

```text
├── BlutdruckApp.swift       # Main application lifecycle entry point
├── ContentView.swift         # Core navigation and primary user dashboard
├── BloodPressure.swift       # Data model and measurement business logic
├── GraphView.swift           # Visual data representations & trends
├── HistoryView.swift         # Detailed log & measurement history
├── PDFReportView.swift       # Document compilation & PDF export
├── SettingsView.swift        # User preferences and targets
└── Assets.xcassets/          # App icons, colors, and visual assets
Getting Started
Prerequisites
Xcode 15.0 or later

macOS Sonoma or later

An active iOS simulator or physical device running iOS 17+

Installation
Clone the repository:

Bash
git clone [https://github.com/your-username/blutdruck-app.git](https://github.com/your-username/blutdruck-app.git)
cd blutdruck-app
Open the project in Xcode:

Bash
open Blutdruck.xcodeproj
# or Blutdruck.xcworkspace if using dependency managers
Build & Run:

Select your target device or simulator.

Press Cmd + R to compile and launch.

Roadmap
[ ] HealthKit integration (sync with Apple Health)

[ ] CSV / Excel data export alongside PDF

[ ] Medication intake tracking & reminders

[ ] iPadOS and Mac Catalyst support

License
This project is licensed under the MIT License — see the LICENSE file for details.
