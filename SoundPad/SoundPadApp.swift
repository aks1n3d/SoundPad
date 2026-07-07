//
//  SoundPadApp.swift
//  App entry point. Owns the two stores and the file panels.
//

import SwiftUI
import UniformTypeIdentifiers

@main
struct SoundPadApp: App {
    @StateObject private var bankStore: BankStore
    @StateObject private var playbackEngine: PlaybackEngine
    @StateObject private var hotkeys: HotkeyController

    init() {
        // @AppStorage declares this default too, but PlaybackEngine reads
        // UserDefaults directly — register so both see the same value.
        UserDefaults.standard.register(defaults: ["useFadeInOut": true])

        // Compose here (not in a view's onAppear) so wiring exists for the
        // app's whole lifetime, whichever windows are open.
        let store = BankStore()
        let engine = PlaybackEngine()
        engine.onBookmarkRefresh = { [weak store] id, data in
            // BankStore's autosave persists the refreshed bookmark.
            store?.refreshBookmark(for: id, data: data)
        }
        engine.setOutputDevice(uid: UserDefaults.standard.string(forKey: "outputDeviceUID"))

        _bankStore = StateObject(wrappedValue: store)
        _playbackEngine = StateObject(wrappedValue: engine)
        _hotkeys = StateObject(wrappedValue: HotkeyController(bankStore: store,
                                                              playbackEngine: engine))
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
            // Decode first: a malformed file must not disturb current playback.
            try bankStore.openProject(from: url)
            playbackEngine.unloadAll()
        } catch {
            print("Open project error: \(error)")
        }
    }
}
