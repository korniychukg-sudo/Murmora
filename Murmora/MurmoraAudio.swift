import Foundation
import AVFoundation

/// Manages a pool of looping AVAudioPlayers, one per active sound, with a
/// global master volume, per-sound volume, and a fade-driven sleep timer.
final class MurmoraAudio {
    private var players: [String: AVAudioPlayer] = [:]
    private(set) var isRunning = false
    private var master: Float = 1.0
    private var fadeMultiplier: Float = 1.0
    private var fadeTimer: Timer?
    private var targetVolumes: [String: Float] = [:]     // per-sound user volume 0..1
    private var sessionActive = false

    // MARK: session

    private func activateSession() {
        guard !sessionActive else { return }
        let s = AVAudioSession.sharedInstance()
        try? s.setCategory(.playback, mode: .default, options: [])
        try? s.setActive(true)
        sessionActive = true
    }

    private func deactivateSession() {
        guard sessionActive else { return }
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        sessionActive = false
    }

    // MARK: player management

    private func player(for id: String) -> AVAudioPlayer? {
        if let p = players[id] { return p }
        guard let url = Bundle.main.url(forResource: id, withExtension: "wav", subdirectory: "Audio")
                ?? Bundle.main.url(forResource: id, withExtension: "wav") else { return nil }
        guard let p = try? AVAudioPlayer(contentsOf: url) else { return nil }
        p.numberOfLoops = -1
        p.volume = 0
        p.prepareToPlay()
        players[id] = p
        return p
    }

    private func effective(_ v: Float) -> Float { v * master * fadeMultiplier }

    // MARK: public API

    /// Apply a full mix (id -> volume 0..1). Removes any players not in the mix.
    func apply(mix: [String: Double]) {
        targetVolumes = mix.mapValues { Float($0) }
        // remove players no longer needed
        for (id, p) in players where mix[id] == nil {
            p.stop(); players[id] = nil
        }
        for (id, v) in targetVolumes {
            guard let p = player(for: id) else { continue }
            p.volume = effective(v)
            if isRunning && !p.isPlaying { p.currentTime = 0; p.play() }
        }
    }

    func setVolume(_ id: String, _ v: Double) {
        let fv = Float(v)
        targetVolumes[id] = fv
        if fv <= 0.001 {
            if let p = players[id] { p.stop(); players[id] = nil }
            targetVolumes[id] = nil
            return
        }
        guard let p = player(for: id) else { return }
        p.volume = effective(fv)
        if isRunning && !p.isPlaying { p.play() }
    }

    func remove(_ id: String) {
        if let p = players[id] { p.stop() }
        players[id] = nil
        targetVolumes[id] = nil
    }

    func setMaster(_ v: Double) {
        master = Float(v)
        refreshVolumes()
    }

    private func refreshVolumes() {
        for (id, p) in players { p.volume = effective(targetVolumes[id] ?? 0) }
    }

    func play() {
        guard !targetVolumes.isEmpty else { return }
        activateSession()
        cancelFade()
        fadeMultiplier = 1.0
        isRunning = true
        for (id, v) in targetVolumes {
            guard let p = player(for: id) else { continue }
            p.volume = effective(v)
            if !p.isPlaying { p.play() }
        }
    }

    func pause() {
        isRunning = false
        cancelFade()
        for (_, p) in players { p.pause() }
        deactivateSession()
    }

    func togglePlay() { isRunning ? pause() : play() }

    // MARK: fade / sleep timer

    private func cancelFade() { fadeTimer?.invalidate(); fadeTimer = nil }

    /// Fade all audio out over `duration` seconds, then stop. Calls completion on finish.
    func fadeOutAndStop(duration: Double, completion: @escaping () -> Void) {
        cancelFade()
        guard isRunning, duration > 0 else { pause(); completion(); return }
        let step = 0.1
        let dec = Float(step / duration)
        fadeTimer = Timer.scheduledTimer(withTimeInterval: step, repeats: true) { [weak self] t in
            guard let self = self else { t.invalidate(); return }
            self.fadeMultiplier -= dec
            if self.fadeMultiplier <= 0 {
                t.invalidate()
                self.fadeMultiplier = 1.0
                self.pause()
                completion()
            } else {
                self.refreshVolumes()
            }
        }
    }

    /// Immediately reset the fade multiplier (used when a new play starts).
    func resetFade() { cancelFade(); fadeMultiplier = 1.0; refreshVolumes() }
}
