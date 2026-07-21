import SwiftUI

struct ScenesView: View {
    @EnvironmentObject var store: GroveStore
    @State private var mixToDelete: SavedMix?

    var body: some View {
        ZStack {
            AuroraBackground(tint: Grove.accent(.forest), secondary: Grove.accent(.sky), reduceMotion: store.reduceMotion)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Scenes").font(.system(size: 28, weight: .heavy, design: .rounded)).foregroundColor(Grove.ink)
                        Text("Curated blends and your own creations")
                            .font(.system(size: 14, weight: .medium, design: .rounded)).foregroundColor(Grove.subtle)
                    }
                    .padding(.top, 8)

                    // Featured tall card
                    if let featured = SceneCatalog.all.first {
                        FeaturedScene(preset: featured)
                    }

                    SectionHeader(title: "Ready-made", subtitle: "Tap to start listening")
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                        ForEach(SceneCatalog.all.dropFirst()) { p in
                            SceneCardView(preset: p)
                        }
                    }

                    if !store.savedMixes.isEmpty {
                        SectionHeader(title: "My Scenes", subtitle: "\(store.savedMixes.count) saved")
                            .padding(.top, 4)
                        VStack(spacing: 12) {
                            ForEach(store.savedMixes) { m in
                                SavedMixRow(mix: m, onDelete: { mixToDelete = m })
                            }
                        }
                    } else {
                        savedEmpty
                    }
                    Color.clear.frame(height: 24)
                }
                .padding(.horizontal, 18)
            }
        }
        .alert(item: $mixToDelete) { m in
            Alert(title: Text("Delete \"\(m.name)\"?"),
                  message: Text("This saved scene will be removed."),
                  primaryButton: .destructive(Text("Delete")) { withAnimation { store.deleteSaved(m) } },
                  secondaryButton: .cancel())
        }
    }

    private var savedEmpty: some View {
        VStack(spacing: 8) {
            GroveIcon(glyph: .bookmark, size: 30, color: Grove.gold.opacity(0.8))
            Text("No saved scenes yet").font(.system(size: 15, weight: .bold, design: .rounded)).foregroundColor(Grove.ink)
            Text("Build a blend in Studio and tap the bookmark to keep it here.")
                .font(.system(size: 12.5, weight: .medium, design: .rounded))
                .foregroundColor(Grove.subtle).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 26).groveCard()
    }
}

// MARK: - Featured

struct FeaturedScene: View {
    @EnvironmentObject var store: GroveStore
    let preset: ScenePreset
    var body: some View {
        Button {
            Haptic.soft(); store.loadPreset(preset)
        } label: {
            ZStack(alignment: .bottomLeading) {
                GroveImage(name: preset.cover, fallbackCat: preset.cat)
                LinearGradient(colors: [.clear, Grove.bgDeep.opacity(0.85)], startPoint: .center, endPoint: .bottom)
                VStack(alignment: .leading, spacing: 6) {
                    GrovePill(text: "Featured", color: Grove.gold, filled: true)
                    Text(preset.name).font(.system(size: 24, weight: .heavy, design: .rounded)).foregroundColor(.white)
                    Text(preset.blurb).font(.system(size: 13, weight: .medium, design: .rounded)).foregroundColor(.white.opacity(0.85))
                    HStack(spacing: 8) {
                        ForEach(orderedSounds(preset)) { s in SoundToken(sound: s, size: 30) }
                        Spacer()
                        HStack(spacing: 5) {
                            GroveIcon(glyph: .play, size: 14, color: Grove.bgDeep)
                            Text("Play").font(.system(size: 13, weight: .bold, design: .rounded)).foregroundColor(Grove.bgDeep)
                        }
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Capsule().fill(.white))
                    }
                    .padding(.top, 4)
                }
                .padding(18)
            }
            .frame(height: 240)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 26).strokeBorder(Grove.stroke, lineWidth: 1))
        }
        .buttonStyle(PressableStyle())
    }
}

func orderedSounds(_ p: ScenePreset) -> [GroveSound] {
    p.mix.keys.compactMap { SoundCatalog.by($0) }.sorted { ($0.name) < ($1.name) }
}
func orderedSounds(_ m: SavedMix) -> [GroveSound] {
    m.mix.keys.compactMap { SoundCatalog.by($0) }.sorted { ($0.name) < ($1.name) }
}

// MARK: - Scene card

struct SceneCardView: View {
    @EnvironmentObject var store: GroveStore
    let preset: ScenePreset
    var body: some View {
        Button {
            Haptic.soft(); store.loadPreset(preset)
        } label: {
            ZStack(alignment: .bottomLeading) {
                GroveImage(name: preset.cover, fallbackCat: preset.cat)
                LinearGradient(colors: [.clear, Grove.bgDeep.opacity(0.9)], startPoint: .center, endPoint: .bottom)
                VStack(alignment: .leading, spacing: 3) {
                    Text(preset.name).font(.system(size: 16, weight: .heavy, design: .rounded)).foregroundColor(.white).lineLimit(1)
                    HStack(spacing: 4) {
                        GroveIcon(glyph: .layers, size: 11, color: .white.opacity(0.8))
                        Text("\(preset.mix.count) sounds").font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(12)
                if store.currentLoadedName == preset.name && store.isPlaying {
                    VStack { HStack {
                        Spacer()
                        EqualizerBars(active: true, color: Grove.gold, bars: 3, reduceMotion: store.reduceMotion)
                            .padding(8).background(Circle().fill(Grove.bgDeep.opacity(0.6)))
                    }; Spacer() }.padding(8)
                }
            }
            .frame(height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Grove.stroke, lineWidth: 1))
        }
        .buttonStyle(PressableStyle())
    }
}

// MARK: - Saved mix row

struct SavedMixRow: View {
    @EnvironmentObject var store: GroveStore
    let mix: SavedMix
    let onDelete: () -> Void
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Grove.gradient(mix.cat)).frame(width: 52, height: 52)
                GroveIcon(glyph: .waveform, size: 22, color: .white)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(mix.name).font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(Grove.ink).lineLimit(1)
                HStack(spacing: -8) {
                    ForEach(orderedSounds(mix).prefix(4)) { s in
                        SoundToken(sound: s, size: 24)
                            .overlay(Circle().strokeBorder(Grove.bg, lineWidth: 1.5))
                    }
                    Text("  \(mix.mix.count) sounds").font(.system(size: 11.5, weight: .medium, design: .rounded)).foregroundColor(Grove.subtle)
                }
            }
            Spacer()
            RoundIconButton(glyph: .play, color: .white, bg: Grove.primary.opacity(0.9), size: 40, iconSize: 15) {
                Haptic.soft(); store.loadSaved(mix)
            }
            RoundIconButton(glyph: .trash, color: Grove.subtle, size: 40, iconSize: 16, action: onDelete)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Grove.card)
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Grove.stroke, lineWidth: 1)))
    }
}
