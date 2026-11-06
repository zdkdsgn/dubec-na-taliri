import SwiftUI

struct WatchContentView: View {
    @StateObject private var model = WatchModel()
    @State private var picking = false
    @State private var page = Cal.today

    var body: some View {
        NavigationStack {
            Group {
                if model.loading && model.data.days.isEmpty {
                    ProgressView()
                } else if model.failed {
                    Text("Nepodařilo se načíst jídelníček.").font(.footnote).foregroundStyle(W.ink2).padding()
                } else {
                    TabView(selection: $page) {
                        ForEach(model.days, id: \.self) { date in
                            ScrollView {
                                DayCard(title: title(date), date: date, model: model)
                                    .padding(.horizontal, 2)
                            }
                            .tag(date)
                        }
                    }
                    .tabViewStyle(.page)
                }
            }
            .containerBackground(for: .navigation) { WatchAmbient() }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { picking = true } label: { Image(systemName: "building.2").foregroundStyle(W.accent) }
                }
            }
            .sheet(isPresented: $picking) {
                NavigationStack {
                    WatchSchoolPicker(currentId: model.school.id, favorites: model.favorites) { s in
                        page = Cal.today
                        model.choose(s)
                        picking = false
                    }
                }
            }
            .task { await model.load() }
            .refreshable { await model.load() }
        }
    }

    private func title(_ d: String) -> String {
        let today = Cal.today
        if d == today { return "Dnes" }
        if d == Cal.add(today, days: 1) { return "Zítra" }
        return Cal.dowName(d)
    }
}

private struct DayCard: View {
    let title: String
    let date: String
    @ObservedObject var model: WatchModel

    var body: some View {
        let sk = model.skupina(date)
        let day = DaySummary(sk)
        VStack(alignment: .leading, spacing: 8) {
            // škola je vidět na každé stránce, ať je jasné, čí jídelníček se čte
            HStack(spacing: 5) {
                Circle().fill(W.accent).frame(width: 6, height: 6)
                Text(model.school.jmeno).font(.system(size: 12, weight: .semibold)).foregroundStyle(W.ink2).lineLimit(1)
            }
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(.system(size: 22, weight: .bold)).tracking(-0.4).foregroundStyle(W.ink)
                Text(Cal.short(date)).font(.system(size: 12)).foregroundStyle(W.ink3)
                Spacer(minLength: 0)
            }
            switch MenuLogic.vydejStav(date: date, vydej: sk?.vydej) {
            case .bezi?: pill("Vydává se", tint: W.accent, bg: W.accentSoft)
            case .po? where date == Cal.today: pill("Vydáno", tint: W.ink3, bg: W.card)
            default: EmptyView()
            }

            if let day {
                if let soup = day.soup { meal(Course.of("polevka"), name: soup, desc: "") }
                ForEach(Array(day.mains.enumerated()), id: \.element.id) { i, m in
                    meal(Course.of(i == 0 ? "obed" : "obed2"), name: m.name, desc: m.desc)
                }
                if let choice = day.choice {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("NA VÝBĚR").font(.system(size: 10, weight: .bold)).tracking(0.8).foregroundStyle(W.ink3)
                        Text(choice).font(.system(size: 12)).foregroundStyle(W.ink2)
                    }
                    .padding(10).frame(maxWidth: .infinity, alignment: .leading)
                    .background(W.card.opacity(0.7), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                if let v = day.vydej {
                    Text("Výdej \(v)").font(.system(size: 11)).foregroundStyle(W.ink3).padding(.leading, 4)
                }
            } else {
                Text(model.data.days.isEmpty ? "Jídelna zatím nezveřejnila jídelníček." : "Bez oběda")
                    .font(.system(size: 14)).foregroundStyle(W.ink2)
                    .padding(10).frame(maxWidth: .infinity, alignment: .leading)
                    .background(W.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .padding(.vertical, 4)
    }

    private func pill(_ text: String, tint: Color, bg: Color) -> some View {
        Text(text).font(.system(size: 11, weight: .bold)).foregroundStyle(tint)
            .padding(.horizontal, 8).padding(.vertical, 3).background(bg, in: Capsule())
    }

    private func meal(_ course: Course, name: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            WatchCourseIcon(course: course)
            VStack(alignment: .leading, spacing: 2) {
                Text(course.label.uppercased()).font(.system(size: 9.5, weight: .bold)).tracking(0.8).foregroundStyle(W.ink3)
                Text(name).font(.system(size: 15, weight: .bold)).tracking(-0.2).foregroundStyle(W.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if !desc.isEmpty {
                    Text(desc).font(.system(size: 12)).foregroundStyle(W.ink2).fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(W.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(.white.opacity(0.06), lineWidth: 1))
    }
}

private struct WatchSchoolPicker: View {
    @StateObject private var schools = WatchSchools()
    @State private var query = ""
    let currentId: String
    let favorites: [SkolaPolozka]
    let pick: (SkolaPolozka) -> Void

    var body: some View {
        let list = query.isEmpty ? schools.list : schools.list.filter { $0.jmeno.localizedCaseInsensitiveContains(query) }
        Group {
            if schools.list.isEmpty && !schools.failed && favorites.isEmpty { ProgressView() }
            else if schools.failed { Text("Seznam škol se nepodařilo načíst.").font(.footnote) }
            else {
                List {
                    if query.isEmpty && !favorites.isEmpty {
                        Section("★ Oblíbené") { ForEach(favorites) { row($0) } }
                        Section("Všechny školy") { ForEach(list) { row($0) } }
                    } else {
                        ForEach(list) { row($0) }
                    }
                }
                .searchable(text: $query, prompt: "Hledat školu")
            }
        }
        .navigationTitle("Vaše škola")
        .task { await schools.load() }
    }

    private func row(_ s: SkolaPolozka) -> some View {
        Button { pick(s) } label: {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text(s.jmeno).font(.system(size: 14, weight: .semibold)).foregroundStyle(W.ink).multilineTextAlignment(.leading)
                    if s.jeIcanteen { Text("iCanteen").font(.system(size: 10, weight: .semibold)).foregroundStyle(W.accent) }
                }
                if s.id == currentId { Spacer(); Image(systemName: "checkmark").foregroundStyle(W.accent) }
            }
        }
        .listRowBackground(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(W.card))
    }
}
