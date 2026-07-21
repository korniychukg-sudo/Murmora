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

struct GroveSound: Identifiable, Equatable {
    let id: String       // matches wav + tok_<id>.png
    let name: String
    let cat: SoundCat
    let blurb: String
    var token: String { "tok_\(id)" }
    var file: String { id }
    static func == (a: GroveSound, b: GroveSound) -> Bool { a.id == b.id }
}

enum SoundCatalog {
    static let all: [GroveSound] = [
        // Rain & Sky
        GroveSound(id: "rain",       name: "Rain Shower",    cat: .sky,   blurb: "A soft, steady curtain of rain."),
        GroveSound(id: "heavyrain",  name: "Heavy Rain",     cat: .sky,   blurb: "Downpour drumming on the roof."),
        GroveSound(id: "thunder",    name: "Distant Thunder",cat: .sky,   blurb: "Low rolls beyond the horizon."),
        GroveSound(id: "wind",       name: "Gentle Wind",    cat: .sky,   blurb: "Air moving through open space."),
        // Fireside & Home
        GroveSound(id: "campfire",   name: "Campfire",       cat: .fire,  blurb: "Crackling logs and warm embers."),
        GroveSound(id: "fan",        name: "Cozy Fan",       cat: .fire,  blurb: "The even hush of a room fan."),
        GroveSound(id: "chimes",     name: "Wind Chimes",    cat: .fire,  blurb: "Soft bells stirred by a breeze."),
        GroveSound(id: "heartbeat",  name: "Calm Heartbeat", cat: .fire,  blurb: "A slow, grounding pulse."),
        // Water & Places
        GroveSound(id: "ocean",      name: "Ocean Waves",    cat: .water, blurb: "Swells breaking on the shore."),
        GroveSound(id: "stream",     name: "Forest Stream",  cat: .water, blurb: "Water burbling over stones."),
        GroveSound(id: "frogs",      name: "Pond Frogs",     cat: .water, blurb: "Croaks across a still pond."),
        GroveSound(id: "train",      name: "Night Train",    cat: .water, blurb: "Rhythmic rails through the dark."),
        // Forest & Night
        GroveSound(id: "crickets",   name: "Night Crickets", cat: .forest,blurb: "A meadow humming after dusk."),
        GroveSound(id: "owl",        name: "Night Owl",      cat: .forest,blurb: "Hoots drifting between the trees."),
        GroveSound(id: "birds",      name: "Morning Birds",  cat: .forest,blurb: "A dawn chorus of songbirds."),
        GroveSound(id: "leaves",     name: "Rustling Leaves",cat: .forest,blurb: "Gusts brushing through foliage."),
        // Focus & Tones
        GroveSound(id: "bowl",       name: "Singing Bowl",   cat: .tones, blurb: "A resonant, meditative drone."),
        GroveSound(id: "piano",      name: "Soft Piano",     cat: .tones, blurb: "Sparse, gentle piano notes."),
        GroveSound(id: "whitenoise", name: "White Noise",    cat: .tones, blurb: "An even veil that masks the world."),
        GroveSound(id: "brownnoise", name: "Brown Noise",    cat: .tones, blurb: "Deep, warm low-frequency hush."),
        // v2 additions (6 per category)
        GroveSound(id: "rain_tent",  name: "Rain on Tent",   cat: .sky,   blurb: "Soft patter close overhead."),
        GroveSound(id: "blizzard",   name: "Blizzard Wind",  cat: .sky,   blurb: "Snow-laden gusts and a low howl."),
        GroveSound(id: "cat",        name: "Purring Cat",    cat: .fire,  blurb: "A warm, steady purr."),
        GroveSound(id: "clock",      name: "Ticking Clock",  cat: .fire,  blurb: "The calm rhythm of a room clock."),
        GroveSound(id: "drips",      name: "Cave Drips",     cat: .water, blurb: "Echoing drops in a still cavern."),
        GroveSound(id: "rowboat",    name: "Rowboat Creaks", cat: .water, blurb: "Wooden creaks and lapping water."),
        GroveSound(id: "cicadas",    name: "Summer Cicadas", cat: .forest,blurb: "A shimmering afternoon chorus."),
        GroveSound(id: "wolves",     name: "Distant Wolves", cat: .forest,blurb: "Far-off howls under the moon."),
        GroveSound(id: "pinknoise",  name: "Pink Noise",     cat: .tones, blurb: "A soft, balanced wash of sound."),
        GroveSound(id: "omdrone",    name: "Om Drone",       cat: .tones, blurb: "A sustained, grounding chant tone."),
    ]

    static func by(_ id: String) -> GroveSound? { all.first { $0.id == id } }
    static func inCat(_ c: SoundCat) -> [GroveSound] { all.filter { $0.cat == c } }
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
    let glyph: GroveGlyph
    let test: (GroveStats) -> Bool
}

struct GroveStats: Codable {
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

    var minutes: Int { Int(totalSeconds / 60) }
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
        Badge(id: "all20",     title: "Full Palette",   detail: "Try all 20 sounds",               glyph: .grid,     test: { $0.usedSounds.count >= 20 }),
        Badge(id: "save3",     title: "Curator",        detail: "Save 3 of your own scenes",        glyph: .bookmark, test: { $0.savedCount >= 3 }),
        Badge(id: "save10",    title: "Collector",      detail: "Save 10 of your own scenes",       glyph: .bookmark, test: { $0.savedCount >= 10 }),
        Badge(id: "min60",     title: "Unwound",        detail: "Listen for 60 minutes",            glyph: .moon,     test: { $0.minutes >= 60 }),
        Badge(id: "min300",    title: "Dreamer",        detail: "Listen for 5 hours",               glyph: .moon,     test: { $0.minutes >= 300 }),
        Badge(id: "min1000",   title: "Zen Master",     detail: "Listen for 1000 minutes",          glyph: .sparkle,  test: { $0.minutes >= 1000 }),
        Badge(id: "sleep",     title: "Deep Rest",      detail: "Finish a sleep timer",             glyph: .moon,     test: { $0.sleepCompleted >= 1 }),
        Badge(id: "focus",     title: "In The Zone",    detail: "Finish a focus session",           glyph: .target,   test: { $0.focusCompleted >= 1 }),
        Badge(id: "days7",     title: "Regular",        detail: "Use Sound Grove on 7 days",        glyph: .calendar, test: { $0.daysActive.count >= 7 }),
    ]
}
