import SwiftUI
import Combine

enum TimerMode: String { case none, sleep, focus }

final class GroveStore: ObservableObject {
    // Active soundscape
    @Published var mix: [String: Double] = [:]           // id -> volume 0..1
    @Published var isPlaying = false
    @Published var masterVolume: Double = 0.85

    // Library
    @Published var savedMixes: [SavedMix] = []

    // Stats & badges
    @Published var stats = GroveStats()
    @Published var unlockedBadges: Set<String> = []
    @Published var justUnlocked: Badge? = nil

    // Timer (sleep / focus)
    @Published var timerMode: TimerMode = .none
    @Published var timerRemaining: TimeInterval = 0
    private var timerTotal: TimeInterval = 0
    private var timerEnd: Date?
    private var fading = false

    // Settings
    @Published var reduceMotion = false
    @Published var defaultSleepMinutes = 30
    @Published var onboardingSeen = false

    private let audio = GroveAudio()
    private var ticker: AnyCancellable?
    private let d = UserDefaults.standard
    private var loadedName: String? = nil     // name of loaded preset/saved, if any

    let defaultAddVolume = 0.6

    init() {
        load()
        ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
            .sink { [weak self] _ in self?.tick() }
        recomputeBadges(silent: true)
    }

    // MARK: derived

    var activeSounds: [GroveSound] {
        SoundCatalog.all.filter { (mix[$0.id] ?? 0) > 0 }
    }
    var activeCount: Int { activeSounds.count }
    var hasMix: Bool { activeCount > 0 }

    // MARK: mixing

    func isActive(_ id: String) -> Bool { (mix[id] ?? 0) > 0 }

    func toggleSound(_ id: String) {
        if isActive(id) {
            mix[id] = nil
            audio.remove(id)
        } else {
            mix[id] = defaultAddVolume
            markUsed(id)
            audio.setVolume(id, defaultAddVolume)
            if !isPlaying { play() }
        }
        loadedName = nil
        objectWillChange.send()
        persistLight()
        registerConcurrency()
    }

    func setVolume(_ id: String, _ v: Double) {
        let clamped = max(0, min(1, v))
        if clamped <= 0.001 {
            mix[id] = nil; audio.remove(id)
        } else {
            mix[id] = clamped; audio.setVolume(id, clamped); markUsed(id)
        }
        objectWillChange.send()
    }

    func setMaster(_ v: Double) {
        masterVolume = max(0, min(1, v))
        audio.setMaster(masterVolume)
        d.set(masterVolume, forKey: "master")
    }

    func clearMix() {
        for id in Array(mix.keys) { audio.remove(id) }
        mix = [:]
        isPlaying = false
        audio.pause()
        loadedName = nil
        persistLight()
    }

    func play() {
        guard hasMix else { return }
        if !isPlaying { stats.sessions += 1; sessionStart = Date() }
        audio.setMaster(masterVolume)
        audio.apply(mix: mix)
        audio.play()
        isPlaying = true
        markDayActive()
        recomputeBadges()
    }

    func pause() {
        audio.pause()
        isPlaying = false
        commitSession()
        saveStats()
    }

    func togglePlay() { isPlaying ? pause() : play() }

    // MARK: presets & saved

    func loadPreset(_ p: ScenePreset) {
        applyMix(p.mix, name: p.name)
    }
    func loadSaved(_ m: SavedMix) {
        applyMix(m.mix, name: m.name)
    }
    private func applyMix(_ newMix: [String: Double], name: String) {
        for id in Array(mix.keys) where newMix[id] == nil { audio.remove(id) }
        mix = newMix
        for id in newMix.keys { markUsed(id) }
        loadedName = name
        audio.setMaster(masterVolume)
        audio.apply(mix: mix)
        play()
        registerConcurrency()
        persistLight()
    }

    var currentLoadedName: String? { loadedName }

    func saveCurrentMix(name: String) {
        guard hasMix else { return }
        let cat = dominantCat()
        let m = SavedMix(id: UUID().uuidString,
                         name: name.isEmpty ? "My Scene" : name,
                         mix: mix, catRaw: cat.rawValue,
                         createdAt: Date().timeIntervalSince1970)
        savedMixes.insert(m, at: 0)
        stats.savedCount = savedMixes.count
        loadedName = m.name
        saveMixes(); saveStats(); recomputeBadges()
    }

    func deleteSaved(_ m: SavedMix) {
        savedMixes.removeAll { $0.id == m.id }
        saveMixes()
    }

    func dominantCat() -> SoundCat {
        var totals: [SoundCat: Double] = [:]
        for s in activeSounds { totals[s.cat, default: 0] += mix[s.id] ?? 0 }
        return totals.max { $0.value < $1.value }?.key ?? .tones
    }

    // MARK: timer (sleep / focus)

    func startTimer(mode: TimerMode, minutes: Int) {
        guard minutes > 0 else { return }
        if !isPlaying { play() }
        audio.resetFade()
        timerMode = mode
        timerTotal = Double(minutes * 60)
        timerEnd = Date().addingTimeInterval(timerTotal)
        timerRemaining = timerTotal
        fading = false
        if mode == .sleep { defaultSleepMinutes = minutes; d.set(minutes, forKey: "defSleep") }
    }

    func cancelTimer() {
        timerMode = .none
        timerEnd = nil
        timerRemaining = 0
        fading = false
        audio.resetFade()
    }

    var timerProgress: Double {
        guard timerTotal > 0 else { return 0 }
        return max(0, min(1, 1 - timerRemaining / timerTotal))
    }

    // MARK: tick

    private var sessionStart: Date?
    private var sessionAccum: TimeInterval = 0

    private func tick() {
        if isPlaying {
            stats.totalSeconds += 1
            sessionAccum += 1
            for s in activeSounds { stats.perSound[s.id, default: 0] += 1 }
            if sessionAccum > stats.longestSeconds { stats.longestSeconds = sessionAccum }
            if Int(stats.totalSeconds) % 15 == 0 { recomputeBadges(); saveStats() }
        }
        // timer countdown
        if timerMode != .none, let end = timerEnd {
            timerRemaining = max(0, end.timeIntervalSinceNow)
            let fadeLead: TimeInterval = timerMode == .sleep ? 15 : 3
            if !fading && timerRemaining <= fadeLead {
                fading = true
                let mode = timerMode
                audio.fadeOutAndStop(duration: max(1, timerRemaining)) { [weak self] in
                    guard let self = self else { return }
                    self.isPlaying = false
                    self.commitSession()
                    if mode == .sleep { self.stats.sleepCompleted += 1 }
                    else if mode == .focus { self.stats.focusCompleted += 1 }
                    self.timerMode = .none
                    self.timerEnd = nil
                    self.timerRemaining = 0
                    self.fading = false
                    self.recomputeBadges()
                    self.saveStats()
                }
            }
        }
    }

    private func commitSession() {
        sessionAccum = 0
        sessionStart = nil
    }

    // MARK: stats helpers

    private var concurrencyDirty = false
    private func registerConcurrency() {
        if activeCount > stats.maxConcurrent { stats.maxConcurrent = activeCount; recomputeBadges() }
    }
    private func markUsed(_ id: String) {
        if !stats.usedSounds.contains(id) { stats.usedSounds.append(id); recomputeBadges() }
    }
    private func markDayActive() {
        let key = Self.dayKey(Date())
        if !stats.daysActive.contains(key) { stats.daysActive.append(key); recomputeBadges() }
    }
    static func dayKey(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "\(c.year ?? 0)-\(c.month ?? 0)-\(c.day ?? 0)"
    }

    func recomputeBadges(silent: Bool = false) {
        for b in BadgeCatalog.all where b.test(stats) {
            if !unlockedBadges.contains(b.id) {
                unlockedBadges.insert(b.id)
                if !silent { justUnlocked = b }
            }
        }
        if !silent { saveBadges() }
    }

    // MARK: onboarding / settings

    func markOnboardingSeen() { onboardingSeen = true; d.set(true, forKey: "onb") }
    func setReduceMotion(_ v: Bool) { reduceMotion = v; d.set(v, forKey: "reduceMotion") }

    func resetAll() {
        clearMix()
        savedMixes = []
        stats = GroveStats()
        unlockedBadges = []
        saveMixes(); saveStats(); saveBadges()
    }

    // MARK: persistence

    private func persistLight() {
        if let data = try? JSONEncoder().encode(mix) { d.set(data, forKey: "activeMix") }
    }
    private func saveMixes() {
        if let data = try? JSONEncoder().encode(savedMixes) { d.set(data, forKey: "savedMixes") }
    }
    private func saveStats() {
        if let data = try? JSONEncoder().encode(stats) { d.set(data, forKey: "stats") }
    }
    private func saveBadges() {
        d.set(Array(unlockedBadges), forKey: "badges")
    }
    private func load() {
        if let data = d.data(forKey: "savedMixes"), let v = try? JSONDecoder().decode([SavedMix].self, from: data) { savedMixes = v }
        if let data = d.data(forKey: "stats"), let v = try? JSONDecoder().decode(GroveStats.self, from: data) { stats = v }
        if let arr = d.array(forKey: "badges") as? [String] { unlockedBadges = Set(arr) }
        if let data = d.data(forKey: "activeMix"), let v = try? JSONDecoder().decode([String: Double].self, from: data) { mix = v }
        if d.object(forKey: "master") != nil { masterVolume = d.double(forKey: "master") }
        reduceMotion = d.bool(forKey: "reduceMotion")
        if d.object(forKey: "defSleep") != nil { defaultSleepMinutes = d.integer(forKey: "defSleep") }
        onboardingSeen = d.bool(forKey: "onb")
        stats.savedCount = savedMixes.count
    }
}
