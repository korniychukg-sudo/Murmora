import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: MurmoraStore
    @State private var tab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            Murmora.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                Group {
                    switch tab {
                    case 0: StudioView()
                    case 1: ScenesView()
                    case 2: SleepView()
                    default: ProfileView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                tabBar
            }

            // Badge unlocked toast
            if let b = store.justUnlocked {
                BadgeToast(badge: b)
                    .padding(.bottom, 92)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        Haptic.success()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
                            withAnimation(.easeInOut) { store.justUnlocked = nil }
                        }
                    }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: store.justUnlocked?.id)
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(0, "Studio", .studio)
            tabButton(1, "Scenes", .scenes)
            tabButton(2, "Sleep", .sleep)
            tabButton(3, "You", .profile)
        }
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(
            ZStack {
                Murmora.bgDeep.opacity(0.96)
                Rectangle().fill(Color.white.opacity(0.05)).frame(height: 1).frame(maxHeight: .infinity, alignment: .top)
            }
            .ignoresSafeArea(edges: .bottom)
        )
    }

    private func tabButton(_ i: Int, _ label: String, _ glyph: MurmoraGlyph) -> some View {
        let selected = tab == i
        return Button {
            Haptic.tap(); withAnimation(.easeInOut(duration: 0.2)) { tab = i }
        } label: {
            VStack(spacing: 4) {
                MurmoraIcon(glyph: glyph, size: 24,
                          color: selected ? Murmora.primary : Murmora.faint,
                          weight: selected ? 2.6 : 2.0)
                    .frame(height: 26)
                Text(label)
                    .font(.system(size: 11, weight: selected ? .bold : .medium, design: .rounded))
                    .foregroundColor(selected ? Murmora.primary : Murmora.faint)
                // playing indicator dot under Studio
                if i == 0 && store.isPlaying {
                    Circle().fill(Murmora.gold).frame(width: 5, height: 5)
                } else {
                    Circle().fill(Color.clear).frame(width: 5, height: 5)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PressableStyle())
    }
}

struct BadgeToast: View {
    let badge: Badge
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Murmora.heroGradient).frame(width: 44, height: 44)
                MurmoraIcon(glyph: badge.glyph, size: 22, color: .white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Badge unlocked").font(.system(size: 11, weight: .bold, design: .rounded)).foregroundColor(Murmora.gold)
                Text(badge.title).font(.system(size: 16, weight: .heavy, design: .rounded)).foregroundColor(Murmora.ink)
            }
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Murmora.bgDeep)
                .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Murmora.gold.opacity(0.5), lineWidth: 1))
                .shadow(color: .black.opacity(0.4), radius: 16, y: 8)
        )
        .padding(.horizontal, 24)
    }
}
