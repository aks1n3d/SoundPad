//
//  PlaybackEngine.swift
//  One AVAudioEngine, one AVAudioPlayerNode per pad. Owns all runtime audio
//  state (playing/progress/mute/solo); persisted mix values live in BankStore.
//

import AudioToolbox
import AVFoundation
import CoreAudio
import Foundation

@MainActor
final class PlaybackEngine: ObservableObject {
    @Published private(set) var playingItemIDs: Set<UUID> = []
    @Published private(set) var progress: [UUID: Double] = [:]
    @Published private(set) var mutedItemIDs: Set<UUID> = []
    @Published private(set) var soloItemID: UUID?

    /// Called when playing an item resolved a stale bookmark; the owner
    /// (BankStore) should persist the refreshed data.
    var onBookmarkRefresh: ((UUID, Data) -> Void)?

    private final class PadPlayer {
        let node = AVAudioPlayerNode()
        let file: AVAudioFile
        // Non-nil means startAccessingSecurityScopedResource succeeded and the
        // scope is held open for the life of the pad (AVAudioFile keeps the
        // file open, so access must outlive individual plays).
        let scopedURL: URL?
        var baseVolume: Float = 1.0
        // Bumped on every (re)start so completion handlers from a superseded
        // schedule can detect they are stale (node.stop() fires them too).
        var generation = 0
        var fadeTask: Task<Void, Never>?
        var isFadingOut = false

        init(file: AVAudioFile, scopedURL: URL?) {
            self.file = file
            self.scopedURL = scopedURL
        }
    }

    private let engine = AVAudioEngine()
    private var pads: [UUID: PadPlayer] = [:]
    private var uiTimer: Timer?
    private var configChangeObserver: NSObjectProtocol?
    private var outputDeviceUID: String?

    private let fadeDuration: TimeInterval = 0.3
    private let fadeStepCount = 15

    init() {
        // Route changes (headphones unplugged, device removed) invalidate the
        // render graph; reset to a clean stopped state.
        configChangeObserver = NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange,
            object: engine,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.stopAllPlayback() }
        }
    }

    private var fadeEnabled: Bool {
        UserDefaults.standard.bool(forKey: "useFadeInOut")
    }

    func isPlaying(_ id: UUID) -> Bool {
        playingItemIDs.contains(id)
    }

    // MARK: - Play / stop

    func toggle(item: SoundPadItem) {
        // A pad that is fading out re-triggers instead of restarting the fade.
        if isPlaying(item.id), pads[item.id]?.isFadingOut != true {
            stop(item: item)
        } else {
            play(item: item)
        }
    }

    func play(item: SoundPadItem) {
        do {
            let pad = try loadPad(for: item)
            try ensureEngineRunning()

            pad.generation += 1
            let generation = pad.generation
            pad.fadeTask?.cancel()
            pad.fadeTask = nil
            pad.isFadingOut = false
            pad.node.stop()

            pad.baseVolume = item.volume
            pad.node.pan = item.pan
            let target = effectiveVolume(for: item.id)
            let useFade = fadeEnabled
            pad.node.volume = useFade ? 0 : target

            pad.file.framePosition = 0
            pad.node.scheduleFile(pad.file, at: nil,
                                  completionCallbackType: .dataPlayedBack) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self,
                          let current = self.pads[item.id],
                          current.generation == generation
                    else { return }
                    self.playingItemIDs.remove(item.id)
                    self.progress[item.id] = 0
                    self.stopUITimerIfIdle()
                }
            }
            pad.node.play()
            playingItemIDs.insert(item.id)
            startUITimerIfNeeded()

            if useFade {
                startFade(pad, itemID: item.id, to: target, fadingOut: false)
            }
        } catch {
            print("SoundPad: cannot play \(item.title): \(error)")
        }
    }

    func stop(item: SoundPadItem) {
        guard let pad = pads[item.id], playingItemIDs.contains(item.id) else { return }
        pad.fadeTask?.cancel()
        pad.fadeTask = nil
        if fadeEnabled {
            startFade(pad, itemID: item.id, to: 0, fadingOut: true)
        } else {
            finishStop(pad, itemID: item.id)
        }
    }

    /// Stop a node and clear its playing state synchronously, so an immediate
    /// follow-up toggle sees the pad as idle (the completion handler's hop to
    /// the main actor would otherwise leave a stale-playing window).
    private func finishStop(_ pad: PadPlayer, itemID: UUID) {
        pad.generation += 1
        pad.isFadingOut = false
        pad.node.stop()
        playingItemIDs.remove(itemID)
        progress[itemID] = 0
        stopUITimerIfIdle()
    }

    func stopAllPlayback() {
        for pad in pads.values {
            pad.fadeTask?.cancel()
            pad.fadeTask = nil
            pad.isFadingOut = false
            pad.generation += 1
            pad.node.stop()
        }
        playingItemIDs.removeAll()
        progress.removeAll()
        stopUITimerIfIdle()
    }

    /// Release everything held for a pad (called when the item is deleted or
    /// the project is replaced).
    func unload(itemID: UUID) {
        guard let pad = pads.removeValue(forKey: itemID) else { return }
        pad.fadeTask?.cancel()
        pad.generation += 1
        pad.node.stop()
        engine.detach(pad.node)
        pad.scopedURL?.stopAccessingSecurityScopedResource()
        playingItemIDs.remove(itemID)
        progress[itemID] = nil
        mutedItemIDs.remove(itemID)
        if soloItemID == itemID { soloItemID = nil }
        stopUITimerIfIdle()
    }

    func unloadAll() {
        for id in Array(pads.keys) {
            unload(itemID: id)
        }
        soloItemID = nil
        mutedItemIDs.removeAll()
    }

    // MARK: - Mix controls

    func setVolume(_ volume: Float, for id: UUID) {
        guard let pad = pads[id] else { return }
        pad.baseVolume = volume
        applyEffectiveVolume(to: pad, id: id)
    }

    func setPan(_ pan: Float, for id: UUID) {
        pads[id]?.node.pan = pan
    }

    func toggleMute(_ id: UUID) {
        if mutedItemIDs.contains(id) {
            mutedItemIDs.remove(id)
        } else {
            mutedItemIDs.insert(id)
        }
        applyEffectiveVolumes()
    }

    func setSolo(_ id: UUID?) {
        soloItemID = id
        applyEffectiveVolumes()
    }

    private func effectiveVolume(for id: UUID) -> Float {
        if mutedItemIDs.contains(id) { return 0 }
        if let solo = soloItemID, solo != id { return 0 }
        return pads[id]?.baseVolume ?? 1.0
    }

    private func applyEffectiveVolume(to pad: PadPlayer, id: UUID) {
        // A fade-out in flight already heads to 0 and then stops — leave it.
        guard !pad.isFadingOut else { return }
        let target = effectiveVolume(for: id)
        if pad.fadeTask != nil {
            // A fade-in is in flight; redirect it smoothly instead of snapping.
            pad.fadeTask?.cancel()
            startFade(pad, itemID: id, to: target, fadingOut: false)
        } else {
            pad.node.volume = target
        }
    }

    private func applyEffectiveVolumes() {
        for (id, pad) in pads {
            applyEffectiveVolume(to: pad, id: id)
        }
    }

    // MARK: - Fades

    private func startFade(_ pad: PadPlayer, itemID: UUID, to target: Float, fadingOut: Bool) {
        let steps = FadeCurve.steps(from: pad.node.volume, to: target, count: fadeStepCount)
        let stepNanos = UInt64(fadeDuration / Double(fadeStepCount) * 1_000_000_000)
        pad.isFadingOut = fadingOut
        pad.fadeTask = Task { @MainActor [weak self, weak pad] in
            for volume in steps {
                try? await Task.sleep(nanoseconds: stepNanos)
                guard !Task.isCancelled, let pad else { return }
                pad.node.volume = volume
            }
            guard !Task.isCancelled, let pad else { return }
            pad.fadeTask = nil
            pad.isFadingOut = false
            if fadingOut {
                self?.finishStop(pad, itemID: itemID)
            }
        }
    }

    // MARK: - Pad loading

    private func loadPad(for item: SoundPadItem) throws -> PadPlayer {
        if let existing = pads[item.id] {
            return existing
        }

        guard let (url, refreshedBookmark) = item.resolveURL() else {
            throw CocoaError(.fileNoSuchFile)
        }
        if let refreshedBookmark {
            onBookmarkRefresh?(item.id, refreshedBookmark)
        }

        let hasScope = url.startAccessingSecurityScopedResource()
        let file: AVAudioFile
        do {
            file = try AVAudioFile(forReading: url)
        } catch {
            if hasScope { url.stopAccessingSecurityScopedResource() }
            throw error
        }

        let pad = PadPlayer(file: file, scopedURL: hasScope ? url : nil)
        engine.attach(pad.node)
        engine.connect(pad.node, to: engine.mainMixerNode, format: file.processingFormat)
        pads[item.id] = pad
        return pad
    }

    // MARK: - Engine / output device

    private func ensureEngineRunning() throws {
        guard !engine.isRunning else { return }
        applyOutputDevice()
        engine.prepare()
        try engine.start()
    }

    /// Route THIS APP's audio to the device with the given UID
    /// (nil = follow the system default). Never touches the system setting.
    func setOutputDevice(uid: String?) {
        let normalized = (uid?.isEmpty == true) ? nil : uid
        guard normalized != outputDeviceUID else { return }
        outputDeviceUID = normalized
        let wasRunning = engine.isRunning
        if wasRunning {
            stopAllPlayback()
            engine.stop()
        }
        applyOutputDevice()
    }

    // Non-nil once we've pinned the output unit to an explicit device.
    private var pinnedDeviceID: AudioDeviceID?

    private func applyOutputDevice() {
        guard let audioUnit = engine.outputNode.audioUnit else { return }
        var deviceID: AudioDeviceID
        if let uid = outputDeviceUID, let id = audioDeviceID(forUID: uid) {
            deviceID = id
        } else if pinnedDeviceID != nil, let systemDefault = systemDefaultOutputDeviceID() {
            // Was pinned to an explicit device; repoint at the current default.
            // (Automatic default-following resumes on the next app launch —
            // an explicitly set output unit no longer tracks default changes.)
            deviceID = systemDefault
        } else {
            // Never touched: the output unit follows the system default natively.
            return
        }
        AudioUnitSetProperty(audioUnit,
                             kAudioOutputUnitProperty_CurrentDevice,
                             kAudioUnitScope_Global,
                             0,
                             &deviceID,
                             UInt32(MemoryLayout<AudioDeviceID>.size))
        pinnedDeviceID = deviceID
    }

    // MARK: - Progress (one shared timer, only while something plays)

    private func startUITimerIfNeeded() {
        guard uiTimer == nil else { return }
        uiTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    private func stopUITimerIfIdle() {
        guard playingItemIDs.isEmpty else { return }
        uiTimer?.invalidate()
        uiTimer = nil
    }

    private func tick() {
        for id in playingItemIDs {
            guard let pad = pads[id],
                  let nodeTime = pad.node.lastRenderTime,
                  let playerTime = pad.node.playerTime(forNodeTime: nodeTime),
                  pad.file.length > 0
            else { continue }
            progress[id] = min(1, Double(playerTime.sampleTime) / Double(pad.file.length))
        }
    }
}
