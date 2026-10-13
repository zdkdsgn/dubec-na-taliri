import SwiftUI

struct InfoView: View {
    @EnvironmentObject var state: AppState
    @Binding var showSchools: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(state.schoolTitle).font(.system(size: 12, weight: .bold)).tracking(1).textCase(.uppercase)
                    .foregroundStyle(T.ink3).padding(.top, 14)
                Text("Info").font(.system(size: 28, weight: .bold)).tracking(-0.8)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Proč appka vznikla").font(.system(size: 16, weight: .bold))
                    Text("Aby šlo na jednom místě jednoduše a přehledně zjistit, co je dnes k obědu – bez přihlašování do systémů jídelen, bez hesel a bez hledání ve složitých webových rozhraních.")
                        .font(.system(size: 14)).foregroundStyle(T.ink2)
                }.padding(16).frame(maxWidth: .infinity, alignment: .leading).card()

                VStack(spacing: 0) {
                    row("Jídelníček aktualizován", state.data.updated.map { $0.formatted(.dateTime.day().month().year().locale(Locale(identifier: "cs_CZ"))) } ?? "–")
                    divider
                    let mon = Cal.monday(state.selectedDate)
                    row("Zobrazený týden", "\(Cal.short(mon)) – \(Cal.short(Cal.add(mon, days: 4)))")
                    divider
                    row("Zdroj dat", state.active.skutecna_data == false ? "Ukázková data" : "Oficiální jídelníček")
                }.padding(.horizontal, 16).card()

                Button { showSchools = true } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "building.2").foregroundStyle(T.ink2).frame(width: 40, height: 40)
                            .background(T.track, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Vaše škola").font(.system(size: 16, weight: .bold)).foregroundStyle(T.ink)
                            Text(state.active.nazev).font(.system(size: 13)).foregroundStyle(T.ink2).multilineTextAlignment(.leading)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(T.ink3)
                    }.padding(14).frame(maxWidth: .infinity).card()
                }.buttonStyle(PressableStyle())

                if let url = URL(string: state.active.web ?? "https://www.jidelna.cz/jidelni-listek/?jidelna=\(state.active.id)") {
                    Link(destination: url) {
                        HStack(spacing: 14) {
                            Image(systemName: "safari").foregroundStyle(T.ink2).frame(width: 40, height: 40)
                                .background(T.track, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Web jídelny").font(.system(size: 16, weight: .bold)).foregroundStyle(T.ink)
                                Text("Jídelníček přímo na webu jídelny.").font(.system(size: 13)).foregroundStyle(T.ink2)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(T.ink3)
                        }.padding(14).frame(maxWidth: .infinity).card()
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Vzhled").font(.system(size: 16, weight: .bold))
                    Picker("", selection: $state.theme) { ForEach(ThemeChoice.allCases) { Text($0.label).tag($0) } }
                        .pickerStyle(.segmented)
                    Toggle("Větší text", isOn: $state.bigText).tint(T.accent).font(.system(size: 15, weight: .medium))
                }.padding(16).card()

                ShareLink(item: URL(string: "https://zdkdsgn.github.io/dubec-na-taliri/")!,
                          message: Text("Jídelníček školní jídelny na jednom talíři – vyzkoušejte appku:")) {
                    Label("Poslat appku dál", systemImage: "square.and.arrow.up").font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(T.accent).frame(maxWidth: .infinity).padding(.vertical, 14).card()
                }
            }
            .padding(.horizontal, 18).padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }

    private var divider: some View { Rectangle().fill(T.cardBorder).frame(height: 1) }
    private func row(_ k: String, _ v: String) -> some View {
        HStack { Text(k).foregroundStyle(T.ink2); Spacer(); Text(v).fontWeight(.semibold) }
            .font(.system(size: 15)).padding(.vertical, 13)
    }
}
