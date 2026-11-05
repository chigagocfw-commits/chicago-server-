// APEX LOADING: the Creator. Runs on the resource ui_page (mouse works
// here, unlike the real loading screen). Renders the ACTUAL loading screen
// behind the chrome, lets the owner drag widgets, switch models, edit every
// text and list, talk to the AI assistant, simulate the load, and publish
// the design to the server for every future connection.
(function () {
  window.APX = window.APX || {};
  const Store = () => APX.Store;
  const L = (k, f) => APX.L(k, f);

  let open = false;
  let selected = null;
  let undoStack = [];
  let redoStack = [];
  let dirty = false;
  let aiEnabled = true;
  let aiBusy = false;

  const esc = (s) => String(s == null ? '' : s)
    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');

  function el(html) {
    const t = document.createElement('template');
    t.innerHTML = html.trim();
    return t.content.firstChild;
  }
  function icon(name) { return APX.icon ? APX.icon(name) : ''; }

  const stage = () => document.getElementById('screen');

  // ── render pipeline ──────────────────────────────────────────────────────
  const previewData = { name: 'Player', players: 87, max: 128, server: 'YOUR SERVER' };

  function renderAll() {
    APX.renderScreen(stage(), Store().state, previewData);
    wireDrag();
    markSelection();
  }

  function snapshot() {
    undoStack.push(JSON.stringify(Store().state));
    if (undoStack.length > 60) undoStack.shift();
    redoStack = [];
    dirty = true;
    syncDirty();
  }
  function undo() {
    if (!undoStack.length) return;
    redoStack.push(JSON.stringify(Store().state));
    Store().load(undoStack.pop());
    renderAll();
    refreshPanels();
  }
  function redo() {
    if (!redoStack.length) return;
    undoStack.push(JSON.stringify(Store().state));
    Store().load(redoStack.pop());
    renderAll();
    refreshPanels();
  }
  function syncDirty() {
    const b = document.getElementById('cr-dirty');
    if (b) b.hidden = !dirty;
  }

  // ── load simulation (the creator drives progress by hand) ────────────────
  const SIM_STAGES = [
    [0.08, 'Starting engine'], [0.22, 'Preparing the world'],
    [0.38, 'Streaming assets (x64a.rpf'], [0.52, 'Streaming assets) vehicles.meta'],
    [0.66, 'Streaming assets: props_apex.ytd'], [0.78, 'Loading the map'],
    [0.9, 'Finalising the world'], [1, 'Joining the session'],
  ];
  let simTimer = null;
  function simRestart() {
    clearInterval(simTimer);
    APX.progress.target = 0;
    APX.progress.shown = 0;
    APX.progress.done = false;
    APX.progress.logLines = [];
    let i = 0;
    simTimer = setInterval(() => {
      if (i >= SIM_STAGES.length) { clearInterval(simTimer); return; }
      APX.progress.setTarget(SIM_STAGES[i][0]);
      APX.progress.setStage(SIM_STAGES[i][1]);
      APX.progress.pushLog(SIM_STAGES[i][1]);
      i++;
    }, 1100);
  }
  function simSet(f) {
    clearInterval(simTimer);
    APX.progress.target = f;
    APX.progress.shown = f;
    APX.progress.done = f >= 1;
    APX.progress.emit();
  }

  // ── alignment guides ─────────────────────────────────────────────────────
  // A centre crosshair you can see at all times, plus lines that appear while
  // dragging whenever the widget lines up with the middle of the screen or
  // with another widget: and it snaps, so "almost centred" stops happening.
  // Hold ALT while dragging to place something freely.
  const SNAP_TOL = 7;                       // px: how close counts as aligned
  const clampA = (v) => Math.min(0.985, Math.max(0.015, v));

  const guides = {
    on: true,

    load() {
      try { this.on = localStorage.getItem('apex_loading:guides') !== '0'; } catch (e) { this.on = true; }
    },
    save() { try { localStorage.setItem('apex_loading:guides', this.on ? '1' : '0'); } catch (e) {} },

    node() { return document.getElementById('cr-guides'); },

    sync() {
      const g = this.node();
      if (g) g.classList.toggle('on', this.on);
      const b = document.getElementById('cr-guides-btn');
      if (b) b.classList.toggle('on', this.on);
    },

    toggle() { this.on = !this.on; this.save(); this.sync(); this.clear(); },

    // the lines that only exist during a drag
    draw(lines) {
      const g = this.node();
      if (!g) return;
      const dyn = g.querySelector('.cg-dyn');
      dyn.innerHTML = '';
      for (const ln of lines) {
        const i = document.createElement('i');
        i.className = 'cg-line cg-' + ln.axis + (ln.mid ? ' cg-mid' : ' cg-obj');
        if (ln.axis === 'v') i.style.left = Math.round(ln.at) + 'px';
        else i.style.top = Math.round(ln.at) + 'px';
        dyn.appendChild(i);
      }
    },

    // live read-out of the anchor, so "50.0% · 50.0%" is provably centred
    badge(w, r) {
      const g = this.node();
      if (!g) return;
      const b = g.querySelector('.cg-badge');
      b.textContent = (w.pos.ax * 100).toFixed(1) + '%  ·  ' + (w.pos.ay * 100).toFixed(1) + '%';
      b.style.left = Math.round(Math.max(8, Math.min(window.innerWidth - 130, r.left))) + 'px';
      b.style.top = Math.round(Math.max(8, r.top - 30)) + 'px';
      b.classList.add('on');
    },

    clear() {
      const g = this.node();
      if (!g) return;
      g.querySelector('.cg-dyn').innerHTML = '';
      g.querySelector('.cg-badge').classList.remove('on');
    },
  };
  guides.load();

  // ⚠ How far one unit of `ax` actually moves a widget: left is ax*100% of the
  // SCREEN while the transform pulls back ax*100% of the WIDGET, so the travel
  // is ax*(screen - widget), not ax*screen. Every pixel↔fraction conversion
  // has to use this or the widget drifts behind the pointer and "centred"
  // lands a pixel or two off.
  const travelX = (rect) => Math.max(1, window.innerWidth - rect.width);
  const travelY = (rect) => Math.max(1, window.innerHeight - rect.height);

  // Snaps the dragged widget to the screen centre and to the other widgets.
  function snapWidget(node, w, disabled) {
    if (!guides.on || disabled) return [];
    const W = window.innerWidth, H = window.innerHeight;
    const r = node.getBoundingClientRect();

    const tx = [{ v: W / 2, mid: true }];
    const ty = [{ v: H / 2, mid: true }];
    stage().querySelectorAll('.ls-widget').forEach((other) => {
      if (other === node) return;
      const o = other.getBoundingClientRect();
      if (!o.width && !o.height) return;
      tx.push({ v: o.left }, { v: o.left + o.width / 2 }, { v: o.right });
      ty.push({ v: o.top }, { v: o.top + o.height / 2 }, { v: o.bottom });
    });

    // the widget offers three edges per axis; the closest pairing wins
    const pick = (points, targets) => {
      let best = null;
      for (const p of points) {
        for (const t of targets) {
          const d = t.v - p;
          if (Math.abs(d) <= SNAP_TOL && (!best || Math.abs(d) < Math.abs(best.d))) {
            best = { d: d, at: t.v, mid: !!t.mid };
          }
        }
      }
      return best;
    };

    const bx = pick([r.left, r.left + r.width / 2, r.right], tx);
    const by = pick([r.top, r.top + r.height / 2, r.bottom], ty);
    const lines = [];
    if (bx) { w.pos.ax = clampA(w.pos.ax + bx.d / travelX(r)); lines.push({ axis: 'v', at: bx.at, mid: bx.mid }); }
    if (by) { w.pos.ay = clampA(w.pos.ay + by.d / travelY(r)); lines.push({ axis: 'h', at: by.at, mid: by.mid }); }
    if (bx || by) APX.place(node, w);
    return lines;
  }

  // ── widget dragging (anchor fractions, fully responsive) ────────────────
  function wireDrag() {
    stage().querySelectorAll('.ls-widget').forEach((node) => {
      node.addEventListener('pointerdown', (e) => {
        if (!open) return;
        e.preventDefault();
        const id = node.dataset.id;
        selectWidget(id);
        const w = Store().get('widgets.' + id);
        const startX = e.clientX, startY = e.clientY;
        const startAx = w.pos.ax, startAy = w.pos.ay;
        // measured once: the widget's size decides how much travel one unit
        // of ax/ay buys, and that is what makes it track the pointer exactly
        const r0 = node.getBoundingClientRect();
        const tX = travelX(r0), tY = travelY(r0);
        let moved = false;
        const onMove = (ev) => {
          const dax = (ev.clientX - startX) / tX;
          const day = (ev.clientY - startY) / tY;
          if (!moved && (Math.abs(dax) > 0.002 || Math.abs(day) > 0.002)) {
            moved = true;
            snapshot();
          }
          if (!moved) return;
          w.pos.ax = clampA(startAx + dax);
          w.pos.ay = clampA(startAy + day);
          APX.place(node, w);
          // snap AFTER the free move, so the correction is measured against
          // where the pointer actually put the widget
          guides.draw(snapWidget(node, w, ev.altKey));
          guides.badge(w, node.getBoundingClientRect());
        };
        const onUp = () => {
          document.removeEventListener('pointermove', onMove);
          document.removeEventListener('pointerup', onUp);
          guides.clear();
          if (moved) dodgeInspector();   // it may have landed under a panel
        };
        document.addEventListener('pointermove', onMove);
        document.addEventListener('pointerup', onUp);
      });
      node.addEventListener('wheel', (e) => {
        if (!open) return;
        const id = node.dataset.id;
        if (selected !== id) return;
        e.preventDefault();
        const w = Store().get('widgets.' + id);
        snapshot();
        w.scale = Math.min(1.8, Math.max(0.5, (w.scale || 1) + (e.deltaY < 0 ? 0.05 : -0.05)));
        APX.place(node, w);
      }, { passive: false });
    });
  }

  function markSelection() {
    stage().querySelectorAll('.ls-widget').forEach((n) => {
      n.classList.toggle('sel', n.dataset.id === selected);
    });
  }

  function selectWidget(id) {
    selected = id;
    markSelection();
    renderInspector();
    // synchronous on purpose: getBoundingClientRect forces the layout we need,
    // and rAF is not dependable here (same lesson as the progress loop)
    dodgeInspector();
  }

  // ── chrome ───────────────────────────────────────────────────────────────
  let chrome = null;
  let activeTab = 'elements';

  function buildChrome() {
    if (chrome) return;
    chrome = el(
      '<div id="creator">' +
      '<div class="cr-top">' +
      '<div class="cr-brand">' + icon('image') + '<b>APEX LOADING</b><span class="cr-tag mono">' +
      esc(L('cr_creator', 'CREATOR')) + '</span><span id="cr-dirty" class="cr-dirty mono" hidden>' +
      esc(L('cr_unsaved', 'UNSAVED')) + '</span></div>' +
      '<div class="cr-actions">' +
      '<button class="cr-btn ghost" id="cr-undo" title="Undo">' + icon('undo') + '</button>' +
      '<button class="cr-btn ghost" id="cr-redo" title="Redo">' + icon('redo') + '</button>' +
      '<span class="cr-sep"></span>' +
      '<button class="cr-btn ghost" id="cr-guides-btn" title="' +
      esc(L('cr_guides_hint', 'Alignment guides: centre lines and snapping (ALT while dragging = free)')) + '">' +
      icon('crosshair') + '<span class="kcap mono">G</span></button>' +
      '<button class="cr-btn ghost" id="cr-hide" title="' +
      esc(L('cr_hide_hint', 'Hide the panels so you can reach any widget')) + '">' +
      icon('eyeOff') + '<span class="kcap mono">H</span></button>' +
      '<span class="cr-sep"></span>' +
      '<button class="cr-btn ghost" id="cr-discard">' + esc(L('cr_discard', 'Discard')) + '</button>' +
      '<button class="cr-btn primary" id="cr-save">' + esc(L('cr_save', 'Save & Publish')) + '</button>' +
      '</div></div>' +
      '<div class="cr-rail">' +
      railBtn('elements', 'layers', L('tab_elements', 'Elements')) +
      railBtn('texts', 'code', L('tab_texts', 'Texts')) +
      railBtn('background', 'image', L('tab_background', 'Background')) +
      railBtn('music', 'music', L('tab_music', 'Music')) +
      railBtn('ai', 'sparkles', L('tab_ai', 'AI')) +
      railBtn('theme', 'palette', L('tab_theme', 'Theme')) +
      railBtn('presets', 'wand', L('tab_presets', 'Presets')) +
      railBtn('settings', 'settings', L('tab_settings', 'Settings')) +
      '</div>' +
      // the guide overlay sits under the panels and never takes the pointer
      '<div id="cr-guides" class="cr-guides">' +
      '<i class="cg-line cg-v cg-axis"></i><i class="cg-line cg-h cg-axis"></i>' +
      '<div class="cg-dyn"></div><div class="cg-badge mono"></div>' +
      '</div>' +
      '<div class="cr-panel" id="cr-panel"></div>' +
      '<div class="cr-inspector" id="cr-inspector" hidden></div>' +
      '<div class="cr-sim">' +
      '<span class="cr-simgrip" title="' + esc(L('cr_grip', 'drag · double-click to reset')) + '"><i></i></span>' +
      '<button class="cr-btn ghost" id="sim-replay" title="' + esc(L('sim_replay', 'Replay the load')) + '">' +
      icon('reset') + '</button>' +
      '<input type="range" id="sim-slider" min="0" max="100" value="0">' +
      '<b class="mono" id="sim-pct">0%</b>' +
      '</div>' +
      '</div>');
    document.body.appendChild(chrome);

    chrome.querySelector('#cr-save').addEventListener('click', save);
    chrome.querySelector('#cr-discard').addEventListener('click', () => close(false));
    chrome.querySelector('#cr-undo').addEventListener('click', undo);
    chrome.querySelector('#cr-redo').addEventListener('click', redo);
    chrome.querySelector('#cr-hide').addEventListener('click', () => toggleChrome());
    chrome.querySelector('#cr-guides-btn').addEventListener('click', () => guides.toggle());
    guides.sync();
    chrome.querySelectorAll('.cr-railbtn').forEach((b) => {
      b.addEventListener('click', () => {
        activeTab = b.dataset.tab;
        chrome.querySelectorAll('.cr-railbtn').forEach((x) => x.classList.toggle('on', x === b));
        renderPanel();
      });
    });
    chrome.querySelector('#sim-replay').addEventListener('click', simRestart);
    const slider = chrome.querySelector('#sim-slider');
    slider.addEventListener('input', () => {
      simSet(slider.value / 100);
    });
    APX.progress.onChange((P) => {
      const pct = chrome.querySelector('#sim-pct');
      if (pct) pct.textContent = Math.round(P.shown * 100) + '%';
      if (document.activeElement !== slider) slider.value = Math.round(P.shown * 100);
    }, chrome);   // dies with the chrome when the creator closes
  }

  function railBtn(tab, ic, label) {
    return '<button class="cr-railbtn' + (tab === 'elements' ? ' on' : '') + '" data-tab="' + tab + '">' +
      icon(ic) + '<span>' + esc(label) + '</span></button>';
  }

  // ── movable creator chrome ───────────────────────────────────────────────
  // Every panel can be dragged out of the way by its grip, because the thing
  // being edited lives underneath them.
  const crPos = {
    load() { try { return JSON.parse(localStorage.getItem('apex_loading:crpos') || '{}'); } catch (e) { return {}; } },
    save(p) { try { localStorage.setItem('apex_loading:crpos', JSON.stringify(p)); } catch (e) {} },
    clear() { try { localStorage.removeItem('apex_loading:crpos'); } catch (e) {} },
  };

  function panelKeyOf(node) {
    if (node.classList.contains('cr-top')) return 'top';
    if (node.classList.contains('cr-panel')) return 'panel';
    if (node.classList.contains('cr-sim')) return 'sim';
    return 'ins';
  }

  function pinPanel(node, xPx, yPx) {
    // kill any entrance transition first: otherwise the panel eases towards
    // the pointer instead of following it and the drag feels broken
    node.style.transition = 'none';
    node.style.left = Math.max(0, Math.min(window.innerWidth - 90, xPx)) + 'px';
    node.style.top = Math.max(0, Math.min(window.innerHeight - 50, yPx)) + 'px';
    node.style.right = 'auto';
    node.style.bottom = 'auto';
    node.style.transform = 'none';
  }

  function applyPanelPositions() {
    const stored = crPos.load();
    const map = { top: '.cr-top', panel: '.cr-panel', ins: '.cr-inspector', sim: '.cr-sim' };
    for (const key in map) {
      const node = document.querySelector('#creator ' + map[key]);
      if (node && stored[key] && stored[key].x != null) pinPanel(node, stored[key].x, stored[key].y);
    }
  }

  function resetPanelPositions() {
    crPos.clear();
    document.querySelectorAll('#creator .cr-top, #creator .cr-panel, #creator .cr-inspector, #creator .cr-sim')
      .forEach((node) => {
        ['left', 'top', 'right', 'bottom', 'transform', 'transition'].forEach((p) => node.style.removeProperty(p));
      });
  }

  const GRIPS = '.cr-grip, #creator .cr-brand, #creator .cr-ins-head, #creator .cr-simgrip';
  const PANELS = '.cr-top, .cr-panel, .cr-inspector, .cr-sim';

  // ── keep the chrome off the widget being edited ──────────────────────────
  // The inspector opens on the right, and widgets legitimately live at the
  // screen edges: so selecting a top-right widget used to bury it under the
  // very panel that opened for it, and it became impossible to grab.
  function rectsHit(a, b, pad) {
    pad = pad || 0;
    return !(b.right < a.left - pad || b.left > a.right + pad ||
             b.bottom < a.top - pad || b.top > a.bottom + pad);
  }

  function dodgeInspector() {
    const ins = document.getElementById('cr-inspector');
    if (!ins || ins.hidden || !selected) return;
    // a panel the owner positioned by hand is theirs: never move it
    if (crPos.load().ins) return;

    const node = stage().querySelector('.ls-widget[data-id="' + selected + '"]');
    if (!node) return;
    const w = node.getBoundingClientRect();
    if (!w.width && !w.height) return;

    // reset to the stylesheet slot, then measure
    ['left', 'top', 'right', 'bottom', 'height', 'transform', 'transition']
      .forEach((p) => ins.style.removeProperty(p));
    const base = ins.getBoundingClientRect();
    if (!rectsHit(w, base, 10)) return;   // already clear

    const W = window.innerWidth, H = window.innerHeight;
    const panel = document.querySelector('#creator .cr-panel');
    const panelRight = panel ? panel.getBoundingClientRect().right : 96;

    // candidates, best first: below the widget · above it · the other side
    const cands = [
      { left: base.left, top: w.bottom + 14, h: H - (w.bottom + 14) - 20 },
      { left: base.left, top: 74, h: w.top - 74 - 14 },
      { left: panelRight + 16, top: base.top, h: base.height },
    ];
    for (const c of cands) {
      if (c.h < 260 || c.left < 0 || c.left + base.width > W) continue;
      const test = { left: c.left, right: c.left + base.width, top: c.top, bottom: c.top + c.h };
      if (rectsHit(w, test, 10)) continue;
      ins.style.transition = 'none';
      ins.style.left = Math.round(c.left) + 'px';
      ins.style.top = Math.round(c.top) + 'px';
      ins.style.right = 'auto';
      ins.style.bottom = 'auto';
      ins.style.height = Math.round(c.h) + 'px';
      return;
    }
  }

  // H = hold the whole chrome out of the way, for anything auto-dodge cannot
  // solve (a widget under the elements panel, the top bar, the sim bar…)
  function toggleChrome(force) {
    if (!chrome) return;
    const on = force == null ? !chrome.classList.contains('chrome-hidden') : force;
    chrome.classList.toggle('chrome-hidden', on);
  }

  document.addEventListener('pointerdown', (e) => {
    if (!open) return;
    const grip = e.target.closest(GRIPS);
    if (!grip || e.target.closest('button, input, textarea')) return;
    const node = grip.closest(PANELS);
    if (!node) return;
    e.preventDefault();
    const key = panelKeyOf(node);
    const r = node.getBoundingClientRect();
    const sx = e.clientX, sy = e.clientY;
    const move = (ev) => pinPanel(node, r.left + (ev.clientX - sx), r.top + (ev.clientY - sy));
    const up = () => {
      document.removeEventListener('pointermove', move);
      document.removeEventListener('pointerup', up);
      const r2 = node.getBoundingClientRect();
      const stored = crPos.load();
      stored[key] = { x: Math.round(r2.left), y: Math.round(r2.top) };
      crPos.save(stored);
    };
    document.addEventListener('pointermove', move);
    document.addEventListener('pointerup', up);
  });

  // double-click a grip = that panel goes home
  document.addEventListener('dblclick', (e) => {
    if (!open) return;
    const grip = e.target.closest(GRIPS);
    if (!grip) return;
    const node = grip.closest(PANELS);
    if (!node) return;
    const stored = crPos.load();
    delete stored[panelKeyOf(node)];
    crPos.save(stored);
    ['left', 'top', 'right', 'bottom', 'transform', 'transition'].forEach((p) => node.style.removeProperty(p));
  });

  // hold-to-confirm: destructive buttons need the mouse held down for 900ms,
  // with the fill bar showing the progress (same contract as the HUD creator)
  function makeHoldable(btn, onConfirm) {
    let timer = null;
    btn.addEventListener('mousedown', () => {
      btn.classList.add('holding');
      timer = setTimeout(() => {
        btn.classList.remove('holding');
        onConfirm();
      }, 900);
    });
    const cancel = () => { btn.classList.remove('holding'); clearTimeout(timer); };
    btn.addEventListener('mouseup', cancel);
    btn.addEventListener('mouseleave', cancel);
    return btn;
  }

  // ── panel content per tab ────────────────────────────────────────────────
  function renderPanel() {
    const p = document.getElementById('cr-panel');
    p.innerHTML = '';
    p.appendChild(el('<div class="cr-grip" title="' +
      esc(L('cr_grip', 'drag · double-click to reset')) + '"><i></i></div>'));
    if (activeTab === 'elements') renderElements(p);
    else if (activeTab === 'texts') renderTexts(p);
    else if (activeTab === 'background') renderBackground(grouped(p));
    else if (activeTab === 'music') renderMusic(p);
    else if (activeTab === 'ai') renderAI(p);
    else if (activeTab === 'theme') renderTheme(grouped(p));
    else if (activeTab === 'presets') renderPresets(p);
    else renderSettings(grouped(p));
  }
  function refreshPanels() {
    renderPanel();
    renderInspector();
  }

  function section(t) { return el('<div class="cr-sec mono">' + esc(t) + '</div>'); }

  // ── collapsible groups ───────────────────────────────────────────────────
  // A tab like Texts has 20+ fields; as one flat list it is an endless scroll
  // where you lose the thing you were editing. Groups keep one topic on screen
  // at a time, and the open/closed state survives re-renders.
  const groupOpen = { headline: true, bglayer: true, thaccent: true, exit: true };

  function group(host, id, title, count) {
    const isOpen = !!groupOpen[id];
    const g = el('<div class="cr-group' + (isOpen ? ' open' : '') + '" data-g="' + esc(id) + '">' +
      '<button type="button" class="cr-group-head">' +
      '<span class="cr-group-title mono">' + esc(title) + '</span>' +
      (count ? '<i class="cr-count mono">' + count + '</i>' : '') +
      icon('chevD') + '</button>' +
      '<div class="cr-group-body"></div></div>');
    g.querySelector('.cr-group-head').addEventListener('click', () => {
      groupOpen[id] = !groupOpen[id];
      g.classList.toggle('open', groupOpen[id]);
    });
    host.appendChild(g);
    return g.querySelector('.cr-group-body');
  }

  // A panel stand-in that routes appends into the group opened last, so the
  // existing tab builders only had to swap their section() calls for .group().
  function grouped(panel) {
    let body = null;
    return {
      group(id, title, count) { body = group(panel, id, title, count); },
      appendChild(n) { (body || panel).appendChild(n); },
      querySelectorAll(sel) { return panel.querySelectorAll(sel); },
      querySelector(sel) { return panel.querySelector(sel); },
    };
  }

  function rowToggle(label, value, onChange) {
    const r = el('<div class="cr-row"><span class="cr-lb">' + esc(label) + '</span>' +
      '<button class="cr-switch' + (value ? ' on' : '') + '"><i></i></button></div>');
    r.querySelector('button').addEventListener('click', function () {
      snapshot();
      const now = !this.classList.contains('on');
      this.classList.toggle('on', now);
      onChange(now);
    });
    return r;
  }

  // Sliders stack like the text fields: a long label ("Seconds per slide")
  // otherwise wraps and shoves the track out of line with every other row.
  // Stacked, every track starts and ends on the same pixels down the panel.
  function rowSlider(label, value, min, max, step, onChange, fmt) {
    const r = el('<div class="cr-field cr-row-sl">' +
      '<span class="cr-lb">' + esc(label) + '<b class="cr-val mono">' +
      esc(String(fmt ? fmt(value) : value)) + '</b></span>' +
      '<input type="range" min="' + min + '" max="' + max + '" step="' + step + '" value="' + value + '">' +
      '</div>');
    const input = r.querySelector('input');
    let snapped = false;
    input.addEventListener('input', () => {
      if (!snapped) { snapshot(); snapped = true; }
      const v = parseFloat(input.value);
      r.querySelector('.cr-val').textContent = fmt ? fmt(v) : v;
      onChange(v);
    });
    input.addEventListener('change', () => { snapped = false; });
    return r;
  }

  // text fields stack: a 290px panel cannot fit "Load log caption" AND a
  // usable input on one line: side by side both end up unreadable
  function rowText(label, value, onChange, placeholder) {
    const r = el('<div class="cr-field"><span class="cr-lb">' + esc(label) + '</span>' +
      '<input type="text" spellcheck="false" placeholder="' + esc(placeholder || '') + '"></div>');
    const input = r.querySelector('input');
    input.value = value == null ? '' : value;
    const commit = () => { snapshot(); onChange(input.value); };
    input.addEventListener('change', commit);
    input.addEventListener('keydown', (e) => { if (e.key === 'Enter') { e.preventDefault(); input.blur(); } });
    return r;
  }

  function rowSelect(label, value, options, onChange) {
    let btns = '';
    for (const [v, lb] of options) {
      btns += '<button data-v="' + esc(v) + '" class="' + (v === value ? 'on' : '') + '">' + esc(lb) + '</button>';
    }
    // 3+ choices never fit beside a label in a 336px panel: stack them
    const r = options.length > 2
      ? el('<div class="cr-field"><span class="cr-lb">' + esc(label) + '</span>' +
          '<div class="cr-seg cr-seg-grid">' + btns + '</div></div>')
      : el('<div class="cr-row cr-row-seg"><span class="cr-lb">' + esc(label) + '</span>' +
          '<div class="cr-seg">' + btns + '</div></div>');
    r.querySelectorAll('.cr-seg button').forEach((b) => {
      b.addEventListener('click', () => {
        snapshot();
        r.querySelectorAll('.cr-seg button').forEach((x) => x.classList.remove('on'));
        b.classList.add('on');
        onChange(b.dataset.v);
      });
    });
    return r;
  }

  // ── image input: link OR upload ───────────────────────────────────────────
  // Uploaded art travels INSIDE the design, which is handed to every player on
  // connect: so it is downscaled and re-encoded here rather than shipped at
  // camera resolution. PNG is kept only when the source is a PNG (alpha).
  const IMG_MAXW = 1600;

  function readImageFile(file, done) {
    if (!file || !/^image\//.test(file.type || '')) { done(null); return; }
    const fr = new FileReader();
    fr.onerror = () => done(null);
    fr.onload = () => {
      const img = new Image();
      img.onerror = () => done(null);
      img.onload = () => {
        const k = Math.min(1, IMG_MAXW / (img.width || IMG_MAXW));
        const w = Math.max(1, Math.round(img.width * k));
        const h = Math.max(1, Math.round(img.height * k));
        const c = document.createElement('canvas');
        c.width = w; c.height = h;
        c.getContext('2d').drawImage(img, 0, 0, w, h);
        // WebP keeps the alpha channel and is usually several times smaller
        // than PNG: every byte here is sent to every player on connect, so
        // the smallest encoding that worked wins
        const png = /png$/i.test(file.type);
        let best = null;
        const tryType = (type, q) => {
          try {
            const u = c.toDataURL(type, q);
            if (u.indexOf('data:' + type) === 0 && (!best || u.length < best.length)) best = u;
          } catch (e) {}
        };
        tryType('image/webp', png ? 0.92 : 0.85);
        tryType(png ? 'image/png' : 'image/jpeg', 0.82);
        done(best || fr.result);
      };
      img.src = fr.result;
    };
    fr.readAsDataURL(file);
  }

  function readImageFiles(files, done) {
    const list = Array.prototype.slice.call(files || []).filter((f) => /^image\//.test(f.type || ''));
    if (!list.length) { done([]); return; }
    const out = [];
    let pending = list.length;
    list.forEach((f, i) => readImageFile(f, (url) => {
      if (url) out[i] = url;
      if (--pending === 0) done(out.filter(Boolean));
    }));
  }

  // click, drag & drop, or paste: the same three routes the clothing studio
  // uses, all of which work inside CEF
  function imageDrop(label, multiple, onImages) {
    const z = el('<div class="cr-drop" tabindex="0">' + icon('image') +
      '<b>' + esc(label) + '</b><span>' + esc(L('img_hint', 'click · drop · paste')) + '</span></div>');

    const pick = () => {
      const inp = document.createElement('input');
      inp.type = 'file';
      inp.accept = 'image/*';
      if (multiple) inp.multiple = true;
      inp.addEventListener('change', () => readImageFiles(inp.files, onImages));
      inp.click();
    };
    z.addEventListener('click', pick);
    z.addEventListener('keydown', (e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); pick(); } });
    ['dragenter', 'dragover'].forEach((ev) => z.addEventListener(ev, (e) => {
      e.preventDefault(); e.stopPropagation(); z.classList.add('over');
    }));
    ['dragleave', 'drop'].forEach((ev) => z.addEventListener(ev, (e) => {
      e.preventDefault(); e.stopPropagation(); z.classList.remove('over');
    }));
    z.addEventListener('drop', (e) => {
      const dt = e.dataTransfer;
      if (!dt) return;
      if (dt.files && dt.files.length) { readImageFiles(dt.files, onImages); return; }
      const url = dt.getData('text/uri-list') || dt.getData('text/plain');
      if (url && /^https?:\/\//i.test(url.trim())) onImages([url.trim()]);
    });
    z.addEventListener('paste', (e) => {
      const items = (e.clipboardData && e.clipboardData.items) || [];
      const files = [];
      for (const it of items) if (it.kind === 'file') files.push(it.getAsFile());
      if (files.length) { e.preventDefault(); readImageFiles(files, onImages); }
    });
    return z;
  }

  // ── media library ────────────────────────────────────────────────────────
  // The one delivery method a loading screen cannot refuse: the file lives in
  // the resource, so there is no origin, referrer, CORS or API in the way.
  const media = { files: [], busy: false, pct: 0, listeners: [] };
  // same rule as the screen widgets: a picker belongs to the panel that built
  // it, and panels are rebuilt constantly: drop the ones no longer on screen
  function mediaChanged() {
    media.listeners = media.listeners.filter((l) => l.node.isConnected);
    for (const l of media.listeners.slice()) { try { l.fn(); } catch (e) {} }
  }

  function mediaRefresh() {
    APX.nuiPost('mediaList').catch(() => {});
  }

  // ── hand-over to the game ────────────────────────────────────────────────
  // ⚠⚠ Big payloads never travel in one piece. The page hands them to the
  // game in parts, the game sends them to the server in smaller parts paced
  // under FXServer's netEventSize limit (one oversized event is dropped, and
  // drops the player with it), and the server reassembles and checks them.
  // Progress comes back as upProgress, problems as upFail with the reason.
  const NUI_PART = 32000;     // characters per call into the game
  let upSeq = 0;

  async function handOver(kind, text, meta) {
    const id = kind.charAt(0) + Date.now().toString(36) + '_' + (++upSeq);
    const parts = Math.max(1, Math.ceil(text.length / NUI_PART));
    let r = await APX.nuiPost('upBegin', { kind: kind, id: id, bytes: text.length, parts: parts, meta: meta || {} });
    if (!r || r.ok !== true) throw new Error((r && r.error) || 'the game refused the upload');
    for (let i = 0; i < parts; i++) {
      r = await APX.nuiPost('upPart', { id: id, index: i + 1, data: text.slice(i * NUI_PART, (i + 1) * NUI_PART) });
      if (!r || r.ok !== true) throw new Error((r && r.error) || 'the game lost part of the upload');
    }
    r = await APX.nuiPost('upCommit', { id: id });
    if (!r || r.ok !== true) throw new Error((r && r.error) || 'the game could not send the upload');
    return id;
  }

  const MEDIA_MAX = 24 * 1024 * 1024;

  function mediaFail(msg) {
    media.busy = false;
    media.pct = 0;
    media.upId = null;
    media.done = null;
    mediaChanged();
    toast(msg, true);
  }

  function mediaUpload(file, done) {
    if (media.busy) { toast(L('md_busy', 'One upload at a time.'), true); return; }
    if (file.size > MEDIA_MAX) {
      toast(L('md_big', 'That file is too large: keep it under 24 MB.'), true);
      return;
    }
    media.busy = true;
    media.pct = 0;
    media.upId = null;
    mediaChanged();
    const fr = new FileReader();
    fr.onerror = () => mediaFail(L('md_read', 'Could not read that file.'));
    fr.onload = () => {
      const b64 = String(fr.result || '').split(',')[1] || '';
      if (!b64) { mediaFail(L('md_read', 'Could not read that file.')); return; }
      media.done = done;
      handOver('media', b64, { name: file.name })
        .then((id) => { media.upId = id; })
        .catch((e) => mediaFail(L('md_fail', 'Upload failed.') + ' ' + e.message));
    };
    fr.readAsDataURL(file);
  }

  function mediaPicker(accept, label, onPick) {
    const box = el('<div class="cr-media"></div>');

    const zone = el('<div class="cr-drop" tabindex="0">' + icon('save') +
      '<b>' + esc(label) + '</b><span>' + esc(L('md_hint', 'click or drop a file')) + '</span>' +
      '<i class="cr-drop-bar"><b></b></i></div>');
    const pick = () => {
      const inp = document.createElement('input');
      inp.type = 'file';
      inp.accept = accept;
      inp.addEventListener('change', () => { if (inp.files && inp.files[0]) mediaUpload(inp.files[0]); });
      inp.click();
    };
    zone.addEventListener('click', pick);
    zone.addEventListener('keydown', (e) => { if (e.key === 'Enter') { e.preventDefault(); pick(); } });
    ['dragenter', 'dragover'].forEach((ev) => zone.addEventListener(ev, (e) => {
      e.preventDefault(); e.stopPropagation(); zone.classList.add('over');
    }));
    ['dragleave', 'drop'].forEach((ev) => zone.addEventListener(ev, (e) => {
      e.preventDefault(); e.stopPropagation(); zone.classList.remove('over');
    }));
    zone.addEventListener('drop', (e) => {
      if (e.dataTransfer && e.dataTransfer.files && e.dataTransfer.files[0]) {
        mediaUpload(e.dataTransfer.files[0]);
      }
    });
    box.appendChild(zone);

    const list = el('<div class="cr-medialist"></div>');
    box.appendChild(list);

    const paint = () => {
      zone.classList.toggle('busy', media.busy);
      zone.querySelector('.cr-drop-bar b').style.width = media.pct + '%';
      list.innerHTML = '';
      if (!media.files.length) {
        list.appendChild(el('<p class="cr-note">' + esc(L('md_empty',
          'Nothing uploaded yet. Files land in the resource’s web/media/ folder.')) + '</p>'));
        return;
      }
      for (const f of media.files) {
        const row = el('<div class="cr-mediarow"><span class="cr-media-name mono">' + esc(f.name) +
          '</span><span class="cr-media-size mono">' + (f.size ? Math.round(f.size / 1024) + ' KB' : '') +
          '</span><button class="cr-media-use">' + esc(L('md_use', 'Use')) + '</button>' +
          '<button class="cr-img-x" title="' + esc(L('img_remove', 'Remove')) + '">' + icon('close') + '</button></div>');
        row.querySelector('.cr-media-use').addEventListener('click', () => {
          snapshot();
          onPick('media/' + f.name);
        });
        row.querySelector('.cr-img-x').addEventListener('click', () => {
          APX.nuiPost('mediaDelete', { name: f.name }).catch(() => {});
        });
        list.appendChild(row);
      }
    };
    media.listeners.push({ fn: paint, node: box });
    paint();
    return box;
  }

  // mirrors the detection in bg.js so the panel names what will actually play
  function videoKind(url) {
    url = String(url || '').trim();
    if (!url) return { ok: false, text: L('vid_none', 'Paste a YouTube, Vimeo or direct .mp4 link.') };
    if (/\.(mp4|webm|ogv|ogg|mov|m4v)(\?|#|$)/i.test(url)) {
      return { ok: true, text: L('vid_file', 'Direct video file: plays natively.') };
    }
    if (/(?:youtube(?:-nocookie)?\.com|youtu\.be)/i.test(url)) {
      return { ok: true, text: L('vid_yt', 'YouTube: plays through the built-in bridge, in this ' +
        'preview and on the real loading screen. If it ever cannot start, players see your ' +
        'gradient instead of an error.') };
    }
    if (/vimeo\.com/i.test(url)) return { ok: true, text: L('vid_vimeo', 'Vimeo: background player.') };
    if (/^https?:\/\//i.test(url)) {
      return { ok: true, text: L('vid_other', 'Other platform: embedded as given. Make sure it allows embedding.') };
    }
    return { ok: false, text: L('vid_bad', 'That does not look like a video link.') };
  }

  const isData = (u) => /^data:/i.test(String(u || ''));
  function prettyUrl(u) {
    u = String(u || '');
    if (isData(u)) return L('img_uploaded', 'uploaded') + ' · ' + Math.round(u.length / 1365) + ' KB';
    return u.length > 46 ? u.slice(0, 22) + '…' + u.slice(-20) : u;
  }

  // colour: swatches + hex field (native colour input is dead in CEF)
  const SWATCHES = ['#E32636', '#8B101D', '#FF3B6B', '#C084FC', '#34D399', '#F43F5E', '#7DD3FC', '#F5C542', '#FFFFFF'];
  function rowColor(label, value, onChange) {
    let sw = '';
    for (const c of SWATCHES) {
      sw += '<i data-c="' + c + '" style="background:' + c + '" class="' + (c.toLowerCase() === String(value).toLowerCase() ? 'on' : '') + '"></i>';
    }
    const r = el('<div class="cr-color"><span class="cr-lb">' + esc(label) + '</span>' +
      '<div class="cr-swatches">' + sw + '</div>' +
      '<input class="mono" type="text" spellcheck="false" maxlength="7"></div>');
    const input = r.querySelector('input');
    input.value = value || '';
    r.querySelectorAll('.cr-swatches i').forEach((i) => {
      i.addEventListener('click', () => {
        snapshot();
        input.value = i.dataset.c;
        onChange(i.dataset.c);
        r.querySelectorAll('.cr-swatches i').forEach((x) => x.classList.toggle('on', x === i));
      });
    });
    input.addEventListener('change', () => {
      let v = input.value.trim();
      if (!v.startsWith('#')) v = '#' + v;
      if (/^#[0-9a-f]{6}$/i.test(v)) { snapshot(); onChange(v); }
    });
    return r;
  }

  // list editor: one entry per line, the box grows with the content and a
  // live counter shows how many entries the design actually has
  function rowArea(label, value, onChange, hint) {
    const r = el('<div class="cr-field cr-area">' +
      '<span class="cr-lb">' + esc(label) + '<i class="cr-count mono"></i></span>' +
      (hint ? '<em class="cr-hint">' + esc(hint) + '</em>' : '') +
      '<textarea spellcheck="false" rows="4"></textarea></div>');
    const ta = r.querySelector('textarea');
    const counter = r.querySelector('.cr-count');
    ta.value = value;
    const grow = () => {
      ta.style.height = 'auto';
      ta.style.height = Math.min(320, Math.max(76, ta.scrollHeight + 2)) + 'px';
      const n = ta.value.split('\n').filter((s) => s.trim()).length;
      counter.textContent = n ? n : '';
    };
    grow();
    requestAnimationFrame(grow);   // once the panel has its real width
    ta.addEventListener('input', grow);
    ta.addEventListener('change', () => { snapshot(); onChange(ta.value); grow(); });
    return r;
  }

  // ── Elements tab ─────────────────────────────────────────────────────────
  function renderElements(p) {
    p.appendChild(section(L('sec_elements', 'ELEMENTS')));
    for (const id in APX.widgets) {
      const w = Store().get('widgets.' + id);
      if (!w) continue;
      const row = el('<div class="cr-el' + (w.on ? '' : ' off') + (selected === id ? ' sel' : '') + '">' +
        '<b>' + esc(L('el_' + id, APX.widgets[id].label)) + '</b>' +
        '<button class="cr-el-eye">' + icon(w.on ? 'eye' : 'eyeOff') + '</button></div>');
      row.addEventListener('click', (e) => {
        if (e.target.closest('.cr-el-eye')) return;
        selectWidget(id);
        renderPanel();
      });
      row.querySelector('.cr-el-eye').addEventListener('click', () => {
        snapshot();
        Store().set('widgets.' + id + '.on', !w.on);
        renderAll();
        renderPanel();
      });
      p.appendChild(row);
    }
    p.appendChild(el('<p class="cr-note">' + esc(L('cr_drag_hint',
      'Drag widgets on the screen · scroll over the selected one to scale it · ' +
      'G toggles the alignment guides, ALT while dragging ignores them')) + '</p>'));
  }

  // ── Texts tab ────────────────────────────────────────────────────────────
  // Every string a player can read, in one place: including the ones that
  // used to be hardcoded (captions and the load stage names).
  function renderTexts(p) {
    const W = (id) => Store().get('widgets.' + id);
    const T = Store().get('text');

    let b = group(p, 'headline', L('sec_headline', 'HEADLINE'));
    const t = W('title');
    b.appendChild(rowText(L('f_text', 'Title'), t.text, (v) => { t.text = v; renderAll(); }));
    b.appendChild(rowText(L('f_sub', 'Subtitle'), t.sub, (v) => { t.sub = v; renderAll(); }));
    const g = W('greeting');
    b.appendChild(rowText(L('el_greeting', 'Greeting'), g.text, (v) => { g.text = v; renderAll(); }));
    b.appendChild(el('<p class="cr-note">' + esc(L('tx_greet_note',
      "The player's own name is added after this automatically.")) + '</p>'));

    b = group(p, 'labels', L('sec_labels', 'ON-SCREEN LABELS'), 6);
    const lab = [
      ['enterHint', L('tx_enter', 'Enter prompt'), 'PRESS ENTER TO JOIN'],
      ['tipCap', L('tx_tipcap', 'Tip caption'), 'TIP'],
      ['nowPlaying', L('tx_nowplaying', 'Now playing'), 'NOW PLAYING'],
      ['noMusic', L('tx_nomusic', 'No music'), 'No music'],
      ['online', L('tx_online', 'Online word'), 'online'],
      ['consoleCap', L('tx_console', 'Load log caption'), 'LOADING'],
    ];
    for (const [key, label, def] of lab) {
      b.appendChild(rowText(label, T[key], (v) => { T[key] = v || def; renderAll(); }, def));
    }

    b = group(p, 'stages', L('sec_stages', 'LOAD STAGES'), 7);
    b.appendChild(el('<p class="cr-note">' + esc(L('tx_stage_note',
      'What the progress widget says at each step of the real load.')) + '</p>'));
    const stages = [
      ['connecting', L('tx_st_connect', 'Connecting'), 'Connecting'],
      ['core', L('tx_st_core', 'Engine'), 'Starting engine'],
      ['beforeMap', L('tx_st_before', 'Before map'), 'Preparing the world'],
      ['streaming', L('tx_st_stream', 'Streaming'), 'Streaming assets'],
      ['map', L('tx_st_map', 'Map'), 'Loading the map'],
      ['afterMap', L('tx_st_after', 'After map'), 'Finalising the world'],
      ['session', L('tx_st_session', 'Session'), 'Joining the session'],
    ];
    for (const [key, label, def] of stages) {
      b.appendChild(rowText(label, T.stages[key], (v) => { T.stages[key] = v || def; renderAll(); }, def));
    }

    // one group per list, so a long tips list never buries the staff list
    const tips = W('tips');
    b = group(p, 'l-tips', L('f_tips', 'Tips'));
    b.appendChild(rowArea(L('f_tips', 'Tips'), (tips.items || []).join('\n'),
      (v) => { tips.items = v.split('\n').map((s) => s.trim()).filter(Boolean); renderAll(); },
      L('f_perline', 'One per line')));

    const news = W('news');
    b = group(p, 'l-news', L('el_news', 'News'));
    b.appendChild(rowText(L('tx_news_title', 'News title'), news.title, (v) => { news.title = v; renderAll(); }));
    b.appendChild(rowArea(L('f_news', 'News items'),
      (news.items || []).map((i) => (i.tag || '') + ' | ' + (i.text || '')).join('\n'),
      (v) => { news.items = splitPairs(v, 'tag', 'text'); renderAll(); }, 'TAG | text'));

    const staff = W('staff');
    b = group(p, 'l-staff', L('el_staff', 'Staff'));
    b.appendChild(rowText(L('tx_staff_title', 'Staff title'), staff.title, (v) => { staff.title = v; renderAll(); }));
    b.appendChild(rowArea(L('f_staff', 'Staff'),
      (staff.items || []).map((i) => (i.name || '') + ' | ' + (i.role || '')).join('\n'),
      (v) => { staff.items = splitPairs(v, 'name', 'role'); renderAll(); }, 'Name | Role'));

    const soc = W('socials');
    b = group(p, 'l-socials', L('el_socials', 'Socials'));
    b.appendChild(rowArea(L('f_socials', 'Links'),
      (soc.items || []).map((i) => (i.icon || 'globe') + ' | ' + (i.label || '')).join('\n'),
      (v) => { soc.items = splitPairs(v, 'icon', 'label'); renderAll(); }, 'discord | discord.gg/you'));

    const kb = W('keybinds');
    b = group(p, 'l-keys', L('el_keybinds', 'Keys help'));
    b.appendChild(rowArea(L('f_keys', 'Keys help'),
      (kb.items || []).map((i) => (i.key || '') + ' | ' + (i.label || '')).join('\n'),
      (v) => { kb.items = splitPairs(v, 'key', 'label'); renderAll(); }, 'M | mute music'));
  }

  // "a | b" per line → [{keyA: a, keyB: b}]
  function splitPairs(text, keyA, keyB) {
    return text.split('\n').map((s) => s.trim()).filter(Boolean).map((line) => {
      const i = line.indexOf('|');
      const o = {};
      if (i < 0) { o[keyA] = line; o[keyB] = ''; }
      else { o[keyA] = line.slice(0, i).trim(); o[keyB] = line.slice(i + 1).trim(); }
      return o;
    });
  }

  // ── Background tab ───────────────────────────────────────────────────────
  function renderBackground(p) {
    const bg = Store().get('background');
    p.group('bglayer', L('sec_bgmode', 'BACKGROUND'));
    p.appendChild(rowSelect(L('bg_mode', 'Mode'), bg.mode, [
      ['gradient', L('bg_gradient', 'Gradient')], ['slideshow', L('bg_slides', 'Slides')],
      ['video', L('bg_video', 'Video')], ['solid', L('bg_solid', 'Solid')],
    ], (v) => { bg.mode = v; renderAll(); renderPanel(); }));

    if (bg.mode === 'gradient') {
      p.appendChild(rowColor(L('bg_from', 'From'), bg.gradient.from, (v) => { bg.gradient.from = v; renderAll(); }));
      p.appendChild(rowColor(L('bg_to', 'To'), bg.gradient.to, (v) => { bg.gradient.to = v; renderAll(); }));
      p.appendChild(rowSlider(L('bg_angle', 'Angle'), bg.gradient.angle, 0, 360, 5,
        (v) => { bg.gradient.angle = v; renderAll(); }, (v) => v + '°'));
      p.appendChild(rowToggle(L('bg_animated', 'Animated'), bg.gradient.animated !== false,
        (v) => { bg.gradient.animated = v; renderAll(); }));
    } else if (bg.mode === 'solid') {
      p.appendChild(rowColor(L('bg_color', 'Color'), bg.solid, (v) => { bg.solid = v; renderAll(); }));
    } else if (bg.mode === 'slideshow') {
      // thumbnails + per-slide remove, then the two ways to add one
      const list = el('<div class="cr-imgs"></div>');
      (bg.images || []).forEach((it, i) => {
        const card = el('<div class="cr-img"><i class="cr-img-thumb"></i>' +
          '<span class="cr-img-name mono">' + esc(prettyUrl(it.url)) + '</span>' +
          '<button class="cr-img-x" title="' + esc(L('img_remove', 'Remove')) + '">' + icon('close') + '</button></div>');
        card.querySelector('.cr-img-thumb').style.backgroundImage =
          'url("' + String(it.url || '').replace(/"/g, '') + '")';
        card.querySelector('.cr-img-x').addEventListener('click', () => {
          snapshot();
          bg.images.splice(i, 1);
          renderAll();
          renderPanel();
        });
        list.appendChild(card);
      });
      if ((bg.images || []).length) p.appendChild(list);

      p.appendChild(imageDrop(L('img_add', 'Add images'), true, (urls) => {
        if (!urls.length) return;
        snapshot();
        bg.images = (bg.images || []).concat(urls.map((u) => ({ url: u })));
        renderAll();
        renderPanel();
      }));
      const addUrl = rowText(L('img_addurl', '…or paste an image link'), '', (v) => {
        v = String(v || '').trim();
        if (!v) return;
        bg.images = (bg.images || []).concat([{ url: v }]);
        renderAll();
        renderPanel();
      }, 'https://…  ·  media/shot.png');
      p.appendChild(addUrl);
      p.appendChild(rowSlider(L('bg_interval', 'Seconds per slide'), bg.interval, 4, 20, 1,
        (v) => { bg.interval = v; renderAll(); }, (v) => v + 's'));
      p.appendChild(rowSelect(L('bg_transition', 'Transition'), bg.transition || 'fade', [
        ['fade', L('bg_tr_fade', 'Fade')], ['slide', L('bg_tr_slide', 'Slide')],
        ['zoom', L('bg_tr_zoom', 'Zoom')],
      ], (v) => { bg.transition = v; renderAll(); }));
      p.appendChild(rowToggle(L('bg_kenburns', 'Ken Burns motion'), bg.kenburns !== false,
        (v) => { bg.kenburns = v; renderAll(); }));
    } else if (bg.mode === 'video') {
      p.appendChild(mediaPicker('video/*', L('md_upvideo', 'Upload a video'), (path) => {
        bg.video.url = path;
        renderAll();
        renderPanel();
      }));
      p.appendChild(rowText(L('bg_videourl', 'Video URL'), bg.video.url,
        (v) => { bg.video.url = v; renderAll(); renderPanel(); },
        'https://youtube.com/watch?v=…'));
      // tell the owner what the link was understood as, so a typo is obvious
      const kind = videoKind(bg.video.url);
      p.appendChild(el('<p class="cr-note cr-vidkind' + (kind.ok ? '' : ' bad') + '">' +
        esc(kind.text) + '</p>'));
      p.appendChild(rowToggle(L('bg_vidloop', 'Loop'), bg.video.loop !== false,
        (v) => { bg.video.loop = v; renderAll(); }));
      p.appendChild(rowToggle(L('bg_vidaudio', 'Play the video sound'), bg.video.audio === true,
        (v) => { bg.video.audio = v; renderAll(); renderPanel(); }));
      if (bg.video.audio) {
        p.appendChild(rowSlider(L('bg_vidvol', 'Video volume'),
          bg.video.volume == null ? 0.6 : bg.video.volume, 0, 1, 0.05,
          (v) => { bg.video.volume = v; renderAll(); }, (v) => Math.round(v * 100) + '%'));
        p.appendChild(el('<p class="cr-note">' + esc(L('bg_vidaudio_note',
          'Turn the music player off, or your players hear both at once.')) + '</p>'));
      }
    }

    p.group('particles', L('sec_particles', 'PARTICLES'));
    const PT = bg.particles;
    p.appendChild(rowSelect(L('pt_mode', 'Effect'), PT.mode, [
      ['none', '-'], ['dust', L('pt_dust', 'Dust')], ['stars', L('pt_stars', 'Stars')],
      ['bokeh', L('pt_bokeh', 'Bokeh')], ['shapes', L('pt_shapes', 'Shapes')],
      ['embers', L('pt_embers', 'Embers')], ['fireflies', L('pt_fire', 'Fireflies')],
      ['snow', L('pt_snow', 'Snow')], ['rain', L('pt_rain', 'Rain')],
    ], (v) => { PT.mode = v; renderAll(); }));
    if (PT.mode && PT.mode !== 'none') {
      p.appendChild(rowSlider(L('pt_density', 'Density'), PT.density, 0.1, 1, 0.05,
        (v) => { PT.density = v; renderAll(); }, (v) => Math.round(v * 100) + '%'));
      p.appendChild(rowSlider(L('pt_speed', 'Speed'), PT.speed == null ? 1 : PT.speed, 0.2, 3, 0.1,
        (v) => { PT.speed = v; renderAll(); }, (v) => v.toFixed(1) + '×'));
      p.appendChild(rowSelect(L('pt_color', 'Colour'), (PT.color || 'accent').charAt(0) === '#' ? 'custom' : PT.color, [
        ['accent', L('pt_c_accent', 'Accent')], ['white', L('pt_c_white', 'White')],
        ['custom', L('pt_c_custom', 'Custom')],
      ], (v) => {
        PT.color = v === 'custom' ? (Store().get('theme.accent') || '#E32636') : v;
        renderAll();
        renderPanel();
      }));
      if ((PT.color || '').charAt(0) === '#') {
        p.appendChild(rowColor(L('pt_c_pick', 'Particle colour'), PT.color,
          (v) => { PT.color = v; renderAll(); }));
      }
    }

    p.group('overlay', L('sec_overlay', 'OVERLAY'));
    const O = bg.overlay;
    p.appendChild(rowSlider(L('ov_dim', 'Darken'), O.dim, 0, 0.8, 0.05,
      (v) => { O.dim = v; renderAll(); }, (v) => Math.round(v * 100) + '%'));
    p.appendChild(rowSlider(L('ov_vignette', 'Vignette'), O.vignette, 0, 1, 0.05,
      (v) => { O.vignette = v; renderAll(); }, (v) => Math.round(v * 100) + '%'));
    O.tint = O.tint || { color: '#E32636', amount: 0 };
    p.appendChild(rowSlider(L('ov_tint', 'Colour wash'), O.tint.amount, 0, 0.6, 0.02,
      (v) => { O.tint.amount = v; renderAll(); }, (v) => Math.round(v * 100) + '%'));
    if (O.tint.amount > 0) {
      p.appendChild(rowColor(L('ov_tint_c', 'Wash colour'), O.tint.color,
        (v) => { O.tint.color = v; renderAll(); }));
    }
    p.appendChild(rowToggle(L('ov_sweep', 'Light sweep'), !!O.sweep, (v) => { O.sweep = v; renderAll(); }));
    p.appendChild(rowToggle(L('ov_grain', 'Film grain'), !!O.grain, (v) => { O.grain = v; renderAll(); }));
    p.appendChild(rowToggle(L('ov_scan', 'Scanlines'), !!O.scanlines, (v) => { O.scanlines = v; renderAll(); }));
    p.appendChild(rowToggle(L('ov_bars', 'Cinema bars'), !!O.bars, (v) => { O.bars = v; renderAll(); }));
  }

  // ── Music tab ────────────────────────────────────────────────────────────
  function renderMusic(p) {
    const m = Store().get('music');
    p.appendChild(section(L('sec_music', 'MUSIC')));
    p.appendChild(rowToggle(L('mu_enabled', 'Enabled'), m.enabled !== false,
      (v) => { m.enabled = v; restartMusic(); }));
    p.appendChild(mediaPicker('audio/*', L('md_upaudio', 'Upload a track'), (path) => {
      const name = path.replace('media/', '').replace(/\.[^.]+$/, '');
      m.tracks = (m.tracks || []).concat([{ title: name, url: path }]);
      restartMusic();
      renderAll();
      renderPanel();
    }));
    p.appendChild(rowArea(L('mu_tracks', 'Playlist'),
      (m.tracks || []).map((t) => (t.title || '') + ' | ' + (t.url || '')).join('\n'),
      (v) => {
        m.tracks = v.split('\n').map((s) => s.trim()).filter(Boolean).map((line) => {
          const i = line.indexOf('|');
          if (i < 0) return { title: 'Track', url: line.trim() };
          return { title: line.slice(0, i).trim() || 'Track', url: line.slice(i + 1).trim() };
        });
        restartMusic();
      }, L('mu_tracks_hint', 'One per line:  Title | link')));
    p.appendChild(el('<p class="cr-note">' + esc(L('mu_tracks_note',
      'Direct .mp3/.ogg links, files dropped in the resource\u2019s web/media/ folder (write media/song.mp3), and YouTube links all play \u2014 YouTube goes through the built-in bridge, and a track that cannot start is skipped automatically.')) + '</p>'));
    p.appendChild(rowSlider(L('mu_volume', 'Volume'), m.volume, 0, 1, 0.05,
      (v) => { m.volume = v; if (APX.music.audio) APX.music.audio.volume = v; },
      (v) => Math.round(v * 100) + '%'));
    p.appendChild(rowToggle(L('mu_shuffle', 'Shuffle'), !!m.shuffle, (v) => { m.shuffle = v; restartMusic(); }));
    p.appendChild(rowToggle(L('mu_viz', 'Visualizer'), m.visualizer !== false, (v) => { m.visualizer = v; }));
    p.appendChild(rowToggle(L('mu_keys', 'Player can control the sound'), m.keys !== false,
      (v) => { m.keys = v; renderPanel(); }));
    if (m.keys !== false) {
      p.appendChild(rowToggle(L('mu_osd', 'Show the volume readout'), m.osd !== false, (v) => { m.osd = v; }));
    }
    p.appendChild(el('<p class="cr-note">' + esc(L('mu_note',
      'On the real loading screen players control it with ↑/↓ volume, M mute, N next.')) + '</p>'));
  }

  // ── AI tab ───────────────────────────────────────────────────────────────
  // ── AI tab ───────────────────────────────────────────────────────────────
  // A conversation, not a form: the assistant says what it changed, the panel
  // shows how many paths it touched, and every answer can be taken straight
  // back: so trying an idea costs nothing.
  const AI_IDEAS = [
    ['ai_i_cyber', 'Cyberpunk neon', 'Dark cyberpunk city: purple and cyan neon, heavy vignette, drifting embers, glitch title.'],
    ['ai_i_min', 'Clean & minimal', 'Minimal and calm: near-black background, one soft gradient, no particles, thin progress bar, small centred title.'],
    ['ai_i_winter', 'Winter night', 'Cold winter night: deep blue gradient, snow particles, frosty white accent, cinematic bars.'],
    ['ai_i_lux', 'Luxury gold', 'Luxury private server: black background, gold accent, subtle dust, serif title, slow elegant entrance.'],
    ['ai_i_race', 'Racing energy', 'High-energy racing: orange accent, fast light sweep, bold uppercase title, segments progress bar.'],
    ['ai_i_tips', 'Better tips', 'Rewrite the tips into eight short rules that actually help a new roleplayer, and show them as a ticker.'],
  ];

  function renderAI(p) {
    const box = el('<div class="cr-ai">' +
      '<div class="cr-ai-head">' +
      '<span class="cr-ai-orb">' + icon('sparkles') + '</span>' +
      '<div class="cr-ai-id"><b>' + esc(L('ai_title', 'Design assistant')) + '</b>' +
      '<span class="cr-ai-state mono"></span></div>' +
      '<button class="cr-ai-clear" title="' + esc(L('ai_clear', 'Clear the conversation')) + '">' +
      icon('reset') + '</button></div>' +
      '<div class="cr-ai-thread"></div>' +
      '<div class="cr-ai-ideas"></div>' +
      '<div class="cr-ai-inrow"><textarea rows="2" spellcheck="false" placeholder="' +
      esc(L('ai_placeholder', 'Describe the loading screen you want…')) + '"></textarea>' +
      '<button class="cr-ai-send" title="' + esc(L('ai_send', 'Send')) + '">' +
      icon('sparkles') + '</button></div>' +
      '<p class="cr-ai-foot mono">' + esc(L('ai_foot', 'ENTER send · SHIFT+ENTER new line')) + '</p>' +
      '</div>');
    p.appendChild(box);

    const thread = box.querySelector('.cr-ai-thread');
    const state = box.querySelector('.cr-ai-state');

    if (!aiEnabled) {
      box.classList.add('is-off');
      state.textContent = L('ai_off', 'OFFLINE');
      box.querySelector('.cr-ai-ideas').remove();
      box.querySelector('.cr-ai-inrow').remove();
      box.querySelector('.cr-ai-foot').remove();
      box.querySelector('.cr-ai-clear').remove();
      thread.appendChild(el('<div class="cr-ai-empty">' + icon('lock') + '<b>' +
        esc(L('ai_disabled_t', 'No API key')) + '</b><span>' + esc(L('ai_disabled',
        'The AI assistant is disabled: set the API key in the config to enable it.')) +
        '</span></div>'));
      return;
    }

    state.textContent = L('ai_ready', 'READY');
    const ta = box.querySelector('textarea');
    const btn = box.querySelector('.cr-ai-send');
    const ideas = box.querySelector('.cr-ai-ideas');

    // starter ideas: one click writes the prompt, so nobody faces a blank box
    for (const [key, label, prompt] of AI_IDEAS) {
      const chip = el('<button class="cr-ai-chip">' + esc(L(key, label)) + '</button>');
      chip.addEventListener('click', () => {
        ta.value = L(key + '_p', prompt);
        ta.focus();
        grow();
      });
      ideas.appendChild(chip);
    }

    const grow = () => {
      ta.style.height = 'auto';
      ta.style.height = Math.min(120, Math.max(38, ta.scrollHeight + 2)) + 'px';
    };

    const paint = () => {
      thread.innerHTML = '';
      if (!APX.ai.history.length) {
        thread.appendChild(el('<div class="cr-ai-empty">' + icon('sparkles') + '<b>' +
          esc(L('ai_hello_t', 'Tell me the vibe')) + '</b><span>' + esc(L('ai_hello',
          'Describe the mood ("dark cyberpunk with purple neon, news on the left, calm music") ' +
          'and I will build the whole screen around it.')) + '</span></div>'));
      }
      APX.ai.history.forEach((m, i) => {
        if (m.role === 'user') {
          thread.appendChild(el('<div class="cr-ai-msg user">' + esc(m.text) + '</div>'));
          return;
        }
        const wrap = el('<div class="cr-ai-msg ai' + (m.error ? ' bad' : '') + '">' +
          '<span class="cr-ai-av">' + icon(m.error ? 'hazard' : 'sparkles') + '</span>' +
          '<div class="cr-ai-body"><p>' + esc(m.text) + '</p></div></div>');
        const body = wrap.querySelector('.cr-ai-body');
        if (m.applied > 0) {
          const meta = el('<div class="cr-ai-meta"><span class="cr-ai-count mono">' +
            esc(L('ai_applied', '%s changes').replace('%s', m.applied)) + '</span></div>');
          // undo only while this answer is still the newest thing that
          // happened: otherwise the button would silently eat later edits
          if (i === APX.ai.history.length - 1 && m.undoAt === undoStack.length) {
            const u = el('<button class="cr-ai-undo">' + icon('undo') + esc(L('ai_undo', 'Undo')) + '</button>');
            u.addEventListener('click', () => { undo(); paint(); });
            meta.appendChild(u);
          }
          if (m.paths && m.paths.length) {
            meta.setAttribute('title', m.paths.slice(0, 12).join('\n'));
          }
          body.appendChild(meta);
        }
        thread.appendChild(wrap);
      });
      if (aiBusy) {
        thread.appendChild(el('<div class="cr-ai-msg ai">' +
          '<span class="cr-ai-av is-busy">' + icon('sparkles') + '</span>' +
          '<div class="cr-ai-body"><span class="cr-ai-busy"><i></i><i></i><i></i></span>' +
          '<em class="cr-ai-thinking">' + esc(L('ai_thinking', 'Designing…')) + '</em></div></div>'));
      }
      ideas.hidden = APX.ai.history.length > 0;
      box.classList.toggle('is-busy', aiBusy);
      thread.scrollTop = thread.scrollHeight;
    };
    paint();

    const send = () => {
      const q = ta.value.trim();
      if (!q || aiBusy) return;
      ta.value = '';
      grow();
      aiBusy = true;
      snapshot();          // one undo step for whatever the AI does
      paint();
      const mark = undoStack.length;
      APX.ai.ask(q, (ok, reply, applied) => {
        aiBusy = false;
        const last = APX.ai.history[APX.ai.history.length - 1];
        if (last && last.role === 'ai') last.undoAt = mark;
        if (ok && applied > 0) {
          renderAll();
          if (activeTab !== 'ai') renderPanel();
          renderInspector();
        }
        paint();
      });
    };
    btn.addEventListener('click', send);
    ta.addEventListener('input', grow);
    ta.addEventListener('keydown', (e) => {
      if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); send(); }
    });
    box.querySelector('.cr-ai-clear').addEventListener('click', () => {
      APX.ai.history.length = 0;
      paint();
    });
    grow();
  }

  // ── Theme tab ────────────────────────────────────────────────────────────
  function renderTheme(p) {
    const t = Store().get('theme');
    p.group('thaccent', L('sec_theme', 'THEME'));
    p.appendChild(rowColor(L('th_accent', 'Accent'), t.accent, (v) => { t.accent = v; renderAll(); }));
    let chips = '<div class="cr-themes">';
    for (const th of Store().THEMES) {
      chips += '<button data-a="' + th.accent + '"><i style="background:' + th.accent + '"></i>' +
        esc(th.label) + '</button>';
    }
    p.appendChild(el(chips + '</div>'));
    p.querySelectorAll('.cr-themes button').forEach((b) => {
      b.addEventListener('click', () => {
        snapshot();
        t.accent = b.dataset.a;
        renderAll();
        renderPanel();
      });
    });
    p.group('typo', L('sec_typo', 'TYPOGRAPHY & SIZE'));
    p.appendChild(rowSelect(L('th_font', 'Font'), t.font || 'geist', [
      ['geist', 'Geist'], ['sans', L('th_f_sans', 'Sans')],
      ['mono', 'Mono'], ['serif', L('th_f_serif', 'Serif')],
    ], (v) => { t.font = v; renderAll(); }));
    p.appendChild(rowSlider(L('th_uiscale', 'Overall size'), t.uiScale == null ? 1 : t.uiScale, 0.6, 1.6, 0.05,
      (v) => { t.uiScale = v; renderAll(); }, (v) => Math.round(v * 100) + '%'));
    p.appendChild(rowColor(L('th_text', 'Text colour'), t.textColor || '#F4F4F5',
      (v) => { t.textColor = v; renderAll(); }));
    p.appendChild(rowColor(L('th_muted', 'Muted text'), t.mutedColor || '#B9B9C2',
      (v) => { t.mutedColor = v; renderAll(); }));

    p.group('surfaces', L('sec_surfaces', 'SURFACES'));
    p.appendChild(rowToggle(L('th_glass', 'Glass surfaces'), t.glass !== false,
      (v) => { t.glass = v; renderAll(); renderPanel(); }));
    if (t.glass !== false) {
      p.appendChild(rowSlider(L('th_surface', 'Panel opacity'), t.surface == null ? 0.7 : t.surface, 0.15, 1, 0.05,
        (v) => { t.surface = v; renderAll(); }, (v) => Math.round(v * 100) + '%'));
    }
    p.appendChild(rowSlider(L('th_radius', 'Corner radius'), t.radius, 4, 22, 1,
      (v) => { t.radius = v; renderAll(); }, (v) => v + 'px'));
    p.appendChild(rowSlider(L('th_shadow', 'Shadow depth'), t.shadow == null ? 1 : t.shadow, 0, 2, 0.1,
      (v) => { t.shadow = v; renderAll(); }, (v) => v.toFixed(1) + '×'));

    p.group('entrance', L('sec_entrance', 'ENTRANCE'));
    p.appendChild(rowSelect(L('th_entrance', 'Animation'), t.entrance || 'rise', [
      ['rise', L('th_e_rise', 'Rise')], ['fade', L('th_e_fade', 'Fade')],
      ['zoom', L('th_e_zoom', 'Spread')], ['none', L('th_e_none', 'None')],
    ], (v) => { t.entrance = v; renderAll(); }));
    p.appendChild(rowSlider(L('th_espeed', 'Speed'), t.entranceSpeed == null ? 1 : t.entranceSpeed, 0.3, 3, 0.1,
      (v) => { t.entranceSpeed = v; renderAll(); }, (v) => v.toFixed(1) + '×'));
  }

  // ── Presets tab ──────────────────────────────────────────────────────────
  function renderPresets(p) {
    p.appendChild(section(L('sec_presets', 'LAYOUT PRESETS')));
    for (const pr of Store().PRESETS) {
      const card = el('<button class="cr-preset"><b>' + esc(pr.label) + '</b><span>' +
        esc(pr.desc) + '</span></button>');
      card.addEventListener('click', () => {
        snapshot();
        Store().applyPreset(pr.id);
        renderAll();
        refreshPanels();
      });
      p.appendChild(card);
    }
    p.appendChild(el('<p class="cr-note">' + esc(L('pr_note',
      'Presets rearrange models and mood: your texts, tips and links are kept.')) + '</p>'));
  }

  // ── Settings tab ─────────────────────────────────────────────────────────
  function renderSettings(p) {
    const ex = Store().get('exit');
    p.group('exit', L('sec_exit', 'ENTERING THE CITY'));
    p.appendChild(rowSelect(L('ex_mode', 'Exit mode'), ex.hold !== false ? 'hold' : 'auto', [
      ['hold', L('ex_hold', 'Press ENTER')], ['auto', L('ex_auto', 'Automatic')],
    ], (v) => { ex.hold = v === 'hold'; }));
    p.appendChild(rowSlider(L('ex_min', 'Minimum seconds'), ex.minSeconds, 0, 20, 1,
      (v) => { ex.minSeconds = v; }, (v) => v + 's'));

    p.group('share', L('sec_share', 'SHARE'));
    const exp = el('<button class="cr-btn ghost cr-wide">' + esc(L('sh_export', 'Copy export code')) + '</button>');
    exp.addEventListener('click', () => {
      const code = Store().exportCode();
      const ta = document.createElement('textarea');
      ta.value = code;
      document.body.appendChild(ta);
      ta.select();
      try { document.execCommand('copy'); } catch (e) {}
      ta.remove();
      toast(L('sh_copied', 'Export code copied'));
    });
    p.appendChild(exp);
    const impArea = rowArea(L('sh_import', 'Import code'), '', () => {}, '');
    const ta2 = impArea.querySelector('textarea');
    ta2.rows = 2;
    const impBtn = el('<button class="cr-btn ghost cr-wide">' + esc(L('sh_apply', 'Import')) + '</button>');
    impBtn.addEventListener('click', () => {
      snapshot();
      if (Store().importCode(ta2.value)) {
        renderAll();
        refreshPanels();
        toast(L('sh_imported', 'Design imported'));
      } else {
        toast(L('sh_bad', 'Invalid code'), true);
      }
    });
    p.appendChild(impArea);
    p.appendChild(impBtn);

    p.group('reset', L('sec_reset', 'RESET'));
    const rst = el('<button class="cr-btn danger cr-wide cr-holdable">' + icon('reset') +
      esc(L('rs_all', 'Reset everything')) +
      '<span class="kcap mono">' + esc(L('cr_hold', 'HOLD')) + '</span><i class="cr-hold"></i></button>');
    makeHoldable(rst, () => {
      snapshot();
      Store().load(null);
      // put the customization UI itself back too: moved panels return home
      resetPanelPositions();
      renderAll();
      refreshPanels();
      toast(L('rs_done', 'Everything reset'));
    });
    p.appendChild(rst);
    p.appendChild(el('<p class="cr-note">' + esc(L('rs_note',
      'Hold the button to confirm. This also puts the moved panels back.')) + '</p>'));
  }

  // ── inspector (selected widget) ──────────────────────────────────────────
  function renderInspector() {
    const ins = document.getElementById('cr-inspector');
    if (!ins) return;
    if (!selected || !Store().get('widgets.' + selected)) { ins.hidden = true; return; }
    const id = selected;
    const w = Store().get('widgets.' + id);
    const def = APX.widgets[id];
    ins.hidden = false;
    ins.innerHTML = '';
    ins.appendChild(el('<div class="cr-ins-head"><b>' + esc(L('el_' + id, def.label)) + '</b>' +
      '<button class="cr-ins-x">' + icon('x') + '</button></div>'));
    ins.querySelector('.cr-ins-x').addEventListener('click', () => { selected = null; markSelection(); renderInspector(); });

    ins.appendChild(section(L('ins_style', 'STYLE')));
    const grid = el('<div class="cr-archs"></div>');
    for (const a of def.archetypes) {
      const b = el('<button class="' + (w.archetype === a ? 'on' : '') + '">' + esc(a) + '</button>');
      b.addEventListener('click', () => {
        snapshot();
        w.archetype = a;
        renderAll();
        renderInspector();
      });
      grid.appendChild(b);
    }
    ins.appendChild(grid);

    ins.appendChild(section(L('ins_options', 'OPTIONS')));
    ins.appendChild(rowToggle(L('ins_visible', 'Visible'), !!w.on, (v) => { w.on = v; renderAll(); }));
    ins.appendChild(rowSlider(L('ins_scale', 'Scale'), w.scale || 1, 0.5, 1.8, 0.05,
      (v) => { w.scale = v; renderAll(); }, (v) => Math.round(v * 100) + '%'));
    ins.appendChild(rowSlider(L('ins_opacity', 'Opacity'), w.opacity == null ? 1 : w.opacity, 0.2, 1, 0.05,
      (v) => { w.opacity = v; renderAll(); }, (v) => Math.round(v * 100) + '%'));

    // position, to the decimal: dragging is fast, typing is exact
    ins.appendChild(rowSlider(L('ins_posx', 'Position X'), w.pos.ax, 0.02, 0.98, 0.005,
      (v) => { w.pos.ax = v; renderAll(); }, (v) => Math.round(v * 100) + '%'));
    ins.appendChild(rowSlider(L('ins_posy', 'Position Y'), w.pos.ay, 0.02, 0.98, 0.005,
      (v) => { w.pos.ay = v; renderAll(); }, (v) => Math.round(v * 100) + '%'));

    // exact centring in one click: dragging can only ever get close
    const centre = el('<div class="cr-center"><span class="cr-lb">' +
      esc(L('ins_center', 'Centre on screen')) + '</span><div class="cr-center-btns">' +
      '<button data-ax="1">' + esc(L('ins_center_h', 'Horizontally')) + '</button>' +
      '<button data-ay="1">' + esc(L('ins_center_v', 'Vertically')) + '</button>' +
      '<button data-ax="1" data-ay="1">' + esc(L('ins_center_b', 'Both')) + '</button>' +
      '</div></div>');
    centre.querySelectorAll('button').forEach((b) => {
      b.addEventListener('click', () => {
        snapshot();
        if (b.dataset.ax) w.pos.ax = 0.5;
        if (b.dataset.ay) w.pos.ay = 0.5;
        renderAll();
        renderInspector();
      });
    });
    ins.appendChild(centre);

    // every widget can break away from the theme accent
    ins.appendChild(section(L('ins_colour', 'COLOUR')));
    ins.appendChild(rowToggle(L('ins_ownaccent', 'Own accent colour'), !!w.accent, (v) => {
      w.accent = v ? (Store().get('theme.accent') || '#E32636') : null;
      renderAll();
      renderInspector();
    }));
    if (w.accent) {
      ins.appendChild(rowColor(L('th_accent', 'Accent'), w.accent, (v) => { w.accent = v; renderAll(); }));
    }

    // per-widget fields
    const rerender = () => renderAll();
    if (id === 'title') {
      ins.appendChild(section(L('ins_text', 'TEXT')));
      ins.appendChild(rowText(L('f_text', 'Title'), w.text, (v) => { w.text = v; rerender(); }));
      ins.appendChild(rowText(L('f_sub', 'Subtitle'), w.sub, (v) => { w.sub = v; rerender(); }));
      ins.appendChild(rowSlider(L('f_size', 'Font size'), w.size == null ? 3.4 : w.size, 1.2, 7, 0.1,
        (v) => { w.size = v; rerender(); }, (v) => v.toFixed(1) + 'rem'));
      ins.appendChild(rowSlider(L('f_track', 'Letter spacing'), w.tracking == null ? 0.14 : w.tracking, -0.05, 0.5, 0.01,
        (v) => { w.tracking = v; rerender(); }, (v) => v.toFixed(2) + 'em'));
      ins.appendChild(rowSelect(L('f_weight', 'Weight'), String(w.weight || 800), [
        ['400', L('f_w_light', 'Light')], ['600', L('f_w_med', 'Medium')],
        ['800', L('f_w_bold', 'Bold')], ['900', L('f_w_black', 'Black')],
      ], (v) => { w.weight = parseInt(v, 10); rerender(); }));
      ins.appendChild(rowToggle(L('f_upper', 'UPPERCASE'), w.upper !== false,
        (v) => { w.upper = v; rerender(); }));
    } else if (id === 'logo') {
      const prev = el('<div class="cr-logoprev"><i></i><span class="mono">' +
        esc(prettyUrl(w.url)) + '</span></div>');
      prev.querySelector('i').style.backgroundImage =
        'url("' + String(w.url || '').replace(/"/g, '') + '")';
      ins.appendChild(prev);
      ins.appendChild(imageDrop(L('img_logo', 'Upload a logo'), false, (urls) => {
        if (!urls.length) return;
        snapshot();
        w.url = urls[0];
        rerender();
        renderInspector();
      }));
      ins.appendChild(rowText(L('f_imgurl', '…or an image link'), w.url, (v) => { w.url = v; rerender(); },
        'assets/Logo.png · media/logo.png · https://…'));
      ins.appendChild(rowSlider(L('f_logow', 'Logo width'), w.width == null ? 9.5 : w.width, 3, 24, 0.5,
        (v) => { w.width = v; rerender(); }, (v) => v.toFixed(1) + 'rem'));
    } else if (id === 'greeting') {
      ins.appendChild(rowText(L('f_text', 'Text'), w.text, (v) => { w.text = v; rerender(); }));
    } else if (id === 'progress') {
      ins.appendChild(rowToggle(L('f_pct', 'Show percent'), w.showPercent !== false,
        (v) => { w.showPercent = v; rerender(); }));
      ins.appendChild(rowToggle(L('f_stage', 'Show stage text'), w.showStage !== false,
        (v) => { w.showStage = v; rerender(); }));
      ins.appendChild(rowSlider(L('f_barw', 'Bar width'), w.width == null ? 44 : w.width, 14, 80, 1,
        (v) => { w.width = v; rerender(); }, (v) => v + 'rem'));
      ins.appendChild(rowSlider(L('f_barh', 'Thickness'), w.thickness == null ? 0.62 : w.thickness, 0.15, 2, 0.05,
        (v) => { w.thickness = v; rerender(); }, (v) => v.toFixed(2) + 'rem'));
      ins.appendChild(rowToggle(L('f_sheen', 'Moving sheen'), w.sheen !== false,
        (v) => { w.sheen = v; rerender(); }));
    } else if (id === 'tips') {
      ins.appendChild(rowArea(L('f_tips', 'Tips'), (w.items || []).join('\n'),
        (v) => { w.items = v.split('\n').map((s) => s.trim()).filter(Boolean); rerender(); },
        L('f_perline', 'One per line')));
      ins.appendChild(rowSlider(L('f_interval', 'Seconds per tip'), w.interval || 6, 3, 20, 1,
        (v) => { w.interval = v; rerender(); }, (v) => v + 's'));
    } else if (id === 'news') {
      ins.appendChild(rowText(L('f_title', 'Card title'), w.title, (v) => { w.title = v; rerender(); }));
      ins.appendChild(rowArea(L('f_news', 'Items'),
        (w.items || []).map((i) => (i.tag || '') + ' | ' + (i.text || '')).join('\n'),
        (v) => {
          w.items = v.split('\n').map((s) => s.trim()).filter(Boolean).map((line) => {
            const i = line.indexOf('|');
            if (i < 0) return { tag: '', text: line };
            return { tag: line.slice(0, i).trim(), text: line.slice(i + 1).trim() };
          });
          rerender();
        }, 'TAG | text'));
    } else if (id === 'staff') {
      ins.appendChild(rowText(L('f_title', 'Card title'), w.title, (v) => { w.title = v; rerender(); }));
      ins.appendChild(rowArea(L('f_staff', 'People'),
        (w.items || []).map((i) => (i.name || '') + ' | ' + (i.role || '')).join('\n'),
        (v) => {
          w.items = v.split('\n').map((s) => s.trim()).filter(Boolean).map((line) => {
            const i = line.indexOf('|');
            if (i < 0) return { name: line, role: '' };
            return { name: line.slice(0, i).trim(), role: line.slice(i + 1).trim() };
          });
          rerender();
        }, 'Name | Role'));
    } else if (id === 'socials') {
      ins.appendChild(rowArea(L('f_socials', 'Links'),
        (w.items || []).map((i) => (i.icon || 'globe') + ' | ' + (i.label || '')).join('\n'),
        (v) => {
          w.items = v.split('\n').map((s) => s.trim()).filter(Boolean).map((line) => {
            const i = line.indexOf('|');
            if (i < 0) return { icon: 'globe', label: line };
            return { icon: line.slice(0, i).trim(), label: line.slice(i + 1).trim() };
          });
          rerender();
        }, 'discord | discord.gg/you'));
    } else if (id === 'keybinds') {
      ins.appendChild(rowArea(L('f_keys', 'Keys'),
        (w.items || []).map((i) => (i.key || '') + ' | ' + (i.label || '')).join('\n'),
        (v) => {
          w.items = v.split('\n').map((s) => s.trim()).filter(Boolean).map((line) => {
            const i = line.indexOf('|');
            if (i < 0) return { key: line, role: '' };
            return { key: line.slice(0, i).trim(), label: line.slice(i + 1).trim() };
          });
          rerender();
        }, 'M | mute music'));
    }
  }

  // ── toast ────────────────────────────────────────────────────────────────
  let toastTimer = null;
  function toast(msg, bad) {
    // with the creator closed the page still sits over the game: a result
    // that lands then goes to the chat from Lua instead
    if (!open) return;
    let t = document.getElementById('cr-toast');
    if (!t) {
      t = el('<div id="cr-toast" class="mono"></div>');
      document.body.appendChild(t);
    }
    t.textContent = msg;
    t.classList.toggle('bad', !!bad);
    t.classList.add('on');
    clearTimeout(toastTimer);
    // a failure carries the reason, which takes longer to read
    toastTimer = setTimeout(() => t.classList.remove('on'), bad ? 7000 : 2600);
  }

  // ── open / close / save ──────────────────────────────────────────────────
  function openCreator(d) {
    if (d && d.locales) APX.locales = d.locales;
    if (d && d.design) Store().load(d.design);
    if (d && d.ai !== undefined) aiEnabled = !!d.ai;
    // the server's public bridge URL, so the preview's YouTube fallback
    // chain is the same one the real loading screen will use
    if (d && d.yt) APX.ytBridge = String(d.yt);
    open = true;
    APX.runtimeEditing = true;
    // the preview must obey the real loading screen's limits, not the
    // ui_page's more generous ones
    APX.previewMode = true;
    dirty = false;
    undoStack = [];
    redoStack = [];
    buildChrome();
    // a publish keeps going when the creator is closed: show where it is
    if (publishing) setSaveBusy(publishing.pct);
    document.body.classList.add('editing');
    renderAll();
    renderPanel();
    applyPanelPositions();   // restore wherever the owner last dragged them
    mediaRefresh();
    syncDirty();
    simRestart();
    restartMusic();
  }

  // The player holds a shuffled index built from the playlist it started
  // with, so editing the tracks has to restart it: otherwise the index points
  // at a track that no longer exists and the music stops for no visible
  // reason. start() tears the previous player down on its own.
  function restartMusic() {
    const m = Store().get('music');
    if (m && m.enabled !== false) APX.music.start(m);
    else APX.music.stop();
  }

  function close(fromLua) {
    open = false;
    APX.runtimeEditing = false;
    document.body.classList.remove('editing');
    if (chrome) { chrome.remove(); chrome = null; }
    const t = document.getElementById('cr-toast');
    if (t) t.classList.remove('on');
    selected = null;
    guides.clear();
    clearInterval(simTimer);

    // ⚠⚠ FiveM renders the ui_page for as long as the resource runs: closing
    // the creator only takes the focus away, it does not destroy this page.
    // Anything still making noise (a music track, a video background, the
    // YouTube bridge iframe) would keep playing over the game until the
    // resource restarts. Tear it all down, then blank the preview.
    APX.music.stop();
    APX.bg.stop();
    const s = stage();
    if (s) s.innerHTML = '';

    if (!fromLua) {
      APX.nuiPost('closeCreator').catch(() => {});
    }
  }

  // ⚠ The toast used to fire the moment the request left the page, so a
  // design the server could not persist looked exactly like one it could.
  // Nothing is claimed now until the server says what it managed to store.
  //
  // ⚠⚠ And the whole design used to go out as ONE network event. With an
  // uploaded logo that is over FXServer's netEventSize limit, so the publish
  // never arrived and all the creator could say was "the server did not
  // answer". It now travels in acknowledged parts (handOver above) and the
  // button shows how far it got.
  const DESIGN_MAX = 8 * 1024 * 1024;   // same cap as the server
  let saveWait = null;
  let publishing = null;                // { id, pct, json } while one is on its way

  function setSaveBusy(pct) {
    const b = document.getElementById('cr-save');
    if (!b) return;
    if (pct == null) {
      b.classList.remove('busy');
      b.disabled = false;
      b.style.minWidth = '';
      b.textContent = L('cr_save', 'Save & Publish');
      return;
    }
    if (!b.classList.contains('busy')) {
      b.style.minWidth = b.offsetWidth + 'px';   // the label changes, the button does not jump
      b.classList.add('busy');
      b.disabled = true;
    }
    b.textContent = L('cr_publishing', 'Publishing %s%').replace('%s', pct);
  }

  // The game reports every few hundred ms while parts are moving, and gives
  // up on its own after 20 s of silence from the server. This is only the
  // backstop for the game itself going quiet.
  function armSaveWatch() {
    clearTimeout(saveWait);
    saveWait = setTimeout(() => {
      finishPublish(false, L('cr_save_noreply', 'The server did not answer. Run loading_diag in the server console.'));
    }, 45000);
  }

  function finishPublish(ok, msg) {
    clearTimeout(saveWait);
    const p = publishing;
    publishing = null;
    setSaveBusy(null);
    if (msg) toast(msg, !ok);
    return p;
  }

  function save() {
    if (publishing) {
      toast(L('cr_save_busy', 'Already publishing: wait for it to finish.'));
      return;
    }
    const json = APX.asciiJson(Store().state);
    if (json.length > DESIGN_MAX) {
      toast(L('cr_save_toobig', 'This design is %s MB, the limit is 8 MB. Remove an uploaded image.')
        .replace('%s', (json.length / 1048576).toFixed(1)), true);
      return;
    }
    publishing = { id: null, pct: 0, json: json };
    setSaveBusy(0);
    armSaveWatch();
    handOver('design', json).then((id) => {
      if (publishing && publishing.json === json) publishing.id = id;
    }).catch((e) => {
      finishPublish(false, L('cr_save_handover', 'The creator could not hand the design to the game: %s')
        .replace('%s', e.message));
    });
  }

  function onUpProgress(d) {
    if (!d) return;
    if (d.kind === 'media') {
      if (!media.busy) return;
      media.pct = Math.max(0, Math.min(100, d.pct | 0));
      mediaChanged();
      return;
    }
    if (!publishing) return;
    publishing.pct = Math.max(0, Math.min(100, d.pct | 0));
    setSaveBusy(publishing.pct);
    armSaveWatch();
  }

  function onUpFail(d) {
    const why = (d && d.error) || L('md_fail', 'Upload failed.');
    const isMedia = d && (d.kind === 'media' || (media.upId && d.id === media.upId));
    if (isMedia) {
      if (media.busy) mediaFail(L('md_fail', 'Upload failed.') + ' ' + why);
      return;
    }
    if (publishing) finishPublish(false, L('cr_save_failed', 'Not published: %s').replace('%s', why));
  }

  function onSaved(res) {
    const p = finishPublish(true, null);
    if (!res || res.ok !== true) {
      toast((res && res.note)
        ? L('cr_save_failed', 'Not published: %s').replace('%s', res.note)
        : L('cr_save_failed_generic', 'The design could not be published. Run loading_diag in the server console.'), true);
      return;
    }
    // anything edited while the parts were travelling is still unsaved
    const now = APX.asciiJson(Store().state);
    dirty = !!(p && p.json !== now);
    syncDirty();
    // uploaded art rides along in the handover, so say so once it gets heavy
    const mb = ((p && p.json) || now).length / 1048576;
    if (mb > 2) {
      toast(L('heavy_warn', 'This design is %s MB. Uploaded images are sent to every player on connect, keep it under 2 MB.')
        .replace('%s', mb.toFixed(1)), true);
    } else {
      toast(L('cr_saved', 'Published: every new connection gets this design'));
    }
  }

  // ── message router (Lua → NUI) ───────────────────────────────────────────
  window.addEventListener('message', (e) => {
    const m = e.data || {};
    if (m.action === 'openCreator') openCreator(m.data || {});
    else if (m.action === 'closeCreator') close(true);
    else if (m.action === 'saved') onSaved(m.data);
    else if (m.action === 'upProgress') onUpProgress(m.data);
    else if (m.action === 'upFail') onUpFail(m.data);
    else if (m.action === 'aiReply') APX.ai.onReply(m.data);
    else if (m.action === 'mediaList') {
      media.files = (m.data && m.data.files) || [];
      media.busy = false;
      media.pct = 0;
      mediaChanged();
    } else if (m.action === 'mediaDone') {
      media.busy = false;
      media.pct = 0;
      media.upId = null;
      if (m.data && m.data.ok) {
        toast(L('md_ok', 'Uploaded: restart the resource (ensure apex_loading) to serve it'));
        mediaRefresh();
        if (media.done) { media.done('media/' + m.data.name); media.done = null; }
      } else {
        toast((m.data && m.data.name) || L('md_fail', 'Upload failed.'), true);
        mediaChanged();
      }
    }
    else if (m.action === 'savedAck') {
      if (m.data && m.data.ok === false) toast(m.data.error || 'Save failed', true);
    }
  });

  document.addEventListener('keydown', (e) => {
    if (!open) return;
    if (e.target.closest('input, textarea')) {
      if (e.key === 'Escape') e.target.blur();
      return;   // never steal keys while the owner is typing
    }
    if (e.key === 'Escape') {
      e.preventDefault();
      if (chrome && chrome.classList.contains('chrome-hidden')) { toggleChrome(false); return; }
      close(false);
    } else if (e.key === 'h' || e.key === 'H') {
      e.preventDefault();
      toggleChrome();
    } else if (e.key === 'g' || e.key === 'G') {
      e.preventDefault();
      guides.toggle();
    } else if (selected && ['ArrowLeft', 'ArrowRight', 'ArrowUp', 'ArrowDown'].includes(e.key)
               && !e.target.closest('input,textarea')) {
      e.preventDefault();
      const w = Store().get('widgets.' + selected);
      const dx = e.key === 'ArrowLeft' ? -1 : e.key === 'ArrowRight' ? 1 : 0;
      const dy = e.key === 'ArrowUp' ? -1 : e.key === 'ArrowDown' ? 1 : 0;
      const node = stage().querySelector('.ls-widget[data-id="' + selected + '"]');
      // one press = one real pixel, whatever the widget's size
      const r = node ? node.getBoundingClientRect() : null;
      const step = e.shiftKey ? 10 : 1;
      w.pos.ax = clampA(w.pos.ax + dx * step / (r ? travelX(r) : window.innerWidth));
      w.pos.ay = clampA(w.pos.ay + dy * step / (r ? travelY(r) : window.innerHeight));
      if (node) APX.place(node, w);
      dirty = true;
      syncDirty();
    } else if ((e.ctrlKey || e.metaKey) && e.key === 'z') {
      e.preventDefault();
      undo();
    } else if ((e.ctrlKey || e.metaKey) && e.key === 'y') {
      e.preventDefault();
      redo();
    }
  });

  // browser preview: ?creator=1 opens the creator immediately with mock data
  if (APX.MOCK) {
    const q = new URLSearchParams(location.search);
    if (q.get('creator') === '1') {
      setTimeout(() => openCreator({
        design: window.nuiHandoverData.apexLoading.design,
        ai: q.get('ai') !== '0',
      }), 150);
    } else {
      // plain preview of the runtime screen inside index.html: borrow the
      // loading screen's own body class so it paints like the real thing
      document.body.classList.add('ls-page');
      setTimeout(() => {
        APX.renderScreen(stage(), Store().load(window.nuiHandoverData.apexLoading.design), previewData);
        simRestart();
      }, 150);
    }
  }
})();
