import Foundation
import WatchConnectivity

/// Přijímá z iPhonu oblíbené školy.
final class WatchSync: NSObject, WCSessionDelegate {
    static let shared = WatchSync()
    var onFavorites: (([SkolaPolozka]) -> Void)?

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    private func apply(_ ctx: [String: Any]) {
        guard let raw = ctx["favorites"] as? Data, let list = try? JSONDecoder().decode([SkolaPolozka].self, from: raw) else { return }
        DispatchQueue.main.async { self.onFavorites?(list) }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        apply(session.receivedApplicationContext)
    }
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        apply(applicationContext)
    }
}
