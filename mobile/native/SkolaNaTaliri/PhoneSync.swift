import Foundation
import WatchConnectivity

/// Posílá na hodinky oblíbené školy (applicationContext – doručí se i když hodinky zrovna nejsou v dosahu).
final class PhoneSync: NSObject, WCSessionDelegate {
    static let shared = PhoneSync()
    private var pending: [SkolaPolozka]?

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func send(favorites: [SkolaPolozka]) {
        guard WCSession.isSupported() else { return }
        pending = favorites
        guard WCSession.default.activationState == .activated, WCSession.default.isWatchAppInstalled,
              let raw = try? JSONEncoder().encode(favorites) else { return }
        try? WCSession.default.updateApplicationContext(["favorites": raw])
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let pending { send(favorites: pending) }
    }
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }
    func sessionWatchStateDidChange(_ session: WCSession) {
        if let pending { send(favorites: pending) }
    }
}
