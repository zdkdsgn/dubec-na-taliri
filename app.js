/* ══════════════════════════════════════════════════════════════════
   Dubeč na talíři — aplikační logika
══════════════════════════════════════════════════════════════════ */
(() => {
"use strict";

const D  = window.MENU_DATA;
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
function nowCourse(date){
  if (date !== TODAY) return null;
  const t = new Date(), m = t.getHours()*60 + t.getMinutes();
  const win = { presnidavka:[7*60,10*60], polevka:[10*60,11*60+45],
                obed:[11*60+45,13*60+30], svacina:[13*60+30,15*60+30] };
  return Object.keys(win).find(c => m >= win[c][0] && m < win[c][1]) || null;
}
const meals = (date, school) => D.days[date]?.[school] || [];
const hasDay = (date, school = S.school) => (D.days[date]?.[school] || []).length > 0;
const hits  = m => m.a.filter(n => S.filter.has(n));

/* ── Karta jídla ────────────────────────────────────────────────── */
function mealNode(m, date, live){
  const c    = D.courses[m.c];
  const hs   = hits(m);
  const lead = (m.c === "obed" || m.c === "obed2") && !hs.length;

  let badge = "";
  if (hs.length)            badge = `<span class="badge warn">Alergen ${hs.join(", ")}</span>`;
  else if (live === m.c)    badge = `<span class="badge now">Právě teď</span>`;
  else if (m.c === "obed")  badge = `<span class="badge lead">Oběd</span>`;
  else if (m.c === "obed2") badge = `<span class="badge lead">Oběd II</span>`;

  const el = document.createElement("button");
  el.className = "meal" + (hs.length ? " flagged" : lead ? " lead" : "");
  el.innerHTML = `
    <span class="meal-ico tone-${c.tone}">${ICON[m.c]}</span>
    <span class="meal-body">
      <span class="meal-kicker">${c.label}${badge}</span>
      <span class="meal-name">${m.n}</span>
      ${m.d ? `<span class="meal-desc">${m.d}</span>` : ""}
      ${m.a.length ? `<span class="a-chip${hs.length ? " hit" : ""}">${I_WHEAT}${m.a.join(", ")}${I_INFO}</span>` : ""}
    </span>`;
  el.addEventListener("click", () => openSheet(m, date));
  return el;
}

/* ── Pohled Den ─────────────────────────────────────────────────── */
function renderDen(){
  const mon = monday(S.date);
  $("#heroSchool").textContent = S.school === "ms" ? "MŠ Dubeč" : "ZŠ Dubeč";
  $("#weekLabel").textContent  = `${short(mon)} – ${short(addD(mon,4))} ${parse(mon).getFullYear()}`;
  $(".segmented").classList.toggle("ms", S.school === "ms");
  $$(".seg").forEach(b => b.setAttribute("aria-selected", b.dataset.school === S.school));

  const days = $("#days"); days.innerHTML = "";
  for (let i = 0; i < 5; i++){
    const d = addD(mon,i);
    const b = document.createElement("button");
    b.className = "day" + (d === S.date ? " sel" : "") + (d === TODAY ? " today" : "");
    b.innerHTML = `<span class="dow">${DOWS[parse(d).getDay()]}</span>
                   <span class="num">${parse(d).getDate()}</span><span class="pip"></span>`;
    b.addEventListener("click", () => { haptic(); S.date = d; renderDen(); });
    days.appendChild(b);
  }

  $("#dayName").innerHTML = `${DOW[parse(S.date).getDay()]} <span class="date">${long(S.date)}</span>`;

  $("#demoNote").hidden = !!D.meta.real?.[S.school];

  const tl = $("#timeline"); tl.innerHTML = "";
  const list = meals(S.date, S.school), live = nowCourse(S.date);
  if (!list.length){
    tl.innerHTML = `<div class="empty">
      <svg viewBox="0 0 24 24"><path d="M4 11h16a8 8 0 01-16 0z"/><path d="M9 7c0-1 1-1.4 1-2.4S9 3 9 3m6 4c0-1 1-1.4 1-2.4S15 3 15 3"/></svg>
      <div>Pro tento den zatím jídelníček nemáme.</div></div>`;
  } else list.forEach(m => tl.appendChild(mealNode(m, S.date, live)));
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
    list.forEach(m => tl.appendChild(mealNode(m, d, nowCourse(d))));
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
      ${c.label} · ${DOW[parse(date).getDay()]} ${short(date)} · ${c.time}
    </div>
    <h2>${m.n}</h2>
    ${m.d ? `<p class="sub">${m.d}</p>` : ""}
    <div class="sheet-sec"><h4>Alergeny</h4>
      ${m.a.length ? m.a.map(n => `
        <div class="a-full${S.filter.has(n) ? " hit" : ""}">
          <span class="n">${n}</span>
          <span><b>${D.allergens[n].name}</b><small>${D.allergens[n].detail}</small></span>
        </div>`).join("") : `<p class="sub" style="margin:0">Bez uvedených alergenů.</p>`}
    </div>
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
  window.scrollTo({ top: 0 });
  if (v === "tyden") renderTyden();
  if (v === "info")  renderInfo();
}

/* ── Sdílení ────────────────────────────────────────────────────── */
function shareWeek(){
  const mon = monday(S.date);
  let txt = `🍽️ Jídelníček ${S.school === "ms" ? "MŠ" : "ZŠ"} Dubeč\n${short(mon)}–${short(addD(mon,4))}\n`;
  for (let i = 0; i < 5; i++){
    const d = addD(mon,i), list = meals(d, S.school);
    if (!list.length) continue;
    txt += `\n${DOW[parse(d).getDay()]} ${short(d)}\n`
         + list.map(m => `• ${D.courses[m.c].label}: ${m.n}`).join("\n") + "\n";
  }
  if (navigator.share) navigator.share({ title:"Dubeč na talíři", text:txt }).catch(() => {});
  else { navigator.clipboard?.writeText(txt); toast("Zkopírováno do schránky"); }
}

/* ── Gesta ──────────────────────────────────────────────────────── */
function swipe(el, onLeft, onRight){
  let x0 = null, y0 = null, lock = null;
  el.addEventListener("touchstart", e => { x0 = e.touches[0].clientX; y0 = e.touches[0].clientY; lock = null; }, { passive:true });
  el.addEventListener("touchmove", e => {
    if (x0 === null) return;
    const dx = e.touches[0].clientX - x0, dy = e.touches[0].clientY - y0;
    if (lock === null && (Math.abs(dx) > 10 || Math.abs(dy) > 10)) lock = Math.abs(dx) > Math.abs(dy) ? "x" : "y";
    if (lock === "x") el.style.transform = `translateX(${dx * .26}px)`;
  }, { passive:true });
  el.addEventListener("touchend", e => {
    if (x0 === null) return;
    const dx = e.changedTouches[0].clientX - x0;
    el.style.transition = "transform .45s var(--spring)"; el.style.transform = "";
    setTimeout(() => el.style.transition = "", 460);
    if (lock === "x" && Math.abs(dx) > 55){ haptic(); dx < 0 ? onLeft() : onRight(); }
    x0 = y0 = null;
  });
}
const step = n => {
  let d = S.date;
  for (let i = 0; i < 10; i++){ d = addD(d,n); if (hasDay(d)) break; }
  if (hasDay(d)){ S.date = d; renderDen(); } else toast("Další jídelníček zatím není k dispozici");
};
const weekStep = n => {
  const cand = addD(monday(S.date), n*7);
  for (let i = 0; i < 5; i++) if (hasDay(addD(cand,i))){ S.date = addD(cand,i); renderDen(); renderTyden(); return; }
  toast("Pro tento týden zatím jídelníček nemáme");
};

/* ── Události ───────────────────────────────────────────────────── */
$$(".seg").forEach(b => b.addEventListener("click", () => {
  haptic(); S.school = b.dataset.school; store.set("school", S.school); renderDen(); renderTyden();
}));
$$(".tab").forEach(t => t.addEventListener("click", () => { haptic(); setView(t.dataset.view); }));
$("#weekPrev").addEventListener("click", () => { haptic(); weekStep(-1); });
$("#weekNext").addEventListener("click", () => { haptic(); weekStep(1); });
$("#weekNow").addEventListener("click",  () => {
  haptic(); S.date = nearestSchoolDay(TODAY); renderDen(); renderTyden(); toast("Zpět na aktuální týden");
});
$("#toWeek").addEventListener("click",      () => { haptic(); setView("tyden"); });
$("#brandInfo").addEventListener("click",   () => { haptic(); setView("info"); });
$("#toAllergens").addEventListener("click", () => { haptic(); setView("alergeny"); });
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
  if (e.key === "Escape") closeSheet();
  if (S.view === "den" && e.key === "ArrowLeft")  step(-1);
  if (S.view === "den" && e.key === "ArrowRight") step(1);
});
swipe($("#timeline"), () => step(1), () => step(-1));

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

/* Horní lišta se schová při scrollu dolů a vrátí se při scrollu nahoru. */
let lastY = 0, barHidden = false;
function onScroll(){
  const y = Math.max(0, window.scrollY), bar = $("#brand"), dy = y - lastY;
  bar.classList.toggle("stuck", y > 8);
  if (y < 64)                        { bar.classList.remove("hide"); barHidden = false; }
  else if (dy >  4 && !barHidden)    { bar.classList.add("hide");    barHidden = true;  }
  else if (dy < -6 &&  barHidden)    { bar.classList.remove("hide"); barHidden = false; }
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

applyTheme(); renderAll(); setView("den"); onScroll();
setInterval(renderDen, 60_000);
})();
