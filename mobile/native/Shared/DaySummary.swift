import Foundation

/// Souhrn jednoho dne pro widget, complication a hodinky: polévka, všechny hlavní
/// chody (každý se svou přílohou) a společná nabídka "Na výběr".
struct DaySummary {
    struct Main: Identifiable {
        let name: String
        let desc: String
        var id: String { name }
    }

    var soup: String?
    var mains: [Main]
    var choice: String?
    var vydej: String?

    var isEmpty: Bool { soup == nil && mains.isEmpty }

    init?(_ sk: Skupina?) {
        guard let sk, !sk.chody.isEmpty else { return nil }
        let ocas = MenuLogic.spolecnyOcas(sk.chody)
        soup = sk.chody.first(where: { $0.c == "polevka" })?.n
        var hlavni = sk.chody.filter { $0.c == "obed" || $0.c == "obed2" }
        // školky bez "obed" (jen přesnídávka/svačina) – ukážeme aspoň to, co je
        if hlavni.isEmpty { hlavni = sk.chody.filter { $0.c != "polevka" } }
        mains = hlavni.map { Main(name: $0.n, desc: MenuLogic.vlastniPopis($0, ocas: ocas)) }
        choice = ocas.isEmpty ? nil : ocas.joined(separator: " · ")
        vydej = sk.vydej
    }
}
