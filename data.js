/* ------------------------------------------------------------------
   Dubeč na talíři — datová vrstva

   GENEROVANÝ SOUBOR – needitujte ho ručně.
   Zdroj: menu/base.json, menu/ms.json, menu/zs.json
   Přegeneruje ho: python3 tools/update-menu.py
------------------------------------------------------------------ */

window.MENU_DATA = {
  meta: {
    school: "MŠ & ZŠ Dubeč",
    updated: "2026-09-11T10:52:51+02:00",
    week: "2026-09-01 – 2026-09-18",
    sources: {
      zs: "https://www.jidelna.cz/jidelni-listek/?jidelna=47",
      ms: "https://www.msdubec.cz/stranka-jidelnicek-45"
    },
    real: {
      zs: true,
      ms: false
    },
    note: "Neoficiální přehled pro rodiče. Změna jídelníčku vyhrazena."
  },
  allergens: {
    "1": {
      name: "Obiloviny obsahující lepek",
      emoji: "🌾",
      detail: "Pšenice, žito, ječmen, oves, špalda, kamut."
    },
    "2": {
      name: "Korýši",
      emoji: "🦐",
      detail: "Krevety, krabi, langusty a výrobky z nich."
    },
    "3": {
      name: "Vejce",
      emoji: "🥚",
      detail: "Vejce a výrobky z nich."
    },
    "4": {
      name: "Ryby",
      emoji: "🐟",
      detail: "Ryby a výrobky z nich."
    },
    "5": {
      name: "Podzemnice olejná (arašídy)",
      emoji: "🥜",
      detail: "Arašídy a výrobky z nich."
    },
    "6": {
      name: "Sójové boby",
      emoji: "🫘",
      detail: "Sója a výrobky z ní."
    },
    "7": {
      name: "Mléko",
      emoji: "🥛",
      detail: "Mléko a výrobky z něj, včetně laktózy."
    },
    "8": {
      name: "Skořápkové plody",
      emoji: "🌰",
      detail: "Mandle, lískové ořechy, vlašské ořechy, kešu, pistácie."
    },
    "9": {
      name: "Celer",
      emoji: "🥬",
      detail: "Celer a výrobky z něj."
    },
    "10": {
      name: "Hořčice",
      emoji: "🌭",
      detail: "Hořčice a výrobky z ní."
    },
    "11": {
      name: "Sezamová semena",
      emoji: "🫓",
      detail: "Sezam a výrobky z něj."
    },
    "12": {
      name: "Oxid siřičitý a siřičitany",
      emoji: "🍇",
      detail: "V koncentraci vyšší než 10 mg/kg."
    },
    "13": {
      name: "Vlčí bob (lupina)",
      emoji: "🌱",
      detail: "Lupina a výrobky z ní."
    },
    "14": {
      name: "Měkkýši",
      emoji: "🐚",
      detail: "Mušle, chobotnice, šneci a výrobky z nich."
    }
  },
  courses: {
    presnidavka: {
      label: "Přesnídávka",
      icon: "sun",
      tone: "amber"
    },
    polevka: {
      label: "Polévka",
      icon: "bowl",
      tone: "orange"
    },
    obed: {
      label: "Hlavní chod",
      icon: "fork",
      tone: "green"
    },
    obed2: {
      label: "Hlavní chod II",
      icon: "fork2",
      tone: "blue"
    },
    svacina: {
      label: "Odpolední svačina",
      icon: "cookie",
      tone: "purple"
    }
  },
  days: {
    "2026-09-01": {
      zs: [
          {"c": "polevka", "n": "Vločková", "d": "", "a": [1, 7, 9]},
          {"c": "obed", "n": "Bulgur s červenou řepou a zeleninou", "d": "Sypaný sýrem, okurka, čaj / mléko", "a": [1, 7, 9, 10]}
        ]
    },
    "2026-09-02": {
      zs: [
          {"c": "polevka", "n": "Zeleninová s luštěninovými trhánky", "d": "", "a": [7, 9]},
          {"c": "obed", "n": "Maso tří chutí", "d": "Rýže · Ovoce · Ovocný čaj, mléčný koktejl", "a": [1, 6, 7, 8, 10], "p": [{"l": "Jídlo", "n": "Maso tří chutí", "a": [1, 6, 10]}, {"l": "Příloha", "n": "Rýže", "a": []}, {"l": "Doplněk", "n": "Ovoce", "a": []}, {"l": "Nápoj", "n": "Ovocný čaj, mléčný koktejl", "a": [7, 8]}]}
        ],
      vydej: {
        zs: "11:30–13:45"
      }
    },
    "2026-09-03": {
      zs: [
          {"c": "polevka", "n": "Rybí", "d": "", "a": [1, 4, 7, 9]},
          {"c": "obed", "n": "Pečené kuře", "d": "Brambory s máslem, mačkané · Zelenina – dresink · Čaj, mléko, voda", "a": [3, 7, 10], "p": [{"l": "Jídlo", "n": "Pečené kuře", "a": []}, {"l": "Příloha", "n": "Brambory s máslem, mačkané", "a": [7]}, {"l": "Doplněk", "n": "Zelenina – dresink", "a": [3, 7, 10]}, {"l": "Nápoj", "n": "Čaj, mléko, voda", "a": [7]}]}
        ],
      vydej: {
        zs: "11:30–13:45"
      }
    },
    "2026-09-04": {
      zs: [
          {"c": "polevka", "n": "Vývar s jáhlami", "d": "", "a": [7, 9]},
          {"c": "obed", "n": "Vepřový guláš", "d": "Těstoviny · Čaj, mléko, voda", "a": [7, 9, 10], "p": [{"l": "Jídlo", "n": "Vepřový guláš", "a": [9, 10]}, {"l": "Příloha", "n": "Těstoviny", "a": []}, {"l": "Nápoj", "n": "Čaj, mléko, voda", "a": [7]}]}
        ],
      vydej: {
        zs: "11:30–13:45"
      }
    },
    "2026-09-07": {
      zs: [
          {"c": "polevka", "n": "Zeleninová s krupicovými noky", "d": "", "a": [1, 3, 7, 9]},
          {"c": "obed", "n": "Fazolový guláš", "d": "Kváskový chléb · Ovoce · Ovocný čaj, mléko, ochucená voda", "a": [1, 7, 9, 10], "p": [{"l": "Jídlo", "n": "Fazolový guláš", "a": [9, 10]}, {"l": "Příloha", "n": "Kváskový chléb", "a": [1]}, {"l": "Doplněk", "n": "Ovoce", "a": []}, {"l": "Nápoj", "n": "Ovocný čaj, mléko, ochucená voda", "a": [7]}]},
          {"c": "obed2", "n": "Zeleninový salát s balkanským sýrem", "d": "Čočkový chlebíček · Ovoce · Ovocný čaj, mléko, ochucená voda", "a": [7, 9, 10], "p": [{"l": "Jídlo", "n": "Zeleninový salát s balkanským sýrem", "a": [7, 9, 10]}, {"l": "Příloha", "n": "Čočkový chlebíček", "a": []}, {"l": "Doplněk", "n": "Ovoce", "a": []}, {"l": "Nápoj", "n": "Ovocný čaj, mléko, ochucená voda", "a": [7]}]}
        ],
      ms: [
          {"c": "presnidavka", "n": "Ovocný jogurt", "d": "Rohlík, hroznové víno, caro", "a": [1, 7]},
          {"c": "polevka", "n": "Rajská s tarhoňou", "d": "", "a": [1]},
          {"c": "obed", "n": "Čočka tří barev", "d": "Vejce, kyselá okurka, mrkev, ochucená voda", "a": [1, 3]},
          {"c": "svacina", "n": "Dubečský chléb s máslem", "d": "Jahodová marmeláda, pomeranč, mléko", "a": [1, 7]}
        ],
      vydej: {
        zs: "11:30–13:45"
      }
    },
    "2026-09-08": {
      zs: [
          {"c": "polevka", "n": "Špenátová", "d": "", "a": [7]},
          {"c": "obed", "n": "Vepřové kotlety na hořčici", "d": "Brambory · Zelenina – dresink · Ovocný čaj, kakao", "a": [3, 7, 9, 10], "p": [{"l": "Jídlo", "n": "Vepřové kotlety na hořčici", "a": [10]}, {"l": "Příloha", "n": "Brambory", "a": []}, {"l": "Doplněk", "n": "Zelenina – dresink", "a": [3, 7, 9, 10]}, {"l": "Nápoj", "n": "Ovocný čaj, kakao", "a": [7]}]},
          {"c": "obed2", "n": "Čínské nudle se zeleninou", "d": "Zelenina – dresink · Ovocný čaj, kakao", "a": [1, 3, 4, 6, 7, 9, 10], "p": [{"l": "Jídlo", "n": "Čínské nudle se zeleninou", "a": [1, 4, 6, 9]}, {"l": "Doplněk", "n": "Zelenina – dresink", "a": [3, 7, 9, 10]}, {"l": "Nápoj", "n": "Ovocný čaj, kakao", "a": [7]}]}
        ],
      ms: [
          {"c": "presnidavka", "n": "Pomazánka z pečeného lilku", "d": "Chléb, cherry rajčata, čaj", "a": [1, 11]},
          {"c": "polevka", "n": "Drožďová s vejcem", "d": "", "a": [1, 3, 9]},
          {"c": "obed", "n": "Boloňské špagety", "d": "Sýr, salát, jablečná šťáva", "a": [1, 7, 9]},
          {"c": "svacina", "n": "Croissant", "d": "Nektarinka, mléko", "a": [1, 3, 7]}
        ],
      vydej: {
        zs: "11:30–13:45"
      }
    },
    "2026-09-09": {
      zs: [
          {"c": "polevka", "n": "Domácí bramboračka", "d": "", "a": [1, 7, 9]},
          {"c": "obed", "n": "Těstoviny s bazalkovým pestem, sýr", "d": "Domácí tvarohovo-smetanový krém s ovocem · Ovocný čaj, mléko, ochucená voda", "a": [1, 7], "p": [{"l": "Jídlo", "n": "Těstoviny s bazalkovým pestem, sýr", "a": [1, 7]}, {"l": "Doplněk", "n": "Domácí tvarohovo-smetanový krém s ovocem", "a": [7]}, {"l": "Nápoj", "n": "Ovocný čaj, mléko, ochucená voda", "a": [7]}]},
          {"c": "obed2", "n": "Obalovaná ryba (hejk)", "d": "Brambory s máslem, mačkané · Domácí tvarohovo-smetanový krém s ovocem · Ovocný čaj, mléko, ochucená voda", "a": [1, 3, 4, 7], "p": [{"l": "Jídlo", "n": "Obalovaná ryba (hejk)", "a": [1, 3, 4, 7]}, {"l": "Příloha", "n": "Brambory s máslem, mačkané", "a": [7]}, {"l": "Doplněk", "n": "Domácí tvarohovo-smetanový krém s ovocem", "a": [7]}, {"l": "Nápoj", "n": "Ovocný čaj, mléko, ochucená voda", "a": [7]}]}
        ],
      ms: [
          {"c": "presnidavka", "n": "Tvarohová pomazánka s pažitkou", "d": "Veka, ředkvičky, bílá káva", "a": [1, 7]},
          {"c": "polevka", "n": "Gulášová", "d": "", "a": [1, 9]},
          {"c": "obed", "n": "Sekaná pečeně, brambor", "d": "Salát z čerstvého zelí, voda s mátou", "a": [1, 3, 10]},
          {"c": "svacina", "n": "Ovocný talíř", "d": "Piškoty, mléko", "a": [1, 3, 7]}
        ],
      vydej: {
        zs: "11:30–13:45"
      }
    },
    "2026-09-10": {
      zs: [
          {"c": "polevka", "n": "Luštěninová", "d": "", "a": [9]},
          {"c": "obed", "n": "Dukátové buchtičky s krémem", "d": "Ovoce · Ovocný čaj, mléko", "a": [1, 3, 7], "p": [{"l": "Jídlo", "n": "Dukátové buchtičky s krémem", "a": [1, 3, 7]}, {"l": "Doplněk", "n": "Ovoce", "a": []}, {"l": "Nápoj", "n": "Ovocný čaj, mléko", "a": [7]}]},
          {"c": "obed2", "n": "Těstovinový salát se sýrem a zeleninou, dresink", "d": "Ovoce · Ovocný čaj, mléko", "a": [1, 3, 7, 10], "p": [{"l": "Jídlo", "n": "Těstovinový salát se sýrem a zeleninou, dresink", "a": [1, 3, 7, 10]}, {"l": "Doplněk", "n": "Ovoce", "a": []}, {"l": "Nápoj", "n": "Ovocný čaj, mléko", "a": [7]}]}
        ],
      ms: [
          {"c": "presnidavka", "n": "Nutela z lískových oříšků", "d": "Chléb, banán, mléko", "a": [1, 7, 8]},
          {"c": "polevka", "n": "Kmínová s vejcem", "d": "", "a": [1, 3, 9]},
          {"c": "obed", "n": "Krůtí guláš, těstoviny", "d": "Kompot, šípkový čaj", "a": [1, 9]},
          {"c": "svacina", "n": "Zeleninové tyčinky s dipem", "d": "Rohlík, čaj", "a": [1, 7]}
        ],
      vydej: {
        zs: "11:30–13:45"
      }
    },
    "2026-09-11": {
      zs: [
          {"c": "polevka", "n": "Zeleninová s droždovými knedlíčky", "d": "", "a": [1, 3, 7, 9]},
          {"c": "obed", "n": "Vepřové na žampionech", "d": "Rýže · Ovocný čaj, mléčný koktejl", "a": [7, 8], "p": [{"l": "Jídlo", "n": "Vepřové na žampionech", "a": []}, {"l": "Příloha", "n": "Rýže", "a": []}, {"l": "Nápoj", "n": "Ovocný čaj, mléčný koktejl", "a": [7, 8]}]},
          {"c": "obed2", "n": "Bramborové noky se slaninou a zelím", "d": "Ovocný čaj, mléčný koktejl", "a": [1, 7, 8, 10], "p": [{"l": "Jídlo", "n": "Bramborové noky se slaninou a zelím", "a": [1, 10]}, {"l": "Nápoj", "n": "Ovocný čaj, mléčný koktejl", "a": [7, 8]}]}
        ],
      ms: [
          {"c": "presnidavka", "n": "Sýrová pomazánka", "d": "Grahamová houska, paprika, kakao", "a": [1, 7]},
          {"c": "polevka", "n": "Frankfurtská", "d": "", "a": [1, 7, 9, 10]},
          {"c": "obed", "n": "Rybí prsty, bramborová kaše", "d": "Citron, salát, voda", "a": [1, 3, 4, 7]},
          {"c": "svacina", "n": "Buchta s povidly", "d": "Jablko, mléko", "a": [1, 3, 7]}
        ],
      vydej: {
        zs: "11:30–13:45"
      }
    },
    "2026-09-14": {
      zs: [
          {"c": "polevka", "n": "Kapustová s bramborem", "d": "", "a": [7]},
          {"c": "obed", "n": "Kuře na paprice", "d": "Celozrné těstoviny · Ovoce · Ovocný čaj, mléko, ochucená voda", "a": [1, 7], "p": [{"l": "Jídlo", "n": "Kuře na paprice", "a": [1, 7]}, {"l": "Příloha", "n": "Celozrné těstoviny", "a": [1]}, {"l": "Doplněk", "n": "Ovoce", "a": []}, {"l": "Nápoj", "n": "Ovocný čaj, mléko, ochucená voda", "a": [7]}]},
          {"c": "obed2", "n": "Zeleninový salát s tuňákem, toustík", "d": "Ovoce · Ovocný čaj, mléko, ochucená voda", "a": [1, 3, 4, 7, 10], "p": [{"l": "Jídlo", "n": "Zeleninový salát s tuňákem, toustík", "a": [1, 3, 4, 7, 10]}, {"l": "Doplněk", "n": "Ovoce", "a": []}, {"l": "Nápoj", "n": "Ovocný čaj, mléko, ochucená voda", "a": [7]}]}
        ],
      vydej: {
        zs: "11:30–13:45"
      }
    },
    "2026-09-15": {
      zs: [
          {"c": "polevka", "n": "Zeleninová se sýrem, svítkem", "d": "", "a": [1, 3, 7, 9]},
          {"c": "obed", "n": "Filet sumečka", "d": "Brambory s pažitkou s máslem, mačkané · Zelenina – dresink · Ovocný čaj, mléčný koktejl", "a": [3, 4, 7, 8, 10], "p": [{"l": "Jídlo", "n": "Filet sumečka", "a": [4]}, {"l": "Příloha", "n": "Brambory s pažitkou s máslem, mačkané", "a": [7]}, {"l": "Doplněk", "n": "Zelenina – dresink", "a": [3, 7, 10]}, {"l": "Nápoj", "n": "Ovocný čaj, mléčný koktejl", "a": [7, 8]}]},
          {"c": "obed2", "n": "Rýžový nákyp s ovocem", "d": "Zelenina – dresink · Ovocný čaj, mléčný koktejl", "a": [3, 7, 8, 10], "p": [{"l": "Jídlo", "n": "Rýžový nákyp s ovocem", "a": [3, 7]}, {"l": "Doplněk", "n": "Zelenina – dresink", "a": [3, 7, 10]}, {"l": "Nápoj", "n": "Ovocný čaj, mléčný koktejl", "a": [7, 8]}]}
        ],
      vydej: {
        zs: "11:30–13:45"
      }
    },
    "2026-09-16": {
      zs: [
          {"c": "polevka", "n": "Hovězí vývar s těstovinou", "d": "", "a": [1, 7, 9]},
          {"c": "obed", "n": "Hovězí svíčková na smetaně, brusinky", "d": "Houskové knedlíky · Ovocný čaj, mléko, ochucená voda", "a": [1, 3, 7, 9], "p": [{"l": "Jídlo", "n": "Hovězí svíčková na smetaně, brusinky", "a": [1, 7, 9]}, {"l": "Příloha", "n": "Houskové knedlíky", "a": [1, 3, 7]}, {"l": "Nápoj", "n": "Ovocný čaj, mléko, ochucená voda", "a": [7]}]},
          {"c": "obed2", "n": "Zeleninový salát s červenou řepou, pečivo", "d": "Ovocný čaj, mléko, ochucená voda", "a": [1, 3, 7, 9, 10], "p": [{"l": "Jídlo", "n": "Zeleninový salát s červenou řepou, pečivo", "a": [1, 3, 7, 9, 10]}, {"l": "Nápoj", "n": "Ovocný čaj, mléko, ochucená voda", "a": [7]}]}
        ],
      vydej: {
        zs: "11:30–13:45"
      }
    },
    "2026-09-17": {
      zs: [
          {"c": "polevka", "n": "Krémová mrkvová polévka", "d": "", "a": [7]},
          {"c": "obed", "n": "Špagety se sušenými rajčaty, sypané sýrem", "d": "Jogurt s musli (cereálie – čokoláda – kokos) · Čaj, mléko", "a": [1, 7], "p": [{"l": "Jídlo", "n": "Špagety se sušenými rajčaty, sypané sýrem", "a": [1, 7]}, {"l": "Doplněk", "n": "Jogurt s musli (cereálie – čokoláda – kokos)", "a": [1, 7]}, {"l": "Nápoj", "n": "Čaj, mléko", "a": [7]}]},
          {"c": "obed2", "n": "Květákový mozeček", "d": "Brambory s máslem, mačkané · Jogurt s musli (cereálie – čokoláda – kokos) · Čaj, mléko", "a": [1, 3, 7], "p": [{"l": "Jídlo", "n": "Květákový mozeček", "a": [3, 7]}, {"l": "Příloha", "n": "Brambory s máslem, mačkané", "a": [7]}, {"l": "Doplněk", "n": "Jogurt s musli (cereálie – čokoláda – kokos)", "a": [1, 7]}, {"l": "Nápoj", "n": "Čaj, mléko", "a": [7]}]}
        ],
      vydej: {
        zs: "11:30–13:45"
      }
    },
    "2026-09-18": {
      zs: [
          {"c": "polevka", "n": "Čočková", "d": "", "a": []},
          {"c": "obed", "n": "Smetanové karbanátky", "d": "Bramborová kaše s máslem, mačkané · Okurkový salát · Čaj, mléko", "a": [1, 3, 7], "p": [{"l": "Jídlo", "n": "Smetanové karbanátky", "a": [1, 3, 7]}, {"l": "Příloha", "n": "Bramborová kaše s máslem, mačkané", "a": [7]}, {"l": "Doplněk", "n": "Okurkový salát", "a": []}, {"l": "Nápoj", "n": "Čaj, mléko", "a": [7]}]},
          {"c": "obed2", "n": "Kuskus se zeleninou, sypané sýrem", "d": "Okurkový salát · Čaj, mléko", "a": [1, 7], "p": [{"l": "Jídlo", "n": "Kuskus se zeleninou, sypané sýrem", "a": [1, 7]}, {"l": "Doplněk", "n": "Okurkový salát", "a": []}, {"l": "Nápoj", "n": "Čaj, mléko", "a": [7]}]}
        ],
      vydej: {
        zs: "11:30–13:45"
      }
    }
  }
};
