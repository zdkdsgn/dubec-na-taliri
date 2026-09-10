/* ══════════════════════════════════════════════════════════════════
   ZŠ na talíři — aplikační logika
══════════════════════════════════════════════════════════════════ */
(() => {
"use strict";

let D  = window.MENU_DATA;
const $  = (s, r = document) => r.querySelector(s);
const $$ = (s, r = document) => [...r.querySelectorAll(s)];

const DOW  = ["Neděle","Pondělí","Úterý","Středa","Čtvrtek","Pátek","Sobota"];
const DOWS = ["Ne","Po","Út","St","Čt","Pá","So"];

/* ── Ikony (line art, stejný rukopis jako značka) ───────────────── */
const svg = p => `<svg viewBox="0 0 24 24">${p}</svg>`;
const ICON = {
  /* přesnídávka – vycházející slunce */
  presnidavka: svg(`<circle cx="12" cy="12" r="3.9"/><path d="M12 3.4v2.2m0 12.8v2.2M3.4 12h2.2m12.8 0h2.2M6 6l1.6 1.6m8.8 8.8L18 18M18 6l-1.6 1.6M7.6 16.4L6 18"/>`),
  /* polévka – mísa s párou */
  polevka:     svg(`<path d="M3.6 11.4h16.8a8.4 8.4 0 01-16.8 0z"/><path d="M5.8 20h12.4"/><path d="M9.4 7.6c0-1.1 1-1.5 1-2.6s-1-1.6-1-1.6m5.2 4.2c0-1.1 1-1.5 1-2.6s-1-1.6-1-1.6"/>`),
  /* hlavní chod – klosh (servírovací poklop) */
  obed:        svg(`<path d="M3.2 17.4h17.6"/><path d="M4.8 17.4a7.2 7.2 0 0114.4 0"/><path d="M12 10.2V8"/><circle cx="12" cy="6.6" r="1.4"/>`),
  /* druhý chod – salátová mísa s lístkem */
  obed2:       svg(`<path d="M3.6 12.8h16.8a8.4 8.4 0 01-16.8 0z"/><path d="M5.8 20.6h12.4"/><path d="M12 12.8c0-4.2 3.1-7.2 7.2-7.4-.3 3.6-2.6 6.2-5.8 7.1M12 12.8c-.4-2.9-2.2-4.6-4.8-5.1.2 2.4 1.5 4.1 3.4 4.9"/>`),
  /* svačina – sušenka */
  svacina:     svg(`<path d="M20.6 12.2a8.6 8.6 0 11-9-8.6 3 3 0 004 4.1 3 3 0 004.9 4.5z"/><circle cx="9.2" cy="11.6" r=".75"/><circle cx="13.6" cy="14.8" r=".75"/><circle cx="8.6" cy="16" r=".75"/>`),
};
/* klas – plný tvar, aby zůstal čitelný i ve 13px chipu */
const WHEAT = (cls) => `<svg class="${cls}" viewBox="0 0 24 24" fill="currentColor" stroke="none">
  <path d="M12.85 21.6a.85.85 0 01-1.7 0V11.4a.85.85 0 011.7 0z"/>
  <ellipse cx="12" cy="5.6" rx="1.5" ry="3"/>
  <ellipse cx="8.8" cy="11" rx="1.45" ry="2.8" transform="rotate(-38 8.8 11)"/>
  <ellipse cx="15.2" cy="11" rx="1.45" ry="2.8" transform="rotate(38 15.2 11)"/>
  <ellipse cx="8.8" cy="15.8" rx="1.45" ry="2.8" transform="rotate(-38 8.8 15.8)"/>
  <ellipse cx="15.2" cy="15.8" rx="1.45" ry="2.8" transform="rotate(38 15.2 15.8)"/>
</svg>`;
const I_WHEAT = WHEAT("wheat");
const I_INFO  = `<svg class="i" viewBox="0 0 24 24"><circle cx="12" cy="12" r="9"/><path d="M12 11v5m0-8.5v.5"/></svg>`;

/* ── Datum ──────────────────────────────────────────────────────── */
const iso   = d => `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,"0")}-${String(d.getDate()).padStart(2,"0")}`;
const parse = s => { const [y,m,d] = s.split("-").map(Number); return new Date(y, m-1, d); };
const addD  = (s,n) => { const d = parse(s); d.setDate(d.getDate()+n); return iso(d); };
const monday= s => { const d = parse(s); d.setDate(d.getDate()-((d.getDay()+6)%7)); return iso(d); };
const short = s => { const d = parse(s); return `${d.getDate()}. ${d.getMonth()+1}.`; };
const TODAY = iso(new Date());

/* ── Stav ───────────────────────────────────────────────────────── */
const store = {
  get(k,f){ try{ return JSON.parse(localStorage.getItem("dubec:"+k)) ?? f; }catch{ return f; } },
  set(k,v){ try{ localStorage.setItem("dubec:"+k, JSON.stringify(v)); }catch{} }
};
/* první den, pro který existují jakákoli data (víkend → pondělí) */
function nearestSchoolDay(from){
  for (let i = 0; i < 14; i++) if (D.days[addD(from,i)]) return addD(from,i);
  const keys = Object.keys(D.days).sort();
  return keys.find(k => k >= from) || keys[keys.length-1];
}
const S = {
  school: store.get("school","zs"),
  date  : nearestSchoolDay(TODAY),
  view  : "den",
  filter: new Set(store.get("filter",[])),
  rating: store.get("rating",{}),
  theme : store.get("theme","auto"),    /* auto | light | dark */
  oblibene: new Set(store.get("oblibene",[]))
};

/* ── Vzhled ─────────────────────────────────────────────────────── */
function applyTheme(){
  const root = document.documentElement;
  if (S.theme === "auto") root.removeAttribute("data-theme");
  else root.setAttribute("data-theme", S.theme);

  const sysDark = matchMedia("(prefers-color-scheme: dark)").matches;
  const dark    = S.theme === "dark" || (S.theme === "auto" && sysDark);
  document.querySelectorAll('meta[name="theme-color"]').forEach(m => m.remove());
  const m = document.createElement("meta");
  m.name = "theme-color"; m.content = dark ? "#0B120E" : "#F6FAF7";
  document.head.appendChild(m);

  document.querySelectorAll("#themePick button").forEach(b => {
    const aktivni = b.dataset.theme === S.theme;
    b.classList.toggle("on", aktivni);
    b.setAttribute("aria-selected", aktivni);
  });
}
matchMedia("(prefers-color-scheme: dark)").addEventListener("change", () => {
  if (S.theme === "auto") applyTheme();
});

/* ── Drobnosti ──────────────────────────────────────────────────── */
const haptic = (ms = 8) => navigator.vibrate?.(ms);
let toastT;
function toast(msg){
  const el = $("#toast");
  el.textContent = msg; el.hidden = false;
  requestAnimationFrame(() => el.classList.add("in"));
  clearTimeout(toastT);
  toastT = setTimeout(() => { el.classList.remove("in"); setTimeout(() => el.hidden = true, 400); }, 2200);
}
/* Výdejní okno bereme z jídelního lístku. Kde ho jídelna neuvádí
   (mateřská škola), neukazujeme žádný čas – radši nic než odhad. */
const vydej = (date, school) => D.days[date]?.vydej?.[school] || null;

function vydejBezi(date, school){
  if (date !== TODAY) return false;
  const v = vydej(date, school);
  if (!v) return false;
  const [od, do_] = v.split("–").map(t => {
    const [h, m] = t.split(":").map(Number);
    return h * 60 + m;
  });
  const t = new Date(), ted = t.getHours() * 60 + t.getMinutes();
  return ted >= od && ted < do_;
}

const meals = (date, school) => D.days[date]?.[school] || [];
const hasDay = (date, school = S.school) => (D.days[date]?.[school] || []).length > 0;
const hits  = m => m.a.filter(n => S.filter.has(n));
/* Položky chodu; u ručně psané MŠ je jen jedna – samotné jídlo. */
const casti     = m => m.p || [{ l: "Jídlo", n: m.n, a: m.a }];
const hlavni    = m => casti(m).find(c => c.l === "Jídlo") || casti(m)[0];
const zasahHlav = m => hlavni(m).a.some(n => S.filter.has(n));
const kdeZasah  = m => [...new Set(casti(m)
  .filter(c => c.a.some(n => S.filter.has(n)))
  .map(c => c.l.toLowerCase()))];

/* ── Přechod mezi dny ───────────────────────────────────────────
   Obsah odjede směrem swipu, nový přijede z druhé strany a karty
   naskáčou po sobě. Dlaždice vybraného dne mezitím plynule přejede.
──────────────────────────────────────────────────────────────── */
const bezAnimaci = () => matchMedia("(prefers-reduced-motion: reduce)").matches;
let prepinam = false;

/* Zelená dlaždice se nekreslí do buňky, ale posouvá se pod ně. */
/* Zamkne skrolování/swajpování stránky pod vyjetým sheetem (počítadlo
   pro případ, že by se překrývaly dva sheety najednou). Na iOS nestačí
   jen overflow:hidden – position:fixed je jediný spolehlivý způsob,
   jak zabránit swajpu pozadím i s odraženým bounce efektem. */
let zamcenoScrollu = 0, ulozenyScrollY = 0;
function zamkniScroll(){
  if (zamcenoScrollu++ > 0) return;
  ulozenyScrollY = window.scrollY;
  document.body.style.position = "fixed";
  document.body.style.top      = `-${ulozenyScrollY}px`;
  document.body.style.left     = "0";
  document.body.style.right    = "0";
}
function odemkniScroll(){
  if (zamcenoScrollu === 0 || --zamcenoScrollu > 0) return;
  document.body.style.position = "";
  document.body.style.top      = "";
  document.body.style.left     = "";
  document.body.style.right    = "";
  window.scrollTo(0, ulozenyScrollY);
}

function posunThumb(thumb, days, cil, skoc){
  if (!cil) { thumb.style.opacity = "0"; return; }
  const r = cil.getBoundingClientRect(), rp = days.getBoundingClientRect();
  const x = r.left - rp.left - days.clientLeft;
  const y = r.top  - rp.top  - days.clientTop;
  if (skoc || bezAnimaci()) thumb.style.transition = "none";
  thumb.style.opacity   = "1";
  thumb.style.width     = `${r.width}px`;
  thumb.style.height    = `${r.height}px`;
  thumb.style.transform = `translate(${x}px, ${y}px)`;
  if (skoc || bezAnimaci()) requestAnimationFrame(() => thumb.style.transition = "");
}

function naskakejKarty(smer){
  if (bezAnimaci()) return;
  $$("#timeline .meal").forEach((el, i) => el.animate(
    [{ opacity: 0, transform: `translate3d(${smer * 22}px,6px,0) scale(.985)` },
     { opacity: 1, transform: "none" }],
    { duration: 380, delay: i * 45, easing: "cubic-bezier(.32,.72,0,1)", fill: "backwards" }
  ));
}

/* smer: 1 = na další den (obsah odjede doleva), -1 = na předchozí.
   odKud = kde obsah zrovna je pod prstem, aby odchod plynule navázal. */
async function prepniDen(cil, smer, odKud = 0){
  if (prepinam || cil === S.date) return;
  smer = smer || (cil > S.date ? 1 : -1);

  if (bezAnimaci()) { S.date = cil; renderDen(); renderTyden(); return; }

  prepinam = true;
  const tl = $("#timeline");
  let odchod;
  try {
    odchod = tl.animate(
      [{ opacity: Math.max(.4, 1 - Math.abs(odKud) / 420), transform: `translate3d(${odKud}px,0,0)` },
       { opacity: 0, transform: `translate3d(${-smer * 60}px,0,0)` }],
      { duration: 160, easing: "cubic-bezier(.4,0,1,1)", fill: "forwards" }
    );
    /* Když je stránka na pozadí, prohlížeč animace nepřehrává a finished by
       nikdy nedoběhlo – proto čekáme nejvýš 260 ms a pak pokračujeme tak jako tak.
       Bez toho by se dal jídelníček zaseknout přepnutím aplikace uprostřed swipu. */
    await Promise.race([
      odchod.finished.catch(() => {}),
      new Promise(r => setTimeout(r, 260)),
    ]);
    S.date = cil;
    renderDen();
    renderTyden();
  } finally {
    odchod?.cancel();          // fill:forwards by jinak držel obsah neviditelný
    prepinam = false;
  }
  naskakejKarty(smer);
}

/* ── Karta jídla ────────────────────────────────────────────────── */
function mealNode(m, date){
  const c    = D.courses[m.c];
  const hs   = hits(m);
  const vJid = hs.length && zasahHlav(m);          // alergen přímo v jídle
  const mimo = hs.length && !vJid;                 // jen v příloze / nápoji
  const lead = (m.c === "obed" || m.c === "obed2") && !hs.length;

  let badge = "";
  if (vJid)                 badge = `<span class="badge warn">Alergen ${hs.join(", ")}</span>`;
  else if (mimo)            badge = `<span class="badge warn-soft">Alergen ${hs.join(", ")} · ${kdeZasah(m).join(", ")}</span>`;
  else if (m.c === "obed")  badge = `<span class="badge lead">Oběd</span>`;
  else if (m.c === "obed2") badge = `<span class="badge lead">Oběd II</span>`;

  const el = document.createElement("button");
  el.className = "meal" + (vJid ? " flagged" : mimo ? " flagged-soft" : lead ? " lead" : "");
  el.innerHTML = `
    <span class="meal-ico tone-${c.tone}">${ICON[m.c]}</span>
    <span class="meal-body">
      <span class="meal-kicker">${c.label}${badge}</span>
      <span class="meal-name">${m.n}</span>
      ${m.d ? `<span class="meal-desc">${m.d}</span>` : ""}
      ${m.a.length ? `<span class="a-chip${vJid ? " hit" : mimo ? " hit-soft" : ""}">${I_WHEAT}${m.a.join(", ")}${I_INFO}</span>` : ""}
    </span>`;
  el.addEventListener("click", () => openSheet(m, date));
  return el;
}

/* ── Pohled Den ─────────────────────────────────────────────────── */
function aktualizujHlavicky(){
  const p = popisekSkoly();
  ["heroSchool", "heroSchoolTyden", "heroSchoolAlergeny", "heroSchoolInfo"].forEach(id => {
    const el = $("#" + id); if (el) el.textContent = p;
  });
  const nazevAppky = `${p} na talíři`;
  if (document.title !== nazevAppky) document.title = nazevAppky;
  const appleTitle = $('meta[name="apple-mobile-web-app-title"]');
  if (appleTitle) appleTitle.setAttribute("content", nazevAppky);
  const popis = $('meta[name="description"]');
  if (popis) popis.setAttribute("content", `Jídelníček ${p} – celý den na jednom talíři.`);
}

/* Appka se aktualizuje automaticky každý všední den – pokud je poslední
   stažení výrazně starší (a zrovna je všední den, kdy by k aktualizaci
   mělo dojít), radši na to rodiče upozorníme, než aby se nevědomky
   rozhodoval podle starého jídelníčku. U ukázkových dat (--skutecna_data:
   false) tohle záměrně nekontrolujeme – ta se aktualizovat nemají. */
function zastaralaData(){
  if (!D.meta.real?.[S.school] || !D.meta.updated) return null;
  const dnesVsedniDen = ![0, 6].includes(new Date().getDay());
  if (!dnesVsedniDen) return null;
  const dny = Math.floor((Date.now() - new Date(D.meta.updated).getTime()) / 86_400_000);
  return dny >= 3 ? dny : null;
}

function renderDen(skoc){
  const mon = monday(S.date);
  aktualizujHlavicky();
  renderPrepinacOblibenych(skoc);
  $("#weekLabel").textContent  = `${short(mon)} – ${short(addD(mon,4))} ${parse(mon).getFullYear()}`;
  $(".segmented").hidden = !AKTIVNI.viceSkupin;
  $(".segmented").classList.toggle("ms", S.school === "ms");
  $$(".seg").forEach(b => b.setAttribute("aria-selected", b.dataset.school === S.school));

  const days  = $("#days");
  const track = $("#daysTrack");
  const jinyTyden = skoc || days.dataset.mon !== mon;
  days.dataset.mon = mon;

  /* Dlaždici nepřekreslujeme – musí zůstat v DOM, aby měla odkud přejet. */
  $$(".day", track).forEach(b => b.remove());
  let thumb = $(".day-thumb", track);
  if (!thumb){
    thumb = document.createElement("span");
    thumb.className = "day-thumb";
    track.appendChild(thumb);
  }

  let vybrany = null;
  for (let i = 0; i < 5; i++){
    const d = addD(mon,i);
    const vybran = d === S.date;
    const b = document.createElement("button");
    b.className = "day" + (vybran ? " sel" : "") + (d === TODAY ? " today" : "");
    b.setAttribute("aria-label", `${DOW[parse(d).getDay()]} ${short(d)}${d === TODAY ? " · dnes" : ""}`);
    b.setAttribute("aria-current", vybran ? "date" : "false");
    b.innerHTML = `<span class="dow" aria-hidden="true">${DOWS[parse(d).getDay()]}</span>
                   <span class="num" aria-hidden="true">${parse(d).getDate()}</span><span class="pip" aria-hidden="true"></span>`;
    b.addEventListener("click", () => { haptic(); prepniDen(d); });
    track.appendChild(b);
    if (d === S.date) vybrany = b;
  }
  posunThumb(thumb, track, vybrany, jinyTyden);

  $("#dayName").textContent = DOW[parse(S.date).getDay()];

  const cas = vydej(S.date, S.school), serve = $("#dayServe");
  serve.hidden = !cas;
  if (cas) serve.innerHTML = vydejBezi(S.date, S.school)
    ? `<span class="live"></span>Právě se vydává · ${cas}`
    : `Výdej ${cas}`;

  $("#demoNote").hidden = !!D.meta.real?.[S.school];

  const dnyStara = zastaralaData();
  $("#staleNote").hidden = dnyStara === null;
  if (dnyStara !== null) {
    const datum = new Date(D.meta.updated);
    $("#staleNoteTxt").textContent =
      `Naposledy staženo ${datum.getDate()}. ${datum.getMonth() + 1}. (před ${dnyStara} dny) – než se podle jídelníčku rozhodnete, ověřte to prosím na webu jídelny.`;
  }

  const tl = $("#timeline"); tl.innerHTML = "";
  const list = meals(S.date, S.school);
  if (!list.length){
    tl.innerHTML = `<div class="empty">
      <svg viewBox="0 0 24 24"><path d="M4 11h16a8 8 0 01-16 0z"/><path d="M9 7c0-1 1-1.4 1-2.4S9 3 9 3m6 4c0-1 1-1.4 1-2.4S15 3 15 3"/></svg>
      <div>Pro tento den zatím jídelníček nemáme.</div></div>`;
  } else list.forEach(m => tl.appendChild(mealNode(m, S.date)));
}

/* ── Pohled Týden ───────────────────────────────────────────────── */
function renderTyden(){
  const mon = monday(S.date);
  $("#weekEyebrow").textContent =
    `Týden ${short(mon)} – ${short(addD(mon,4))}${AKTIVNI.viceSkupin ? " · " + (S.school === "ms" ? "MŠ" : "ZŠ") : ""}`;
  const wrap = $("#weekList"); wrap.innerHTML = "";
  for (let i = 0; i < 5; i++){
    const d = addD(mon,i), list = meals(d, S.school);
    const main = list.find(m => m.c === "obed");
    const box = document.createElement("div");
    box.className = "wday" + (d === TODAY ? " today open" : "");
    box.innerHTML = `
      <button class="wday-head">
        <span class="wday-date">${parse(d).getDate()}</span>
        <span class="wday-txt"><h3>${DOW[parse(d).getDay()]}</h3>
          <p>${main ? main.n : "Bez jídelníčku"}</p></span>
        <svg class="chev" viewBox="0 0 24 24"><path d="M9 5l7 7-7 7"/></svg>
      </button>
      <div class="wday-body"><div><div class="meals"></div></div></div>`;
    const tl = $(".meals", box);
    list.forEach(m => tl.appendChild(mealNode(m, d)));
    $(".wday-head", box).addEventListener("click", () => { haptic(); box.classList.toggle("open"); });
    wrap.appendChild(box);
  }
}

/* ── Pohled Alergeny ────────────────────────────────────────────── */
function renderAlergeny(){
  const g = $("#allergenGrid"); g.innerHTML = "";
  Object.entries(D.allergens).forEach(([n,a]) => {
    const zapnuto = S.filter.has(+n);
    const b = document.createElement("button");
    b.className = "a-row" + (zapnuto ? " on" : "");
    b.setAttribute("role", "switch");
    b.setAttribute("aria-checked", zapnuto);
    b.innerHTML = `<span class="num">${n}</span>
      <span class="txt"><b>${a.name}</b><small>${a.detail}</small></span>
      <span class="switch"></span>`;
    b.addEventListener("click", () => {
      haptic(12);
      S.filter.has(+n) ? S.filter.delete(+n) : S.filter.add(+n);
      store.set("filter", [...S.filter]);
      renderAlergeny(); renderDen(); renderTyden();
      toast(S.filter.size
        ? `Hlídáme ${S.filter.size} alergen${S.filter.size > 4 ? "ů" : S.filter.size > 1 ? "y" : ""}`
        : "Filtr vypnut");
    });
    g.appendChild(b);
  });
}

function odkazNaJidelnu(){
  if (!AKTIVNI) return { url: "", popis: "" };
  if (AKTIVNI.web) return { url: AKTIVNI.web, popis: "Oficiální informace o jídelně." };
  return {
    url: `https://www.jidelna.cz/jidelni-listek/?jidelna=${AKTIVNI.id}`,
    popis: "Jídelníček přímo na webu jídelny.",
  };
}

/* Ratingy se ukládají jen jako číslo pod klíč den|skupina|chod (bez
   ID školy – viz openSheet). Jméno jídla k nim dohledáváme zpětně
   v aktuálně načteném jídelníčku; co se nedohledá (jiná škola, dávno
   smazaný týden), do žebříčku prostě nespadne. */
function zebricekJidel(){
  const soucty = {};
  for (const [key, hodnoceni] of Object.entries(S.rating)){
    const [date, school, kurz] = key.split("|");
    const jidlo = meals(date, school).find(m => m.c === kurz);
    if (!jidlo) continue;
    const z = soucty[jidlo.n] ??= { plus: 0, stred: 0, minus: 0 };
    if (hodnoceni === 1) z.plus++;
    else if (hodnoceni === -1) z.minus++;
    else z.stred++;
  }
  return Object.entries(soucty)
    .map(([nazev, z]) => ({ nazev, ...z }))
    .sort((a, b) => (b.plus - b.minus) - (a.plus - a.minus) || (b.plus+b.stred+b.minus) - (a.plus+a.stred+a.minus));
}

function renderZebricek(){
  const zebricek = zebricekJidel().slice(0, 6);
  $("#cardZebricek").hidden = !zebricek.length;
  $("#zebricekList").innerHTML = zebricek.map(z => `
    <div class="zebricek-radek">
      <span class="txt">${z.nazev}</span>
      <span class="skore">
        ${z.plus  ? `<b>👍${z.plus}</b>`  : ""}
        ${z.stred ? `<b>😐${z.stred}</b>` : ""}
        ${z.minus ? `<b>👎${z.minus}</b>` : ""}
      </span>
    </div>`).join("");
}

function renderInfo(){
  const u = new Date(D.meta.updated);
  $("#infoUpdated").textContent = `${u.getDate()}. ${u.getMonth()+1}. ${u.getFullYear()}`;
  const mon = monday(S.date);
  $("#infoWeek").textContent = `${short(mon)} – ${short(addD(mon,4))}`;
  $("#infoSource").textContent = D.meta.real?.[S.school] ? "Oficiální jídelníček" : "Ukázková data";
  $("#infoMode").textContent   = navigator.onLine ? "Online" : "Offline (z paměti)";
  const { url, popis } = odkazNaJidelnu();
  const a = $("#webJidelny");
  if (a) { a.href = url; }
  const p = $("#webJidelnyPopis");
  if (p) { p.textContent = popis; }
  renderZebricek();
}
const renderAll = () => { renderDen(); renderTyden(); renderAlergeny(); renderInfo(); };

/* ── Detail jídla ───────────────────────────────────────────────── */
function openSheet(m, date){
  haptic();
  const c   = D.courses[m.c];
  const key = `${date}|${S.school}|${m.c}`;
  const r   = S.rating[key];
  $("#sheetBody").innerHTML = `
    <div class="sheet-kicker">
      <span class="meal-ico tone-${c.tone}">${ICON[m.c]}</span>
      ${c.label} · ${DOW[parse(date).getDay()]} ${short(date)}${vydej(date, S.school) ? " · " + vydej(date, S.school) : ""}
    </div>
    <h2>${m.n}</h2>
    ${m.d ? `<p class="sub">${m.d}</p>` : ""}
    <div class="sheet-sec"><h4>Alergeny</h4>
      ${m.a.length ? m.a.map(n => `
        <div class="a-full${S.filter.has(n) ? " hit" : ""}">
          <span class="n">${n}</span>
          <span><b>${D.allergens[n].name}</b><small>${
            m.p ? m.p.filter(x => x.a.includes(n)).map(x => `${x.l}: ${x.n}`).join(" · ")
                : D.allergens[n].detail}</small></span>
        </div>`).join("") : `<p class="sub" style="margin:0">Bez uvedených alergenů.</p>`}
    </div>
    ${m.p && m.p.length > 1 ? `<div class="sheet-sec"><h4>Co je na talíři</h4>
      ${m.p.map(x => `<div class="a-full">
        <span class="l">${x.l}</span>
        <span><b>${x.n}</b>${x.a.length ? `<small>alergeny ${x.a.join(", ")}</small>` : ""}</span>
      </div>`).join("")}
    </div>` : ""}
    <div class="sheet-sec"><h4>Chutnalo dětem?</h4>
      <div class="rate">
        <button data-r="1"  aria-pressed="${r === 1}"  class="${r === 1  ? "on" : ""}">👍<span class="lbl">Super</span></button>
        <button data-r="0"  aria-pressed="${r === 0}"  class="${r === 0  ? "on" : ""}">😐<span class="lbl">Ujde</span></button>
        <button data-r="-1" aria-pressed="${r === -1}" class="${r === -1 ? "on" : ""}">👎<span class="lbl">Nic moc</span></button>
      </div>
    </div>`;
  $$("#sheetBody .rate button").forEach(b => b.addEventListener("click", () => {
    haptic(14);
    const v = +b.dataset.r;
    if (S.rating[key] === v) delete S.rating[key]; else S.rating[key] = v;
    store.set("rating", S.rating);
    $$("#sheetBody .rate button").forEach(x => {
      const aktivni = +x.dataset.r === S.rating[key];
      x.classList.toggle("on", aktivni);
      x.setAttribute("aria-pressed", aktivni);
    });
    if (S.rating[key] !== undefined) toast("Uloženo do vašeho telefonu");
  }));
  $("#scrim").hidden = false; $("#sheet").hidden = false;
  zamkniScroll();
  requestAnimationFrame(() => { $("#scrim").classList.add("in"); $("#sheet").classList.add("in"); });
}
function closeSheet(){
  $("#scrim").classList.remove("in"); $("#sheet").classList.remove("in");
  odemkniScroll();
  setTimeout(() => { $("#scrim").hidden = true; $("#sheet").hidden = true; }, 460);
}

/* ── Pohledy ────────────────────────────────────────────────────── */
function setView(v){
  S.view = v;
  $$(".view").forEach(s => s.hidden = s.id !== "view-" + v);
  $$(".tab").forEach(t => t.classList.toggle("is-active", t.dataset.view === v));
  syncFabIcon();
  window.scrollTo({ top: 0 });
  if (v === "den")   renderDen(true);
  if (v === "tyden") renderTyden();
  if (v === "info")  renderInfo();
}

/* ── Sdílení ────────────────────────────────────────────────────── */
function shareWeek(){
  const mon = monday(S.date);
  const jmenoSkoly = popisekSkoly();
  let txt = `🍽️ Jídelníček ${jmenoSkoly}\n${short(mon)}–${short(addD(mon,4))}\n`;
  for (let i = 0; i < 5; i++){
    const d = addD(mon,i), list = meals(d, S.school);
    if (!list.length) continue;
    txt += `\n${DOW[parse(d).getDay()]} ${short(d)}\n`
         + list.map(m => `• ${D.courses[m.c].label}: ${m.n}`).join("\n") + "\n";
  }
  if (navigator.share) navigator.share({ title:"ZŠ na talíři", text:txt }).catch(() => {});
  else { navigator.clipboard?.writeText(txt); toast("Zkopírováno do schránky"); }
}

function shareDen(){
  const jmenoSkoly = popisekSkoly();
  const list = meals(S.date, S.school);
  let txt = `🍽️ ${jmenoSkoly} · ${DOW[parse(S.date).getDay()]} ${short(S.date)}\n`;
  txt += list.length
    ? list.map(m => `• ${D.courses[m.c].label}: ${m.n}`).join("\n")
    : "Pro tento den zatím jídelníček nemáme.";
  if (navigator.share) navigator.share({ title:"ZŠ na talíři", text:txt }).catch(() => {});
  else { navigator.clipboard?.writeText(txt); toast("Zkopírováno do schránky"); }
}

/* ── Gesta ──────────────────────────────────────────────────────── */
function swipe(el, onLeft, onRight, vizual = el){
  let x0 = null, y0 = null, lock = null, posun = 0;

  el.addEventListener("touchstart", e => {
    if (prepinam) return;
    x0 = e.touches[0].clientX; y0 = e.touches[0].clientY; lock = null; posun = 0;
  }, { passive: true });

  el.addEventListener("touchmove", e => {
    if (x0 === null) return;
    const dx = e.touches[0].clientX - x0, dy = e.touches[0].clientY - y0;
    if (lock === null && (Math.abs(dx) > 10 || Math.abs(dy) > 10))
      lock = Math.abs(dx) > Math.abs(dy) ? "x" : "y";
    if (lock === "x"){
      posun = dx * .45;
      vizual.style.transform = `translate3d(${posun}px,0,0)`;
      vizual.style.opacity   = String(Math.max(.4, 1 - Math.abs(posun) / 420));
    }
  }, { passive: true });

  el.addEventListener("touchend", e => {
    if (x0 === null) return;
    const dx = e.changedTouches[0].clientX - x0;
    const potvrzeno = lock === "x" && Math.abs(dx) > 55;

    if (potvrzeno){
      haptic();
      vizual.style.transform = ""; vizual.style.opacity = "";     // převezme prepniDen
      (dx < 0 ? onLeft : onRight)(posun);
    } else if (lock === "x"){
      vizual.style.transition = "transform .45s var(--spring), opacity .3s ease";
      vizual.style.transform  = ""; vizual.style.opacity = "";
      setTimeout(() => vizual.style.transition = "", 460);
    }
    x0 = y0 = null; posun = 0;
  });
}

const step = (n, odKud = 0) => {
  let d = S.date;
  for (let i = 0; i < 10; i++){ d = addD(d,n); if (hasDay(d)) break; }
  if (hasDay(d)) prepniDen(d, n, odKud);
  else toast("Další jídelníček zatím není k dispozici");
};
const weekStep = n => {
  const cand = addD(monday(S.date), n*7);
  for (let i = 0; i < 5; i++) if (hasDay(addD(cand,i))){ prepniDen(addD(cand,i), n); return; }
  toast("Pro tento týden zatím jídelníček nemáme");
};

/* ── Výběr školy ──────────────────────────────────────────────────
   Appka nemá žádnou vestavěnou "domovskou" školu – i ZŠ Dubeč je jen
   běžná položka registru (id "47"), stahovaná stejně jako kterákoli
   jiná. Při úplně prvním spuštění (nic v localStorage) appka jen
   zkusí naběhnout na ni jako na rozumný výchozí tip, ať má hned co
   ukázat – funkčně se ale nijak neliší od výběru libovolné jiné
   školy. D.courses/D.allergens zůstávají společné pro všechny školy.
──────────────────────────────────────────────────────────────────── */
const VYCHOZI_LOKACE = "47";   // id ZŠ Dubeč na jidelna.cz – tip pro úplně první spuštění
const VYCHOZI_SKOLA  = {
  id: VYCHOZI_LOKACE, nazev: "Základní škola, Starodubečská 413, Praha 10 - Dubeč",
  kratky: "ZŠ Dubeč", zdroj: "jidelna.cz", skutecna_data: true,
};
const SKOLY_PROXY    = "https://zs-jidelny.zdkdsgn.workers.dev/";
let AKTIVNI = null;   // {id, nazev, skutecna_data, …} aktivně vybraná škola – null jen do dokončení startu
let registrSkol = null;

let registrChyba = false;
async function nactiRegistr(){
  if (registrSkol) return registrSkol;
  try {
    const r = await fetch("schools/index.json", { cache: "no-store" });
    if (!r.ok) throw new Error(String(r.status));
    registrSkol = await r.json();
    registrChyba = false;
  } catch {
    registrChyba = true;
    return [];   // neukládáme neúspěch – při příštím otevření (např. po obnově sítě) to zkusí znovu
  }
  return registrSkol;
}

async function stahniSkolu(id){
  const rd = await fetch(`schools/${id}/days.json`, { cache: "no-store" });
  if (!rd.ok) throw new Error(`days.json ${rd.status}`);
  const dny = await rd.json();

  let base = {};
  try {
    const rb = await fetch(`schools/${id}/base.json`, { cache: "no-store" });
    if (rb.ok) base = await rb.json();
  } catch { /* meta je jen na dozdobení, appka bez ní funguje */ }

  // Den může mít tři podoby (viz tools/jidelna_client.py):
  //  - holé pole chodů (starý ruční tvar, např. MŠ Dubeč)
  //  - {vydej, chody} – jednostopá škola, zabalíme pod "zs"
  //  - {skupiny: {zs:{…}, ms:{…}}} – vícestopá škola (spojená ZŠ+MŠ na
  //    jedné stránce), skupiny necháme tak, jak jsou, ať appka umí
  //    ukázat stejný přepínač jako u Dubče
  const zabaleneDny = {};
  const naleze = new Set();
  for (const [den, zaznam] of Object.entries(dny)) {
    if (zaznam && zaznam.skupiny) {
      const den_ = {};
      for (const [sk, z] of Object.entries(zaznam.skupiny)) {
        den_[sk] = z.chody;
        if (z.vydej) (den_.vydej ??= {})[sk] = z.vydej;
        naleze.add(sk);
      }
      zabaleneDny[den] = den_;
      continue;
    }
    const chody = Array.isArray(zaznam) ? zaznam : (zaznam.chody || []);
    zabaleneDny[den] = { zs: chody };
    const cas = Array.isArray(zaznam) ? null : zaznam.vydej;
    if (cas) zabaleneDny[den].vydej = { zs: cas };
    naleze.add("zs");
  }
  return { dny: zabaleneDny, base, skupiny: [...naleze].sort() };
}

async function prepniNaSkolu(polozka){
  try {
    const { dny, base, skupiny } = await stahniSkolu(polozka.id);
    D = {
      ...window.MENU_DATA,
      meta: { ...window.MENU_DATA.meta, ...base,
              real: Object.fromEntries(skupiny.map(s => [s, !!polozka.skutecna_data])) },
      days: dny,
    };
    AKTIVNI = { ...polozka, viceSkupin: skupiny.length > 1 };
    S.school = skupiny.includes("zs") ? "zs" : skupiny[0];
    S.date   = nearestSchoolDay(TODAY);
    store.set("lokace", polozka.id);
    store.set("lokaceData", polozka);
    return true;
  } catch {
    toast("Škola se nepodařilo načíst – zkuste to znovu");
    return false;
  }
}

/* Krátký, čitelný název aktivní školy – u vícestopé (ZŠ+MŠ) školy se
   před ni dá stejný prefix jako u Dubče, ať appka nemusí mít prefix
   napevno v každém "kratky" zvlášť. */
function popisekSkoly(){
  if (!AKTIVNI) return "";
  let zaklad = AKTIVNI.kratky || AKTIVNI.nazev;
  if (!AKTIVNI.viceSkupin) return zaklad;
  zaklad = zaklad.replace(/^(ZŠ|MŠ)\s+/, "");   // "kratky" psané pro jednoskupinovou
                                                  // podobu ať appka nezdvojí vlastním prefixem
  return `${S.school === "ms" ? "MŠ" : "ZŠ"} ${zaklad}`;
}

const HVEZDA = `<svg viewBox="0 0 24 24"><path d="M12 3.4l2.7 6 6.4.6-4.9 4.4 1.5 6.3L12 17.4l-5.7 3.3 1.5-6.3-4.9-4.4 6.4-.6z"/></svg>`;

function prepniOblibenou(polozka){
  haptic();
  if (S.oblibene.has(polozka.id)) S.oblibene.delete(polozka.id); else S.oblibene.add(polozka.id);
  store.set("oblibene", [...S.oblibene]);
  vykresliDostupneSkoly();
  renderPrepinacOblibenych();
}

/* Rychlý přepínač nahoře na Den – jen když jsou v oblíbených aspoň
   2 školy, co appka umí pojmenovat (z registru, nebo rovnou aktivní
   škola, kdyby registr ještě nebyl načtený). U jedné oblíbené nemá
   smysl cokoli přepínat, tak se nezobrazí vůbec. */
function renderPrepinacOblibenych(skoc){
  const wrap = $("#skolaPrepinac");
  if (!wrap) return;
  const zname = new Map((registrSkol || []).map(s => [s.id, s]));
  if (AKTIVNI) zname.set(AKTIVNI.id, AKTIVNI);
  const skoly = [...S.oblibene].map(id => zname.get(id)).filter(Boolean)
    .sort((a, b) => (a.kratky || a.nazev).localeCompare(b.kratky || b.nazev, "cs"));
  wrap.hidden = skoly.length < 2;
  if (skoly.length < 2) { wrap.innerHTML = ""; return; }

  /* Přepínač si podobně jako dlaždice dní nechává vlastní "thumb" v
     DOM napříč překreslením, ať má odkud plynule přejet na nově
     zvolenou školu, místo aby jen naskočila barva. */
  let thumb = $(".prepinac-thumb", wrap);
  $$("button", wrap).forEach(b => b.remove());
  if (!thumb){
    thumb = document.createElement("span");
    thumb.className = "prepinac-thumb";
    wrap.appendChild(thumb);
  }

  let vybrany = null;
  skoly.forEach(s => {
    const aktivni = !!AKTIVNI && AKTIVNI.id === s.id;
    const b = document.createElement("button");
    b.type = "button"; b.setAttribute("role", "tab"); b.dataset.id = s.id;
    b.className = aktivni ? "on" : "";
    b.setAttribute("aria-selected", aktivni);
    b.textContent = s.kratky || s.nazev;
    b.addEventListener("click", async () => {
      if (aktivni) return;
      haptic();
      const ok = await prepniNaSkolu(s);
      if (ok) { renderAll(); toast(`Přepnuto na ${AKTIVNI.nazev}`); }
    });
    wrap.appendChild(b);
    if (aktivni) vybrany = b;
  });
  posunThumb(thumb, wrap, vybrany, skoc);
}

function skolaKarta(polozka, aktivni){
  const row = document.createElement("div");
  row.className = "skola-radek" + (aktivni ? " aktivni" : "");
  const popisek = polozka.skutecna_data ? "" : "<small>ukázková data</small>";
  const oblibena = S.oblibene.has(polozka.id);
  row.innerHTML = `
    <button class="skola-radek-vyber" type="button">
      <span class="zn">${polozka.nazev.slice(0,1)}</span>
      <span class="txt"><b>${polozka.nazev}</b>${popisek}</span>
      ${aktivni ? `<span class="stitek">Aktivní</span>` : ""}
    </button>
    <button class="hvezda${oblibena ? " on" : ""}" type="button"
      aria-label="${oblibena ? "Odebrat z oblíbených" : "Přidat do oblíbených"}" aria-pressed="${oblibena}">${HVEZDA}</button>`;
  $(".skola-radek-vyber", row).addEventListener("click", async () => {
    if (aktivni) { $("#skolaSheet").classList.contains("in") && zavriSkolaSheet(); return; }
    haptic();
    const ok = await prepniNaSkolu(polozka);
    if (ok) {
      $("#skolaAktualni").textContent = AKTIVNI.nazev;
      renderAll();
      zavriSkolaSheet();
      toast(`Přepnuto na ${AKTIVNI.nazev}`);
    }
  });
  $(".hvezda", row).addEventListener("click", () => prepniOblibenou(polozka));
  return row;
}

/* Když škola sama neříká svoje město (Dubeč – vestavěná, appka jí
   žádný registr nedává), zkusíme ho vyčíst z názvu. Naprostá většina
   jidelna.cz jmen má tvar "Typ školy, Město[/Praha N], Ulice číslo" –
   hledáme první část za čárkou, co nevypadá jako ulice (žádné číslo). */
function odhadniMesto(polozka){
  if (polozka.mesto) return polozka.mesto;
  for (const cast of polozka.nazev.split(",").slice(1).map(c => c.trim())) {
    const bezOkresu = cast.replace(/^okres\s+/i, "");
    if (/^Praha\b/i.test(bezOkresu)) return "Praha";
    if (!/\d/.test(bezOkresu) && bezOkresu.length > 2 && bezOkresu.length <= 30 &&
        !/organizace|s\.r\.o\.|p\.o\./i.test(bezOkresu)) {
      return bezOkresu.replace(/\s*-\s*/g, "-");   // "Brno - venkov" a "Brno-venkov" ať jsou jedna skupina
    }
  }
  return "Ostatní";
}

/* Typ školy appka nikde neeviduje – odhaduje se z názvu, stejně jako
   město. Spojená ZŠ+MŠ v názvu (běžné u menších obcí) spadne do obou
   filtrů zároveň, ať se neschová ani pod jedním. */
function odhadniTyp(polozka){
  const n = polozka.nazev;
  const typy = new Set();
  if (/mateřsk[áé]\s+škol|^MŠ\b/i.test(n)) typy.add("ms");
  if (/základn[íi]\s+škol|^ZŠ\b/i.test(n)) typy.add("zs");
  if (/gymnázium|střední\s+(odborn|škol)|lyceum|konzervato[řr]|obchodní akademie|\bSOU\b|\bSOŠ\b/i.test(n)) typy.add("ss");
  return typy.size ? [...typy] : ["ostatni"];
}

let filtrTypu = "vse";

function vykresliDostupneSkoly(){
  const wrap = $("#skolaDostupne");
  const otevrenaPredtim = new Set($$(".skola-sekce.otevrena .skola-sekce-hlavicka > span:first-child", wrap)
    .map(el => el.textContent));
  wrap.innerHTML = "";

  if (registrChyba) {
    wrap.innerHTML = `<div class="skola-stav">
      Plný seznam škol se nepodařilo načíst – nejspíš nejste online.
      ${AKTIVNI ? `Dostupná zůstává jen ${AKTIVNI.nazev}.` : "Zkuste to znovu, až budete mít připojení."}
    </div>`;
  }

  const vsechny = registrSkol || (AKTIVNI ? [AKTIVNI] : []);
  const aktivniId = AKTIVNI?.id ?? null;
  const filtrovane = filtrTypu === "vse" ? vsechny : vsechny.filter(s => odhadniTyp(s).includes(filtrTypu));

  if (S.oblibene.size){
    const oblibene = filtrovane.filter(s => S.oblibene.has(s.id))
      .sort((a, b) => (a.kratky || a.nazev).localeCompare(b.kratky || b.nazev, "cs"));
    if (oblibene.length){
      const sekce = document.createElement("div");
      sekce.className = "skola-sekce skola-oblibene otevrena";
      sekce.innerHTML = `
        <div class="skola-sekce-hlavicka">
          <span>★ Oblíbené</span><span class="pocet">${oblibene.length}</span>
        </div>
        <div class="skola-sekce-telo"><div></div></div>`;
      const telo = $(".skola-sekce-telo > div", sekce);
      oblibene.forEach(s => telo.appendChild(skolaKarta(s, s.id === aktivniId)));
      wrap.appendChild(sekce);
    }
  }

  if (!filtrovane.length){
    wrap.insertAdjacentHTML("beforeend",
      `<div class="skola-stav">V tomto typu žádnou školu nemáme.</div>`);
  }

  const podleMesta = {};
  filtrovane.forEach(s => (podleMesta[odhadniMesto(s)] ??= []).push(s));

  Object.keys(podleMesta).sort((a, b) => a.localeCompare(b, "cs")).forEach(mesto => {
    const polozky = podleMesta[mesto].sort((a, b) =>
      (a.kratky || a.nazev).localeCompare(b.kratky || b.nazev, "cs"));
    const maAktivni = polozky.some(s => s.id === aktivniId);

    const sekce = document.createElement("div");
    sekce.className = "skola-sekce" + (maAktivni || otevrenaPredtim.has(mesto) ? " otevrena" : "");
    sekce.innerHTML = `
      <button class="skola-sekce-hlavicka">
        <span>${mesto}</span><span class="pocet">${polozky.length}</span>
        <svg class="chev" viewBox="0 0 24 24"><path d="M9 5l7 7-7 7"/></svg>
      </button>
      <div class="skola-sekce-telo"><div></div></div>`;
    const telo = $(".skola-sekce-telo > div", sekce);
    polozky.forEach(s => telo.appendChild(skolaKarta(s, s.id === aktivniId)));
    $(".skola-sekce-hlavicka", sekce).addEventListener("click", () => {
      haptic(); sekce.classList.toggle("otevrena");
    });
    wrap.appendChild(sekce);
  });
}

let hledaniTimer = null;
async function hledejSkolu(dotaz){
  const vysledky = $("#skolaVysledky");
  if (dotaz.trim().length < 4) { vysledky.innerHTML = ""; return; }
  vysledky.innerHTML = `<div class="skola-stav">Hledám…</div>`;
  try {
    const r = await fetch(SKOLY_PROXY + "?q=" + encodeURIComponent(dotaz));
    const data = await r.json();
    if (!data.ok || !data.vysledky.length) {
      vysledky.innerHTML = `<div class="skola-stav">${
        data.stav === "prilis_siroke" ? "Moc obecný dotaz – upřesněte název nebo ulici."
                                       : "Nic jsme nenašli."
      }</div>`;
      return;
    }
    const znameId = new Set((registrSkol || []).map(s => s.id));
    vysledky.innerHTML = "";
    data.vysledky.forEach(v => {
      const dostupna = znameId.has(v.id);
      const radek = document.createElement("div");
      radek.className = "skola-vysledek";
      radek.innerHTML = `
        <span class="txt"><b>${v.nazev}</b>${dostupna ? "" : "<small>zatím bez staženého jídelníčku</small>"}</span>
        ${dostupna ? `<button>Vybrat</button>` : ""}`;
      if (dostupna) {
        radek.querySelector("button").addEventListener("click", async () => {
          haptic();
          const polozka = registrSkol.find(s => s.id === v.id);
          const ok = await prepniNaSkolu(polozka);
          if (ok) {
            $("#skolaAktualni").textContent = AKTIVNI.nazev;
            renderAll();
            zavriSkolaSheet();
            toast(`Přepnuto na ${AKTIVNI.nazev}`);
          }
        });
      }
      vysledky.appendChild(radek);
    });
  } catch {
    vysledky.innerHTML = `<div class="skola-stav">Vyhledávání teď nejde – zkuste to později.</div>`;
  }
}

async function otevriSkolaSheet(){
  haptic();
  await nactiRegistr();
  filtrTypu = "vse";
  $$(".skola-typ-filtr button").forEach(b => {
    b.classList.toggle("on", b.dataset.typ === "vse");
    b.setAttribute("aria-selected", b.dataset.typ === "vse");
  });
  vykresliDostupneSkoly();
  $("#skolaQuery").value = "";
  $("#skolaVysledky").innerHTML = "";
  $("#skolaScrim").hidden = false; $("#skolaSheet").hidden = false;
  zamkniScroll();
  requestAnimationFrame(() => { $("#skolaScrim").classList.add("in"); $("#skolaSheet").classList.add("in"); });
}
function zavriSkolaSheet(){
  $("#skolaScrim").classList.remove("in"); $("#skolaSheet").classList.remove("in");
  odemkniScroll();
  setTimeout(() => { $("#skolaScrim").hidden = true; $("#skolaSheet").hidden = true; }, 460);
}

/* ── Události ───────────────────────────────────────────────────── */
$$(".seg").forEach(b => b.addEventListener("click", () => {
  haptic(); S.school = b.dataset.school; store.set("school", S.school); renderDen(); renderTyden();
}));
$$(".tab").forEach(t => t.addEventListener("click", () => { haptic(); setView(t.dataset.view); }));
$("#weekPrev").addEventListener("click", () => { haptic(); weekStep(-1); });
$("#weekNext").addEventListener("click", () => { haptic(); weekStep(1); });
$("#weekNow").addEventListener("click",  () => {
  haptic(); prepniDen(nearestSchoolDay(TODAY)); toast("Zpět na aktuální týden");
});
$("#toWeek").addEventListener("click",      () => { haptic(); setView("tyden"); });
$("#toAllergens").addEventListener("click", () => { haptic(); setView("alergeny"); });
$("#toSkola").addEventListener("click", otevriSkolaSheet);
$("#skolaScrim").addEventListener("click", zavriSkolaSheet);
$$(".skola-typ-filtr button").forEach(b => b.addEventListener("click", () => {
  if (b.dataset.typ === filtrTypu) return;
  haptic();
  filtrTypu = b.dataset.typ;
  $$(".skola-typ-filtr button").forEach(x => {
    x.classList.toggle("on", x === b);
    x.setAttribute("aria-selected", x === b);
  });
  vykresliDostupneSkoly();
}));
$("#skolaQuery").addEventListener("input", e => {
  clearTimeout(hledaniTimer);
  hledaniTimer = setTimeout(() => hledejSkolu(e.target.value), 400);
});
/* Pole je nahoře přilepené, ale výsledky se vykreslí pod ním – když
   do něj ťuknete uprostřed odscrollovaného seznamu měst, ať se rovnou
   vrátí nahoru, ať výsledky hned uvidíte. */
$("#skolaQuery").addEventListener("focus", () => {
  $("#skolaSheet").scrollTo({ top: 0, behavior: "smooth" });
});
$("#tabbarFab").addEventListener("click", () => {
  haptic();
  lastY = window.scrollY;   // ať hned po rozbalení scroll nezaklapne menu zpátky
  setTabsCollapsed(false);
});
$$("#themePick button").forEach(b => b.addEventListener("click", () => {
  haptic(); S.theme = b.dataset.theme; store.set("theme", S.theme); applyTheme();
  toast(S.theme === "auto" ? "Vzhled podle systému" : S.theme === "dark" ? "Tmavý režim" : "Světlý režim");
}));
$("#shareWeek").addEventListener("click", shareWeek);
$("#shareDen").addEventListener("click", () => { haptic(); shareDen(); });
$("#clearAllergens").addEventListener("click", () => {
  S.filter.clear(); store.set("filter", []); renderAll(); toast("Filtry zrušeny");
});
$("#scrim").addEventListener("click", closeSheet);
document.addEventListener("keydown", e => {
  if (e.key === "Escape") { closeSheet(); zavriSkolaSheet(); }
  if (S.view === "den" && e.key === "ArrowLeft")  step(-1);
  if (S.view === "den" && e.key === "ArrowRight") step(1);
});
swipe($("#timeline"), p => step(1, p), p => step(-1, p));
swipe($("#days"), () => weekStep(1), () => weekStep(-1), $("#daysTrack"));

(() => {  /* sheet stažením dolů */
  const sh = $("#sheet"); let y0 = null;
  sh.addEventListener("touchstart", e => { if (sh.scrollTop <= 0) y0 = e.touches[0].clientY; }, { passive:true });
  sh.addEventListener("touchmove",  e => {
    if (y0 === null) return;
    const dy = e.touches[0].clientY - y0; if (dy > 0) sh.style.transform = `translateY(${dy}px)`;
  }, { passive:true });
  sh.addEventListener("touchend", e => {
    if (y0 === null) return;
    const dy = e.changedTouches[0].clientY - y0;
    sh.style.transform = ""; if (dy > 110) closeSheet(); y0 = null;
  });
})();

function pripojStazeniSheetu(sh, zavri){
  let y0 = null;
  sh.addEventListener("touchstart", e => { if (sh.scrollTop <= 0) y0 = e.touches[0].clientY; }, { passive:true });
  sh.addEventListener("touchmove",  e => {
    if (y0 === null) return;
    const dy = e.touches[0].clientY - y0; if (dy > 0) sh.style.transform = `translateY(${dy}px)`;
  }, { passive:true });
  sh.addEventListener("touchend", e => {
    if (y0 === null) return;
    const dy = e.changedTouches[0].clientY - y0;
    sh.style.transform = ""; if (dy > 110) zavri(); y0 = null;
  });
}
pripojStazeniSheetu($("#skolaSheet"), zavriSkolaSheet);

/* ── Detekce nové verze po návratu do aplikace ──────────────────
   iOS appku na ploše často jen probudí z paměti a stránku znovu nenačte,
   takže by appka klidně několik dní ukazovala starý kód i stará data.
   Porovnáváme drobný version.json (otisk index.html/styles.css/app.js/
   sw.js) s tím, co appka viděla naposledy – hlídá tedy i úpravy appky
   samotné, ne jen aktualizace jídelníčku. cache:"no-store" zajišťuje,
   že se ptáme opravdu sítě, ne desetiminutové HTTP cache GitHub Pages. */
const KONTROLA_PO = 5 * 60 * 1000;
let posledniKontrola = Date.now();

/* kontrolovat=false: appka právě naběhla skutečným načtením stránky,
   takže verze je jistě aktuální – jen si ji zapamatujeme jako výchozí.
   kontrolovat=true: appka se jen probrala z paměti (návrat do appky),
   žádné skutečné načtení neproběhlo – tady rozdíl znamená zastaralý kód
   i data a je namístě appku restartovat. */
async function overVerzi(kontrolovat){
  if (!navigator.onLine) return;
  try {
    const r = await fetch("version.json", { cache: "no-store" });
    if (!r.ok) return;                                  // např. jednosouborová verze
    const { v } = await r.json();
    if (!v) return;

    const videna = store.get("appVersion", null);
    store.set("appVersion", v);
    if (kontrolovat && videna !== null && videna !== v){
      toast("Máme novou verzi");
      setTimeout(() => location.reload(), 900);
    }
  } catch {
    /* offline nebo výpadek sítě – necháme na obrazovce, co máme */
  }
}

document.addEventListener("visibilitychange", () => {
  if (document.visibilityState !== "visible") return;
  if (!$("#sheet").hidden) return;                      // nebudeme rušit otevřený detail
  if (Date.now() - posledniKontrola < KONTROLA_PO) return;
  posledniKontrola = Date.now();
  overVerzi(true);
});

/* Spodní menu se při scrollu dolů smrskne do jedné ikony (aktuální
   záložky) a při scrollu nahoru – nebo klepnutím na tu ikonu – se zase
   rozbalí. U kraje stránky je vždy rozbalené. */
let lastY = 0, tabsCollapsed = false;
function setTabsCollapsed(on){
  if (on === tabsCollapsed) return;
  tabsCollapsed = on;
  $("#tabbar").classList.toggle("collapsed", on);
  $("#tabbar").setAttribute("aria-hidden", String(on));
  $("#tabbarFab").classList.toggle("show", on);
  $("#tabbarFab").setAttribute("aria-expanded", String(!on));
}
function syncFabIcon(){
  const active = $(".tab.is-active svg");
  if (active) $("#tabbarFab").innerHTML = active.outerHTML;
}
function onScroll(){
  const y = Math.max(0, window.scrollY), dy = y - lastY;
  if (y < 64)                            setTabsCollapsed(false);
  else if (dy >  4 && !tabsCollapsed)    setTabsCollapsed(true);
  else if (dy < -6 &&  tabsCollapsed)    setTabsCollapsed(false);
  lastY = y;
}
window.addEventListener("scroll", onScroll, { passive:true });
window.addEventListener("online",  renderInfo);
window.addEventListener("offline", () => { renderInfo(); toast("Jste offline – zobrazujeme uloženou verzi"); });

let deferred = null;
window.addEventListener("beforeinstallprompt", e => { e.preventDefault(); deferred = e; $("#installBtn").hidden = false; });
$("#installBtn").addEventListener("click", async () => {
  if (!deferred) return;
  deferred.prompt(); await deferred.userChoice; deferred = null; $("#installBtn").hidden = true;
});
if ("serviceWorker" in navigator && location.protocol.startsWith("http"))
  window.addEventListener("load", () => navigator.serviceWorker.register("sw.js").catch(() => {}));

(async () => {
  applyTheme();

  // Úplně první spuštění appky (v localStorage ještě není žádná volba
  // školy) – appka si zatím tiše "vybere" ZŠ Dubeč jako rozumný výchozí
  // tip, ať má hned co ukázat, ale rovnou po vykreslení otevře výběr,
  // ať si rodič najde tu svou. Kdo si školu už někdy vybral (třeba i
  // ZŠ Dubeč), se tímhle znovu neobtěžuje. Funkčně se to od výběru
  // jakékoli jiné školy nijak neliší – žádná "vestavěná" výjimka.
  const jePrvniSpusteni = localStorage.getItem("dubec:lokace") === null;
  const ulozenaData = store.get("lokaceData", null);
  const ok = await prepniNaSkolu(ulozenaData || VYCHOZI_SKOLA);
  if (!ok) {
    // Offline při úplně prvním spuštění (nic stažené k dispozici) –
    // ukážeme aspoň vestavěná ukázková data, ať appka nezůstane prázdná.
    D = window.MENU_DATA;
    AKTIVNI = { id: VYCHOZI_LOKACE, nazev: D.meta.school, kratky: D.meta.school, viceSkupin: true };
    S.school = store.get("school", "zs") || "zs";
    S.date   = nearestSchoolDay(TODAY);
  }
  $("#skolaAktualni").textContent = AKTIVNI.nazev;

  renderAll(); setView("den"); onScroll();
  overVerzi(false);   // appka právě naběhla čerstvě – jen zapamatovat výchozí verzi
  setInterval(renderDen, 60_000);

  // Registr se jinak načítá až při otevření "Vaše škola" – ať ale jde
  // rovnou vidět přepínač oblíbených škol na Den, natáhneme ho potichu
  // na pozadí i tady, bez čekání na vykreslení prvního obsahu.
  if (S.oblibene.size >= 2) nactiRegistr().then(renderPrepinacOblibenych);

  if (jePrvniSpusteni) setTimeout(otevriSkolaSheet, 700);
})();
})();
