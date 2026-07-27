import SwiftUI

/// A living, animated dusk environment rendered in a single Canvas.
/// Layers appear/intensify based on which sounds are active and their volume.
/// `intensity` scales particle density so the same engine serves a compact
/// stage and a full-screen hero. Respects reduce-motion (static frame).
struct LiveSceneView: View {
    let active: [MurmoraSound]
    let volumes: [String: Double]
    var playing: Bool = true
    var reduceMotion: Bool = false
    var intensity: CGFloat = 1

    // MARK: derived intensities (0…~1+) per visual layer
    private func vol(_ ids: [String]) -> CGFloat {
        var s: CGFloat = 0
        for id in ids where (volumes[id] ?? 0) > 0 { s += CGFloat(volumes[id] ?? 0) }
        return min(1.6, s)
    }
    private var rainI: CGFloat  { vol(["rain", "heavyrain", "rain_tent"]) }
    private var windI: CGFloat  { vol(["wind", "blizzard", "leaves"]) }
    private var snowI: CGFloat  { vol(["blizzard"]) }
    private var waveI: CGFloat  { vol(["ocean"]) }
    private var emberI: CGFloat { vol(["campfire"]) }
    private var fireflyI: CGFloat { vol(["crickets", "owl", "frogs", "wolves"]) }
    private var birdI: CGFloat  { vol(["birds", "cicadas"]) }
    private var auraI: CGFloat  { vol(["bowl", "piano", "omdrone", "whitenoise", "brownnoise", "pinknoise", "chimes", "heartbeat", "drips", "stream"]) }
    private var lightning: Bool { (volumes["thunder"] ?? 0) > 0 }
    private var daytime: Bool   { (volumes["birds"] ?? 0) > 0 || (volumes["cicadas"] ?? 0) > 0 }

    private var dominant: SoundCat {
        var totals: [SoundCat: Double] = [:]
        for s in active { totals[s.cat, default: 0] += volumes[s.id] ?? 0 }
        return totals.max { $0.value < $1.value }?.key ?? .tones
    }

    var body: some View {
        let tint = Murmora.accent(dominant)
        let deep = Murmora.accentDeep(dominant)
        TimelineView(.animation(minimumInterval: 1.0/30.0, paused: !playing || reduceMotion)) { tl in
            Canvas { ctx, size in
                let t = reduceMotion ? 1000.0 : tl.date.timeIntervalSinceReferenceDate
                draw(&ctx, size: size, t: t, tint: tint, deep: deep)
            }
        }
    }

    // MARK: main draw
    private func draw(_ ctx: inout GraphicsContext, size: CGSize, t: TimeInterval,
                      tint: Color, deep: Color) {
        let W = size.width, H = size.height
        let I = intensity

        // 1. Sky gradient
        let skyTop = daytime ? Color(red: 0.16, green: 0.20, blue: 0.30) : Murmora.bgDeep
        let skyBot = deep.opacity(daytime ? 0.55 : 0.40)
        ctx.fill(Path(CGRect(x: 0, y: 0, width: W, height: H)),
                 with: .linearGradient(Gradient(colors: [skyTop, Murmora.bg, skyBot]),
                                       startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 0, y: H)))

        // 2. Atmosphere bloom
        ctx.fill(Path(ellipseIn: CGRect(x: W*0.2, y: H*0.35, width: W*0.6, height: H*0.6)),
                 with: .radialGradient(Gradient(colors: [tint.opacity(0.22), .clear]),
                                       center: CGPoint(x: W*0.5, y: H*0.62), startRadius: 0, endRadius: W*0.5))

        // 3. Moon / sun (drifts slightly)
        let mx = W*0.76 + CGFloat(sin(t*0.02)) * 10
        let my = H*0.26 + CGFloat(cos(t*0.017)) * 6
        let moonColor: Color = daytime ? Color(red: 1.0, green: 0.86, blue: 0.5) : Color(red: 0.97, green: 0.97, blue: 0.88)
        ctx.fill(Path(ellipseIn: CGRect(x: mx-70, y: my-70, width: 140, height: 140)),
                 with: .radialGradient(Gradient(colors: [moonColor.opacity(0.5), .clear]),
                                       center: CGPoint(x: mx, y: my), startRadius: 0, endRadius: 90))
        ctx.fill(Path(ellipseIn: CGRect(x: mx-34, y: my-34, width: 68, height: 68)), with: .color(moonColor))

        // 4. Stars (twinkle)
        var rs = SeededRNG(seed: 42)
        let starCount = Int(46 * I)
        for _ in 0..<starCount {
            let x = CGFloat(rs.next()) * W
            let y = CGFloat(rs.next()) * H * 0.6
            let base = CGFloat(rs.next())
            let tw = reduceMotion ? 0.6 : (0.35 + 0.65 * (0.5 + 0.5 * sin(t * (0.6 + base) + base * 6)))
            let r = 0.6 + base * 1.7
            ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)),
                     with: .color(.white.opacity(0.12 + 0.5 * Double(tw))))
        }

        // 5. Clouds (drift with wind)
        if !daytime || windI > 0 {
            let speed = 6.0 + Double(windI) * 22.0
            for k in 0..<2 {
                let baseX = (t * speed + Double(k) * 520).truncatingRemainder(dividingBy: Double(W) + 340) - 170
                let cy = H * (0.16 + CGFloat(k) * 0.12)
                cloud(&ctx, x: CGFloat(baseX), y: cy, w: 230, h: 60, color: .white.opacity(0.05 + 0.05 * Double(min(1, windI + 0.4))))
            }
        }

        // 6. Aura ripples (tones / calm sounds)
        if auraI > 0.01 {
            for k in 0..<3 {
                let phase = (t * 0.25 + Double(k) * 0.4).truncatingRemainder(dividingBy: 1.2) / 1.2
                let rr = CGFloat(phase) * W * 0.55
                let a = (1 - phase) * 0.28 * Double(min(1, auraI))
                var p = Path(); p.addEllipse(in: CGRect(x: W/2 - rr, y: H*0.62 - rr, width: rr*2, height: rr*2))
                ctx.stroke(p, with: .color(tint.opacity(a)), lineWidth: 2)
            }
        }

        // 7. Waves (ocean) at the base
        if waveI > 0.01 {
            for row in 0..<3 {
                let yBase = H - CGFloat(row) * 16 - 20
                let amp = 10.0 + Double(row) * 4
                let ph = t * (0.8 + Double(row) * 0.2)
                var p = Path()
                p.move(to: CGPoint(x: 0, y: yBase))
                var x: CGFloat = 0
                while x <= W {
                    let y = yBase + CGFloat(sin(Double(x) * 0.02 + ph)) * amp
                    p.addLine(to: CGPoint(x: x, y: y)); x += 12
                }
                p.addLine(to: CGPoint(x: W, y: H)); p.addLine(to: CGPoint(x: 0, y: H)); p.closeSubpath()
                ctx.fill(p, with: .color(Murmora.accent(.water).opacity(0.12 + 0.10 * Double(min(1, waveI)) + Double(row) * 0.04)))
            }
        }

        // 8. Fireflies (night creatures)
        if fireflyI > 0.01 {
            var rf = SeededRNG(seed: 777)
            let n = Int(20 * I * min(1, fireflyI + 0.3))
            for _ in 0..<n {
                let bx = CGFloat(rf.next()) * W
                let by = H * 0.5 + CGFloat(rf.next()) * H * 0.45
                let ph = CGFloat(rf.next())
                let blink = 0.5 + 0.5 * sin(t * 1.6 + Double(ph) * 6.28)
                let x = bx + CGFloat(sin(t * 0.5 + Double(ph) * 6)) * 12
                let y = by + CGFloat(cos(t * 0.4 + Double(ph) * 5)) * 8
                ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 4, height: 4)),
                         with: .color(Color(red: 0.85, green: 0.95, blue: 0.55).opacity(0.15 + 0.7 * blink)))
            }
        }

        // 9. Rain
        if rainI > 0.01 {
            var rr2 = SeededRNG(seed: 303)
            let n = Int(80 * I * min(1.4, rainI))
            let speed = 700.0 + Double(rainI) * 500
            for _ in 0..<n {
                let x = CGFloat(rr2.next()) * W
                let off = CGFloat(rr2.next())
                let len = 12 + CGFloat(rr2.next()) * 16
                let yStart = (t * speed + Double(off) * Double(H)).truncatingRemainder(dividingBy: Double(H) + 40) - 20
                var p = Path()
                p.move(to: CGPoint(x: x, y: CGFloat(yStart)))
                p.addLine(to: CGPoint(x: x - 2, y: CGFloat(yStart) + len))
                ctx.stroke(p, with: .color(.white.opacity(0.18 + 0.12 * Double(min(1, rainI)))), lineWidth: 1.4)
            }
        }

        // 10. Snow (blizzard)
        if snowI > 0.01 {
            var rsn = SeededRNG(seed: 909)
            let n = Int(60 * I * min(1.2, snowI))
            for _ in 0..<n {
                let baseX = CGFloat(rsn.next()) * W
                let off = CGFloat(rsn.next())
                let sp = 60.0 + Double(off) * 90
                let y = (t * sp + Double(off) * Double(H)).truncatingRemainder(dividingBy: Double(H) + 20) - 10
                let x = baseX + CGFloat(sin(t * 0.8 + Double(off) * 6)) * 22
                let r = 2 + off * 2
                ctx.fill(Path(ellipseIn: CGRect(x: x, y: CGFloat(y), width: r, height: r)),
                         with: .color(.white.opacity(0.5)))
            }
        }

        // 11. Embers (campfire) rising from bottom-centre + glow
        if emberI > 0.01 {
            ctx.fill(Path(ellipseIn: CGRect(x: W/2 - 150, y: H - 90, width: 300, height: 180)),
                     with: .radialGradient(Gradient(colors: [Color(red: 1, green: 0.55, blue: 0.2).opacity(0.28 * Double(min(1, emberI)) + 0.05), .clear]),
                                           center: CGPoint(x: W/2, y: H), startRadius: 0, endRadius: 170))
            var re = SeededRNG(seed: 155)
            let n = Int(22 * I * min(1.2, emberI))
            for _ in 0..<n {
                let off = CGFloat(re.next())
                let sway = CGFloat(re.next())
                let life = (t * (0.4 + Double(off) * 0.4) + Double(off)).truncatingRemainder(dividingBy: 1)
                let y = H - CGFloat(life) * H * 0.55
                let x = W/2 + (sway - 0.5) * 150 + CGFloat(sin(t * 2 + Double(off) * 6)) * 14
                let a = (1 - life) * 0.9
                ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 3.5, height: 3.5)),
                         with: .color(Color(red: 1, green: 0.7, blue: 0.3).opacity(a)))
            }
        }

        // 12. Wind motes / leaves
        if windI > 0.01 {
            var rw = SeededRNG(seed: 611)
            let n = Int(26 * I * min(1.2, windI))
            let speed = 60.0 + Double(windI) * 130
            for _ in 0..<n {
                let off = CGFloat(rw.next())
                let y = CGFloat(rw.next()) * H
                let x = (t * speed + Double(off) * Double(W)).truncatingRemainder(dividingBy: Double(W) + 30) - 15
                let drift = CGFloat(sin(t * 1.2 + Double(off) * 6)) * 8
                let r = 1.5 + off * 2
                ctx.fill(Path(ellipseIn: CGRect(x: CGFloat(x), y: y + drift, width: r, height: r)),
                         with: .color(.white.opacity(0.10 + 0.12 * Double(off))))
            }
        }

        // 13. Birds / dawn crossers
        if birdI > 0.01 && !reduceMotion {
            let n = 3
            for k in 0..<n {
                let sp = 30.0 + Double(k) * 8
                let x = (t * sp + Double(k) * 260).truncatingRemainder(dividingBy: Double(W) + 80) - 40
                let y = H * (0.22 + CGFloat(k) * 0.05) + CGFloat(sin(t + Double(k))) * 6
                birdMark(&ctx, x: CGFloat(x), y: y, flap: sin(t * 6 + Double(k)))
            }
        }

        // 14. Lightning flash (thunder) — brief, occasional
        if lightning && !reduceMotion {
            let cycle = t.truncatingRemainder(dividingBy: 9)
            if cycle < 0.18 {
                let a = (cycle < 0.09 ? cycle / 0.09 : (0.18 - cycle) / 0.09) * 0.45
                ctx.fill(Path(CGRect(x: 0, y: 0, width: W, height: H)), with: .color(.white.opacity(a)))
            }
        }

        // 15. Foreground silhouette (depth)
        var rg = SeededRNG(seed: 24)
        var fg = Path()
        fg.move(to: CGPoint(x: 0, y: H))
        fg.addLine(to: CGPoint(x: 0, y: H - 34))
        var fx: CGFloat = 0
        while fx <= W {
            let nx = fx + 70 + CGFloat(rg.next()) * 90
            let peak = H - 30 - CGFloat(rg.next()) * 34
            fg.addQuadCurve(to: CGPoint(x: nx, y: H - 34), control: CGPoint(x: (fx + nx)/2, y: peak))
            fx = nx
        }
        fg.addLine(to: CGPoint(x: W, y: H)); fg.closeSubpath()
        ctx.fill(fg, with: .color(Murmora.bgDeep.opacity(0.92)))
    }

    // MARK: small helpers
    private func cloud(_ ctx: inout GraphicsContext, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, color: Color) {
        ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: w, height: h)), with: .color(color))
        ctx.fill(Path(ellipseIn: CGRect(x: x + w*0.22, y: y - h*0.35, width: w*0.5, height: h*1.3)), with: .color(color))
        ctx.fill(Path(ellipseIn: CGRect(x: x + w*0.5, y: y - h*0.1, width: w*0.44, height: h*1.0)), with: .color(color))
    }
    private func birdMark(_ ctx: inout GraphicsContext, x: CGFloat, y: CGFloat, flap: Double) {
        var p = Path()
        let s: CGFloat = 7
        let lift = CGFloat(flap) * 3
        p.move(to: CGPoint(x: x - s, y: y + lift))
        p.addQuadCurve(to: CGPoint(x: x, y: y), control: CGPoint(x: x - s*0.4, y: y - 3))
        p.addQuadCurve(to: CGPoint(x: x + s, y: y + lift), control: CGPoint(x: x + s*0.4, y: y - 3))
        ctx.stroke(p, with: .color(.white.opacity(0.5)), lineWidth: 2)
    }
}
