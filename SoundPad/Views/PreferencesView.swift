//
//  PreferencesView.swift
//  Fade toggle, highlight color, per-app output device. The device picker
//  routes only SoundPad's audio — the system default is never touched.
//

import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject var playbackEngine: PlaybackEngine

    @AppStorage("useFadeInOut") var useFadeInOut: Bool = true
    @AppStorage("highlightColor") var highlightColorHex: String = "#FFD700"
    @AppStorage("outputDeviceUID") var outputDeviceUID: String = ""

    @State private var availableDevices: [AudioDeviceInfo] = []

    var body: some View {
        Form {
            Toggle("Use Fade In/Out", isOn: $useFadeInOut)

            ColorPicker("Highlight color:", selection: highlightColorBinding,
                        supportsOpacity: false)

            Divider()

            Picker("Output Device:", selection: $outputDeviceUID) {
                Text("System Default").tag("")
                ForEach(availableDevices, id: \.uid) { device in
                    Text(device.name).tag(device.uid)
                }
            }
        }
        .padding()
        .frame(width: 400)
        .onAppear {
            availableDevices = getOutputDevices()
        }
        .onChange(of: outputDeviceUID) { _, newUID in
            playbackEngine.setOutputDevice(uid: newUID.isEmpty ? nil : newUID)
        }
    }

    private var highlightColorBinding: Binding<Color> {
        Binding(
            get: { Color(hex: highlightColorHex) ?? .yellow },
            set: { highlightColorHex = $0.hexString }
        )
    }
}
