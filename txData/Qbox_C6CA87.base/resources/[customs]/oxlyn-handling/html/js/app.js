/* ══════════════════════════════════════════════════════════════════════
   OXLYN-HANDLING • app.js (v2)
   Studio state machine. Performance notes:
   - Cards are built into a DocumentFragment (single reflow per render).
   - Live slider changes batch into ONE NUI message per animation frame.
   - Search re-renders are debounced and skip entrance animations.
   - The scroller gets rAF-lerp smooth scrolling (CEF wheel steps feel
     heavy otherwise) + content-visibility in CSS skips offscreen cards.
   All values handled here are DISPLAY-space; Lua converts to native.
   ══════════════════════════════════════════════════════════════════════ */

const RES = (typeof GetParentResourceName === 'function') ? GetParentResourceName() : 'oxlyn-handling';
const post = (name, data) =>
    fetch(`https://${RES}/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data || {}),
    }).then(r => r.json()).catch(() => null);

const $ = id => document.getElementById(id);

/* ── State ─────────────────────────────────────────────────────────── */
let L = {};                 // locale table
let FIELDS = [];            // schema array from Lua (only fields this vehicle has)
let DEF = {};               // name → default (display)
let VAL = {};               // name → current (display)
let REFS = {};              // name → DOM refs
let CATS = [];
let PRESETS = { builtin: [], custom: [] };
let activeCat = 'all';
let search = '';
let advOn = false;
let hasOverride = false;
let speedUnit = 'kmh';
let refocusKey = 'F2';
let isOpen = false;
let firstRender = true;

/* vehicle classes */
let VEHICLES = [];          // [{n:model, l:label, h:hashKey}] — every model on the server
let GROUPS = {};            // gid → { label, members:[names], hasTune }
let memberOf = {};          // model name → gid
let TUNED = new Set();      // hashKeys with a direct model tune
let selGroup = null;
let vehSearch = '';
let curModelKey = null;     // hash key of the vehicle being edited
let curGroupLabel = null;   // class label of the edited vehicle (if any)
let expanded = false;

function rebuildMemberOf() {
    memberOf = {};
    Object.entries(GROUPS).forEach(([gid, g]) => {
        (g.members || []).forEach(n => { memberOf[n] = gid; });
    });
}

const t = (k, ...a) => {
    let s = (L && L[k] !== undefined) ? L[k] : k;
    a.forEach(x => { s = s.replace('%s', x); });
    return s;
};

const fmt = (v, dec) => Number(v).toFixed(dec);
const clamp = (v, lo, hi) => Math.min(hi, Math.max(lo, v));
const eps = f => Math.max(1e-6, Math.pow(10, -(f.dec + 1)) * 5);

/* ── Icons ─────────────────────────────────────────────────────────── */
const svg = p => `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">${p}</svg>`;
const ICONS = {
    all:          svg('<rect x="4" y="4" width="7" height="7" rx="2"/><rect x="13" y="4" width="7" height="7" rx="2"/><rect x="4" y="13" width="7" height="7" rx="2"/><rect x="13" y="13" width="7" height="7" rx="2"/>'),
    transmission: svg('<circle cx="12" cy="12" r="3"/><path d="M12 3v3M12 18v3M3 12h3M18 12h3M5.6 5.6l2.2 2.2M16.2 16.2l2.2 2.2M18.4 5.6l-2.2 2.2M7.8 16.2l-2.2 2.2"/>'),
    physics:      svg('<path d="M6 20h12M12 4v12M8 8l4-4 4 4"/><circle cx="12" cy="18" r="1.6"/>'),
    brakes:       svg('<circle cx="12" cy="12" r="8.5"/><circle cx="12" cy="12" r="3.5"/><path d="M12 3.5v2M12 18.5v2M3.5 12h2M18.5 12h2"/>'),
    traction:     svg('<circle cx="12" cy="12" r="8.5"/><circle cx="12" cy="12" r="2"/><path d="M12 5.5l1.5 3.5M17.8 8.6l-3.4 1.8M17.8 15.4l-3.4-1.8M12 18.5l1.5-3.5M6.2 15.4l3.4-1.8M6.2 8.6l3.4 1.8"/>'),
    suspension:   svg('<path d="M12 3v2M12 19v2M7 7l10 2M7 11l10 2M7 15l10 2M7 5h10M7 19h10"/>'),
    damage:       svg('<path d="M12 3l8 3v6c0 4.5-3.2 7.6-8 9-4.8-1.4-8-4.5-8-9V6l8-3z"/><path d="M12 8l-2 4h4l-2 4"/>'),
    misc:         svg('<circle cx="6" cy="12" r="1.6"/><circle cx="12" cy="12" r="1.6"/><circle cx="18" cy="12" r="1.6"/>'),
    flag:         svg('<path d="M6 21V4m0 1h11l-2.5 4L17 13H6"/>'),
    drift:        svg('<path d="M4 17c4 0 4-10 8-10s4 10 8 10"/><path d="M15 14l5 3-5 3"/>'),
    mountain:     svg('<path d="M3 19L9.5 7l4 7 2.5-4 5 9H3z"/>'),
    bolt:         svg('<path d="M13 2L5 13h5l-1 9 8-11h-5l1-9z"/>'),
    grip:         svg('<circle cx="12" cy="12" r="8.5"/><path d="M12 12l4-6M12 12l-6 3.5"/>'),
    shield:       svg('<path d="M12 3l8 3v6c0 4.5-3.2 7.6-8 9-4.8-1.4-8-4.5-8-9V6l8-3z"/>'),
    gauge:        svg('<path d="M4.5 19a9 9 0 1 1 15 0"/><path d="M12 14l3.5-4.5"/><circle cx="12" cy="14" r="1.4"/>'),
    ok:           svg('<path d="M5 12.5l4.5 4.5L19 7.5"/>'),
    err:          svg('<circle cx="12" cy="12" r="8.5"/><path d="M9 9l6 6M15 9l-6 6"/>'),
    info:         svg('<circle cx="12" cy="12" r="8.5"/><path d="M12 11v5M12 8v.2"/>'),
    reset:        svg('<path d="M4 10a8 8 0 1 1 2 6M4 10V4m0 6h6"/>'),
    trash:        svg('<path d="M5 7h14M10 7V5h4v2M8 7l1 13h6l1-13"/>'),
    wrench:       svg('<path d="M14.5 6.3a4.2 4.2 0 0 0-5.8 5L4 16v4h4l4.7-4.7a4.2 4.2 0 0 0 5-5.8l-2.7 2.7-2.3-2.3 2.8-2.6z"/>'),
    stopwatch:    svg('<circle cx="12" cy="13.5" r="7"/><path d="M12 13.5V10M9.5 3.5h5M12 3.5v3"/>'),
    cardown:      svg('<path d="M5 9l1.3-3.5A2 2 0 0 1 8.2 4h7.6a2 2 0 0 1 1.9 1.5L19 9M5 9h14M5 9a2 2 0 0 0-2 2v2h18v-2a2 2 0 0 0-2-2M12 16v5m0 0l-2.5-2.5M12 21l2.5-2.5"/>'),
    engine:       svg('<rect x="7" y="9" width="10" height="9" rx="2"/><path d="M9.5 9V6.5h5V9M12 3.5v3M4.5 12v4M19.5 12v4"/>'),
};

/* ── Themes & interface scale (Settings) ───────────────────────────── */
const THEMES = [
    { id: 'ocean',   label: 'Ocean',   accent: '#0A84FF', rgb: '10, 132, 255',  light: '#8fc7ff', hi: '#2f97ff', lo: '#0a6fe0' },
    { id: 'crimson', label: 'Crimson', accent: '#FF3B30', rgb: '255, 59, 48',   light: '#ff9d94', hi: '#ff6157', lo: '#d92c22' },
    { id: 'emerald', label: 'Emerald', accent: '#30D158', rgb: '48, 209, 88',   light: '#8fe7a8', hi: '#4adc6d', lo: '#1fa844' },
    { id: 'sunset',  label: 'Sunset',  accent: '#FF9F0A', rgb: '255, 159, 10',  light: '#ffce7d', hi: '#ffb340', lo: '#e08600' },
    { id: 'violet',  label: 'Violet',  accent: '#BF5AF2', rgb: '191, 90, 242',  light: '#dcabf7', hi: '#cd7bf5', lo: '#a63fd9' },
    { id: 'rose',    label: 'Rose',    accent: '#FF375F', rgb: '255, 55, 95',   light: '#ff9ab0', hi: '#ff5e7e', lo: '#dd2247' },
    { id: 'teal',    label: 'Teal',    accent: '#40C8E0', rgb: '64, 200, 224',  light: '#9fe3f0', hi: '#5fd4e8', lo: '#22a8c4' },
    { id: 'gold',    label: 'Gold',    accent: '#FFD60A', rgb: '255, 214, 10',  light: '#ffe97d', hi: '#ffdf40', lo: '#dbb500' },
];
const SCALES = [
    { id: 'auto', label: null },   // label filled from locale
    { id: '1',    label: '100%' },
    { id: '1.15', label: '115%' },
    { id: '1.3',  label: '130%' },
    { id: '1.5',  label: '150%' },
];
//  Angled HUD (compact mode): how far the panel leans toward the player.
//  'off' keeps it perfectly flat. Each step pairs an angle with a matching
//  perspective distance and shrink so the tall panel never clips off-screen.
//  Angles are NEGATIVE: rotating that way around a right-edge origin keeps
//  every point at scale <= 1, so the panel can never clip off-screen.
const TILTS = [
    { id: 'off',    label: null, tilt: '0deg',   depth: '2400px', shrink: '1' },
    { id: 'subtle', label: null, tilt: '-6deg',  depth: '2100px', shrink: '1' },
    { id: 'normal', label: null, tilt: '-10deg', depth: '1700px', shrink: '1' },
    { id: 'strong', label: null, tilt: '-15deg', depth: '1400px', shrink: '1' },
];
let curTheme = 'ocean';
let uiScale = 'auto';
let hudTilt = 'normal';

function applyTheme(id) {
    const th = THEMES.find(x => x.id === id) || THEMES[0];
    curTheme = th.id;
    const r = document.documentElement.style;
    r.setProperty('--accent', th.accent);
    r.setProperty('--accent-rgb', th.rgb);
    r.setProperty('--accent-light', th.light);
    r.setProperty('--grad-hi', th.hi);
    r.setProperty('--grad-lo', th.lo);
}

//  4K / 1440p readability: zoom the whole UI. 'auto' scales against 1080p
//  design height (1440p → ~1.33×, 4K → 2×), manual choices override.
function applyScale() {
    const z = uiScale === 'auto'
        ? Math.max(1, Math.min(2, window.innerHeight / 1080))
        : parseFloat(uiScale) || 1;
    document.documentElement.style.zoom = z;
}
window.addEventListener('resize', () => { if (uiScale === 'auto') applyScale(); });

function applyTilt() {
    const p = TILTS.find(x => x.id === hudTilt) || TILTS[2];
    const r = document.documentElement.style;
    r.setProperty('--hud-tilt', p.tilt);
    r.setProperty('--hud-depth', p.depth);
    r.setProperty('--hud-shrink', p.shrink);
}

/* boot: apply persisted prefs immediately (toasts can show before open) */
try {
    curTheme = localStorage.getItem('oxlyn_handling_theme') || 'ocean';
    uiScale = localStorage.getItem('oxlyn_handling_scale') || 'auto';
    hudTilt = localStorage.getItem('oxlyn_handling_tilt') || 'normal';
} catch (e) {}
applyTheme(curTheme);
applyScale();
applyTilt();

/* ── Sounds v2 (soft, filtered WebAudio — Apple-ish) ───────────────── */
let actx = null, sndMaster = null, lastTick = 0;
function ac() {
    if (!actx) {
        actx = new AudioContext();
        sndMaster = actx.createGain();
        sndMaster.gain.value = 0.55;
        const lp = actx.createBiquadFilter();
        lp.type = 'lowpass';
        lp.frequency.value = 5200;         // soften the top end — no harsh beeps
        sndMaster.connect(lp);
        lp.connect(actx.destination);
    }
    return actx;
}
function blip(freq, dur, gain, type, delay, slideTo) {
    try {
        const ctx = ac();
        const t0 = ctx.currentTime + (delay || 0);
        const o = ctx.createOscillator(), g = ctx.createGain();
        o.type = type || 'sine';
        o.frequency.setValueAtTime(freq, t0);
        if (slideTo) o.frequency.exponentialRampToValueAtTime(Math.max(40, slideTo), t0 + dur);
        g.gain.setValueAtTime(0.0001, t0);
        g.gain.exponentialRampToValueAtTime(gain, t0 + 0.008);
        g.gain.exponentialRampToValueAtTime(0.0001, t0 + dur);
        o.connect(g); g.connect(sndMaster);
        o.start(t0); o.stop(t0 + dur + 0.02);
    } catch (e) { /* audio not ready yet */ }
}
const sTick  = () => { const n = performance.now(); if (n - lastTick > 45) { lastTick = n; blip(1750, 0.025, 0.018); } };
const sClick = () => blip(620, 0.07, 0.05, 'sine', 0, 320);
const sOpen  = () => { blip(523, 0.10, 0.05); blip(784, 0.15, 0.045, 'sine', 0.07); };
const sClose = () => { blip(660, 0.09, 0.04); blip(440, 0.13, 0.04, 'sine', 0.06); };
const sOk    = () => { blip(659, 0.09, 0.05); blip(988, 0.15, 0.05, 'sine', 0.08); };
const sErr   = () => blip(200, 0.22, 0.06, 'sawtooth', 0, 130);

/* ── Smooth scrolling (rAF lerp — CEF wheel steps feel heavy) ──────── */
function smoothScroll(el) {
    let target = 0, current = 0, raf = null;
    const step = () => {
        current += (target - current) * 0.16;
        if (Math.abs(target - current) < 0.5) {
            current = target;
            el.scrollTop = current;
            raf = null;
            return;
        }
        el.scrollTop = current;
        raf = requestAnimationFrame(step);
    };
    el.addEventListener('wheel', e => {
        e.preventDefault();
        const max = el.scrollHeight - el.clientHeight;
        if (raf === null) { target = current = el.scrollTop; }
        target = clamp(target + e.deltaY, 0, max);
        if (!raf) raf = requestAnimationFrame(step);
    }, { passive: false });
    el.addEventListener('scroll', () => { if (!raf) { target = current = el.scrollTop; } });
    return {
        toTop() {
            if (raf) cancelAnimationFrame(raf);
            raf = null; target = current = 0; el.scrollTop = 0;
        },
    };
}
const listScroll = smoothScroll($('fieldList'));
smoothScroll(document.querySelector('.drawer-scroll'));
const vehScroll = smoothScroll($('vehList'));

/* ── Live send (batched per animation frame) ───────────────────────── */
let pendingSend = {}, sendQueued = false;
function queueSend(name) {
    pendingSend[name] = VAL[name];
    if (!sendQueued) {
        sendQueued = true;
        requestAnimationFrame(() => {
            sendQueued = false;
            const batch = pendingSend; pendingSend = {};
            post('setFields', { values: batch });
        });
    }
}

/* ── Modified helpers ──────────────────────────────────────────────── */
function isModified(f) {
    const v = VAL[f.name], d = DEF[f.name], e = eps(f);
    if (f.type === 'vector')
        return Math.abs(v.x - d.x) > e || Math.abs(v.y - d.y) > e || Math.abs(v.z - d.z) > e;
    return Math.abs(v - d) > e;
}

const changeCount = () => FIELDS.reduce((n, f) => n + (isModified(f) ? 1 : 0), 0);

function refreshChanges() {
    const n = changeCount();
    const el = $('changeCount');
    el.textContent = n > 0 ? t('ui_changes', n) : t('ui_no_changes');
    el.classList.toggle('has', n > 0);
    // rail modified dots
    const modCats = new Set(FIELDS.filter(isModified).map(f => f.cat));
    document.querySelectorAll('.rail-btn[data-cat]').forEach(b => {
        const c = b.dataset.cat;
        b.classList.toggle('modified', c === 'all' ? modCats.size > 0 : modCats.has(c));
    });
    // drive pill counter
    const pc = $('pChanges');
    pc.textContent = n > 0 ? t('ui_changes', n) : t('ui_no_changes');
    pc.classList.toggle('none', n === 0);
}

/* ── Visibility (category + advanced + search) ─────────────────────── */
function fieldVisible(f, q) {
    if (f.adv && !advOn) return false;
    if (activeCat !== 'all' && f.cat !== activeCat) return false;
    if (q) {
        const label = t('f_' + f.name), desc = t('d_' + f.name);
        if (!(label.toLowerCase().includes(q) || f.name.toLowerCase().includes(q) || desc.toLowerCase().includes(q)))
            return false;
    }
    return true;
}

/* ── Card UI sync ──────────────────────────────────────────────────── */
function syncCard(f) {
    const r = REFS[f.name];
    if (!r) return;
    const mod = isModified(f);
    r.card.classList.toggle('modified', mod);
    const range = `<span class="card-range">${fmt(f.min, f.dec)} – ${fmt(f.max, f.dec)}${f.unit ? ' ' + f.unit : ''}</span>`;
    if (f.type === 'vector') {
        ['x', 'y', 'z'].forEach(ax => {
            r.slider[ax].value = VAL[f.name][ax];
            r.slider[ax].style.setProperty('--fill', ((VAL[f.name][ax] - f.min) / (f.max - f.min) * 100) + '%');
            r.num[ax].value = fmt(VAL[f.name][ax], f.dec);
        });
        r.def.innerHTML = `<span>${t('ui_default')}: <b>${fmt(DEF[f.name].x, f.dec)} / ${fmt(DEF[f.name].y, f.dec)} / ${fmt(DEF[f.name].z, f.dec)}</b></span>${range}`;
    } else {
        r.slider.value = VAL[f.name];
        r.slider.style.setProperty('--fill', ((VAL[f.name] - f.min) / (f.max - f.min) * 100) + '%');
        r.num.value = fmt(VAL[f.name], f.dec);
        // live delta vs stock (absolute + %, when meaningful)
        let delta = '';
        if (mod) {
            const d = VAL[f.name] - DEF[f.name];
            const sign = d > 0 ? '+' : '';
            let pct = '';
            if (Math.abs(DEF[f.name]) > 1e-6) {
                const p = d / DEF[f.name] * 100;
                if (Math.abs(p) < 1000) pct = ` (${sign}${p.toFixed(0)}%)`;
            }
            delta = `<span class="card-delta">Δ ${sign}${fmt(d, f.dec)}${pct}</span>`;
        }
        r.def.innerHTML = `<span>${t('ui_default')}: <b>${fmt(DEF[f.name], f.dec)}${f.unit ? ' ' + f.unit : ''}</b>${delta}</span>${range}`;
    }
}

function syncAll() {
    FIELDS.forEach(syncCard);
    refreshChanges();
}

function setVal(f, v, axis) {
    if (f.type === 'vector') VAL[f.name][axis] = clamp(v, f.min, f.max);
    else VAL[f.name] = f.type === 'int' ? Math.round(clamp(v, f.min, f.max)) : clamp(v, f.min, f.max);
    syncCard(f);
    refreshChanges();
    queueSend(f.name);
}

/* ── Render: vertical rail ─────────────────────────────────────────── */
function renderRail() {
    const counts = { all: 0 };
    FIELDS.forEach(f => {
        if (f.adv && !advOn) return;
        counts.all++;
        counts[f.cat] = (counts[f.cat] || 0) + 1;
    });
    const wrap = $('railCats');
    wrap.innerHTML = '';
    const frag = document.createDocumentFragment();
    ['all', ...CATS].forEach(c => {
        if (c !== 'all' && !counts[c]) return;   // category fully hidden (all-adv, adv off)
        const b = document.createElement('button');
        b.className = 'rail-btn' + (activeCat === c ? ' active' : '');
        b.dataset.cat = c;
        b.innerHTML = `${ICONS[c] || ICONS.misc}<span class="rl"></span><span class="rc">${counts[c] || 0}</span>`;
        b.querySelector('.rl').textContent = t('cat_' + c);
        b.title = t('cat_' + c);
        b.onclick = () => {
            if (activeCat === c) return;
            sClick();
            activeCat = c;
            renderRail();
            renderList(true);
            listScroll.toTop();
        };
        frag.appendChild(b);
    });
    wrap.appendChild(frag);
    refreshChanges();
}

/* ── Render: one control row (slider + number + unit) ──────────────── */
function makeCtrlRow(f, axis) {
    const row = document.createElement('div');
    row.className = 'ctrl-row';
    if (axis) {
        const a = document.createElement('span');
        a.className = 'axis';
        a.textContent = axis.toUpperCase();
        row.appendChild(a);
    }
    const slider = document.createElement('input');
    slider.type = 'range';
    slider.min = f.min; slider.max = f.max; slider.step = f.step;
    slider.addEventListener('input', () => { sTick(); setVal(f, parseFloat(slider.value), axis); });
    // double-click a slider = reset that parameter to stock
    slider.addEventListener('dblclick', () => {
        sClick();
        VAL[f.name] = f.type === 'vector' ? { ...DEF[f.name] } : DEF[f.name];
        syncCard(f); refreshChanges();
        post('resetField', { name: f.name });
    });

    const numWrap = document.createElement('div');
    numWrap.className = 'num-wrap' + (f.unit && !axis ? '' : ' no-unit');
    const num = document.createElement('input');
    num.type = 'text';
    num.className = 'num';
    const commit = () => {
        const v = parseFloat(num.value.replace(',', '.'));
        if (isNaN(v)) { syncCard(f); return; }
        setVal(f, v, axis);
    };
    num.addEventListener('change', commit);
    num.addEventListener('keydown', e => { if (e.key === 'Enter') { commit(); num.blur(); } e.stopPropagation(); });
    numWrap.appendChild(num);
    if (f.unit && !axis) {
        const u = document.createElement('span');
        u.className = 'num-unit';
        u.textContent = f.unit;
        numWrap.appendChild(u);
    }

    row.appendChild(slider);
    row.appendChild(numWrap);
    return { row, slider, num };
}

/* ── Render: field cards (DocumentFragment, optional stagger) ──────── */
function renderList(animate) {
    const list = $('fieldList');
    const frag = document.createDocumentFragment();
    REFS = {};
    const q = search.trim().toLowerCase();
    let shown = 0, idx = 0, lastCat = null;

    FIELDS.forEach(f => {
        if (!fieldVisible(f, q)) return;

        if (activeCat === 'all' && f.cat !== lastCat) {
            lastCat = f.cat;
            const h = document.createElement('div');
            h.className = 'cat-head';
            h.textContent = t('cat_' + f.cat);
            frag.appendChild(h);
        }

        const card = document.createElement('div');
        card.className = 'card' + (animate ? ' anim' : '');
        if (animate) card.style.animationDelay = Math.min(idx * 14, 220) + 'ms';
        idx++; shown++;

        const top = document.createElement('div');
        top.className = 'card-top';
        top.innerHTML = `<span class="card-label"></span><code class="card-name">${f.name}</code>${f.adv ? `<span class="adv-chip">${t('ui_adv_badge')}</span>` : ''}<span class="mod-dot"></span>`;
        top.querySelector('.card-label').textContent = t('f_' + f.name);

        const btnReset = document.createElement('button');
        btnReset.className = 'card-reset';
        btnReset.title = t('ui_reset_field');
        btnReset.innerHTML = ICONS.reset;
        btnReset.onclick = () => {
            sClick();
            VAL[f.name] = f.type === 'vector' ? { ...DEF[f.name] } : DEF[f.name];
            syncCard(f); refreshChanges();
            post('resetField', { name: f.name });
        };
        top.appendChild(btnReset);
        card.appendChild(top);

        const d = document.createElement('div');
        d.className = 'card-desc';
        d.textContent = t('d_' + f.name);
        card.appendChild(d);

        const defEl = document.createElement('div');
        defEl.className = 'card-def';
        card.appendChild(defEl);

        const refs = { card, def: defEl };
        if (f.type === 'vector') {
            refs.slider = {}; refs.num = {};
            ['x', 'y', 'z'].forEach(ax => {
                const c = makeCtrlRow(f, ax);
                refs.slider[ax] = c.slider; refs.num[ax] = c.num;
                card.appendChild(c.row);
            });
        } else {
            const c = makeCtrlRow(f, null);
            refs.slider = c.slider; refs.num = c.num;
            card.appendChild(c.row);
        }

        REFS[f.name] = refs;
        frag.appendChild(card);
    });

    list.innerHTML = '';
    list.appendChild(frag);
    // sync AFTER attach (content-visibility needs layout for --fill anyway)
    FIELDS.forEach(f => { if (REFS[f.name]) syncCard(f); });

    $('fieldCount').textContent = shown;
    $('noResults').classList.toggle('hidden', shown > 0);
    $('noResults').textContent = t('ui_no_results');
    refreshChanges();
}

/* ── Advanced toggle ───────────────────────────────────────────────── */
$('advToggle').onclick = () => {
    sClick();
    advOn = !advOn;
    $('advToggle').classList.toggle('on', advOn);
    // if the active category vanished with adv off, fall back to All
    if (!advOn && activeCat !== 'all' && !FIELDS.some(f => f.cat === activeCat && !f.adv)) activeCat = 'all';
    renderRail();
    renderList(true);
};

/* ── Presets ───────────────────────────────────────────────────────── */
function applyPresetOps(fieldsSpec, absolute) {
    Object.entries(fieldsSpec).forEach(([name, spec]) => {
        const f = FIELDS.find(x => x.name === name);
        if (!f) return;
        if (f.type === 'vector') {
            if (absolute && spec && spec.x !== undefined) {
                VAL[name] = { x: clamp(spec.x, f.min, f.max), y: clamp(spec.y, f.min, f.max), z: clamp(spec.z, f.min, f.max) };
                queueSend(name);
            }
            return;
        }
        let v;
        if (absolute) v = Number(spec);
        else {
            const d = DEF[name];
            if (spec.mode === 'mul') v = d * spec.v;
            else if (spec.mode === 'add') v = d + spec.v;
            else v = spec.v;
        }
        if (isNaN(v)) return;
        VAL[name] = f.type === 'int' ? Math.round(clamp(v, f.min, f.max)) : clamp(v, f.min, f.max);
        queueSend(name);
    });
    syncAll();
}

function renderPresets() {
    const bg = $('builtinGrid');
    bg.innerHTML = '';
    const bfrag = document.createDocumentFragment();
    PRESETS.builtin.forEach((p, i) => {
        const c = document.createElement('div');
        c.className = 'preset-card';
        c.style.animationDelay = (i * 30) + 'ms';
        c.innerHTML = `<div class="preset-ico">${ICONS[p.icon] || ICONS.gauge}</div><h4></h4><p></p><div class="pc-n">${t('ui_preset_fields', p.count)}</div>`;
        c.querySelector('h4').textContent = p.label;
        c.querySelector('p').textContent = p.desc || '';
        c.onclick = () => {
            sClick();
            applyPresetOps(p.fields, false);
            closeDrawer();
            toast(t('toast_preset_applied', p.label), 'info');
        };
        bfrag.appendChild(c);
    });
    bg.appendChild(bfrag);

    const cl = $('customList');
    cl.innerHTML = '';
    if (!PRESETS.custom.length) {
        const e = document.createElement('div');
        e.className = 'preset-empty';
        e.textContent = t('ui_preset_none');
        cl.appendChild(e);
    }
    const cfrag = document.createDocumentFragment();
    PRESETS.custom.forEach((p, i) => {
        const r = document.createElement('div');
        r.className = 'preset-row';
        r.style.animationDelay = (i * 30) + 'ms';
        r.innerHTML = `<div class="pr-info"><h4></h4><p>${t('ui_preset_fields', p.count || Object.keys(p.fields).length)}</p></div>
                       <button class="pr-apply">${t('ui_apply')}</button>
                       <button class="pr-del">${ICONS.trash}</button>`;
        r.querySelector('h4').textContent = p.label;
        r.querySelector('.pr-apply').onclick = () => {
            sClick();
            applyPresetOps(p.fields, true);
            closeDrawer();
            toast(t('toast_preset_applied', p.label), 'info');
        };
        r.querySelector('.pr-del').onclick = () => {
            confirmBox(t('ui_confirm_delete'), async () => {
                const res = await post('deletePreset', { id: p.id });
                if (res && res.ok) {
                    PRESETS.custom = res.presets || [];
                    renderPresets();
                    toast(t('toast_preset_deleted'), 'info');
                }
            });
        };
        cfrag.appendChild(r);
    });
    cl.appendChild(cfrag);
}

/* ── Animated hide ─────────────────────────────────────────────────────
   Every overlay entered with a spring and then vanished on a raw
   display:none, which read as a glitch. `.closing` plays the reverse
   (see the Motion polish block in style.css) and only then do we set
   .hidden. `instant` skips it — used when the editor re-opens and has to
   reset every overlay in the same frame. */
const EXIT_MS = 210;
const exitTimers = new WeakMap();
let appExitTimer = null;   // pending slide-out of the whole editor
function hideAnimated(el, instant) {
    if (!el) return;
    const pending = exitTimers.get(el);
    if (pending) { clearTimeout(pending); exitTimers.delete(el); }
    el.classList.remove('closing');
    if (instant || el.classList.contains('hidden')) {
        el.classList.add('hidden');
        return;
    }
    el.classList.add('closing');
    exitTimers.set(el, setTimeout(() => {
        el.classList.add('hidden');
        el.classList.remove('closing');
        exitTimers.delete(el);
    }, EXIT_MS));
}
/* Show helper: cancels any in-flight exit so a fast close→open never
   leaves an overlay stuck mid-animation. */
function showAnimated(el) {
    if (!el) return;
    const pending = exitTimers.get(el);
    if (pending) { clearTimeout(pending); exitTimers.delete(el); }
    el.classList.remove('closing');
    el.classList.remove('hidden');
}

function openDrawer()  { sClick(); renderPresets(); showAnimated($('drawer')); }
function closeDrawer(instant) { hideAnimated($('drawer'), instant); }

/* ── Vehicles / classes drawer ─────────────────────────────────────── */
function openVehDrawer() {
    sClick();
    showAnimated($('vehDrawer'));   // visible first: the virtualizer needs clientHeight
    renderGroupChips();
    renderGroupActions();
    renderVehList();
}
function closeVehDrawer(instant) { hideAnimated($('vehDrawer'), instant); }

function applyGroupsUpdate(groups) {
    GROUPS = groups || {};
    if (selGroup && !GROUPS[selGroup]) selGroup = null;
    rebuildMemberOf();
    renderGroupChips();
    renderGroupActions();
    renderVehList(true);   // keep scroll
}

function renderGroupChips() {
    const wrap = $('groupChips');
    wrap.innerHTML = '';
    const frag = document.createDocumentFragment();
    Object.entries(GROUPS)
        .sort((a, b) => a[1].label.localeCompare(b[1].label))
        .forEach(([gid, g]) => {
            const c = document.createElement('button');
            c.className = 'group-chip' + (selGroup === gid ? ' active' : '');
            c.innerHTML = `${g.hasTune ? '<span class="gc-tune"></span>' : ''}<span class="gc-l"></span><span class="gc-n">${(g.members || []).length}</span>`;
            c.querySelector('.gc-l').textContent = g.label;
            c.onclick = () => {
                sClick();
                selGroup = (selGroup === gid) ? null : gid;
                renderGroupChips();
                renderGroupActions();
                renderVehList(true);
            };
            frag.appendChild(c);
        });
    wrap.appendChild(frag);
}

function renderGroupActions() {
    const box = $('groupActions');
    const g = selGroup && GROUPS[selGroup];
    if (!g) { box.classList.add('hidden'); return; }
    box.classList.remove('hidden');
    $('gaCount').textContent = `${g.label} — ${t('ui_members', (g.members || []).length)} · ${g.hasTune ? t('ui_group_tuned') : t('ui_group_no_tune')}`;
    $('btnGroupClear').style.display = g.hasTune ? '' : 'none';
}

/* Virtualized vehicle list: with 1000+ models, real DOM rows make scrolling
   heavy no matter what. Only the ~20 visible rows exist — a recycled pool of
   elements repositioned with transforms over a spacer that provides the
   scroll height. Buttery at any list size, 1 or 2 columns. */
const VROW_H = 47;   // 42px row + 5px gap
let vehFiltered = [];
let vehPool = [];
let vehSpacer = null;
let vehRaf = false;

function filterVehicles() {
    const q = vehSearch.trim().toLowerCase();
    vehFiltered = q
        ? VEHICLES.filter(v => v.l.toLowerCase().includes(q) || v.n.includes(q))
        : VEHICLES;
    $('vehCount').textContent = vehFiltered.length;
}

function makeVehRow() {
    const el = document.createElement('div');
    el.className = 'veh-row';
    el.innerHTML =
        `<span class="v-check">${ICONS.ok}</span>` +
        `<div class="v-info"><h4></h4><code></code></div>` +
        `<span class="v-badge tuned"></span><span class="v-badge grp"></span>`;
    el.onclick = async () => {
        const v = el._veh;
        if (!v) return;
        if (!selGroup) { toast(t('toast_select_group'), 'err'); return; }
        sClick();
        const res = await post('toggleMember', { id: selGroup, model: v.n });
        if (res && res.ok) applyGroupsUpdate(res.groups);
    };
    return el;
}

function bindVehRow(el, v) {
    const gid = memberOf[v.n];
    const inSel = selGroup && gid === selGroup;
    el._veh = v;
    el.classList.toggle('in-sel', !!inSel);
    el.querySelector('h4').textContent = v.l;
    el.querySelector('code').textContent = v.n;
    const tb = el.querySelector('.v-badge.tuned');
    if (TUNED.has(v.h)) { tb.style.display = ''; tb.textContent = t('ui_tuned'); }
    else tb.style.display = 'none';
    const gb = el.querySelector('.v-badge.grp');
    if (gid && GROUPS[gid]) {
        gb.style.display = '';
        gb.textContent = GROUPS[gid].label;
        gb.classList.toggle('other', !inSel);
    } else gb.style.display = 'none';
}

function renderVehVirtual() {
    const list = $('vehList');
    if (!vehSpacer) {
        vehSpacer = document.createElement('div');
        vehSpacer.style.cssText = 'width:1px;pointer-events:none;';
        list.appendChild(vehSpacer);
        list.addEventListener('scroll', () => {
            if (vehRaf) return;
            vehRaf = true;
            requestAnimationFrame(() => { vehRaf = false; renderVehVirtual(); });
        });
    }
    const cols = expanded ? 2 : 1;
    const rowW = cols === 2 ? 'calc((100% - 47px)/2)' : 'calc(100% - 38px)';
    const totalRows = Math.ceil(vehFiltered.length / cols);
    vehSpacer.style.height = (totalRows * VROW_H + 12) + 'px';

    const h = list.clientHeight || 420;
    const need = (Math.ceil(h / VROW_H) + 4) * cols;
    while (vehPool.length < need) {
        const r = makeVehRow();
        vehPool.push(r);
        list.appendChild(r);
    }
    const firstRow = Math.max(0, Math.floor(list.scrollTop / VROW_H) - 2);
    for (let i = 0; i < vehPool.length; i++) {
        const el = vehPool[i];
        const idx = firstRow * cols + i;
        if (i >= need || idx >= vehFiltered.length) { el.style.display = 'none'; continue; }
        const row = Math.floor(idx / cols), col = idx % cols;
        el.style.display = '';
        el.style.width = rowW;
        el.style.transform = `translate(${col ? 'calc(100% + 9px)' : '0px'}, ${row * VROW_H + 4}px)`;
        bindVehRow(el, vehFiltered[idx]);
    }
}

function renderVehList(keepScroll) {
    filterVehicles();
    if (!keepScroll) $('vehList').scrollTop = 0;
    renderVehVirtual();
}

$('btnVehicles').onclick = openVehDrawer;
$('btnVehClose').onclick = () => { sClick(); closeVehDrawer(); };

$('btnCreateGroup').onclick = async () => {
    const name = $('groupName').value.trim();
    if (!name) { toast(t('toast_group_name'), 'err'); return; }
    sClick();
    const res = await post('createGroup', { label: name });
    if (res && res.ok) {
        $('groupName').value = '';
        selGroup = res.gid || null;
        applyGroupsUpdate(res.groups);
        toast(t('toast_group_created', name), 'ok');
    }
};
$('groupName').addEventListener('keydown', e => {
    if (e.key === 'Enter') $('btnCreateGroup').click();
    e.stopPropagation();
});

$('btnGroupRename').onclick = () => {
    const g = selGroup && GROUPS[selGroup];
    if (!g) return;
    promptBox(t('ui_rename_group'), g.label, async name => {
        const res = await post('renameGroup', { id: selGroup, label: name });
        if (res && res.ok) {
            applyGroupsUpdate(res.groups);
            toast(t('toast_group_renamed', name), 'ok');
        }
    });
};

$('btnGroupDelete').onclick = () => {
    const g = selGroup && GROUPS[selGroup];
    if (!g) return;
    confirmBox(t('ui_confirm_group_delete', g.label), async () => {
        const res = await post('deleteGroup', { id: selGroup });
        if (res && res.ok) {
            applyGroupsUpdate(res.groups);
            toast(t('toast_group_deleted'), 'info');
        }
    });
};

$('btnGroupTune').onclick = () => {
    const g = selGroup && GROUPS[selGroup];
    if (!g) return;
    confirmBox(t('ui_confirm_group_tune', g.label), async () => {
        const res = await post('saveGroupTune', { id: selGroup });
        if (res && res.ok) {
            applyGroupsUpdate(res.groups);
            toast(t('toast_group_tune_saved'), 'ok');
        } else {
            toast(t('toast_save_error'), 'err');
        }
    });
};

$('btnGroupClear').onclick = () => {
    const g = selGroup && GROUPS[selGroup];
    if (!g) return;
    confirmBox(t('ui_confirm_group_clear', g.label), async () => {
        const res = await post('clearGroupTune', { id: selGroup });
        if (res && res.ok) {
            applyGroupsUpdate(res.groups);
            toast(t('toast_group_tune_cleared'), 'info');
        }
    });
};

let vehSearchTimer = null;
$('vehSearch').addEventListener('input', e => {
    vehSearch = e.target.value;
    clearTimeout(vehSearchTimer);
    vehSearchTimer = setTimeout(() => { renderVehList(); vehScroll.toTop(); }, 120);
});

/* ── Layout: compact (right panel) ⇄ expanded (centered) ───────────── */
function applyLayout() {
    $('panel').classList.toggle('expanded', expanded);
    $('btnLayout').title = expanded ? t('ui_compact') : t('ui_expand');
    if (!$('vehDrawer').classList.contains('hidden')) renderVehVirtual();   // 1 ⇄ 2 columns
}
$('btnLayout').onclick = () => {
    sClick();
    expanded = !expanded;
    try { localStorage.setItem('oxlyn_handling_expanded', expanded ? '1' : '0'); } catch (e) {}
    applyLayout();
};

/* ── Settings drawer ───────────────────────────────────────────────── */
function renderSettings() {
    const tg = $('themeGrid');
    tg.innerHTML = '';
    THEMES.forEach(th => {
        const b = document.createElement('button');
        b.className = 'theme-sw' + (curTheme === th.id ? ' active' : '');
        b.style.background = `linear-gradient(150deg, rgba(${th.rgb}, 0.42), rgba(${th.rgb}, 0.10) 55%, rgba(16,17,22,0.6))`;
        b.innerHTML = `<span class="sw-dot" style="background:linear-gradient(180deg, ${th.hi}, ${th.lo})"></span><span class="sw-name">${th.label}</span>`;
        b.onclick = () => {
            sClick();
            applyTheme(th.id);
            try { localStorage.setItem('oxlyn_handling_theme', th.id); } catch (e) {}
            renderSettings();
        };
        tg.appendChild(b);
    });

    const sr = $('scaleRow');
    sr.innerHTML = '';
    SCALES.forEach(sc => {
        const c = document.createElement('button');
        c.className = 'scale-chip' + (uiScale === sc.id ? ' active' : '');
        c.textContent = sc.label || t('ui_scale_auto');
        c.onclick = () => {
            sClick();
            uiScale = sc.id;
            try { localStorage.setItem('oxlyn_handling_scale', sc.id); } catch (e) {}
            applyScale();
            renderSettings();
        };
        sr.appendChild(c);
    });

    const tr = $('tiltRow');
    tr.innerHTML = '';
    TILTS.forEach(tl => {
        const c = document.createElement('button');
        c.className = 'scale-chip' + (hudTilt === tl.id ? ' active' : '');
        c.textContent = t('ui_tilt_' + tl.id);
        c.onclick = () => {
            sClick();
            hudTilt = tl.id;
            try { localStorage.setItem('oxlyn_handling_tilt', tl.id); } catch (e) {}
            applyTilt();
            renderSettings();
        };
        tr.appendChild(c);
    });
}
$('btnSettings').onclick = () => { sClick(); renderSettings(); showAnimated($('setDrawer')); };
$('btnSetClose').onclick = () => { sClick(); hideAnimated($('setDrawer')); };

/* ── Export: current values as a handling.meta <Item> block ────────── */
const fx6 = n => Number(n).toFixed(6);
function buildMetaXml() {
    const nm = ($('vehModel').textContent || 'model').toUpperCase();
    const lines = ['<Item type="CHandlingData">', `  <handlingName>${nm}</handlingName>`];
    FIELDS.forEach(f => {
        const v = VAL[f.name];
        if (v === undefined) return;
        if (f.type === 'vector') lines.push(`  <${f.name} x="${fx6(v.x)}" y="${fx6(v.y)}" z="${fx6(v.z)}" />`);
        else if (f.type === 'int') lines.push(`  <${f.name} value="${Math.round(v)}" />`);
        else lines.push(`  <${f.name} value="${fx6(v)}" />`);
    });
    lines.push('</Item>');
    return lines.join('\n');
}
/* Auto-edit handling.meta files: when ON, every successful Save also writes
   the values into the model's handling.meta inside its resource. */
let autoEdit = false;
try { autoEdit = localStorage.getItem('oxlyn_handling_autoedit') === '1'; } catch (e) {}

function syncAutoEditUI() {
    $('autoEditToggle').classList.toggle('on', autoEdit);
}
$('autoEditToggle').onclick = () => {
    sClick();
    autoEdit = !autoEdit;
    try { localStorage.setItem('oxlyn_handling_autoedit', autoEdit ? '1' : '0'); } catch (e) {}
    syncAutoEditUI();
};

async function runAutoEditMeta() {
    const res = await post('autoEditMeta');
    if (res && res.ok) toast(t('toast_meta_edited', res.where || ''), 'ok');
    else toast(t('toast_meta_notfound'), 'err');
}

$('btnExport').onclick = () => {
    sClick();
    $('exportText').value = buildMetaXml();
    syncAutoEditUI();
    showAnimated($('exportWrap'));
};
$('btnExportClose').onclick = () => { sClick(); hideAnimated($('exportWrap')); };
$('btnCopyExport').onclick = () => {
    const ta = $('exportText');
    ta.focus(); ta.select();
    try { document.execCommand('copy'); toast(t('toast_copied'), 'ok'); }
    catch (e) { toast(t('toast_save_error'), 'err'); }
};

/* ── Handling clipboard (copy on one vehicle → paste on another) ─────
   The snapshot lives in localStorage, so it survives closing the editor,
   switching vehicles and even relogging. Paste applies through the same
   absolute-preset path as custom presets: only fields that exist on the
   TARGET vehicle are touched, everything is clamped to schema ranges,
   and nothing is persisted until the user presses Save. */
let CLIP = null;
try { CLIP = JSON.parse(localStorage.getItem('oxlyn_handling_clipboard') || 'null'); } catch (e) { CLIP = null; }

function updatePasteBtn() {
    const b = $('btnPasteTune');
    const has = !!(CLIP && CLIP.values);
    b.classList.toggle('dim', !has);
    b.title = has ? t('ui_paste_tune_from', CLIP.label || CLIP.model || '?') : t('ui_paste_tune');
}

$('btnCopyTune').onclick = () => {
    sClick();
    const values = {};
    let n = 0;
    FIELDS.forEach(f => {
        const v = VAL[f.name];
        if (v === undefined) return;
        values[f.name] = f.type === 'vector' ? { ...v } : v;
        n++;
    });
    CLIP = { label: $('vehLabel').textContent, model: $('vehModel').textContent, values };
    try { localStorage.setItem('oxlyn_handling_clipboard', JSON.stringify(CLIP)); } catch (e) {}
    updatePasteBtn();
    toast(t('toast_tune_copied', CLIP.label, n), 'ok');
};

$('btnPasteTune').onclick = () => {
    if (!CLIP || !CLIP.values) { toast(t('toast_clipboard_empty'), 'err'); return; }
    sClick();
    const applicable = Object.keys(CLIP.values).filter(name => FIELDS.some(f => f.name === name));
    if (!applicable.length) { toast(t('toast_paste_none'), 'err'); return; }
    applyPresetOps(CLIP.values, true);
    toast(t('toast_tune_pasted', CLIP.label || CLIP.model || '?', applicable.length), 'ok');
};

/* ── Toasts ────────────────────────────────────────────────────────── */
function toast(msg, type = 'ok') {
    const el = document.createElement('div');
    el.className = `toast ${type}`;
    el.innerHTML = `${ICONS[type] || ICONS.ok}<span></span>`;
    el.querySelector('span').textContent = msg;
    $('toasts').appendChild(el);
    if (type === 'err') sErr(); else sOk();
    setTimeout(() => { el.classList.add('out'); setTimeout(() => el.remove(), 320); }, 2800);
}

/* ── Prompt dialog (text input) ────────────────────────────────────── */
let promptCb = null;
function promptBox(msg, initial, cb) {
    promptCb = cb;
    $('promptMsg').textContent = msg;
    $('promptInput').value = initial || '';
    showAnimated($('promptWrap'));
    setTimeout(() => { $('promptInput').focus(); $('promptInput').select(); }, 50);
}
$('btnPromptNo').onclick = () => { sClick(); hideAnimated($('promptWrap')); promptCb = null; };
$('btnPromptYes').onclick = () => {
    sClick();
    const v = $('promptInput').value.trim();
    hideAnimated($('promptWrap'));
    if (promptCb && v) promptCb(v);
    promptCb = null;
};
$('promptInput').addEventListener('keydown', e => {
    if (e.key === 'Enter') $('btnPromptYes').click();
    e.stopPropagation();
});

/* ── Confirm dialog ────────────────────────────────────────────────── */
let confirmCb = null;
function confirmBox(msg, cb) {
    confirmCb = cb;
    $('confirmMsg').textContent = msg;
    showAnimated($('confirmWrap'));
}
$('btnConfirmNo').onclick = () => { sClick(); hideAnimated($('confirmWrap')); confirmCb = null; };
$('btnConfirmYes').onclick = () => {
    sClick();
    hideAnimated($('confirmWrap'));
    if (confirmCb) { confirmCb(); confirmCb = null; }
};

/* ── Static UI text ────────────────────────────────────────────────── */
function applyLocaleChrome() {
    $('hSub').textContent = t('ui_subtitle');
    $('hTitle').textContent = t('ui_title');
    $('search').placeholder = t('ui_search');
    $('btnPresetsTxt').textContent = t('ui_presets');
    $('btnResetAllTxt').textContent = t('ui_reset_all');
    $('btnDriveTxt').textContent = t('ui_drive');
    $('btnSaveTxt').textContent = t('ui_save');
    $('drawerTitle').textContent = t('ui_presets');
    $('hBuiltin').textContent = t('ui_preset_builtin');
    $('hCustom').textContent = t('ui_preset_custom');
    $('presetName').placeholder = t('ui_preset_name_ph');
    $('btnSavePresetTxt').textContent = t('ui_save_preset');
    $('advLabel').textContent = t('ui_advanced');
    $('advToggle').title = t('ui_advanced_hint');
    $('btnVehiclesTxt').textContent = t('ui_vehicles');
    $('vehTitle').textContent = t('ui_vehicles');
    $('hGroups').textContent = t('ui_groups');
    $('groupName').placeholder = t('ui_new_group_ph');
    $('btnCreateGroupTxt').textContent = t('ui_create');
    $('btnGroupTuneTxt').textContent = t('ui_set_group_tune');
    $('btnGroupClearTxt').textContent = t('ui_clear_group_tune');
    $('btnGroupDelete').title = t('ui_delete');
    $('btnGroupRename').title = t('ui_rename');
    $('btnPromptNo').querySelector('span').textContent = t('ui_cancel');
    $('btnPromptYes').querySelector('span').textContent = t('ui_confirm');
    $('vehHint').textContent = t('ui_select_group_hint') + ' ' + t('ui_group_priority');
    $('vehSearch').placeholder = t('ui_search_vehicles');
    $('btnLayout').title = expanded ? t('ui_compact') : t('ui_expand');
    $('btnExport').title = t('ui_export');
    $('btnCopyTune').title = t('ui_copy_tune');
    updatePasteBtn();
    $('btnSettings').title = t('ui_settings');
    $('setTitle').textContent = t('ui_settings');
    $('hTheme').textContent = t('ui_theme');
    $('hScale').textContent = t('ui_scale');
    $('hTilt').textContent = t('ui_tilt');
    $('exportTitle').textContent = t('ui_export');
    $('exportHint').textContent = t('ui_export_hint');
    $('autoEditLabel').textContent = t('ui_autoedit');
    $('autoEditHint').textContent = t('ui_autoedit_hint');
    $('btnCopyExportTxt').textContent = t('ui_copy');
    $('tSpeedK').textContent = t('ui_speed');
    $('tGearK').textContent = t('ui_gear');
    $('tRpmK').textContent = t('ui_rpm');
    $('pGearK').textContent = t('ui_gear');
    const unit = speedUnit === 'mph' ? t('ui_mph') : t('ui_kmh');
    $('tUnit').textContent = unit;
    $('pUnit').textContent = unit;
    $('btnConfirmNo').querySelector('span').textContent = t('ui_cancel');
    $('btnConfirmYes').querySelector('span').textContent = t('ui_confirm');
    $('footHint').innerHTML =
        `<span><span class="key-chip">ESC</span>${t('ui_close')}</span>` +
        `<span><span class="key-chip">${refocusKey}</span>${t('ui_drive')}</span>`;
}

function setBadge() {
    const b = $('tuneBadge');
    if (hasOverride) {
        b.className = 'badge custom';
        b.textContent = t('ui_override_active');
    } else if (curGroupLabel) {
        b.className = 'badge custom';
        b.textContent = curGroupLabel.toUpperCase();
    } else {
        b.className = 'badge stock';
        b.textContent = t('ui_stock_vehicle');
    }
}

/* ── Buttons ───────────────────────────────────────────────────────── */
$('btnClose').onclick = () => { sClick(); post('close'); };
$('btnPresets').onclick = openDrawer;
$('btnDrawerClose').onclick = () => { sClick(); closeDrawer(); };

$('btnResetAll').onclick = () => {
    sClick();
    FIELDS.forEach(f => { VAL[f.name] = f.type === 'vector' ? { ...DEF[f.name] } : DEF[f.name]; });
    syncAll();
    post('resetAll');
    toast(t('toast_all_reset'), 'info');
};

$('btnSave').onclick = async () => {
    sClick();
    const btn = $('btnSave');
    btn.classList.add('saving');
    $('btnSaveTxt').textContent = t('ui_saving');
    const res = await post('save');
    btn.classList.remove('saving');
    $('btnSaveTxt').textContent = t('ui_save');
    if (res && res.ok) {
        hasOverride = res.count > 0;
        if (curModelKey) {
            if (hasOverride) TUNED.add(curModelKey); else TUNED.delete(curModelKey);
        }
        setBadge();
        toast(res.count > 0 ? t('toast_saved', $('vehLabel').textContent) : t('toast_reset'), 'ok');
        if (autoEdit) runAutoEditMeta();
    } else {
        toast(t('toast_save_error'), 'err');
    }
};

$('btnDrive').onclick = () => {
    sClick();
    post('drive');
    $('panel').classList.add('hidden');
    $('pHint').innerHTML = t('ui_drive_hint', `<b>${refocusKey}</b>`);
    $('drivePill').classList.remove('hidden');
    refreshChanges();
};

$('btnSavePreset').onclick = async () => {
    const name = $('presetName').value.trim();
    if (!name) { toast(t('toast_preset_name'), 'err'); return; }
    sClick();
    const res = await post('savePreset', { label: name });
    if (res && res.ok) {
        PRESETS.custom = res.presets || [];
        $('presetName').value = '';
        renderPresets();
        toast(t('toast_preset_saved', name), 'ok');
    } else {
        toast(t('toast_save_error'), 'err');
    }
};

/* Debounced search (re-render without entrance animations) */
let searchTimer = null;
$('search').addEventListener('input', e => {
    search = e.target.value;
    clearTimeout(searchTimer);
    searchTimer = setTimeout(() => { renderList(false); listScroll.toTop(); }, 110);
});

/* ── Keyboard ──────────────────────────────────────────────────────── */
window.addEventListener('keydown', e => {
    if (!isOpen) return;
    if (e.key === 'Escape') {
        /* an overlay already playing its exit counts as closed — otherwise a
           double-ESC would restart its animation instead of falling through
           to the next layer. */
        const vis = id => {
            const el = $(id);
            return !el.classList.contains('hidden') && !el.classList.contains('closing');
        };
        if (vis('confirmWrap')) { hideAnimated($('confirmWrap')); confirmCb = null; return; }
        if (vis('promptWrap'))  { hideAnimated($('promptWrap')); promptCb = null; return; }
        if (vis('exportWrap'))  { hideAnimated($('exportWrap')); return; }
        if (vis('setDrawer'))   { hideAnimated($('setDrawer')); return; }
        if (vis('drawer'))      { closeDrawer(); return; }
        if (vis('vehDrawer'))   { closeVehDrawer(); return; }
        post('close');
    }
});

/* ── Reset model: click the "custom tune" badge ────────────────────── */
$('tuneBadge').onclick = () => {
    if (!hasOverride) return;
    confirmBox(t('ui_confirm_reset'), async () => {
        const res = await post('resetModel');
        if (res && res.ok) {
            FIELDS.forEach(f => { VAL[f.name] = f.type === 'vector' ? { ...DEF[f.name] } : DEF[f.name]; });
            hasOverride = false;
            if (curModelKey) TUNED.delete(curModelKey);
            setBadge();
            syncAll();
            toast(t('toast_reset'), 'ok');
        }
    });
};

/* ── Drive-mode gauge ──────────────────────────────────────────────── */
const GAUGE_LEN = 245;   // 270° of a r=52 circle
function setGauge(rpm) {
    $('gaugeArc').style.strokeDashoffset = (GAUGE_LEN * (1 - clamp(rpm, 0, 1))).toFixed(1);
}

/*  Restore every INTERFACE preference to the script defaults.
    Triggered by the reset command (see Config.ResetCommand) so a player who
    picked an interface size too large to click Settings can always recover —
    it works with the editor closed and never touches handling data. */
function resetUiSettings() {
    ['theme', 'scale', 'tilt', 'expanded', 'autoedit']
        .forEach(k => { try { localStorage.removeItem('oxlyn_handling_' + k); } catch (e) {} });

    uiScale = 'auto';
    hudTilt = 'normal';
    expanded = false;
    autoEdit = false;
    applyTheme('ocean');
    applyScale();
    applyTilt();
    applyLayout();
    syncAutoEditUI();
    if (!$('setDrawer').classList.contains('hidden')) renderSettings();
}

/* ── NUI messages ──────────────────────────────────────────────────── */
window.addEventListener('message', ({ data }) => {
    if (data.action === 'open') {
        L = data.locale || {};
        CATS = data.categories || [];
        FIELDS = data.fields || [];
        PRESETS = data.presets || { builtin: [], custom: [] };
        speedUnit = data.speedUnit || 'kmh';
        refocusKey = data.refocusKey || 'F2';
        hasOverride = !!(data.vehicle && data.vehicle.hasOverride);
        DEF = {}; VAL = {};
        FIELDS.forEach(f => {
            DEF[f.name] = f.type === 'vector' ? { ...f.def } : f.def;
            VAL[f.name] = f.type === 'vector' ? { ...f.value } : f.value;
        });
        activeCat = 'all'; search = ''; firstRender = true;
        $('search').value = '';
        $('vehLabel').textContent = (data.vehicle && data.vehicle.label) || '—';
        $('vehModel').textContent = ((data.vehicle && data.vehicle.model) || '').toLowerCase();
        /* vehicle classes */
        VEHICLES = data.vehicles || [];
        GROUPS = data.groups || {};
        rebuildMemberOf();
        TUNED = new Set(data.tuned || []);
        curModelKey = (data.vehicle && data.vehicle.modelKey) || null;
        curGroupLabel = (data.vehicle && data.vehicle.group) || null;
        selGroup = null; vehSearch = '';
        $('vehSearch').value = '';
        /* layout preference */
        try { expanded = localStorage.getItem('oxlyn_handling_expanded') === '1'; } catch (e) { expanded = false; }
        applyLayout();
        applyLocaleChrome();
        setBadge();
        renderRail();
        renderList(true);
        listScroll.toTop();
        /* instant: the editor is opening fresh, nothing should be seen
           animating itself away behind the incoming panel */
        closeDrawer(true);
        closeVehDrawer(true);
        hideAnimated($('setDrawer'), true);
        hideAnimated($('confirmWrap'), true);
        hideAnimated($('promptWrap'), true);
        hideAnimated($('exportWrap'), true);
        $('drivePill').classList.add('hidden');
        $('panel').classList.remove('hidden');
        /* clear a pending close so re-opening mid-slide-out restarts clean */
        if (appExitTimer) { clearTimeout(appExitTimer); appExitTimer = null; }
        $('app').classList.remove('closing');
        $('app').classList.remove('hidden');
        isOpen = true;
        sOpen();
    }
    else if (data.action === 'close') {
        isOpen = false;
        /* slide the HUD back out instead of blinking off. Lua has already
           dropped NUI focus, so these ~260ms are purely cosmetic. */
        const app = $('app');
        if (appExitTimer) clearTimeout(appExitTimer);
        app.classList.add('closing');
        appExitTimer = setTimeout(() => {
            app.classList.add('hidden');
            app.classList.remove('closing');
            appExitTimer = null;
        }, 260);
        sClose();
    }
    else if (data.action === 'resetUi') {
        resetUiSettings();
    }
    else if (data.action === 'notify') {
        toast(data.msg, data.ntype || 'info');
    }
    else if (data.action === 'refocus') {
        $('drivePill').classList.add('hidden');
        $('panel').classList.remove('hidden');
    }
    else if (data.action === 'telemetry') {
        const gear = data.gear === 0 ? 'R' : data.gear;
        $('tSpeed').textContent = data.speed;
        $('tGear').textContent = gear;
        $('tRpmFill').style.width = Math.round((data.rpm || 0) * 100) + '%';
        $('pSpeed').textContent = data.speed;
        $('pGear').textContent = gear;
        setGauge(data.rpm || 0);
    }
});
