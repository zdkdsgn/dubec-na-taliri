import SwiftUI

struct WatchContentView: View {
    @StateObject private var model = WatchModel()
    @State private var picking = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if model.loading && model.data.days.isEmpty {
                        ProgressView().frame(maxWidth: .infinity).padding(.top, 24)
                    } else if model.failed {
                        Text("Nepodařilo se načíst jídelníček.").font(.footnote).foregroundStyle(.secondary)
                    } else {
                        let today = Cal.today, tomorrow = Cal.add(today, days: 1)
                        DayCard(title: "Dnes", date: today, model: model)
                        Divider()
                        DayCard(title: "Zítra", date: tomorrow, model: model)
                    }
                }
                .padding(.horizontal, 4)
            }
            .navigationTitle(model.school.jmeno)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { picking = true } label: { Image(systemName: "building.2") }
                }
            }
            .sheet(isPresented: $picking) {
                NavigationStack {
                    WatchSchoolPicker(currentId: model.school.id) { s in model.choose(s); picking = false }
                }
            }
            .task { await model.load() }
            .refreshable { await model.load() }
        }
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
    let pick: (SkolaPolozka) -> Void

    var body: some View {
        let list = query.isEmpty ? schools.list : schools.list.filter { $0.jmeno.localizedCaseInsensitiveContains(query) }
        Group {
            if schools.list.isEmpty && !schools.failed { ProgressView() }
            else if schools.failed { Text("Seznam škol se nepodařilo načíst.").font(.footnote) }
            else {
                List(list) { s in
                    Button { pick(s) } label: {
                        HStack {
                            Text(s.jmeno).multilineTextAlignment(.leading)
                            if s.id == currentId { Spacer(); Image(systemName: "checkmark").foregroundStyle(.green) }
                        }
                    }
                }
                .searchable(text: $query, prompt: "Hledat školu")
            }
        }
        .navigationTitle("Vaše škola")
        .task { await schools.load() }
    }
}
