import Foundation

/// Sdílené úložiště mezi appkou a widgety (App Group): která škola je vybraná.
enum SharedStore {
    static let group = "group.cz.zdkdsgn.skolanatalire"
    private static var defaults: UserDefaults { UserDefaults(suiteName: group) ?? .standard }

    static func saveSchool(_ s: SkolaPolozka) {
        if let raw = try? JSONEncoder().encode(s) { defaults.set(raw, forKey: "school") }
    }
    static func loadSchool() -> SkolaPolozka {
        if let raw = defaults.data(forKey: "school"), let s = try? JSONDecoder().decode(SkolaPolozka.self, from: raw) { return s }
        return .vychozi
    }
}
