//
//  SoundPadApp.swift
//  App entry point. Owns the two stores and the file panels.
//

import SwiftUI
import UniformTypeIdentifiers

@main
struct SoundPadApp: App {
    @StateObject private var bankStore = BankStore()
    @StateObject private var playbackEngine = PlaybackEngine()

    init() {
        // @AppStorage declares this default too, but PlaybackEngine reads
        // UserDefaults directly — register so both see the same value.
        UserDefaults.standard.register(defaults: ["useFadeInOut": true])
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(bankStore)
                .environmentObject(playbackEngine)
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("Save Project As…") {
                    saveProjectAs()
                }
                Button("Open Project…") {
                    openProject()
                }
            }
        }

        Window("Mixer", id: "mixer") {
            MixerView()
                .environmentObject(bankStore)
                .environmentObject(playbackEngine)
        }

        Settings {
            PreferencesView()
                .environmentObject(playbackEngine)
        }
    }

    // MARK: - Project file panels (logic lives in BankStore)

    private func saveProjectAs() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.nameFieldStringValue = "SoundPadProject.json"
        guard savePanel.runModal() == .OK, let url = savePanel.url else { return }
        do {
            try bankStore.saveProject(to: url)
        } catch {
            print("Save project error: \(error)")
        }
    }

    private func openProject() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.json]
        guard openPanel.runModal() == .OK, let url = openPanel.url else { return }
        do {
            playbackEngine.unloadAll()
            try bankStore.openProject(from: url)
        } catch {
            print("Open project error: \(error)")
        }
    }
}
