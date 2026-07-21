import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var store: GroveStore
    @State private var showPrivacy = false
    @State private var showReset = false

    private var lvl: (level: Int, into: Int, span: Int) { Grove.level(minutes: store.stats.minutes) }

    var body: some View {
        ZStack {
            AuroraBackground(tint: Grove.gold, secondary: Grove.primary, reduceMotion: store.reduceMotion)
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
        .sheet(isPresented: $showPrivacy) { GrovePrivacySheet() }
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
                    Text("Your Grove").font(.system(size: 26, weight: .heavy, design: .rounded)).foregroundColor(Grove.ink)
                    Text("Listening Level \(lvl.level)").font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundColor(Grove.gold)
                }
                Spacer()
                ZStack {
                    Circle().fill(Grove.heroGradient).frame(width: 56, height: 56)
                    Text("\(lvl.level)").font(.system(size: 24, weight: .heavy, design: .rounded)).foregroundColor(.white)
                }
                .glow(Grove.primary, radius: 14, opacity: 0.5)
            }
            VStack(alignment: .leading, spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.12)).frame(height: 10)
                        Capsule().fill(Grove.heroGradient)
                            .frame(width: max(10, geo.size.width * CGFloat(Double(lvl.into) / Double(max(1, lvl.span)))), height: 10)
                    }
                }.frame(height: 10)
                Text("\(lvl.into) / \(lvl.span) min to Level \(lvl.level + 1)")
                    .font(.system(size: 11.5, weight: .medium, design: .rounded)).foregroundColor(Grove.subtle)
            }
        }
        .groveCard()
    }

    // MARK: stats

    private var statRow: some View {
        HStack(spacing: 12) {
            statTile("\(store.stats.minutes)", "minutes", .moon, Grove.primary)
            statTile("\(store.stats.sessions)", "sessions", .play, Grove.accent(.water))
            statTile(formatDuration(store.stats.longestSeconds), "longest", .timer, Grove.gold)
        }
    }
    private func statTile(_ value: String, _ label: String, _ glyph: GroveGlyph, _ color: Color) -> some View {
        VStack(spacing: 6) {
            GroveIcon(glyph: glyph, size: 20, color: color)
            Text(value).font(.system(size: 20, weight: .heavy, design: .rounded)).foregroundColor(Grove.ink).lineLimit(1).minimumScaleFactor(0.6)
            Text(label).font(.system(size: 11, weight: .medium, design: .rounded)).foregroundColor(Grove.subtle)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 16).groveCard(padding: 4, radius: 18)
    }

    // MARK: top sounds bar chart

    private var topSounds: some View {
        let items = store.stats.perSound.sorted { $0.value > $1.value }.prefix(5)
        let maxV = items.first?.value ?? 1
        return VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Most Played", subtitle: items.isEmpty ? "Start a soundscape to see this" : "Your favourite sounds")
            if items.isEmpty {
                HStack { Spacer(); GroveIcon(glyph: .waveform, size: 26, color: Grove.faint); Spacer() }.padding(.vertical, 12)
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(items), id: \.key) { key, val in
                        if let s = SoundCatalog.by(key) {
                            HStack(spacing: 10) {
                                SoundToken(sound: s, size: 30)
                                Text(s.name).font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundColor(Grove.ink).frame(width: 110, alignment: .leading).lineLimit(1)
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule().fill(Color.white.opacity(0.08)).frame(height: 12)
                                        Capsule().fill(Grove.gradient(s.cat))
                                            .frame(width: max(12, geo.size.width * CGFloat(val / maxV)), height: 12)
                                    }
                                }.frame(height: 12)
                                Text(formatDuration(val)).font(.system(size: 11, weight: .bold, design: .rounded)).foregroundColor(Grove.subtle).frame(width: 44, alignment: .trailing)
                            }
                        }
                    }
                }
            }
        }
        .groveCard()
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
                            Circle().fill(got ? Grove.heroGradient : LinearGradient(colors: [Grove.card, Grove.card], startPoint: .top, endPoint: .bottom))
                                .frame(width: 40, height: 40)
                                .overlay(Circle().strokeBorder(got ? Color.clear : Grove.stroke, lineWidth: 1))
                            GroveIcon(glyph: b.glyph, size: 19, color: got ? .white : Grove.faint)
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text(b.title).font(.system(size: 12.5, weight: .bold, design: .rounded)).foregroundColor(got ? Grove.ink : Grove.faint).lineLimit(1)
                            Text(b.detail).font(.system(size: 10, weight: .medium, design: .rounded)).foregroundColor(Grove.subtle).lineLimit(2)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 16).fill(got ? Grove.gold.opacity(0.10) : Grove.card)
                        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(got ? Grove.gold.opacity(0.4) : Grove.stroke, lineWidth: 1)))
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
                .toggleStyle(SwitchToggleStyle(tint: Grove.primary))
                .padding(.vertical, 12)
                Divider().background(Grove.stroke)
                Button { showPrivacy = true } label: {
                    HStack { settingLabel(.info, "Privacy Policy", "How your data is handled"); Spacer(); GroveIcon(glyph: .chevron, size: 16, color: Grove.faint) }
                        .padding(.vertical, 12)
                }
                Divider().background(Grove.stroke)
                Button { showReset = true } label: {
                    HStack { settingLabel(.reset, "Reset all data", "Clear scenes, stats & badges"); Spacer() }
                        .padding(.vertical, 12)
                }
            }
            .groveCard(padding: 14)
            Text("Sound Grove • Offline • No account, no tracking")
                .font(.system(size: 11, weight: .medium, design: .rounded)).foregroundColor(Grove.faint)
                .frame(maxWidth: .infinity, alignment: .center).padding(.top, 6)
        }
    }
    private func settingLabel(_ glyph: GroveGlyph, _ title: String, _ sub: String) -> some View {
        HStack(spacing: 12) {
            GroveIcon(glyph: glyph, size: 18, color: Grove.primary)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.system(size: 15, weight: .semibold, design: .rounded)).foregroundColor(Grove.ink)
                Text(sub).font(.system(size: 11.5, weight: .medium, design: .rounded)).foregroundColor(Grove.subtle)
            }
        }
    }
}

// MARK: - Privacy sheet (offline text + optional web policy)

struct GrovePrivacySheet: View {
    @Environment(\.presentationMode) var presentation
    var body: some View {
        ZStack {
            Grove.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Text("Privacy Policy").font(.system(size: 20, weight: .heavy, design: .rounded)).foregroundColor(Grove.ink)
                    Spacer()
                    Button { presentation.wrappedValue.dismiss() } label: {
                        ZStack { Circle().fill(Grove.card).frame(width: 34, height: 34); GroveIcon(glyph: .close, size: 15, color: Grove.ink) }
                    }
                }.padding(18)
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        policyBlock("Fully offline", "Sound Grove works entirely on your device. It has no account system and no analytics.")
                        policyBlock("No data collected", "Your saved scenes, listening stats and badges are stored only in local app storage and never leave your phone.")
                        policyBlock("No permissions", "The app does not request access to the microphone, camera, location, contacts or notifications.")
                        policyBlock("No tracking", "There are no third-party trackers or advertising identifiers.")
                        Text("If you delete the app, all locally stored data is removed with it.")
                            .font(.system(size: 13, weight: .medium, design: .rounded)).foregroundColor(Grove.subtle)
                            .padding(.top, 6)
                    }
                    .padding(.horizontal, 20).padding(.bottom, 30)
                }
            }
        }
    }
    private func policyBlock(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(Grove.ink)
            Text(body).font(.system(size: 13.5, weight: .medium, design: .rounded)).foregroundColor(Grove.subtle).fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .groveCard(padding: 14, radius: 16)
    }
}
