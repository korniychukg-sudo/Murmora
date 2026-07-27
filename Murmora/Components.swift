import SwiftUI

// MARK: - Animated dusk background (aurora blobs + drifting stars)

struct AuroraBackground: View {
    var tint: Color = Murmora.primary
    var secondary: Color = Murmora.accent(.water)
    var animated: Bool = true
    var reduceMotion: Bool = false
    @State private var t: CGFloat = 0

    var body: some View {
        ZStack {
            Murmora.bgGradient
            GeometryReader { geo in
                let w = geo.size.width, h = geo.size.height
                ZStack {
                    blob(tint.opacity(0.32), size: w*0.9)
                        .offset(x: -w*0.25 + sin(t) * w*0.10, y: -h*0.18 + cos(t*0.8) * h*0.06)
                    blob(secondary.opacity(0.26), size: w*0.85)
                        .offset(x: w*0.28 + cos(t*0.9) * w*0.10, y: h*0.10 + sin(t*1.1) * h*0.06)
                    blob(Murmora.gold.opacity(0.14), size: w*0.6)
                        .offset(x: w*0.05 + sin(t*1.3) * w*0.08, y: h*0.34 + cos(t) * h*0.05)
                }
                .blur(radius: 42)
            }
            StarLayer(count: 46, reduceMotion: reduceMotion)
        }
        .ignoresSafeArea()
        .onAppear {
            guard animated && !reduceMotion else { return }
            withAnimation(.linear(duration: 26).repeatForever(autoreverses: true)) { t = .pi * 2 }
        }
    }

    private func blob(_ c: Color, size: CGFloat) -> some View {
        Circle().fill(c).frame(width: size, height: size)
    }
}

struct StarLayer: View {
    let count: Int
    var reduceMotion: Bool = false
    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 3 : 0.08, paused: false)) { tl in
            Canvas { ctx, size in
                let time = tl.date.timeIntervalSinceReferenceDate
                var rng = SeededRNG(seed: 20240717)
                for _ in 0..<count {
                    let x = CGFloat(rng.next()) * size.width
                    let y = CGFloat(rng.next()) * size.height * 0.9
                    let base = CGFloat(rng.next())
                    let tw = reduceMotion ? 0.6 : (0.4 + 0.6 * (0.5 + 0.5 * sin(time * (0.6 + base) + base * 6)))
                    let r = 0.6 + base * 1.8
                    ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)),
                             with: .color(.white.opacity(0.18 + 0.5 * Double(tw))))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

struct SeededRNG {
    var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 1 : seed }
    mutating func next() -> Double {
        state ^= state << 13; state ^= state >> 7; state ^= state << 17
        return Double(state >> 11) * (1.0 / 9007199254740992.0)
    }
}

// MARK: - Equalizer bars (animate while playing)

struct EqualizerBars: View {
    var active: Bool
    var color: Color
    var bars: Int = 4
    var reduceMotion: Bool = false
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.09, paused: !active || reduceMotion)) { tl in
            let time = tl.date.timeIntervalSinceReferenceDate
            HStack(alignment: .bottom, spacing: 3) {
                ForEach(0..<bars, id: \.self) { i in
                    let phase = Double(i) * 1.3
                    let h: CGFloat = active
                        ? CGFloat(0.35 + 0.65 * (0.5 + 0.5 * sin(time * 6 + phase)))
                        : 0.3
                    Capsule().fill(color)
                        .frame(width: 3, height: 16 * h)
                }
            }
            .frame(height: 16, alignment: .bottom)
        }
    }
}

// MARK: - Floating living token (used on the Studio stage)

struct FloatingToken: View {
    let sound: MurmoraSound
    let volume: Double
    let playing: Bool
    var reduceMotion: Bool = false
    var index: Int = 0
    @State private var bob = false

    var body: some View {
        let scale = 0.8 + 0.35 * volume
        ZStack {
            Circle()
                .fill(Murmora.accent(sound.cat).opacity(0.28 + 0.4 * volume))
                .frame(width: 92, height: 92)
                .blur(radius: 10)
                .scaleEffect(playing ? (bob ? 1.12 : 0.96) : 1.0)
            SoundToken(sound: sound, size: 62)
                .glow(Murmora.accent(sound.cat), radius: 12, opacity: 0.6 * volume + 0.2)
        }
        .scaleEffect(scale)
        .offset(y: bob && !reduceMotion ? -8 : 6)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.2 + Double(index % 4) * 0.35)
                            .repeatForever(autoreverses: true)) { bob = true }
        }
    }
}

// MARK: - Volume slider (custom, no system controls)

struct VolumeSlider: View {
    @Binding var value: Double
    var tint: Color
    var height: CGFloat = 10

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.12)).frame(height: height)
                Capsule().fill(LinearGradient(colors: [tint.opacity(0.8), tint],
                                              startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(height, CGFloat(value) * w), height: height)
                Circle().fill(Color.white)
                    .frame(width: height + 8, height: height + 8)
                    .shadow(color: tint.opacity(0.6), radius: 5)
                    .offset(x: max(0, min(w - height - 8, CGFloat(value) * w - (height+8)/2)))
            }
            .frame(height: 28)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { g in
                value = max(0, min(1, Double(g.location.x / w)))
            })
        }
        .frame(height: 28)
    }
}

// MARK: - Circular progress ring

struct ProgressRing: View {
    var progress: Double
    var tint: Color
    var line: CGFloat = 10
    var body: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.10), lineWidth: line)
            Circle().trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(LinearGradient(colors: [tint, tint.opacity(0.6)], startPoint: .top, endPoint: .bottom),
                        style: StrokeStyle(lineWidth: line, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

// MARK: - Pill / chip

struct MurmoraPill: View {
    let text: String
    var color: Color = Murmora.primary
    var filled: Bool = false
    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundColor(filled ? Murmora.bgDeep : color)
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(
                Capsule().fill(filled ? color : color.opacity(0.16))
            )
    }
}

// MARK: - Section header

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.system(size: 20, weight: .heavy, design: .rounded)).foregroundColor(Murmora.ink)
            if let s = subtitle {
                Text(s).font(.system(size: 13, weight: .medium, design: .rounded)).foregroundColor(Murmora.subtle)
            }
        }
    }
}

// MARK: - Confetti / sparkle burst

struct SparkleBurst: View {
    var trigger: Bool
    var color: Color = Murmora.gold
    @State private var animate = false
    private let seeds = (0..<18).map { _ in (Double.random(in: -1...1), Double.random(in: -1...1)) }

    var body: some View {
        ZStack {
            ForEach(0..<seeds.count, id: \.self) { i in
                let (dx, dy) = seeds[i]
                Circle()
                    .fill(i % 2 == 0 ? color : Murmora.primary)
                    .frame(width: 8, height: 8)
                    .scaleEffect(animate ? 0.2 : 1)
                    .offset(x: animate ? CGFloat(dx) * 150 : 0,
                            y: animate ? CGFloat(dy) * 150 : 0)
                    .opacity(animate ? 0 : 1)
            }
        }
        .onChange(of: trigger) { _ in
            animate = false
            withAnimation(.easeOut(duration: 0.9)) { animate = true }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Round icon button

struct RoundIconButton: View {
    let glyph: MurmoraGlyph
    var color: Color = Murmora.ink
    var bg: Color = Murmora.card
    var size: CGFloat = 44
    var iconSize: CGFloat = 20
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().fill(bg)
                    .overlay(Circle().strokeBorder(Murmora.stroke, lineWidth: 1))
                MurmoraIcon(glyph: glyph, size: iconSize, color: color)
            }
            .frame(width: size, height: size)
        }
        .buttonStyle(PressableStyle())
    }
}

struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Haptics

enum Haptic {
    static func tap() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func soft() { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
}

// MARK: - Time formatting

func formatMinSec(_ seconds: TimeInterval) -> String {
    let s = Int(seconds)
    let m = s / 60, r = s % 60
    return String(format: "%d:%02d", m, r)
}
func formatDuration(_ seconds: Double) -> String {
    let total = Int(seconds)
    let h = total / 3600, m = (total % 3600) / 60
    if h > 0 { return "\(h)h \(m)m" }
    return "\(m)m"
}
