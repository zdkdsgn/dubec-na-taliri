import SwiftUI

/// Úvod při prvním spuštění: tři krátké obrazovky, pak výběr školy.
struct OnboardingView: View {
    let onDone: () -> Void
    @State private var page = 0
    private let last = 2

    var body: some View {
        ZStack {
            AmbientBackground()
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button("Přeskočit") { onDone() }
                        .font(.system(size: 15, weight: .semibold)).foregroundStyle(T.ink2)
                        .opacity(page == last ? 0 : 1)
                }
                .padding(.horizontal, 24).padding(.top, 12).frame(height: 44)

                TabView(selection: $page) {
                    slide(0, title: "Co je dnes k obědu?",
                          text: "Jídelníček vaší školy nebo školky na jednom místě – bez přihlašování a bez hesel.") { mealMock }
                    slide(1, title: "Hlídejte alergeny",
                          text: "Nastavte, co dítě nesmí. Appka označí každé jídlo, které to obsahuje.") { allergenMock }
                    slide(2, title: "Vždy po ruce",
                          text: "Upozornění na nový jídelníček, widget na ploše a hodinky Apple Watch.") { notifyMock }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                HStack(spacing: 8) {
                    ForEach(0...last, id: \.self) { i in
                        Capsule().fill(i == page ? T.accent : T.ink3.opacity(0.35))
                            .frame(width: i == page ? 22 : 8, height: 8)
                            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: page)
                    }
                }.padding(.bottom, 22)

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    if page < last { withAnimation(.snappy) { page += 1 } } else { onDone() }
                } label: {
                    Text(page < last ? "Dál" : "Vybrat školu").font(.system(size: 17, weight: .bold))
                        .foregroundStyle(T.onAccent).frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(T.accent, in: Capsule())
                        .shadow(color: T.accent.opacity(0.3), radius: 12, y: 5)
                }
                .buttonStyle(PressableStyle())
                .padding(.horizontal, 24).padding(.bottom, 24)
            }
        }
    }

    private func slide<M: View>(_ i: Int, title: String, text: String, @ViewBuilder mock: () -> M) -> some View {
        VStack(spacing: 28) {
            Spacer(minLength: 0)
            mock().padding(.horizontal, 28)
            VStack(spacing: 10) {
                Text(title).font(.system(size: 30, weight: .bold)).tracking(-0.8).foregroundStyle(T.ink)
                    .multilineTextAlignment(.center)
                Text(text).font(.system(size: 17)).foregroundStyle(T.ink2).multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }.padding(.horizontal, 32)
            Spacer(minLength: 0)
        }
        .tag(i)
    }

    // MARK: ilustrace (malé ukázky skutečných prvků appky)

    private var mealMock: some View {
        VStack(spacing: 12) {
            row(icon: "cup.and.saucer", tone: .orange, label: "POLÉVKA", name: "Zeleninová s drožďovými knedlíčky", chip: "1, 3, 7, 9")
            row(icon: "fork.knife", tone: .green, label: "HLAVNÍ CHOD", name: "Svíčková na smetaně", chip: "1, 3, 7", highlight: true)
        }
    }

    private var allergenMock: some View {
        VStack(spacing: 12) {
            row(icon: "fork.knife", tone: .green, label: "HLAVNÍ CHOD", name: "Kuřecí řízek, brambory", chip: "1, 3")
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("HLAVNÍ CHOD II").font(.system(size: 11, weight: .bold)).tracking(1).foregroundStyle(T.ink3)
                    Spacer()
                    Text("Alergen 7").font(.system(size: 11, weight: .bold)).foregroundStyle(T.red)
                        .padding(.horizontal, 9).padding(.vertical, 3).background(T.redBg, in: Capsule())
                }
                Text("Smažený sýr, tatarka").font(.system(size: 19, weight: .bold)).foregroundStyle(T.red)
            }
            .padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .card(fill: T.redBg, stroke: T.red.opacity(0.35))
        }
    }

    private var notifyMock: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image("SplashIcon").resizable().frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Škola na talíři").font(.system(size: 14, weight: .bold)).foregroundStyle(T.ink)
                    Text("Nový jídelníček na příští týden").font(.system(size: 14)).foregroundStyle(T.ink2)
                }
                Spacer(minLength: 0)
            }.padding(14).card()
            HStack(spacing: 12) {
                tile("square.grid.2x2", "Widget")
                tile("applewatch", "Hodinky")
                tile("star.fill", "Oblíbené")
            }
        }
    }

    private func tile(_ symbol: String, _ label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: symbol).font(.system(size: 22, weight: .semibold)).foregroundStyle(T.accent).frame(height: 28)
            Text(label).font(.system(size: 13, weight: .semibold)).foregroundStyle(T.ink)
        }.frame(maxWidth: .infinity).padding(.vertical, 16).card()
    }

    private func row(icon: String, tone: Tone, label: String, name: String, chip: String, highlight: Bool = false) -> some View {
        let t = T.tone(tone)
        return HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon).font(.system(size: 20, weight: .semibold)).foregroundStyle(t.fg)
                .frame(width: 46, height: 46).background(t.bg, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            VStack(alignment: .leading, spacing: 5) {
                Text(label).font(.system(size: 11, weight: .bold)).tracking(1).foregroundStyle(T.ink3)
                Text(name).font(.system(size: 18, weight: .bold)).foregroundStyle(highlight ? T.accent : T.ink)
                    .multilineTextAlignment(.leading)
                HStack(spacing: 5) {
                    Image(systemName: "leaf").font(.system(size: 11))
                    Text(chip).font(.system(size: 12, weight: .semibold)).monospacedDigit()
                }
                .foregroundStyle(T.ink2).padding(.horizontal, 9).padding(.vertical, 4).background(T.track, in: Capsule())
            }
            Spacer(minLength: 0)
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .card(fill: highlight ? T.accentSoft : T.card, stroke: highlight ? T.accent.opacity(0.25) : T.cardBorder)
    }
}
