import SwiftUI
import UIKit

private func dyn(_ light: UInt32, _ dark: UInt32, lightAlpha: Double = 1, darkAlpha: Double = 1) -> Color {
    Color(UIColor { t in
        let hex = t.userInterfaceStyle == .dark ? dark : light
        let a = t.userInterfaceStyle == .dark ? darkAlpha : lightAlpha
        return UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                       blue: CGFloat(hex & 0xFF) / 255, alpha: a)
    })
}

enum T {
    static let bg = dyn(0xF6FAF7, 0x0B120E)
    static let ink = dyn(0x10201A, 0xECF3EE)
    static let ink2 = dyn(0x5E7268, 0x93A79C)
    static let ink3 = dyn(0x5F7166, 0x728979)
    static let accent = dyn(0x1E7A55, 0x4FCB8E)
    static let accentSoft = dyn(0xEAF4EE, 0x4FCB8E, darkAlpha: 0.12)
    static let onAccent = dyn(0xFFFFFF, 0x0B120E)
    static let card = dyn(0xFFFFFF, 0x131C17)
    static let cardBorder = dyn(0x10281C, 0xFFFFFF, lightAlpha: 0.06, darkAlpha: 0.07)
    static let track = dyn(0xEEF3F0, 0x182119)
    static let amber = dyn(0xC98A12, 0xEBBB63)
    static let amberBg = dyn(0xFDF3E0, 0xEBBB63, darkAlpha: 0.13)
    static let red = dyn(0xC4384F, 0xEE7B90)
    static let redBg = dyn(0xFBEBEE, 0xEE7B90, darkAlpha: 0.13)

    static func tone(_ t: Tone) -> (fg: Color, bg: Color) {
        switch t {
        case .amber: return (dyn(0xC98A12, 0xEBBB63), dyn(0xFDF3E0, 0xEBBB63, darkAlpha: 0.13))
        case .orange: return (dyn(0xD2643C, 0xF09070), dyn(0xFCEDE6, 0xF09070, darkAlpha: 0.13))
        case .green: return (dyn(0x1E7A55, 0x4FCB8E), dyn(0xE7F3EB, 0x4FCB8E, darkAlpha: 0.13))
        case .blue: return (dyn(0x3568C6, 0x82A8F5), dyn(0xE9F0FC, 0x82A8F5, darkAlpha: 0.13))
        case .purple: return (dyn(0x6F55C0, 0xA895EE), dyn(0xEFEBFA, 0xA895EE, darkAlpha: 0.13))
        }
    }
}

struct CardStyle: ViewModifier {
    var fill: Color = T.card
    var stroke: Color = T.cardBorder
    func body(content: Content) -> some View {
        content
            .background(fill, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(stroke, lineWidth: 1))
            .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 6)
    }
}
extension View {
    func card(fill: Color = T.card, stroke: Color = T.cardBorder) -> some View {
        modifier(CardStyle(fill: fill, stroke: stroke))
    }
}

/// Jemný barevný přísvit pod obsahem (stejný nápad jako .ambient na webu).
struct AmbientBackground: View {
    var body: some View {
        ZStack {
            T.bg
            Circle().fill(T.accent.opacity(0.16)).frame(width: 320).blur(radius: 70).offset(x: -110, y: -300)
            Circle().fill(T.amber.opacity(0.10)).frame(width: 260).blur(radius: 70).offset(x: 150, y: -120)
        }
        .ignoresSafeArea()
    }
}
