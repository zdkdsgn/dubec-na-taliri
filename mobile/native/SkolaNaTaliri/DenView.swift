import SwiftUI

struct DenView: View {
    @EnvironmentObject var state: AppState
    @Binding var showSchools: Bool
    @Binding var tab: Int
    @State private var selectedMeal: Chod?
    @State private var swiping = false
    @State private var showSearch = false
    @Namespace private var thumb
    @Namespace private var favThumb

    var body: some View {
        let date = state.selectedDate
        let list = state.meals(date)
        let ocas = MenuLogic.spolecnyOcas(list)

        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header
                favSwitcher
                weekBar
                dayStrip
                if state.multiGroup { groupPicker }
                notes

                VStack(alignment: .leading, spacing: 14) {
                    dayTitle(date)
                    if list.isEmpty {
                        emptyState
                    } else {
                        ForEach(Array(list.enumerated()), id: \.element.id) { i, m in
                            MealCard(meal: m, date: date, ocas: ocas) { if !swiping { selectedMeal = m } }
                                .staggerIn(i)
                        }
                        if !ocas.isEmpty { OcasCard(items: ocas).staggerIn(list.count) }
                    }
                    tomorrowCard
                    Text("Neoficiální přehled pro rodiče.\nZměna jídelníčku vyhrazena.")
                        .font(.system(size: 12.5)).foregroundStyle(T.ink3)
                        .multilineTextAlignment(.center).frame(maxWidth: .infinity).padding(.top, 8)
                }
                .id(date)
                .transition(.asymmetric(
                    insertion: .move(edge: state.forward ? .trailing : .leading).combined(with: .opacity),
                    removal: .move(edge: state.forward ? .leading : .trailing).combined(with: .opacity)))
            }
            .padding(.horizontal, 18).padding(.top, 8).padding(.bottom, 24)
            .simultaneousGesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { v in if abs(v.translation.width) > 10 { swiping = true } }
                    .onEnded { v in
                        // klepnutí na kartu se po swipu spustí taky – krátce ho ignorujeme
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { swiping = false }
                        guard abs(v.translation.width) > 70, abs(v.translation.width) > abs(v.translation.height) * 1.5 else { return }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        state.step(v.translation.width < 0 ? 1 : -1)
                    })
        }
        .scrollIndicators(.hidden)
        .refreshable { await state.refresh() }
        .sheet(isPresented: $showSearch) {
            SearchSheet { d in state.select(d) }.environmentObject(state)
        }
        .sheet(item: $selectedMeal) { m in
            MealSheet(meal: m, date: date).environmentObject(state)
        }
        .overlay { if state.loading && state.data.days.isEmpty { ProgressView() } }
    }

    // MARK: části

    private var header: some View {
        Button { showSchools = true } label: {
            HStack(spacing: 10) {
                Circle().fill(T.accent).frame(width: 8, height: 8)
                (Text(state.schoolTitle + " ").font(.system(size: 20, weight: .bold)).foregroundColor(T.ink)
                    + Text(Image(systemName: "chevron.down")).font(.system(size: 11, weight: .bold)).foregroundColor(T.ink3))
                    .tracking(-0.4).multilineTextAlignment(.leading).lineLimit(2).padding(.trailing, 96)
                Spacer()
            }
            .padding(.top, 14).padding(.bottom, 4)
        }.buttonStyle(.plain)
        .overlay(alignment: .trailing) {
            HStack(spacing: 8) {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { state.toggleFavorite(state.active) }
                } label: {
                    Image(systemName: state.activeIsFavorite ? "star.fill" : "star").font(.system(size: 15, weight: .medium))
                        .foregroundStyle(state.activeIsFavorite ? T.amber : T.ink2)
                        .frame(width: 38, height: 38).glassEffect(.regular.interactive(), in: Circle())
                        .pop(state.activeIsFavorite)
                }
                Button { showSearch = true } label: {
                    Image(systemName: "magnifyingglass").font(.system(size: 15, weight: .medium)).foregroundStyle(T.ink2)
                        .frame(width: 38, height: 38).glassEffect(.regular.interactive(), in: Circle())
                }
            }.padding(.top, 10)
        }
    }

    @ViewBuilder private var notes: some View {
        if let days = state.staleDays, let u = state.data.updated {
            note(icon: "exclamationmark.triangle", tint: T.amber, bg: T.amberBg,
                 title: "Data možná nejsou aktuální.",
                 text: "Naposledy staženo \(Cal.day(Cal.iso(u))). \(Cal.month(Cal.iso(u))). (před \(days) dny) – než se podle jídelníčku rozhodnete, ověřte to prosím na webu jídelny.")
        }
        if state.active.skutecna_data == false {
            note(icon: "info.circle", tint: T.ink2, bg: T.track,
                 title: "Ukázková data.", text: "Tahle jídelna zatím nezveřejnila skutečný jídelníček, takže vidíte jen ukázku.")
        }
    }

    private func note(icon: String, tint: Color, bg: Color, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon).foregroundStyle(tint).padding(.top, 2)
            Text("\(title) ").font(.system(size: 13.5, weight: .bold)).foregroundStyle(T.ink)
                + Text(text).font(.system(size: 13.5)).foregroundStyle(T.ink2)
        }
        .padding(12).frame(maxWidth: .infinity, alignment: .leading)
        .background(bg, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder private var favSwitcher: some View {
        let favs = state.favoriteSchools
        if favs.count >= 2 || (favs.count == 1 && favs[0].id != state.active.id) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(favs) { s in
                        let on = s.id == state.active.id
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            Task { withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {}; await state.choose(s) }
                        } label: {
                            Text(s.jmeno).font(.system(size: 14, weight: .semibold)).lineLimit(1)
                                .frame(maxWidth: 190)
                                .foregroundStyle(on ? T.onAccent : T.ink2)
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background {
                                    if on { Capsule().fill(T.accent).matchedGeometryEffect(id: "favthumb", in: favThumb) }
                                    else { Capsule().fill(T.track) }
                                }
                        }.buttonStyle(.plain)
                    }
                    Button { showSchools = true } label: {
                        Image(systemName: "plus").font(.system(size: 13, weight: .bold)).foregroundStyle(T.ink2)
                            .frame(width: 34, height: 34).background(T.track, in: Circle())
                    }.buttonStyle(.plain)
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: state.active.id)
        }
    }

    private var weekBar: some View {
        let mon = Cal.monday(state.selectedDate)
        return HStack(spacing: 10) {
            Image(systemName: "calendar").foregroundStyle(T.ink3)
            Text("\(Cal.short(mon)) – \(Cal.short(Cal.add(mon, days: 4))) \(String(Cal.cal.component(.year, from: Cal.date(mon))))")
                .font(.system(size: 14, weight: .semibold)).foregroundStyle(T.ink2).monospacedDigit()
            Spacer()
            HStack(spacing: 4) {
                Button { state.weekStep(-1) } label: { Image(systemName: "chevron.left") }
                Button { state.select(state.nearestSchoolDay(from: Cal.today)) } label: {
                    Text("Aktuální").font(.system(size: 13, weight: .semibold))
                }.padding(.horizontal, 6)
                Button { state.weekStep(1) } label: { Image(systemName: "chevron.right") }
            }
            .font(.system(size: 14, weight: .semibold)).foregroundStyle(T.ink2).buttonStyle(.plain)
        }
    }

    private var dayStrip: some View {
        let mon = Cal.monday(state.selectedDate)
        return HStack(spacing: 0) {
            ForEach(0..<5, id: \.self) { i in
                let d = Cal.add(mon, days: i)
                let sel = d == state.selectedDate
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    state.select(d)
                } label: {
                    VStack(spacing: 2) {
                        Text(Cal.dowShort(d)).font(.system(size: 11, weight: .bold))
                        Text("\(Cal.day(d))").font(.system(size: 20, weight: .bold)).monospacedDigit()
                        Circle().fill(d == Cal.today ? (sel ? T.onAccent : T.accent) : .clear).frame(width: 4, height: 4)
                    }
                    .foregroundStyle(sel ? T.onAccent : T.ink)
                    .frame(maxWidth: .infinity).padding(.vertical, 9)
                    .background {
                        if sel {
                            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(T.accent)
                                .shadow(color: T.accent.opacity(0.35), radius: 10, y: 4)
                                .matchedGeometryEffect(id: "thumb", in: thumb)
                        }
                    }
                }.buttonStyle(.plain)
            }
        }
        .padding(4)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .animation(.spring(response: 0.5, dampingFraction: 0.82), value: state.selectedDate)
    }

    private var groupPicker: some View {
        Picker("", selection: $state.group) {
            Text("Základní škola").tag("zs")
            Text("Mateřská škola").tag("ms")
        }.pickerStyle(.segmented)
    }

    private func dayTitle(_ date: String) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(Cal.dowName(date)).font(.system(size: 30, weight: .bold)).tracking(-0.8).foregroundStyle(T.ink)
                if let v = state.vydej(date) { ServeLine(date: date, vydej: v) }
            }
            Spacer()
            HStack(spacing: 8) {
                ShareLink(item: shareText(date)) {
                    Image(systemName: "square.and.arrow.up").font(.system(size: 15, weight: .medium))
                        .foregroundStyle(T.ink2).frame(width: 38, height: 38).glassEffect(.regular.interactive(), in: Circle())
                }
                Button { withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { tab = 1 } } label: {
                    Text("Celý týden ↗").font(.system(size: 14, weight: .bold)).foregroundStyle(T.accent)
                }
            }
        }
    }

    private func shareText(_ date: String) -> String {
        let list = state.meals(date)
        var t = "🍽️ \(state.schoolTitle) · \(Cal.dowName(date)) \(Cal.short(date))\n"
        t += list.isEmpty ? "Pro tento den zatím jídelníček nemáme." :
            list.map { "• \(Course.of($0.c).label): \($0.n)" }.joined(separator: "\n")
        return t
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "cup.and.saucer").font(.system(size: 30)).foregroundStyle(T.ink3)
            Text(state.loadFailed ? "Jídelníček se nepodařilo načíst." : "Pro tento den zatím jídelníček nemáme.")
                .foregroundStyle(T.ink2)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 40)
    }

    @ViewBuilder private var tomorrowCard: some View {
        let tomorrow = Cal.add(Cal.today, days: 1)
        if state.selectedDate == Cal.today, let m = state.meals(tomorrow).first(where: { $0.c == "obed" }) ?? state.meals(tomorrow).first {
            Button { state.select(tomorrow) } label: {
                HStack(spacing: 14) {
                    Image(systemName: "calendar.badge.clock").font(.system(size: 18)).foregroundStyle(T.ink2)
                        .frame(width: 40, height: 40).background(T.track, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Zítra · \(Cal.dowName(tomorrow))").font(.system(size: 16, weight: .bold)).foregroundStyle(T.ink)
                        Text(m.n).font(.system(size: 14)).foregroundStyle(T.ink2).lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(T.ink3)
                }
                .padding(14).frame(maxWidth: .infinity).card()
            }.buttonStyle(PressableStyle())
        }
    }
}
