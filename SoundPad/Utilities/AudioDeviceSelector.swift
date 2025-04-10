//
//  AudioDeviceSelector.swift
//

import CoreAudio
import AVFoundation
import Foundation

struct AudioDeviceInfo {
    var id: UInt32
    var name: String
}

/// Получаем список доступных устройств ввода (микрофонов)
func getInputDevices() -> [AudioDeviceInfo] {
    var devices: [AudioDeviceInfo] = []

    var propSize: UInt32 = 0
    var address = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDevices,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )

    if AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject),
                                      &address,
                                      0,
                                      nil,
                                      &propSize) == noErr
    {
        let deviceCount = Int(propSize / UInt32(MemoryLayout<AudioObjectID>.size))
        var deviceIDs = Array(repeating: AudioObjectID(0), count: deviceCount)

        if AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject),
                                      &address,
                                      0,
                                      nil,
                                      &propSize,
                                      &deviceIDs) == noErr
        {
            for devID in deviceIDs {
                // Проверяем, есть ли у устройства входные потоки
                var addrIn = AudioObjectPropertyAddress(
                    mSelector: kAudioDevicePropertyStreams,
                    mScope: kAudioDevicePropertyScopeInput,
                    mElement: 0
                )
                if AudioObjectHasProperty(devID, &addrIn) {
                    var propSize2 = UInt32(0)
                    if AudioObjectGetPropertyDataSize(devID, &addrIn, 0, nil, &propSize2) == noErr, propSize2 > 0 {
                        let name = getDeviceName(deviceID: devID) ?? "Unknown"
                        devices.append(AudioDeviceInfo(id: devID, name: name))
                    }
                }
            }
        }
    }

    return devices
}

/// Установить системное «Default Input Device» (микрофон)
func setSystemInputDevice(deviceID: UInt32) {
    var theDevice = deviceID
    let propSize = UInt32(MemoryLayout<UInt32>.size)
    var address = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDefaultInputDevice,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )
    AudioObjectSetPropertyData(AudioObjectID(kAudioObjectSystemObject),
                               &address,
                               0,
                               nil,
                               propSize,
                               &theDevice)
}

/// Получение списка доступных Output-устройств (упрощённый пример)
func getOutputDevices() -> [AudioDeviceInfo] {
    var devices: [AudioDeviceInfo] = []

    var propSize: UInt32 = 0
    var address = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDevices,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )

    if AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject),
                                      &address,
                                      0,
                                      nil,
                                      &propSize) == noErr
    {
        let deviceCount = Int(propSize / UInt32(MemoryLayout<AudioObjectID>.size))
        var deviceIDs = Array(repeating: AudioObjectID(0), count: deviceCount)

        if AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject),
                                      &address,
                                      0,
                                      nil,
                                      &propSize,
                                      &deviceIDs) == noErr
        {
            for devID in deviceIDs {
                // Проверяем, является ли устройство выводом
                var addrOut = AudioObjectPropertyAddress(
                    mSelector: kAudioDevicePropertyStreams,
                    mScope: kAudioDevicePropertyScopeOutput,
                    mElement: 0
                )
                if AudioObjectHasProperty(devID, &addrOut) {
                    var propSize2 = UInt32(0)
                    if AudioObjectGetPropertyDataSize(devID, &addrOut, 0, nil, &propSize2) == noErr, propSize2 > 0 {
                        // Получим имя (c учётом Unicode)
                        let name = getDeviceName(deviceID: devID) ?? "Unknown"
                        devices.append(AudioDeviceInfo(id: devID, name: name))
                    }
                }
            }
        }
    }

    return devices
}

/// Получить название устройства как CFString, конвертировать в Swift String
func getDeviceName(deviceID: AudioObjectID) -> String? {
    var address = AudioObjectPropertyAddress(
        mSelector: kAudioObjectPropertyName,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )

    // Будем читать как CFString
    var nameCF: CFString = "" as CFString
    var propSize = UInt32(MemoryLayout<CFString>.size)

    let status = AudioObjectGetPropertyData(
        deviceID,
        &address,
        0,      // inQualifierDataSize
        nil,    // inQualifierData
        &propSize,
        &nameCF
    )

    guard status == noErr else {
        print("AudioObjectGetPropertyData error: \(status)")
        return nil
    }

    let name = nameCF as String
    return name
}

/// Установить системное устройство вывода
func setSystemOutputDevice(deviceID: UInt32) {
    var theDevice = deviceID
    let propSize = UInt32(MemoryLayout<UInt32>.size)
    var address = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDefaultOutputDevice,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )
    AudioObjectSetPropertyData(AudioObjectID(kAudioObjectSystemObject),
                               &address,
                               0,
                               nil,
                               propSize,
                               &theDevice)
}
