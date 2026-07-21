import SwiftUI

/// Loads bundled PNGs from the copied "Art" folder reference, cached in memory.
enum GroveArtLoader {
    private static var cache: [String: UIImage] = [:]
    static func image(_ name: String) -> UIImage? {
        if let hit = cache[name] { return hit }
        if let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "Art"),
           let img = UIImage(contentsOfFile: url.path) {
            cache[name] = img; return img
        }
        if let img = UIImage(named: name) { cache[name] = img; return img }
        return nil
    }
}

/// Round emblem for a sound. Uses generated token art, falls back to a
/// gradient disc + glyph if the file is missing.
struct SoundToken: View {
    let sound: GroveSound
    var size: CGFloat = 64

    var body: some View {
        ZStack {
            if let ui = GroveArtLoader.image(sound.token) {
                Image(uiImage: ui).resizable().scaledToFill()
            } else {
                Circle().fill(Grove.gradient(sound.cat))
                GroveIcon(glyph: .waveform, size: size * 0.42, color: .white)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

/// Wide illustration loader (banners / scene covers) with graceful fallback.
struct GroveImage: View {
    let name: String
    var fallbackCat: SoundCat = .tones
    var body: some View {
        GeometryReader { geo in
            if let ui = GroveArtLoader.image(name) {
                Image(uiImage: ui).resizable().scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height).clipped()
            } else {
                Grove.gradient(fallbackCat)
            }
        }
    }
}

/// Multiply-blended paper/star grain overlay.
struct GrainOverlay: View {
    var opacity: Double = 0.5
    var body: some View {
        if let ui = GroveArtLoader.image("grain") {
            Image(uiImage: ui).resizable(resizingMode: .tile)
                .opacity(opacity).blendMode(.screen).allowsHitTesting(false)
        }
    }
}
