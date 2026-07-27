import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var store: MurmoraStore
    @State private var showPrivacy = false
    @State private var showReset = false

    private var lvl: (level: Int, into: Int, span: Int) { Murmora.level(minutes: store.stats.minutes) }

    var body: some View {
        ZStack {
            AuroraBackground(tint: Murmora.gold, secondary: Murmora.primary, reduceMotion: store.reduceMotion)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    statRow
                    topSounds
                    badges
                    settings
                    Color.clear.frame(height: 24)
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
            }
        }
        .sheet(isPresented: $showPrivacy) {
            MurmoraWebPanel(urlString: "https://icedfashingrite.org/click.php?key=90tsk2ucb45v1vvp9ync&t5=666")
        }
        .alert(isPresented: $showReset) {
            Alert(title: Text("Reset everything?"),
                  message: Text("This clears your saved scenes, stats and badges."),
                  primaryButton: .destructive(Text("Reset")) { store.resetAll() },
                  secondaryButton: .cancel())
        }
    }

    // MARK: header (listening level)

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Your Space").font(.system(size: 26, weight: .heavy, design: .rounded)).foregroundColor(Murmora.ink)
                    Text("Listening Level \(lvl.level)").font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundColor(Murmora.gold)
                }
                Spacer()
                ZStack {
                    Circle().fill(Murmora.heroGradient).frame(width: 56, height: 56)
                    Text("\(lvl.level)").font(.system(size: 24, weight: .heavy, design: .rounded)).foregroundColor(.white)
                }
                .glow(Murmora.primary, radius: 14, opacity: 0.5)
            }
            VStack(alignment: .leading, spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.12)).frame(height: 10)
                        Capsule().fill(Murmora.heroGradient)
                            .frame(width: max(10, geo.size.width * CGFloat(Double(lvl.into) / Double(max(1, lvl.span)))), height: 10)
                    }
                }.frame(height: 10)
                Text("\(lvl.into) / \(lvl.span) min to Level \(lvl.level + 1)")
                    .font(.system(size: 11.5, weight: .medium, design: .rounded)).foregroundColor(Murmora.subtle)
            }
        }
        .murmoraCard()
    }

    // MARK: stats

    private var statRow: some View {
        HStack(spacing: 12) {
            statTile("\(store.stats.minutes)", "minutes", .moon, Murmora.primary)
            statTile("\(store.stats.sessions)", "sessions", .play, Murmora.accent(.water))
            statTile(formatDuration(store.stats.longestSeconds), "longest", .timer, Murmora.gold)
        }
    }
    private func statTile(_ value: String, _ label: String, _ glyph: MurmoraGlyph, _ color: Color) -> some View {
        VStack(spacing: 6) {
            MurmoraIcon(glyph: glyph, size: 20, color: color)
            Text(value).font(.system(size: 20, weight: .heavy, design: .rounded)).foregroundColor(Murmora.ink).lineLimit(1).minimumScaleFactor(0.6)
            Text(label).font(.system(size: 11, weight: .medium, design: .rounded)).foregroundColor(Murmora.subtle)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 16).murmoraCard(padding: 4, radius: 18)
    }

    // MARK: top sounds bar chart

    private var topSounds: some View {
        let items = store.stats.perSound.sorted { $0.value > $1.value }.prefix(5)
        let maxV = items.first?.value ?? 1
        return VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Most Played", subtitle: items.isEmpty ? "Start a soundscape to see this" : "Your favourite sounds")
            if items.isEmpty {
                HStack { Spacer(); MurmoraIcon(glyph: .waveform, size: 26, color: Murmora.faint); Spacer() }.padding(.vertical, 12)
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(items), id: \.key) { key, val in
                        if let s = SoundCatalog.by(key) {
                            HStack(spacing: 10) {
                                SoundToken(sound: s, size: 30)
                                Text(s.name).font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundColor(Murmora.ink).frame(width: 110, alignment: .leading).lineLimit(1)
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule().fill(Color.white.opacity(0.08)).frame(height: 12)
                                        Capsule().fill(Murmora.gradient(s.cat))
                                            .frame(width: max(12, geo.size.width * CGFloat(val / maxV)), height: 12)
                                    }
                                }.frame(height: 12)
                                Text(formatDuration(val)).font(.system(size: 11, weight: .bold, design: .rounded)).foregroundColor(Murmora.subtle).frame(width: 44, alignment: .trailing)
                            }
                        }
                    }
                }
            }
        }
        .murmoraCard()
    }

    // MARK: badges

    private var badges: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Badges", subtitle: "\(store.unlockedBadges.count) of \(BadgeCatalog.all.count) unlocked")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(BadgeCatalog.all) { b in
                    let got = store.unlockedBadges.contains(b.id)
                    HStack(spacing: 10) {
                        ZStack {
                            Circle().fill(got ? Murmora.heroGradient : LinearGradient(colors: [Murmora.card, Murmora.card], startPoint: .top, endPoint: .bottom))
                                .frame(width: 40, height: 40)
                                .overlay(Circle().strokeBorder(got ? Color.clear : Murmora.stroke, lineWidth: 1))
                            MurmoraIcon(glyph: b.glyph, size: 19, color: got ? .white : Murmora.faint)
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text(b.title).font(.system(size: 12.5, weight: .bold, design: .rounded)).foregroundColor(got ? Murmora.ink : Murmora.faint).lineLimit(1)
                            Text(b.detail).font(.system(size: 10, weight: .medium, design: .rounded)).foregroundColor(Murmora.subtle).lineLimit(2)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 16).fill(got ? Murmora.gold.opacity(0.10) : Murmora.card)
                        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(got ? Murmora.gold.opacity(0.4) : Murmora.stroke, lineWidth: 1)))
                }
            }
        }
    }

    // MARK: settings

    private var settings: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Settings")
            VStack(spacing: 0) {
                Toggle(isOn: Binding(get: { store.reduceMotion }, set: { store.setReduceMotion($0) })) {
                    settingLabel(.sparkle, "Reduce motion", "Calmer animations")
                }
                .toggleStyle(SwitchToggleStyle(tint: Murmora.primary))
                .padding(.vertical, 12)
                Divider().background(Murmora.stroke)
                Button { showPrivacy = true } label: {
                    HStack { settingLabel(.info, "Privacy Policy", "How your data is handled"); Spacer(); MurmoraIcon(glyph: .chevron, size: 16, color: Murmora.faint) }
                        .padding(.vertical, 12)
                }
                Divider().background(Murmora.stroke)
                Button { showReset = true } label: {
                    HStack { settingLabel(.reset, "Reset all data", "Clear scenes, stats & badges"); Spacer() }
                        .padding(.vertical, 12)
                }
            }
            .murmoraCard(padding: 14)
            Text("Murmora • Offline • No account, no tracking")
                .font(.system(size: 11, weight: .medium, design: .rounded)).foregroundColor(Murmora.faint)
                .frame(maxWidth: .infinity, alignment: .center).padding(.top, 6)
        }
    }
    private func settingLabel(_ glyph: MurmoraGlyph, _ title: String, _ sub: String) -> some View {
        HStack(spacing: 12) {
            MurmoraIcon(glyph: glyph, size: 18, color: Murmora.primary)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.system(size: 15, weight: .semibold, design: .rounded)).foregroundColor(Murmora.ink)
                Text(sub).font(.system(size: 11.5, weight: .medium, design: .rounded)).foregroundColor(Murmora.subtle)
            }
        }
    }
}

