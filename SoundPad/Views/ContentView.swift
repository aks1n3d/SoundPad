//
//  ContentView.swift
//  Главное окно. Без записи, только воспроизведение.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var audioEngineManager: AudioEngineManager

    var body: some View {
        VStack {
            // Выбор банка (SegmentedPicker)
            Picker("Bank", selection: $audioEngineManager.selectedBankIndex) {
                ForEach(audioEngineManager.banks.indices, id: \.self) { i in
                    Text(audioEngineManager.banks[i].name).tag(i)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)

            HStack {
                Button("Add Audio File") {
                    selectAudioFiles()
                }
                Button("New Bank") {
                    addNewBank()
                }
                Spacer()
            }
            .padding(.vertical, 4)
            .padding(.horizontal)

            if audioEngineManager.selectedBankIndex < audioEngineManager.banks.count {
                let bank = audioEngineManager.banks[audioEngineManager.selectedBankIndex]
                PadGridView(bank: bank)
            } else {
                Text("No banks available")
            }
        }
        .onChange(of: audioEngineManager.banks) { _ in
            audioEngineManager.saveSession()
        }
        .frame(minWidth: 800, minHeight: 600)
    }

    private func selectAudioFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [.audio]
        if panel.runModal() == .OK {
            guard audioEngineManager.selectedBankIndex < audioEngineManager.banks.count else { return }
            for url in panel.urls {
                let newItem = SoundPadItem(title: url.lastPathComponent, url: url)
                audioEngineManager.banks[audioEngineManager.selectedBankIndex].items.append(newItem)
            }
        }
    }

    private func addNewBank() {
        let newBank = SoundBank(name: "Bank \(audioEngineManager.banks.count + 1)", items: [])
        audioEngineManager.banks.append(newBank)
        audioEngineManager.selectedBankIndex = audioEngineManager.banks.count - 1
    }
}
