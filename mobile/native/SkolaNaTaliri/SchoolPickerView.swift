import SwiftUI

extension SkolaPolozka {
    var typy: Set<String> {
        var t = Set<String>()
        let n = nazev
        func has(_ p: String) -> Bool { n.range(of: p, options: [.regularExpression, .caseInsensitive]) != nil }
        if has("mateřsk[áé]\\s+škol|^MŠ\\b") { t.insert("ms") }
        if has("základn[íi]\\s+škol|^ZŠ\\b") { t.insert("zs") }
        if has("gymnázium|střední\\s+(odborn|škol)|lyceum|konzervato[řr]|obchodní akademie|\\bSOU\\b|\\bSOŠ\\b") { t.insert("ss") }
        return t.isEmpty ? ["ostatni"] : t
    }
}

struct SchoolPickerView: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var typ = "vse"
    @State private var expanded: Set<String> = []

    private let typy = [("vse", "Vše"), ("zs", "ZŠ"), ("ms", "MŠ"), ("ss", "SŠ")]

    private var filtered: [SkolaPolozka] {
        let base = state.schools.isEmpty ? [state.active] : state.schools
        return base.filter { s in
            (typ == "vse" || s.typy.contains(typ)) &&
            (query.count < 2 || MenuLogic.normalize(s.nazev).contains(MenuLogic.normalize(query)) ||
             MenuLogic.normalize(s.jmeno).contains(MenuLogic.normalize(query)))
        }
    }

    var body: some View {
        NavigationStack {
            let list = filtered
            let grouped = Dictionary(grouping: list, by: \.mesto)
            List {
                Section {
                    Picker("", selection: $typ) { ForEach(typy, id: \.0) { Text($0.1).tag($0.0) } }
                        .pickerStyle(.segmented)
                }.listRowBackground(Color.clear).listRowInsets(EdgeInsets())

                let favs = list.filter { state.favorites.contains($0.id) }
                if !favs.isEmpty {
                    Section("★ Oblíbené") { ForEach(favs) { row($0) } }
                }
                if query.count >= 2 {
                    Section("Výsledky") { ForEach(list) { row($0) } }
                } else {
                    ForEach(grouped.keys.sorted { $0.localizedCompare($1) == .orderedAscending }, id: \.self) { mesto in
                        let items = (grouped[mesto] ?? []).sorted { $0.jmeno.localizedCompare($1.jmeno) == .orderedAscending }
                        DisclosureGroup(isExpanded: Binding(
                            get: { expanded.contains(mesto) || items.contains { $0.id == state.active.id } },
                            set: { if $0 { expanded.insert(mesto) } else { expanded.remove(mesto) } })) {
                            ForEach(items) { row($0) }
                        } label: {
                            HStack { Text(mesto).font(.system(size: 16, weight: .semibold)); Text("\(items.count)").foregroundStyle(T.ink3) }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(T.bg)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Název nebo ulice")
            .navigationTitle("Vaše škola")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Hotovo") { dismiss() } } }
        }
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(30)
    }

    private func row(_ s: SkolaPolozka) -> some View {
        let active = s.id == state.active.id
        let fav = state.favorites.contains(s.id)
        return HStack(spacing: 12) {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                Task { await state.choose(s); dismiss() }
            } label: {
                HStack(spacing: 12) {
                    Text(String(s.nazev.prefix(1))).font(.system(size: 13, weight: .bold)).foregroundStyle(T.accent)
                        .frame(width: 30, height: 30).background(T.accentSoft, in: Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text(s.nazev).font(.system(size: 15, weight: .semibold)).foregroundStyle(T.ink).multilineTextAlignment(.leading)
                        if s.skutecna_data == false { Text("ukázková data").font(.system(size: 12)).foregroundStyle(T.ink3) }
                    }
                    Spacer()
                    if active { Text("Aktivní").font(.system(size: 11, weight: .bold)).foregroundStyle(T.accent)
                        .padding(.horizontal, 8).padding(.vertical, 3).background(T.accentSoft, in: Capsule()) }
                }
            }.buttonStyle(.plain)
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { state.toggleFavorite(s) }
            } label: {
                Image(systemName: fav ? "star.fill" : "star").foregroundStyle(fav ? T.amber : T.ink3).pop(fav)
            }.buttonStyle(.borderless)
        }
        .listRowBackground(T.card)
    }
}
