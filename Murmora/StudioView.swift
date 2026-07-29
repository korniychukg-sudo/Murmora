import SwiftUI

struct StudioView: View {
    @EnvironmentObject var store: MurmoraStore
    @State private var showSave = false
    @State private var saveName = ""
    @State private var sparkle = false
    @State private var showImmersive = false

    var body: some View {
        ZStack {
            AuroraBackground(tint: store.hasMix ? Murmora.accent(store.dominantCat()) : Murmora.primary,
                             secondary: Murmora.accent(.water),
                             reduceMotion: store.reduceMotion)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    header
                    stage
                    masterBar
                    ForEach(SoundCat.allCases) { cat in
                        categorySection(cat)
                    }
                    Color.clear.frame(height: 24)
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
            }

            SparkleBurst(trigger: sparkle).allowsHitTesting(false)
        }
        .sheet(isPresented: $showSave) { saveSheet }
        .fullScreenCover(isPresented: $showImmersive) {
            ImmersiveView().environmentObject(store)
        }
    }

    // MARK: header

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Murmora")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundColor(Murmora.ink)
                Text(store.currentLoadedName ?? (store.hasMix ? "\(store.activeCount) sounds blending" : "Build your soundscape"))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(Murmora.subtle)
            }
            Spacer()
            EqualizerBars(active: store.isPlaying, color: Murmora.gold, bars: 5, reduceMotion: store.reduceMotion)
                .frame(width: 34)
        }
        .padding(.top, 6)
    }

    // MARK: the living stage

    private var stage: some View {
        ZStack {
            // Living animated scene behind everything
            LiveSceneView(active: store.activeSounds, volumes: store.mix,
                          playing: store.isPlaying, reduceMotion: store.reduceMotion, intensity: 0.7)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 28).strokeBorder(Murmora.stroke, lineWidth: 1))

            if store.activeSounds.isEmpty {
                VStack(spacing: 10) {
                    MurmoraIcon(glyph: .waveform, size: 40, color: Murmora.primary.opacity(0.8))
                    Text("Your soundscape is quiet")
                        .font(.system(size: 17, weight: .bold, design: .rounded)).foregroundColor(Murmora.ink)
                    Text("Tap sounds below to bring the scene to life.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(Murmora.subtle).multilineTextAlignment(.center)
                }
                .padding(.horizontal, 30)
            } else {
                let shown = Array(store.activeSounds.prefix(8))
                GeometryReader { geo in
                    ForEach(Array(shown.enumerated()), id: \.element.id) { idx, s in
                        FloatingToken(sound: s, volume: store.mix[s.id] ?? 0.5,
                                      playing: store.isPlaying, reduceMotion: store.reduceMotion, index: idx)
                            .position(stagePosition(idx, count: shown.count, in: geo.size))
                    }
                    if store.activeCount > 8 {
                        Text("+\(store.activeCount - 8)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(Murmora.subtle)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(Capsule().fill(Murmora.bgDeep.opacity(0.7)))
                            .position(x: geo.size.width - 32, y: geo.size.height - 18)
                    }
                }
            }
        }
        .frame(height: 210)
        .overlay(alignment: .topTrailing) {
            if store.hasMix {
                Button {
                    Haptic.soft(); showImmersive = true
                } label: {
                    HStack(spacing: 5) {
                        MurmoraIcon(glyph: .sparkle, size: 13, color: .white)
                        Text("Immerse").font(.system(size: 12.5, weight: .bold, design: .rounded)).foregroundColor(.white)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 7)
                    .background(Capsule().fill(Murmora.bgDeep.opacity(0.55))
                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.25), lineWidth: 1)))
                }
                .buttonStyle(PressableStyle())
                .padding(12)
            }
        }
    }

    private func stagePosition(_ i: Int, count: Int, in size: CGSize) -> CGPoint {
        let cols = min(count, 4)
        let rows = Int(ceil(Double(count) / Double(cols)))
        let col = i % cols, row = i / cols
        let cw = size.width / CGFloat(cols)
        let rh = size.height / CGFloat(max(1, rows))
        let x = cw * (CGFloat(col) + 0.5)
        let y = rh * (CGFloat(row) + 0.5)
        return CGPoint(x: x, y: y)
    }

    // MARK: master controls

    private var masterBar: some View {
        HStack(spacing: 14) {
            Button {
                Haptic.soft(); store.togglePlay()
            } label: {
                ZStack {
                    Circle().fill(store.hasMix ? Murmora.heroGradient
                                  : LinearGradient(colors: [Murmora.faint.opacity(0.4), Murmora.faint.opacity(0.2)], startPoint: .top, endPoint: .bottom))
                        .frame(width: 60, height: 60)
                        .glow(Murmora.primary, radius: 16, opacity: store.isPlaying ? 0.6 : 0.2)
                    MurmoraIcon(glyph: store.isPlaying ? .pause : .play, size: 26, color: .white)
                        .offset(x: store.isPlaying ? 0 : 2)
                }
            }
            .buttonStyle(PressableStyle())
            .disabled(!store.hasMix)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Master").font(.system(size: 12, weight: .bold, design: .rounded)).foregroundColor(Murmora.subtle)
                    Spacer()
                    Text("\(Int(store.masterVolume * 100))%").font(.system(size: 12, weight: .bold, design: .rounded)).foregroundColor(Murmora.faint)
                }
                VolumeSlider(value: Binding(get: { store.masterVolume },
                                            set: { store.setMaster($0) }), tint: Murmora.primary)
            }

            RoundIconButton(glyph: .bookmark, color: Murmora.gold, size: 44, iconSize: 18) {
                guard store.hasMix else { return }
                saveName = store.currentLoadedName ?? ""
                showSave = true
            }
            .opacity(store.hasMix ? 1 : 0.4)

            RoundIconButton(glyph: .trash, color: Murmora.subtle, size: 44, iconSize: 18) {
                Haptic.tap(); withAnimation { store.clearMix() }
            }
            .opacity(store.hasMix ? 1 : 0.4)
        }
        .murmoraCard(padding: 14, radius: 24)
    }

    // MARK: category section

    private func categorySection(_ cat: SoundCat) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Circle().fill(Murmora.accent(cat)).frame(width: 10, height: 10)
                Text(cat.title).font(.system(size: 17, weight: .heavy, design: .rounded)).foregroundColor(Murmora.ink)
                Spacer()
                Text("hold for details")
                    .font(.system(size: 11, weight: .medium, design: .rounded)).foregroundColor(Murmora.faint)
            }
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(SoundCatalog.inCat(cat)) { sound in
                    SoundCard(sound: sound)
                }
            }
        }
    }

    // MARK: save sheet

    private var saveSheet: some View {
        ZStack {
            Murmora.bg.ignoresSafeArea()
            VStack(spacing: 18) {
                Capsule().fill(Murmora.stroke).frame(width: 40, height: 5).padding(.top, 10)
                Text("Save Scene").font(.system(size: 22, weight: .heavy, design: .rounded)).foregroundColor(Murmora.ink)
                Text("\(store.activeCount) sounds in this blend")
                    .font(.system(size: 13, weight: .medium, design: .rounded)).foregroundColor(Murmora.subtle)

                HStack(spacing: 10) {
                    ForEach(store.activeSounds.prefix(5)) { s in
                        SoundToken(sound: s, size: 40)
                    }
                }

                TextField("", text: $saveName)
                    .placeholder(when: saveName.isEmpty) {
                        Text("Name your scene").foregroundColor(Murmora.faint)
                    }
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(Murmora.ink)
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Murmora.card)
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Murmora.stroke, lineWidth: 1)))
                    .padding(.horizontal, 24)

                Button {
                    store.saveCurrentMix(name: saveName)
                    Haptic.success(); sparkle.toggle()
                    showSave = false
                } label: {
                    Text("Save Scene")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(Murmora.bgDeep)
                        .frame(maxWidth: .infinity).padding(.vertical, 15)
                        .background(Capsule().fill(Murmora.gold))
                        .padding(.horizontal, 24)
                }
                .buttonStyle(PressableStyle())

                Button("Cancel") { showSave = false }
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(Murmora.subtle)
                Spacer()
            }
        }
    }
}

// MARK: - Sound card

struct SoundCard: View {
    @EnvironmentObject var store: MurmoraStore
    let sound: MurmoraSound
    @State private var showDetail = false

    var body: some View {
        let active = store.isActive(sound.id)
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                SoundToken(sound: sound, size: 46)
                    .glow(Murmora.accent(sound.cat), radius: active ? 10 : 0, opacity: active ? 0.6 : 0)
                VStack(alignment: .leading, spacing: 2) {
                    Text(sound.name)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Murmora.ink).lineLimit(1).minimumScaleFactor(0.8)
                    if active {
                        EqualizerBars(active: store.isPlaying, color: Murmora.accent(sound.cat), bars: 4, reduceMotion: store.reduceMotion)
                            .frame(height: 12, alignment: .leading)
                    } else {
                        Text(sound.blurb)
                            .font(.system(size: 10.5, weight: .medium, design: .rounded))
                            .foregroundColor(Murmora.subtle).lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
            }
            if active {
                VolumeSlider(value: Binding(get: { store.mix[sound.id] ?? 0 },
                                            set: { store.setVolume(sound.id, $0) }),
                             tint: Murmora.accent(sound.cat), height: 8)
            }
        }
        .padding(12)
        .frame(height: active ? 118 : 74)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(active ? Murmora.accent(sound.cat).opacity(0.14) : Murmora.card)
                .overlay(RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(active ? Murmora.accent(sound.cat).opacity(0.6) : Murmora.stroke, lineWidth: active ? 1.5 : 1))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            Haptic.tap()
            withAnimation(.spring(response: 0.34, dampingFraction: 0.7)) { store.toggleSound(sound.id) }
        }
        .onLongPressGesture(minimumDuration: 0.4) {
            Haptic.soft(); showDetail = true
        }
        .sheet(isPresented: $showDetail) {
            SoundDetailView(sound: sound).environmentObject(store)
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.75), value: active)
    }
}

// Placeholder helper for TextField (iOS 15 friendly)
extension View {
    func placeholder<Content: View>(when show: Bool, alignment: Alignment = .leading,
                                    @ViewBuilder placeholder: () -> Content) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(show ? 1 : 0)
            self
        }
    }
}
