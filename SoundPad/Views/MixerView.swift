//
//  MixerView.swift
//  Микшер для громкости, панорамы, mute/solo
//

import SwiftUI

struct MixerView: View {
    @EnvironmentObject var audioEngineManager: AudioEngineManager
    @State private var soloItemID: UUID?

    var body: some View {
        VStack {
            Text("Mixer")
                .font(.title)

            if audioEngineManager.selectedBankIndex < audioEngineManager.banks.count {
                let bank = audioEngineManager.banks[audioEngineManager.selectedBankIndex]
                List {
                    ForEach(bank.items) { item in
                        MixerRow(item: binding(for: item), soloItemID: $soloItemID)
                    }
                }
            } else {
                Text("No bank selected.")
            }
        }
        .frame(minWidth: 400, minHeight: 400)
    }

    private func binding(for item: SoundPadItem) -> Binding<SoundPadItem> {
        guard let bankIndex = audioEngineManager.banks.firstIndex(where: { $0.id == audioEngineManager.banks[audioEngineManager.selectedBankIndex].id }),
              let itemIndex = audioEngineManager.banks[bankIndex].items.firstIndex(where: { $0.id == item.id })
        else {
            return .constant(item)
        }
        return Binding<SoundPadItem>(
            get: {
                audioEngineManager.banks[bankIndex].items[itemIndex]
            },
            set: { newValue in
                audioEngineManager.banks[bankIndex].items[itemIndex] = newValue
            }
        )
    }
}

struct MixerRow: View {
    @Binding var item: SoundPadItem
    @Binding var soloItemID: UUID?
    @EnvironmentObject var audioEngineManager: AudioEngineManager

    @State private var isMuted = false

    private var isSolo: Bool {
        soloItemID == item.id
    }

    var body: some View {
        HStack {
            Text(item.title).frame(width: 100, alignment: .leading)

            // Громкость
            Slider(value: $item.volume, in: 0...1)
                .frame(width: 100)
                .onChange(of: item.volume) { newVal in
                    // Если звук играет – обновим громкость "на лету"
                    if let player = audioEngineManager.audioPlayers[item.id] {
                        player.volume = newVal
                    }
                }

            // Пан
            Slider(value: $item.pan, in: -1...1)
                .frame(width: 100)

            Button(isMuted ? "Unmute" : "Mute") {
                isMuted.toggle()
                if isMuted {
                    audioEngineManager.stopSound(item: item)
                }
            }

            Button(isSolo ? "Unsolo" : "Solo") {
                if isSolo {
                    soloItemID = nil
                } else {
                    soloItemID = item.id
                    muteOthersExcept(item.id)
                }
            }
        }
    }

    private func muteOthersExcept(_ keepID: UUID) {
        for (id, player) in audioEngineManager.audioPlayers {
            if id != keepID {
                player.stop()
            }
        }
    }
}
