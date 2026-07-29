import SwiftUI

struct BreatheView: View {
    @EnvironmentObject var store: MurmoraStore

    @State private var patternID = "box"
    @State private var minutes = 5
    @State private var startedAt: Date? = nil
    @State private var elapsed: Double = 0
    @State private var justFinished = false
    @State private var withSound = true

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var pattern: BreathPattern { BreathCatalog.by(patternID) ?? BreathCatalog.all[0] }
    private var total: Double { Double(minutes * 60) }
    private var running: Bool { startedAt != nil }
    private var tint: Color { Murmora.accent(pattern.cat) }

    var body: some View {
        ZStack {
            AuroraBackground(tint: tint, secondary: Murmora.primary, animated: !store.reduceMotion)
                .opacity(running ? 0.85 : 0.45)
            if running { runner } else { setup }
        }
        .onReceive(ticker) { _ in
            guard let s = startedAt else { return }
            elapsed = Date().timeIntervalSince(s)
            if elapsed >= total { finish(completed: true) }
        }
    }

    // MARK: - Setup

    private var setup: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Breathe").font(.system(size: 30, weight: .heavy, design: .rounded)).foregroundColor(Murmora.ink)
                    Text("Slow your breath, with or without sound")
                        .font(.system(size: 14, weight: .medium, design: .rounded)).foregroundColor(Murmora.subtle)
                }

                if justFinished { finishedCard }

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Pattern", subtitle: "Pick a rhythm to follow")
                    ForEach(BreathCatalog.all) { p in
                        patternCard(p)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Length", subtitle: "How long you want to sit with it")
                    HStack(spacing: 10) {
                        ForEach([2, 5, 10, 15], id: \.self) { m in
                            Button {
                                Haptic.soft(); minutes = m
                            } label: {
                                Text("\(m) min")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundColor(minutes == m ? Murmora.bgDeep : Murmora.ink)
                                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                                    .background(Capsule().fill(minutes == m ? tint : Murmora.card))
                            }
                            .buttonStyle(PressableStyle())
                        }
                    }
                }

                Button {
                    Haptic.soft(); withSound.toggle()
                } label: {
                    HStack(spacing: 12) {
                        MurmoraIcon(glyph: .waveform, size: 18, color: withSound ? tint : Murmora.faint)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Play my soundscape").font(.system(size: 15, weight: .bold, design: .rounded)).foregroundColor(Murmora.ink)
                            Text(store.hasMix ? "Starts your current mix when the session begins"
                                              : "Add sounds in Studio to use this")
                                .font(.system(size: 12.5, weight: .medium, design: .rounded)).foregroundColor(Murmora.subtle)
                        }
                        Spacer()
                        ZStack {
                            Capsule().fill(withSound ? tint.opacity(0.9) : Color.white.opacity(0.12)).frame(width: 46, height: 28)
                            Circle().fill(.white).frame(width: 22, height: 22)
                                .offset(x: withSound ? 9 : -9)
                        }
                    }
                    .murmoraCard(padding: 14, radius: 18)
                }
                .buttonStyle(PressableStyle())

                Button {
                    start()
                } label: {
                    HStack(spacing: 8) {
                        MurmoraIcon(glyph: .play, size: 17, color: Murmora.bgDeep)
                        Text("Begin \(minutes)-minute session")
                            .font(.system(size: 16, weight: .heavy, design: .rounded)).foregroundColor(Murmora.bgDeep)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(Capsule().fill(tint))
                }
                .buttonStyle(PressableStyle())

                statsRow

                Color.clear.frame(height: 24)
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
        }
    }

    private func patternCard(_ p: BreathPattern) -> some View {
        let selected = p.id == patternID
        return Button {
            Haptic.soft(); patternID = p.id
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle().fill(Murmora.gradient(p.cat)).frame(width: 38, height: 38)
                        Text(p.ratio).font(.system(size: 10, weight: .heavy, design: .rounded)).foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(p.name).font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(Murmora.ink)
                        Text(p.blurb).font(.system(size: 12.5, weight: .medium, design: .rounded)).foregroundColor(Murmora.subtle)
                    }
                    Spacer()
                    if selected { MurmoraIcon(glyph: .check, size: 18, color: Murmora.accent(p.cat)) }
                }
                if selected {
                    Text(p.detail)
                        .font(.system(size: 12.5, weight: .medium, design: .rounded))
                        .foregroundColor(Murmora.subtle)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("One cycle takes \(Int(p.cycle)) seconds")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(Murmora.accent(p.cat))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .murmoraCard(padding: 14, radius: 18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(selected ? Murmora.accent(p.cat).opacity(0.7) : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(PressableStyle())
    }

    private var finishedCard: some View {
        HStack(spacing: 12) {
            MurmoraIcon(glyph: .check, size: 20, color: Murmora.gold)
            VStack(alignment: .leading, spacing: 2) {
                Text("Session complete").font(.system(size: 15, weight: .bold, design: .rounded)).foregroundColor(Murmora.ink)
                Text("That is \(store.stats.breathSessions) breathing \(store.stats.breathSessions == 1 ? "session" : "sessions") so far")
                    .font(.system(size: 12.5, weight: .medium, design: .rounded)).foregroundColor(Murmora.subtle)
            }
            Spacer()
        }
        .murmoraCard(padding: 14, radius: 18)
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            miniStat("\(store.stats.breathSessions)", "sessions")
            miniStat("\(store.stats.breathMinutes)m", "breathing")
            miniStat("\(Int(pattern.cycle))s", "per cycle")
        }
    }

    private func miniStat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 3) {
            Text(value).font(.system(size: 19, weight: .heavy, design: .rounded)).foregroundColor(Murmora.ink)
            Text(label).font(.system(size: 11.5, weight: .medium, design: .rounded)).foregroundColor(Murmora.subtle)
        }
        .frame(maxWidth: .infinity)
        .murmoraCard(padding: 12, radius: 16)
    }

    // MARK: - Runner

    private var runner: some View {
        TimelineView(.animation(minimumInterval: store.reduceMotion ? 0.5 : nil)) { ctx in
            let t = startedAt.map { max(0, ctx.date.timeIntervalSince($0)) } ?? 0
            let inCycle = t.truncatingRemainder(dividingBy: pattern.cycle)
            let phase = pattern.phase(at: inCycle).0
            let full = pattern.fullness(at: inCycle)
            let remaining = max(0, total - t)

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(RadialGradient(colors: [tint.opacity(0.5), tint.opacity(0.02)],
                                             center: .center, startRadius: 8, endRadius: 165))
                        .frame(width: 300, height: 300)
                        .scaleEffect(0.5 + 0.5 * full)

                    Circle()
                        .strokeBorder(tint.opacity(0.5), lineWidth: 2)
                        .frame(width: 250, height: 250)
                        .scaleEffect(0.55 + 0.45 * full)

                    ProgressRing(progress: total > 0 ? t / total : 0, tint: tint, line: 5)
                        .frame(width: 320, height: 320)

                    VStack(spacing: 6) {
                        Text(phase.label)
                            .font(.system(size: 26, weight: .heavy, design: .rounded))
                            .foregroundColor(Murmora.ink)
                        Text("cycle \(Int(t / pattern.cycle) + 1)")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(Murmora.subtle)
                    }
                }
                .frame(height: 340)

                Spacer()

                VStack(spacing: 4) {
                    Text(mmss(remaining))
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundColor(Murmora.ink)
                        .monospacedDigit()
                    Text("\(pattern.name) • \(pattern.ratio)")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(Murmora.subtle)
                }

                Button {
                    Haptic.soft(); finish(completed: false)
                } label: {
                    Text("End session")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(Murmora.ink)
                        .padding(.horizontal, 30).padding(.vertical, 13)
                        .background(Capsule().fill(Murmora.card))
                }
                .buttonStyle(PressableStyle())
                .padding(.top, 22)
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 18)
        }
    }

    // MARK: - Actions

    private func start() {
        Haptic.soft()
        justFinished = false
        elapsed = 0
        startedAt = Date()
        if withSound && store.hasMix && !store.isPlaying { store.play() }
    }

    private func finish(completed: Bool) {
        let secs = min(elapsed, total)
        startedAt = nil
        elapsed = 0
        store.logBreath(seconds: secs)
        if completed {
            Haptic.success()
            withAnimation(.easeInOut) { justFinished = true }
        }
    }

    private func mmss(_ s: Double) -> String {
        let t = max(0, Int(s.rounded()))
        return String(format: "%d:%02d", t / 60, t % 60)
    }
}
