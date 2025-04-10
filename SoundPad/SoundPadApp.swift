//
//  SoundPadApp.swift
//  Точка входа в приложение
//

import SwiftUI

@main
struct SoundPadApp: App {
    @StateObject private var audioEngineManager = AudioEngineManager()

    // Настройки (AppStorage)
    @AppStorage("selectedOutputDeviceID") var selectedOutputDeviceID: Int = 0
    @AppStorage("useFadeInOut") var useFadeInOut: Bool = true
    @AppStorage("highlightColor") var highlightColorHex: String = "#FFD700"

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(audioEngineManager)
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("Save Project As…") {
                    audioEngineManager.saveProjectAs()
                }
                Button("Open Project…") {
                    audioEngineManager.openProject()
                }
            }
        }

        // SwiftUI Preferences window (macOS 13+)
        Settings {
            PreferencesView()
                .environmentObject(audioEngineManager)
        }
    }
}
