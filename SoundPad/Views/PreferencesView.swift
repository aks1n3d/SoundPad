//
//  PreferencesView.swift
//

import SwiftUI

struct PreferencesView: View {
    @AppStorage("useFadeInOut") var useFadeInOut: Bool = true
    @AppStorage("highlightColor") var highlightColorHex: String = "#FFD700"
    
    // Выбор аудиоустройства
    @State private var availableDevices: [AudioDeviceInfo] = []
    @AppStorage("selectedOutputDeviceID") var selectedOutputDeviceID: Int = 0
    
    @State private var availableInputDevices: [AudioDeviceInfo] = []
    @AppStorage("selectedInputDeviceID") var selectedInputDeviceID: Int = 0
    
    var body: some View {
        Form {
            Toggle("Use Fade In/Out", isOn: $useFadeInOut)
            
            HStack {
                Text("Highlight color:")
                TextField("#RRGGBB", text: $highlightColorHex)
                    .frame(width: 80)
            }
            
            Divider()
            
            Text("Input Device (Microphone):")
            Picker("Input Device", selection: $selectedInputDeviceID) {
                ForEach(availableInputDevices, id: \.id) { device in
                    Text(device.name).tag(Int(device.id))
                }
            }
                
                Divider()
                
                Text("Output Device:")
                Picker("Output Device", selection: $selectedOutputDeviceID) {
                    ForEach(availableDevices, id: \.id) { device in
                        Text(device.name).tag(Int(device.id))
                    }
                }
            }
            .padding()
            .onAppear {
                availableDevices = getOutputDevices()
                availableInputDevices = getInputDevices()
            }
            .onChange(of: selectedOutputDeviceID) { newID in
                setSystemOutputDevice(deviceID: UInt32(newID))
            }
            .onChange(of: selectedInputDeviceID) { newID in
                setSystemInputDevice(deviceID: UInt32(newID))
            }
        }
    }

