import SwiftUI

struct SoundDetailView: View {
    @EnvironmentObject var store: MurmoraStore
    @Environment(\.presentationMode) var presentation
    let sound: MurmoraSound

    /// Curated scenes this sound is part of.
    private var scenes: [ScenePreset] {
        SceneCatalog.all.filter { $0.mix[sound.id] != nil }
    }

    /// Sounds that share a curated scene with this one, most frequent first.
    private var pairsWith: [MurmoraSound] {
        var counts: [String: Int] = [:]
        for s in scenes {
            for id in s.mix.keys where id != sound.id { counts[id, default: 0] += 1 }
        }
        return counts.sorted { $0.value > $1.value }
            .compactMap { SoundCatalog.by($0.key) }
            .prefix(4).map { $0 }
    }

    private var listened: Double { store.stats.perSound[sound.id] ?? 0 }
    private var active: Bool { store.isActive(sound.id) }
    private var tint: Color { Murmora.accent(sound.cat) }

    var body: some View {
        ZStack {
            Murmora.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button { presentation.wrappedValue.dismiss() } label: {
                        ZStack { Circle().fill(Murmora.card).frame(width: 34, height: 34); MurmoraIcon(glyph: .close, size: 15, color: Murmora.ink) }
                    }
                }.padding(18)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        hero
                        controls
                        if !pairsWith.isEmpty { pairsCard }
                        if !scenes.isEmpty { scenesCard }
                        statsCard
                        Color.clear.frame(height: 20)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .frame(maxWidth: Murmora.contentMaxWidth)
        }
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(spacing: 12) {
            SoundToken(sound: sound, size: 108)
                .glow(tint, radius: 22, opacity: 0.55)
            VStack(spacing: 6) {
                Text(sound.name)
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundColor(Murmora.ink)
                MurmoraPill(text: sound.cat.title, color: tint)
                Text(sound.blurb)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Murmora.subtle)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: 14) {
            Button {
                Haptic.tap()
                withAnimation(.spring(response: 0.34, dampingFraction: 0.75)) { store.toggleSound(sound.id) }
            } label: {
                HStack(spacing: 8) {
                    MurmoraIcon(glyph: active ? .close : .plus, size: 16, color: active ? Murmora.ink : Murmora.bgDeep)
                    Text(active ? "Remove from mix" : "Add to mix")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundColor(active ? Murmora.ink : Murmora.bgDeep)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 14)
                .background(Capsule().fill(active ? Murmora.card : tint))
            }
            .buttonStyle(PressableStyle())

            if active {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Level in your mix")
                        .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                        .foregroundColor(Murmora.subtle)
                    VolumeSlider(value: Binding(get: { store.mix[sound.id] ?? 0 },
                                                set: { store.setVolume(sound.id, $0) }),
                                 tint: tint, height: 10)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .murmoraCard(padding: 14, radius: 18)
            }
        }
    }

    // MARK: - Pairs

    private var pairsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Blends well with", subtitle: "Drawn from the curated scenes")
            ForEach(pairsWith) { s in
                Button {
                    Haptic.tap()
                    if !store.isActive(s.id) { store.toggleSound(s.id) }
                } label: {
                    HStack(spacing: 10) {
                        SoundToken(sound: s, size: 34)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(s.name).font(.system(size: 14, weight: .bold, design: .rounded)).foregroundColor(Murmora.ink)
                            Text(s.blurb).font(.system(size: 11.5, weight: .medium, design: .rounded))
                                .foregroundColor(Murmora.subtle).lineLimit(1)
                        }
                        Spacer()
                        MurmoraIcon(glyph: store.isActive(s.id) ? .check : .plus, size: 16,
                                    color: store.isActive(s.id) ? Murmora.accent(s.cat) : Murmora.faint)
                    }
                    .murmoraCard(padding: 12, radius: 16)
                }
                .buttonStyle(PressableStyle())
            }
        }
    }

    // MARK: - Scenes

    private var scenesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Heard in", subtitle: "Ready-made scenes using this sound")
            ForEach(scenes) { p in
                Button {
                    Haptic.soft(); store.loadPreset(p); presentation.wrappedValue.dismiss()
                } label: {
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Murmora.gradient(p.cat)).frame(width: 44, height: 44)
                            MurmoraIcon(glyph: .play, size: 15, color: .white)
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text(p.name).font(.system(size: 14, weight: .bold, design: .rounded)).foregroundColor(Murmora.ink)
                            Text(p.blurb).font(.system(size: 11.5, weight: .medium, design: .rounded))
                                .foregroundColor(Murmora.subtle).lineLimit(1)
                        }
                        Spacer()
                        MurmoraIcon(glyph: .chevron, size: 15, color: Murmora.faint)
                    }
                    .murmoraCard(padding: 12, radius: 16)
                }
                .buttonStyle(PressableStyle())
            }
        }
    }

    // MARK: - Stats

    private var statsCard: some View {
        HStack(spacing: 10) {
            statBox(listened >= 60 ? "\(Int(listened / 60))m" : "\(Int(listened))s", "you played")
            statBox("\(scenes.count)", scenes.count == 1 ? "scene" : "scenes")
            statBox(store.stats.usedSounds.contains(sound.id) ? "Yes" : "Not yet", "tried")
        }
    }

    private func statBox(_ value: String, _ label: String) -> some View {
        VStack(spacing: 3) {
            Text(value).font(.system(size: 18, weight: .heavy, design: .rounded)).foregroundColor(Murmora.ink)
            Text(label).font(.system(size: 11.5, weight: .medium, design: .rounded)).foregroundColor(Murmora.subtle)
        }
        .frame(maxWidth: .infinity)
        .murmoraCard(padding: 12, radius: 16)
    }
}
