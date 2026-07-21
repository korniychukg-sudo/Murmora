// Sound Grove — illustrated art generator (Core Graphics).
// swiftc -O artgen.swift -o artgen && ./artgen <artDir> <iconPath>
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let rgb = CGColorSpaceCreateDeviceRGB()

struct RNG { var s: UInt64; init(_ x: UInt64){ s = x==0 ? 88172645463325252 : x }
    mutating func n()->UInt64{ s ^= s<<13; s ^= s>>7; s ^= s<<17; return s }
    mutating func d()->Double{ Double(n() >> 11) * (1.0/9007199254740992.0) }
    mutating func r(_ a:Double,_ b:Double)->Double{ a+(b-a)*d() } }

func col(_ r:Double,_ g:Double,_ b:Double,_ a:Double = 1) -> CGColor {
    CGColor(colorSpace: rgb, components: [CGFloat(r),CGFloat(g),CGFloat(b),CGFloat(a)])! }

func ctx(_ w:Int,_ h:Int, opaque:Bool = false) -> CGContext {
    let info = opaque ? CGImageAlphaInfo.noneSkipLast.rawValue : CGImageAlphaInfo.premultipliedLast.rawValue
    let c = CGContext(data:nil, width:w, height:h, bitsPerComponent:8, bytesPerRow:0,
                      space:rgb, bitmapInfo:info)!
    c.interpolationQuality = .high
    c.setAllowsAntialiasing(true)
    return c
}

func save(_ c: CGContext, _ path: String) {
    guard let img = c.makeImage() else { return }
    let url = URL(fileURLWithPath: path) as CFURL
    guard let dest = CGImageDestinationCreateWithURL(url, UTType.png.identifier as CFString, 1, nil) else { return }
    CGImageDestinationAddImage(dest, img, nil)
    CGImageDestinationFinalize(dest)
}

func radialFill(_ c: CGContext, rect: CGRect, inner: CGColor, outer: CGColor, center: CGPoint? = nil, rad: CGFloat? = nil) {
    let g = CGGradient(colorsSpace: rgb, colors: [inner, outer] as CFArray, locations: [0,1])!
    let ctr = center ?? CGPoint(x: rect.midX, y: rect.midY)
    let rr = rad ?? max(rect.width, rect.height) * 0.75
    c.saveGState(); c.addRect(rect); c.clip()
    c.drawRadialGradient(g, startCenter: ctr, startRadius: 0, endCenter: ctr, endRadius: rr, options: [.drawsAfterEndLocation])
    c.restoreGState()
}
func linFill(_ c: CGContext, rect: CGRect, top: CGColor, bottom: CGColor) {
    let g = CGGradient(colorsSpace: rgb, colors: [top, bottom] as CFArray, locations: [0,1])!
    c.saveGState(); c.addRect(rect); c.clip()
    c.drawLinearGradient(g, start: CGPoint(x: rect.midX, y: rect.maxY), end: CGPoint(x: rect.midX, y: rect.minY), options: [])
    c.restoreGState()
}

func circle(_ c: CGContext, _ x: CGFloat, _ y: CGFloat, _ r: CGFloat, _ color: CGColor) {
    c.setFillColor(color); c.fillEllipse(in: CGRect(x: x-r, y: y-r, width: 2*r, height: 2*r))
}
func strokeCircle(_ c: CGContext, _ x: CGFloat, _ y: CGFloat, _ r: CGFloat, _ color: CGColor, _ w: CGFloat) {
    c.setStrokeColor(color); c.setLineWidth(w); c.strokeEllipse(in: CGRect(x: x-r, y: y-r, width: 2*r, height: 2*r))
}

// Category palette
struct Pal { let a: CGColor; let a2: CGColor; let deep: CGColor }
func pal(_ key: String) -> Pal {
    switch key {
    case "sky":   return Pal(a: col(0.53,0.66,0.92), a2: col(0.34,0.46,0.78), deep: col(0.10,0.14,0.28))
    case "water": return Pal(a: col(0.36,0.78,0.80), a2: col(0.20,0.55,0.62), deep: col(0.06,0.16,0.20))
    case "fire":  return Pal(a: col(0.98,0.68,0.34), a2: col(0.93,0.44,0.28), deep: col(0.20,0.10,0.10))
    case "forest":return Pal(a: col(0.52,0.74,0.50), a2: col(0.28,0.52,0.40), deep: col(0.08,0.16,0.12))
    default:      return Pal(a: col(0.70,0.60,0.94), a2: col(0.50,0.42,0.80), deep: col(0.13,0.11,0.24)) // tones
    }
}

let star: [CGPoint] = []

// ---- token motifs ---------------------------------------------------------
func drawDrops(_ c: CGContext, cx: CGFloat, cy: CGFloat, s: CGFloat, color: CGColor, n: Int, spread: CGFloat, seed: UInt64) {
    var rng = RNG(seed)
    for _ in 0..<n {
        let x = cx + CGFloat(rng.r(-Double(spread), Double(spread)))
        let y = cy - CGFloat(rng.r(0, Double(spread)))
        let ln = s * CGFloat(rng.r(0.5, 1.0))
        c.setStrokeColor(color); c.setLineWidth(s*0.18); c.setLineCap(.round)
        c.move(to: CGPoint(x:x, y:y)); c.addLine(to: CGPoint(x:x - ln*0.2, y:y - ln)); c.strokePath()
    }
}
func cloud(_ c: CGContext, cx: CGFloat, cy: CGFloat, s: CGFloat, color: CGColor) {
    circle(c, cx - s*0.5, cy, s*0.55, color)
    circle(c, cx + s*0.5, cy, s*0.55, color)
    circle(c, cx, cy + s*0.25, s*0.7, color)
    c.setFillColor(color)
    c.fill(CGRect(x: cx - s*1.05, y: cy - s*0.55, width: s*2.1, height: s*0.9))
}
func flame(_ c: CGContext, cx: CGFloat, cy: CGFloat, s: CGFloat, outer: CGColor, inner: CGColor) {
    let p = CGMutablePath()
    p.move(to: CGPoint(x: cx, y: cy + s*1.4))
    p.addCurve(to: CGPoint(x: cx - s*0.9, y: cy), control1: CGPoint(x: cx - s*0.7, y: cy + s), control2: CGPoint(x: cx - s*0.9, y: cy + s*0.5))
    p.addCurve(to: CGPoint(x: cx, y: cy - s*1.2), control1: CGPoint(x: cx - s*0.9, y: cy - s*0.7), control2: CGPoint(x: cx - s*0.2, y: cy - s*0.6))
    p.addCurve(to: CGPoint(x: cx + s*0.9, y: cy), control1: CGPoint(x: cx + s*0.4, y: cy - s*0.6), control2: CGPoint(x: cx + s*0.9, y: cy - s*0.5))
    p.addCurve(to: CGPoint(x: cx, y: cy + s*1.4), control1: CGPoint(x: cx + s*0.9, y: cy + s*0.5), control2: CGPoint(x: cx + s*0.7, y: cy + s))
    c.setFillColor(outer); c.addPath(p); c.fillPath()
    let p2 = CGMutablePath()
    p2.move(to: CGPoint(x: cx, y: cy + s*1.0))
    p2.addCurve(to: CGPoint(x: cx - s*0.45, y: cy + s*0.2), control1: CGPoint(x: cx - s*0.35, y: cy + s*0.7), control2: CGPoint(x: cx - s*0.45, y: cy + s*0.5))
    p2.addCurve(to: CGPoint(x: cx, y: cy - s*0.4), control1: CGPoint(x: cx - s*0.45, y: cy - s*0.1), control2: CGPoint(x: cx - s*0.1, y: cy - s*0.2))
    p2.addCurve(to: CGPoint(x: cx + s*0.45, y: cy + s*0.2), control1: CGPoint(x: cx + s*0.2, y: cy - s*0.15), control2: CGPoint(x: cx + s*0.45, y: cy - s*0.05))
    p2.addCurve(to: CGPoint(x: cx, y: cy + s*1.0), control1: CGPoint(x: cx + s*0.45, y: cy + s*0.5), control2: CGPoint(x: cx + s*0.35, y: cy + s*0.7))
    c.setFillColor(inner); c.addPath(p2); c.fillPath()
}
func waves(_ c: CGContext, cx: CGFloat, cy: CGFloat, s: CGFloat, color: CGColor, rows: Int) {
    c.setStrokeColor(color); c.setLineWidth(s*0.16); c.setLineCap(.round)
    for r in 0..<rows {
        let y = cy + CGFloat(r) * s*0.5 - CGFloat(rows-1)*s*0.25
        let p = CGMutablePath()
        p.move(to: CGPoint(x: cx - s*1.2, y: y))
        var x = cx - s*1.2
        var up = true
        while x < cx + s*1.2 {
            let nx = x + s*0.6
            p.addQuadCurve(to: CGPoint(x: nx, y: y), control: CGPoint(x: x + s*0.3, y: y + (up ? s*0.35 : -s*0.35)))
            x = nx; up.toggle()
        }
        c.addPath(p); c.strokePath()
    }
}
func bolt(_ c: CGContext, cx: CGFloat, cy: CGFloat, s: CGFloat, color: CGColor) {
    let p = CGMutablePath()
    p.move(to: CGPoint(x: cx + s*0.3, y: cy + s*1.1))
    p.addLine(to: CGPoint(x: cx - s*0.4, y: cy + s*0.1))
    p.addLine(to: CGPoint(x: cx + s*0.05, y: cy + s*0.1))
    p.addLine(to: CGPoint(x: cx - s*0.3, y: cy - s*1.1))
    p.addLine(to: CGPoint(x: cx + s*0.5, y: cy - s*0.1))
    p.addLine(to: CGPoint(x: cx + s*0.02, y: cy - s*0.1))
    p.closeSubpath()
    c.setFillColor(color); c.addPath(p); c.fillPath()
}
func swirl(_ c: CGContext, cx: CGFloat, cy: CGFloat, s: CGFloat, color: CGColor) {
    c.setStrokeColor(color); c.setLineWidth(s*0.16); c.setLineCap(.round)
    for k in 0..<3 {
        let y = cy + CGFloat(k-1)*s*0.6
        let p = CGMutablePath()
        p.move(to: CGPoint(x: cx - s*1.1, y: y))
        p.addCurve(to: CGPoint(x: cx + s*0.7, y: y), control1: CGPoint(x: cx - s*0.3, y: y + s*0.5), control2: CGPoint(x: cx + s*0.2, y: y - s*0.5))
        p.addCurve(to: CGPoint(x: cx + s*1.0, y: y + s*0.35), control1: CGPoint(x: cx + s*1.1, y: y + s*0.1), control2: CGPoint(x: cx + s*1.05, y: y + s*0.35))
        c.addPath(p); c.strokePath()
    }
}
func owlFace(_ c: CGContext, cx: CGFloat, cy: CGFloat, s: CGFloat, body: CGColor, eye: CGColor, dark: CGColor) {
    // body
    let p = CGMutablePath()
    p.addEllipse(in: CGRect(x: cx - s, y: cy - s*1.1, width: s*2, height: s*2.2))
    c.setFillColor(body); c.addPath(p); c.fillPath()
    // ears
    let e = CGMutablePath()
    e.move(to: CGPoint(x: cx - s*0.85, y: cy + s*0.7)); e.addLine(to: CGPoint(x: cx - s*1.05, y: cy + s*1.25)); e.addLine(to: CGPoint(x: cx - s*0.45, y: cy + s*0.85)); e.closeSubpath()
    e.move(to: CGPoint(x: cx + s*0.85, y: cy + s*0.7)); e.addLine(to: CGPoint(x: cx + s*1.05, y: cy + s*1.25)); e.addLine(to: CGPoint(x: cx + s*0.45, y: cy + s*0.85)); e.closeSubpath()
    c.setFillColor(body); c.addPath(e); c.fillPath()
    // eyes
    circle(c, cx - s*0.42, cy + s*0.25, s*0.42, eye)
    circle(c, cx + s*0.42, cy + s*0.25, s*0.42, eye)
    circle(c, cx - s*0.42, cy + s*0.25, s*0.2, dark)
    circle(c, cx + s*0.42, cy + s*0.25, s*0.2, dark)
    // beak
    let bk = CGMutablePath()
    bk.move(to: CGPoint(x: cx, y: cy + s*0.05)); bk.addLine(to: CGPoint(x: cx - s*0.14, y: cy - s*0.2)); bk.addLine(to: CGPoint(x: cx + s*0.14, y: cy - s*0.2)); bk.closeSubpath()
    c.setFillColor(dark); c.addPath(bk); c.fillPath()
}
func bird(_ c: CGContext, cx: CGFloat, cy: CGFloat, s: CGFloat, body: CGColor, dark: CGColor) {
    let p = CGMutablePath()
    p.addEllipse(in: CGRect(x: cx - s*0.8, y: cy - s*0.6, width: s*1.5, height: s*1.2))
    c.setFillColor(body); c.addPath(p); c.fillPath()
    circle(c, cx + s*0.55, cy + s*0.45, s*0.45, body) // head
    circle(c, cx + s*0.62, cy + s*0.52, s*0.09, dark) // eye
    let bk = CGMutablePath()
    bk.move(to: CGPoint(x: cx + s*0.95, y: cy + s*0.45)); bk.addLine(to: CGPoint(x: cx + s*1.25, y: cy + s*0.52)); bk.addLine(to: CGPoint(x: cx + s*0.95, y: cy + s*0.6)); bk.closeSubpath()
    c.setFillColor(dark); c.addPath(bk); c.fillPath()
    // wing
    let w = CGMutablePath()
    w.move(to: CGPoint(x: cx - s*0.5, y: cy)); w.addQuadCurve(to: CGPoint(x: cx + s*0.4, y: cy - s*0.1), control: CGPoint(x: cx, y: cy + s*0.5))
    w.addQuadCurve(to: CGPoint(x: cx - s*0.5, y: cy), control: CGPoint(x: cx - s*0.1, y: cy - s*0.3))
    c.setFillColor(dark); c.addPath(w); c.fillPath()
    // tail
    let t = CGMutablePath()
    t.move(to: CGPoint(x: cx - s*0.7, y: cy)); t.addLine(to: CGPoint(x: cx - s*1.2, y: cy - s*0.25)); t.addLine(to: CGPoint(x: cx - s*0.6, y: cy - s*0.35)); t.closeSubpath()
    c.setFillColor(body); c.addPath(t); c.fillPath()
}
func leafShape(_ c: CGContext, cx: CGFloat, cy: CGFloat, s: CGFloat, ang: CGFloat, color: CGColor, vein: CGColor) {
    c.saveGState(); c.translateBy(x: cx, y: cy); c.rotate(by: ang)
    let p = CGMutablePath()
    p.move(to: CGPoint(x: 0, y: -s))
    p.addQuadCurve(to: CGPoint(x: 0, y: s), control: CGPoint(x: s*0.7, y: 0))
    p.addQuadCurve(to: CGPoint(x: 0, y: -s), control: CGPoint(x: -s*0.7, y: 0))
    c.setFillColor(color); c.addPath(p); c.fillPath()
    c.setStrokeColor(vein); c.setLineWidth(s*0.08); c.setLineCap(.round)
    c.move(to: CGPoint(x:0,y:-s*0.8)); c.addLine(to: CGPoint(x:0,y:s*0.8)); c.strokePath()
    c.restoreGState()
}
func bowlShape(_ c: CGContext, cx: CGFloat, cy: CGFloat, s: CGFloat, color: CGColor, rim: CGColor) {
    let p = CGMutablePath()
    p.move(to: CGPoint(x: cx - s, y: cy + s*0.35))
    p.addQuadCurve(to: CGPoint(x: cx + s, y: cy + s*0.35), control: CGPoint(x: cx, y: cy - s*0.9))
    p.closeSubpath()
    c.setFillColor(color); c.addPath(p); c.fillPath()
    c.setFillColor(rim)
    c.fill(CGRect(x: cx - s*1.05, y: cy + s*0.28, width: s*2.1, height: s*0.16))
    // rings above
    for i in 0..<3 {
        let rr = s*0.4 + CGFloat(i)*s*0.32
        strokeCircle(c, cx, cy + s*0.5 + CGFloat(i)*s*0.15, rr, rim, s*0.06)
    }
}
func pianoKeys(_ c: CGContext, cx: CGFloat, cy: CGFloat, s: CGFloat, white: CGColor, black: CGColor) {
    let n = 5
    let kw = s*2.0 / CGFloat(n)
    for i in 0..<n {
        let x = cx - s + CGFloat(i)*kw
        c.setFillColor(white)
        let rp = CGPath(roundedRect: CGRect(x: x+1, y: cy - s*0.9, width: kw-2, height: s*1.8), cornerWidth: 3, cornerHeight: 3, transform: nil)
        c.addPath(rp); c.fillPath()
    }
    for i in 0..<(n-1) {
        if i == 2 { continue }
        let x = cx - s + CGFloat(i+1)*kw
        c.setFillColor(black)
        c.fill(CGRect(x: x - kw*0.28, y: cy - s*0.1, width: kw*0.56, height: s*0.9))
    }
}
func heart(_ c: CGContext, cx: CGFloat, cy: CGFloat, s: CGFloat, color: CGColor) {
    let p = CGMutablePath()
    p.move(to: CGPoint(x: cx, y: cy - s*0.7))
    p.addCurve(to: CGPoint(x: cx - s, y: cy + s*0.4), control1: CGPoint(x: cx - s*0.5, y: cy - s*1.1), control2: CGPoint(x: cx - s, y: cy - s*0.2))
    p.addCurve(to: CGPoint(x: cx, y: cy + s*1.0), control1: CGPoint(x: cx - s, y: cy + s*0.8), control2: CGPoint(x: cx - s*0.35, y: cy + s*0.85))
    p.addCurve(to: CGPoint(x: cx + s, y: cy + s*0.4), control1: CGPoint(x: cx + s*0.35, y: cy + s*0.85), control2: CGPoint(x: cx + s, y: cy + s*0.8))
    p.addCurve(to: CGPoint(x: cx, y: cy - s*0.7), control1: CGPoint(x: cx + s, y: cy - s*0.2), control2: CGPoint(x: cx + s*0.5, y: cy - s*1.1))
    c.setFillColor(color); c.addPath(p); c.fillPath()
}
func pulseLine(_ c: CGContext, cx: CGFloat, cy: CGFloat, s: CGFloat, color: CGColor) {
    c.setStrokeColor(color); c.setLineWidth(s*0.12); c.setLineCap(.round); c.setLineJoin(.round)
    let p = CGMutablePath()
    p.move(to: CGPoint(x: cx - s*1.2, y: cy))
    p.addLine(to: CGPoint(x: cx - s*0.4, y: cy))
    p.addLine(to: CGPoint(x: cx - s*0.2, y: cy + s*0.6))
    p.addLine(to: CGPoint(x: cx, y: cy - s*0.8))
    p.addLine(to: CGPoint(x: cx + s*0.2, y: cy + s*0.3))
    p.addLine(to: CGPoint(x: cx + s*0.4, y: cy))
    p.addLine(to: CGPoint(x: cx + s*1.2, y: cy))
    c.addPath(p); c.strokePath()
}
func fanBlades(_ c: CGContext, cx: CGFloat, cy: CGFloat, s: CGFloat, color: CGColor, hub: CGColor) {
    strokeCircle(c, cx, cy, s*1.1, color, s*0.14)
    for k in 0..<4 {
        c.saveGState(); c.translateBy(x: cx, y: cy); c.rotate(by: CGFloat(k) * .pi/2)
        let p = CGMutablePath()
        p.move(to: CGPoint(x: 0, y: 0))
        p.addQuadCurve(to: CGPoint(x: s*0.9, y: s*0.2), control: CGPoint(x: s*0.7, y: s*0.7))
        p.addQuadCurve(to: CGPoint(x: 0, y: 0), control: CGPoint(x: s*0.5, y: -s*0.2))
        c.setFillColor(color); c.addPath(p); c.fillPath()
        c.restoreGState()
    }
    circle(c, cx, cy, s*0.22, hub)
}
func chimeBars(_ c: CGContext, cx: CGFloat, cy: CGFloat, s: CGFloat, bar: CGColor, top: CGColor) {
    c.setFillColor(top)
    c.fill(CGRect(x: cx - s*0.9, y: cy + s*1.0, width: s*1.8, height: s*0.14)) // top holder
    let n = 4
    for i in 0..<n {
        let x = cx - s*0.7 + CGFloat(i) * s*0.46
        let h = s*(1.6 - CGFloat(i)*0.22)
        c.setStrokeColor(top); c.setLineWidth(s*0.03)
        c.move(to: CGPoint(x:x,y:cy+s*1.0)); c.addLine(to: CGPoint(x:x,y:cy+s*0.75)); c.strokePath()
        let rp = CGPath(roundedRect: CGRect(x: x - s*0.1, y: cy + s*0.75 - h, width: s*0.2, height: h), cornerWidth: s*0.1, cornerHeight: s*0.1, transform: nil)
        c.setFillColor(bar); c.addPath(rp); c.fillPath()
    }
}
func trainCar(_ c: CGContext, cx: CGFloat, cy: CGFloat, s: CGFloat, body: CGColor, dark: CGColor, glow: CGColor) {
    let rp = CGPath(roundedRect: CGRect(x: cx - s*1.1, y: cy - s*0.5, width: s*2.0, height: s*1.1), cornerWidth: s*0.2, cornerHeight: s*0.2, transform: nil)
    c.setFillColor(body); c.addPath(rp); c.fillPath()
    // cab front
    let cab = CGPath(roundedRect: CGRect(x: cx + s*0.55, y: cy - s*0.5, width: s*0.55, height: s*1.3), cornerWidth: s*0.15, cornerHeight: s*0.15, transform: nil)
    c.setFillColor(dark); c.addPath(cab); c.fillPath()
    // windows
    c.setFillColor(glow)
    c.fill(CGRect(x: cx - s*0.85, y: cy + s*0.05, width: s*0.35, height: s*0.35))
    c.fill(CGRect(x: cx - s*0.35, y: cy + s*0.05, width: s*0.35, height: s*0.35))
    // headlight
    circle(c, cx + s*0.95, cy - s*0.1, s*0.12, glow)
    // wheels
    circle(c, cx - s*0.6, cy - s*0.6, s*0.22, dark)
    circle(c, cx + s*0.2, cy - s*0.6, s*0.22, dark)
    circle(c, cx + s*0.75, cy - s*0.6, s*0.18, dark)
}
func lilyPad(_ c: CGContext, cx: CGFloat, cy: CGFloat, s: CGFloat, pad: CGColor, ripple: CGColor) {
    for i in 0..<3 { strokeCircle(c, cx, cy - s*0.2, s*(0.7 + CGFloat(i)*0.4), ripple, s*0.05) }
    let p = CGMutablePath()
    p.addArc(center: CGPoint(x: cx, y: cy), radius: s*0.8, startAngle: CGFloat(0.35), endAngle: CGFloat(-0.35 + 2 * .pi), clockwise: false)
    p.addLine(to: CGPoint(x: cx, y: cy))
    c.setFillColor(pad); c.addPath(p); c.fillPath()
}
func grassBlades(_ c: CGContext, cx: CGFloat, cy: CGFloat, s: CGFloat, color: CGColor, seed: UInt64) {
    var rng = RNG(seed)
    for _ in 0..<7 {
        let x = cx + CGFloat(rng.r(-Double(s), Double(s)))
        let h = s * CGFloat(rng.r(0.9, 1.7))
        let bend = CGFloat(rng.r(-0.4, 0.4)) * s
        c.setStrokeColor(color); c.setLineWidth(s*0.1); c.setLineCap(.round)
        let p = CGMutablePath(); p.move(to: CGPoint(x:x,y:cy - s*0.6))
        p.addQuadCurve(to: CGPoint(x: x+bend, y: cy - s*0.6 + h), control: CGPoint(x: x+bend*0.4, y: cy - s*0.6 + h*0.6))
        c.addPath(p); c.strokePath()
    }
}
func pebbleStream(_ c: CGContext, cx: CGFloat, cy: CGFloat, s: CGFloat, water: CGColor, pebble: CGColor, seed: UInt64) {
    waves(c, cx: cx, cy: cy + s*0.3, s: s*0.8, color: water, rows: 3)
    var rng = RNG(seed)
    for _ in 0..<4 {
        let x = cx + CGFloat(rng.r(-Double(s), Double(s)))
        let y = cy - s*0.7 + CGFloat(rng.r(-Double(s)*0.2, Double(s)*0.2))
        circle(c, x, y, s*CGFloat(rng.r(0.14,0.24)), pebble)
    }
}
func radialDots(_ c: CGContext, cx: CGFloat, cy: CGFloat, s: CGFloat, color: CGColor, seed: UInt64) {
    var rng = RNG(seed)
    for _ in 0..<70 {
        let ang = rng.r(0, 6.283); let rad = CGFloat(rng.r(0, Double(s)*1.3))
        let x = cx + cos(ang)*Double(rad); let y = cy + sin(ang)*Double(rad)
        let a = 0.7 * (1 - Double(rad)/(Double(s)*1.3))
        circle(c, CGFloat(x), CGFloat(y), CGFloat(rng.r(1.5, 5)), col(1,1,1,max(0.05,a)))
    }
    _ = color
}
func concentric(_ c: CGContext, cx: CGFloat, cy: CGFloat, s: CGFloat, color: CGColor) {
    for i in 0..<5 { strokeCircle(c, cx, cy, s*(0.3+CGFloat(i)*0.3), col(1,1,1, 0.6 - Double(i)*0.1), s*0.09) }
    _ = color
}

// draw one token: name -> motif
func drawMotif(_ c: CGContext, _ key: String, cx: CGFloat, cy: CGFloat, s: CGFloat, p: Pal) {
    let white = col(0.97,0.98,1.0)
    let soft = col(0.90,0.94,1.0,0.9)
    switch key {
    case "rain":
        cloud(c, cx: cx, cy: cy + s*0.4, s: s*0.75, color: white); drawDrops(c, cx: cx, cy: cy - s*0.3, s: s*0.7, color: soft, n: 6, spread: s*0.9, seed: 11)
    case "heavyrain":
        cloud(c, cx: cx, cy: cy + s*0.5, s: s*0.8, color: col(0.82,0.86,0.95)); drawDrops(c, cx: cx, cy: cy - s*0.2, s: s*0.9, color: soft, n: 11, spread: s*1.0, seed: 22)
    case "thunder":
        cloud(c, cx: cx, cy: cy + s*0.55, s: s*0.8, color: col(0.78,0.82,0.92)); bolt(c, cx: cx, cy: cy - s*0.55, s: s*0.7, color: col(0.99,0.86,0.45))
    case "wind":
        swirl(c, cx: cx, cy: cy, s: s*0.9, color: white)
    case "campfire":
        // logs
        c.setStrokeColor(col(0.45,0.32,0.22)); c.setLineWidth(s*0.22); c.setLineCap(.round)
        c.move(to: CGPoint(x: cx - s*0.7, y: cy - s*0.8)); c.addLine(to: CGPoint(x: cx + s*0.7, y: cy - s*0.55)); c.strokePath()
        c.move(to: CGPoint(x: cx + s*0.7, y: cy - s*0.8)); c.addLine(to: CGPoint(x: cx - s*0.7, y: cy - s*0.55)); c.strokePath()
        flame(c, cx: cx, cy: cy + s*0.15, s: s*0.7, outer: col(0.98,0.55,0.25), inner: col(0.99,0.85,0.45))
    case "fan":
        fanBlades(c, cx: cx, cy: cy, s: s*0.85, color: white, hub: p.a)
    case "chimes":
        chimeBars(c, cx: cx, cy: cy - s*0.2, s: s*0.7, bar: white, top: col(0.55,0.4,0.3))
    case "heartbeat":
        heart(c, cx: cx, cy: cy + s*0.1, s: s*0.8, color: col(0.96,0.5,0.5)); pulseLine(c, cx: cx, cy: cy + s*0.1, s: s*0.7, color: white)
    case "ocean":
        waves(c, cx: cx, cy: cy, s: s*0.9, color: white, rows: 3)
    case "stream":
        pebbleStream(c, cx: cx, cy: cy, s: s*0.9, water: white, pebble: col(0.7,0.78,0.82), seed: 33)
    case "frogs":
        lilyPad(c, cx: cx, cy: cy, s: s*0.9, pad: col(0.4,0.7,0.45), ripple: soft); circle(c, cx + s*0.5, cy + s*0.3, s*0.12, col(0.55,0.8,0.5))
    case "train":
        trainCar(c, cx: cx, cy: cy, s: s*0.85, body: white, dark: p.a2, glow: col(0.99,0.86,0.5))
    case "crickets":
        grassBlades(c, cx: cx, cy: cy, s: s*0.85, color: white, seed: 44)
        // note
        circle(c, cx + s*0.7, cy + s*0.6, s*0.16, white); c.setStrokeColor(white); c.setLineWidth(s*0.08)
        c.move(to: CGPoint(x: cx + s*0.85, y: cy + s*0.6)); c.addLine(to: CGPoint(x: cx + s*0.85, y: cy + s*1.1)); c.strokePath()
    case "owl":
        owlFace(c, cx: cx, cy: cy, s: s*0.7, body: white, eye: col(0.99,0.82,0.4), dark: col(0.2,0.24,0.32))
    case "birds":
        bird(c, cx: cx - s*0.1, cy: cy, s: s*0.8, body: white, dark: p.a2)
    case "leaves":
        leafShape(c, cx: cx - s*0.35, cy: cy - s*0.1, s: s*0.7, ang: -0.5, color: white, vein: p.a2)
        leafShape(c, cx: cx + s*0.35, cy: cy + s*0.2, s: s*0.6, ang: 0.6, color: soft, vein: p.a2)
        leafShape(c, cx: cx, cy: cy - s*0.55, s: s*0.5, ang: 0.1, color: white, vein: p.a2)
    case "bowl":
        bowlShape(c, cx: cx, cy: cy - s*0.2, s: s*0.85, color: white, rim: col(0.99,0.82,0.45))
    case "piano":
        pianoKeys(c, cx: cx, cy: cy, s: s*0.85, white: white, black: col(0.18,0.16,0.24))
    case "whitenoise":
        concentric(c, cx: cx, cy: cy, s: s, color: white); radialDots(c, cx: cx, cy: cy, s: s*0.9, color: white, seed: 55)
    case "brownnoise":
        radialFill(c, rect: CGRect(x: cx - s*1.3, y: cy - s*1.3, width: s*2.6, height: s*2.6), inner: col(0.85,0.6,0.4,0.9), outer: col(0.85,0.6,0.4,0.0))
        radialDots(c, cx: cx, cy: cy, s: s, color: white, seed: 66)
    default:
        circle(c, cx, cy, s*0.6, white)
    }
}

// ---- render a token -------------------------------------------------------
func token(_ key: String, cat: String, path: String) {
    let W = 512
    let c = ctx(W, W, opaque: false)
    let p = pal(cat)
    let cx = CGFloat(W)/2, cy = CGFloat(W)/2
    // disc
    c.saveGState()
    c.addEllipse(in: CGRect(x: 24, y: 24, width: W-48, height: W-48)); c.clip()
    radialFill(c, rect: CGRect(x:0,y:0,width:W,height:W), inner: p.a, outer: p.a2,
               center: CGPoint(x: cx, y: cy + 60), rad: CGFloat(W)*0.7)
    // subtle top sheen
    radialFill(c, rect: CGRect(x:0,y:0,width:W,height:W), inner: col(1,1,1,0.22), outer: col(1,1,1,0.0),
               center: CGPoint(x: cx, y: CGFloat(W)-120), rad: 220)
    c.restoreGState()
    // inner ring
    strokeCircle(c, cx, cy, CGFloat(W)/2 - 26, col(1,1,1,0.35), 4)
    strokeCircle(c, cx, cy, CGFloat(W)/2 - 20, col(0,0,0,0.12), 6)
    // motif
    drawMotif(c, key, cx: cx, cy: cy, s: 118, p: p)
    save(c, path)
}

// ---- category banner ------------------------------------------------------
func banner(_ cat: String, keys: [String], path: String) {
    let W = 1200, H = 480
    let c = ctx(W, H, opaque: false)
    let p = pal(cat)
    linFill(c, rect: CGRect(x:0,y:0,width:W,height:H), top: p.a2, bottom: p.deep)
    radialFill(c, rect: CGRect(x:0,y:0,width:W,height:H), inner: col(1,1,1,0.14), outer: col(1,1,1,0),
               center: CGPoint(x: 300, y: H-120), rad: 500)
    // scattered stars
    var rng = RNG(cat.count == 0 ? 7 : UInt64(cat.unicodeScalars.first!.value) * 13 + 5)
    for _ in 0..<40 { circle(c, CGFloat(rng.r(0,Double(W))), CGFloat(rng.r(Double(H)*0.4,Double(H))), CGFloat(rng.r(1,3)), col(1,1,1,rng.r(0.15,0.55))) }
    // three motif discs
    let xs: [CGFloat] = [280, 620, 940]
    for (i,k) in keys.prefix(3).enumerated() {
        let cx = xs[i], cy = CGFloat(H)/2 - 20
        circle(c, cx, cy, 120, col(1,1,1,0.10))
        strokeCircle(c, cx, cy, 120, col(1,1,1,0.25), 3)
        drawMotif(c, k, cx: cx, cy: cy, s: 68, p: p)
    }
    save(c, path)
}

// ---- scene preset cover ---------------------------------------------------
func cover(_ name: String, cat: String, keys: [String], path: String, night: Bool) {
    let W = 1000, H = 700
    let c = ctx(W, H, opaque: false)
    let p = pal(cat)
    let top = night ? p.deep : p.a2
    linFill(c, rect: CGRect(x:0,y:0,width:W,height:H), top: p.deep, bottom: top)
    // moon/sun
    let glow = night ? col(0.95,0.95,0.85) : col(0.99,0.85,0.5)
    radialFill(c, rect: CGRect(x:0,y:0,width:W,height:H), inner: col(glow.components![0],glow.components![1],glow.components![2],0.5), outer: col(1,1,1,0),
               center: CGPoint(x: 780, y: 520), rad: 320)
    circle(c, 780, 520, 70, glow)
    // stars
    var rng = RNG(UInt64(name.count) * 131 + 17)
    for _ in 0..<80 { circle(c, CGFloat(rng.r(0,Double(W))), CGFloat(rng.r(Double(H)*0.35,Double(H))), CGFloat(rng.r(1,3)), col(1,1,1,rng.r(0.2,0.7))) }
    // layered hills
    for layer in 0..<3 {
        let base = CGFloat(120 + layer*70)
        let shade = 0.14 + Double(layer)*0.10
        let path2 = CGMutablePath()
        path2.move(to: CGPoint(x: 0, y: 0))
        path2.addLine(to: CGPoint(x: 0, y: base))
        var x: CGFloat = 0
        while x < CGFloat(W) {
            let nx = x + CGFloat(rng.r(120,220))
            let peak = base + CGFloat(rng.r(20,90))
            path2.addQuadCurve(to: CGPoint(x: nx, y: base), control: CGPoint(x: (x+nx)/2, y: peak))
            x = nx
        }
        path2.addLine(to: CGPoint(x: CGFloat(W), y: 0)); path2.closeSubpath()
        c.setFillColor(col(p.a.components![0]*CGFloat(shade+0.1), p.a.components![1]*CGFloat(shade+0.1), p.a.components![2]*CGFloat(shade+0.1), 1))
        c.addPath(path2); c.fillPath()
    }
    // motif discs floating
    let xs: [CGFloat] = [230, 470, 700]
    for (i,k) in keys.prefix(3).enumerated() {
        let cx = xs[i], cy = CGFloat(H) - 260 + CGFloat(i%2)*40
        circle(c, cx, cy, 78, col(1,1,1,0.12))
        strokeCircle(c, cx, cy, 78, col(1,1,1,0.3), 3)
        drawMotif(c, k, cx: cx, cy: cy, s: 44, p: p)
    }
    save(c, path)
}

// ---- onboarding illustration ----------------------------------------------
func onboard(_ idx: Int, path: String) {
    let W = 1000, H = 1000
    let c = ctx(W, H, opaque: false)
    let cats = ["sky","fire","tones"]
    let p = pal(cats[idx % 3])
    linFill(c, rect: CGRect(x:0,y:0,width:W,height:H), top: col(0.10,0.12,0.22), bottom: col(0.05,0.06,0.13))
    radialFill(c, rect: CGRect(x:0,y:0,width:W,height:H), inner: col(p.a.components![0],p.a.components![1],p.a.components![2],0.35), outer: col(1,1,1,0),
               center: CGPoint(x: 500, y: 560), rad: 460)
    var rng = RNG(UInt64(idx*97+3))
    for _ in 0..<120 { circle(c, CGFloat(rng.r(0,Double(W))), CGFloat(rng.r(0,Double(H))), CGFloat(rng.r(1,3)), col(1,1,1,rng.r(0.1,0.5))) }
    // central grove of discs
    let motifs: [[String]] = [["rain","campfire","ocean"], ["chimes","piano","bowl"], ["owl","birds","stream"]]
    let ms = motifs[idx % 3]
    let positions: [(CGFloat,CGFloat,CGFloat)] = [(500,560,150),(330,430,95),(680,440,95)]
    for (i,k) in ms.enumerated() {
        let (x,y,r) = positions[i]
        let pp = pal(["sky","fire","water","forest","tones"][(idx*3+i) % 5])
        c.saveGState(); c.addEllipse(in: CGRect(x:x-r,y:y-r,width:2*r,height:2*r)); c.clip()
        radialFill(c, rect: CGRect(x:x-r,y:y-r,width:2*r,height:2*r), inner: pp.a, outer: pp.a2, center: CGPoint(x:x,y:y+r*0.4), rad: r*1.4)
        c.restoreGState()
        strokeCircle(c, x, y, r-4, col(1,1,1,0.35), 4)
        drawMotif(c, k, cx: x, cy: y, s: r*0.55, p: pp)
    }
    save(c, path)
}

// ---- grain tile -----------------------------------------------------------
func grain(_ path: String) {
    let W = 256
    let c = ctx(W, W, opaque: false)
    var rng = RNG(999)
    for _ in 0..<9000 {
        let x = CGFloat(rng.r(0,Double(W))), y = CGFloat(rng.r(0,Double(W)))
        let v = rng.d()
        c.setFillColor(col(1,1,1, v*0.05))
        c.fill(CGRect(x:x,y:y,width:1,height:1))
    }
    save(c, path)
}

// ---- app icon (abstract, opaque, no alpha) --------------------------------
func appIcon(_ path: String) {
    let W = 1024
    let c = ctx(W, W, opaque: true)
    // dusk background
    linFill(c, rect: CGRect(x:0,y:0,width:W,height:W), top: col(0.16,0.16,0.30), bottom: col(0.05,0.06,0.13))
    radialFill(c, rect: CGRect(x:0,y:0,width:W,height:W), inner: col(0.35,0.30,0.55,0.7), outer: col(0.05,0.06,0.13,0),
               center: CGPoint(x: 512, y: 560), rad: 620)
    // concentric sound rings (abstract emblem)
    let cx: CGFloat = 512, cy: CGFloat = 512
    let ringCols = [col(0.70,0.60,0.94), col(0.55,0.72,0.95), col(0.40,0.80,0.82)]
    for i in 0..<3 {
        let r = CGFloat(150 + i*95)
        c.setStrokeColor(col(ringCols[i].components![0],ringCols[i].components![1],ringCols[i].components![2], 0.9 - Double(i)*0.18))
        c.setLineWidth(26 - CGFloat(i)*4); c.setLineCap(.round)
        // partial arcs (sound wave feel)
        c.addArc(center: CGPoint(x: cx, y: cy), radius: r, startAngle: -0.9, endAngle: 0.9, clockwise: false); c.strokePath()
        c.addArc(center: CGPoint(x: cx, y: cy), radius: r, startAngle: .pi - 0.9, endAngle: .pi + 0.9, clockwise: false); c.strokePath()
    }
    // center orb
    let g = CGGradient(colorsSpace: rgb, colors: [col(0.99,0.90,0.60), col(0.95,0.66,0.34)] as CFArray, locations: [0,1])!
    c.drawRadialGradient(g, startCenter: CGPoint(x: cx-20, y: cy+20), startRadius: 4, endCenter: CGPoint(x: cx, y: cy), endRadius: 90, options: [])
    // sparkles
    circle(c, 350, 720, 10, col(1,1,1,0.9))
    circle(c, 700, 340, 8, col(1,1,1,0.8))
    circle(c, 760, 700, 6, col(1,1,1,0.7))
    save(c, path)
}

// ===========================================================================
let artDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
let iconPath = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : "AppIcon-1024.png"

let catOf: [String:String] = [
    "rain":"sky","heavyrain":"sky","thunder":"sky","wind":"sky",
    "campfire":"fire","fan":"fire","chimes":"fire","heartbeat":"fire",
    "ocean":"water","stream":"water","frogs":"water","train":"water",
    "crickets":"forest","owl":"forest","birds":"forest","leaves":"forest",
    "bowl":"tones","piano":"tones","whitenoise":"tones","brownnoise":"tones",
]

print("Rendering tokens...")
for (k,cat) in catOf { token(k, cat: cat, path: "\(artDir)/tok_\(k).png") }

print("Rendering banners...")
banner("sky", keys: ["rain","thunder","wind"], path: "\(artDir)/banner_sky.png")
banner("fire", keys: ["campfire","chimes","fan"], path: "\(artDir)/banner_fire.png")
banner("water", keys: ["ocean","stream","train"], path: "\(artDir)/banner_water.png")
banner("forest", keys: ["owl","birds","leaves"], path: "\(artDir)/banner_forest.png")
banner("tones", keys: ["bowl","piano","whitenoise"], path: "\(artDir)/banner_tones.png")

print("Rendering scene covers...")
cover("Rainy Cabin", cat: "sky", keys: ["rain","campfire","wind"], path: "\(artDir)/scene_cabin.png", night: true)
cover("Ocean Dusk", cat: "water", keys: ["ocean","wind","chimes"], path: "\(artDir)/scene_ocean.png", night: false)
cover("Midnight Forest", cat: "forest", keys: ["crickets","owl","leaves"], path: "\(artDir)/scene_forest.png", night: true)
cover("Cozy Fireside", cat: "fire", keys: ["campfire","fan","bowl"], path: "\(artDir)/scene_fireside.png", night: true)
cover("Thunderstorm", cat: "sky", keys: ["heavyrain","thunder","wind"], path: "\(artDir)/scene_storm.png", night: true)
cover("Morning Meadow", cat: "forest", keys: ["birds","stream","leaves"], path: "\(artDir)/scene_meadow.png", night: false)
cover("Night Train", cat: "water", keys: ["train","rain","brownnoise"], path: "\(artDir)/scene_train.png", night: true)
cover("Zen Garden", cat: "tones", keys: ["bowl","piano","stream"], path: "\(artDir)/scene_zen.png", night: false)
cover("Deep Focus", cat: "tones", keys: ["brownnoise","fan","rain"], path: "\(artDir)/scene_focus.png", night: true)
cover("Sleepy Pond", cat: "forest", keys: ["frogs","crickets","wind"], path: "\(artDir)/scene_pond.png", night: true)

print("Rendering onboarding + grain...")
onboard(0, path: "\(artDir)/onb_1.png")
onboard(1, path: "\(artDir)/onb_2.png")
onboard(2, path: "\(artDir)/onb_3.png")
grain("\(artDir)/grain.png")

print("Rendering app icon...")
appIcon(iconPath)
print("Done.")
