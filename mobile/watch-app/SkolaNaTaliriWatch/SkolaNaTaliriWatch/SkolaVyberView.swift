import SwiftUI

struct SkolaVyberView: View {
    @StateObject private var skoly = SkolyModel()
    @State private var hledani = ""
    let aktualniId: String
    let vyber: (SkolaPolozka) -> Void

    private var vyfiltrovane: [SkolaPolozka] {
        guard !hledani.isEmpty else { return skoly.skoly }
        return skoly.skoly.filter {
            $0.zobrazovaneJmeno.localizedCaseInsensitiveContains(hledani)
        }
    }

    var body: some View {
        Group {
            if skoly.nacita && skoly.skoly.isEmpty {
                ProgressView()
            } else if let chyba = skoly.chyba {
                Text(chyba).font(.footnote).foregroundStyle(.secondary)
            } else {
                List(vyfiltrovane) { polozka in
                    Button {
                        vyber(polozka)
                    } label: {
                        HStack {
                            Text(polozka.zobrazovaneJmeno)
                                .multilineTextAlignment(.leading)
                            if polozka.id == aktualniId {
                                Spacer()
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }
                .searchable(text: $hledani, prompt: "Hledat školu")
            }
        }
        .navigationTitle("Vaše škola")
        .task { await skoly.nacistPokudTreba() }
    }
}
