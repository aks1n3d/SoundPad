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
        .frame(minWidth: 800, minHeight: 600)
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
