import SwiftUI

struct SleepView: View {
    @EnvironmentObject var store: GroveStore
    @State private var mode: TimerMode = .sleep
    @State private var showImmersive = false
    private let sleepOptions = [10, 15, 30, 45, 60, 90]
    private let focusOptions = [15, 25, 45, 60]

    var body: some View {
        ZStack {
            AuroraBackground(tint: mode == .sleep ? Grove.primary : Grove.accent(.water),
                             secondary: Grove.accent(.tones), reduceMotion: store.reduceMotion)
            if store.hasMix {
                LiveSceneView(active: store.activeSounds, volumes: store.mix,
                              playing: store.isPlaying, reduceMotion: store.reduceMotion, intensity: 0.5)
                    .opacity(0.5).ignoresSafeArea()
            }

            if store.timerMode != .none {
                activeTimer
            } else {
                setup
            }
        }
        .fullScreenCover(isPresented: $showImmersive) {
            ImmersiveView().environmentObject(store)
        }
    }

    // MARK: setup

    private var setup: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 22) {
                VStack(spacing: 4) {
                    Text("Rest & Focus").font(.system(size: 28, weight: .heavy, design: .rounded)).foregroundColor(Grove.ink)
                    Text("Play your grove for a set time, then let it fade")
                        .font(.system(size: 13.5, weight: .medium, design: .rounded))
                        .foregroundColor(Grove.subtle).multilineTextAlignment(.center)
                }
                .padding(.top, 12)

                BreathingOrb(playing: store.isPlaying, tint: mode == .sleep ? Grove.primary : Grove.accent(.water),
                             reduceMotion: store.reduceMotion)
                    .frame(height: 190)

                // mode switch
                HStack(spacing: 0) {
                    modeTab(.sleep, "Sleep", .moon)
                    modeTab(.focus, "Focus", .target)
                }
                .padding(4)
                .background(Capsule().fill(Grove.card).overlay(Capsule().strokeBorder(Grove.stroke, lineWidth: 1)))

                if !store.hasMix {
                    HStack(spacing: 8) {
                        GroveIcon(glyph: .info, size: 16, color: Grove.gold)
                        Text("Pick sounds in Studio or Scenes first.")
                            .font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundColor(Grove.subtle)
                    }
                    .padding(.vertical, 12).padding(.horizontal, 16)
                    .frame(maxWidth: .infinity).groveCard(padding: 4)
                } else {
                    nowPlayingCard
                }

                // duration grid
                Text(mode == .sleep ? "Fade out after" : "Focus for")
                    .font(.system(size: 15, weight: .bold, design: .rounded)).foregroundColor(Grove.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(mode == .sleep ? sleepOptions : focusOptions, id: \.self) { min in
                        Button {
                            Haptic.soft(); store.startTimer(mode: mode, minutes: min)
                        } label: {
                            VStack(spacing: 3) {
                                Text("\(min)").font(.system(size: 26, weight: .heavy, design: .rounded)).foregroundColor(Grove.ink)
                                Text("min").font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundColor(Grove.subtle)
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(RoundedRectangle(cornerRadius: 18).fill(Grove.card)
                                .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Grove.stroke, lineWidth: 1)))
                        }
                        .buttonStyle(PressableStyle())
                        .disabled(!store.hasMix)
                        .opacity(store.hasMix ? 1 : 0.5)
                    }
                }
                Color.clear.frame(height: 20)
            }
            .padding(.horizontal, 18)
        }
    }

    private func modeTab(_ m: TimerMode, _ label: String, _ glyph: GroveGlyph) -> some View {
        let sel = mode == m
        return Button {
            Haptic.tap(); withAnimation(.easeInOut(duration: 0.2)) { mode = m }
        } label: {
            HStack(spacing: 6) {
                GroveIcon(glyph: glyph, size: 16, color: sel ? Grove.bgDeep : Grove.subtle)
                Text(label).font(.system(size: 14, weight: .bold, design: .rounded)).foregroundColor(sel ? Grove.bgDeep : Grove.subtle)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 10)
            .background(Capsule().fill(sel ? Grove.primary : Color.clear))
        }
        .buttonStyle(PressableStyle())
    }

    private var nowPlayingCard: some View {
        HStack(spacing: 12) {
            Button { store.togglePlay() } label: {
                ZStack {
                    Circle().fill(Grove.heroGradient).frame(width: 48, height: 48)
                    GroveIcon(glyph: store.isPlaying ? .pause : .play, size: 20, color: .white)
                }
            }.buttonStyle(PressableStyle())
            VStack(alignment: .leading, spacing: 3) {
                Text(store.currentLoadedName ?? "Your blend").font(.system(size: 15, weight: .bold, design: .rounded)).foregroundColor(Grove.ink).lineLimit(1)
                HStack(spacing: -8) {
                    ForEach(store.activeSounds.prefix(5)) { s in
                        SoundToken(sound: s, size: 26).overlay(Circle().strokeBorder(Grove.bg, lineWidth: 1.5))
                    }
                }
            }
            Spacer()
            Button { Haptic.soft(); showImmersive = true } label: {
                HStack(spacing: 5) {
                    GroveIcon(glyph: .sparkle, size: 13, color: Grove.bgDeep)
                    Text("Immerse").font(.system(size: 12.5, weight: .bold, design: .rounded)).foregroundColor(Grove.bgDeep)
                }
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(Capsule().fill(Grove.gold))
            }.buttonStyle(PressableStyle())
        }
        .groveCard(padding: 12)
    }

    // MARK: active timer

    private var activeTimer: some View {
        VStack(spacing: 26) {
            Spacer()
            Text(store.timerMode == .sleep ? "Drifting off" : "In focus")
                .font(.system(size: 15, weight: .bold, design: .rounded)).foregroundColor(Grove.gold)
                .textCase(.uppercase)
            ZStack {
                ProgressRing(progress: store.timerProgress,
                             tint: store.timerMode == .sleep ? Grove.primary : Grove.accent(.water), line: 12)
                    .frame(width: 250, height: 250)
                BreathingOrb(playing: store.isPlaying, tint: store.timerMode == .sleep ? Grove.primary : Grove.accent(.water),
                             reduceMotion: store.reduceMotion, compact: true)
                    .frame(width: 180, height: 180)
                VStack(spacing: 4) {
                    Text(formatMinSec(store.timerRemaining))
                        .font(.system(size: 46, weight: .heavy, design: .rounded)).foregroundColor(Grove.ink)
                        .monospacedDigit()
                    Text("remaining").font(.system(size: 13, weight: .medium, design: .rounded)).foregroundColor(Grove.subtle)
                }
            }
            Text(store.currentLoadedName ?? "\(store.activeCount) sounds playing")
                .font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundColor(Grove.subtle)
            Spacer()
            Button {
                Haptic.tap(); store.cancelTimer()
            } label: {
                Text("Cancel timer")
                    .font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(Grove.ink)
                    .frame(maxWidth: .infinity).padding(.vertical, 15)
                    .background(Capsule().fill(Grove.card).overlay(Capsule().strokeBorder(Grove.stroke, lineWidth: 1)))
                    .padding(.horizontal, 40)
            }
            .buttonStyle(PressableStyle())
            Spacer().frame(height: 20)
        }
        .padding()
    }
}

// MARK: - Breathing orb

struct BreathingOrb: View {
    var playing: Bool
    var tint: Color
    var reduceMotion: Bool = false
    var compact: Bool = false
    @State private var breathe = false

    var body: some View {
        ZStack {
            ForEach(0..<3) { i in
                Circle()
                    .stroke(tint.opacity(0.25 - Double(i) * 0.06), lineWidth: 2)
                    .frame(width: (compact ? 90 : 120) + CGFloat(i) * 40)
                    .scaleEffect(breathe ? 1.12 : 0.9)
            }
            Circle()
                .fill(RadialGradient(colors: [tint.opacity(0.9), tint.opacity(0.2)], center: .center, startRadius: 4, endRadius: compact ? 80 : 96))
                .frame(width: compact ? 96 : 120, height: compact ? 96 : 120)
                .scaleEffect(breathe ? 1.08 : 0.86)
                .glow(tint, radius: 30, opacity: 0.6)
            GroveIcon(glyph: .leaf, size: compact ? 30 : 40, color: .white.opacity(0.9))
                .scaleEffect(breathe ? 1.05 : 0.92)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) { breathe = true }
        }
    }
}
