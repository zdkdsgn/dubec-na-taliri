import SwiftUI
import UserNotifications

extension Notification.Name {
    static let openSchoolFromPush = Notification.Name("openSchoolFromPush")
}

/// Apple push (APNs): token zařízení + přihlášení/odhlášení odběru školy na naší Cloudflare službě.
@MainActor
final class PushService: ObservableObject {
    static let shared = PushService()
    private let base = URL(string: "https://zs-jidelny.zdkdsgn.workers.dev/")!
    private let tokenKey = "skola.apnsToken"

    #if DEBUG
    private let environment = "sandbox"
    #else
    private let environment = "production"
    #endif

    @Published var denied = false
    private var tokenWaiters: [CheckedContinuation<String?, Never>] = []

    var token: String? { UserDefaults.standard.string(forKey: tokenKey) }

    func refreshAuthorization() async {
        let s = await UNUserNotificationCenter.current().notificationSettings()
        denied = s.authorizationStatus == .denied
    }

    func receivedToken(_ data: Data) {
        let hex = data.map { String(format: "%02x", $0) }.joined()
        UserDefaults.standard.set(hex, forKey: tokenKey)
        tokenWaiters.forEach { $0.resume(returning: hex) }
        tokenWaiters.removeAll()
    }

    func failedToRegister() {
        tokenWaiters.forEach { $0.resume(returning: nil) }
        tokenWaiters.removeAll()
    }

    /// Vrátí token zařízení; při prvním použití vyžádá povolení a zaregistruje se u Apple.
    private func obtainToken() async -> String? {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        await refreshAuthorization()
        guard granted else { return nil }
        UIApplication.shared.registerForRemoteNotifications()
        if let t = token { return t }
        return await withCheckedContinuation { cont in
            tokenWaiters.append(cont)
            Task {
                try? await Task.sleep(nanoseconds: 8_000_000_000)
                if !tokenWaiters.isEmpty { failedToRegister() }
            }
        }
    }

    /// true = povedlo se, false = nepovedlo (povolení zamítnuto, žádný token, síť).
    func setSubscribed(_ on: Bool, schoolId: String) async -> Bool {
        if on {
            guard let t = await obtainToken() else { return false }
            return await post("apns/subscribe", ["token": t, "schoolId": schoolId, "env": environment])
        } else {
            guard let t = token else { return true }
            return await post("apns/unsubscribe", ["token": t, "schoolId": schoolId])
        }
    }

    private func post(_ path: String, _ body: [String: String]) async -> Bool {
        var req = URLRequest(url: base.appendingPathComponent(path))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        req.timeoutInterval = 15
        guard let (_, resp) = try? await URLSession.shared.data(for: req) else { return false }
        return (resp as? HTTPURLResponse)?.statusCode == 200
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Task { @MainActor in PushService.shared.receivedToken(deviceToken) }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Task { @MainActor in PushService.shared.failedToRegister() }
    }

    // notifikace v popředí se ukáže jako banner
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    // klepnutí na notifikaci otevře školu, ke které patří
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        if let id = response.notification.request.content.userInfo["schoolId"] as? String {
            await MainActor.run { NotificationCenter.default.post(name: .openSchoolFromPush, object: id) }
        }
    }
}
