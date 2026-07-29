import SwiftUI

// MARK: - Categories

enum SoundCat: String, CaseIterable, Codable, Identifiable {
    case sky, fire, water, forest, tones
    var id: String { rawValue }
    var title: String {
        switch self {
        case .sky:    return "Rain & Sky"
        case .fire:   return "Fireside & Home"
        case .water:  return "Water & Places"
        case .forest: return "Forest & Night"
        case .tones:  return "Focus & Tones"
        }
    }
    var subtitle: String {
        switch self {
        case .sky:    return "Storms, showers and open air"
        case .fire:   return "Warm rooms and gentle hums"
        case .water:  return "Shores, streams and journeys"
        case .forest: return "Crickets, owls and leaves"
        case .tones:  return "Bowls, keys and steady noise"
        }
    }
    var banner: String {
        switch self {
        case .sky: return "banner_sky"; case .fire: return "banner_fire"
        case .water: return "banner_water"; case .forest: return "banner_forest"
        case .tones: return "banner_tones"
        }
    }
}

// MARK: - Sound

struct MurmoraSound: Identifiable, Equatable {
    let id: String       // matches wav + tok_<id>.png
    let name: String
    let cat: SoundCat
    let blurb: String
    var token: String { "tok_\(id)" }
    var file: String { id }
    static func == (a: MurmoraSound, b: MurmoraSound) -> Bool { a.id == b.id }
}

enum SoundCatalog {
    static let all: [MurmoraSound] = [
        // Rain & Sky
        MurmoraSound(id: "rain",       name: "Rain Shower",    cat: .sky,   blurb: "A soft, steady curtain of rain."),
        MurmoraSound(id: "heavyrain",  name: "Heavy Rain",     cat: .sky,   blurb: "Downpour drumming on the roof."),
        MurmoraSound(id: "thunder",    name: "Distant Thunder",cat: .sky,   blurb: "Low rolls beyond the horizon."),
        MurmoraSound(id: "wind",       name: "Gentle Wind",    cat: .sky,   blurb: "Air moving through open space."),
        // Fireside & Home
        MurmoraSound(id: "campfire",   name: "Campfire",       cat: .fire,  blurb: "Crackling logs and warm embers."),
        MurmoraSound(id: "fan",        name: "Cozy Fan",       cat: .fire,  blurb: "The even hush of a room fan."),
        MurmoraSound(id: "chimes",     name: "Wind Chimes",    cat: .fire,  blurb: "Soft bells stirred by a breeze."),
        MurmoraSound(id: "heartbeat",  name: "Calm Heartbeat", cat: .fire,  blurb: "A slow, grounding pulse."),
        // Water & Places
        MurmoraSound(id: "ocean",      name: "Ocean Waves",    cat: .water, blurb: "Swells breaking on the shore."),
        MurmoraSound(id: "stream",     name: "Forest Stream",  cat: .water, blurb: "Water burbling over stones."),
        MurmoraSound(id: "frogs",      name: "Pond Frogs",     cat: .water, blurb: "Croaks across a still pond."),
        MurmoraSound(id: "train",      name: "Night Train",    cat: .water, blurb: "Rhythmic rails through the dark."),
        // Forest & Night
        MurmoraSound(id: "crickets",   name: "Night Crickets", cat: .forest,blurb: "A meadow humming after dusk."),
        MurmoraSound(id: "owl",        name: "Night Owl",      cat: .forest,blurb: "Hoots drifting between the trees."),
        MurmoraSound(id: "birds",      name: "Morning Birds",  cat: .forest,blurb: "A dawn chorus of songbirds."),
        MurmoraSound(id: "leaves",     name: "Rustling Leaves",cat: .forest,blurb: "Gusts brushing through foliage."),
        // Focus & Tones
        MurmoraSound(id: "bowl",       name: "Singing Bowl",   cat: .tones, blurb: "A resonant, meditative drone."),
        MurmoraSound(id: "piano",      name: "Soft Piano",     cat: .tones, blurb: "Sparse, gentle piano notes."),
        MurmoraSound(id: "whitenoise", name: "White Noise",    cat: .tones, blurb: "An even veil that masks the world."),
        MurmoraSound(id: "brownnoise", name: "Brown Noise",    cat: .tones, blurb: "Deep, warm low-frequency hush."),
        // v2 additions (6 per category)
        MurmoraSound(id: "rain_tent",  name: "Rain on Tent",   cat: .sky,   blurb: "Soft patter close overhead."),
        MurmoraSound(id: "blizzard",   name: "Blizzard Wind",  cat: .sky,   blurb: "Snow-laden gusts and a low howl."),
        MurmoraSound(id: "cat",        name: "Purring Cat",    cat: .fire,  blurb: "A warm, steady purr."),
        MurmoraSound(id: "clock",      name: "Ticking Clock",  cat: .fire,  blurb: "The calm rhythm of a room clock."),
        MurmoraSound(id: "drips",      name: "Cave Drips",     cat: .water, blurb: "Echoing drops in a still cavern."),
        MurmoraSound(id: "rowboat",    name: "Rowboat Creaks", cat: .water, blurb: "Wooden creaks and lapping water."),
        MurmoraSound(id: "cicadas",    name: "Summer Cicadas", cat: .forest,blurb: "A shimmering afternoon chorus."),
        MurmoraSound(id: "wolves",     name: "Distant Wolves", cat: .forest,blurb: "Far-off howls under the moon."),
        MurmoraSound(id: "pinknoise",  name: "Pink Noise",     cat: .tones, blurb: "A soft, balanced wash of sound."),
        MurmoraSound(id: "omdrone",    name: "Om Drone",       cat: .tones, blurb: "A sustained, grounding chant tone."),
    ]

    static func by(_ id: String) -> MurmoraSound? { all.first { $0.id == id } }
    static func inCat(_ c: SoundCat) -> [MurmoraSound] { all.filter { $0.cat == c } }
}

// MARK: - Scene presets

struct ScenePreset: Identifiable {
    let id: String
    let name: String
    let blurb: String
    let cover: String
    let cat: SoundCat
    let mix: [String: Double]
}

enum SceneCatalog {
    static let all: [ScenePreset] = [
        ScenePreset(id: "cabin",  name: "Rainy Cabin",     blurb: "Rain on the windows, fire in the hearth.", cover: "scene_cabin",  cat: .sky,
                    mix: ["rain": 0.72, "campfire": 0.55, "wind": 0.35]),
        ScenePreset(id: "ocean",  name: "Ocean Dusk",      blurb: "Waves and chimes as the sun dips low.",    cover: "scene_ocean",  cat: .water,
                    mix: ["ocean": 0.75, "wind": 0.30, "chimes": 0.40]),
        ScenePreset(id: "forest", name: "Midnight Forest", blurb: "Crickets, an owl, and shifting leaves.",   cover: "scene_forest", cat: .forest,
                    mix: ["crickets": 0.62, "owl": 0.5, "leaves": 0.38]),
        ScenePreset(id: "fireside",name: "Cozy Fireside",  blurb: "Logs, a soft fan, and a singing bowl.",    cover: "scene_fireside",cat: .fire,
                    mix: ["campfire": 0.7, "fan": 0.35, "bowl": 0.28]),
        ScenePreset(id: "storm",  name: "Thunderstorm",    blurb: "A full downpour with distant thunder.",    cover: "scene_storm",  cat: .sky,
                    mix: ["heavyrain": 0.78, "thunder": 0.6, "wind": 0.42]),
        ScenePreset(id: "meadow", name: "Morning Meadow",  blurb: "Birdsong over a bright little stream.",     cover: "scene_meadow", cat: .forest,
                    mix: ["birds": 0.6, "stream": 0.5, "leaves": 0.3]),
        ScenePreset(id: "train",  name: "Night Train",     blurb: "Rails and rain rock you to sleep.",         cover: "scene_train",  cat: .water,
                    mix: ["train": 0.6, "rain": 0.45, "brownnoise": 0.3]),
        ScenePreset(id: "zen",    name: "Zen Garden",      blurb: "A bowl, soft piano, and flowing water.",    cover: "scene_zen",    cat: .tones,
                    mix: ["bowl": 0.5, "piano": 0.45, "stream": 0.35]),
        ScenePreset(id: "focus",  name: "Deep Focus",      blurb: "Steady noise to hold your attention.",      cover: "scene_focus",  cat: .tones,
                    mix: ["brownnoise": 0.55, "fan": 0.4, "rain": 0.3]),
        ScenePreset(id: "pond",   name: "Sleepy Pond",     blurb: "Frogs and crickets on a windless night.",   cover: "scene_pond",   cat: .forest,
                    mix: ["frogs": 0.55, "crickets": 0.5, "wind": 0.28]),
        ScenePreset(id: "snowycabin", name: "Snowy Cabin", blurb: "A blizzard outside, a fire within.",       cover: "scene_snowycabin", cat: .sky,
                    mix: ["blizzard": 0.7, "campfire": 0.55, "wind": 0.3]),
        ScenePreset(id: "reading", name: "Reading Nook",   blurb: "A purring cat, a clock, soft rain.",        cover: "scene_reading", cat: .fire,
                    mix: ["cat": 0.6, "clock": 0.4, "rain": 0.4]),
        ScenePreset(id: "cave",   name: "Dripping Cave",   blurb: "Echoing drops in the deep dark.",           cover: "scene_cave",   cat: .water,
                    mix: ["drips": 0.62, "brownnoise": 0.4, "wind": 0.25]),
        ScenePreset(id: "cicadaday", name: "Cicada Afternoon", blurb: "A bright, buzzing summer day.",         cover: "scene_cicadaday", cat: .forest,
                    mix: ["cicadas": 0.6, "birds": 0.45, "leaves": 0.35]),
        ScenePreset(id: "wolfridge", name: "Wolf Ridge",   blurb: "Howls carried on a cold wind.",             cover: "scene_wolfridge", cat: .forest,
                    mix: ["wolves": 0.55, "wind": 0.4, "owl": 0.4]),
        ScenePreset(id: "temple", name: "Temple Calm",     blurb: "A chant, a bowl, and falling water.",       cover: "scene_temple", cat: .tones,
                    mix: ["omdrone": 0.55, "bowl": 0.45, "drips": 0.35]),
    ]
}

// MARK: - Breathing patterns

enum BreathPhase: String {
    case inhale, holdIn, exhale, holdOut
    var label: String {
        switch self {
        case .inhale:  return "Breathe in"
        case .holdIn:  return "Hold"
        case .exhale:  return "Breathe out"
        case .holdOut: return "Rest"
        }
    }
}

struct BreathPattern: Identifiable {
    let id: String
    let name: String
    let blurb: String
    let detail: String
    let cat: SoundCat
    let inhale: Double
    let holdIn: Double
    let exhale: Double
    let holdOut: Double

    var cycle: Double { inhale + holdIn + exhale + holdOut }
    var ratio: String {
        let parts = [inhale, holdIn, exhale, holdOut].filter { $0 > 0 }
        return parts.map { String(Int($0)) }.joined(separator: "-")
    }

    /// Phase and its 0..1 progress at `t` seconds into a cycle.
    func phase(at t: Double) -> (BreathPhase, Double) {
        var edge = inhale
        if t < edge { return (.inhale, inhale > 0 ? t / inhale : 1) }
        if holdIn > 0 {
            if t < edge + holdIn { return (.holdIn, (t - edge) / holdIn) }
            edge += holdIn
        }
        if t < edge + exhale { return (.exhale, exhale > 0 ? (t - edge) / exhale : 1) }
        edge += exhale
        if holdOut > 0 { return (.holdOut, min(1, (t - edge) / holdOut)) }
        return (.exhale, 1)
    }

    /// 0..1 fullness of the lungs — drives the ring size.
    func fullness(at t: Double) -> Double {
        let (p, k) = phase(at: t)
        switch p {
        case .inhale:  return k
        case .holdIn:  return 1
        case .exhale:  return 1 - k
        case .holdOut: return 0
        }
    }
}

enum BreathCatalog {
    static let all: [BreathPattern] = [
        BreathPattern(id: "box", name: "Box Breathing", blurb: "Even four counts on every side.",
                      detail: "Used by divers and athletes to steady the nerves before a demanding moment. Equal counts keep your attention from wandering.",
                      cat: .tones, inhale: 4, holdIn: 4, exhale: 4, holdOut: 4),
        BreathPattern(id: "relax", name: "4-7-8 Relax", blurb: "A long exhale to wind down.",
                      detail: "The extended exhale is the part that settles you. Best paired with a sleep timer once you are already in bed.",
                      cat: .sky, inhale: 4, holdIn: 7, exhale: 8, holdOut: 0),
        BreathPattern(id: "calm", name: "Calm 4-6", blurb: "Gentle, no holding at all.",
                      detail: "Nothing to hold and nothing to count past six — the easiest pattern to start with if breathwork is new to you.",
                      cat: .water, inhale: 4, holdIn: 0, exhale: 6, holdOut: 0),
        BreathPattern(id: "unwind", name: "Unwind 5-5", blurb: "A slow, balanced rhythm.",
                      detail: "Five in, five out lands close to six breaths a minute, the pace people naturally fall into when they are deeply relaxed.",
                      cat: .forest, inhale: 5, holdIn: 0, exhale: 5, holdOut: 0),
    ]
    static func by(_ id: String) -> BreathPattern? { all.first { $0.id == id } }
}

// MARK: - Saved mix

struct SavedMix: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var mix: [String: Double]
    var catRaw: String
    var createdAt: Double
    var cat: SoundCat { SoundCat(rawValue: catRaw) ?? .tones }
}

// MARK: - Badges

struct Badge: Identifiable {
    let id: String
    let title: String
    let detail: String
    let glyph: MurmoraGlyph
    let test: (MurmoraStats) -> Bool
}

struct MurmoraStats: Codable {
    var totalSeconds: Double = 0
    var sessions: Int = 0
    var longestSeconds: Double = 0
    var perSound: [String: Double] = [:]     // id -> seconds
    var usedSounds: [String] = []            // distinct ids ever mixed
    var maxConcurrent: Int = 0
    var savedCount: Int = 0
    var sleepCompleted: Int = 0
    var focusCompleted: Int = 0
    var daysActive: [String] = []            // yyyy-mm-dd
    var perDay: [String: Double] = [:]       // day key -> seconds listened
    var breathSessions: Int = 0
    var breathSeconds: Double = 0

    var minutes: Int { Int(totalSeconds / 60) }
    var breathMinutes: Int { Int(breathSeconds / 60) }
    var favoriteSound: String? {
        perSound.max { $0.value < $1.value }?.key
    }
}

enum BadgeCatalog {
    static let all: [Badge] = [
        Badge(id: "first",     title: "First Breath",   detail: "Play your first soundscape",       glyph: .play,     test: { $0.sessions >= 1 }),
        Badge(id: "layer3",    title: "Layered",        detail: "Blend 3 sounds at once",           glyph: .layers,   test: { $0.maxConcurrent >= 3 }),
        Badge(id: "layer5",    title: "Mixologist",     detail: "Blend 5 sounds at once",           glyph: .layers,   test: { $0.maxConcurrent >= 5 }),
        Badge(id: "explore10", title: "Sound Explorer", detail: "Try 10 different sounds",          glyph: .compass,  test: { $0.usedSounds.count >= 10 }),
        Badge(id: "all20",     title: "Full Palette",   detail: "Try 20 different sounds",         glyph: .grid,     test: { $0.usedSounds.count >= 20 }),
        Badge(id: "save3",     title: "Curator",        detail: "Save 3 of your own scenes",        glyph: .bookmark, test: { $0.savedCount >= 3 }),
        Badge(id: "save10",    title: "Collector",      detail: "Save 10 of your own scenes",       glyph: .bookmark, test: { $0.savedCount >= 10 }),
        Badge(id: "min60",     title: "Unwound",        detail: "Listen for 60 minutes",            glyph: .moon,     test: { $0.minutes >= 60 }),
        Badge(id: "min300",    title: "Dreamer",        detail: "Listen for 5 hours",               glyph: .moon,     test: { $0.minutes >= 300 }),
        Badge(id: "min1000",   title: "Zen Master",     detail: "Listen for 1000 minutes",          glyph: .sparkle,  test: { $0.minutes >= 1000 }),
        Badge(id: "sleep",     title: "Deep Rest",      detail: "Finish a sleep timer",             glyph: .moon,     test: { $0.sleepCompleted >= 1 }),
        Badge(id: "focus",     title: "In The Zone",    detail: "Finish a focus session",           glyph: .target,   test: { $0.focusCompleted >= 1 }),
        Badge(id: "days7",     title: "Regular",        detail: "Use Murmora on 7 days",            glyph: .calendar, test: { $0.daysActive.count >= 7 }),
        Badge(id: "breath1",   title: "First Breath In",detail: "Finish a breathing session",       glyph: .leaf,     test: { $0.breathSessions >= 1 }),
        Badge(id: "breath10",  title: "Steady Rhythm",  detail: "Finish 10 breathing sessions",     glyph: .leaf,     test: { $0.breathSessions >= 10 }),
        Badge(id: "breath60",  title: "Long Exhale",    detail: "Breathe along for 60 minutes",     glyph: .heart,    test: { $0.breathMinutes >= 60 }),
    ]
}
