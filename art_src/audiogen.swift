// Sound Grove — procedural ambient audio loop generator.
// Compile:  swiftc -O audiogen.swift -o audiogen
// Run:      ./audiogen  <output_dir>
// Writes seamless-looping 16-bit PCM mono WAV files (44.1 kHz).
import Foundation

let SR: Double = 44100.0

// Deterministic RNG (xorshift) so builds are reproducible.
struct RNG {
    var s: UInt64
    init(_ seed: UInt64) { s = seed == 0 ? 0x9E3779B97F4A7C15 : seed }
    mutating func next() -> UInt64 {
        s ^= s << 13; s ^= s >> 7; s ^= s << 17; return s
    }
    mutating func d() -> Double { Double(next() >> 11) * (1.0 / 9007199254740992.0) } // 0..1
    mutating func pm() -> Double { d() * 2.0 - 1.0 } // -1..1
    mutating func range(_ a: Double, _ b: Double) -> Double { a + (b - a) * d() }
}

// One-pole low-pass.
final class LP { var y = 0.0; var a: Double
    init(_ cutoff: Double) { let x = exp(-2.0 * Double.pi * cutoff / SR); a = x }
    func f(_ x: Double) -> Double { y = (1 - a) * x + a * y; return y } }
// One-pole high-pass.
final class HP { var lp: LP; init(_ c: Double) { lp = LP(c) }
    func f(_ x: Double) -> Double { return x - lp.f(x) } }

func softClip(_ x: Double) -> Double {
    if x > 1 { return 1 } ; if x < -1 { return -1 }
    return 1.5 * x - 0.5 * x * x * x
}

// Equal-power crossfade the tail F samples over the head so start==end seamlessly.
func makeSeamless(_ buf: [Double], fade: Int) -> [Double] {
    let n = buf.count
    if fade <= 0 || fade * 2 >= n { return buf }
    var out = buf
    for i in 0..<fade {
        let w = Double(i) / Double(fade)      // 0..1 across the head
        let head = buf[i]
        let tail = buf[n - fade + i]
        // fade head in, fade wrapped tail out; equal power
        let a = sin(w * Double.pi / 2)
        let b = cos(w * Double.pi / 2)
        out[i] = head * a + tail * b
    }
    // drop the last `fade` samples we folded back
    return Array(out[0..<(n - fade)])
}

func normalize(_ buf: inout [Double], peak: Double) {
    var mx = 1e-9
    for v in buf { mx = max(mx, abs(v)) }
    let g = peak / mx
    for i in 0..<buf.count { buf[i] *= g }
}

func writeWAV(_ path: String, _ samples: [Double]) {
    var data = Data()
    let n = samples.count
    let byteRate = Int(SR) * 2
    func le32(_ v: Int) -> [UInt8] { [UInt8(v & 0xff), UInt8((v>>8)&0xff), UInt8((v>>16)&0xff), UInt8((v>>24)&0xff)] }
    func le16(_ v: Int) -> [UInt8] { [UInt8(v & 0xff), UInt8((v>>8)&0xff)] }
    data.append(contentsOf: Array("RIFF".utf8))
    data.append(contentsOf: le32(36 + n * 2))
    data.append(contentsOf: Array("WAVE".utf8))
    data.append(contentsOf: Array("fmt ".utf8))
    data.append(contentsOf: le32(16))
    data.append(contentsOf: le16(1))          // PCM
    data.append(contentsOf: le16(1))          // mono
    data.append(contentsOf: le32(Int(SR)))
    data.append(contentsOf: le32(byteRate))
    data.append(contentsOf: le16(2))          // block align
    data.append(contentsOf: le16(16))         // bits
    data.append(contentsOf: Array("data".utf8))
    data.append(contentsOf: le32(n * 2))
    var pcm = [UInt8](); pcm.reserveCapacity(n * 2)
    for s in samples {
        let c = max(-1.0, min(1.0, s))
        let v = Int16(c * 32767.0)
        pcm.append(UInt8(bitPattern: Int8(truncatingIfNeeded: Int(v) & 0xff)))
        pcm.append(UInt8(bitPattern: Int8(truncatingIfNeeded: (Int(v) >> 8) & 0xff)))
    }
    data.append(contentsOf: pcm)
    try? data.write(to: URL(fileURLWithPath: path))
}

let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."

// ---- synthesis helpers ----------------------------------------------------

func seconds(_ s: Double) -> Int { Int(s * SR) }

// Generate `dur` seconds + fade tail, then make seamless with `fadeSec`.
func build(_ name: String, dur: Double, fadeSec: Double, peak: Double, seed: UInt64,
           _ gen: (inout [Double], inout RNG) -> Void) {
    let fade = seconds(fadeSec)
    var buf = [Double](repeating: 0, count: seconds(dur) + fade)
    var rng = RNG(seed)
    gen(&buf, &rng)
    var seam = makeSeamless(buf, fade: fade)
    normalize(&seam, peak: peak)
    writeWAV("\(outDir)/\(name).wav", seam)
    print("  \(name).wav  \(seam.count) samples")
}

// bell / struck tone with inharmonic partials and exponential decay
func addBell(_ buf: inout [Double], at: Int, freq: Double, dur: Double, amp: Double) {
    let len = seconds(dur)
    let partials: [(Double, Double)] = [(1.0, 1.0), (2.01, 0.5), (2.99, 0.32), (4.2, 0.2), (5.4, 0.12)]
    for i in 0..<len {
        let idx = at + i
        if idx >= buf.count { break }
        let t = Double(i) / SR
        let env = exp(-t * (3.0 + 6.0 / dur))
        var s = 0.0
        for (m, a) in partials { s += a * sin(2 * Double.pi * freq * m * t) }
        buf[idx] += softClip(s * 0.3) * env * amp
    }
}

// piano-ish struck note (few harmonics, faster decay, slight detune)
func addNote(_ buf: inout [Double], at: Int, freq: Double, dur: Double, amp: Double) {
    let len = seconds(dur)
    let harm: [(Double, Double)] = [(1, 1.0), (2, 0.4), (3, 0.18), (4, 0.08)]
    for i in 0..<len {
        let idx = at + i
        if idx >= buf.count { break }
        let t = Double(i) / SR
        let env = (t < 0.005 ? t / 0.005 : exp(-t * (2.4 + 3.0 / dur)))
        var s = 0.0
        for (m, a) in harm { s += a * sin(2 * Double.pi * freq * m * t) }
        buf[idx] += s * 0.22 * env * amp
    }
}

// low sine thump with soft attack
func addThump(_ buf: inout [Double], at: Int, freq: Double, dur: Double, amp: Double) {
    let len = seconds(dur)
    for i in 0..<len {
        let idx = at + i
        if idx >= buf.count { break }
        let t = Double(i) / SR
        let env = sin(Double.pi * min(1.0, t / dur))
        buf[idx] += sin(2 * Double.pi * freq * t) * env * amp
    }
}

// short bright crackle (for fire)
func addCrackle(_ buf: inout [Double], at: Int, amp: Double, rng: inout RNG) {
    let len = seconds(rng.range(0.004, 0.02))
    for i in 0..<len {
        let idx = at + i
        if idx >= buf.count { break }
        let t = Double(i) / Double(len)
        buf[idx] += rng.pm() * (1 - t) * amp
    }
}

let PENT: [Double] = [220.0, 246.94, 293.66, 329.63, 392.0, 440.0, 493.88, 587.33] // A minor pentatonic
let PENT_HI: [Double] = [523.25, 587.33, 698.46, 783.99, 880.0, 1046.5]

print("Generating audio into \(outDir) ...")

// 1. Rain Shower ------------------------------------------------------------
build("rain", dur: 22, fadeSec: 1.0, peak: 0.82, seed: 101) { buf, rng in
    let hp = HP(500), lp = LP(6500)
    var amp = 0.0
    for i in 0..<buf.count {
        let target = 0.5 + 0.2 * sin(Double(i) / SR * 0.4)
        amp += (target - amp) * 0.0002
        var s = hp.f(rng.pm())
        s = lp.f(s)
        buf[i] = s * amp
    }
    // droplets
    var i = 0
    while i < buf.count {
        if rng.d() < 0.5 { addBell(&buf, at: i, freq: rng.range(1800, 4200), dur: 0.03, amp: rng.range(0.05, 0.14)) }
        i += seconds(rng.range(0.01, 0.05))
    }
}

// 2. Heavy Rain (on roof) ---------------------------------------------------
build("heavyrain", dur: 22, fadeSec: 1.0, peak: 0.9, seed: 202) { buf, rng in
    let lp = LP(3800); let rumbleLP = LP(180)
    for i in 0..<buf.count {
        let hiss = lp.f(rng.pm())
        let rumble = rumbleLP.f(rng.pm()) * 0.5
        buf[i] = hiss * 0.7 + rumble
    }
    var i = 0
    while i < buf.count {
        if rng.d() < 0.6 { addCrackle(&buf, at: i, amp: rng.range(0.06, 0.16), rng: &rng) }
        i += seconds(rng.range(0.006, 0.02))
    }
}

// 3. Distant Thunder --------------------------------------------------------
build("thunder", dur: 26, fadeSec: 1.2, peak: 0.85, seed: 303) { buf, rng in
    // soft rain bed
    let lp = LP(3000)
    for i in 0..<buf.count { buf[i] = lp.f(rng.pm()) * 0.28 }
    // two long low rumbles
    for center in [seconds(7.0), seconds(18.0)] {
        let dur = seconds(rng.range(2.5, 4.0))
        let rl = LP(rng.range(90, 160))
        for i in 0..<dur {
            let idx = center + i
            if idx < 0 || idx >= buf.count { continue }
            let t = Double(i) / Double(dur)
            let env = sin(Double.pi * t) * (0.6 + 0.4 * sin(t * 30))
            buf[idx] += rl.f(rng.pm()) * env * 0.9
        }
    }
}

// 4. Gentle Wind ------------------------------------------------------------
build("wind", dur: 20, fadeSec: 1.4, peak: 0.7, seed: 404) { buf, rng in
    let bp1 = LP(700), hp = HP(200)
    for i in 0..<buf.count {
        let lfo = 0.45 + 0.35 * sin(Double(i) / SR * 0.5 + sin(Double(i) / SR * 0.13))
        var s = hp.f(rng.pm())
        s = bp1.f(s)
        buf[i] = s * lfo
    }
}

// 5. Campfire ---------------------------------------------------------------
build("campfire", dur: 22, fadeSec: 1.0, peak: 0.8, seed: 505) { buf, rng in
    let low = LP(320)
    for i in 0..<buf.count { buf[i] = low.f(rng.pm()) * 0.5 }
    var i = 0
    while i < buf.count {
        // clusters of crackles
        if rng.d() < 0.3 {
            let pops = Int(rng.range(1, 5))
            for _ in 0..<pops {
                let off = i + seconds(rng.range(0, 0.05))
                addCrackle(&buf, at: off, amp: rng.range(0.15, 0.5), rng: &rng)
            }
        }
        i += seconds(rng.range(0.02, 0.09))
    }
}

// 6. Ocean Waves ------------------------------------------------------------
build("ocean", dur: 24, fadeSec: 1.5, peak: 0.85, seed: 606) { buf, rng in
    let lp = LP(1400); let rumble = LP(150)
    let period = 9.0
    for i in 0..<buf.count {
        let t = Double(i) / SR
        let ph = (t.truncatingRemainder(dividingBy: period)) / period
        // swell: rise then wash
        let swell = pow(sin(Double.pi * ph), 1.6)
        let ph2 = ((t + 4.5).truncatingRemainder(dividingBy: period)) / period
        let swell2 = pow(sin(Double.pi * ph2), 1.6) * 0.7
        let bright = lp.f(rng.pm())
        let low = rumble.f(rng.pm()) * 0.4
        buf[i] = (bright * (swell + swell2) + low)
    }
}

// 7. Forest Stream ----------------------------------------------------------
build("stream", dur: 20, fadeSec: 1.0, peak: 0.78, seed: 707) { buf, rng in
    let hp = HP(700), lp = LP(5000)
    for i in 0..<buf.count {
        var s = hp.f(rng.pm()); s = lp.f(s)
        buf[i] = s * 0.5
    }
    // burbles
    var i = 0
    while i < buf.count {
        if rng.d() < 0.4 { addBell(&buf, at: i, freq: rng.range(600, 1600), dur: rng.range(0.04, 0.1), amp: rng.range(0.06, 0.16)) }
        i += seconds(rng.range(0.02, 0.08))
    }
}

// 8. Night Crickets ---------------------------------------------------------
build("crickets", dur: 20, fadeSec: 0.8, peak: 0.7, seed: 808) { buf, rng in
    let bed = LP(2000)
    for i in 0..<buf.count { buf[i] = bed.f(rng.pm()) * 0.05 }
    // several cricket voices, each a pulsed high tone
    for _ in 0..<5 {
        let freq = rng.range(3600, 4800)
        let rate = rng.range(22, 34)      // trill rate Hz
        let phase = rng.range(0, 6.28)
        let gain = rng.range(0.1, 0.22)
        for i in 0..<buf.count {
            let t = Double(i) / SR
            let trill = max(0.0, sin(2 * Double.pi * rate * t + phase))
            let onOff = (sin(t * 0.7 + phase) > -0.2) ? 1.0 : 0.0   // occasional pauses
            buf[i] += sin(2 * Double.pi * freq * t) * trill * trill * gain * onOff
        }
    }
}

// 9. Night Owl --------------------------------------------------------------
build("owl", dur: 24, fadeSec: 0.8, peak: 0.72, seed: 909) { buf, rng in
    let bed = LP(1800)
    for i in 0..<buf.count { buf[i] = bed.f(rng.pm()) * 0.06 }
    // faint crickets
    for _ in 0..<2 {
        let freq = rng.range(3800, 4400); let rate = rng.range(24, 30)
        for i in 0..<buf.count {
            let t = Double(i) / SR
            let tr = max(0.0, sin(2 * Double.pi * rate * t))
            buf[i] += sin(2 * Double.pi * freq * t) * tr * tr * 0.04
        }
    }
    // hoots: "hoo-hoo" pairs
    var t = rng.range(1.5, 3.0)
    while t < 22.5 {
        for k in 0..<2 {
            let at = seconds(t + Double(k) * 0.55)
            let f = rng.range(360, 430)
            let dur = seconds(0.4)
            for i in 0..<dur {
                let idx = at + i; if idx >= buf.count { break }
                let tt = Double(i) / SR
                let env = sin(Double.pi * min(1, tt / 0.4))
                let vib = 1 + 0.02 * sin(2 * Double.pi * 6 * tt)
                buf[idx] += (sin(2 * Double.pi * f * vib * tt) + 0.3 * sin(4 * Double.pi * f * tt)) * env * 0.5
            }
        }
        t += rng.range(4.5, 7.0)
    }
}

// 10. Morning Birds ---------------------------------------------------------
build("birds", dur: 22, fadeSec: 0.8, peak: 0.7, seed: 1010) { buf, rng in
    let bed = LP(2500)
    for i in 0..<buf.count { buf[i] = bed.f(rng.pm()) * 0.05 }
    var i = 0
    while i < buf.count {
        if rng.d() < 0.5 {
            // a chirp = few quick swept blips
            let blips = Int(rng.range(2, 6))
            var at = i
            let baseF = rng.range(2200, 4200)
            for _ in 0..<blips {
                let dur = seconds(rng.range(0.03, 0.08))
                let f0 = baseF * rng.range(0.9, 1.1)
                let f1 = f0 * rng.range(1.1, 1.6)
                for j in 0..<dur {
                    let idx = at + j; if idx >= buf.count { break }
                    let t = Double(j) / Double(dur)
                    let f = f0 + (f1 - f0) * t
                    let env = sin(Double.pi * t)
                    buf[idx] += sin(2 * Double.pi * f * (Double(j) / SR)) * env * 0.22
                }
                at += dur + seconds(rng.range(0.02, 0.06))
            }
        }
        i += seconds(rng.range(0.1, 0.5))
    }
}

// 11. Night Train -----------------------------------------------------------
build("train", dur: 24, fadeSec: 1.0, peak: 0.82, seed: 1111) { buf, rng in
    let railLP = LP(2200)
    for i in 0..<buf.count { buf[i] = railLP.f(rng.pm()) * 0.28 }
    // rhythmic chug: thumps every ~0.55s, clack pairs
    var t = 0.0
    while t < 23.5 {
        addThump(&buf, at: seconds(t), freq: rng.range(55, 70), dur: 0.14, amp: 0.5)
        // clack
        let cAt = seconds(t + 0.28)
        addCrackle(&buf, at: cAt, amp: 0.3, rng: &rng)
        addCrackle(&buf, at: cAt + seconds(0.04), amp: 0.22, rng: &rng)
        t += 0.55
    }
}

// 12. Wind Chimes -----------------------------------------------------------
build("chimes", dur: 24, fadeSec: 1.2, peak: 0.75, seed: 1212) { buf, rng in
    let bed = HP(400)
    for i in 0..<buf.count { buf[i] = bed.f(rng.pm()) * 0.015 }
    var t = rng.range(0.5, 2.0)
    while t < 22.0 {
        let cluster = Int(rng.range(1, 4))
        for _ in 0..<cluster {
            let f = PENT_HI[Int(rng.d() * Double(PENT_HI.count)) % PENT_HI.count]
            addBell(&buf, at: seconds(t + rng.range(0, 0.3)), freq: f, dur: rng.range(1.5, 3.0), amp: rng.range(0.2, 0.4))
        }
        t += rng.range(1.5, 4.0)
    }
}

// 13. Singing Bowl (continuous drone) ---------------------------------------
build("bowl", dur: 20, fadeSec: 2.0, peak: 0.7, seed: 1313) { buf, rng in
    let f0 = 174.0
    let partials: [(Double, Double, Double)] = [ (1.0, 1.0, 4.1), (2.74, 0.5, 5.3), (5.1, 0.28, 6.7), (8.9, 0.12, 3.3) ]
    for i in 0..<buf.count {
        let t = Double(i) / SR
        var s = 0.0
        for (m, a, beat) in partials {
            let beating = 1.0 + 0.06 * sin(2 * Double.pi * beat * 0.1 * t)
            s += a * sin(2 * Double.pi * f0 * m * t) * beating
        }
        let env = 0.8 + 0.2 * sin(2 * Double.pi * 0.08 * t)
        buf[i] = softClip(s * 0.25) * env
    }
}

// 14. Soft Piano (sparse random notes) --------------------------------------
build("piano", dur: 26, fadeSec: 1.2, peak: 0.72, seed: 1414) { buf, rng in
    var t = rng.range(0.3, 1.2)
    while t < 24.0 {
        let notes = Int(rng.range(1, 3))
        for _ in 0..<notes {
            let f = PENT[Int(rng.d() * Double(PENT.count)) % PENT.count]
            addNote(&buf, at: seconds(t + rng.range(0, 0.15)), freq: f, dur: rng.range(1.6, 2.8), amp: rng.range(0.35, 0.6))
        }
        t += rng.range(1.6, 3.2)
    }
}

// 15. White Noise -----------------------------------------------------------
build("whitenoise", dur: 12, fadeSec: 0.5, peak: 0.72, seed: 1515) { buf, rng in
    let lp = LP(9000)
    for i in 0..<buf.count { buf[i] = lp.f(rng.pm()) }
}

// 16. Brown Noise -----------------------------------------------------------
build("brownnoise", dur: 12, fadeSec: 0.5, peak: 0.85, seed: 1616) { buf, rng in
    var last = 0.0
    let lp = LP(60)
    for i in 0..<buf.count {
        last += rng.pm() * 0.02
        last = max(-1, min(1, last))
        last -= lp.f(last) * 0.02   // gentle leak toward center
        buf[i] = last
    }
}

// 17. Cozy Fan --------------------------------------------------------------
build("fan", dur: 14, fadeSec: 0.8, peak: 0.8, seed: 1717) { buf, rng in
    let lp = LP(900); let hum = 0.0
    for i in 0..<buf.count {
        let t = Double(i) / SR
        let air = lp.f(rng.pm())
        let blade = 0.85 + 0.15 * sin(2 * Double.pi * 12 * t)   // blade pass modulation
        let motor = 0.12 * sin(2 * Double.pi * 120 * t)
        buf[i] = air * blade * 0.8 + motor + hum
    }
}

// 18. Calm Heartbeat --------------------------------------------------------
build("heartbeat", dur: 12, fadeSec: 0.4, peak: 0.85, seed: 1818) { buf, rng in
    let bpm = 60.0
    let period = 60.0 / bpm
    var t = 0.2
    while t < 11.8 {
        addThump(&buf, at: seconds(t), freq: 60, dur: 0.13, amp: 0.9)          // lub
        addThump(&buf, at: seconds(t + 0.22), freq: 52, dur: 0.16, amp: 0.7)   // dub
        t += period
    }
    // faint low bed
    let lp = LP(120)
    for i in 0..<buf.count { buf[i] += lp.f(rng.pm()) * 0.04 }
}

// 19. Pond Frogs ------------------------------------------------------------
build("frogs", dur: 22, fadeSec: 0.8, peak: 0.7, seed: 1919) { buf, rng in
    // water bed
    let hp = HP(800), lp = LP(4000)
    for i in 0..<buf.count { var s = hp.f(rng.pm()); s = lp.f(s); buf[i] = s * 0.12 }
    // croaks: buzzy pitched bursts
    var t = rng.range(0.5, 1.5)
    while t < 21.0 {
        let f = rng.range(120, 260)
        let dur = rng.range(0.15, 0.35)
        let len = seconds(dur)
        let buzz = rng.range(28, 45)
        let at = seconds(t)
        for i in 0..<len {
            let idx = at + i; if idx >= buf.count { break }
            let tt = Double(i) / SR
            let env = sin(Double.pi * (Double(i) / Double(len)))
            let am = 0.5 + 0.5 * sin(2 * Double.pi * buzz * tt)
            buf[idx] += softClip(sin(2 * Double.pi * f * tt) * 1.4) * env * am * 0.4
        }
        t += rng.range(0.5, 2.2)
    }
}

// 20. Rustling Leaves -------------------------------------------------------
build("leaves", dur: 20, fadeSec: 1.2, peak: 0.68, seed: 2020) { buf, rng in
    let hp = HP(1200), lp = LP(7000)
    for i in 0..<buf.count {
        let t = Double(i) / SR
        // gusts
        let gust = max(0.0, sin(t * 0.6 + sin(t * 0.21)) )
        var s = hp.f(rng.pm()); s = lp.f(s)
        buf[i] = s * (0.15 + 0.85 * gust)
    }
}

print("Done.")
