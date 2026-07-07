//
//  ContentView.swift
//  Main window: bank picker, toolbar, pad grid. Playback only, no recording.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var bankStore: BankStore
    @EnvironmentObject var playbackEngine: PlaybackEngine
    @Environment(\.openWindow) private var openWindow

    @AppStorage("outputDeviceUID") private var outputDeviceUID: String = ""

    @State private var hotkeyMonitor = HotkeyMonitor()

    var body: some View {
        VStack {
            Picker("Bank", selection: $bankStore.selectedBankIndex) {
                ForEach(bankStore.banks.indices, id: \.self) { i in
                    Text(bankStore.banks[i].name).tag(i)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)

            HStack {
                Button("Add Audio File") {
                    selectAudioFiles()
                }
                Button("New Bank") {
                    bankStore.addBank()
                }
                Spacer()
                Button("Mixer") {
                    openWindow(id: "mixer")
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal)

            if let bank = bankStore.selectedBank {
                PadGridView(bank: bank)
            } else {
                Text("No banks available")
            }
        }
        .onChange(of: bankStore.banks) {
            try? bankStore.saveSession()
        }
        .onAppear {
            wireEngine()
            startHotkeys()
        }
        .onDisappear {
            hotkeyMonitor.stop()
        }
        .frame(minWidth: 800, minHeight: 600)
    }

    private func wireEngine() {
        playbackEngine.onBookmarkRefresh = { [weak bankStore] id, data in
            bankStore?.refreshBookmark(for: id, data: data)
            try? bankStore?.saveSession()
        }
        // Apply the persisted per-app output routing ("" = system default).
        playbackEngine.setOutputDevice(uid: outputDeviceUID.isEmpty ? nil : outputDeviceUID)
    }

    private func startHotkeys() {
        hotkeyMonitor.start { key in
            guard let item = bankStore.item(withHotkey: key) else { return false }
            playbackEngine.toggle(item: item)
            return true
        }
    }

    private func selectAudioFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [.audio]
        if panel.runModal() == .OK {
            bankStore.addItems(urls: panel.urls)
        }
    }
}
