//
//  AudioDeviceSelector.swift
//  Core Audio output-device enumeration. Devices are identified by their
//  persistent UID string (AudioDeviceIDs change across reboots/hot-plugs).
//

import CoreAudio
import Foundation

struct AudioDeviceInfo: Hashable {
    var id: AudioDeviceID
    var uid: String
    var name: String
}

/// All devices with at least one output stream.
func getOutputDevices() -> [AudioDeviceInfo] {
    var devices: [AudioDeviceInfo] = []

    var propSize: UInt32 = 0
    var address = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDevices,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )

    guard AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject),
                                         &address, 0, nil, &propSize) == noErr
    else { return devices }

    let deviceCount = Int(propSize / UInt32(MemoryLayout<AudioObjectID>.size))
    var deviceIDs = Array(repeating: AudioObjectID(0), count: deviceCount)

    guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject),
                                     &address, 0, nil, &propSize, &deviceIDs) == noErr
    else { return devices }

    for devID in deviceIDs {
        var addrOut = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreams,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: 0
        )
        guard AudioObjectHasProperty(devID, &addrOut) else { continue }
        var streamsSize = UInt32(0)
        guard AudioObjectGetPropertyDataSize(devID, &addrOut, 0, nil, &streamsSize) == noErr,
              streamsSize > 0
        else { continue }

        let name = getDeviceName(deviceID: devID) ?? "Unknown"
        let uid = getDeviceUID(deviceID: devID) ?? String(devID)
        devices.append(AudioDeviceInfo(id: devID, uid: uid, name: name))
    }

    return devices
}

/// Look up the current AudioDeviceID for a persisted device UID.
func audioDeviceID(forUID uid: String) -> AudioDeviceID? {
    getOutputDevices().first { $0.uid == uid }?.id
}

/// The device the system is currently using as default output.
func systemDefaultOutputDeviceID() -> AudioDeviceID? {
    var deviceID = AudioDeviceID(0)
    var propSize = UInt32(MemoryLayout<AudioDeviceID>.size)
    var address = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDefaultOutputDevice,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )
    let status = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject),
                                            &address, 0, nil, &propSize, &deviceID)
    return status == noErr ? deviceID : nil
}

func getDeviceName(deviceID: AudioObjectID) -> String? {
    stringProperty(deviceID: deviceID, selector: kAudioObjectPropertyName)
}

func getDeviceUID(deviceID: AudioObjectID) -> String? {
    stringProperty(deviceID: deviceID, selector: kAudioDevicePropertyDeviceUID)
}

private func stringProperty(deviceID: AudioObjectID,
                            selector: AudioObjectPropertySelector) -> String? {
    var address = AudioObjectPropertyAddress(
        mSelector: selector,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )
    var valueCF: CFString = "" as CFString
    var propSize = UInt32(MemoryLayout<CFString>.size)
    let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &propSize, &valueCF)
    guard status == noErr else { return nil }
    return valueCF as String
}
