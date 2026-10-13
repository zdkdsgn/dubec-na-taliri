import WidgetKit
import SwiftUI

struct LunchEntry: TimelineEntry {
    let date: Date
    let school: String
    let label: String          // Dnes / Zítra / název dne
    let name: String?
    let desc: String
    let vydej: String?
    let live: Bool
    let nextLabel: String?
    let nextName: String?
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> LunchEntry {
        LunchEntry(date: .now, school: "ZŠ Dubeč", label: "Dnes", name: "Svíčková na smetaně",
                   desc: "Houskový knedlík", vydej: "11:30–13:45", live: false, nextLabel: "Zítra", nextName: "Rizoto")
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
        guard let data = try? await DataService.school(school.id) else {
            return LunchEntry(date: .now, school: school.jmeno, label: "Dnes", name: nil, desc: "", vydej: nil, live: false, nextLabel: nil, nextName: nil)
        }
        let group = data.groups.contains("zs") ? "zs" : (data.groups.first ?? "zs")
        func lunch(_ d: String) -> (Chod, String?)? {
            guard let sk = data.days[d]?[group], let m = sk.chody.first(where: { $0.c == "obed" }) ?? sk.chody.first else { return nil }
            return (m, sk.vydej)
        }
        let today = Cal.today
        let days = data.days.keys.sorted().filter { $0 >= today && lunch($0) != nil }
        func label(_ d: String) -> String {
            d == today ? "Dnes" : d == Cal.add(today, days: 1) ? "Zítra" : Cal.dowName(d)
        }
        guard let first = days.first, let (m, v) = lunch(first) else {
            return LunchEntry(date: .now, school: school.jmeno, label: "Dnes", name: nil, desc: "", vydej: nil, live: false, nextLabel: nil, nextName: nil)
        }
        let next = days.dropFirst().first
        let live = first == today && MenuLogic.vydejStav(date: first, vydej: v) == .bezi
        return LunchEntry(date: .now, school: school.jmeno, label: label(first), name: m.n, desc: m.d, vydej: v, live: live,
                          nextLabel: next.map(label), nextName: next.flatMap { lunch($0)?.0.n })
    }
}

struct SkolaWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: LunchEntry

    var body: some View {
        switch family {
        case .accessoryInline:
            Text("🍽 \(entry.name ?? "Bez oběda")")
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "fork.knife").font(.system(size: 20, weight: .semibold))
            }
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 1) {
                Text(entry.label.uppercased() + (entry.live ? " · VYDÁVÁ SE" : "")).font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
                Text(entry.name ?? "Bez oběda").font(.system(size: 15, weight: .semibold)).lineLimit(2)
                if let v = entry.vydej { Text(v).font(.system(size: 11)).foregroundStyle(.secondary) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        #if os(watchOS)
        case .accessoryCorner:
            Image(systemName: "fork.knife").font(.system(size: 22, weight: .semibold))
                .widgetLabel { Text(entry.name ?? "Bez oběda") }
        #endif
        #if os(iOS)
        case .systemMedium:
            HStack(alignment: .top, spacing: 14) {
                block(entry.label, entry.name, desc: entry.desc, vydej: entry.vydej, big: true)
                if let n = entry.nextName {
                    Divider()
                    block(entry.nextLabel ?? "", n, desc: "", vydej: nil, big: false)
                }
            }
            .containerBackground(gradient, for: .widget)
        default:
            block(entry.label, entry.name, desc: entry.desc, vydej: entry.vydej, big: true)
                .containerBackground(gradient, for: .widget)
        #else
        default:
            Text(entry.name ?? "Bez oběda")
        #endif
        }
    }

    private var gradient: LinearGradient {
        LinearGradient(colors: [Color.green.opacity(0.30), Color.green.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private func block(_ label: String, _ name: String?, desc: String, vydej: String?, big: Bool) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 5) {
                if entry.live && big { Circle().fill(Color.green).frame(width: 6, height: 6) }
                Text(label.uppercased()).font(.system(size: 11, weight: .bold)).tracking(0.8).foregroundStyle(.secondary)
            }
            Text(name ?? "Bez oběda").font(.system(size: big ? 17 : 14, weight: .bold)).lineLimit(big ? 3 : 4).minimumScaleFactor(0.8)
            if !desc.isEmpty && big { Text(desc).font(.system(size: 12)).foregroundStyle(.secondary).lineLimit(2) }
            Spacer(minLength: 0)
            if let v = vydej, big { Text(entry.live ? "Vydává se · \(v)" : v).font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary) }
            else if big { Text(entry.school).font(.system(size: 11)).foregroundStyle(.secondary) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SkolaWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SkolaWidget", provider: Provider()) { entry in
            SkolaWidgetView(entry: entry)
        }
        .configurationDisplayName("Dnešní oběd")
        .description("Co je dnes (a zítra) k obědu ve vybrané škole.")
        .supportedFamilies(Self.families)
    }

    private static var families: [WidgetFamily] {
        #if os(watchOS)
        [.accessoryRectangular, .accessoryInline, .accessoryCircular, .accessoryCorner]
        #else
        [.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline, .accessoryCircular]
        #endif
    }
}

@main
struct SkolaWidgetBundle: WidgetBundle {
    var body: some Widget { SkolaWidget() }
}
