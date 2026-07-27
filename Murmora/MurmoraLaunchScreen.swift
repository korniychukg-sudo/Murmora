import SwiftUI

struct MurmoraLaunchScreen: View {
    @State private var pulse = false
    @State private var ring = false

    var body: some View {
        ZStack {
            AuroraBackground(tint: Murmora.primary, secondary: Murmora.accent(.water), animated: false)
            VStack(spacing: 22) {
                ZStack {
                    ForEach(0..<3) { i in
                        Circle()
                            .stroke(Murmora.primary.opacity(0.3 - Double(i) * 0.08), lineWidth: 3)
                            .frame(width: 110 + CGFloat(i) * 44)
                            .scaleEffect(ring ? 1.1 : 0.9)
                    }
                    Circle().fill(Murmora.heroGradient)
                        .frame(width: 96, height: 96)
                        .scaleEffect(pulse ? 1.06 : 0.94)
                        .glow(Murmora.primary, radius: 30, opacity: 0.6)
                    MurmoraIcon(glyph: .waveform, size: 46, color: .white)
                }
                Text("Murmora")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundColor(Murmora.ink)
                Text("Tuning the ambience...")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Murmora.subtle)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) { pulse = true }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) { ring = true }
        }
    }
}
