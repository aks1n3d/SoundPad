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
        ZStack {
            Theme.background
                .ignoresSafeArea()

            if let bank = bankStore.selectedBank, !bank.items.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(bank.items) { item in
                            MixerRow(item: item)
                        }
                    }
                    .padding()
                }
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 40))
                        .foregroundStyle(Theme.textSecondary)
                    Text("No sounds in the selected bank")
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .navigationTitle("Mixer")
        .frame(minWidth: 620, minHeight: 400)
        .preferredColorScheme(.dark)
    }
}

struct MixerRow: View {
    @EnvironmentObject var bankStore: BankStore
    @EnvironmentObject var playbackEngine: PlaybackEngine

    let item: SoundPadItem

    @AppStorage("highlightColor") private var highlightColorHex: String = Theme.defaultHighlightHex
    @State private var hotkeyText: String = ""

    private var isMuted: Bool {
        playbackEngine.mutedItemIDs.contains(item.id)
    }

    private var isSolo: Bool {
        playbackEngine.soloItemID == item.id
    }

    private var highlight: Color {
        Theme.highlight(fromHex: highlightColorHex)
    }

    var body: some View {
        HStack(spacing: 14) {
            Text(item.title)
                .font(.callout.weight(.medium))
                .foregroundStyle(.white)
                .frame(width: 120, alignment: .leading)
                .lineLimit(1)

            HStack(spacing: 6) {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                Slider(value: volumeBinding, in: 0...1)
                    .frame(width: 110)
            }

            HStack(spacing: 6) {
                Text("L")
                    .font(.caption2)
                    .foregroundStyle(Theme.textSecondary)
                Slider(value: panBinding, in: -1...1)
                    .frame(width: 90)
                Text("R")
                    .font(.caption2)
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer(minLength: 0)

            roundToggle(
                systemImage: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                active: isMuted,
                activeColor: .red,
                help: isMuted ? "Unmute" : "Mute"
            ) {
                playbackEngine.toggleMute(item.id)
            }

            roundToggle(
                systemImage: "headphones",
                active: isSolo,
                activeColor: highlight,
                help: isSolo ? "Unsolo" : "Solo"
            ) {
                playbackEngine.setSolo(isSolo ? nil : item.id)
            }

            TextField("Key", text: $hotkeyText)
                .textFieldStyle(PlainTextFieldStyle())
                .multilineTextAlignment(.center)
                .frame(width: 34, height: 24)
                .background(RoundedRectangle(cornerRadius: 6).fill(Theme.controlFill))
                .help("Hotkey for this pad")
                .onChange(of: hotkeyText) { _, newValue in
                    commitHotkey(newValue)
                }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Theme.cardBorder, lineWidth: 1)
                )
        )
        .onAppear {
            hotkeyText = item.hotkey ?? ""
        }
        .onChange(of: item.hotkey) { _, newValue in
            // Assigning this key to another pad clears it here.
            hotkeyText = newValue ?? ""
        }
    }

    private func roundToggle(systemImage: String,
                             active: Bool,
                             activeColor: Color,
                             help: String,
                             action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(active ? activeColor : Theme.textSecondary)
                .frame(width: 28, height: 28)
                .background(
                    Circle().fill(active ? activeColor.opacity(0.18) : Theme.controlFill)
                )
        }
        .buttonStyle(.plain)
        .help(help)
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
