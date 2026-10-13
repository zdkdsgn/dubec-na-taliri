import SwiftUI

/// Karty naskakují po sobě (stejný efekt jako naskakejKarty() na webu).
struct StaggerIn: ViewModifier {
    let index: Int
    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var reduce
    func body(content: Content) -> some View {
        content
            .opacity(shown || reduce ? 1 : 0)
            .offset(y: shown || reduce ? 0 : 14)
            .scaleEffect(shown || reduce ? 1 : 0.985)
            .onAppear {
                guard !shown else { return }
                withAnimation(.spring(response: 0.5, dampingFraction: 0.82).delay(Double(index) * 0.05)) { shown = true }
            }
    }
}
extension View { func staggerIn(_ i: Int) -> some View { modifier(StaggerIn(index: i)) } }

/// Krátké "pop" při zapnutí (hvězdička, hodnocení, poznámka).
struct Pop: ViewModifier {
    let trigger: Bool
    @State private var scale: CGFloat = 1
    func body(content: Content) -> some View {
        content.scaleEffect(scale).onChange(of: trigger) { _, _ in
            withAnimation(.spring(response: 0.18, dampingFraction: 0.45)) { scale = 1.25 }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6).delay(0.12)) { scale = 1 }
        }
    }
}
extension View { func pop(_ trigger: Bool) -> some View { modifier(Pop(trigger: trigger)) } }

struct Badge: View {
    enum Kind { case warn, warnSoft, muted, lead }
    let text: String
    let kind: Kind
    var body: some View {
        let (fg, bg): (Color, Color) = {
            switch kind {
            case .warn: return (T.red, T.redBg)
            case .warnSoft: return (T.amber, T.amberBg)
            case .muted: return (T.ink3, T.track)
            case .lead: return (T.accent, T.accentSoft)
            }
        }()
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(fg)
            .padding(.horizontal, 9).padding(.vertical, 3)
            .background(bg, in: Capsule())
    }
}

struct AllergenChip: View {
    let ids: [Int]
    let tint: Color
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "leaf.fill").font(.system(size: 10))
            Text(ids.map(String.init).joined(separator: ", ")).font(.system(size: 12, weight: .semibold))
            Image(systemName: "info.circle").font(.system(size: 11)).opacity(0.7)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(T.track, in: Capsule())
    }
}

struct MealIcon: View {
    let course: Course
    var size: CGFloat = 44
    var body: some View {
        let tone = T.tone(course.tone)
        Image(systemName: course.symbol)
            .font(.system(size: size * 0.42, weight: .medium))
            .foregroundStyle(tone.fg)
            .frame(width: size, height: size)
            .background(tone.bg, in: RoundedRectangle(cornerRadius: size * 0.32, style: .continuous))
    }
}

struct MealCard: View {
    @EnvironmentObject var state: AppState
    let meal: Chod
    let date: String
    let ocas: [String]
    let onTap: () -> Void

    var body: some View {
        let hits = state.hits(meal)
        let inMain = !hits.isEmpty && state.hitsInMain(meal)
        let outside = !hits.isEmpty && !inMain
        let disliked = hits.isEmpty && state.isDisliked(meal)
        let lead = (meal.c == "obed" || meal.c == "obed2") && hits.isEmpty && !disliked
        let course = Course.of(meal.c)
        let desc = MenuLogic.vlastniPopis(meal, ocas: ocas)
        let accent: Color = inMain ? T.red : outside ? T.amber : lead ? T.accent : T.ink
        let past = date < Cal.today

        Button(action: onTap) {
            HStack(alignment: .top, spacing: 14) {
                MealIcon(course: course)
                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(course.label.uppercased())
                            .font(.system(size: 11, weight: .bold)).tracking(1).foregroundStyle(T.ink3)
                        Spacer(minLength: 6)
                        if inMain { Badge(text: "Alergen \(hits.map(String.init).joined(separator: ", "))", kind: .warn) }
                        else if outside { Badge(text: "Alergen \(hits.map(String.init).joined(separator: ", ")) · \(state.hitPlaces(meal).joined(separator: ", "))", kind: .warnSoft) }
                        else if disliked { Badge(text: "Nemá rád", kind: .muted) }
                        else if meal.c == "obed" { Badge(text: "Oběd", kind: .lead) }
                        else if meal.c == "obed2" { Badge(text: "Oběd II", kind: .lead) }
                    }
                    Text(meal.n)
                        .font(.system(size: 19, weight: .bold)).tracking(-0.3)
                        .foregroundStyle(accent).multilineTextAlignment(.leading)
                    if !desc.isEmpty {
                        Text(desc).font(.system(size: 15)).foregroundStyle(T.ink2).multilineTextAlignment(.leading)
                    }
                    if !meal.a.isEmpty {
                        AllergenChip(ids: meal.a, tint: inMain ? T.red : outside ? T.amber : T.ink2).padding(.top, 3)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .card(fill: inMain ? T.redBg : outside ? T.amberBg : lead ? T.accentSoft : T.card,
                  stroke: inMain ? T.red.opacity(0.35) : outside ? T.amber.opacity(0.35) : lead ? T.accent.opacity(0.25) : T.cardBorder)
            .opacity(past ? 0.6 : (disliked ? 0.75 : 1))
            .saturation(past ? 0.5 : 1)
        }
        .buttonStyle(PressableStyle())
    }
}

struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct OcasCard: View {
    let items: [String]
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("NA VÝBĚR").font(.system(size: 11, weight: .bold)).tracking(1).foregroundStyle(T.ink3)
            Text(items.joined(separator: " · ")).font(.system(size: 14.5)).foregroundStyle(T.ink2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(T.track, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
            .strokeBorder(T.cardBorder, style: StrokeStyle(lineWidth: 1, dash: [5, 4])))
    }
}

/// Stav výdeje: pulzující tečka / "již vydáno" / čas výdeje.
struct ServeLine: View {
    let date: String
    let vydej: String
    @State private var pulse = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { _ in
            let stav = MenuLogic.vydejStav(date: date, vydej: vydej)
            HStack(spacing: 7) {
                switch stav {
                case .bezi:
                    ZStack {
                        Circle().fill(T.accent.opacity(0.35)).frame(width: 7, height: 7)
                            .scaleEffect(pulse ? 2.6 : 1).opacity(pulse ? 0 : 1)
                        Circle().fill(T.accent).frame(width: 7, height: 7).scaleEffect(pulse ? 1 : 1.2)
                    }
                    .onAppear { withAnimation(.easeOut(duration: 1.6).repeatForever(autoreverses: false)) { pulse = true } }
                    Text("Právě se vydává ·").foregroundStyle(T.ink2)
                case .po:
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 13)).foregroundStyle(T.ink3.opacity(0.7))
                    Text("Již vydáno ·").foregroundStyle(T.ink3)
                default:
                    Text("Výdej").foregroundStyle(T.ink2)
                }
                Text(vydej).foregroundStyle(stav == .po ? T.ink3 : T.ink2)
            }
            .font(.system(size: 13, weight: .medium)).monospacedDigit()
        }
    }
}
