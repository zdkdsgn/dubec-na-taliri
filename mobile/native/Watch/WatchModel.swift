import SwiftUI

@MainActor
final class WatchModel: ObservableObject {
    @Published var data = SkolaData.empty
    @Published var school: SkolaPolozka
    @Published var loading = true
    @Published var failed = false

    private let defaults = UserDefaults.standard

    init() {
        if let raw = defaults.data(forKey: "school"), let s = try? JSONDecoder().decode(SkolaPolozka.self, from: raw) {
            school = s
        } else {
            school = .vychozi
        }
    }

    var group: String { data.groups.contains("zs") ? "zs" : (data.groups.first ?? "zs") }

    func skupina(_ date: String) -> Skupina? { data.days[date]?[group] }
    func lunch(_ date: String) -> Chod? {
        skupina(date)?.chody.first(where: { $0.c == "obed" }) ?? skupina(date)?.chody.first
    }

    func load() async {
        loading = true; failed = false
        do { data = try await DataService.school(school.id) } catch { failed = data.days.isEmpty }
        loading = false
    }

    func choose(_ s: SkolaPolozka) {
        school = s
        if let raw = try? JSONEncoder().encode(s) { defaults.set(raw, forKey: "school") }
        data = .empty
        Task { await load() }
    }
}

@MainActor
final class WatchSchools: ObservableObject {
    @Published var list: [SkolaPolozka] = []
    @Published var failed = false
    func load() async {
        guard list.isEmpty else { return }
        do {
            list = try await DataService.schools().sorted { $0.jmeno.localizedCaseInsensitiveCompare($1.jmeno) == .orderedAscending }
        } catch { failed = true }
    }
}
