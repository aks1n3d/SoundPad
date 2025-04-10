//
//  AudioEngineManager.swift
//  Управляет воспроизведением, загрузкой/сохранением проектов
//

import Foundation
import AVFoundation
import SwiftUI
import UniformTypeIdentifiers

class AudioEngineManager: ObservableObject {
    // Список банков (каждый банк – набор пэдов)
    @Published var banks: [SoundBank] = []
    // Текущий индекс выбранного банка
    @Published var selectedBankIndex: Int = 0

    // Словарь плееров (ключ: UUID элемента, значение: AVAudioPlayer)
    var audioPlayers: [UUID: AVAudioPlayer] = [:]

    init() {
        // Загружаем прошлую сессию (если есть)
        loadLastSession()
    }

    // MARK: - Воспроизведение

    func playSound(item: SoundPadItem) {
        do {
            let player = try AVAudioPlayer(contentsOf: item.url)
            // Если включён Fade In/Out
            if UserDefaults.standard.bool(forKey: "useFadeInOut") {
                player.volume = 0
            } else {
                player.volume = item.volume
            }
            player.play()
            audioPlayers[item.id] = player

            // Плавное нарастание (Fade In), если включено
            if UserDefaults.standard.bool(forKey: "useFadeInOut") {
                fadeVolumeIn(player: player, targetVolume: item.volume)
            }
        } catch {
            print("Error playing sound: \(error)")
        }
    }

    func stopSound(item: SoundPadItem) {
        if let player = audioPlayers[item.id] {
            if UserDefaults.standard.bool(forKey: "useFadeInOut") {
                fadeVolumeOutAndStop(player: player)
            } else {
                player.stop()
                audioPlayers[item.id] = nil
            }
        }
    }

    private func fadeVolumeIn(player: AVAudioPlayer, targetVolume: Float) {
        let steps = 20
        let interval = 0.05 // 50ms
        let volumeStep = targetVolume / Float(steps)
        var currentStep = 0
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
            currentStep += 1
            let newVolume = Float(currentStep) * volumeStep
            player.volume = newVolume
            if currentStep >= steps {
                timer.invalidate()
            }
        }
    }

    private func fadeVolumeOutAndStop(player: AVAudioPlayer) {
        let steps = 20
        let interval = 0.05
        let volumeStep = player.volume / Float(steps)
        var currentStep = 0
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
            currentStep += 1
            let newVolume = player.volume - volumeStep
            player.volume = max(newVolume, 0)
            if currentStep >= steps {
                player.stop()
                timer.invalidate()
            }
        }
    }

    // MARK: - Управление данными (rename / delete)

    /// Переименовать элемент в текущем банке
    func renameItem(_ item: SoundPadItem, newTitle: String) {
        guard let bankIndex = banks.firstIndex(where: {
            $0.items.contains(where: { $0.id == item.id })
        }) else { return }

        if let itemIndex = banks[bankIndex].items.firstIndex(where: { $0.id == item.id }) {
            banks[bankIndex].items[itemIndex].title = newTitle
        }
    }

    /// Удалить элемент из банка
    func deleteItem(_ item: SoundPadItem) {
        guard let bankIndex = banks.firstIndex(where: {
            $0.items.contains(where: { $0.id == item.id })
        }) else { return }

        if let itemIndex = banks[bankIndex].items.firstIndex(where: { $0.id == item.id }) {
            // Если звук играет – остановим
            stopSound(item: banks[bankIndex].items[itemIndex])
            // Удаляем из массива
            banks[bankIndex].items.remove(at: itemIndex)
        }
    }

    // MARK: - Сохранение/загрузка проектов (JSON)

    func saveProjectAs() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.nameFieldStringValue = "SoundPadProject.json"
        if savePanel.runModal() == .OK, let url = savePanel.url {
            do {
                let data = try JSONEncoder().encode(banks)
                try data.write(to: url)
            } catch {
                print("Save project error: \(error)")
            }
        }
    }

    func openProject() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.json]
        if openPanel.runModal() == .OK, let url = openPanel.url {
            do {
                let data = try Data(contentsOf: url)
                let decoded = try JSONDecoder().decode([SoundBank].self, from: data)
                banks = decoded
                selectedBankIndex = 0
            } catch {
                print("Open project error: \(error)")
            }
        }
    }

    // MARK: - Автосохранение/загрузка

    private func loadLastSession() {
        let url = getDefaultSessionURL()
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                let data = try Data(contentsOf: url)
                let decoded = try JSONDecoder().decode([SoundBank].self, from: data)
                banks = decoded
            } catch {
                print("Error loading session: \(error)")
                banks = [SoundBank(name: "Bank 1", items: [])]
            }
        } else {
            // Если файл не найден, создаём 1 пустой банк
            banks = [SoundBank(name: "Bank 1", items: [])]
        }
    }

    func saveSession() {
        let url = getDefaultSessionURL()
        do {
            let data = try JSONEncoder().encode(banks)
            try data.write(to: url)
        } catch {
            print("Error saving session: \(error)")
        }
    }

    private func getDefaultSessionURL() -> URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
        return support.appendingPathComponent("DefaultSession.json")
    }
}
