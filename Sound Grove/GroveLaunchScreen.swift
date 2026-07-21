import SwiftUI

struct GroveLaunchScreen: View {
    @State private var pulse = false
    @State private var ring = false

    var body: some View {
        ZStack {
            AuroraBackground(tint: Grove.primary, secondary: Grove.accent(.water), animated: false)
            VStack(spacing: 22) {
                ZStack {
                    ForEach(0..<3) { i in
                        Circle()
                            .stroke(Grove.primary.opacity(0.3 - Double(i) * 0.08), lineWidth: 3)
                            .frame(width: 110 + CGFloat(i) * 44)
                            .scaleEffect(ring ? 1.1 : 0.9)
                    }
                    Circle().fill(Grove.heroGradient)
                        .frame(width: 96, height: 96)
                        .scaleEffect(pulse ? 1.06 : 0.94)
                        .glow(Grove.primary, radius: 30, opacity: 0.6)
                    GroveIcon(glyph: .waveform, size: 46, color: .white)
                }
                Text("Sound Grove")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundColor(Grove.ink)
                Text("Tuning the ambience...")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Grove.subtle)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) { pulse = true }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) { ring = true }
        }
    }
}
