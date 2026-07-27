import SwiftUI

/// Custom vector glyphs (no SF Symbols, no emoji). Stroked or filled paths.
enum MurmoraGlyph {
    case studio, scenes, sleep, profile
    case play, pause, plus, close, trash, bookmark, bookmarkFill
    case timer, gear, chevron, chevronDown, reset
    case layers, compass, grid, moon, sparkle, target, calendar
    case sliders, waveform, heart, leaf, check, share, info
}

struct MurmoraIcon: View {
    let glyph: MurmoraGlyph
    var size: CGFloat = 24
    var color: Color = Murmora.ink
    var weight: CGFloat = 2.2

    var body: some View {
        Canvas { ctx, s in
            let lw = weight * (size / 24)
            let (fill, stroke, useFill) = Self.build(glyph, in: s)
            if useFill { ctx.fill(fill, with: .color(color)) }
            ctx.stroke(stroke, with: .color(color),
                       style: StrokeStyle(lineWidth: lw, lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
    }

    static func build(_ glyph: MurmoraGlyph, in s: CGSize) -> (Path, Path, Bool) {
        let w = s.width, h = s.height
        let lw = 2.2 * (w / 24)
        func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x*w, y: y*h) }
        var stroke = Path()
        var fill = Path()
        var useFill = false

        switch glyph {
            case .studio, .sliders:
                // three mixer faders
                for (i, fx) in [0.24, 0.5, 0.76].enumerated() {
                    stroke.move(to: P(CGFloat(fx), 0.15)); stroke.addLine(to: P(CGFloat(fx), 0.85))
                    let ky: CGFloat = [0.4, 0.62, 0.32][i]
                    fill.addEllipse(in: CGRect(x: CGFloat(fx)*w - lw*1.6, y: ky*h - lw*1.6, width: lw*3.2, height: lw*3.2))
                }
                useFill = true
            case .scenes:
                // stacked cards
                stroke.addRoundedRect(in: CGRect(x: 0.22*w, y: 0.14*h, width: 0.56*w, height: 0.34*h), cornerSize: CGSize(width: lw*2, height: lw*2))
                stroke.addRoundedRect(in: CGRect(x: 0.14*w, y: 0.42*h, width: 0.72*w, height: 0.44*h), cornerSize: CGSize(width: lw*2, height: lw*2))
            case .sleep, .moon:
                var m = Path()
                m.addArc(center: P(0.5,0.5), radius: 0.36*w, startAngle: .degrees(-60), endAngle: .degrees(150), clockwise: false)
                m.addArc(center: P(0.66,0.42), radius: 0.32*w, startAngle: .degrees(150), endAngle: .degrees(-60), clockwise: true)
                fill = m; useFill = true
            case .profile:
                fill.addEllipse(in: CGRect(x: 0.34*w, y: 0.14*h, width: 0.32*w, height: 0.32*h))
                var body = Path()
                body.addArc(center: P(0.5, 0.92), radius: 0.30*w, startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
                fill.addPath(body); useFill = true
            case .play:
                fill.move(to: P(0.28,0.18)); fill.addLine(to: P(0.82,0.5)); fill.addLine(to: P(0.28,0.82)); fill.closeSubpath()
                useFill = true
            case .pause:
                fill.addRoundedRect(in: CGRect(x: 0.28*w, y: 0.2*h, width: 0.15*w, height: 0.6*h), cornerSize: CGSize(width: lw, height: lw))
                fill.addRoundedRect(in: CGRect(x: 0.57*w, y: 0.2*h, width: 0.15*w, height: 0.6*h), cornerSize: CGSize(width: lw, height: lw))
                useFill = true
            case .plus:
                stroke.move(to: P(0.5,0.2)); stroke.addLine(to: P(0.5,0.8))
                stroke.move(to: P(0.2,0.5)); stroke.addLine(to: P(0.8,0.5))
            case .close:
                stroke.move(to: P(0.24,0.24)); stroke.addLine(to: P(0.76,0.76))
                stroke.move(to: P(0.76,0.24)); stroke.addLine(to: P(0.24,0.76))
            case .check:
                stroke.move(to: P(0.22,0.52)); stroke.addLine(to: P(0.43,0.73)); stroke.addLine(to: P(0.8,0.28))
            case .trash:
                stroke.move(to: P(0.22,0.28)); stroke.addLine(to: P(0.78,0.28))
                stroke.addRoundedRect(in: CGRect(x: 0.28*w, y: 0.28*h, width: 0.44*w, height: 0.56*h), cornerSize: CGSize(width: lw, height: lw))
                stroke.move(to: P(0.4,0.18)); stroke.addLine(to: P(0.6,0.18))
                stroke.move(to: P(0.42,0.4)); stroke.addLine(to: P(0.42,0.72))
                stroke.move(to: P(0.58,0.4)); stroke.addLine(to: P(0.58,0.72))
            case .bookmark:
                stroke.move(to: P(0.3,0.16)); stroke.addLine(to: P(0.7,0.16)); stroke.addLine(to: P(0.7,0.84))
                stroke.addLine(to: P(0.5,0.66)); stroke.addLine(to: P(0.3,0.84)); stroke.closeSubpath()
            case .bookmarkFill:
                fill.move(to: P(0.3,0.16)); fill.addLine(to: P(0.7,0.16)); fill.addLine(to: P(0.7,0.84))
                fill.addLine(to: P(0.5,0.66)); fill.addLine(to: P(0.3,0.84)); fill.closeSubpath(); useFill = true
            case .timer:
                stroke.addEllipse(in: CGRect(x: 0.2*w, y: 0.26*h, width: 0.6*w, height: 0.6*h))
                stroke.move(to: P(0.5,0.56)); stroke.addLine(to: P(0.5,0.4))
                stroke.move(to: P(0.4,0.14)); stroke.addLine(to: P(0.6,0.14))
            case .gear:
                stroke.addEllipse(in: CGRect(x: 0.36*w, y: 0.36*h, width: 0.28*w, height: 0.28*h))
                let gcx = 0.5*w, gcy = 0.5*h
                for i in 0..<8 {
                    let a = CGFloat(i) * (.pi/4)
                    stroke.move(to: CGPoint(x: gcx + cos(a)*0.30*w, y: gcy + sin(a)*0.30*h))
                    stroke.addLine(to: CGPoint(x: gcx + cos(a)*0.44*w, y: gcy + sin(a)*0.44*h))
                }
            case .chevron:
                stroke.move(to: P(0.4,0.24)); stroke.addLine(to: P(0.64,0.5)); stroke.addLine(to: P(0.4,0.76))
            case .chevronDown:
                stroke.move(to: P(0.26,0.4)); stroke.addLine(to: P(0.5,0.64)); stroke.addLine(to: P(0.74,0.4))
            case .reset:
                stroke.addArc(center: P(0.5,0.5), radius: 0.3*w, startAngle: .degrees(60), endAngle: .degrees(-200), clockwise: true)
                stroke.move(to: P(0.5,0.12)); stroke.addLine(to: P(0.28,0.2)); // arrow head
                stroke.move(to: P(0.5,0.12)); stroke.addLine(to: P(0.44,0.32))
            case .layers:
                fill.move(to: P(0.5,0.16)); fill.addLine(to: P(0.86,0.36)); fill.addLine(to: P(0.5,0.56)); fill.addLine(to: P(0.14,0.36)); fill.closeSubpath()
                stroke.move(to: P(0.14,0.52)); stroke.addLine(to: P(0.5,0.72)); stroke.addLine(to: P(0.86,0.52))
                stroke.move(to: P(0.14,0.66)); stroke.addLine(to: P(0.5,0.86)); stroke.addLine(to: P(0.86,0.66))
                useFill = true
            case .compass:
                stroke.addEllipse(in: CGRect(x: 0.16*w, y: 0.16*h, width: 0.68*w, height: 0.68*h))
                fill.move(to: P(0.5,0.28)); fill.addLine(to: P(0.6,0.5)); fill.addLine(to: P(0.5,0.72)); fill.addLine(to: P(0.4,0.5)); fill.closeSubpath()
                useFill = true
            case .grid:
                for r in 0..<2 { for cc in 0..<2 {
                    let x = 0.22 + Double(cc)*0.34, y = 0.22 + Double(r)*0.34
                    stroke.addRoundedRect(in: CGRect(x: CGFloat(x)*w, y: CGFloat(y)*h, width: 0.22*w, height: 0.22*h), cornerSize: CGSize(width: lw, height: lw))
                }}
            case .sparkle:
                let cx = 0.5*w, cy = 0.5*h
                for k in 0..<4 {
                    let a = CGFloat(k) * (.pi / 2)
                    let inner: CGFloat = 0.16, outer: CGFloat = 0.36
                    let p1 = CGPoint(x: cx + cos(a - 0.35) * inner * w, y: cy + sin(a - 0.35) * inner * h)
                    let p2 = CGPoint(x: cx + cos(a) * outer * w, y: cy + sin(a) * outer * h)
                    let p3 = CGPoint(x: cx + cos(a + 0.35) * inner * w, y: cy + sin(a + 0.35) * inner * h)
                    fill.move(to: CGPoint(x: cx, y: cy))
                    fill.addLine(to: p1); fill.addLine(to: p2); fill.addLine(to: p3)
                    fill.closeSubpath()
                }
                useFill = true
            case .target:
                stroke.addEllipse(in: CGRect(x: 0.16*w, y: 0.16*h, width: 0.68*w, height: 0.68*h))
                stroke.addEllipse(in: CGRect(x: 0.34*w, y: 0.34*h, width: 0.32*w, height: 0.32*h))
                fill.addEllipse(in: CGRect(x: 0.44*w, y: 0.44*h, width: 0.12*w, height: 0.12*h)); useFill = true
            case .calendar:
                stroke.addRoundedRect(in: CGRect(x: 0.18*w, y: 0.22*h, width: 0.64*w, height: 0.6*h), cornerSize: CGSize(width: lw*1.6, height: lw*1.6))
                stroke.move(to: P(0.18,0.38)); stroke.addLine(to: P(0.82,0.38))
                stroke.move(to: P(0.34,0.14)); stroke.addLine(to: P(0.34,0.28))
                stroke.move(to: P(0.66,0.14)); stroke.addLine(to: P(0.66,0.28))
            case .waveform:
                for (i, hgt) in [0.3, 0.6, 0.85, 0.5, 0.7, 0.35].enumerated() {
                    let x = 0.16 + Double(i)*0.14
                    stroke.move(to: P(CGFloat(x), CGFloat(0.5 - hgt/2)))
                    stroke.addLine(to: P(CGFloat(x), CGFloat(0.5 + hgt/2)))
                }
            case .heart:
                fill.move(to: P(0.5,0.78))
                fill.addCurve(to: P(0.16,0.38), control1: P(0.28,0.62), control2: P(0.16,0.5))
                fill.addArc(center: P(0.33,0.34), radius: 0.17*w, startAngle: .degrees(160), endAngle: .degrees(-20), clockwise: false)
                fill.addArc(center: P(0.67,0.34), radius: 0.17*w, startAngle: .degrees(200), endAngle: .degrees(20), clockwise: false)
                fill.addCurve(to: P(0.5,0.78), control1: P(0.84,0.5), control2: P(0.72,0.62))
                fill.closeSubpath(); useFill = true
            case .leaf:
                fill.move(to: P(0.5,0.14))
                fill.addQuadCurve(to: P(0.5,0.86), control: P(0.86,0.5))
                fill.addQuadCurve(to: P(0.5,0.14), control: P(0.14,0.5))
                useFill = true
            case .share:
                fill.addEllipse(in: CGRect(x: 0.66*w, y: 0.14*h, width: 0.2*w, height: 0.2*h))
                fill.addEllipse(in: CGRect(x: 0.14*w, y: 0.4*h, width: 0.2*w, height: 0.2*h))
                fill.addEllipse(in: CGRect(x: 0.66*w, y: 0.66*h, width: 0.2*w, height: 0.2*h))
                stroke.move(to: P(0.34,0.46)); stroke.addLine(to: P(0.66,0.26))
                stroke.move(to: P(0.34,0.54)); stroke.addLine(to: P(0.66,0.74))
                useFill = true
            case .info:
                stroke.addEllipse(in: CGRect(x: 0.18*w, y: 0.18*h, width: 0.64*w, height: 0.64*h))
                stroke.move(to: P(0.5,0.46)); stroke.addLine(to: P(0.5,0.68))
                fill.addEllipse(in: CGRect(x: 0.46*w, y: 0.3*h, width: 0.08*w, height: 0.08*h)); useFill = true
            }
        _ = lw
        return (fill, stroke, useFill)
    }
}
