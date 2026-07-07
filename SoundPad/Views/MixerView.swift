//
//  MixerView.swift
//  Volume, pan, mute/solo and hotkey per pad. Volume/pan persist via
//  BankStore; mute/solo are runtime state in PlaybackEngine.
//

import SwiftUI

struct MixerView: View {
    @EnvironmentObject var bankStore: BankStore
    @EnvironmentObject var playbackEngine: PlaybackEngine

    var body: some View {
        VStack {
            Text("Mixer")
                .font(.title)

            if let bank = bankStore.selectedBank, !bank.items.isEmpty {
                List {
                    ForEach(bank.items) { item in
                        MixerRow(item: item)
                    }
                }
            } else {
                Text("No sounds in the selected bank.")
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding(.top, 8)
        .frame(minWidth: 560, minHeight: 400)
    }
}

struct MixerRow: View {
    @EnvironmentObject var bankStore: BankStore
    @EnvironmentObject var playbackEngine: PlaybackEngine

    let item: SoundPadItem

    @State private var hotkeyText: String = ""

    private var isMuted: Bool {
        playbackEngine.mutedItemIDs.contains(item.id)
    }

    private var isSolo: Bool {
        playbackEngine.soloItemID == item.id
    }

    var body: some View {
        HStack {
            Text(item.title)
                .frame(width: 110, alignment: .leading)
                .lineLimit(1)

            Label {
                Slider(value: volumeBinding, in: 0...1)
                    .frame(width: 100)
            } icon: {
                Image(systemName: "speaker.wave.2")
            }

            Label {
                Slider(value: panBinding, in: -1...1)
                    .frame(width: 100)
            } icon: {
                Image(systemName: "arrow.left.and.right")
            }

            Button(isMuted ? "Unmute" : "Mute") {
                playbackEngine.toggleMute(item.id)
            }

            Button(isSolo ? "Unsolo" : "Solo") {
                playbackEngine.setSolo(isSolo ? nil : item.id)
            }

            TextField("Key", text: $hotkeyText)
                .frame(width: 36)
                .multilineTextAlignment(.center)
                .onChange(of: hotkeyText) { _, newValue in
                    commitHotkey(newValue)
                }
        }
        .onAppear {
            hotkeyText = item.hotkey ?? ""
        }
        .onChange(of: item.hotkey) { _, newValue in
            // Assigning this key to another pad clears it here.
            hotkeyText = newValue ?? ""
        }
    }

    private var volumeBinding: Binding<Float> {
        Binding(
            get: { bankStore.item(id: item.id)?.volume ?? item.volume },
            set: { newValue in
                bankStore.updateItem(id: item.id) { $0.volume = newValue }
                playbackEngine.setVolume(newValue, for: item.id)
            }
        )
    }

    private var panBinding: Binding<Float> {
        Binding(
            get: { bankStore.item(id: item.id)?.pan ?? item.pan },
            set: { newValue in
                bankStore.updateItem(id: item.id) { $0.pan = newValue }
                playbackEngine.setPan(newValue, for: item.id)
            }
        )
    }

    private func commitHotkey(_ text: String) {
        // Keep at most one character; typing replaces the old binding.
        let key = text.suffix(1).lowercased()
        if key != text {
            hotkeyText = String(key)
        }
        bankStore.assignHotkey(key.isEmpty ? nil : String(key), to: item.id)
    }
}
