import SwiftUI
import WidgetKit

enum ThemeChoice: String, CaseIterable, Identifiable {
    case auto, light, dark
    var id: String { rawValue }
    var label: String { self == .auto ? "Auto" : self == .light ? "Světlý" : "Tmavý" }
    var scheme: ColorScheme? { self == .light ? .light : self == .dark ? .dark : nil }
}

private enum Store {
    static let d = UserDefaults.standard
    static func get<V: Decodable>(_ key: String, _ fallback: V) -> V {
        guard let data = d.data(forKey: "skola." + key), let v = try? JSONDecoder().decode(V.self, from: data) else { return fallback }
        return v
    }
    static func set<V: Encodable>(_ key: String, _ value: V) {
        if let data = try? JSONEncoder().encode(value) { d.set(data, forKey: "skola." + key) }
    }
}

@MainActor
final class AppState: ObservableObject {
    @Published var schools: [SkolaPolozka] = []
    @Published var active: SkolaPolozka = Store.get("activeSchool", SkolaPolozka.vychozi) {
        didSet { Store.set("activeSchool", active); SharedStore.saveSchool(active); WidgetCenter.shared.reloadAllTimelines() }
    }
    @Published var data = SkolaData.empty
    @Published var loading = false
    @Published var loadFailed = false
    @Published var group = "zs"
    @Published var selectedDate = Cal.today
    @Published var forward = true

    @Published var allergenFilter: Set<Int> = Set(Store.get("filter", [Int]())) {
        didSet { Store.set("filter", Array(allergenFilter)) }
    }
    @Published var ratings: [String: Int] = Store.get("ratings", [String: Int]()) {
        didSet { Store.set("ratings", ratings) }
    }
    @Published var dislikes: Set<String> = Set(Store.get("dislikes", [String]())) {
        didSet { Store.set("dislikes", Array(dislikes)) }
    }
    @Published var favorites: Set<String> = Set(Store.get("favorites", [String]())) {
        didSet { Store.set("favorites", Array(favorites)) }
    }
    @Published var theme: ThemeChoice = ThemeChoice(rawValue: Store.get("theme", "auto")) ?? .auto {
        didSet { Store.set("theme", theme.rawValue) }
    }
    @Published var bigText: Bool = Store.get("bigText", false) {
        didSet { Store.set("bigText", bigText) }
    }

    // MARK: načítání

    func start() async {
        SharedStore.saveSchool(active)
        async let list: Void = loadSchools()
        await load(active)
        await list
    }

    func loadSchools() async {
        if let s = try? await DataService.schools() { schools = s }
    }

    func load(_ school: SkolaPolozka) async {
        loading = true
        loadFailed = false
        defer { loading = false }
        do {
            let d = try await DataService.school(school.id)
            data = d
            active = school
            if !d.groups.contains(group) { group = d.groups.contains("zs") ? "zs" : (d.groups.first ?? "zs") }
            selectedDate = nearestSchoolDay(from: Cal.today)
        } catch {
            loadFailed = data.days.isEmpty
        }
    }

    func refresh() async {
        let keep = selectedDate
        await load(active)
        if hasDay(keep) { selectedDate = keep }
    }

    func choose(_ school: SkolaPolozka) async {
        await load(school)
    }

    // MARK: data dne

    func skupina(_ date: String) -> Skupina? { data.days[date]?[group] }
    func meals(_ date: String) -> [Chod] { skupina(date)?.chody ?? [] }
    func vydej(_ date: String) -> String? { skupina(date)?.vydej }
    func hasDay(_ date: String) -> Bool { !meals(date).isEmpty }
    var multiGroup: Bool { data.groups.count > 1 }

    func nearestSchoolDay(from: String) -> String {
        for i in 0..<14 { let d = Cal.add(from, days: i); if hasDay(d) { return d } }
        let keys = data.days.keys.sorted()
        return keys.first(where: { $0 >= from }) ?? keys.last ?? from
    }

    // MARK: navigace mezi dny

    func select(_ date: String) {
        guard date != selectedDate else { return }
        forward = date > selectedDate
        withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) { selectedDate = date }
    }

    @discardableResult
    func step(_ n: Int) -> Bool {
        var d = selectedDate
        for _ in 0..<10 { d = Cal.add(d, days: n); if hasDay(d) { select(d); return true } }
        return false
    }

    @discardableResult
    func weekStep(_ n: Int) -> Bool {
        let cand = Cal.add(Cal.monday(selectedDate), days: n * 7)
        for i in 0..<5 { let d = Cal.add(cand, days: i); if hasDay(d) { select(d); return true } }
        return false
    }

    var schoolTitle: String {
        guard multiGroup else { return active.jmeno }
        let base = active.jmeno.replacingOccurrences(of: "^(ZŠ|MŠ)\\s+", with: "", options: .regularExpression)
        return "\(group == "ms" ? "MŠ" : "ZŠ") \(base)"
    }

    // MARK: upozornění, hledání, připomínka

    /// Počet dní od posledního stažení, pokud je to ve všední den podezřele dlouho.
    var staleDays: Int? {
        guard active.skutecna_data != false, let u = data.updated else { return nil }
        let wd = Calendar.current.component(.weekday, from: Date())
        guard wd != 1, wd != 7 else { return nil }
        let d = Calendar.current.dateComponents([.day], from: u, to: Date()).day ?? 0
        return d >= 3 ? d : nil
    }

    func search(_ q: String) -> [(date: String, meal: Chod)] {
        let needle = MenuLogic.normalize(q.trimmingCharacters(in: .whitespaces))
        guard needle.count >= 2 else { return [] }
        var out: [(date: String, meal: Chod)] = []
        for date in data.days.keys.sorted(by: >) {
            for m in meals(date) where MenuLogic.normalize(m.n).contains(needle) { out.append((date, m)) }
            if out.count >= 60 { break }
        }
        return out
    }

    /// .ics s večerní připomínkou den před dalším školním dnem (odhlášení oběda).
    func reminderFile() -> URL? {
        let target = nearestSchoolDay(from: Cal.add(Cal.today, days: 1))
        let d = Cal.date(target)
        let c = Cal.cal.dateComponents([.year, .month, .day], from: d)
        let ds = String(format: "%04d%02d%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
        let stamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: "-", with: "").replacingOccurrences(of: ":", with: "")
        let ics = [
            "BEGIN:VCALENDAR", "VERSION:2.0", "PRODID:-//Skola na taliri//CS", "CALSCALE:GREGORIAN",
            "BEGIN:VEVENT", "UID:pripominka-obed-\(ds)@skola-na-taliri", "DTSTAMP:\(stamp)",
            "DTSTART;VALUE=DATE:\(ds)", "SUMMARY:Rozhodnout o obědě – případně odhlásit",
            "DESCRIPTION:Pokud dítě zítra nepůjde do školy\\, nezapomeňte oběd včas odhlásit na webu jídelny.",
            "BEGIN:VALARM", "ACTION:DISPLAY", "DESCRIPTION:Odhlásit oběd", "TRIGGER:-P1DT5H", "END:VALARM",
            "END:VEVENT", "END:VCALENDAR",
        ].joined(separator: "\r\n")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("pripominka-obed.ics")
        do { try ics.write(to: url, atomically: true, encoding: .utf8); return url } catch { return nil }
    }

    // MARK: žebříček a oblíbené

    var favoriteSchools: [SkolaPolozka] {
        var known = Dictionary(uniqueKeysWithValues: schools.map { ($0.id, $0) })
        known[active.id] = active
        return favorites.compactMap { known[$0] }.sorted { $0.jmeno.localizedCompare($1.jmeno) == .orderedAscending }
    }

    struct Skore: Identifiable { let nazev: String; var plus = 0, stred = 0, minus = 0; var id: String { nazev } }
    /// Nejlépe hodnocená jídla (jen z dnů, které má aktivní škola ve svých datech).
    var leaderboard: [Skore] {
        var out: [String: Skore] = [:]
        for (key, v) in ratings {
            let p = key.split(separator: "|").map(String.init)
            guard p.count == 3, let m = data.days[p[0]]?[p[1]]?.chody.first(where: { $0.c == p[2] }) else { continue }
            var s = out[m.n] ?? Skore(nazev: m.n)
            if v > 0 { s.plus += 1 } else if v < 0 { s.minus += 1 } else { s.stred += 1 }
            out[m.n] = s
        }
        return out.values.sorted { ($0.plus - $0.minus, $0.plus + $0.stred + $0.minus) > ($1.plus - $1.minus, $1.plus + $1.stred + $1.minus) }
    }

    // MARK: hodnocení, poznámky, oblíbené

    func ratingKey(_ date: String, _ m: Chod) -> String { "\(date)|\(group)|\(m.c)" }
    func rate(_ date: String, _ m: Chod, _ v: Int) {
        let k = ratingKey(date, m)
        if ratings[k] == v { ratings[k] = nil } else { ratings[k] = v }
    }
    func toggleDislike(_ m: Chod) {
        let k = MenuLogic.normalize(m.n)
        if dislikes.contains(k) { dislikes.remove(k) } else { dislikes.insert(k) }
    }
    func isDisliked(_ m: Chod) -> Bool { dislikes.contains(MenuLogic.normalize(m.n)) }
    func toggleFavorite(_ s: SkolaPolozka) {
        if favorites.contains(s.id) { favorites.remove(s.id) } else { favorites.insert(s.id) }
    }
    func toggleAllergen(_ id: Int) {
        if allergenFilter.contains(id) { allergenFilter.remove(id) } else { allergenFilter.insert(id) }
    }

    /// Alergeny z filtru zasažené daným chodem: (v jídle, jen v příloze/nápoji).
    func hits(_ m: Chod) -> [Int] { m.a.filter { allergenFilter.contains($0) } }
    func hitsInMain(_ m: Chod) -> Bool { m.hlavni.a.contains { allergenFilter.contains($0) } }
    func hitPlaces(_ m: Chod) -> [String] {
        var seen: [String] = []
        for c in m.casti where c.a.contains(where: { allergenFilter.contains($0) }) {
            let l = c.l.lowercased(); if !seen.contains(l) { seen.append(l) }
        }
        return seen
    }
}
