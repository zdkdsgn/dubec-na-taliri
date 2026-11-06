import SwiftUI

/// Paleta z iPhonu (Theme.swift), jen tmavá varianta – hodinky jsou vždy tmavé.
enum W {
    private static func hex(_ v: UInt32, _ a: Double = 1) -> Color {
        Color(.sRGB, red: Double((v >> 16) & 0xFF) / 255, green: Double((v >> 8) & 0xFF) / 255, blue: Double(v & 0xFF) / 255, opacity: a)
    }
    static let bg = hex(0x0B120E)
    static let card = hex(0x131C17)
    static let ink = hex(0xECF3EE)
    static let ink2 = hex(0x93A79C)
    static let ink3 = hex(0x728979)
    static let accent = hex(0x4FCB8E)
    static let accentSoft = hex(0x4FCB8E, 0.14)
    static let amber = hex(0xEBBB63)

    static func tone(_ t: Tone) -> (fg: Color, bg: Color) {
        switch t {
        case .amber: return (hex(0xEBBB63), hex(0xEBBB63, 0.14))
        case .orange: return (hex(0xF09070), hex(0xF09070, 0.14))
        case .green: return (hex(0x4FCB8E), hex(0x4FCB8E, 0.14))
        case .blue: return (hex(0x82A8F5), hex(0x82A8F5, 0.14))
        case .purple: return (hex(0xA895EE), hex(0xA895EE, 0.14))
        }
    }
}

/// Jemný zelený přísvit pod obsahem (stejný nápad jako AmbientBackground na iPhonu).
struct WatchAmbient: View {
    var body: some View {
        ZStack {
            W.bg
            Circle().fill(W.accent.opacity(0.18)).frame(width: 170).blur(radius: 40).offset(x: -60, y: -110)
            Circle().fill(W.amber.opacity(0.08)).frame(width: 130).blur(radius: 40).offset(x: 80, y: -30)
        }
    }
}

struct WatchCourseIcon: View {
    let course: Course
    var size: CGFloat = 28
    var body: some View {
        let t = W.tone(course.tone)
        Image(systemName: course.symbol)
            .font(.system(size: size * 0.44, weight: .medium))
            .foregroundStyle(t.fg)
            .frame(width: size, height: size)
            .background(t.bg, in: RoundedRectangle(cornerRadius: size * 0.32, style: .continuous))
    }
}
