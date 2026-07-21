import SwiftUI

struct OnboardingView: View {
    let onDone: () -> Void
    @State private var page = 0

    private let pages: [(String, String, String)] = [
        ("onb_1", "Build your soundscape", "Layer rain, fire, waves and more into a living blend that's all your own."),
        ("onb_2", "Mix and save scenes", "Tune each sound's volume, then keep your favourite blends for later."),
        ("onb_3", "Drift off or focus", "Set a sleep timer to fade out gently, or a focus session to stay in the zone."),
    ]

    var body: some View {
        ZStack {
            AuroraBackground(tint: Grove.primary, secondary: Grove.accent(.water), animated: true)
            VStack(spacing: 0) {
                Spacer()
                TabView(selection: $page) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        VStack(spacing: 26) {
                            ZStack {
                                Circle().fill(Grove.primary.opacity(0.18)).frame(width: 250, height: 250).blur(radius: 20)
                                if let ui = GroveArtLoader.image(pages[i].0) {
                                    Image(uiImage: ui).resizable().scaledToFit()
                                        .frame(width: 240, height: 240)
                                        .clipShape(Circle())
                                        .overlay(Circle().strokeBorder(Grove.stroke, lineWidth: 1))
                                        .glow(Grove.primary, radius: 24, opacity: 0.4)
                                } else {
                                    Circle().fill(Grove.heroGradient).frame(width: 240, height: 240)
                                }
                            }
                            VStack(spacing: 12) {
                                Text(pages[i].1).font(.system(size: 26, weight: .heavy, design: .rounded))
                                    .foregroundColor(Grove.ink).multilineTextAlignment(.center)
                                Text(pages[i].2).font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundColor(Grove.subtle).multilineTextAlignment(.center)
                                    .padding(.horizontal, 36)
                            }
                            .tag(i)
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                Spacer()
                // dots
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Capsule().fill(i == page ? Grove.primary : Grove.faint.opacity(0.4))
                            .frame(width: i == page ? 22 : 8, height: 8)
                            .animation(.easeInOut, value: page)
                    }
                }
                .padding(.bottom, 26)
                Button {
                    Haptic.soft()
                    if page < pages.count - 1 { withAnimation { page += 1 } } else { onDone() }
                } label: {
                    Text(page < pages.count - 1 ? "Next" : "Enter the Grove")
                        .font(.system(size: 17, weight: .bold, design: .rounded)).foregroundColor(Grove.bgDeep)
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(Capsule().fill(Grove.gold)).padding(.horizontal, 30)
                }
                .buttonStyle(PressableStyle())
                Button("Skip") { onDone() }
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(Grove.subtle).padding(.top, 14).padding(.bottom, 30)
            }
        }
    }
}
