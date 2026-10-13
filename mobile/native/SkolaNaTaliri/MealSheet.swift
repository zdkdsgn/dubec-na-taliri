import SwiftUI

struct MealSheet: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss
    let meal: Chod
    let date: String

    var body: some View {
        let course = Course.of(meal.c)
        let rating = state.ratings[state.ratingKey(date, meal)]
        let disliked = state.isDisliked(meal)

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    HStack(spacing: 9) {
                        MealIcon(course: course, size: 28)
                        Text("\(course.label) · \(Cal.dowName(date)) \(Cal.short(date))\(state.vydej(date).map { " · \($0)" } ?? "")")
                            .font(.system(size: 11, weight: .bold)).tracking(0.8).textCase(.uppercase).foregroundStyle(T.ink2)
                    }
                    Spacer()
                    ShareLink(item: "🍽️ \(meal.n)\n\(course.label) · \(Cal.dowName(date)) \(Cal.short(date)) · \(state.schoolTitle)") {
                        Image(systemName: "square.and.arrow.up").foregroundStyle(T.ink2)
                            .frame(width: 36, height: 36).background(T.track, in: Circle())
                    }
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(meal.n).font(.system(size: 26, weight: .bold)).tracking(-0.6)
                    if !meal.d.isEmpty { Text(meal.d).font(.system(size: 15)).foregroundStyle(T.ink2) }
                }

                section("Alergeny") {
                    if meal.a.isEmpty {
                        Text("Bez uvedených alergenů.").foregroundStyle(T.ink2)
                    } else {
                        ForEach(meal.a, id: \.self) { n in
                            let a = Allergen.named(n)
                            let hit = state.allergenFilter.contains(n)
                            HStack(spacing: 12) {
                                Text("\(n)").font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(hit ? T.red : T.accent)
                                    .frame(width: 30, height: 30).background((hit ? T.redBg : T.accentSoft), in: Circle())
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(a?.name ?? "Alergen \(n)").font(.system(size: 15, weight: .semibold))
                                    Text(meal.p.map { parts in parts.filter { $0.a.contains(n) }.map { "\($0.l): \($0.n)" }.joined(separator: " · ") } ?? a?.detail ?? "")
                                        .font(.system(size: 13)).foregroundStyle(T.ink2)
                                }
                                Spacer()
                            }
                            .padding(12).card(fill: hit ? T.redBg : T.card, stroke: hit ? T.red.opacity(0.3) : T.cardBorder)
                        }
                    }
                }

                if let p = meal.p, p.count > 1 {
                    section("Co je na talíři") {
                        ForEach(Array(p.enumerated()), id: \.offset) { _, x in
                            HStack(alignment: .top, spacing: 12) {
                                Text(x.l).font(.system(size: 11, weight: .bold)).foregroundStyle(T.ink3)
                                    .frame(width: 64, alignment: .leading).padding(.top, 3)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(x.n).font(.system(size: 15, weight: .semibold))
                                    if !x.a.isEmpty {
                                        Text("alergeny \(x.a.map(String.init).joined(separator: ", "))")
                                            .font(.system(size: 13)).foregroundStyle(T.ink2)
                                    }
                                }
                                Spacer()
                            }
                            .padding(12).card()
                        }
                    }
                }

                section("Chutnalo dětem?") {
                    HStack(spacing: 10) {
                        rateButton("👍", "Super", 1, rating)
                        rateButton("😐", "Ujde", 0, rating)
                        rateButton("👎", "Nic moc", -1, rating)
                    }
                }

                section("Osobní poznámka") {
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        state.toggleDislike(meal)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: disliked ? "xmark.circle.fill" : "xmark.circle")
                            Text("Dítě tohle nemá rádo").font(.system(size: 15, weight: .semibold))
                            Spacer()
                        }
                        .foregroundStyle(disliked ? T.ink : T.ink2)
                        .padding(14)
                        .background(disliked ? T.track : T.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(disliked ? T.ink3 : T.cardBorder))
                        .pop(disliked)
                    }.buttonStyle(PressableStyle())
                }
            }
            .padding(22)
        }
        .background(T.bg)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(30)
    }

    private func section<C: View>(_ title: String, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased()).font(.system(size: 11.5, weight: .bold)).tracking(1.1).foregroundStyle(T.ink3)
            content()
        }
    }

    private func rateButton(_ emoji: String, _ label: String, _ v: Int, _ current: Int?) -> some View {
        let on = current == v
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            state.rate(date, meal, v)
        } label: {
            VStack(spacing: 4) {
                Text(emoji).font(.system(size: 26))
                Text(label).font(.system(size: 12, weight: .semibold)).foregroundStyle(on ? T.accent : T.ink2)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 12)
            .background(on ? T.accentSoft : T.track, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(on ? T.accent.opacity(0.5) : .clear, lineWidth: 1.5))
            .pop(on)
        }.buttonStyle(PressableStyle())
    }
}
