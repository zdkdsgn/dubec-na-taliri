/* ------------------------------------------------------------------
   Dubeč na talíři — datová vrstva
   Tenhle soubor je jediné místo, kde žijí data jídelníčku.
   V produkci ho nahradí fetch('/api/menu.json') – struktura zůstává.
------------------------------------------------------------------ */

window.MENU_DATA = {
  meta: {
    school: "MŠ & ZŠ Dubeč",
    updated: "2026-09-07T15:30:00+02:00",
    week: "1. 9. – 11. 9. 2026",
    sources: {
      zs: "https://www.jidelna.cz/jidelni-listek/?jidelna=47",
      ms: "https://www.msdubec.cz/stranka-jidelnicek-45"
    },
    /* ZŠ = opsáno z oficiálního jídelního lístku (týden 37).
       MŠ = ukázková data; mateřská škola má na webu stále červenec 2026
            a v žádném veřejném systému (jidelna.cz, strava.cz) registrovaná není. */
    real: { zs: true, ms: false },
    note: "Neoficiální přehled pro rodiče. Změna jídelníčku vyhrazena."
  },

  /* 14 zákonných alergenů dle EU nařízení 1169/2011 */
  allergens: {
    1:  { name: "Obiloviny obsahující lepek", emoji: "🌾", detail: "Pšenice, žito, ječmen, oves, špalda, kamut." },
    2:  { name: "Korýši",                     emoji: "🦐", detail: "Krevety, krabi, langusty a výrobky z nich." },
    3:  { name: "Vejce",                      emoji: "🥚", detail: "Vejce a výrobky z nich." },
    4:  { name: "Ryby",                       emoji: "🐟", detail: "Ryby a výrobky z nich." },
    5:  { name: "Podzemnice olejná (arašídy)",emoji: "🥜", detail: "Arašídy a výrobky z nich." },
    6:  { name: "Sójové boby",                emoji: "🫘", detail: "Sója a výrobky z ní." },
    7:  { name: "Mléko",                      emoji: "🥛", detail: "Mléko a výrobky z něj, včetně laktózy." },
    8:  { name: "Skořápkové plody",           emoji: "🌰", detail: "Mandle, lískové ořechy, vlašské ořechy, kešu, pistácie." },
    9:  { name: "Celer",                      emoji: "🥬", detail: "Celer a výrobky z něj." },
    10: { name: "Hořčice",                    emoji: "🌭", detail: "Hořčice a výrobky z ní." },
    11: { name: "Sezamová semena",            emoji: "🫓", detail: "Sezam a výrobky z něj." },
    12: { name: "Oxid siřičitý a siřičitany", emoji: "🍇", detail: "V koncentraci vyšší než 10 mg/kg." },
    13: { name: "Vlčí bob (lupina)",          emoji: "🌱", detail: "Lupina a výrobky z ní." },
    14: { name: "Měkkýši",                    emoji: "🐚", detail: "Mušle, chobotnice, šneci a výrobky z nich." }
  },

  /* Typy chodů – pořadí určuje pořadí v denní ose */
  courses: {
    presnidavka: { label: "Přesnídávka",       icon: "sun",   time: "8:45",  tone: "amber"  },
    polevka:     { label: "Polévka",           icon: "bowl",  time: "11:40", tone: "orange" },
    obed:        { label: "Hlavní chod",       icon: "fork",  time: "11:45", tone: "green"  },
    obed2:       { label: "Hlavní chod II",    icon: "fork2", time: "11:45", tone: "blue"   },
    svacina:     { label: "Odpolední svačina", icon: "cookie",time: "14:30", tone: "purple" }
  },

  /* days[ISO datum][skupina] = pole chodů */
  days: {
    /* ── Týden 36 – jen ZŠ (MŠ svůj jídelníček nezveřejnila) ─────── */
    "2026-09-01": {
      zs: [
        { c: "polevka", n: "Vločková", d: "", a: [1,7,9] },
        { c: "obed", n: "Bulgur s červenou řepou a zeleninou", d: "Sypaný sýrem, okurka, čaj / mléko", a: [1,7,9,10] }
      ]
    },
    "2026-09-02": {
      zs: [
        { c: "polevka", n: "Zeleninová s luštěninovými trhanci", d: "", a: [7,9] },
        { c: "obed", n: "Maso tří chutí", d: "Rýže, ovoce, ovocný čaj / mléčný koktejl", a: [1,6,7,8,10] }
      ]
    },
    "2026-09-03": {
      zs: [
        { c: "polevka", n: "Rybí", d: "", a: [1,4,7,9] },
        { c: "obed", n: "Pečené kuře", d: "Šťouchané brambory s máslem, zelenina s dresinkem, čaj / mléko / voda", a: [3,7,10] }
      ]
    },
    "2026-09-04": {
      zs: [
        { c: "polevka", n: "Vývar s jáhlami", d: "", a: [7,9] },
        { c: "obed", n: "Vepřový guláš", d: "Těstoviny, čaj / mléko / voda", a: [7,9,10] }
      ]
    },

    /* ── Týden 37 ────────────────────────────────────────────────── */
    "2026-09-07": {
      ms: [
        { c: "presnidavka", n: "Ovocný jogurt", d: "Rohlík, hroznové víno, caro", a: [1,7] },
        { c: "polevka", n: "Rajská s tarhoňou", d: "", a: [1] },
        { c: "obed", n: "Čočka tří barev", d: "Vejce, kyselá okurka, mrkev, ochucená voda", a: [1,3] },
        { c: "svacina", n: "Dubečský chléb s máslem", d: "Jahodová marmeláda, pomeranč, mléko", a: [1,7] }
      ],
      zs: [
        { c: "polevka", n: "Zeleninová s krupicovými noky", d: "", a: [1,3,7,9] },
        { c: "obed", n: "Fazolový guláš", d: "Kváskový chléb, ovoce, ovocný čaj / mléko / ochucená voda", a: [1,7,9,10] },
        { c: "obed2", n: "Zeleninový salát s balkánským sýrem", d: "Čočkový chlebíček, ovoce", a: [7,9,10] }
      ]
    },
    "2026-09-08": {
      ms: [
        { c: "presnidavka", n: "Pomazánka z pečeného lilku", d: "Chléb, cherry rajčata, čaj", a: [1,11] },
        { c: "polevka", n: "Drožďová s vejcem", d: "", a: [1,3,9] },
        { c: "obed", n: "Boloňské špagety", d: "Sýr, salát, jablečná šťáva", a: [1,7,9] },
        { c: "svacina", n: "Croissant", d: "Nektarinka, mléko", a: [1,3,7] }
      ],
      zs: [
        { c: "polevka", n: "Špenátová", d: "", a: [7] },
        { c: "obed", n: "Vepřové kotlety na hořčici", d: "Brambory, zelenina s dresinkem, kakao", a: [3,7,9,10] },
        { c: "obed2", n: "Čínské nudle se zeleninou", d: "Zelenina s dresinkem, kakao", a: [1,3,4,6,7,9,10] }
      ]
    },
    "2026-09-09": {
      ms: [
        { c: "presnidavka", n: "Tvarohová pomazánka s pažitkou", d: "Veka, ředkvičky, bílá káva", a: [1,7] },
        { c: "polevka", n: "Gulášová", d: "", a: [1,9] },
        { c: "obed", n: "Sekaná pečeně, brambor", d: "Salát z čerstvého zelí, voda s mátou", a: [1,3,10] },
        { c: "svacina", n: "Ovocný talíř", d: "Piškoty, mléko", a: [1,3,7] }
      ],
      zs: [
        { c: "polevka", n: "Domácí bramboračka", d: "", a: [1,7,9] },
        { c: "obed", n: "Těstoviny s bazalkovým pestem a sýrem", d: "Domácí tvarohovo-smetanový krém s ovocem", a: [1,7] },
        { c: "obed2", n: "Obalovaná ryba (hejk)", d: "Brambory s máslem, tvarohovo-smetanový krém s ovocem", a: [1,3,4,7] }
      ]
    },
    "2026-09-10": {
      ms: [
        { c: "presnidavka", n: "Nutela z lískových oříšků", d: "Chléb, banán, mléko", a: [1,7,8] },
        { c: "polevka", n: "Kmínová s vejcem", d: "", a: [1,3,9] },
        { c: "obed", n: "Krůtí guláš, těstoviny", d: "Kompot, šípkový čaj", a: [1,9] },
        { c: "svacina", n: "Zeleninové tyčinky s dipem", d: "Rohlík, čaj", a: [1,7] }
      ],
      zs: [
        { c: "polevka", n: "Luštěninová", d: "", a: [9] },
        { c: "obed", n: "Dukátové buchtičky s krémem", d: "Ovoce, ovocný čaj, mléko", a: [1,3,7] },
        { c: "obed2", n: "Těstovinový salát se sýrem a zeleninou", d: "Dresink, ovoce", a: [1,3,7,10] }
      ]
    },
    "2026-09-11": {
      ms: [
        { c: "presnidavka", n: "Sýrová pomazánka", d: "Grahamová houska, paprika, kakao", a: [1,7] },
        { c: "polevka", n: "Frankfurtská", d: "", a: [1,7,9,10] },
        { c: "obed", n: "Rybí prsty, bramborová kaše", d: "Citron, salát, voda", a: [1,3,4,7] },
        { c: "svacina", n: "Buchta s povidly", d: "Jablko, mléko", a: [1,3,7] }
      ],
      zs: [
        { c: "polevka", n: "Zeleninová s droždovými knedlíčky", d: "", a: [1,3,7,9] },
        { c: "obed", n: "Vepřové na žampionech", d: "Rýže, mléčný koktejl", a: [7,8] },
        { c: "obed2", n: "Bramborové noky se slaninou a zelím", d: "Mléčný koktejl", a: [1,7,8,10] }
      ]
    }
  }
};
