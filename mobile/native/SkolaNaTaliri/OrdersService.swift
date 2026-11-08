import SwiftUI
import WebKit

/// Přihlášené obědy z jidelna.cz (jen čtení). Rodič se přihlásí přímo na webu jidelna.cz v zabudovaném
/// okně – appka heslo nikdy nevidí, drží se jen přihlašovací cookie v WebKitu. Objednávky se čtou
/// z přihlášené stránky jídelního lístku a zůstávají jen v telefonu.

struct OrderMenu: Codable, Hashable { var c: Int; var o: [Bool] }
struct OrderDay: Codable, Hashable { var d: String; var jmena: [String]; var menu: [OrderMenu]; var odhl: [Bool] }

struct OrderSnapshot: Codable {
    var schoolId: String
    var fetched: Date
    var dny: [OrderDay]

    var children: [String] { dny.first(where: { !$0.jmena.isEmpty })?.jmena ?? [] }

    /// Stav jednoho dne pro jedno dítě. nil = den na stránce není (jiný týden).
    func status(_ date: String, child: Int) -> OrderStatus? {
        guard let day = dny.first(where: { $0.d == date }) else { return nil }
        if day.odhl.indices.contains(child), day.odhl[child] { return .opted_out }
        let menus = day.menu.filter { $0.o.indices.contains(child) && $0.o[child] }.map(\.c)
        return menus.isEmpty ? .nothing : .menu(menus)
    }
}

enum OrderStatus: Equatable {
    case menu([Int]), opted_out, nothing
}

@MainActor
final class OrdersService: NSObject, ObservableObject, WKNavigationDelegate {
    @Published private(set) var snapshot: OrderSnapshot?
    @Published private(set) var loggedIn: Bool
    @Published private(set) var busy = false
    @Published var child = 0
    private(set) var demo = false

    private var web: WKWebView?
    private var waiting: CheckedContinuation<String?, Never>?

    override init() {
        let d = UserDefaults.standard
        snapshot = d.data(forKey: "skola.orders").flatMap { try? JSONDecoder().decode(OrderSnapshot.self, from: $0) }
        loggedIn = d.bool(forKey: "skola.ordersLoggedIn")
        super.init()
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-demoOrders") { loadDemo() }
        #endif
    }

    #if DEBUG
    /// Ukázková data pro náhled UI (spuštění s argumentem -demoOrders): dvě děti, různé stavy.
    private func loadDemo() {
        demo = true; loggedIn = true
        let j = ["NOVÁKOVÁ ANIČKA", "NOVÁK KVÍDO"]
        func d(_ iso: String, _ a: (Int?, Bool), _ b: (Int?, Bool)) -> OrderDay {
            OrderDay(d: iso, jmena: j,
                     menu: [OrderMenu(c: 1, o: [a.0 == 1, b.0 == 1]), OrderMenu(c: 2, o: [a.0 == 2, b.0 == 2])],
                     odhl: [a.1, b.1])
        }
        snapshot = OrderSnapshot(schoolId: "47", fetched: Date(), dny: [
            d("2026-11-09", (1, false), (2, false)),
            d("2026-11-10", (1, false), (nil, false)),
            d("2026-11-11", (nil, true), (1, false)),
            d("2026-11-12", (2, false), (1, false)),
            d("2026-11-13", (1, false), (nil, true)),
        ])
    }
    #endif

    /// Jména dětí pro přepínač (prázdné, když není přihlášení nebo je vybraná jiná škola).
    func children(schoolId: String) -> [String] {
        guard loggedIn, let s = snapshot, s.schoolId == schoolId else { return [] }
        return s.children
    }

    /// Stav vybraného dítěte v daný den (nil = bez dat nebo nepřihlášeno).
    func status(_ date: String, schoolId: String) -> OrderStatus? {
        guard loggedIn, let s = snapshot, s.schoolId == schoolId else { return nil }
        return s.status(date, child: min(child, max(s.children.count - 1, 0)))
    }

    /// Menu přihlášená vybranému dítěti na daný den.
    func orderedMenus(_ date: String, schoolId: String) -> [Int] {
        guard loggedIn, let s = snapshot, s.schoolId == schoolId, case .menu(let m)? = s.status(date, child: child) else { return [] }
        return m
    }

    static func pageURL(_ schoolId: String) -> URL? {
        Int(schoolId) == nil ? nil : URL(string: "https://www.jidelna.cz/jidelni-listek/?jidelna=\(schoolId)")
    }

    /// Orders only exist for numeric jidelna.cz schools.
    static func supports(_ schoolId: String) -> Bool { Int(schoolId) != nil }

    // MARK: stažení

    /// Načte jídelní lístek v neviditelném okně a přečte objednávky. Když je rodič odhlášený, jen to zaznamená.
    func refresh(schoolId: String) async {
        guard !demo, Self.supports(schoolId), loggedIn, !busy, let url = Self.pageURL(schoolId) else { return }
        busy = true
        defer { busy = false }
        let wv = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        wv.navigationDelegate = self
        web = wv
        let json: String? = await withCheckedContinuation { cont in
            waiting = cont
            wv.load(URLRequest(url: url, timeoutInterval: 20))
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: 25_000_000_000)
                self?.finish(nil)
            }
        }
        web = nil
        if let json { ingest(json, schoolId: schoolId) }
    }

    private func finish(_ json: String?) {
        guard let c = waiting else { return }
        waiting = nil
        c.resume(returning: json)
    }

    nonisolated func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript(OrdersService.extractJS) { [weak self] result, _ in
            Task { @MainActor in self?.finish(result as? String) }
        }
    }

    nonisolated func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        Task { @MainActor in self.finish(nil) }
    }
    nonisolated func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        Task { @MainActor in self.finish(nil) }
    }

    private struct Extract: Decodable { let prihlasen: Bool; let dny: [OrderDay] }

    /// Zpracuje výsledek extrakce (z neviditelného i z přihlašovacího okna).
    @discardableResult
    func ingest(_ json: String, schoolId: String) -> Bool {
        guard let data = json.data(using: .utf8), let r = try? JSONDecoder().decode(Extract.self, from: data) else { return false }
        setLoggedIn(r.prihlasen)
        guard r.prihlasen else { return false }
        if !r.dny.isEmpty {
            let s = OrderSnapshot(schoolId: schoolId, fetched: Date(), dny: r.dny)
            snapshot = s
            if let d = try? JSONEncoder().encode(s) { UserDefaults.standard.set(d, forKey: "skola.orders") }
        }
        return !r.dny.isEmpty
    }

    private func setLoggedIn(_ v: Bool) {
        loggedIn = v
        UserDefaults.standard.set(v, forKey: "skola.ordersLoggedIn")
    }

    /// Odhlásí rodiče: smaže cookie jidelna.cz i uložené objednávky.
    func logout() async {
        let store = WKWebsiteDataStore.default()
        let records = await store.dataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes())
        await store.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), for: records.filter { $0.displayName.contains("jidelna.cz") })
        snapshot = nil
        UserDefaults.standard.removeObject(forKey: "skola.orders")
        setLoggedIn(false)
    }

    /// Čte DOM jídelního lístku po přihlášení: objednané menu má u buňky strávníka třídu "zvyrazneny".
    static let extractJS = """
    (function () {
      var login = document.querySelector('#snippet--login');
      var res = { prihlasen: !!login && /Přihlášen:/.test(login.innerText), dny: [] };
      var f = document.querySelector('#frm-listek-objednavaciFormular');
      if (!f) return JSON.stringify(res);
      var den = null;
      [].forEach.call(f.querySelectorAll('.hlavicka.row, .menu.row'), function (el) {
        if (el.classList.contains('hlavicka')) {
          var d = el.querySelector('.datum');
          var m = d && d.innerText.match(/(\\d+)\\.\\s*(\\d+)\\.\\s*(\\d{4})/);
          if (!m) { den = null; return; }
          den = { d: m[3] + '-' + ('0' + m[2]).slice(-2) + '-' + ('0' + m[1]).slice(-2),
            jmena: [].map.call(el.querySelectorAll('.stravnik'), function (e) { return e.innerText.trim(); }), menu: [], odhl: [] };
          res.dny.push(den); return;
        }
        if (!den) return;
        var kids = [].slice.call(el.children);
        var ai = kids.findIndex(function (c) { return /alergeny/.test(c.className); });
        var cells = kids.slice(ai >= 0 ? ai + 1 : 0).filter(function (c) {
          return c.querySelector('.volbaUzivatele') || /Volba|col-xs-2/.test(c.className); });
        var stav = cells.map(function (c) {
          return !!(c.classList.contains('zvyrazneny') || c.querySelector('.zvyrazneny') || (c.querySelector('input[type=radio]') || {}).checked); });
        if (el.classList.contains('odhlaseni')) { den.odhl = stav; return; }
        var n = el.innerText.match(/^\\s*(\\d+)/);
        if (n) den.menu.push({ c: parseInt(n[1], 10), o: stav });
      });
      return JSON.stringify(res);
    })()
    """
}

// MARK: přihlašovací okno

struct OrdersLoginView: View {
    @EnvironmentObject var orders: OrdersService
    @Environment(\.dismiss) private var dismiss
    let schoolId: String
    @State private var connected = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let url = OrdersService.pageURL(schoolId) {
                    LoginWeb(url: url) { json in
                        if orders.ingest(json, schoolId: schoolId) { connected = true }
                    }
                }
                Text(connected
                     ? "Přihlášení funguje, objednávky jsou načtené."
                     : "Přihlaste se svým účtem jidelna.cz. Heslo vidí jen jidelna.cz – appka ho nezíská, zapamatuje si jen, že jste přihlášeni.")
                    .font(.system(size: 13)).foregroundStyle(T.ink2).multilineTextAlignment(.center)
                    .padding(12).frame(maxWidth: .infinity).background(T.card)
            }
            .navigationTitle("Přihlášení k jidelna.cz").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button(connected ? "Hotovo" : "Zavřít") { dismiss() } }
            }
        }
    }
}

private struct LoginWeb: UIViewRepresentable {
    let url: URL
    let onPage: (String) -> Void

    func makeCoordinator() -> Coord { Coord(onPage: onPage) }
    func makeUIView(context: Context) -> WKWebView {
        let wv = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        wv.navigationDelegate = context.coordinator
        wv.load(URLRequest(url: url))
        return wv
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coord: NSObject, WKNavigationDelegate {
        let onPage: (String) -> Void
        private var redirected = false
        init(onPage: @escaping (String) -> Void) { self.onPage = onPage }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            let target = webView.url
            webView.evaluateJavaScript(OrdersService.extractJS) { [weak self, onPage] r, _ in
                guard let s = r as? String else { return }
                onPage(s)
                // přihlášen, ale přistál jinde než na lístku → jednou ho otevřeme
                if let self, !self.redirected, s.contains("\"prihlasen\":true"), s.contains("\"dny\":[]"),
                   target?.path.contains("jidelni-listek") != true,
                   let url = URL(string: "https://www.jidelna.cz/jidelni-listek/?jidelna=" + (target.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false)?.queryItems?.first { $0.name == "jidelna" }?.value } ?? "")) {
                    self.redirected = true
                    webView.load(URLRequest(url: url))
                }
            }
        }
    }
}

// MARK: sdílené prvky UI

/// Křestní jméno z „PŘÍJMENÍ JMÉNO“ (jidelna.cz píše příjmení první).
func givenName(_ full: String) -> String {
    (full.split(separator: " ").last.map(String.init) ?? full).capitalized
}

/// Přepínač dětí přes celou šířku (u víc než tří dětí se posouvá).
struct OrderChildPicker: View {
    @EnvironmentObject var orders: OrdersService
    @EnvironmentObject var state: AppState

    var body: some View {
        let names = orders.children(schoolId: state.active.id)
        if names.count > 1 {
            let i = min(orders.child, names.count - 1)
            let items = ForEach(Array(names.enumerated()), id: \.offset) { k, n in
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.snappy) { orders.child = k }
                } label: {
                    Text(givenName(n)).font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(k == i ? T.onAccent : T.ink)
                        .frame(maxWidth: names.count > 3 ? nil : .infinity)
                        .padding(.horizontal, 16).padding(.vertical, 9)
                        .background(k == i ? T.accent : Color.clear, in: Capsule())
                }.buttonStyle(.plain)
            }
            Group {
                if names.count > 3 {
                    ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 4) { items } }
                } else {
                    HStack(spacing: 4) { items }
                }
            }
            .padding(3).background(T.track, in: Capsule())
        }
    }
}

/// Malý stav oběda pod dnem: tečka = přihlášeno, ✕ = odhlášeno, tečkovaný kroužek = nic.
struct OrderGlyph: View {
    @EnvironmentObject var orders: OrdersService
    @EnvironmentObject var state: AppState
    let date: String
    var sel = false

    var body: some View {
        switch orders.status(date, schoolId: state.active.id) {
        case .menu?: Circle().fill(sel ? T.onAccent : T.accent).frame(width: 6, height: 6).frame(height: 13)
        case .opted_out?: Image(systemName: "xmark.circle.fill").font(.system(size: 13))
                .foregroundStyle(sel ? T.onAccent : T.red)
        case .nothing?: Image(systemName: "circle.dotted").font(.system(size: 12))
                .foregroundStyle(sel ? T.onAccent.opacity(0.6) : T.ink3.opacity(0.6))
        case nil: EmptyView()
        }
    }
}
