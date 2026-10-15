import WidgetKit
import SwiftUI

struct LunchEntry: TimelineEntry {
    let date: Date
    let school: String
    let label: String          // Dnes / Zítra / název dne
    let day: DaySummary?
    let live: Bool
    let nextLabel: String?
    let next: DaySummary?
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> LunchEntry {
        let sk = Skupina(vydej: "11:30–13:45", chody: [
            Chod.sample("polevka", "Zeleninová s drožďovými knedlíčky", ""),
            Chod.sample("obed", "Svíčková na smetaně", "Houskový knedlík · Čaj, mléko"),
            Chod.sample("obed2", "Zeleninové rizoto", "Strouhaný sýr · Čaj, mléko"),
        ])
        return LunchEntry(date: .now, school: "ZŠ Dubeč", label: "Dnes", day: DaySummary(sk), live: false,
                          nextLabel: "Zítra", next: DaySummary(sk))
    }

    func getSnapshot(in context: Context, completion: @escaping (LunchEntry) -> Void) {
        if context.isPreview { completion(placeholder(in: context)); return }
        Task { completion(await build()) }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LunchEntry>) -> Void) {
        Task {
            let entry = await build()
            // stav výdeje se mění v čase – widget obnovujeme aspoň po půlhodině
            completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(30 * 60))))
        }
    }

    private func build() async -> LunchEntry {
        let school = SharedStore.loadSchool()
        let empty = LunchEntry(date: .now, school: school.jmeno, label: "Dnes", day: nil, live: false, nextLabel: nil, next: nil)
        guard let data = try? await DataService.school(school.id) else { return empty }
        let group = data.groups.contains("zs") ? "zs" : (data.groups.first ?? "zs")
        let today = Cal.today
        let days = data.days.keys.sorted().filter { $0 >= today && DaySummary(data.days[$0]?[group]) != nil }
        func label(_ d: String) -> String {
            d == today ? "Dnes" : d == Cal.add(today, days: 1) ? "Zítra" : Cal.dowName(d)
        }
        guard let first = days.first, let day = DaySummary(data.days[first]?[group]) else { return empty }
        let nextDate = days.dropFirst().first
        let live = first == today && MenuLogic.vydejStav(date: first, vydej: day.vydej) == .bezi
        return LunchEntry(date: .now, school: school.jmeno, label: label(first), day: day, live: live,
                          nextLabel: nextDate.map(label), next: nextDate.flatMap { DaySummary(data.days[$0]?[group]) })
    }
}

extension Chod {
    /// jen pro náhled widgetu v galerii
    static func sample(_ c: String, _ n: String, _ d: String) -> Chod {
        let json = #"{"c":"\#(c)","n":"\#(n)","d":"\#(d)","a":[]}"#
        return try! JSONDecoder().decode(Chod.self, from: Data(json.utf8))
    }
}

// MARK: - Zobrazení

struct SkolaWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: LunchEntry

    var body: some View {
        switch family {
        case .accessoryInline:
            Text("🍽 " + (entry.day.map { $0.mains.map(\.name).joined(separator: " / ") } ?? "Bez oběda"))
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "fork.knife").font(.system(size: 20, weight: .semibold))
            }
        case .accessoryRectangular:
            rectangular
        #if os(watchOS)
        case .accessoryCorner:
            Image(systemName: "fork.knife").font(.system(size: 22, weight: .semibold))
                .widgetLabel { Text(entry.day?.mains.first?.name ?? "Bez oběda") }
        #endif
        #if os(iOS)
        case .systemMedium:
            detail(entry.label, entry.day, full: true).containerBackground(gradient, for: .widget)
        case .systemLarge:
            VStack(alignment: .leading, spacing: 10) {
                detail(entry.label, entry.day, full: true)
                if let next = entry.next, let nl = entry.nextLabel {
                    Divider()
                    detail(nl, next, full: false)
                }
            }
            .containerBackground(gradient, for: .widget)
        default:
            small.containerBackground(gradient, for: .widget)
        #else
        default:
            Text(entry.day?.mains.first?.name ?? "Bez oběda")
        #endif
        }
    }

    private var gradient: LinearGradient {
        LinearGradient(colors: [Color.green.opacity(0.30), Color.green.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    // Zamykací obrazovka / ciferník: hlavní chody (až dva), polévka nad nimi
    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(entry.label.uppercased() + (entry.live ? " · VYDÁVÁ SE" : ""))
                .font(.system(size: 10, weight: .semibold)).foregroundStyle(.secondary).lineLimit(1)
            if let day = entry.day {
                if let soup = day.soup { Text("🥣 " + soup).font(.system(size: 11)).foregroundStyle(.secondary).lineLimit(1) }
                ForEach(day.mains.prefix(2)) { m in
                    Text(m.name).font(.system(size: 13, weight: .semibold)).lineLimit(1)
                }
            } else {
                Text("Bez oběda").font(.system(size: 14, weight: .semibold))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    #if os(iOS)
    private var small: some View {
        VStack(alignment: .leading, spacing: 3) {
            header(entry.label, vydej: nil)
            if let day = entry.day {
                if let soup = day.soup {
                    Text(soup).font(.system(size: 11)).foregroundStyle(.secondary).lineLimit(1).minimumScaleFactor(0.8)
                }
                ForEach(day.mains.prefix(3)) { m in
                    Text(m.name).font(.system(size: 13, weight: .bold)).lineLimit(2).minimumScaleFactor(0.8)
                }
                Spacer(minLength: 0)
                if let v = day.vydej { Text(entry.live ? "Vydává se · \(v)" : v).font(.system(size: 10, weight: .medium)).foregroundStyle(.secondary) }
            } else {
                Text("Bez oběda").font(.system(size: 15, weight: .bold))
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func header(_ label: String, vydej: String?) -> some View {
        HStack(spacing: 5) {
            if entry.live && label == entry.label { Circle().fill(Color.green).frame(width: 6, height: 6) }
            Text(label.uppercased()).font(.system(size: 11, weight: .bold)).tracking(0.8).foregroundStyle(.secondary)
            Spacer(minLength: 0)
            if let vydej { Text(vydej).font(.system(size: 10, weight: .medium)).foregroundStyle(.secondary) }
        }
    }

    /// Polévka, hlavní chody s přílohou a "Na výběr" pro jeden den.
    private func detail(_ label: String, _ day: DaySummary?, full: Bool) -> some View {
        VStack(alignment: .leading, spacing: full ? 5 : 3) {
            header(label, vydej: full ? day?.vydej : nil)
            if let day {
                if let soup = day.soup {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("Polévka").font(.system(size: 10, weight: .bold)).foregroundStyle(.secondary).frame(width: 46, alignment: .leading)
                        Text(soup).font(.system(size: 12)).lineLimit(1)
                    }
                }
                ForEach(day.mains) { m in
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("Hlavní").font(.system(size: 10, weight: .bold)).foregroundStyle(.secondary).frame(width: 46, alignment: .leading)
                        VStack(alignment: .leading, spacing: 0) {
                            Text(m.name).font(.system(size: 13, weight: .bold)).lineLimit(1)
                            if full && !m.desc.isEmpty { Text(m.desc).font(.system(size: 11)).foregroundStyle(.secondary).lineLimit(1) }
                        }
                    }
                }
                if full, let choice = day.choice {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("Výběr").font(.system(size: 10, weight: .bold)).foregroundStyle(.secondary).frame(width: 46, alignment: .leading)
                        Text(choice).font(.system(size: 11)).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
            } else {
                Text("Bez oběda").font(.system(size: 14, weight: .bold))
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    #endif
}

struct SkolaWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SkolaWidget", provider: Provider()) { entry in
            SkolaWidgetView(entry: entry)
        }
        .configurationDisplayName("Dnešní oběd")
        .description("Polévka, hlavní chody a nabídka na výběr ve vybrané škole.")
        .supportedFamilies(Self.families)
    }

    private static var families: [WidgetFamily] {
        #if os(watchOS)
        [.accessoryRectangular, .accessoryInline, .accessoryCircular, .accessoryCorner]
        #else
        [.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular, .accessoryInline, .accessoryCircular]
        #endif
    }
}

@main
struct SkolaWidgetBundle: WidgetBundle {
    var body: some Widget { SkolaWidget() }
}
