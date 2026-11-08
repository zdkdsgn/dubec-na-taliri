import SwiftUI

struct InfoView: View {
    @EnvironmentObject var state: AppState
    @Binding var showSchools: Bool
    @State private var reminder: URL?
    @State private var pushError: String?
    @EnvironmentObject var orders: OrdersService
    @EnvironmentObject var reminders: LocalReminders
    @State private var showLogin = false
    @ObservedObject private var push = PushService.shared

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

                if let i = state.info, i.hasContent { aboutCard(i) }

                if OrdersService.supports(state.active.id) { ordersCard }

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

                Link(destination: URL(string: "https://zdkdsgn.github.io/dubec-na-taliri/soukromi.html")!) {
                    HStack(spacing: 14) {
                        Image(systemName: "hand.raised").foregroundStyle(T.ink2).frame(width: 40, height: 40)
                            .background(T.track, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        Text("Zásady ochrany soukromí").font(.system(size: 16, weight: .bold)).foregroundStyle(T.ink)
                        Spacer()
                        Image(systemName: "arrow.up.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(T.ink3)
                    }.padding(14).frame(maxWidth: .infinity).card()
                }

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

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        Image(systemName: "bell").foregroundStyle(T.ink2).frame(width: 40, height: 40)
                            .background(T.track, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        Text("Upozornění na nový jídelníček").font(.system(size: 16, weight: .bold))
                    }
                    Text("Dáme vědět, jakmile appka stáhne nový jídelníček – zvlášť pro každou školu.")
                        .font(.system(size: 14)).foregroundStyle(T.ink2)
                    ForEach(state.pushCandidates) { s in
                        let on = state.pushSchools.contains(s.id)
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            Task { pushError = await state.togglePush(s) }
                        } label: {
                            HStack {
                                Text(s.jmeno).font(.system(size: 15, weight: .semibold)).foregroundStyle(T.ink)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                                Toggle("", isOn: .constant(on)).labelsHidden().tint(T.accent).allowsHitTesting(false)
                            }
                            .padding(.horizontal, 14).padding(.vertical, 10)
                            .background(on ? T.accentSoft : T.track, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(PressableStyle()).disabled(state.pushBusy)
                    }
                    if let pushError { Text(pushError).font(.system(size: 13)).foregroundStyle(T.red) }
                }.padding(16).frame(maxWidth: .infinity, alignment: .leading).card()
                .task { await push.refreshAuthorization() }

                VStack(alignment: .leading, spacing: 8) {
                    Toggle(isOn: Binding(get: { reminders.enabled }, set: { v in Task { await reminders.setEnabled(v) } })) {
                        HStack(spacing: 12) {
                            Image(systemName: "moon.stars").foregroundStyle(T.ink2).frame(width: 40, height: 40)
                                .background(T.track, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            Text("Večerní upozornění").font(.system(size: 16, weight: .bold))
                        }
                    }.tint(T.accent)
                    Text("V 18:00 den předem napíšeme, když jídelníček obsahuje váš alergen, nebo (po přihlášení k jidelna.cz) když není přihlášený oběd.")
                        .font(.system(size: 14)).foregroundStyle(T.ink2)
                    if reminders.denied {
                        Text("Upozornění jsou v Nastavení iPhonu vypnutá. Povolte je pro Školu na talíři.")
                            .font(.system(size: 13)).foregroundStyle(T.amber)
                    }
                }.padding(16).frame(maxWidth: .infinity, alignment: .leading).card()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Odhlášení z obědů").font(.system(size: 16, weight: .bold))
                    Text("Při nemoci nebo dovolené je potřeba oběd včas odhlásit – řeší se přímo na webu jídelny (karta výše).")
                        .font(.system(size: 14)).foregroundStyle(T.ink2)
                    if let reminder {
                        ShareLink(item: reminder) {
                            Label("Přidat připomínku do kalendáře", systemImage: "calendar.badge.plus")
                                .font(.system(size: 15, weight: .semibold)).foregroundStyle(T.accent)
                                .padding(.vertical, 8)
                        }
                    }
                }.padding(16).frame(maxWidth: .infinity, alignment: .leading).card()
                .onAppear { reminder = state.reminderFile() }

                let top = Array(state.leaderboard.prefix(6))
                if !top.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Co dětem nejvíc chutnalo").font(.system(size: 16, weight: .bold))
                        ForEach(top) { z in
                            HStack {
                                Text(z.nazev).font(.system(size: 14.5)).lineLimit(2)
                                Spacer()
                                HStack(spacing: 8) {
                                    if z.plus > 0 { Text("👍\(z.plus)") }
                                    if z.stred > 0 { Text("😐\(z.stred)") }
                                    if z.minus > 0 { Text("👎\(z.minus)") }
                                }.font(.system(size: 13, weight: .semibold)).foregroundStyle(T.ink2)
                            }
                        }
                    }.padding(16).frame(maxWidth: .infinity, alignment: .leading).card()
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

    private var ordersCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle").foregroundStyle(T.ink2).frame(width: 40, height: 40)
                    .background(T.track, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                Text("Přihlášené obědy").font(.system(size: 16, weight: .bold))
                Text("BETA").font(.system(size: 10, weight: .heavy)).foregroundStyle(T.accent)
                    .padding(.horizontal, 6).padding(.vertical, 2).background(T.accentSoft, in: Capsule())
            }
            if orders.loggedIn {
                let kids = orders.children(schoolId: state.active.id).map(givenName)
                if !kids.isEmpty {
                    Text("Přihlášeno · " + kids.joined(separator: ", ")).font(.system(size: 15, weight: .semibold)).foregroundStyle(T.accent)
                }
                Text(orders.snapshot.map { "Načteno \($0.fetched.formatted(.dateTime.day().month().year().hour().minute().locale(Locale(identifier: "cs_CZ")))). V jídelníčku uvidíte, které menu má dítě přihlášené." }
                     ?? "Přihlášeno. Objednávky se načítají…")
                    .font(.system(size: 14)).foregroundStyle(T.ink2)
                Button { Task { await orders.refresh(schoolId: state.active.id) } } label: {
                    Text(orders.busy ? "Načítám…" : "Obnovit objednávky").font(.system(size: 15, weight: .semibold)).foregroundStyle(T.accent)
                        .frame(maxWidth: .infinity).padding(.vertical, 11)
                        .background(T.accentSoft, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }.disabled(orders.busy).buttonStyle(PressableStyle())
                Divider().padding(.top, 4)
                Button(role: .destructive) { Task { await orders.logout() } } label: {
                    Text("Odhlásit od jidelna.cz").font(.system(size: 14, weight: .medium)).foregroundStyle(T.red)
                }
            } else {
                if orders.expired {
                    Text("Přihlášení vypršelo. Přihlaste se prosím znovu.").font(.system(size: 14, weight: .semibold)).foregroundStyle(T.amber)
                }
                Text("Přihlaste se k jidelna.cz a v jídelníčku uvidíte, na která jídla má vaše dítě přihlášený oběd. Appka jen čte, nic neobjednává ani neodhlašuje, a heslo nikdy nevidí.")
                    .font(.system(size: 14)).foregroundStyle(T.ink2)
                Button { showLogin = true } label: {
                    Text("Přihlásit se").font(.system(size: 15, weight: .semibold)).foregroundStyle(T.accent)
                }
            }
        }.padding(16).frame(maxWidth: .infinity, alignment: .leading).card()
        .sheet(isPresented: $showLogin) {
            OrdersLoginView(schoolId: state.active.id).environmentObject(orders)
        }
    }

    @ViewBuilder private func aboutCard(_ i: SkolaInfo) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("O jídelně").font(.system(size: 16, weight: .bold)).padding(.top, 16).padding(.bottom, 4)
            if let v = i.vydeje, !v.isEmpty {
                ForEach(v, id: \.self) { x in row("Výdej – \(x.chod.lowercased())", x.cas); divider }
            }
            if let a = i.adresa {
                let q = [a, i.psc].compactMap { $0 }.joined(separator: " ")
                linkRow("Adresa", a, URL(string: "https://maps.apple.com/?q=" + (q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")))
                divider
            }
            if let t = i.telefon {
                linkRow("Telefon", t, URL(string: "tel:" + t.replacingOccurrences(of: " ", with: ""))); divider
            }
            if let e = i.email { linkRow(i.email_zdroj == "rejstrik" ? "E-mail školy" : "E-mail", e, URL(string: "mailto:" + e)); divider }
            if let w = i.web { linkRow("Web", w, i.web_url.flatMap(URL.init(string:))); divider }
            if let x = i.vedouci_jidelny { row("Vedoucí jídelny", x); divider }
            if let x = i.vedouci_kuchyne { row("Vedoucí kuchyně", x); divider }
            if let x = i.reditel { row("Ředitel/ka", x); divider }
            if let x = i.ico { row("IČO", x); divider }
            if let x = i.ucet { row("Číslo účtu", x) }
            if i.reditel != nil || i.email_zdroj != nil {
                Text("Údaje o řediteli a e-mail školy: rejstřík škol a školských zařízení, MŠMT.")
                    .font(.system(size: 12)).foregroundStyle(T.ink3).padding(.top, 8).padding(.bottom, 10)
            }
        }.padding(.horizontal, 16).padding(.bottom, 4).frame(maxWidth: .infinity, alignment: .leading).card()
    }

    @ViewBuilder private func linkRow(_ k: String, _ v: String, _ url: URL?) -> some View {
        if let url {
            Link(destination: url) {
                HStack(alignment: .top) {
                    Text(k).foregroundStyle(T.ink2); Spacer(minLength: 16)
                    Text(v).fontWeight(.semibold).foregroundStyle(T.accent).multilineTextAlignment(.trailing)
                }.font(.system(size: 15)).padding(.vertical, 13)
            }
        } else { row(k, v) }
    }

    private var divider: some View { Rectangle().fill(T.cardBorder).frame(height: 1) }
    private func row(_ k: String, _ v: String) -> some View {
        HStack(alignment: .top) { Text(k).foregroundStyle(T.ink2); Spacer(minLength: 16); Text(v).fontWeight(.semibold).multilineTextAlignment(.trailing) }
            .font(.system(size: 15)).padding(.vertical, 13)
    }
}
