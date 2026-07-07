//
//  PreferencesView.swift
//  Fade toggle, highlight color, per-app output device. The device picker
//  routes only SoundPad's audio — the system default is never touched.
//

import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject var playbackEngine: PlaybackEngine

    @AppStorage("useFadeInOut") var useFadeInOut: Bool = true
    @AppStorage("highlightColor") var highlightColorHex: String = Theme.defaultHighlightHex
    @AppStorage("outputDeviceUID") var outputDeviceUID: String = ""

    @State private var availableDevices: [AudioDeviceInfo] = []

    var body: some View {
        Form {
            Section("Playback") {
                Toggle("Use Fade In/Out", isOn: $useFadeInOut)
            }

            Section("Appearance") {
                ColorPicker("Highlight color", selection: highlightColorBinding,
                            supportsOpacity: false)
            }

            Section("Audio Output") {
                Picker("Output Device", selection: $outputDeviceUID) {
                    Text("System Default").tag("")
                    ForEach(availableDevices, id: \.uid) { device in
                        Text(device.name).tag(device.uid)
                    }
                }
                Text("Routes only SoundPad's audio — your system output is untouched.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .preferredColorScheme(.dark)
        .onAppear {
            availableDevices = getOutputDevices()
        }
        .onChange(of: outputDeviceUID) { _, newUID in
            playbackEngine.setOutputDevice(uid: newUID.isEmpty ? nil : newUID)
        }
    }

    private var highlightColorBinding: Binding<Color> {
        Binding(
            get: { Theme.highlight(fromHex: highlightColorHex) },
            set: { highlightColorHex = $0.hexString }
        )
    }
}
