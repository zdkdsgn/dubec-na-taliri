import Foundation

struct ChodCast: Decodable, Hashable {
    let l: String
    let n: String
    let a: [Int]
}

struct Chod: Decodable, Identifiable, Hashable {
    let c: String
    let n: String
    let d: String
    let a: [Int]
    let p: [ChodCast]?
    var id: String { c + "|" + n }

    enum CodingKeys: String, CodingKey { case c, n, d, a, p }
    init(from decoder: Decoder) throws {
        let k = try decoder.container(keyedBy: CodingKeys.self)
        c = try k.decode(String.self, forKey: .c)
        n = try k.decode(String.self, forKey: .n)
        d = try k.decodeIfPresent(String.self, forKey: .d) ?? ""
        a = try k.decodeIfPresent([Int].self, forKey: .a) ?? []
        p = try k.decodeIfPresent([ChodCast].self, forKey: .p)
    }

    var casti: [ChodCast] { p ?? [ChodCast(l: "Jídlo", n: n, a: a)] }
    var hlavni: ChodCast { casti.first(where: { $0.l == "Jídlo" }) ?? casti[0] }
}

struct Skupina: Hashable {
    var vydej: String?
    var chody: [Chod]
}

/// Jeden den ve všech podobách, které appka kdy dostala (viz tools/jidelna_client.py).
struct DenZaznam: Decodable {
    var skupiny: [String: Skupina]

    private struct Raw: Decodable {
        var vydej: String?
        var chody: [Chod]?
        var skupiny: [String: RawSk]?
    }
    private struct RawSk: Decodable {
        var vydej: String?
        var chody: [Chod]?
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let arr = try? c.decode([Chod].self) {
            skupiny = ["zs": Skupina(vydej: nil, chody: arr)]
            return
        }
        let raw = try c.decode(Raw.self)
        if let sk = raw.skupiny {
            skupiny = sk.mapValues { Skupina(vydej: $0.vydej, chody: $0.chody ?? []) }
        } else {
            skupiny = ["zs": Skupina(vydej: raw.vydej, chody: raw.chody ?? [])]
        }
    }
}

struct SkolaPolozka: Codable, Identifiable, Hashable {
    let id: String
    let nazev: String
    var kratky: String?
    var zdroj: String?
    var skutecna_data: Bool?
    var web: String?

    var jmeno: String { kratky ?? nazev }

    static let vychozi = SkolaPolozka(
        id: "47", nazev: "Základní škola, Starodubečská 413, Praha 10 - Dubeč",
        kratky: "ZŠ Dubeč", zdroj: "jidelna.cz", skutecna_data: true, web: nil)
}

struct SkolaData {
    var days: [String: [String: Skupina]] = [:]
    var updated: Date?
    var groups: [String] = ["zs"]
    static let empty = SkolaData()
}

struct Allergen: Identifiable, Hashable {
    let id: Int
    let name: String
    let emoji: String
    let detail: String

    static let all: [Allergen] = [
        Allergen(id: 1, name: "Obiloviny obsahující lepek", emoji: "🌾", detail: "Pšenice, žito, ječmen, oves, špalda, kamut."),
        Allergen(id: 2, name: "Korýši", emoji: "🦐", detail: "Krevety, krabi, langusty a výrobky z nich."),
        Allergen(id: 3, name: "Vejce", emoji: "🥚", detail: "Vejce a výrobky z nich."),
        Allergen(id: 4, name: "Ryby", emoji: "🐟", detail: "Ryby a výrobky z nich."),
        Allergen(id: 5, name: "Podzemnice olejná (arašídy)", emoji: "🥜", detail: "Arašídy a výrobky z nich."),
        Allergen(id: 6, name: "Sójové boby", emoji: "🫘", detail: "Sója a výrobky z ní."),
        Allergen(id: 7, name: "Mléko", emoji: "🥛", detail: "Mléko a výrobky z něj, včetně laktózy."),
        Allergen(id: 8, name: "Skořápkové plody", emoji: "🌰", detail: "Mandle, lískové ořechy, vlašské ořechy, kešu, pistácie."),
        Allergen(id: 9, name: "Celer", emoji: "🥬", detail: "Celer a výrobky z něj."),
        Allergen(id: 10, name: "Hořčice", emoji: "🌭", detail: "Hořčice a výrobky z ní."),
        Allergen(id: 11, name: "Sezamová semena", emoji: "🫓", detail: "Sezam a výrobky z něj."),
        Allergen(id: 12, name: "Oxid siřičitý a siřičitany", emoji: "🍇", detail: "V koncentraci vyšší než 10 mg/kg."),
        Allergen(id: 13, name: "Vlčí bob (lupina)", emoji: "🌱", detail: "Lupina a výrobky z ní."),
        Allergen(id: 14, name: "Měkkýši", emoji: "🐚", detail: "Mušle, chobotnice, šneci a výrobky z nich."),
    ]
    static func named(_ id: Int) -> Allergen? { all.first { $0.id == id } }
}

enum Tone { case amber, orange, green, blue, purple }

struct Course {
    let label: String
    let tone: Tone
    let symbol: String

    static func of(_ code: String) -> Course {
        switch code {
        case "presnidavka": return Course(label: "Přesnídávka", tone: .amber, symbol: "sun.max")
        case "polevka": return Course(label: "Polévka", tone: .orange, symbol: "cup.and.saucer")
        case "obed": return Course(label: "Hlavní chod", tone: .green, symbol: "fork.knife")
        case "obed2": return Course(label: "Hlavní chod II", tone: .blue, symbol: "leaf")
        case "svacina": return Course(label: "Odpolední svačina", tone: .purple, symbol: "birthday.cake")
        default: return Course(label: code, tone: .green, symbol: "fork.knife")
        }
    }
}
