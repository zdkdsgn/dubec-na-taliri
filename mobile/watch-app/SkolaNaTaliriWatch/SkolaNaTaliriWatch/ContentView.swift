import SwiftUI

struct ContentView: View {
    @StateObject private var model = JidelnicekModel()
    @State private var ukazatVyber = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if model.nacita && model.dnes == nil {
                        ProgressView().frame(maxWidth: .infinity).padding(.top, 24)
                    } else if let chyba = model.chyba {
                        Text(chyba)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        DenKarta(titulek: "Dnes", den: model.dnes)
                        if let zitra = model.zitra {
                            Divider()
                            DenKarta(titulek: "Zítra", den: zitra)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
            .navigationTitle(model.skolaNazev)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        ukazatVyber = true
                    } label: {
                        Image(systemName: "building.2")
                    }
                }
            }
            .sheet(isPresented: $ukazatVyber) {
                NavigationStack {
                    SkolaVyberView(aktualniId: model.skolaId) { polozka in
                        model.vyberSkolu(polozka)
                        ukazatVyber = false
                    }
                }
            }
            .task { await model.nacistPokudTreba() }
            .refreshable { await model.nacist() }
        }
    }
}

private struct DenKarta: View {
    let titulek: String
    let den: DenNahled?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(titulek.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if let den, titulek == "Dnes" {
                    Stavovka(stav: den.stav)
                }
            }
            if let obed = den?.obed {
                Text(obed.n)
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
                if let d = obed.d, !d.isEmpty {
                    Text(d)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let vydej = den?.vydej {
                    Text(vydej)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            } else {
                Text("Bez oběda")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct Stavovka: View {
    let stav: VydejStav

    var body: some View {
        switch stav {
        case .bezi:
            Text("Vydává se")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.green)
        case .po:
            Text("Vydáno")
                .font(.caption2)
                .foregroundStyle(.secondary)
        case .pred:
            EmptyView()
        }
    }
}

#Preview {
    ContentView()
}
