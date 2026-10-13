import Foundation

enum DataService {
    static let base = URL(string: "https://zdkdsgn.github.io/dubec-na-taliri/")!

    private static var cacheDir: URL {
        let d = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("skola-data", isDirectory: true)
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }

    /// Síť má přednost; při výpadku se použije poslední uložená kopie (offline režim).
    private static func fetch(_ path: String) async throws -> Data {
        let file = cacheDir.appendingPathComponent(path.replacingOccurrences(of: "/", with: "_"))
        var req = URLRequest(url: base.appendingPathComponent(path))
        req.cachePolicy = .reloadIgnoringLocalCacheData
        req.timeoutInterval = 15
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
            try? data.write(to: file)
            return data
        } catch {
            if let cached = try? Data(contentsOf: file) { return cached }
            throw error
        }
    }

    static func schools() async throws -> [SkolaPolozka] {
        try JSONDecoder().decode([SkolaPolozka].self, from: await fetch("schools/index.json"))
    }

    static func school(_ id: String) async throws -> SkolaData {
        let raw = try JSONDecoder().decode([String: DenZaznam?].self, from: await fetch("schools/\(id)/days.json"))
        var out = SkolaData()
        var groups = Set<String>()
        for (date, zaznam) in raw {
            guard let zaznam else { continue }
            out.days[date] = zaznam.skupiny
            groups.formUnion(zaznam.skupiny.keys)
        }
        out.groups = groups.isEmpty ? ["zs"] : groups.sorted()
        if let base = try? await fetch("schools/\(id)/base.json"),
           let obj = try? JSONSerialization.jsonObject(with: base) as? [String: Any],
           let s = obj["updated"] as? String {
            out.updated = ISO8601DateFormatter().date(from: s)
        }
        return out
    }
}

/// Kalendářní pomůcky nad ISO daty "yyyy-MM-dd" (stejné klíče jako days.json).
enum Cal {
    static let cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.firstWeekday = 2
        return c
    }()
    private static let fmt: DateFormatter = {
        let f = DateFormatter()
        f.calendar = cal
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func iso(_ d: Date) -> String { fmt.string(from: d) }
    static func date(_ s: String) -> Date { fmt.date(from: s) ?? Date() }
    static var today: String { iso(Date()) }
    static func add(_ s: String, days n: Int) -> String {
        iso(cal.date(byAdding: .day, value: n, to: date(s)) ?? date(s))
    }
    static func monday(_ s: String) -> String {
        let d = date(s)
        let wd = (cal.component(.weekday, from: d) + 5) % 7   // po = 0
        return add(s, days: -wd)
    }
    static func day(_ s: String) -> Int { cal.component(.day, from: date(s)) }
    static func month(_ s: String) -> Int { cal.component(.month, from: date(s)) }
    static func short(_ s: String) -> String { "\(day(s)). \(month(s))." }
    static let dow = ["Neděle", "Pondělí", "Úterý", "Středa", "Čtvrtek", "Pátek", "Sobota"]
    static let dows = ["Ne", "Po", "Út", "St", "Čt", "Pá", "So"]
    static func dowName(_ s: String) -> String { dow[cal.component(.weekday, from: date(s)) - 1] }
    static func dowShort(_ s: String) -> String { dows[cal.component(.weekday, from: date(s)) - 1] }
}

enum VydejStav { case pred, bezi, po }

enum MenuLogic {
    /// Stejná logika jako vydejStav() ve webové appce.
    static func vydejStav(date: String, vydej: String?) -> VydejStav? {
        guard let vydej else { return nil }
        let today = Cal.today
        if date < today { return .po }
        if date > today { return .pred }
        let parts = vydej.split(separator: "–").map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 2 else { return .pred }
        func minutes(_ t: String) -> Int {
            let hm = t.split(separator: ":").compactMap { Int($0) }
            return hm.count == 2 ? hm[0] * 60 + hm[1] : 0
        }
        let now = Calendar.current.dateComponents([.hour, .minute], from: Date())
        let ted = (now.hour ?? 0) * 60 + (now.minute ?? 0)
        return ted < minutes(parts[0]) ? .pred : ted < minutes(parts[1]) ? .bezi : .po
    }

    /// Nejdelší shodný "ocas" popisů příloh napříč chody dne (společná nabídka "Na výběr").
    static func spolecnyOcas(_ list: [Chod]) -> [String] {
        let segy = list.filter { !$0.d.isEmpty }.map { $0.d.components(separatedBy: " · ") }
        guard segy.count >= 2 else { return [] }
        var spolecne: [String] = []
        let nejkratsi = segy.map(\.count).min() ?? 0
        guard nejkratsi >= 1 else { return [] }
        for k in 1...nejkratsi {
            let ocasy = Set(segy.map { $0.suffix(k).joined(separator: "\u{1}") })
            if ocasy.count != 1 { break }
            spolecne = Array(segy[0].suffix(k))
        }
        return spolecne
    }

    static func vlastniPopis(_ m: Chod, ocas: [String]) -> String {
        if m.d.isEmpty { return "" }
        let segy = m.d.components(separatedBy: " · ")
        if ocas.isEmpty { return m.d }
        return segy.count > ocas.count ? segy.dropLast(ocas.count).joined(separator: " · ") : ""
    }

    static func normalize(_ s: String) -> String {
        s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
    }
}
