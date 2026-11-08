import SwiftUI
import UserNotifications

/// Večerní upozornění předem (místní, počítají se v telefonu z už stažených dat – bez serveru):
/// v 18:00 den před jídelním dnem, když jídelníček obsahuje hlídaný alergen, nebo když
/// (po přihlášení k jidelna.cz) pro dítě není přihlášený oběd.
@MainActor
final class LocalReminders: ObservableObject {
    @Published private(set) var enabled = UserDefaults.standard.bool(forKey: "skola.reminders")
    @Published private(set) var denied = false
    private let hour = 18
    private let center = UNUserNotificationCenter.current()

    func setEnabled(_ on: Bool) async {
        if on {
            let ok = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
            denied = !ok
            guard ok else { return }
        }
        enabled = on
        UserDefaults.standard.set(on, forKey: "skola.reminders")
        if !on { await clear() }
    }

    private func clear() async {
        let ids = await center.pendingNotificationRequests().map(\.identifier).filter { $0.hasPrefix("rem-") }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    /// Přeplánuje upozornění na nejbližších 7 jídelních dnů.
    func reschedule(state: AppState, orders: OrdersService) async {
        guard enabled, state.hasSchool else { return }
        await clear()
        let group = state.data.groups.contains(state.group) ? state.group : (state.data.groups.first ?? "zs")
        let days = state.data.days.keys.sorted().filter { $0 > Cal.today }.prefix(7)
        for d in days {
            guard let sk = state.data.days[d]?[group] else { continue }
            var lines: [String] = []
            for m in sk.chody where !state.hits(m).isEmpty {
                lines.append("\(m.n): alergen \(state.hits(m).map(String.init).joined(separator: ", "))")
            }
            if lines.count > 2 { lines = Array(lines.prefix(2)) }
            if orders.status(d, schoolId: state.active.id) == .nothing { lines.append("Na tento den není přihlášený oběd.") }
            guard !lines.isEmpty else { continue }

            guard let prev = Cal.cal.date(byAdding: .day, value: -1, to: Cal.date(d)),
                  let fire = Cal.cal.date(bySettingHour: hour, minute: 0, second: 0, of: prev), fire > Date() else { continue }
            let c = UNMutableNotificationContent()
            c.title = "\(Cal.dowName(d)) v jídelně"
            c.body = lines.joined(separator: "\n")
            c.sound = .default
            let comps = Cal.cal.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
            let req = UNNotificationRequest(identifier: "rem-\(d)", content: c,
                                            trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false))
            try? await center.add(req)
        }
    }
}
