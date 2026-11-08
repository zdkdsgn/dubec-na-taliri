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
    @State private var adding = false
    /// První spuštění: žádná škola není předvybraná, výběr nejde zavřít bez volby.
    var welcome = false

    private let typy = [("vse", "Vše"), ("zs", "ZŠ"), ("ms", "MŠ"), ("ss", "SŠ")]

    private var filtered: [SkolaPolozka] {
        let base = state.schools.isEmpty ? (state.hasSchool ? [state.active] : []) : state.schools
        return base.filter { s in
            (typ == "vse" || s.typy.contains(typ)) &&
            (query.count < 2 || MenuLogic.normalize(s.nazev).contains(MenuLogic.normalize(query)) ||
             MenuLogic.normalize(s.jmeno).contains(MenuLogic.normalize(query)))
        }
    }

    var body: some View {
        NavigationStack {
            let list = filtered.filter { !$0.jeIcanteen }
            let mine = filtered.filter(\.jeIcanteen)
            let grouped = Dictionary(grouping: list, by: \.mesto)
            List {
                Section {
                    Picker("", selection: $typ) { ForEach(typy, id: \.0) { Text($0.1).tag($0.0) } }
                        .pickerStyle(.segmented)
                }.listRowBackground(Color.clear).listRowInsets(EdgeInsets())

                Section("Moje jídelny (iCanteen)") {
                    ForEach(mine) { row($0) }
                        .onDelete { idx in idx.map { mine[$0] }.forEach(state.removeCustom) }
                    Button { adding = true } label: { Label("Přidat jídelnu z iCanteen", systemImage: "plus.circle") }
                        .foregroundStyle(T.accent)
                        .listRowBackground(T.card)
                }

                let favs = (list + mine).filter { state.favorites.contains($0.id) }
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
            .navigationTitle(welcome ? "Vyberte svou školu" : "Vaše škola")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { if !welcome { ToolbarItem(placement: .confirmationAction) { Button("Hotovo") { dismiss() } } } }
            .sheet(isPresented: $adding) { AddIcanteenView(onDone: { adding = false; dismiss() }) }
        }
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(30)
        .interactiveDismissDisabled(welcome)
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
                        if s.bez_listku == true { Text("zatím bez jídelníčku").font(.system(size: 12)).foregroundStyle(T.ink3) }
                        else if s.jeIcanteen { Text("iCanteen").font(.system(size: 12, weight: .semibold)).foregroundStyle(T.accent) }
                        else if s.skutecna_data == false { Text("ukázková data").font(.system(size: 12)).foregroundStyle(T.ink3) }
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

/// Přidání jídelny z iCanteen ve dvou krocích: najít (náhled, ať je jasné, že odkaz sedí), pak pojmenovat.
struct AddIcanteenView: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss
    let onDone: () -> Void
    @State private var link = ""
    @State private var name = ""
    @State private var cislo: String?
    @State private var preview = ""
    @State private var error: String?
    @State private var busy = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("strav.nasejidelna.cz/0341", text: $link)
                        .textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL)
                        .onChange(of: link) { _, _ in cislo = nil; error = nil }
                } footer: {
                    Text("Otevřete přihlášení do školní jídelny (iCanteen) a vložte odkaz. Jídelníček je na něm vidět bez hesla.")
                }
                if cislo != nil {
                    Section {
                        Text(preview).font(.system(size: 14)).foregroundStyle(T.ink)
                            .listRowBackground(T.accentSoft)
                        TextField("Jméno školy (např. ZŠ Novákova)", text: $name)
                    }
                }
                if let error { Section { Text(error).foregroundStyle(T.red).font(.footnote) } }
                Section {
                    Button {
                        busy = true
                        Task {
                            if cislo == nil {
                                let r = await state.previewCustom(link: link)
                                cislo = r.cislo; preview = r.text; error = r.error
                            } else if let cislo {
                                error = await state.addCustom(cislo: cislo, name: name)
                                if error == nil { onDone() }
                            }
                            busy = false
                        }
                    } label: {
                        HStack { Text(cislo == nil ? "Najít jídelnu" : "Přidat jídelnu"); if busy { Spacer(); ProgressView() } }
                    }.disabled(busy || (cislo == nil && link.isEmpty))
                }
            }
            .navigationTitle("Jídelna z iCanteen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Zrušit") { dismiss() } } }
        }
    }
}
