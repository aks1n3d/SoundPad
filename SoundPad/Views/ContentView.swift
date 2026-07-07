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
        NavigationStack {
            ZStack {
                Theme.background
                    .ignoresSafeArea()

                VStack(spacing: 12) {
                    Picker("Bank", selection: $bankStore.selectedBankIndex) {
                        ForEach(bankStore.banks.indices, id: \.self) { i in
                            Text(bankStore.banks[i].name).tag(i)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .labelsHidden()
                    .padding(.horizontal)
                    .padding(.top, 10)

                    if let bank = bankStore.selectedBank {
                        PadGridView(bank: bank)
                    } else {
                        Text("No banks available")
                            .foregroundStyle(Theme.textSecondary)
                        Spacer()
                    }
                }
            }
            .navigationTitle("SoundPad")
            .toolbar {
                ToolbarItemGroup {
                    Button {
                        selectAudioFiles()
                    } label: {
                        Label("Add Sound", systemImage: "plus")
                    }
                    .help("Add audio files")

                    Button {
                        bankStore.addBank()
                    } label: {
                        Label("New Bank", systemImage: "folder.badge.plus")
                    }
                    .help("Create a new bank")

                    Button {
                        openWindow(id: "mixer")
                    } label: {
                        Label("Mixer", systemImage: "slider.horizontal.3")
                    }
                    .help("Open the mixer")
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .preferredColorScheme(.dark)
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
