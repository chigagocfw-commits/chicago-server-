// APEX LOADING: load progress. Ingests the real FiveM loadscreen events
// (loadProgress, init functions, data file entries) and exposes a SMOOTHED
// fraction: eased toward the target, never moving backwards, snapping to 1.
(function () {
  window.APX = window.APX || {};

  // stage names come from the design (creator → Texts tab), never hardcoded
  const STAGE_KEYS = {
    INIT_CORE: ['core', 'Starting engine'],
    INIT_BEFORE_MAP_LOADED: ['beforeMap', 'Preparing the world'],
    INIT_AFTER_MAP_LOADED: ['afterMap', 'Finalising the world'],
    INIT_SESSION: ['session', 'Joining the session'],
    MAP: ['map', 'Loading the map'],
  };
  function stageLabel(type) {
    const e = STAGE_KEYS[type];
    if (!e) return APX.T('stages.connecting', 'Loading');
    return APX.T('stages.' + e[0], e[1]);
  }

  const P = {
    target: 0,
    shown: 0,
    stage: '',
    lastEntry: '',
    logLines: [],
    done: false,
    listeners: [],

    // `owner` is the node the callback paints into. The creator rebuilds the
    // whole screen on every edit, so without it the listeners of replaced
    // widgets pile up forever and every one of them runs 25× a second.
    onChange(fn, owner) {
      // registering is the natural moment to sweep: a re-render adds one
      // listener and retires one, so the list stays the size of the screen
      // (emit alone is not enough: it stops firing once progress settles)
      if (owner) this.prune();
      this.listeners.push({ fn: fn, owner: owner || null });
    },
    prune() {
      let dead = false;
      for (const l of this.listeners) { if (l.owner && !l.owner.isConnected) { dead = true; break; } }
      if (dead) this.listeners = this.listeners.filter((l) => !l.owner || l.owner.isConnected);
    },
    emit() {
      this.prune();
      for (const l of this.listeners.slice()) l.fn(this);
    },

    setTarget(f) {
      if (typeof f !== 'number' || isNaN(f)) return;
      this.target = Math.max(this.target, Math.min(1, f));
    },

    setStage(s) {
      if (s && s !== this.stage) {
        this.stage = s;
        this.emit();
      }
    },

    pushLog(line) {
      if (!line) return;
      this.logLines.push(String(line).slice(0, 120));
      if (this.logLines.length > 8) this.logLines.shift();
      this.emit();
    },
  };

  window.addEventListener('message', (e) => {
    const d = e.data || {};
    if (d.eventName === 'loadProgress') {
      P.setTarget(d.loadFraction);
    } else if (d.eventName === 'startInitFunction') {
      P.setStage(stageLabel(d.type));
    } else if (d.eventName === 'initFunctionInvoking') {
      P.setStage(stageLabel(d.type) + (d.name ? ': ' + d.name : ''));
      P.pushLog((d.name || 'init') + ' (' + ((d.idx || 0) + '/' + (d.count || 0)) + ')');
    } else if (d.eventName === 'startDataFileEntries') {
      P.setStage(APX.T('stages.streaming', 'Streaming assets'));
      P.entryCount = d.count || 0;
      P.entryIdx = 0;
    } else if (d.eventName === 'onDataFileEntry') {
      P.entryIdx = (P.entryIdx || 0) + 1;
      P.lastEntry = d.name || '';
      P.setStage(APX.T('stages.streaming', 'Streaming assets') + (d.name ? ': ' + d.name : ''));
      P.pushLog(d.name);
    } else if (d.eventName === 'performMapLoadFunction') {
      P.setStage(stageLabel('MAP'));
    } else if (d.eventName === 'onLogLine') {
      P.pushLog(d.message);
    }
  });

  // the first stage label needs the design loaded, so resolve it lazily
  P.stage = APX.T('stages.connecting', 'Connecting');

  // easing loop: widgets read P.shown, which glides toward the target.
  // Deliberately a TIMER, not requestAnimationFrame: on a real loading
  // screen the renderer can be starved by asset streaming and rAF stalls,
  // which must never stall the load-complete signal.
  setInterval(() => {
    const before = P.shown;
    P.shown += (P.target - P.shown) * 0.09;
    if (P.target >= 1 && P.target - P.shown < 0.002) P.shown = 1;
    if (P.shown !== before) P.emit();
    if (P.shown >= 1 && !P.done) {
      P.done = true;
      P.emit();
      document.dispatchEvent(new CustomEvent('apx-load-done'));
    }
  }, 40);

  APX.progress = P;
})();
