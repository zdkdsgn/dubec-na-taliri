# Mobilní appky

## `native/` – nativní SwiftUI appka (iPhone + vestavěné Apple Watch)

Hlavní směr: jedna Xcode appka `SkolaNaTaliri` (iOS 26+, Liquid Glass) s vestavěnou
hodinkovou appkou. Sdílený kód v `Shared/` (modely, načítání dat z GitHub Pages,
logika výdeje). Otevřít: `mobile/native/SkolaNaTaliri.xcodeproj`. Projekt generuje
`gen_project.rb` (`LANG=en_US.UTF-8 ruby gen_project.rb`, kvůli diakritice v cestě).
Pro TestFlight: v Xcode přihlásit placený účet, nastavit Team u obou targetů a
Product → Archive.

## Starší prototypy


Experimentální nativní obaly appky – nejsou součástí nasazené PWA na GitHub Pages,
žijí tu jen pro budoucí práci.

## `watch-app/` – nativní watchOS appka

Samostatná appka pro Apple Watch (`WKWatchOnly`, žádný iPhone není potřeba). Ukazuje
dnešní a zítřejší oběd, stažené přímo z `https://zdkdsgn.github.io/dubec-na-taliri/`,
a umožňuje vybrat libovolnou z 200+ škol (výběr se ukládá).

Otevřít: `mobile/watch-app/SkolaNaTaliriWatch/SkolaNaTaliriWatch.xcodeproj`

Projekt je vygenerovaný přes `gen_project.rb` (Ruby gem `xcodeproj`) – při přidání
dalšího `.swift` souboru stačí ho zapsat do pole v `gen_project.rb` a skript spustit
znovu (přepíše `.xcodeproj`).

## `ios-wrapper/` – Capacitor obal pro iPhone

Tenký nativní iOS obal, co jen načítá živou appku z GitHub Pages
(`capacitor.config.json` → `server.url`). Otevřít: `mobile/ios-wrapper/ios/App/App.xcodeproj`.
Po `npm install` v `mobile/ios-wrapper/` jde přegenerovat přes `npx cap sync ios`.

## Nasazení na vlastní zařízení (zdarma, bez Developer účtu)

1. V Xcode: **Signing & Capabilities** → Team = tvůj Apple ID ("Personal Team")
2. Připoj iPhone (a přes něj hodinky) k Macu, odklepni důvěru
3. Vyber zařízení jako cíl a **Run**
4. U hodinek (zvlášť starších modelů se slabším Bluetooth/Wi-Fi spojením k Macu):
   **Product → Scheme → Edit Scheme → Run → Info → odškrtnout "Debug executable"** –
   jinak appka čeká na debugger přes nestabilní spojení a zůstane věčně na loading
   kolečku
5. Appka takhle nahraná vyprší za 7 dní (bez placeného Developer účtu) – stačí
   zopakovat krok 3

Podrobnější troubleshooting (Developer Mode na hodinkách, "networking error",
AP izolace na routeru) viz historie konverzace, kde tenhle prototyp vznikl.
