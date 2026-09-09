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
const MON  = ["ledna","února","března","dubna","května","června","července",
              "srpna","září","října","listopadu","prosince"];

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
const long  = s => { const d = parse(s); return `${d.getDate()}. ${MON[d.getMonth()]}`; };
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
  theme : store.get("theme","auto")     /* auto | light | dark */
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

  document.querySelectorAll("#themePick button")
    .forEach(b => b.classList.toggle("on", b.dataset.theme === S.theme));
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
function renderDen(){
  const mon = monday(S.date);
  $("#heroSchool").textContent = AKTIVNI ? AKTIVNI.nazev : (S.school === "ms" ? "MŠ Dubeč" : "ZŠ Dubeč");
  $("#weekLabel").textContent  = `${short(mon)} – ${short(addD(mon,4))} ${parse(mon).getFullYear()}`;
  $(".segmented").hidden = !!AKTIVNI;
  $(".segmented").classList.toggle("ms", S.school === "ms");
  $$(".seg").forEach(b => b.setAttribute("aria-selected", b.dataset.school === S.school));

  const days = $("#days");
  const jinyTyden = days.dataset.mon !== mon;
  days.dataset.mon = mon;

  /* Dlaždici nepřekreslujeme – musí zůstat v DOM, aby měla odkud přejet. */
  $$(".day", days).forEach(b => b.remove());
  let thumb = $(".day-thumb", days);
  if (!thumb){
    thumb = document.createElement("span");
    thumb.className = "day-thumb";
    days.appendChild(thumb);
  }

  let vybrany = null;
  for (let i = 0; i < 5; i++){
    const d = addD(mon,i);
    const b = document.createElement("button");
    b.className = "day" + (d === S.date ? " sel" : "") + (d === TODAY ? " today" : "");
    b.innerHTML = `<span class="dow">${DOWS[parse(d).getDay()]}</span>
                   <span class="num">${parse(d).getDate()}</span><span class="pip"></span>`;
    b.addEventListener("click", () => { haptic(); prepniDen(d); });
    days.appendChild(b);
    if (d === S.date) vybrany = b;
  }
  posunThumb(thumb, days, vybrany, jinyTyden);

  $("#dayName").innerHTML = `${DOW[parse(S.date).getDay()]} <span class="date">${long(S.date)}</span>`;

  const cas = vydej(S.date, S.school), serve = $("#dayServe");
  serve.hidden = !cas;
  if (cas) serve.innerHTML = vydejBezi(S.date, S.school)
    ? `<span class="live"></span>Právě se vydává · ${cas}`
    : `Výdej ${cas}`;

  $("#demoNote").hidden = !!D.meta.real?.[S.school];

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
    `${short(mon)} – ${short(addD(mon,4))} · ${S.school === "ms" ? "MŠ" : "ZŠ"}`;
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
    const b = document.createElement("button");
    b.className = "a-row" + (S.filter.has(+n) ? " on" : "");
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

function renderInfo(){
  const u = new Date(D.meta.updated);
  $("#infoUpdated").textContent = `${u.getDate()}. ${u.getMonth()+1}. ${u.getFullYear()}`;
  const mon = monday(S.date);
  $("#infoWeek").textContent = `${short(mon)} – ${short(addD(mon,4))}`;
  $("#infoSource").textContent = D.meta.real?.[S.school] ? "Oficiální jídelníček" : "Ukázková data";
  $("#infoMode").textContent   = navigator.onLine ? "Online" : "Offline (z paměti)";
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
        <button data-r="1"  class="${r === 1  ? "on" : ""}">👍<span class="lbl">Super</span></button>
        <button data-r="0"  class="${r === 0  ? "on" : ""}">😐<span class="lbl">Ujde</span></button>
        <button data-r="-1" class="${r === -1 ? "on" : ""}">👎<span class="lbl">Nic moc</span></button>
      </div>
    </div>`;
  $$("#sheetBody .rate button").forEach(b => b.addEventListener("click", () => {
    haptic(14);
    const v = +b.dataset.r;
    if (S.rating[key] === v) delete S.rating[key]; else S.rating[key] = v;
    store.set("rating", S.rating);
    $$("#sheetBody .rate button").forEach(x => x.classList.toggle("on", +x.dataset.r === S.rating[key]));
    if (S.rating[key] !== undefined) toast("Uloženo do vašeho telefonu");
  }));
  $("#scrim").hidden = false; $("#sheet").hidden = false;
  requestAnimationFrame(() => { $("#scrim").classList.add("in"); $("#sheet").classList.add("in"); });
}
function closeSheet(){
  $("#scrim").classList.remove("in"); $("#sheet").classList.remove("in");
  setTimeout(() => { $("#scrim").hidden = true; $("#sheet").hidden = true; }, 420);
}

/* ── Pohledy ────────────────────────────────────────────────────── */
function setView(v){
  S.view = v;
  $$(".view").forEach(s => s.hidden = s.id !== "view-" + v);
  $$(".tab").forEach(t => t.classList.toggle("is-active", t.dataset.view === v));
  syncFabIcon();
  window.scrollTo({ top: 0 });
  if (v === "tyden") renderTyden();
  if (v === "info")  renderInfo();
}

/* ── Sdílení ────────────────────────────────────────────────────── */
function shareWeek(){
  const mon = monday(S.date);
  const jmenoSkoly = AKTIVNI ? AKTIVNI.nazev : `${S.school === "ms" ? "MŠ" : "ZŠ"} Dubeč`;
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

/* ── Gesta ──────────────────────────────────────────────────────── */
function swipe(el, onLeft, onRight){
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
      el.style.transform = `translate3d(${posun}px,0,0)`;
      el.style.opacity   = String(Math.max(.4, 1 - Math.abs(posun) / 420));
    }
  }, { passive: true });

  el.addEventListener("touchend", e => {
    if (x0 === null) return;
    const dx = e.changedTouches[0].clientX - x0;
    const potvrzeno = lock === "x" && Math.abs(dx) > 55;

    if (potvrzeno){
      haptic();
      el.style.transform = ""; el.style.opacity = "";     // převezme prepniDen
      (dx < 0 ? onLeft : onRight)(posun);
    } else if (lock === "x"){
      el.style.transition = "transform .45s var(--spring), opacity .3s ease";
      el.style.transform  = ""; el.style.opacity = "";
      setTimeout(() => el.style.transition = "", 460);
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
   Výchozí appka (localStorage bez uloženého "lokace", nebo VYCHOZI_LOKACE)
   se chová přesně jako dřív – bere data z vestavěného data.js, žádný
   síťový dotaz navíc. Teprve když si rodič vybere jinou školu, appka
   za běhu stáhne schools/<id>/{base,days}.json a nahradí jimi D.days –
   allergeny i typy chodů (D.courses/D.allergens) zůstávají společné,
   ty se nemění škola od školy.
──────────────────────────────────────────────────────────────────── */
const VYCHOZI_LOKACE = "dubec";
const SKOLY_PROXY    = "https://zs-jidelny.zdkdsgn.workers.dev/";
let AKTIVNI = null;   // {id, nazev, skutecna_data} když je zvolena jiná škola než výchozí
let registrSkol = null;

async function nactiRegistr(){
  if (registrSkol) return registrSkol;
  try {
    const r = await fetch("schools/index.json", { cache: "no-store" });
    registrSkol = r.ok ? await r.json() : [];
  } catch { registrSkol = []; }
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

  // Jednokuchyňová škola nemá ms/zs split – zabalíme ji pod "zs",
  // ať appka pro ni beze změny použije existující vykreslování.
  const zabaleneDny = {};
  for (const [den, zaznam] of Object.entries(dny)) {
    const chody = Array.isArray(zaznam) ? zaznam : (zaznam.chody || []);
    zabaleneDny[den] = { zs: chody };
    const cas = Array.isArray(zaznam) ? null : zaznam.vydej;
    if (cas) zabaleneDny[den].vydej = { zs: cas };
  }
  return { dny: zabaleneDny, base };
}

async function prepniNaSkolu(polozka){
  try {
    const { dny, base } = await stahniSkolu(polozka.id);
    D = {
      ...window.MENU_DATA,
      meta: { ...window.MENU_DATA.meta, ...base, real: { zs: !!polozka.skutecna_data } },
      days: dny,
    };
    AKTIVNI = polozka;
    S.school = "zs";
    S.date   = nearestSchoolDay(TODAY);
    store.set("lokace", polozka.id);
    store.set("lokaceData", polozka);
    return true;
  } catch {
    toast("Škola se nepodařilo načíst – zkuste to znovu");
    return false;
  }
}

function zpetNaVychozi(){
  D = window.MENU_DATA;
  AKTIVNI = null;
  S.school = store.get("school", "zs") || "zs";
  S.date   = nearestSchoolDay(TODAY);
  store.set("lokace", VYCHOZI_LOKACE);
}

function skolaKarta(polozka, aktivni){
  const b = document.createElement("button");
  b.className = "skola-radek" + (aktivni ? " aktivni" : "");
  const popisek = polozka.id === VYCHOZI_LOKACE ? ""
    : polozka.skutecna_data ? "" : "<small>ukázková data</small>";
  b.innerHTML = `
    <span class="zn">${polozka.nazev.slice(0,1)}</span>
    <span class="txt"><b>${polozka.nazev}</b>${popisek}</span>
    ${aktivni ? `<span class="stitek">Aktivní</span>` : ""}`;
  b.addEventListener("click", async () => {
    if (aktivni) { $("#skolaSheet").classList.contains("in") && zavriSkolaSheet(); return; }
    haptic();
    const ok = polozka.id === VYCHOZI_LOKACE ? (zpetNaVychozi(), true) : await prepniNaSkolu(polozka);
    if (ok) {
      $("#skolaAktualni").textContent = AKTIVNI ? AKTIVNI.nazev : "Dubeč";
      renderAll();
      zavriSkolaSheet();
      toast(`Přepnuto na ${AKTIVNI ? AKTIVNI.nazev : "Dubeč"}`);
    }
  });
  return b;
}

function vykresliDostupneSkoly(){
  const wrap = $("#skolaDostupne"); wrap.innerHTML = "";
  wrap.appendChild(skolaKarta({ id: VYCHOZI_LOKACE, nazev: "Dubeč (výchozí)" }, !AKTIVNI));
  (registrSkol || []).forEach(s => wrap.appendChild(skolaKarta(s, !!(AKTIVNI && AKTIVNI.id === s.id))));
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
  vykresliDostupneSkoly();
  $("#skolaQuery").value = "";
  $("#skolaVysledky").innerHTML = "";
  $("#skolaScrim").hidden = false; $("#skolaSheet").hidden = false;
  requestAnimationFrame(() => { $("#skolaScrim").classList.add("in"); $("#skolaSheet").classList.add("in"); });
}
function zavriSkolaSheet(){
  $("#skolaScrim").classList.remove("in"); $("#skolaSheet").classList.remove("in");
  setTimeout(() => { $("#skolaScrim").hidden = true; $("#skolaSheet").hidden = true; }, 420);
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
$("#skolaQuery").addEventListener("input", e => {
  clearTimeout(hledaniTimer);
  hledaniTimer = setTimeout(() => hledejSkolu(e.target.value), 400);
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

  // Uložená volba jiné školy než výchozí Dubeč – načíst ji ještě před
  // prvním vykreslením, ať appka rovnou naskočí na správná data (žádné
  // blikání "nejdřív Dubeč, pak přeskok na tu vybranou").
  const ulozenaLokace = store.get("lokace", VYCHOZI_LOKACE);
  if (ulozenaLokace !== VYCHOZI_LOKACE) {
    const ulozenaData = store.get("lokaceData", null);
    if (ulozenaData) await prepniNaSkolu(ulozenaData);
  }
  $("#skolaAktualni").textContent = AKTIVNI ? AKTIVNI.nazev : "Dubeč";

  renderAll(); setView("den"); onScroll();
  overVerzi(false);   // appka právě naběhla čerstvě – jen zapamatovat výchozí verzi
  setInterval(renderDen, 60_000);
})();
})();
