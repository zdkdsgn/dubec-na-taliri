import SwiftUI

struct TydenView: View {
    @EnvironmentObject var state: AppState
    @State private var open: Set<String> = [Cal.today]
    @State private var selectedMeal: (Chod, String)?

    var body: some View {
        let mon = Cal.monday(state.selectedDate)
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Týden \(Cal.short(mon)) – \(Cal.short(Cal.add(mon, days: 4)))\(state.multiGroup ? " · " + (state.group == "ms" ? "MŠ" : "ZŠ") : "")")
                            .font(.system(size: 12, weight: .bold)).tracking(1).textCase(.uppercase).foregroundStyle(T.ink3)
                        Text(state.schoolTitle).font(.system(size: 28, weight: .bold)).tracking(-0.8)
                    }
                    Spacer()
                    ShareLink(item: weekText(mon)) {
                        Image(systemName: "square.and.arrow.up").foregroundStyle(T.ink2)
                            .frame(width: 38, height: 38).glassEffect(.regular.interactive(), in: Circle())
                    }
                }
                .padding(.top, 14)

                ForEach(0..<5, id: \.self) { i in
                    let d = Cal.add(mon, days: i)
                    dayBox(d).staggerIn(i)
                }
            }
            .padding(.horizontal, 18).padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .refreshable { await state.refresh() }
        .sheet(item: Binding(get: { selectedMeal.map { Sel(meal: $0.0, date: $0.1) } }, set: { selectedMeal = $0.map { ($0.meal, $0.date) } })) { s in
            MealSheet(meal: s.meal, date: s.date).environmentObject(state)
        }
    }

    private struct Sel: Identifiable { let meal: Chod; let date: String; var id: String { date + meal.id } }

    private func dayBox(_ d: String) -> some View {
        let list = state.meals(d)
        let main = list.first(where: { $0.c == "obed" })
        let isOpen = open.contains(d)
        let ocas = MenuLogic.spolecnyOcas(list)
        return VStack(spacing: 0) {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                    if isOpen { open.remove(d) } else { open.insert(d) }
                }
            } label: {
                HStack(spacing: 14) {
                    Text("\(Cal.day(d))").font(.system(size: 20, weight: .bold)).monospacedDigit()
                        .foregroundStyle(d == Cal.today ? T.onAccent : T.ink)
                        .frame(width: 46, height: 46)
                        .background(d == Cal.today ? T.accent : T.track, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Cal.dowName(d)).font(.system(size: 17, weight: .bold)).foregroundStyle(T.ink)
                        Text(main?.n ?? "Bez jídelníčku").font(.system(size: 14)).foregroundStyle(T.ink2).lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(T.ink3)
                        .rotationEffect(.degrees(isOpen ? 90 : 0))
                }
                .padding(14)
            }.buttonStyle(.plain)

            if isOpen && !list.isEmpty {
                VStack(spacing: 10) {
                    ForEach(list) { m in
                        MealCard(meal: m, date: d, ocas: ocas) { selectedMeal = (m, d) }
                    }
                    if !ocas.isEmpty { OcasCard(items: ocas) }
                }
                .padding(.horizontal, 10).padding(.bottom, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(maxWidth: .infinity)
        .card()
    }

    private func weekText(_ mon: String) -> String {
        var t = "🍽️ Jídelníček \(state.schoolTitle)\n\(Cal.short(mon))–\(Cal.short(Cal.add(mon, days: 4)))\n"
        for i in 0..<5 {
            let d = Cal.add(mon, days: i); let list = state.meals(d)
            if list.isEmpty { continue }
            t += "\n\(Cal.dowName(d)) \(Cal.short(d))\n" + list.map { "• \(Course.of($0.c).label): \($0.n)" }.joined(separator: "\n") + "\n"
        }
        return t
    }
}
