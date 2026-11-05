// APEX LOADING: loadscreen runtime. Reads the design from the deferrals
// handover (window.nuiHandoverData.apexLoading), renders the screen, starts
// the music, and handles the exit: hold mode waits for ENTER, auto mode
// plays the outro when the load completes. Either way the page tells Lua
// through the resource's NUI callback endpoint and Lua shuts the NUI down.
(function () {
  window.APX = window.APX || {};

  const stage = document.getElementById('screen');
  if (!stage) return;

  // ── design + handover ────────────────────────────────────────────────────
  const ho = (window.nuiHandoverData && window.nuiHandoverData.apexLoading) || null;
  let design = null;
  let data = { name: 'Player', players: null, max: null, server: '' };

  if (ho) {
    if (ho.design) design = APX.Store.load(ho.design);
    data = {
      name: ho.name || 'Player',
      players: ho.players,
      max: ho.max,
      server: ho.server || '',
    };
    if (ho.locales) APX.locales = ho.locales;
    // the server's public bridge URL: the last-resort origin for YouTube
    // (js/yt.js tries the resource's own cfx-nui host first)
    if (ho.yt) APX.ytBridge = String(ho.yt);
  }
  if (!design) design = APX.Store.load(null);   // factory default

  // ── diagnostics ──────────────────────────────────────────────────────────
  // Anything that refuses to play says so in F8, with the origin it was
  // served from: that origin is the whole reason YouTube embeds fail here.
  APX.diag = function (msg) {
    try {
      APX.nuiPost('diag', { msg: String(msg) }).catch(() => {});
    } catch (e) {}
    try { console.warn('[apex_loading] ' + msg); } catch (e) {}
  };
  APX.diag('loading screen ready · origin=' + location.origin +
    ' · background=' + (design.background && design.background.mode) +
    ' · tracks=' + ((design.music && design.music.tracks) || []).length +
    ' · yt bridge=' + (APX.yt ? APX.yt.bases().join(' , ') : 'n/a'));

  // the player's volume/mute must exist before anything starts making noise
  APX.audio.init(design.music || {});
  APX.renderScreen(stage, design, data);
  APX.music.start(design.music);

  // ── exit flow ────────────────────────────────────────────────────────────
  const holdMode = design.exit && design.exit.hold !== false;
  const minMs = ((design.exit && design.exit.minSeconds) || 0) * 1000;
  const bootAt = performance.now();
  let leaving = false;

  function tellLua() {
    // Silence first: Lua shuts this page down right after, but if that call is
    // ever late or lost, a track still playing would follow the player into
    // the city. The outro has already finished by now, so nothing is lost.
    try { APX.music.stop(); } catch (e) {}
    try { APX.bg.stop(); } catch (e) {}
    try {
      APX.nuiPost('apexExit').catch(() => {});
    } catch (e) {}
  }

  function leave() {
    if (leaving) return;
    leaving = true;
    stage.classList.add('ls-exit');
    setTimeout(tellLua, 650);   // let the outro play, then hand over to Lua
  }

  function readyToLeave() {
    return APX.progress.done && (performance.now() - bootAt) >= minMs;
  }

  const enterHint = document.getElementById('enterHint');

  document.addEventListener('apx-load-done', () => {
    if (holdMode) {
      if (enterHint) {
        enterHint.querySelector('b').textContent = APX.T('enterHint', 'PRESS ENTER TO JOIN');
        enterHint.hidden = false;
        void enterHint.offsetWidth;
        enterHint.classList.add('on');
      }
    } else {
      const wait = Math.max(0, minMs - (performance.now() - bootAt));
      setTimeout(leave, wait + 900);
    }
  });

  document.addEventListener('keydown', (e) => {
    if (e.key === 'Enter' && holdMode && readyToLeave()) leave();
  });

  // Safety net: if events never arrive (unusual builds), creep the target so
  // the screen never looks frozen; Lua's own timeout still guarantees entry.
  setTimeout(() => {
    if (APX.progress.target < 0.03) {
      const iv = setInterval(() => {
        if (APX.progress.target >= 0.95) { clearInterval(iv); return; }
        APX.progress.setTarget(APX.progress.target + 0.012);
      }, 900);
    }
  }, 8000);
})();
