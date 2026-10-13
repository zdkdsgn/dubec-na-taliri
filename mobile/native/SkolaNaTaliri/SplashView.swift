import SwiftUI

/// Úvodní animace: dýchající záře, ikona s pružným příjezdem a lesklý přejezd.
struct SplashView: View {
    @State private var glow = false
    @State private var iconIn = false
    @State private var nameIn = false
    @State private var shine: CGFloat = -1.4

    var body: some View {
        ZStack {
            T.bg.ignoresSafeArea()
            Circle()
                .fill(RadialGradient(colors: [T.accent.opacity(0.4), .clear], center: .center, startRadius: 0, endRadius: 130))
                .frame(width: 280, height: 280)
                .scaleEffect(glow ? 1.1 : 0.84).opacity(glow ? 0.85 : 0.35)
            VStack(spacing: 16) {
                Image("SplashIcon").resizable().frame(width: 92, height: 92)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay {
                        GeometryReader { g in
                            LinearGradient(colors: [.clear, .white.opacity(0.55), .clear], startPoint: .leading, endPoint: .trailing)
                                .frame(width: g.size.width * 0.6).rotationEffect(.degrees(18))
                                .offset(x: g.size.width * shine)
                        }.clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    }
                    .shadow(color: .black.opacity(0.25), radius: 18, y: 10)
                    .scaleEffect(iconIn ? 1 : 0.55).opacity(iconIn ? 1 : 0)
                Text("Škola na talíři").font(.system(size: 16, weight: .bold)).foregroundStyle(T.ink2)
                    .opacity(nameIn ? 1 : 0).offset(y: nameIn ? 0 : 6)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) { glow = true }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.62)) { iconIn = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) { nameIn = true }
            withAnimation(.easeInOut(duration: 0.9).delay(0.45).repeatForever(autoreverses: false)) { shine = 1.6 }
        }
    }
}
