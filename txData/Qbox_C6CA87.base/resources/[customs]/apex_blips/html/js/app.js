/* ═══════════════════════════════════════════════════════════════════════════
   APEX BLIP STUDIO — app.js
   One plain-JS file, no build step. Two personalities:

     · the STUDIO — everything visible: list, editor, images, developer tab;
     · the BAKE SERVICE — always on, even with the page hidden: Lua sends a
       stored image + a size + a byte order, this file decodes it on a canvas
       and returns raw pixels for the runtime-texture engine.

   Strings: T(key, fallback) over the locale table Lua ships in `open`.
   The English in the markup is the fallback, so nothing ever renders blank.
   ═══════════════════════════════════════════════════════════════════════════ */

(() => {
'use strict';

/* ── Tiny helpers ────────────────────────────────────────────────────────── */

const $  = (s, r) => (r || document).querySelector(s);
const $$ = (s, r) => Array.from((r || document).querySelectorAll(s));

const RES = (typeof GetParentResourceName === 'function') ? GetParentResourceName() : 'apex_blips';

function post(name, data) {
  return fetch(`https://${RES}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data || {}),
  }).then(r => r.json()).catch(() => ({}));
}

const clamp = (v, lo, hi) => Math.min(hi, Math.max(lo, v));

function esc(s) { return String(s == null ? '' : s); }   // we only ever assign textContent

/* ── State ───────────────────────────────────────────────────────────────── */

const S = {
  open: false,
  locale: {},
  blips: [],
  images: {},                 // id -> record
  defaults: { sprite: 1, colour: 0, scale: 0.9, alpha: 255, shortRange: true, category: 1, display: 2, zoneColour: 1, zoneAlpha: 80 },
  zones: { maxRadius: 2000, maxSide: 4000 },
  imgcfg: { size: 128, maxKB: 192, maxCount: 96 },
  slots: { used: 0, total: 0, hijacked: [] },
  myPos: { x: 0, y: 0, z: 30 },

  tab: 'blips',
  search: '',
  selectedId: null,
  editing: null,              // working copy while the editor is open
  dirty: false,
  pendingImageSelect: false,  // an upload/bake wants to select the next saved image
  /* The REAL ceilings, sent by the server in open (Config.limits). The
     fallbacks are only for a page opened before that message lands; they are
     deliberately the old slider ends, so an un-booted page can never offer
     more than the smallest server would take. */
  limits: { scaleMin: 0.2, scaleMax: 2, alphaMin: 20, alphaMax: 255, zoneAlphaMin: 10, zoneAlphaMax: 200 },
  badgeFa: false,             // badge glyph comes from Font Awesome, not text/emoji
};

function T(key, fallback) {
  const v = S.locale[key];
  return (typeof v === 'string' && v !== '') ? v : (fallback || key);
}
function TF(key, fallback, ...args) {
  // %s / %d substitution, in order.
  let out = T(key, fallback);
  for (const a of args) out = out.replace(/%[sd]/, String(a));
  return out;
}

/* ── GTA blip colour palette (curated; the id is what matters — the hex is
      a faithful approximation for the swatch) ─────────────────────────────── */

const GTA_COLOURS = [
  [0,  '#F1F1F1'], [1,  '#E03232'], [2,  '#71CB71'], [3,  '#5DB6E5'],
  [5,  '#EEC64E'], [7,  '#A26BC9'], [8,  '#DE5AA8'], [17, '#E8863C'],
  [18, '#63B7D8'], [21, '#A0793F'], [25, '#8AA645'], [27, '#B15FD9'],
  [29, '#4763B8'], [33, '#E9DC5B'], [38, '#3B6BD6'], [46, '#EBC85C'],
  [49, '#C74642'], [52, '#699C52'], [59, '#D33131'], [84, '#5A8AD6'],
];
function colourHex(id) {
  const hit = GTA_COLOURS.find(c => c[0] === Number(id));
  return hit ? hit[1] : '#F1F1F1';
}

/* ── Emoji & icon data for the badge maker ──────────────────────────────────
   Emojis are generated from the Unicode blocks (the COMPLETE set the client
   font can draw; unsupported codepoints are filtered out with a canvas
   render test against a known-unassigned reference glyph). Font Awesome
   icons come from js/fadata.js (window.APEX_FA, the full free-solid set,
   generated from the official metadata) with the font self-hosted in
   html/fonts/. */

const EMOJI_BLOCKS = [
  ['em_smileys',   'Smileys',         0x1F600, 0x1F64F],
  ['em_picto',     'Pictographs',     0x1F300, 0x1F5FF],
  ['em_transport', 'Transport & map', 0x1F680, 0x1F6FF],
  ['em_extra',     'More symbols',    0x1F900, 0x1F9FF],
  ['em_extra2',    'Even more',       0x1FA70, 0x1FAFF],
  ['em_symbols',   'Classic symbols', 0x2600,  0x26FF],
  ['em_dingbats',  'Dingbats',        0x2700,  0x27BF],
];
const TEXT_ICONS = ['★', '✦', '✚', '✖', '➤', '⚑', '♥', '♦', '♣', '♠', '♛', '♜', '♞', '☯', '☢', '☣', '⚕', '⚖', '⚔', '§', '†', '‡', 'Ω', 'µ'];

/* True when the client font actually draws this glyph (not a tofu box). */
const glyphSupported = (() => {
  const cv = document.createElement('canvas');
  cv.width = cv.height = 24;
  const ctx = cv.getContext('2d', { willReadFrequently: true });
  let tofu = null;
  const sig = ch => {
    ctx.clearRect(0, 0, 24, 24);
    ctx.font = '18px "Segoe UI Emoji","Segoe UI Symbol","Segoe UI",sans-serif';
    ctx.textBaseline = 'top';
    ctx.fillText(ch, 0, 0);
    const d = ctx.getImageData(0, 0, 24, 24).data;
    let s = 0;
    for (let i = 3; i < d.length; i += 8) { if (d[i] > 10) s = (s * 33 + i) >>> 0; }
    return s;
  };
  return ch => {
    if (tofu === null) tofu = sig('͸');       // permanently unassigned
    const v = sig(ch);
    return v !== 0 && v !== tofu;
  };
})();

/* ── Sprite catalogue (blipdata.js → window.APEX_BLIPS = [[id,name,file],…]) ─ */

let CAT = null, CAT_BY_ID = null;
function catalogue() {
  if (CAT) return CAT;
  CAT = Array.isArray(window.APEX_BLIPS) ? window.APEX_BLIPS : [];
  CAT_BY_ID = new Map(CAT.map(e => [e[0], e]));
  return CAT;
}
function spriteEntry(id) { catalogue(); return CAT_BY_ID.get(Number(id)) || null; }
function spriteImgSrc(id) {
  const e = spriteEntry(id);
  return e ? ('blips/' + e[2]) : 'blips/radar_level.png';
}
function spriteName(id) {
  const e = spriteEntry(id);
  return e ? e[1] : ('sprite ' + id);
}

/* ── Toasts ──────────────────────────────────────────────────────────────── */

/** @param sticky true keeps the toast on screen until toastClose(); a batch
 *         upload uses one sticky toast as its progress line instead of
 *         stacking one toast per picture.
 *  @return the toast element, so it can be updated in place */
function toast(kind, text, sticky) {
  const host = $('#toasts');
  const el = document.createElement('div');
  el.className = 'toast ' + (kind || 'info');
  const icon = kind === 'ok' ? 'i-check' : kind === 'err' ? 'i-warn' : 'i-info';
  el.innerHTML = `<svg class="ic"><use href="#${icon}"/></svg><span></span>`;
  el.querySelector('span').textContent = text;
  host.appendChild(el);
  if (!sticky) setTimeout(() => toastClose(el), 2600);
  return el;
}

function toastSet(el, kind, text) {
  if (!el || !el.isConnected) return;
  el.className = 'toast ' + (kind || 'info');
  const icon = kind === 'ok' ? 'i-check' : kind === 'err' ? 'i-warn' : 'i-info';
  el.querySelector('use').setAttribute('href', '#' + icon);
  el.querySelector('span').textContent = text;
}

function toastClose(el, delay) {
  if (!el || !el.isConnected) return;
  const go = () => { el.classList.add('out'); setTimeout(() => el.remove(), 220); };
  if (delay) setTimeout(go, delay); else go();
}

/* ── Modals ──────────────────────────────────────────────────────────────── */

function closeModal() {
  const root = $('#modal-root');
  root.innerHTML = '';
  delete root.dataset.enterOk;
  root._onEnter = null;
}

function confirmModal(title, message, okLabel, onOk) {
  const root = $('#modal-root');
  root.innerHTML = `
    <div class="modal">
      <div class="modal-head"><h3></h3></div>
      <div class="modal-body"><p></p></div>
      <div class="modal-actions">
        <button class="btn btn-secondary" data-act="cancel"><span></span>&nbsp;<span class="keycap">ESC</span></button>
        <button class="btn btn-danger" data-act="ok"><span></span>&nbsp;<span class="keycap">ENTER</span></button>
      </div>
    </div>`;
  $('.modal-head h3', root).textContent = title;
  $('.modal-body p', root).textContent = message;
  $('[data-act="cancel"] span', root).textContent = T('modal_cancel', 'Cancel');
  $('[data-act="ok"] span', root).textContent = okLabel;
  $('[data-act="cancel"]', root).onclick = closeModal;
  $('[data-act="ok"]', root).onclick = () => { closeModal(); onOk(); };
  root.dataset.enterOk = '1';
  root._onEnter = () => { closeModal(); onOk(); };
}

/* ── i18n over static markup ─────────────────────────────────────────────── */

function applyI18n() {
  $$('[data-i18n]').forEach(el => { el.textContent = T(el.dataset.i18n, el.textContent); });
  $$('[data-i18n-ph]').forEach(el => { el.placeholder = T(el.dataset.i18nPh, el.placeholder); });
  $$('[data-i18n-title]').forEach(el => { el.title = T(el.dataset.i18nTitle, el.title); });
  $$('[data-i18n-tip]').forEach(el => { el.dataset.tip = T(el.dataset.i18nTip, el.dataset.tip || ''); });
}

/* ── Tooltips ────────────────────────────────────────────────────────────────
   Every icon-only control carries data-tip (and optionally data-tip-pos:
   'right' | 'left' | default below). One fixed element, delegated events,
   260ms delay; position: fixed so scroll containers and the rail edge can
   never clip it. */

function initTooltips() {
  const tip = document.createElement('div');
  tip.id = 'tooltip';
  tip.hidden = true;
  document.body.appendChild(tip);

  let timer = null;
  let current = null;

  const hide = () => {
    if (timer) { clearTimeout(timer); timer = null; }
    current = null;
    tip.hidden = true;
  };

  document.addEventListener('mouseover', ev => {
    const t = ev.target.closest('[data-tip]');
    if (!t || t === current) return;
    if (timer) clearTimeout(timer);
    current = t;
    timer = setTimeout(() => {
      if (!document.body.contains(t) || current !== t || !t.dataset.tip) return;
      tip.textContent = t.dataset.tip;
      tip.hidden = false;
      const r = t.getBoundingClientRect();
      const tr = tip.getBoundingClientRect();
      const pos = t.dataset.tipPos || 'down';
      let x, y;
      if (pos === 'right')      { x = r.right + 8; y = r.top + (r.height - tr.height) / 2; }
      else if (pos === 'left')  { x = r.left - tr.width - 8; y = r.top + (r.height - tr.height) / 2; }
      else                      { x = r.left + (r.width - tr.width) / 2; y = r.bottom + 7; }
      tip.style.left = clamp(x, 6, window.innerWidth - tr.width - 6) + 'px';
      tip.style.top = clamp(y, 6, window.innerHeight - tr.height - 6) + 'px';
    }, 260);
  });
  document.addEventListener('mouseout', ev => {
    const t = ev.target.closest('[data-tip]');
    if (t && t === current) hide();
  });
  document.addEventListener('mousedown', hide, true);
  document.addEventListener('scroll', hide, true);
}

/* ══════════════════════════════════════════════════════════════════════════
   IMAGE HELPERS (uploads + badges; the in-game texture work happens in a DUI,
   not in this page)
   ══════════════════════════════════════════════════════════════════════════ */

function loadImage(src) {
  return new Promise((resolve, reject) => {
    const img = new Image();
    img.onload = () => resolve(img);
    img.onerror = () => reject(new Error('image failed to load'));
    img.src = src;
  });
}

function drawCover(ctx, img, size) {
  // Cover-fit: fill the square, crop the overflow, keep the centre.
  const s = Math.max(size / img.width, size / img.height);
  const w = img.width * s, h = img.height * s;
  ctx.clearRect(0, 0, size, size);
  ctx.imageSmoothingEnabled = true;
  ctx.imageSmoothingQuality = 'high';
  ctx.drawImage(img, (size - w) / 2, (size - h) / 2, w, h);
}

/* ══════════════════════════════════════════════════════════════════════════
   EDITOR MODEL
   ══════════════════════════════════════════════════════════════════════════ */

function newDef() {
  const d = S.defaults;
  return {
    id: null,
    name: '',
    iconMode: 'sprite',
    sprite: d.sprite || 1,
    image: null,
    shape: 'none',
    colour: d.colour || 0,
    scale: d.scale || 0.9,
    alpha: d.alpha || 255,
    pos: { x: S.myPos.x, y: S.myPos.y, z: S.myPos.z },
    shortRange: d.shortRange !== false,
    flash: false,
    route: false,
    routeColour: 0,
    category: d.category || 1,
    display: d.display || 2,
    zone: { mode: 'none', radius: 50, w: 100, h: 100, rot: 0, colour: d.zoneColour || 1, alpha: d.zoneAlpha || 80, events: false },
    vis: { mode: 'everyone', jobs: [] },
    enabled: true,
  };
}

function defFromStored(b) {
  const e = newDef();
  e.id = b.id;
  e.name = b.name || '';
  const ic = b.icon || {};
  e.iconMode = ic.mode === 'image' ? 'image' : 'sprite';
  e.sprite = ic.sprite || 1;
  e.image = ic.image || null;
  e.shape = ic.shape === 'rounded' || ic.shape === 'circle' ? ic.shape : 'none';
  e.colour = b.colour || 0;
  e.scale = b.scale || 0.9;
  e.alpha = b.alpha != null ? b.alpha : 255;
  e.pos = { x: b.pos.x, y: b.pos.y, z: b.pos.z };
  e.shortRange = b.shortRange === true;
  e.flash = b.flash === true;
  e.route = b.route === true;
  e.routeColour = b.routeColour || 0;
  e.category = b.category || 1;
  e.display = b.display || 2;
  const z = b.zone || {};
  e.zone = {
    mode: z.mode || 'none',
    radius: z.radius || 50, w: z.w || 100, h: z.h || 100, rot: z.rot || 0,
    colour: z.colour != null ? z.colour : 1, alpha: z.alpha != null ? z.alpha : 80,
    events: z.events === true,
  };
  const v = b.vis || {};
  e.vis = { mode: v.mode || 'everyone', jobs: Array.isArray(v.jobs) ? v.jobs.slice() : [] };
  e.enabled = b.enabled !== false;
  return e;
}

function defToServer(e) {
  return {
    id: e.id || undefined,
    name: e.name,
    icon: e.iconMode === 'image'
      ? { mode: 'image', image: e.image, shape: e.shape !== 'none' ? e.shape : undefined }
      : { mode: 'sprite', sprite: e.sprite },
    pos: e.pos,
    colour: e.colour, scale: e.scale, alpha: e.alpha,
    shortRange: e.shortRange, flash: e.flash, route: e.route, routeColour: e.routeColour,
    category: e.category, display: e.display,
    zone: e.zone, vis: e.vis, enabled: e.enabled,
  };
}

/* The rail Save tile mirrors the editor state: enabled while a blip is open,
   with the minimap-style yellow dot while there are unsaved changes. */
function syncRailSave() {
  const btn = $('#rail-save');
  if (!btn) return;
  btn.classList.toggle('is-disabled', !S.editing);
  const dot = $('#rail-dirty');
  if (dot) dot.hidden = !(S.editing && S.dirty);
}

function markDirty() {
  if (!S.dirty) { S.dirty = true; $('#hd-dirty').hidden = false; }
  syncRailSave();
}
function clearDirty() {
  S.dirty = false;
  $('#hd-dirty').hidden = true;
  syncRailSave();
}

/* ══════════════════════════════════════════════════════════════════════════
   TABS
   ══════════════════════════════════════════════════════════════════════════ */

const TAB_ORDER = ['blips', 'editor', 'images', 'dev'];

function setTab(tab) {
  S.tab = tab;
  $$('.rail-tab').forEach(b => b.classList.toggle('is-active', b.dataset.tab === tab));
  $$('.pane').forEach(p => p.classList.toggle('is-active', p.id === 'pane-' + tab));
  if (tab === 'editor') {
    renderEditor();
    // The map measures itself against a pane that was display:none a moment
    // ago — re-measure once the layout has settled.
    setTimeout(() => { if (MAP.map) { try { MAP.map.invalidateSize(); } catch (_) {} } }, 120);
  }
  if (tab === 'images') { renderImages(); }
  if (tab === 'dev')    { renderDev(); }
}

/* ══════════════════════════════════════════════════════════════════════════
   BLIP LIST
   ══════════════════════════════════════════════════════════════════════════ */

function shapeClass(shape) {
  if (shape === 'rounded') return 'shape-rounded';
  if (shape === 'circle') return 'shape-circle';
  return '';
}

function iconThumbInto(host, iconMode, sprite, imageId, shape) {
  host.innerHTML = '';
  const img = document.createElement('img');
  img.alt = '';
  if (iconMode === 'image' && imageId && S.images[imageId]) {
    img.src = S.images[imageId].data;
    const cls = shapeClass(shape);
    if (cls) img.className = cls;
  } else {
    img.src = spriteImgSrc(sprite);
    img.onerror = () => { img.onerror = null; img.src = 'blips/radar_level.png'; };
  }
  host.appendChild(img);
}

function renderList() {
  const list = $('#bl-list');
  list.innerHTML = '';
  const q = S.search.trim().toLowerCase();
  const rows = S.blips.filter(b => !q || (b.name || '').toLowerCase().includes(q));

  $('#bl-empty').hidden = !(S.blips.length === 0);
  if (S.blips.length && rows.length === 0) {
    const note = document.createElement('p');
    note.className = 'hint';
    note.style.padding = '18px 4px';
    note.textContent = T('list_none_match', 'Nothing matches that search.');
    list.appendChild(note);
  }

  rows.forEach((b, i) => {
    const row = document.createElement('div');
    row.className = 'rowb' + (b.enabled === false ? ' is-off' : '') + (S.selectedId === b.id ? ' is-selected' : '');
    row.style.animationDelay = Math.min(i * 20, 220) + 'ms';

    const thumb = document.createElement('span');
    thumb.className = 'thumb';
    const ic = b.icon || {};
    iconThumbInto(thumb, ic.mode, ic.sprite, ic.image, ic.shape);
    row.appendChild(thumb);

    const txt = document.createElement('div');
    txt.className = 'rowb-txt';
    const name = document.createElement('span');
    name.className = 'rowb-name';
    name.textContent = b.name || '';
    const sub = document.createElement('div');
    sub.className = 'rowb-sub';
    const coords = document.createElement('span');
    coords.className = 'rowb-coords mono';
    coords.textContent = `${(b.pos.x).toFixed(1)} · ${(b.pos.y).toFixed(1)}`;
    sub.appendChild(coords);

    const addChip = (cls, label) => {
      const c = document.createElement('span');
      c.className = 'chip-xs ' + cls;
      c.textContent = label;
      sub.appendChild(c);
    };
    if (ic.mode === 'image') addChip('c-img', S.images[ic.image] && S.images[ic.image].badge ? T('chip_badge', 'badge') : T('chip_image', 'image'));
    if (b.zone && b.zone.mode && b.zone.mode !== 'none') addChip('c-zone', T('chip_zone', 'zone'));
    if (b.vis && b.vis.mode === 'jobs') addChip('c-jobs', T('chip_jobs', 'jobs'));
    if (b.vis && b.vis.mode === 'private') addChip('c-priv', T('chip_private', 'private'));
    if (b.enabled === false) addChip('c-off', T('chip_off', 'off'));

    txt.appendChild(name);
    txt.appendChild(sub);
    row.appendChild(txt);

    const actions = document.createElement('div');
    actions.className = 'rowb-actions';
    const mkBtn = (icon, tipText, danger, fn) => {
      const btn = document.createElement('button');
      btn.className = 'icon-btn' + (danger ? ' danger' : '');
      btn.dataset.tip = tipText;
      btn.innerHTML = `<svg class="ic"><use href="#${icon}"/></svg>`;
      btn.onclick = ev => { ev.stopPropagation(); fn(); };
      actions.appendChild(btn);
    };
    mkBtn('i-edit', T('act_edit', 'Edit'), false, () => { openEditor(defFromStored(b)); });
    mkBtn('i-target', T('act_locate', 'Set waypoint to this blip'), false, () => { post('locate', { x: b.pos.x, y: b.pos.y }); });
    mkBtn('i-dup', T('act_dup', 'Duplicate'), false, () => {
      const copy = defFromStored(b);
      copy.id = null;
      copy.name = (copy.name || 'Blip') + ' 2';
      openEditor(copy);
    });
    mkBtn(b.enabled === false ? 'i-eye' : 'i-eye-off',
          b.enabled === false ? T('act_on', 'Enable') : T('act_off', 'Disable'), false, () => {
      post('save', { def: { id: b.id, enabled: b.enabled === false } });
    });
    mkBtn('i-trash', T('act_del', 'Delete'), true, () => {
      confirmModal(T('modal_del_t', 'Delete this blip?'), T('modal_del_d', 'This removes it for every player. There is no undo.'),
        T('modal_ok', 'Delete'), () => post('delete', { id: b.id }));
    });
    row.appendChild(actions);

    row.onclick = () => {
      S.selectedId = b.id;
      renderList();
      if (S.tab === 'dev') renderDev();
      // fly the big map to this blip
      if (MAP.map) {
        try { MAP.map.setView([b.pos.y, b.pos.x], Math.max(MAP.map.getZoom() || 4, 4)); } catch (_) {}
      }
    };
    list.appendChild(row);
  });

  $('#hd-count').textContent = String(S.blips.length);
}

/* ══════════════════════════════════════════════════════════════════════════
   EDITOR
   ══════════════════════════════════════════════════════════════════════════ */

function openEditor(def) {
  S.editing = def;
  clearDirty();
  setTab('editor');
  renderMapMarkers();          // the edited blip leaves the static layer
}

function closeEditor() {
  S.editing = null;
  clearDirty();
  clearEditLayers();
  renderMapMarkers();
  setTab('blips');
}

function buildSwatches(hostSel, valueGetter, valueSetter) {
  const host = $(hostSel);
  host.innerHTML = '';
  GTA_COLOURS.forEach(([id, hex]) => {
    const sw = document.createElement('button');
    sw.className = 'sw';
    sw.style.background = hex;
    sw.dataset.id = String(id);
    sw.title = String(id);
    sw.onclick = () => { valueSetter(id); syncSwatches(hostSel, valueGetter()); markDirty(); refreshPreview(); };
    host.appendChild(sw);
  });
}
function syncSwatches(hostSel, value) {
  $$(hostSel + ' .sw').forEach(sw => sw.classList.toggle('is-active', Number(sw.dataset.id) === Number(value)));
}

function segValue(hostSel) {
  const a = $(hostSel + ' .seg-btn.is-active');
  return a ? a.dataset.v : null;
}
function segSet(hostSel, value) {
  $$(hostSel + ' .seg-btn').forEach(b => b.classList.toggle('is-active', String(b.dataset.v) === String(value)));
}
function segBind(hostSel, fn) {
  $$(hostSel + ' .seg-btn').forEach(b => {
    b.addEventListener('click', () => { segSet(hostSel, b.dataset.v); fn(b.dataset.v); });
  });
}

/* ── Editor render (model → fields) ─────────────────────────────────────── */

function renderEditor() {
  // No implicit blip: opening the Editor tab with nothing selected shows the
  // empty state instead of inventing a default marker at the player's feet.
  const empty = $('#ed-empty');
  const form = $('#ed-form');
  if (!S.editing) {
    if (empty) empty.hidden = false;
    if (form) form.hidden = true;
    const legend = $('#stage-legend');
    if (legend) legend.hidden = true;
    syncRailSave();
    return;
  }
  if (empty) empty.hidden = true;
  if (form) form.hidden = false;
  syncRailSave();
  const e = S.editing;

  $('#ed-title').textContent = e.id ? T('ed_edit_t', 'Editing') : T('ed_new_t', 'New blip');
  $('#ed-id').hidden = !e.id;
  $('#ed-id').textContent = e.id || '';
  $('#ed-delete').hidden = !e.id;
  $('#ed-save-label').textContent = e.id ? T('btn_save', 'Save blip') : T('btn_create', 'Create blip');

  segSet('#ic-mode', e.iconMode);
  segSet('#ic-shape', e.shape || 'none');
  syncIconPanels();

  // sprite panel
  $('#ic-sprite-thumb img').src = spriteImgSrc(e.sprite);
  $('#ic-sprite-name').textContent = spriteName(e.sprite);
  $('#ic-sprite-id').textContent = '#' + e.sprite;

  renderLibStrip();

  $('#f-name').value = e.name;
  syncSwatches('#f-colour', e.colour);
  $('#f-colour-val').textContent = String(e.colour);
  $('#f-scale').value = e.scale; $('#f-scale-val').value = Number(e.scale).toFixed(2);
  $('#f-alpha').value = e.alpha; $('#f-alpha-val').value = String(e.alpha);

  $('#f-x').value = e.pos.x.toFixed(1);
  $('#f-y').value = e.pos.y.toFixed(1);
  $('#f-z').value = e.pos.z.toFixed(1);

  $('#f-shortrange').checked = e.shortRange;
  $('#f-flash').checked = e.flash;
  $('#f-route').checked = e.route;
  $('#f-routecolour-field').hidden = !e.route;
  syncSwatches('#f-routecolour', e.routeColour);
  $('#f-routecolour-val').textContent = String(e.routeColour);
  segSet('#f-category', e.category);
  segSet('#f-display', e.display);

  segSet('#z-mode', e.zone.mode);
  syncZoneBody();
  $('#z-radius').value = e.zone.radius; $('#z-radius-val').value = String(e.zone.radius);
  $('#z-w').value = e.zone.w; $('#z-w-val').value = String(e.zone.w);
  $('#z-h').value = e.zone.h; $('#z-h-val').value = String(e.zone.h);
  $('#z-rot').value = e.zone.rot; $('#z-rot-val').value = String(e.zone.rot);
  syncSwatches('#z-colour', e.zone.colour);
  $('#z-colour-val').textContent = String(e.zone.colour);
  $('#z-alpha').value = e.zone.alpha; $('#z-alpha-val').value = String(e.zone.alpha);
  $('#z-events').checked = e.zone.events;

  segSet('#v-mode', e.vis.mode);
  syncVisBody();
  renderJobChips();

  if (e.iconMode === 'badge') refreshBadgePreview();
  refreshPreview(true);
}

function syncIconPanels() {
  const m = S.editing.iconMode;
  $('#icp-sprite').hidden = m !== 'sprite';
  $('#icp-image').hidden = m !== 'image';
  $('#icp-badge').hidden = m !== 'badge';
}

function syncZoneBody() {
  const m = S.editing.zone.mode;
  $('#z-body').hidden = m === 'none';
  $('#z-radius-row').hidden = m !== 'radius';
  $('#z-area-row').hidden = m !== 'area';
}

function syncVisBody() {
  const m = S.editing.vis.mode;
  $('#v-jobs-body').hidden = m !== 'jobs';
  $('#v-private-hint').hidden = m !== 'private';
}

function renderJobChips() {
  const host = $('#v-jobs-chips');
  host.innerHTML = '';
  S.editing.vis.jobs.forEach(j => {
    const chip = document.createElement('span');
    chip.className = 'jobchip';
    const label = document.createElement('span');
    label.textContent = j;
    const btn = document.createElement('button');
    btn.innerHTML = '<svg class="ic"><use href="#i-close"/></svg>';
    btn.onclick = () => {
      S.editing.vis.jobs = S.editing.vis.jobs.filter(x => x !== j);
      renderJobChips(); markDirty();
    };
    chip.appendChild(label); chip.appendChild(btn);
    host.appendChild(chip);
  });
}

function renderLibStrip() {
  const host = $('#ic-lib');
  host.innerHTML = '';
  const ids = Object.keys(S.images);
  if (ids.length === 0) {
    const note = document.createElement('span');
    note.className = 'lib-empty-note';
    note.textContent = T('img_empty_d', 'Upload a logo or bake a badge in the editor. Saved icons appear here.');
    host.appendChild(note);
    return;
  }
  ids.forEach(id => {
    const rec = S.images[id];
    const tile = document.createElement('button');
    tile.className = 'lib-tile' + (S.editing && S.editing.image === id ? ' is-active' : '');
    tile.dataset.tip = rec.name || id;
    const img = document.createElement('img');
    img.src = rec.data;
    const dot = document.createElement('span');
    dot.className = 'sel-dot';
    dot.innerHTML = '<svg class="ic"><use href="#i-check"/></svg>';
    tile.appendChild(img); tile.appendChild(dot);
    tile.onclick = () => {
      S.editing.image = id;
      S.editing.iconMode = 'image';
      renderLibStrip(); markDirty(); refreshPreview();
    };
    host.appendChild(tile);
  });
}

/* ── Badge generator ─────────────────────────────────────────────────────── */

function renderBadge(cv, size, opts) {
  cv.width = cv.height = size;
  const ctx = cv.getContext('2d');
  ctx.clearRect(0, 0, size, size);

  const noDisc = opts.shape === 'none';
  if (!noDisc) {
    const pad = size * 0.04;
    const r = (size - pad * 2) / 2;
    ctx.fillStyle = opts.bg;
    ctx.beginPath();
    if (opts.shape === 'circle') {
      ctx.arc(size / 2, size / 2, r, 0, Math.PI * 2);
    } else if (opts.shape === 'rounded') {
      const rr = size * 0.22;
      roundRect(ctx, pad, pad, size - pad * 2, size - pad * 2, rr);
    } else {
      ctx.rect(pad, pad, size - pad * 2, size - pad * 2);
    }
    ctx.fill();
    // inner light, so the disc reads as material even at 20px
    ctx.strokeStyle = 'rgba(255,255,255,.25)';
    ctx.lineWidth = Math.max(1, size * 0.015);
    ctx.stroke();
  }

  const text = (opts.text || '').trim();
  if (text) {
    const parts = Array.from(text).slice(0, 3);
    const chars = parts.join('');
    ctx.fillStyle = opts.fg;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    // no disc = no frame, so the glyph fills the whole texture
    const base = noDisc
      ? (parts.length === 1 ? 0.84 : parts.length === 2 ? 0.58 : 0.44)
      : (parts.length === 1 ? 0.58 : parts.length === 2 ? 0.42 : 0.32);
    const faPx = noDisc ? 0.78 : 0.52;
    ctx.font = opts.fa
      ? `900 ${Math.round(size * faPx)}px "Font Awesome 6 Free"`
      : `700 ${Math.round(size * base)}px "Inter","Segoe UI Emoji","Segoe UI",sans-serif`;
    ctx.fillText(chars, size / 2, size / 2 + size * 0.02);
  }
}

function roundRect(ctx, x, y, w, h, r) {
  ctx.moveTo(x + r, y);
  ctx.arcTo(x + w, y, x + w, y + h, r);
  ctx.arcTo(x + w, y + h, x, y + h, r);
  ctx.arcTo(x, y + h, x, y, r);
  ctx.arcTo(x, y, x + w, y, r);
  ctx.closePath();
}

function badgeOpts() {
  return {
    text: $('#bd-text').value,
    bg: $('#bd-bg').value,
    fg: $('#bd-fg').value,
    shape: segValue('#bd-shape') || 'circle',
    fa: S.badgeFa === true,
  };
}

function refreshBadgePreview() {
  renderBadge($('#bd-canvas'), 64, badgeOpts());
  refreshPreview();
}

/* ── Uploads ─────────────────────────────────────────────────────────────── */

/*  ⚠⚠ ONE UPLOAD ON THE WIRE AT A TIME, A QUEUE BEHIND IT, AND IT ALWAYS ENDS.

    A save is a round trip: the picture goes to the server as a latent event and
    the answer comes back as `imageSaved`. Nothing used to mark that window, so
    a second upload could be posted on top of the first, the server's flood
    guard dropped it in silence, and the person was left looking at a studio
    that had stopped responding. That is the report ("to upload several images
    I have to log out and back in"), together with the bandwidth problem fixed
    in server/main.lua.

    "One at a time" is correct on the WIRE and wrong at the button: a person
    with twenty icons to add should pick twenty files and walk away. So the file
    inputs take a multiple selection, the pictures wait in `uploadQ`, and the
    queue posts them one by one, each only after the previous one was answered.

    ⚠ The server's flood guard is `rated(src, 400)` and `rated` shares ONE
    timestamp per source across every write event, so two uploads posted less
    than 400 ms apart means the second is refused with 'busy'. The queue paces
    itself above that, and a 'busy' answer puts the picture back at the head of
    the queue instead of losing it.

    A watchdog still releases everything if an answer never arrives, because a
    button stuck disabled is the same bug wearing a different hat. */
const UPLOAD_GAP_MS = 500;        // > the server's 400 ms guard, with headroom

let uploadBusy = false;
let uploadWatchdog = 0;
let uploadQ = [];                 // [{ file, replaceId, retried }]
let uploadInFlight = null;        // the one the server has not answered yet
let uploadLastPost = 0;
let uploadPumpTimer = 0;
let batch = null;                 // { total, done, failed, toast } while a run is live

function uploadStart() {
  uploadBusy = true;
  uploadLastPost = Date.now();
  clearTimeout(uploadWatchdog);
  uploadWatchdog = setTimeout(() => {
    if (!uploadBusy) return;
    uploadBusy = false;
    uploadInFlight = null;
    // Whatever is still queued cannot be trusted to a channel that just went
    // quiet: drop it and say so once, rather than timing out twenty times.
    uploadQ = [];
    batchEnd(T('t_img_timeout', 'The server did not answer. The image was not saved.'), 'err');
    uploadIdle();
  }, 15000);
  $$('.js-upload').forEach(b => { b.disabled = true; b.classList.add('is-busy'); });
}

function uploadIdle() {
  clearTimeout(uploadWatchdog);
  $$('.js-upload').forEach(b => { b.disabled = false; b.classList.remove('is-busy'); });
}

/** Called when an answer lands: the wire is free, so look at the queue. */
function uploadDone() {
  uploadBusy = false;
  clearTimeout(uploadWatchdog);
  if (uploadQ.length === 0) { uploadIdle(); return; }
  pumpUpload();
}

function pumpUpload() {
  if (uploadBusy || uploadQ.length === 0) return;
  clearTimeout(uploadPumpTimer);
  const wait = Math.max(0, UPLOAD_GAP_MS - (Date.now() - uploadLastPost));
  if (wait > 0) { uploadPumpTimer = setTimeout(pumpUpload, wait); return; }
  const item = uploadQ.shift();
  sendUpload(item);
}

/** @param files FileList|File[]
 *  @param replaceId string|undefined  an existing image id to overwrite in
 *         place, so every blip already pointing at it changes picture at once.
 *         A replace is always a single file, whatever was selected. */
function enqueueUploads(files, replaceId) {
  const list = Array.prototype.slice.call(files || []);
  if (list.length === 0) return;

  const imgs = list.filter(f => f && /^image\//.test(f.type));
  const rejected = list.length - imgs.length;
  if (rejected > 0) toast('err', T('t_img_type', 'That file is not an image.'));
  if (imgs.length === 0) return;

  const take = replaceId ? imgs.slice(0, 1) : imgs;

  // Room left in the library, checked here so twenty files do not become twenty
  // refusals from the server. The server is still the authority.
  if (!replaceId) {
    const max = S.imgcfg.maxCount || 96;
    const have = Object.keys(S.images || {}).length + uploadQ.length + (uploadBusy ? 1 : 0);
    const room = Math.max(0, max - have);
    if (room === 0) { toast('err', TF('t_img_limit', 'The library is full (max %d).', max)); return; }
    if (take.length > room) {
      toast('err', TF('t_img_room', 'Only %d more fit in the library. The rest were skipped.', room));
      take.length = room;
    }
  }

  for (const f of take) uploadQ.push({ file: f, replaceId: replaceId });

  if (!batch) batch = { total: 0, done: 0, failed: 0, toast: null };
  batch.total += take.length;
  batchProgress();
  pumpUpload();
}

function batchProgress() {
  if (!batch || batch.total <= 1) return;   // a single picture speaks for itself
  const n = batch.done + batch.failed;
  const text = TF('t_img_progress', 'Uploading pictures… %s', (n + 1) + '/' + batch.total);
  if (!batch.toast) batch.toast = toast('info', text, true);
  else toastSet(batch.toast, 'info', text);
}

/** Closes the run: one summary line instead of one toast per picture. */
function batchEnd(forcedText, forcedKind) {
  if (!batch) {
    if (forcedText) toast(forcedKind || 'err', forcedText);
    return;
  }
  const b = batch;
  batch = null;
  if (b.total <= 1) {
    toastClose(b.toast);
    if (forcedText) toast(forcedKind || 'err', forcedText);
    return;                                  // the single-picture toast already fired
  }
  const text = forcedText ? forcedText
    : b.failed === 0 ? TF('t_img_batch_ok', '%d pictures saved.', b.done)
    : TF('t_img_batch_part', '%d of %d pictures saved.', b.done, b.total);
  const kind = forcedText ? (forcedKind || 'err') : (b.failed === 0 ? 'ok' : 'err');
  if (b.toast) { toastSet(b.toast, kind, text); toastClose(b.toast, 2600); }
  else toast(kind, text);
}

/** One picture: downsize, encode, post. Anything that goes wrong here has to
 *  release the wire itself, or the queue stops on a file the server never saw. */
function sendUpload(item) {
  const file = item.file, replaceId = item.replaceId;
  // Kept so a 'busy' answer can put this exact picture back in the queue.
  uploadInFlight = item;

  const fail = text => {
    toast('err', text);
    if (batch) batch.failed += 1;
    uploadInFlight = null;
    uploadBusy = false;
    if (uploadQ.length > 0) { batchProgress(); pumpUpload(); }
    else { uploadIdle(); batchEnd(); }
  };

  const reader = new FileReader();
  reader.onerror = () => fail(T('t_img_type', 'That file is not an image.'));
  reader.onload = () => {
    loadImage(reader.result).then(img => {
      const size = S.imgcfg.size || 128;
      const cv = document.createElement('canvas');
      cv.width = cv.height = size;
      drawCover(cv.getContext('2d'), img, size);
      const data = cv.toDataURL('image/png');
      if (data.length > (S.imgcfg.maxKB || 192) * 1024) {
        fail(TF('t_img_big', 'Image is too heavy even after downsizing (max %d KB).', S.imgcfg.maxKB));
        return;
      }
      const payload = { data, size };
      if (replaceId && S.images[replaceId]) {
        // A replace keeps the name the library already shows: the point is the
        // picture, and silently renaming it to the file name would be a second,
        // unasked-for change.
        payload.id = replaceId;
        payload.name = S.images[replaceId].name;
      } else {
        payload.name = file.name.replace(/\.[^.]+$/, '').slice(0, 40) || 'Image';
        // Only the LAST picture of a run claims the editor's icon slot. A batch
        // of twenty should not flip the open blip's icon twenty times.
        S.pendingImageSelect = uploadQ.length === 0;
      }
      batchProgress();
      uploadStart();
      post('saveImage', payload);
    }).catch(() => fail(T('t_img_type', 'That file is not an image.')));
  };
  reader.readAsDataURL(file);
}

/* ── Preview — the REAL map ──────────────────────────────────────────────────
   Leaflet over the gtamap.xyz styleAtlas tiles with the exact world→map
   transform the apex_bossmenu tactical map runs in production. latlng is
   (lat = world Y, lng = world X), so distances are plain metres and
   L.circle(radius) is a true in-world radius. Click the map or drag the
   marker to move the blip. */

const MAP_TILE = 'https://www.gtamap.xyz/mapStyles/styleAtlas/{z}/{x}/{y}.jpg';
const MAP_CENTER_X = 117.3, MAP_CENTER_Y = 172.8, MAP_SCALE_X = 0.02072, MAP_SCALE_Y = 0.0205;
const MAP = { built: false, failed: false, map: null, marker: null, zone: null, all: null };

function ensurePrevMap() {
  if (MAP.built) return MAP.map;
  const target = $('#prev-map');
  if (!target) return null;
  if (typeof L === 'undefined') {
    // Leaflet CDN unreachable — leave a quiet placeholder, nothing else breaks.
    if (!MAP.failed) {
      MAP.failed = true;
      const d = document.createElement('div');
      d.className = 'map-fallback';
      d.textContent = T('prev_map_off', 'Map tiles unavailable (no internet).');
      target.appendChild(d);
    }
    return null;
  }
  const CRS = L.extend({}, L.CRS.Simple, {
    projection: L.Projection.LonLat,
    scale: z => Math.pow(2, z),
    zoom: s => Math.log(s) / Math.LN2,
    distance: (a, b) => {
      const dx = b.lng - a.lng, dy = b.lat - a.lat;
      return Math.sqrt(dx * dx + dy * dy);
    },
    transformation: new L.Transformation(MAP_SCALE_X, MAP_CENTER_X, -MAP_SCALE_Y, MAP_CENTER_Y),
    infinite: true,
  });
  const map = L.map(target, {
    crs: CRS, minZoom: 2, maxZoom: 5, zoom: 3, center: [-200, 0],
    zoomControl: false, preferCanvas: true, attributionControl: false,
    maxBounds: [[8000.0, -5500.0], [-8000.0, 5500.0]],
  });
  L.control.zoom({ position: 'bottomright' }).addTo(map);
  L.tileLayer(MAP_TILE, { minZoom: 2, maxZoom: 5, noWrap: true }).addTo(map);
  map.on('click', ev => {
    // The map only MOVES a blip while the editor is the active pane;
    // otherwise clicks are for panning and picking markers.
    if (S.tab !== 'editor' || !S.editing) return;
    setEditingPos(ev.latlng.lng, ev.latlng.lat, null, false);
  });
  MAP.map = map;
  MAP.built = true;
  return map;
}

/* Every stored blip lives on the big map; the one being edited is drawn by
   updateMapLayers instead (draggable, with its zone). Clicking a marker
   opens it in the editor. */
function markerHtmlFor(b) {
  const ic = b.icon || {};
  let src = null;
  if (ic.mode === 'image') {
    if (S.images[ic.image]) src = S.images[ic.image].data;
  } else {
    src = spriteImgSrc(ic.sprite);
  }
  if (!src) return '';
  const img = document.createElement('img');
  img.src = src;
  if (ic.mode === 'image') {
    const cls = shapeClass(ic.shape);
    if (cls) img.className = cls;
  }
  img.style.opacity = b.enabled === false ? '0.35' : String(clamp((b.alpha || 255) / 255, 0.15, 1));
  return img.outerHTML;
}

function renderMapMarkers() {
  const map = ensurePrevMap();
  if (!map) return;
  if (MAP.all) { MAP.all.remove(); MAP.all = null; }
  MAP.all = L.layerGroup();
  S.blips.forEach(b => {
    if (S.editing && S.editing.id && S.editing.id === b.id) return;   // edited one is the live marker
    const px = Math.round(clamp(26 * (b.scale || 1), 14, 52));
    const html = markerHtmlFor(b);
    if (!html) return;
    const mk = L.marker([b.pos.y, b.pos.x], {
      icon: L.divIcon({ className: 'blip-mk', html, iconSize: [px, px], iconAnchor: [px / 2, px / 2] }),
      title: b.name,
    });
    mk.on('click', () => {
      S.selectedId = b.id;
      openEditor(defFromStored(b));
    });
    mk.addTo(MAP.all);
  });
  MAP.all.addTo(map);
}

function clearEditLayers() {
  if (MAP.marker) { MAP.marker.remove(); MAP.marker = null; }
  if (MAP.zone) { MAP.zone.remove(); MAP.zone = null; }
  const legend = $('#stage-legend');
  if (legend) legend.hidden = true;
}

/* ── World blips overlay — every blip alive on the GTA map right now,
      whatever script created it. Icons come from the local sprite catalogue;
      GTA-tinted sprites are recoloured with a CSS mask so the colour ids
      read the same as in game. ───────────────────────────────────────────── */

function clearWorldLayer() {
  if (MAP.worldLayer) { MAP.worldLayer.remove(); MAP.worldLayer = null; }
  S.worldOn = false;
  const btn = $('#rail-world');
  if (btn) btn.classList.remove('on');
}

async function toggleWorldBlips() {
  if (S.worldOn) { clearWorldLayer(); return; }
  const map = ensurePrevMap();
  if (!map) return;

  const r = await post('worldBlips');
  if (!r || r.ok !== true || !Array.isArray(r.blips)) return;

  if (MAP.worldLayer) MAP.worldLayer.remove();
  MAP.worldLayer = L.layerGroup();
  r.blips.forEach(b => {
    const src = spriteImgSrc(b.sprite);
    let html;
    if ((b.colour || 0) > 0) {
      html = `<div class="wb-tint" style="background-color:${colourHex(b.colour)};-webkit-mask-image:url('${src}')"></div>`;
    } else {
      html = `<img src="${src}">`;
    }
    L.marker([b.y, b.x], {
      icon: L.divIcon({ className: 'blip-mk blip-world', html, iconSize: [22, 22], iconAnchor: [11, 11] }),
      title: `${spriteName(b.sprite)} · ${b.sprite}`,
      interactive: false,
    }).addTo(MAP.worldLayer);
  });
  MAP.worldLayer.addTo(map);
  S.worldOn = true;
  const btn = $('#rail-world');
  if (btn) btn.classList.add('on');
  toast('ok', TF('t_world_n', '%d game blips shown.', r.blips.length));
}

/* One source of truth for position edits (map click, marker drag, buttons). */
function setEditingPos(x, y, z, recenter) {
  if (!S.editing) return;
  S.editing.pos.x = x;
  S.editing.pos.y = y;
  if (z != null) S.editing.pos.z = z;
  $('#f-x').value = Number(x).toFixed(1);
  $('#f-y').value = Number(y).toFixed(1);
  if (z != null) $('#f-z').value = Number(z).toFixed(1);
  markDirty();
  refreshPreview(recenter === true);
}

function currentIconSrc() {
  const e = S.editing;
  if (!e) return null;
  if (e.iconMode === 'badge') {
    const cv = document.createElement('canvas');
    renderBadge(cv, 96, badgeOpts());
    return cv.toDataURL('image/png');
  }
  if (e.iconMode === 'image') {
    return (e.image && S.images[e.image]) ? S.images[e.image].data : null;
  }
  return spriteImgSrc(e.sprite);
}

function updateMapLayers(recenter) {
  const map = ensurePrevMap();
  const e = S.editing;
  if (!map || !e) return;

  const ll = [e.pos.y, e.pos.x];
  const px = Math.round(clamp(26 * (e.scale || 1), 14, 52));
  const src = currentIconSrc();
  const img = document.createElement('img');
  if (src) img.src = src;
  img.style.opacity = String(clamp((e.alpha || 255) / 255, 0.15, 1));
  if (e.iconMode === 'image') {
    const cls = shapeClass(e.shape);
    if (cls) img.className = cls;
  }
  const icon = L.divIcon({ className: 'blip-mk', html: src ? img.outerHTML : '', iconSize: [px, px], iconAnchor: [px / 2, px / 2] });

  if (!MAP.marker) {
    MAP.marker = L.marker(ll, { icon, draggable: true }).addTo(map);
    MAP.marker.on('dragend', () => {
      const p = MAP.marker.getLatLng();
      setEditingPos(p.lng, p.lat, null, false);
    });
  } else {
    MAP.marker.setLatLng(ll);
    MAP.marker.setIcon(icon);
  }

  if (MAP.zone) { MAP.zone.remove(); MAP.zone = null; }
  const z = e.zone;
  const hex = colourHex(z.colour);
  const fillOp = clamp(z.alpha / 255, 0.06, 0.7);
  if (z.mode === 'radius') {
    MAP.zone = L.circle(ll, {
      radius: z.radius, color: hex, weight: 2, opacity: 0.9,
      fillColor: hex, fillOpacity: fillOp,
    }).addTo(map);
  } else if (z.mode === 'area') {
    const a = z.rot * Math.PI / 180;
    const c = Math.cos(a), s = Math.sin(a);
    const pts = [[-z.w / 2, -z.h / 2], [z.w / 2, -z.h / 2], [z.w / 2, z.h / 2], [-z.w / 2, z.h / 2]]
      .map(([dx, dy]) => [e.pos.y + (dx * s + dy * c), e.pos.x + (dx * c - dy * s)]);
    MAP.zone = L.polygon(pts, {
      color: hex, weight: 2, opacity: 0.9, fillColor: hex, fillOpacity: fillOp,
    }).addTo(map);
  }

  if (recenter) map.setView(ll, Math.max(map.getZoom() || 4, 4));
}

function refreshPreview(recenter) {
  const e = S.editing;
  const legend = $('#stage-legend');
  if (!e) {
    if (legend) legend.hidden = true;
    return;
  }
  if (legend) legend.hidden = false;

  updateMapLayers(recenter === true);

  // Floating legend card over the map
  if (e.iconMode === 'badge') {
    const cv = document.createElement('canvas');
    renderBadge(cv, 96, badgeOpts());
    updateLegend(cv, null);
  } else {
    updateLegend(null, currentIconSrc());
  }
  $('#prev-coords').textContent = `${Number(e.pos.x).toFixed(1)} · ${Number(e.pos.y).toFixed(1)}`;
  $('#prev-meta').textContent = `×${Number(e.scale).toFixed(2)} · ${e.alpha}`;
}

function updateLegend(canvas, src) {
  const host = $('#prev-legend-ic');
  host.innerHTML = '';
  if (canvas) {
    canvas.style.width = '20px'; canvas.style.height = '20px';
    host.appendChild(canvas);
  } else if (src) {
    const img = document.createElement('img');
    img.src = src;
    if (S.editing && S.editing.iconMode === 'image') {
      const cls = shapeClass(S.editing.shape);
      if (cls) img.className = cls;
    }
    host.appendChild(img);
  }
  const nm = (S.editing && S.editing.name) || '';
  $('#prev-legend-name').textContent = nm !== '' ? nm : T('f_name_ph', 'Shown in the pause-map legend');
}

/* ── Sprite picker modal ─────────────────────────────────────────────────── */

function openSpritePicker() {
  const root = $('#modal-root');
  root.innerHTML = `
    <div class="modal modal-lg">
      <div class="modal-head">
        <h3></h3>
        <button class="icon-btn" data-act="x" data-tip=""><svg class="ic"><use href="#i-close"/></svg></button>
      </div>
      <div class="modal-body">
        <label class="input-well search" style="width:100%">
          <svg class="ic"><use href="#i-search"/></svg>
          <input type="text" id="sp-q" autofocus>
        </label>
        <div class="sp-grid" id="sp-grid"></div>
        <p class="sp-note" id="sp-note"></p>
      </div>
    </div>`;
  $('.modal-head h3', root).textContent = T('sp_title', 'GTA sprite catalogue');
  $('#sp-q').placeholder = T('sp_search_ph', 'Search by name or id…');
  $('[data-act="x"]', root).dataset.tip = T('btn_close', 'Close');
  $('[data-act="x"]', root).onclick = closeModal;

  const CAP = 240;
  const hijacked = new Set((S.slots.hijacked || []).map(Number));

  const renderGrid = () => {
    const q = $('#sp-q').value.trim().toLowerCase();
    const grid = $('#sp-grid');
    const note = $('#sp-note');
    grid.innerHTML = '';

    const all = catalogue().filter(e => !hijacked.has(e[0]));
    if (all.length === 0) {
      note.className = 'sp-note warn';
      note.textContent = T('sp_fail', 'Sprite catalogue failed to load. Restart the resource.');
      return;
    }
    const hits = all.filter(e => !q || e[1].includes(q) || String(e[0]) === q);
    const shown = hits.slice(0, CAP);

    shown.forEach(e => {
      const cell = document.createElement('button');
      cell.className = 'sp-cell' + (S.editing && S.editing.sprite === e[0] ? ' is-active' : '');
      const img = document.createElement('img');
      img.loading = 'lazy';
      img.src = 'blips/' + e[2];
      img.onerror = () => { img.onerror = null; img.src = 'blips/radar_level.png'; };
      const label = document.createElement('span');
      label.textContent = e[0] + ' ' + e[1].replace(/^radar_/, '');
      cell.appendChild(img); cell.appendChild(label);
      cell.onclick = () => {
        S.editing.sprite = e[0];
        S.editing.iconMode = 'sprite';
        closeModal();
        renderEditor();
        markDirty();
      };
      grid.appendChild(cell);
    });

    note.className = 'sp-note';
    note.textContent = hits.length > CAP
      ? TF('sp_cap', 'Showing the first %d. Refine the search.', CAP)
      : TF('sp_count', '%d of %d sprites', hits.length, all.length);
  };

  let deb = null;
  $('#sp-q').addEventListener('input', () => { clearTimeout(deb); deb = setTimeout(renderGrid, 120); });
  renderGrid();
  setTimeout(() => $('#sp-q').focus(), 30);
}

/* ══════════════════════════════════════════════════════════════════════════
   IMAGES TAB
   ══════════════════════════════════════════════════════════════════════════ */

function imageUsage(id) {
  return S.blips.filter(b => b.icon && b.icon.mode === 'image' && b.icon.image === id).length;
}

function renderImages() {
  const grid = $('#img-grid');
  grid.innerHTML = '';
  const ids = Object.keys(S.images);
  $('#img-empty').hidden = ids.length !== 0;

  ids.forEach((id, i) => {
    const rec = S.images[id];
    const used = imageUsage(id);
    const card = document.createElement('div');
    card.className = 'card img-card';
    card.style.animationDelay = Math.min(i * 14, 155) + 'ms';

    const box = document.createElement('div');
    box.className = 'imgbox';
    const img = document.createElement('img');
    img.src = rec.data;
    box.appendChild(img);
    card.appendChild(box);

    const well = document.createElement('label');
    well.className = 'input-well';
    const input = document.createElement('input');
    input.type = 'text';
    input.maxLength = 40;
    input.value = rec.name || '';
    input.placeholder = T('img_name_ph', 'Image name');
    let deb = null;
    input.addEventListener('input', () => {
      clearTimeout(deb);
      deb = setTimeout(() => post('saveImage', { id, name: input.value }), 600);
    });
    well.appendChild(input);
    card.appendChild(well);

    const foot = document.createElement('div');
    foot.className = 'img-card-foot';
    const chip = document.createElement('span');
    chip.className = 'chip-xs' + (used ? ' c-img' : '');
    chip.textContent = used ? TF('img_used', 'used by %d', used) : T('img_unused', 'unused');
    const sp = document.createElement('span'); sp.className = 'spacer';

    /* REPLACE THE PICTURE, IN PLACE.
       The id stays, so every blip already pointing at it gets the new artwork
       on the next sync and nothing has to be repointed by hand. The server
       overwrites the record (upsertImage with an existing id) and re-syncs the
       players only when the image is actually on somebody's map. */
    const rep = document.createElement('button');
    rep.className = 'icon-btn js-upload';
    rep.dataset.tip = used
      ? TF('act_replace_used', 'Replace picture (updates %d blips)', used)
      : T('act_replace', 'Replace picture');
    rep.innerHTML = '<svg class="ic"><use href="#i-upload"/></svg>';
    rep.style.width = '26px'; rep.style.height = '26px';
    rep.onclick = () => {
      const f = $('#img-file');
      f.dataset.replace = id;          // read back by the change handler
      f.multiple = false;              // one picture replaces one picture
      f.click();
    };

    const del = document.createElement('button');
    del.className = 'icon-btn danger';
    del.dataset.tip = T('act_del', 'Delete');
    del.innerHTML = '<svg class="ic"><use href="#i-trash"/></svg>';
    del.style.width = '26px'; del.style.height = '26px';
    del.onclick = () => {
      if (used > 0) { toast('err', TF('n_image_in_use', 'That image is used by %d blips. Repoint them first.', used)); return; }
      confirmModal(T('img_del_t', 'Delete this image?'), T('img_del_d', 'Blips using it must be repointed first. The server refuses to orphan them.'),
        T('modal_ok', 'Delete'), () => post('deleteImage', { id }));
    };
    foot.appendChild(chip); foot.appendChild(sp); foot.appendChild(rep); foot.appendChild(del);
    card.appendChild(foot);
    grid.appendChild(card);
  });
}

/* ══════════════════════════════════════════════════════════════════════════
   DEVELOPER TAB
   ══════════════════════════════════════════════════════════════════════════ */

function copyText(text) {
  const ta = document.createElement('textarea');
  ta.value = text;
  ta.style.position = 'fixed'; ta.style.opacity = '0';
  document.body.appendChild(ta);
  ta.select();
  try { document.execCommand('copy'); } catch (_) {}
  ta.remove();
  toast('ok', T('dev_copied', 'Copied.'));
}

function snippetCard(title, code) {
  const card = document.createElement('div');
  card.className = 'card snippet';
  const head = document.createElement('div');
  head.className = 'snippet-head';
  const t = document.createElement('span');
  t.className = 'snippet-title';
  t.textContent = title;
  const btn = document.createElement('button');
  btn.className = 'icon-btn';
  btn.dataset.tip = T('dev_copy', 'Copy');
  btn.innerHTML = '<svg class="ic"><use href="#i-copy"/></svg>';
  btn.onclick = () => copyText(code);
  head.appendChild(t); head.appendChild(btn);
  const pre = document.createElement('pre');
  pre.textContent = code;
  card.appendChild(head); card.appendChild(pre);
  return card;
}

/* Lua code for one stored blip, exactly as AddBlip would take it. */
function luaStr(s) {
  return "'" + String(s).replace(/\\/g, '\\\\').replace(/'/g, "\\'") + "'";
}
function blipToLua(b) {
  const lines = [];
  lines.push(`    name = ${luaStr(b.name)},`);
  const ic = b.icon || {};
  if (ic.mode === 'image') {
    const shape = (ic.shape === 'rounded' || ic.shape === 'circle') ? `, shape = ${luaStr(ic.shape)}` : '';
    lines.push(`    icon = { mode = 'image', image = ${luaStr(ic.image)}${shape} },`);
  } else {
    lines.push(`    icon = { mode = 'sprite', sprite = ${ic.sprite || 1} },`);
  }
  lines.push(`    pos = { x = ${b.pos.x}, y = ${b.pos.y}, z = ${b.pos.z} },`);
  lines.push(`    colour = ${b.colour || 0}, scale = ${b.scale}, alpha = ${b.alpha},`);
  lines.push(`    shortRange = ${b.shortRange === true}, flash = ${b.flash === true}, route = ${b.route === true}, routeColour = ${b.routeColour || 0},`);
  lines.push(`    category = ${b.category || 1}, display = ${b.display || 2},`);
  const z = b.zone || {};
  if (z.mode === 'radius') {
    lines.push(`    zone = { mode = 'radius', radius = ${z.radius}, colour = ${z.colour}, alpha = ${z.alpha}, events = ${z.events === true} },`);
  } else if (z.mode === 'area') {
    lines.push(`    zone = { mode = 'area', w = ${z.w}, h = ${z.h}, rot = ${z.rot}, colour = ${z.colour}, alpha = ${z.alpha}, events = ${z.events === true} },`);
  }
  const v = b.vis || {};
  if (v.mode === 'jobs') {
    lines.push(`    vis = { mode = 'jobs', jobs = { ${(v.jobs || []).map(luaStr).join(', ')} } },`);
  } else if (v.mode === 'private') {
    lines.push(`    vis = { mode = 'private' },`);
  }
  return `local id = exports.apex_blips:AddBlip({\n${lines.join('\n')}\n})`;
}

/* The blip picker at the top of the Developer tab. */
function renderDevPicker() {
  const host = $('#dev-picker');
  host.innerHTML = '';
  if (S.blips.length === 0) return;

  if (!S.selectedId || !S.blips.find(b => b.id === S.selectedId)) S.selectedId = S.blips[0].id;
  const cur = S.blips.find(b => b.id === S.selectedId);

  const label = document.createElement('span');
  label.className = 'eyebrow';
  label.style.display = 'block';
  label.style.marginBottom = '6px';
  label.textContent = T('dev_pick', 'Blip');
  host.appendChild(label);

  const btn = document.createElement('button');
  btn.className = 'drop-btn';
  const th = document.createElement('span');
  th.className = 'thumb';
  const ci = cur.icon || {};
  iconThumbInto(th, ci.mode, ci.sprite, ci.image, ci.shape);
  const nm = document.createElement('span');
  nm.className = 'drop-label';
  nm.textContent = cur.name;
  const idc = document.createElement('span');
  idc.className = 'drop-id';
  idc.textContent = cur.id;
  btn.appendChild(th); btn.appendChild(nm); btn.appendChild(idc);
  btn.insertAdjacentHTML('beforeend', '<svg class="ic"><use href="#i-chevron-down"/></svg>');

  const menu = document.createElement('div');
  menu.className = 'drop-menu';
  menu.hidden = true;
  S.blips.forEach(b => {
    const it = document.createElement('button');
    it.className = 'drop-item' + (b.id === S.selectedId ? ' is-active' : '');
    const t2 = document.createElement('span');
    t2.className = 'thumb';
    const bi = b.icon || {};
    iconThumbInto(t2, bi.mode, bi.sprite, bi.image, bi.shape);
    const n2 = document.createElement('span');
    n2.className = 'nm';
    n2.textContent = b.name;
    const i2 = document.createElement('span');
    i2.className = 'drop-id';
    i2.textContent = b.id;
    it.appendChild(t2); it.appendChild(n2); it.appendChild(i2);
    it.onclick = () => { S.selectedId = b.id; renderDev(); renderList(); };
    menu.appendChild(it);
  });

  btn.onclick = ev => { ev.stopPropagation(); menu.hidden = !menu.hidden; };
  host.appendChild(btn);
  host.appendChild(menu);
}

function renderDev() {
  renderDevPicker();
  const host = $('#dev-body');
  host.innerHTML = '';
  const sel = S.blips.find(b => b.id === S.selectedId) || null;
  const id = sel ? sel.id : 'b_000001';

  const mkSec = title => {
    const sec = document.createElement('div');
    sec.className = 'dev-sec';
    const eb = document.createElement('span');
    eb.className = 'eyebrow';
    eb.textContent = title;
    sec.appendChild(eb);
    host.appendChild(sec);
    return sec;
  };

  if (sel) {
    const own = mkSec(T('dev_thiscode', 'This blip, as code (AddBlip)'));
    own.appendChild(snippetCard(sel.name + '  ·  ' + sel.id, blipToLua(sel)));
  }

  const srv = mkSec(T('dev_srv_t', 'Server exports'));
  srv.appendChild(snippetCard('AddBlip',
`local id = exports.apex_blips:AddBlip({
    name = 'Drop-off',
    icon = { mode = 'sprite', sprite = 501 },
    pos  = { x = 215.2, y = -810.1, z = 30.7 },
    zone = { mode = 'radius', radius = 80.0, colour = 1, alpha = 90, events = true },
    vis  = { mode = 'jobs', jobs = { 'police' } },
})`));
  srv.appendChild(snippetCard('UpdateBlip / SetBlipEnabled / RemoveBlip',
`exports.apex_blips:UpdateBlip('${id}', { scale = 1.2, route = true })
exports.apex_blips:SetBlipEnabled('${id}', false)
exports.apex_blips:RemoveBlip('${id}')`));
  srv.appendChild(snippetCard(T('dev_sn_reg', 'RegisterImage (any picture, then use it as an icon)'),
`local img = exports.apex_blips:RegisterImage('Crew logo', 'data:image/png;base64,....')
exports.apex_blips:AddBlip({
    name = 'Crew HQ',
    icon = { mode = 'image', image = img },
    pos  = { x = 100.0, y = 200.0, z = 30.0 },
})`));

  const cli = mkSec(T('dev_cli_t', 'Client exports'));
  cli.appendChild(snippetCard(T('dev_sn_local', 'AddLocalBlip (this player only, never stored)'),
`local id = exports.apex_blips:AddLocalBlip({
    name = 'Your delivery',
    icon = { mode = 'image', data = 'data:image/png;base64,....' },
    pos  = { x = 425.1, y = -979.5, z = 30.7 },
    route = true,
})
-- later: exports.apex_blips:RemoveLocalBlip(id)`));
  cli.appendChild(snippetCard('GetBlipHandle / IsInZone',
`local handle = exports.apex_blips:GetBlipHandle('${id}')  -- native blip handle
if exports.apex_blips:IsInZone('${id}') then
    -- this player is inside the blip's zone right now
end`));

  const ev = mkSec(T('dev_ev_t', 'Events'));
  ev.appendChild(snippetCard(T('dev_sn_evc', 'Zone events (client)'),
`AddEventHandler('apex_blips:client:zoneEnter', function(id, name)
    print(('entered %s (%s)'):format(name, id))
end)
AddEventHandler('apex_blips:client:zoneExit', function(id, name) end)`));
  ev.appendChild(snippetCard(T('dev_sn_evs', 'Zone events (server)'),
`AddEventHandler('apex_blips:zone', function(src, id, inside)
    -- src walked in/out of blip id's zone (zone.events must be on)
end)`));

  // Export / import
  const io = mkSec(T('dev_export_t', 'Export all blips (JSON)'));
  const wrap = document.createElement('div');
  wrap.className = 'dev-io';

  const exCard = document.createElement('div');
  exCard.className = 'card';
  const exTa = document.createElement('textarea');
  exTa.className = 'well';
  exTa.readOnly = true;
  const usedImages = {};
  S.blips.forEach(b => {
    if (b.icon && b.icon.mode === 'image' && S.images[b.icon.image]) usedImages[b.icon.image] = S.images[b.icon.image];
  });
  exTa.value = JSON.stringify({ blips: S.blips, images: usedImages });
  const exBtn = document.createElement('button');
  exBtn.className = 'btn btn-soft';
  exBtn.innerHTML = '<svg class="ic"><use href="#i-copy"/></svg><span></span>';
  exBtn.querySelector('span').textContent = T('dev_export_btn', 'Copy JSON');
  exBtn.onclick = () => copyText(exTa.value);
  exCard.appendChild(exTa); exCard.appendChild(exBtn);

  const imCard = document.createElement('div');
  imCard.className = 'card';
  const imTitle = document.createElement('span');
  imTitle.className = 'eyebrow';
  imTitle.textContent = T('dev_import_t', 'Import blips (JSON)');
  const imTa = document.createElement('textarea');
  imTa.className = 'well';
  imTa.placeholder = T('dev_import_ph', 'Paste a JSON export here…');
  const imBtn = document.createElement('button');
  imBtn.className = 'btn btn-secondary';
  imBtn.innerHTML = '<svg class="ic"><use href="#i-import"/></svg><span></span>';
  imBtn.querySelector('span').textContent = T('dev_import_btn', 'Import');
  imBtn.onclick = () => {
    let pack = null;
    try { pack = JSON.parse(imTa.value); } catch (_) {}
    if (!pack || (!Array.isArray(pack.blips) && !Array.isArray(pack))) {
      toast('err', T('t_bad_import', 'That is not a valid blip export.'));
      return;
    }
    if (Array.isArray(pack)) pack = { blips: pack };
    post('importAll', { pack });
    toast('ok', TF('t_import_ok', '%d blips sent to the server.', pack.blips.length));
    imTa.value = '';
  };
  imCard.appendChild(imTitle); imCard.appendChild(imTa); imCard.appendChild(imBtn);

  wrap.appendChild(exCard); wrap.appendChild(imCard);
  io.appendChild(wrap);
}

/* ══════════════════════════════════════════════════════════════════════════
   SAVE / VALIDATE
   ══════════════════════════════════════════════════════════════════════════ */

function saveEditing() {
  const e = S.editing;
  if (!e) return;
  if (!e.name.trim()) { toast('err', T('t_need_name', 'Give the blip a name first.')); $('#f-name').focus(); return; }
  if (e.iconMode === 'badge') { toast('err', T('t_need_badge', 'Type something for the badge first.')); return; }
  if (e.iconMode === 'image' && (!e.image || !S.images[e.image])) {
    toast('err', T('t_need_image', 'Choose or upload an image first.'));
    return;
  }
  if (e.vis.mode === 'jobs' && e.vis.jobs.length === 0) {
    toast('err', T('t_no_jobs', 'Add at least one job, or switch visibility back to Everyone.'));
    return;
  }
  post('save', { def: defToServer(e) });
}

/* ══════════════════════════════════════════════════════════════════════════
   DATA IN
   ══════════════════════════════════════════════════════════════════════════ */

function acceptData(msg) {
  if (Array.isArray(msg.blips)) S.blips = msg.blips;
  if (msg.images && typeof msg.images === 'object') S.images = msg.images;
  if (msg.slots) S.slots = Object.assign(S.slots, msg.slots);

  renderList();
  renderMapMarkers();
  if (S.tab === 'images') renderImages();
  if (S.tab === 'dev') renderDev();
  if (S.tab === 'editor' && S.editing) {
    renderLibStrip();
    refreshPreview();
  }
}

/* ══════════════════════════════════════════════════════════════════════════
   MESSAGE ROUTER
   ══════════════════════════════════════════════════════════════════════════ */

window.addEventListener('message', ev => {
  const msg = ev.data;
  if (!msg || typeof msg.action !== 'string') return;

  switch (msg.action) {
    case 'open': {
      S.open = true;
      S.locale = msg.locale || {};
      if (msg.defaults) S.defaults = msg.defaults;
      if (msg.zones) S.zones = msg.zones;
      if (msg.limits) S.limits = Object.assign(S.limits, msg.limits);
      if (msg.imgcfg) S.imgcfg = { size: msg.imgcfg.size, maxKB: msg.imgcfg.maxKB, maxCount: msg.imgcfg.maxCount };
      if (msg.myPos) S.myPos = msg.myPos;
      applyI18n();
      applyRangeCaps();
      document.body.classList.remove('hidden', 'picking');
      S.editing = null;
      clearDirty();
      clearEditLayers();
      clearWorldLayer();          // fresh session, overlay starts off
      acceptData(msg);
      setTab('blips');
      // The map measured itself while the body was hidden on the very first
      // open; re-measure once the layout is real.
      setTimeout(() => { if (MAP.map) { try { MAP.map.invalidateSize(); } catch (_) {} } }, 120);
      break;
    }

    case 'data':
      acceptData(msg);
      break;

    case 'close':
      S.open = false;
      document.body.classList.add('hidden');
      document.body.classList.remove('picking');
      closeModal();
      // Never let an unsaved draft (and its ghost marker) survive into the
      // next session — the page stays resident, so clean up explicitly.
      S.editing = null;
      clearDirty();
      clearEditLayers();
      renderMapMarkers();
      break;

    case 'saved':
      if (msg.ok) {
        toast('ok', S.editing && !S.editing.id ? T('t_created', 'Blip created.') : T('t_saved', 'Blip saved.'));
        if (S.editing && !S.editing.id && msg.id) S.editing.id = msg.id;
        if (S.editing) {
          S.selectedId = S.editing.id;
          $('#ed-id').hidden = !S.editing.id;
          $('#ed-id').textContent = S.editing.id || '';
          $('#ed-delete').hidden = !S.editing.id;
          $('#ed-save-label').textContent = T('btn_save', 'Save blip');
        }
        clearDirty();
      }
      break;

    /* ONE image landing, instead of the whole library coming back. See
       pushImage in server/main.lua: re-sending every picture after every save
       is what filled the wire and made the next upload look dead. */
    case 'image': {
      if (typeof msg.id === 'string') {
        if (msg.removed) delete S.images[msg.id];
        else if (msg.image) S.images[msg.id] = msg.image;
        if (msg.slots) S.slots = Object.assign(S.slots, msg.slots);
        /* The same redraws acceptData() does, minus the ones that only depend
           on the blip list, which this message cannot change. */
        renderList();
        if (S.tab === 'images') renderImages();
        if (S.tab === 'dev') renderDev();
        if (S.tab === 'editor' && S.editing) { renderLibStrip(); refreshPreview(); }
      }
      break;
    }

    case 'imageSaved': {
      const sent = uploadInFlight;
      uploadInFlight = null;

      /* ⚠ 'busy' IS NOT A FAILURE, IT IS A RETRY. The server's flood guard is
         shared with every other write event, so an unlucky save or delete in
         the same 400 ms window can bounce a queued picture. Losing it halfway
         through a batch of twenty is exactly the silence this whole queue
         exists to remove, so the picture goes back to the head of the queue
         and is tried once more. */
      if (!msg.ok && msg.reason === 'busy' && sent && !sent.retried) {
        sent.retried = true;
        uploadQ.unshift(sent);
        uploadDone();
        break;
      }

      const single = !batch || batch.total <= 1;
      if (msg.ok) {
        if (batch) batch.done += 1;
        if (single) {
          toast('ok', msg.replaced
            ? T('t_img_replaced', 'Picture replaced. Every blip using it was updated.')
            : T('t_img_saved', 'Image saved.'));
        }
        if (S.pendingImageSelect && S.editing) {
          S.pendingImageSelect = false;
          S.editing.image = msg.id;
          S.editing.iconMode = 'image';
          segSet('#ic-mode', 'image');
          syncIconPanels();
          markDirty();
          // the library strip re-renders when the refreshed data lands
        }
      } else {
        if (batch) batch.failed += 1;
        S.pendingImageSelect = false;
        /* ⚠ FAILURES USED TO BE SILENT HERE TOO. The server now answers every
           refused save with a reason, so say it: a person who sees nothing
           assumes the button is broken and reconnects. */
        toast('err',
          msg.reason === 'busy'  ? T('t_img_busy', 'One at a time. Try that again in a moment.') :
          msg.reason === 'limit' ? TF('t_img_limit', 'The library is full (max %d).', S.imgcfg.maxCount) :
          msg.reason === 'perm'  ? T('t_no_perm', 'You are not allowed to edit blips.') :
                                   T('t_img_fail', 'That image could not be saved.'));
        // A full library or no permission will refuse every remaining picture
        // too. Stop the run rather than spraying the same refusal twenty times.
        if (msg.reason === 'limit' || msg.reason === 'perm') uploadQ = [];
      }

      if (uploadQ.length > 0) batchProgress(); else batchEnd();
      uploadDone();
      break;
    }

    case 'pickHide':
      document.body.classList.add('picking');
      break;

    case 'pickResult':
      document.body.classList.remove('picking');
      if (msg.ok && S.editing) {
        setEditingPos(msg.x, msg.y, msg.z, true);
      }
      break;
  }
});

/* Sliders whose ceilings come from config */
/* The sliders are given a comfortable TRAVEL, not a rule: typing past the end
   stretches the track (see bindNum). What may never be exceeded is
   S.limits, which is the server's own clamp. */
function applyRangeCaps() {
  $('#z-radius').max = String(S.zones.maxRadius || 2000);
  $('#z-w').max = String(S.zones.maxSide || 4000);
  $('#z-h').max = String(S.zones.maxSide || 4000);

  // Scale: keep the handle usable (a track out to 10 makes every normal blip a
  // thumbnail at the far left) while letting the box reach the real ceiling.
  $('#f-scale').min = String(S.limits.scaleMin);
  $('#f-scale').max = String(Math.min(S.limits.scaleMax, 4));
  $('#f-alpha').min = String(S.limits.alphaMin);
  $('#f-alpha').max = String(S.limits.alphaMax);
  $('#z-alpha').min = String(S.limits.zoneAlphaMin);
  $('#z-alpha').max = String(S.limits.zoneAlphaMax);
}

/* ══════════════════════════════════════════════════════════════════════════
   WIRING (once, at boot)
   ══════════════════════════════════════════════════════════════════════════ */

function wire() {
  // Rail actions
  $('#btn-close').onclick = () => post('close');
  $('#rail-save').onclick = () => { if (S.editing) saveEditing(); };
  $('#rail-world').onclick = toggleWorldBlips;

  // Rail
  $$('.rail-tab').forEach(b => b.addEventListener('click', () => setTab(b.dataset.tab)));

  // List toolbar
  $('#bl-new').onclick = () => openEditor(newDef());
  $('#ed-empty-new').onclick = () => openEditor(newDef());
  let searchDeb = null;
  $('#bl-search').addEventListener('input', ev => {
    clearTimeout(searchDeb);
    searchDeb = setTimeout(() => { S.search = ev.target.value; renderList(); }, 120);
  });

  // Icon mode
  segBind('#ic-mode', v => {
    S.editing.iconMode = v;
    syncIconPanels();
    if (v === 'badge') refreshBadgePreview();
    markDirty(); refreshPreview();
  });
  $('#ic-sprite-pick').onclick = openSpritePicker;
  // The editor's own upload button. Always a NEW image (it is how you give the
  // blip you are editing a picture it does not have yet); replacing an existing
  // one is the library's job, where you can see what you are overwriting.
  $('#ic-upload').classList.add('js-upload');
  $('#ic-upload').onclick = () => $('#ic-file').click();
  // Several files at once are welcome here too: they all land in the library,
  // and the LAST one becomes this blip's icon (see S.pendingImageSelect).
  $('#ic-file').addEventListener('change', ev => {
    const files = ev.target.files;
    enqueueUploads(files);
    ev.target.value = '';
  });
  segBind('#ic-shape', v => { S.editing.shape = v; markDirty(); refreshPreview(); });

  // Emoji & Font Awesome dropdown for the badge maker
  const emojiPop = $('#bd-emoji-pop');
  let pickerTab = 'emoji';

  function pickGlyph(ch, isFa) {
    S.badgeFa = isFa === true;
    $('#bd-text').value = ch;
    const face = $('#bd-emoji-face');
    face.textContent = ch;
    face.classList.toggle('fa-face', S.badgeFa);
    emojiPop.hidden = true;
    markDirty();
    refreshBadgePreview();
  }

  function buildEmojiTab(body) {
    const blocks = [...EMOJI_BLOCKS];
    const buildGroup = i => {
      if (i >= blocks.length) {
        // plain text glyphs render in the UI font, always available
        const group = document.createElement('div');
        group.className = 'emoji-group';
        const eb = document.createElement('span');
        eb.className = 'eyebrow';
        eb.textContent = T('em_text', 'Text icons');
        const grid = document.createElement('div');
        grid.className = 'emoji-grid';
        TEXT_ICONS.forEach(ch => {
          const cell = document.createElement('button');
          cell.className = 'emoji-cell';
          cell.type = 'button';
          cell.textContent = ch;
          cell.onclick = () => pickGlyph(ch, false);
          grid.appendChild(cell);
        });
        group.appendChild(eb);
        group.appendChild(grid);
        body.appendChild(group);
        return;
      }
      const [key, fallback, from, to] = blocks[i];
      const group = document.createElement('div');
      group.className = 'emoji-group';
      const eb = document.createElement('span');
      eb.className = 'eyebrow';
      eb.textContent = T(key, fallback);
      const grid = document.createElement('div');
      grid.className = 'emoji-grid';
      for (let cp = from; cp <= to; cp++) {
        const ch = String.fromCodePoint(cp);
        if (!glyphSupported(ch)) continue;
        const cell = document.createElement('button');
        cell.className = 'emoji-cell';
        cell.type = 'button';
        cell.textContent = ch;
        cell.onclick = () => pickGlyph(ch, false);
        grid.appendChild(cell);
      }
      if (grid.children.length) {
        group.appendChild(eb);
        group.appendChild(grid);
        body.appendChild(group);
      }
      // one block per frame keeps the open animation smooth
      setTimeout(() => buildGroup(i + 1), 0);
    };
    buildGroup(0);
  }

  function buildFaTab(body, query) {
    body.innerHTML = '';
    const all = Array.isArray(window.APEX_FA) ? window.APEX_FA : [];
    const q = (query || '').trim().toLowerCase();
    const hits = all.filter(e => !q || e[0].includes(q));
    const CAP = 320;
    const grid = document.createElement('div');
    grid.className = 'emoji-grid fa-grid';
    hits.slice(0, CAP).forEach(([name, hex]) => {
      const cell = document.createElement('button');
      cell.className = 'emoji-cell fa-cell';
      cell.type = 'button';
      cell.title = name;
      cell.textContent = String.fromCodePoint(parseInt(hex, 16));
      cell.onclick = () => pickGlyph(cell.textContent, true);
      grid.appendChild(cell);
    });
    body.appendChild(grid);
    const note = document.createElement('p');
    note.className = 'sp-note';
    note.textContent = hits.length > CAP
      ? TF('sp_cap', 'Showing the first %d. Refine the search.', CAP)
      : TF('fa_count', '%d of %d icons', hits.length, all.length);
    body.appendChild(note);
  }

  function buildEmojiPop() {
    if (emojiPop.dataset.built) return;
    emojiPop.dataset.built = '1';

    const tabs = document.createElement('div');
    tabs.className = 'seg seg-sm pop-tabs';
    const tEmoji = document.createElement('button');
    tEmoji.className = 'seg-btn is-active';
    tEmoji.textContent = T('emoji_tab_emoji', 'Emojis');
    const tFa = document.createElement('button');
    tFa.className = 'seg-btn';
    tFa.textContent = T('emoji_tab_fa', 'Font Awesome');
    tabs.appendChild(tEmoji);
    tabs.appendChild(tFa);

    const search = document.createElement('label');
    search.className = 'input-well pop-search';
    search.hidden = true;
    const sIn = document.createElement('input');
    sIn.type = 'text';
    sIn.placeholder = T('emoji_search_ph', 'Search icons by name…');
    search.appendChild(sIn);

    const bodyEmoji = document.createElement('div');
    const bodyFa = document.createElement('div');
    bodyFa.hidden = true;

    const setTabP = which => {
      pickerTab = which;
      tEmoji.classList.toggle('is-active', which === 'emoji');
      tFa.classList.toggle('is-active', which === 'fa');
      bodyEmoji.hidden = which !== 'emoji';
      bodyFa.hidden = which !== 'fa';
      search.hidden = which !== 'fa';
      if (which === 'fa' && !bodyFa.dataset.built) {
        bodyFa.dataset.built = '1';
        buildFaTab(bodyFa, '');
      }
    };
    tEmoji.onclick = () => setTabP('emoji');
    tFa.onclick = () => setTabP('fa');
    let faDeb = null;
    sIn.addEventListener('input', () => {
      clearTimeout(faDeb);
      faDeb = setTimeout(() => buildFaTab(bodyFa, sIn.value), 140);
    });

    // custom entry: paste any emoji/character, or an fa hex code like f1b9
    const custom = document.createElement('div');
    custom.className = 'pop-custom';
    const cWell = document.createElement('label');
    cWell.className = 'input-well grow';
    const cIn = document.createElement('input');
    cIn.type = 'text';
    cIn.placeholder = T('emoji_custom_ph', 'Anything missing? Paste an emoji, or an fa code like f1b9');
    cWell.appendChild(cIn);
    const cBtn = document.createElement('button');
    cBtn.className = 'btn btn-soft';
    cBtn.textContent = T('emoji_custom_use', 'Use');
    const useCustom = () => {
      const v = cIn.value.trim();
      if (!v) return;
      if (/^f[0-9a-f]{3}$/i.test(v)) pickGlyph(String.fromCodePoint(parseInt(v, 16)), true);
      else pickGlyph(v, false);
      cIn.value = '';
    };
    cBtn.onclick = useCustom;
    cIn.addEventListener('keydown', ev => { if (ev.key === 'Enter') { ev.preventDefault(); useCustom(); } });
    custom.appendChild(cWell);
    custom.appendChild(cBtn);

    emojiPop.appendChild(tabs);
    emojiPop.appendChild(search);
    emojiPop.appendChild(custom);
    emojiPop.appendChild(bodyEmoji);
    emojiPop.appendChild(bodyFa);
    buildEmojiTab(bodyEmoji);
  }

  $('#bd-emoji-btn').onclick = ev => {
    ev.stopPropagation();
    buildEmojiPop();
    emojiPop.hidden = !emojiPop.hidden;
  };

  // Any open dropdown closes on an outside click.
  document.addEventListener('click', ev => {
    if (!emojiPop.hidden && !emojiPop.contains(ev.target)) emojiPop.hidden = true;
    $$('.drop-menu').forEach(m => {
      if (!m.hidden && !m.contains(ev.target)) m.hidden = true;
    });
  });

  // Badge controls. Typing by hand means "this is text/emoji, not an FA glyph".
  $('#bd-text').addEventListener('input', ev => {
    if (S.badgeFa) {
      S.badgeFa = false;
      $('#bd-emoji-face').classList.remove('fa-face');
    }
    $('#bd-emoji-face').textContent = Array.from(ev.target.value.trim()).slice(0, 1).join('') || '😀';
    refreshBadgePreview();
  });
  ['#bd-bg', '#bd-fg'].forEach(sel => $(sel).addEventListener('input', refreshBadgePreview));
  segBind('#bd-shape', () => refreshBadgePreview());
  $('#bd-bake').onclick = () => {
    const opts = badgeOpts();
    if (!opts.text.trim()) { toast('err', T('t_need_badge', 'Type something for the badge first.')); return; }
    /* ⚠ A bake is a saveImage like any other, so it has to respect the same
       one-on-the-wire rule. It used to post straight past it, which is how a
       bake landed on top of a running upload and the server dropped one of
       them. */
    if (uploadBusy || uploadQ.length > 0) { toast('err', T('t_img_busy', 'One at a time. Try that again in a moment.')); return; }
    const size = S.imgcfg.size || 128;
    const cv = document.createElement('canvas');
    renderBadge(cv, size, opts);
    S.pendingImageSelect = true;
    uploadStart();
    post('saveImage', {
      name: ('Badge ' + Array.from(opts.text.trim()).slice(0, 3).join('')).slice(0, 40),
      data: cv.toDataURL('image/png'),
      size, badge: true,
    });
  };

  // Identity
  $('#f-name').addEventListener('input', ev => { S.editing.name = ev.target.value; markDirty(); refreshPreview(); });
  buildSwatches('#f-colour', () => S.editing.colour, v => { S.editing.colour = v; $('#f-colour-val').textContent = String(v); });
  /*  ══ THE VALUE BOXES ARE TYPEABLE, AND THE SLIDER IS NOT THE CEILING ══
      A slider end is a comfortable range, not a rule. Scale stopped at 2.00
      because that is where its track ended, while the engine goes on scaling
      well past it; the same was true of zone opacity at 200. So the readout
      next to each slider is now an input, and the pair works both ways:

        · drag the slider  -> the box follows
        · type in the box  -> the value is taken as typed, and if it is beyond
                              the slider's travel the TRACK GROWS to include it,
                              so the handle still means something afterwards
        · arrow keys       -> step, because a value box you cannot nudge is
                              only half a value box

      The only real limit is `lim`, which comes from the server (Config.limits,
      the same numbers sanitizeBlip clamps to). The page never offers a number
      the server would quietly take back.

      Committed on `change` and on Enter, not on every keystroke: typing "12"
      passes through "1", and a blip that jumps to 1 and then to 12 on its way
      is noise. Blur and Enter are when a person has finished saying it. */
  const bindNum = (sel, valSel, apply, opt) => {
    const o = opt || {};
    const dec = o.decimals != null ? o.decimals : 0;
    const fmt = v => (dec > 0 ? Number(v).toFixed(dec) : String(Math.round(v)));
    /* min/max may be a number or a function: the real ceilings arrive from the
       server in the open payload, after this wiring has already run. */
    const lim = (v, fallback) => {
      const r = typeof v === 'function' ? v() : v;
      return (r == null || !isFinite(r)) ? fallback : Number(r);
    };
    const hardMin = () => lim(o.min, Number($(sel).min));
    const hardMax = () => lim(o.max, Number($(sel).max));

    const commit = (v, fromBox) => {
      /* ⚠ NO BLIP OPEN, NOTHING TO SET. The editor refuses to invent a blip
         just because a field was touched (that rule is why the empty state
         exists), but the fields are still in the DOM and still focusable. The
         old read-only readouts could not be typed into, so this never came up;
         a typeable box without this guard throws on every commit. */
      if (!S.editing) return;
      if (!isFinite(v)) return;
      v = clamp(v, hardMin(), hardMax());
      if (dec > 0) v = Number(v.toFixed(dec)); else v = Math.round(v);
      // Grow the track when the typed value is past its end, so the handle is
      // not pinned uselessly at the far right for the rest of the session.
      const r = $(sel);
      if (v > Number(r.max)) r.max = String(v);
      if (v < Number(r.min)) r.min = String(v);
      r.value = String(v);
      /* ALWAYS write the normalised number back, including when the edit came
         from the box. commit() only runs on `change` and on Enter, which is
         after a person has finished typing, so there is no caret to fight: what
         they see afterwards is exactly what was stored, clamping and decimals
         included. Without this, typing 999 left "999" sitting in a box holding
         10, which is the field lying about itself. */
      $(valSel).value = fmt(v);
      apply(v);
      markDirty(); refreshPreview();
    };

    $(sel).addEventListener('input', ev => {
      if (!S.editing) return;          // same rule as commit(), see above
      const v = Number(ev.target.value);
      $(valSel).value = fmt(v);
      apply(dec > 0 ? Number(v.toFixed(dec)) : Math.round(v));
      markDirty(); refreshPreview();
    });

    const box = $(valSel);
    box.addEventListener('change', () => commit(parseFloat(box.value), true));
    box.addEventListener('blur', () => { box.value = fmt(Number($(sel).value)); });
    box.addEventListener('keydown', ev => {
      if (ev.key === 'Enter') { ev.preventDefault(); commit(parseFloat(box.value), true); box.blur(); return; }
      if (ev.key !== 'ArrowUp' && ev.key !== 'ArrowDown') return;
      ev.preventDefault();
      const step = (Number($(sel).step) || 1) * (ev.shiftKey ? 10 : 1);
      const cur = parseFloat(box.value);
      const next = (isFinite(cur) ? cur : Number($(sel).value)) + (ev.key === 'ArrowUp' ? step : -step);
      box.value = fmt(clamp(next, hardMin(), hardMax()));
      commit(parseFloat(box.value), true);
    });
    /* ⚠ Typing in a NUI text box with the game behind it: Escape and the
       studio's own shortcuts must not fire while a number is half-written. */
    box.addEventListener('keyup', ev => ev.stopPropagation());
  };

  bindNum('#f-scale', '#f-scale-val', v => S.editing.scale = v,
    { decimals: 2, min: () => S.limits.scaleMin, max: () => S.limits.scaleMax });
  bindNum('#f-alpha', '#f-alpha-val', v => S.editing.alpha = Math.round(v),
    { min: () => S.limits.alphaMin, max: () => S.limits.alphaMax });

  // Position
  const bindPos = (sel, key) => {
    $(sel).addEventListener('input', ev => {
      const v = parseFloat(ev.target.value);
      if (!isNaN(v)) { S.editing.pos[key] = v; markDirty(); refreshPreview(true); }
    });
  };
  bindPos('#f-x', 'x'); bindPos('#f-y', 'y'); bindPos('#f-z', 'z');

  $('#pos-me').onclick = async () => {
    const r = await post('myPos');
    if (r && r.ok) setEditingPos(r.x, r.y, r.z, true);
  };
  $('#pos-wp').onclick = async () => {
    const r = await post('waypoint');
    if (r && r.ok) setEditingPos(r.x, r.y, r.z, true);
    else toast('err', T('n_waypoint_none', 'No waypoint set. Open the map and place one first.'));
  };
  $('#pos-map').onclick = () => { toast('info', T('t_pick_wait', 'Waiting for the map…')); post('pickMap'); };

  // Behaviour
  $('#f-shortrange').addEventListener('change', ev => { S.editing.shortRange = ev.target.checked; markDirty(); });
  $('#f-flash').addEventListener('change', ev => { S.editing.flash = ev.target.checked; markDirty(); });
  $('#f-route').addEventListener('change', ev => {
    S.editing.route = ev.target.checked;
    $('#f-routecolour-field').hidden = !ev.target.checked;
    markDirty();
  });
  buildSwatches('#f-routecolour', () => S.editing.routeColour, v => { S.editing.routeColour = v; $('#f-routecolour-val').textContent = String(v); });
  segBind('#f-category', v => { S.editing.category = Number(v); markDirty(); });
  segBind('#f-display', v => { S.editing.display = Number(v); markDirty(); });

  // Zone
  segBind('#z-mode', v => { S.editing.zone.mode = v; syncZoneBody(); markDirty(); refreshPreview(); });
  bindNum('#z-radius', '#z-radius-val', v => S.editing.zone.radius = v,
    { decimals: 1, min: 1, max: () => S.zones.maxRadius });
  bindNum('#z-w', '#z-w-val', v => S.editing.zone.w = v,
    { decimals: 1, min: 1, max: () => S.zones.maxSide });
  bindNum('#z-h', '#z-h-val', v => S.editing.zone.h = v,
    { decimals: 1, min: 1, max: () => S.zones.maxSide });
  bindNum('#z-rot', '#z-rot-val', v => S.editing.zone.rot = v, { min: 0, max: 359 });
  buildSwatches('#z-colour', () => S.editing.zone.colour, v => { S.editing.zone.colour = v; $('#z-colour-val').textContent = String(v); });
  bindNum('#z-alpha', '#z-alpha-val', v => S.editing.zone.alpha = Math.round(v),
    { min: () => S.limits.zoneAlphaMin, max: () => S.limits.zoneAlphaMax });
  $('#z-events').addEventListener('change', ev => { S.editing.zone.events = ev.target.checked; markDirty(); });

  // Visibility
  segBind('#v-mode', v => { S.editing.vis.mode = v; syncVisBody(); markDirty(); });
  $('#v-jobs-input').addEventListener('keydown', ev => {
    if (ev.key !== 'Enter') return;
    ev.preventDefault();
    const raw = ev.target.value.trim().toLowerCase();
    if (!raw) return;
    raw.split(',').map(s => s.trim().replace(/[^a-z0-9_\-]/g, '')).filter(Boolean).forEach(j => {
      if (!S.editing.vis.jobs.includes(j) && S.editing.vis.jobs.length < 16) S.editing.vis.jobs.push(j);
    });
    ev.target.value = '';
    renderJobChips(); markDirty();
  });

  // Editor actions
  $('#ed-save').onclick = saveEditing;
  $('#ed-cancel').onclick = closeEditor;
  $('#ed-delete').onclick = () => {
    const id = S.editing && S.editing.id;
    if (!id) return;
    confirmModal(T('modal_del_t', 'Delete this blip?'), T('modal_del_d', 'This removes it for every player. There is no undo.'),
      T('modal_ok', 'Delete'), () => {
        post('delete', { id });
        closeEditor();
      });
  };

  // Images tab
  $('#img-upload-btn').classList.add('js-upload');
  $('#img-upload-btn').onclick = () => {
    const f = $('#img-file');
    delete f.dataset.replace;        // a plain upload is never a replace
    f.multiple = true;               // ...and a plain upload takes as many as you like
    f.click();
  };
  /* ⚠ `value = ''` AND the replace target cleared on EVERY change, success or
     not. Without the reset, picking the same file twice fires no event at all;
     without clearing dataset.replace, the next plain upload would silently
     overwrite the image the previous replace was aimed at. */
  $('#img-file').addEventListener('change', ev => {
    const target = ev.target.dataset.replace || undefined;
    delete ev.target.dataset.replace;
    enqueueUploads(ev.target.files, target);
    ev.target.value = '';
  });

  // Keyboard
  window.addEventListener('keydown', ev => {
    if (!S.open) return;
    if (ev.key === 'Escape') {
      if ($('#modal-root').innerHTML !== '') { closeModal(); return; }
      post('close');
    }
    if (ev.key === 'Enter' && $('#modal-root').dataset.enterOk === '1' && $('#modal-root')._onEnter) {
      if ($('#modal-root').innerHTML !== '') { ev.preventDefault(); $('#modal-root')._onEnter(); }
    }
  });
}

document.addEventListener('DOMContentLoaded', () => {
  wire();
  initTooltips();
  // Warm the Font Awesome face so the first FA badge renders instantly.
  if (document.fonts && document.fonts.load) {
    document.fonts.load('900 32px "Font Awesome 6 Free"').catch(() => {});
  }
  post('ready');
});

})();
