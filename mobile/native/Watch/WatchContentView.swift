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
                    Text("Nepodařilo se načíst jídelníček.").font(.footnote).foregroundStyle(.secondary)
                } else {
                    TabView(selection: $page) {
                        ForEach(model.days, id: \.self) { date in
                            ScrollView {
                                DayCard(title: title(date), date: date, model: model)
                                    .padding(.horizontal, 4)
                            }
                            .tag(date)
                        }
                    }
                    .tabViewStyle(.page)
                }
            }
            .navigationTitle(model.school.jmeno)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { picking = true } label: { Image(systemName: "building.2") }
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
        return "\(Cal.dowName(d)) \(Cal.short(d))"
    }
}

private struct DayCard: View {
    let title: String
    let date: String
    @ObservedObject var model: WatchModel

    var body: some View {
        let sk = model.skupina(date)
        let day = DaySummary(sk)
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(title.uppercased()).font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
                Spacer()
                switch MenuLogic.vydejStav(date: date, vydej: sk?.vydej) {
                case .bezi?: Text("Vydává se").font(.caption2.weight(.semibold)).foregroundStyle(.green)
                case .po? where date == Cal.today: Text("Vydáno").font(.caption2).foregroundStyle(.secondary)
                default: EmptyView()
                }
            }
            if let day {
                if let soup = day.soup {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Polévka").font(.system(size: 10, weight: .semibold)).foregroundStyle(.secondary)
                        Text(soup).font(.footnote)
                    }
                }
                ForEach(day.mains) { m in
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Hlavní chod").font(.system(size: 10, weight: .semibold)).foregroundStyle(.secondary)
                        Text(m.name).font(.headline).fixedSize(horizontal: false, vertical: true)
                        if !m.desc.isEmpty { Text(m.desc).font(.caption).foregroundStyle(.secondary) }
                    }
                }
                if let choice = day.choice {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Na výběr").font(.system(size: 10, weight: .semibold)).foregroundStyle(.secondary)
                        Text(choice).font(.caption).foregroundStyle(.secondary)
                    }
                }
                if let v = day.vydej { Text(v).font(.caption2).foregroundStyle(.tertiary) }
            } else {
                Text("Bez oběda").font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
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
                        Section("Oblíbené") { ForEach(favorites) { row($0) } }
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
                Text(s.jmeno).multilineTextAlignment(.leading)
                if s.id == currentId { Spacer(); Image(systemName: "checkmark").foregroundStyle(.green) }
            }
        }
    }
}
