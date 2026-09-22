import Foundation

struct Chod: Decodable {
    let c: String
    let n: String
    let d: String?
    let vydej: String?
}

struct DenZaznam: Decodable {
    let vydej: String?
    let chody: [Chod]?
}

struct SkolaPolozka: Decodable, Identifiable, Hashable {
    let id: String
    let nazev: String
    let kratky: String?

    var zobrazovaneJmeno: String { kratky ?? nazev }
}

enum VydejStav {
    case pred, bezi, po
}

struct DenNahled: Identifiable {
    let id: String          // ISO datum
    let datum: Date
    let obed: Chod?
    let vydej: String?

    var stav: VydejStav {
        let dnes = Calendar.current.startOfDay(for: Date())
        let denDatum = Calendar.current.startOfDay(for: datum)
        if denDatum < dnes { return .po }
        if denDatum > dnes { return .pred }
        guard let vydej, let rozsah = Self.parsujRozsah(vydej) else { return .pred }
        let ted = Date()
        if ted < rozsah.0 { return .pred }
        if ted > rozsah.1 { return .po }
        return .bezi
    }

    private static func parsujRozsah(_ text: String) -> (Date, Date)? {
        let casti = text.split(separator: "–").map { $0.trimmingCharacters(in: .whitespaces) }
        guard casti.count == 2 else { return nil }
        let df = DateFormatter()
        df.dateFormat = "HH:mm"
        guard let od = df.date(from: casti[0]), let doo = df.date(from: casti[1]) else { return nil }
        let dnes = Calendar.current.startOfDay(for: Date())
        let cal = Calendar.current
        func kombinuj(_ cas: Date) -> Date {
            let slozky = cal.dateComponents([.hour, .minute], from: cas)
            return cal.date(bySettingHour: slozky.hour ?? 0, minute: slozky.minute ?? 0, second: 0, of: dnes) ?? dnes
        }
        return (kombinuj(od), kombinuj(doo))
    }
}

@MainActor
final class JidelnicekModel: ObservableObject {
    @Published var dnes: DenNahled?
    @Published var zitra: DenNahled?
    @Published var skolaNazev: String
    @Published var nacita = true
    @Published var chyba: String?

    private static let vychoziId = "47"
    private static let vychoziNazev = "ZŠ Dubeč"
    private let defaults = UserDefaults.standard
    private let base = "https://zdkdsgn.github.io/dubec-na-taliri/"

    private(set) var skolaId: String {
        didSet { defaults.set(skolaId, forKey: "skolaId") }
    }

    init() {
        skolaId = defaults.string(forKey: "skolaId") ?? Self.vychoziId
        skolaNazev = defaults.string(forKey: "skolaNazev") ?? Self.vychoziNazev
    }

    func vyberSkolu(_ polozka: SkolaPolozka) {
        skolaId = polozka.id
        skolaNazev = polozka.zobrazovaneJmeno
        defaults.set(skolaNazev, forKey: "skolaNazev")
        dnes = nil
        zitra = nil
        Task { await nacist() }
    }

    func nacistPokudTreba() async {
        guard dnes == nil, chyba == nil else { return }
        await nacist()
    }

    func nacist() async {
        nacita = true
        chyba = nil
        do {
            let url = URL(string: "\(base)schools/\(skolaId)/days.json")!
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            let (data, _) = try await URLSession.shared.data(for: request)
            let dny = try JSONDecoder().decode([String: DenZaznam?].self, from: data)

            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            df.timeZone = TimeZone(identifier: "Europe/Prague")

            func sestav(_ posun: Int) -> DenNahled? {
                let datum = Calendar.current.date(byAdding: .day, value: posun, to: Date())!
                let iso = df.string(from: datum)
                guard let zaznam = dny[iso] ?? nil else { return nil }
                let obed = zaznam.chody?.first(where: { $0.c == "obed" })
                return DenNahled(id: iso, datum: datum, obed: obed, vydej: zaznam.vydej)
            }

            dnes = sestav(0)
            zitra = sestav(1)
        } catch {
            chyba = "Nepodařilo se načíst jídelníček."
        }
        nacita = false
    }
}

@MainActor
final class SkolyModel: ObservableObject {
    @Published var skoly: [SkolaPolozka] = []
    @Published var nacita = false
    @Published var chyba: String?

    private let base = "https://zdkdsgn.github.io/dubec-na-taliri/"

    func nacistPokudTreba() async {
        guard skoly.isEmpty, chyba == nil else { return }
        nacita = true
        do {
            let url = URL(string: "\(base)schools/index.json")!
            let (data, _) = try await URLSession.shared.data(from: url)
            skoly = try JSONDecoder().decode([SkolaPolozka].self, from: data)
                .sorted { $0.zobrazovaneJmeno.localizedCaseInsensitiveCompare($1.zobrazovaneJmeno) == .orderedAscending }
        } catch {
            chyba = "Nepodařilo se načíst seznam škol."
        }
        nacita = false
    }
}
