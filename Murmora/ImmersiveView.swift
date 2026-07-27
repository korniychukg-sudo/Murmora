import SwiftUI

/// Full-screen "Now Playing" — the living scene fills the display with a soft
/// clock and auto-hiding minimal controls. Beautiful to leave on overnight.
struct ImmersiveView: View {
    @EnvironmentObject var store: MurmoraStore
    @Environment(\.presentationMode) var presentation
    @State private var showControls = true
    @State private var hideGen = 0

    private let clockFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "H:mm"; return f
    }()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            LiveSceneView(active: store.activeSounds, volumes: store.mix,
                          playing: store.isPlaying, reduceMotion: store.reduceMotion, intensity: 1.25)
                .ignoresSafeArea()

            // gentle top/bottom scrims for legibility
            VStack {
                LinearGradient(colors: [Color.black.opacity(0.5), .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: 200)
                Spacer()
                LinearGradient(colors: [.clear, Color.black.opacity(0.55)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 240)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                topBar.opacity(showControls ? 1 : 0)
                Spacer()
                clock
                Spacer()
                bottomControls.opacity(showControls ? 1 : 0)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .contentShape(Rectangle())
        .onTapGesture { toggleControls() }
        .onAppear { scheduleHide() }
        .statusBarHidden(true)
        .preferredColorScheme(.dark)
    }

    // MARK: clock
    private var clock: some View {
        TimelineView(.periodic(from: Date(), by: 20)) { ctx in
            VStack(spacing: 10) {
                Text(clockFormatter.string(from: ctx.date))
                    .font(.system(size: 74, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: Murmora.primary.opacity(0.6), radius: 24)
                    .shadow(color: .black.opacity(0.4), radius: 8, y: 4)
                Text(store.currentLoadedName ?? "\(store.activeCount) sounds")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                HStack(spacing: -8) {
                    ForEach(store.activeSounds.prefix(6)) { s in
                        SoundToken(sound: s, size: 34)
                            .overlay(Circle().strokeBorder(Color.black.opacity(0.3), lineWidth: 1.5))
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    // MARK: top bar
    private var topBar: some View {
        HStack {
            if store.timerMode != .none {
                HStack(spacing: 6) {
                    MurmoraIcon(glyph: .moon, size: 15, color: Murmora.gold)
                    Text(formatMinSec(store.timerRemaining))
                        .font(.system(size: 15, weight: .bold, design: .rounded)).foregroundColor(.white).monospacedDigit()
                }
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(Capsule().fill(Color.black.opacity(0.35)))
            }
            Spacer()
            Button { presentation.wrappedValue.dismiss() } label: {
                ZStack {
                    Circle().fill(Color.black.opacity(0.4)).frame(width: 42, height: 42)
                    MurmoraIcon(glyph: .close, size: 16, color: .white)
                }
            }.buttonStyle(PressableStyle())
        }
    }

    // MARK: bottom controls
    private var bottomControls: some View {
        VStack(spacing: 16) {
            HStack(spacing: 10) {
                ForEach([15, 30, 60], id: \.self) { m in
                    Button {
                        Haptic.soft(); store.startTimer(mode: .sleep, minutes: m); scheduleHide()
                    } label: {
                        Text("\(m)m")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(store.timerMode == .sleep ? Murmora.bgDeep : .white)
                            .padding(.horizontal, 16).padding(.vertical, 9)
                            .background(Capsule().fill(store.timerMode == .sleep ? Murmora.gold : Color.white.opacity(0.14)))
                    }.buttonStyle(PressableStyle())
                }
                if store.timerMode != .none {
                    Button { Haptic.tap(); store.cancelTimer() } label: {
                        MurmoraIcon(glyph: .close, size: 14, color: .white)
                            .padding(10).background(Circle().fill(Color.white.opacity(0.14)))
                    }.buttonStyle(PressableStyle())
                }
            }
            Button {
                Haptic.soft(); store.togglePlay(); scheduleHide()
            } label: {
                ZStack {
                    Circle().fill(Murmora.heroGradient).frame(width: 72, height: 72)
                        .glow(Murmora.primary, radius: 20, opacity: 0.6)
                    MurmoraIcon(glyph: store.isPlaying ? .pause : .play, size: 30, color: .white)
                        .offset(x: store.isPlaying ? 0 : 2)
                }
            }.buttonStyle(PressableStyle())
        }
    }

    // MARK: chrome auto-hide
    private func toggleControls() {
        withAnimation(.easeInOut(duration: 0.25)) { showControls.toggle() }
        if showControls { scheduleHide() }
    }
    private func scheduleHide() {
        showControls = true
        hideGen += 1
        let gen = hideGen
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            if gen == hideGen && store.isPlaying {
                withAnimation(.easeInOut(duration: 0.4)) { showControls = false }
            }
        }
    }
}
