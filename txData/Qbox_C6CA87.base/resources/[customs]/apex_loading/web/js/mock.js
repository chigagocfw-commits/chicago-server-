// APEX LOADING: browser mock. Active only outside CEF (dev preview and
// screenshots): fabricates handover data and a realistic load progression.
// Query params: ?preset=cinematic|command|minimal|festival  ?accent=%23C8FF00
//               ?hold=0  ?fast=1  ?creator=1 (index.html only)
(function () {
  window.APX = window.APX || {};
  if (window.invokeNative) return;   // real CEF: never mock in game
  APX.MOCK = true;

  const q = new URLSearchParams(location.search);

  // handover payload exactly like sv_main builds it: mutate Store.state
  // itself, because that is the object the handover below hands over
  const design = APX.Store.defaults();
  APX.Store.state = design;
  if (q.get('preset')) APX.Store.applyPreset(q.get('preset'));
  if (q.get('accent')) design.theme.accent = q.get('accent');
  if (q.get('hold') === '0') design.exit.hold = false;
  // media overrides for the harness: ?video=<url> and ?music=<url> exercise
  // the same code paths a real design with those links would take
  if (q.get('video')) {
    design.background.mode = 'video';
    design.background.video = { url: q.get('video'), loop: true, audio: true, volume: 0.5 };
  }
  if (q.get('music')) {
    design.music.enabled = true;
    design.music.tracks = [{ title: 'Harness track', url: q.get('music') }];
  }

  window.nuiHandoverData = {
    apexLoading: {
      design: APX.Store.state,
      name: 'Citizen',
      players: 87,
      max: 128,
      server: 'CHICAGO ROLEPLAY',
    },
  };

  // simulated load: staged fractions + log lines, like a real join
  const fast = q.get('fast') === '1';
  const STAGES = [
    [0.04, 'startInitFunction', { type: 'INIT_CORE' }],
    [0.12, 'initFunctionInvoking', { type: 'INIT_CORE', name: 'gameSkeleton', idx: 1, count: 3 }],
    [0.22, 'startInitFunction', { type: 'INIT_BEFORE_MAP_LOADED' }],
    [0.34, 'startDataFileEntries', { count: 140 }],
    [0.38, 'onDataFileEntry', { name: 'x64a.rpf' }],
    [0.46, 'onDataFileEntry', { name: 'vehicles.meta' }],
    [0.55, 'onDataFileEntry', { name: 'apex_hud/web' }],
    [0.63, 'onDataFileEntry', { name: 'stream/props_apex.ytd' }],
    [0.72, 'performMapLoadFunction', { idx: 1 }],
    [0.82, 'startInitFunction', { type: 'INIT_AFTER_MAP_LOADED' }],
    [0.92, 'startInitFunction', { type: 'INIT_SESSION' }],
    [1.0, 'onLogLine', { message: 'session started' }],
  ];
  let i = 0;
  const step = () => {
    if (i >= STAGES.length) return;
    const [f, name, payload] = STAGES[i++];
    window.postMessage(Object.assign({ eventName: name }, payload), '*');
    window.postMessage({ eventName: 'loadProgress', loadFraction: f }, '*');
    setTimeout(step, fast ? 120 : 550 + Math.random() * 900);
  };
  setTimeout(step, fast ? 100 : 700);

  // NUI callbacks go nowhere in the browser: swallow them politely, and play
  // the game's part of the chunked upload so publishing is testable offline
  const origFetch = window.fetch.bind(window);
  const staged = {};
  APX.mockUploads = [];   // finished uploads, for the harness to inspect
  window.fetch = function (url, opts) {
    if (typeof url === 'string' && url.startsWith('https://apex_loading/')) {
      const name = url.split('/').pop();
      const body = (() => { try { return JSON.parse((opts && opts.body) || '{}'); } catch (e) { return {}; } })();
      if (name === 'upBegin') {
        staged[body.id] = { kind: body.kind, bytes: body.bytes, parts: body.parts, meta: body.meta, chunks: [] };
        return Promise.resolve(new Response('{"ok":true}', { status: 200 }));
      }
      if (name === 'upPart') {
        const st = staged[body.id];
        if (!st) return Promise.resolve(new Response('{"ok":false,"error":"mock lost it"}', { status: 200 }));
        st.chunks[body.index - 1] = body.data;
        return Promise.resolve(new Response('{"ok":true}', { status: 200 }));
      }
      if (name === 'upCommit') {
        const st = staged[body.id];
        delete staged[body.id];
        const text = st ? st.chunks.join('') : '';
        if (!st || text.length !== st.bytes) {
          return Promise.resolve(new Response('{"ok":false,"error":"mock size mismatch"}', { status: 200 }));
        }
        APX.mockUploads.push({ kind: st.kind, id: body.id, text: text, meta: st.meta });
        const fail = q.get('upfail');
        [25, 60, 100].forEach((pct, i) => setTimeout(() => {
          window.postMessage({ action: 'upProgress', data: { kind: st.kind, id: body.id, pct: pct } }, '*');
        }, 150 * (i + 1)));
        setTimeout(() => {
          if (fail) {
            window.postMessage({ action: 'upFail', data: { kind: st.kind, id: body.id, error: fail } }, '*');
          } else if (st.kind === 'design') {
            window.postMessage({ action: 'saved', data: { ok: true, note: 'mock', id: body.id } }, '*');
          } else {
            window.postMessage({ action: 'mediaDone', data: { ok: true, name: st.meta.name, size: text.length } }, '*');
          }
        }, 700);
        return Promise.resolve(new Response('{"ok":true}', { status: 200 }));
      }
      console.log('[mock nui]', name, opts && opts.body);
      if (url.endsWith('/aiAsk')) {
        // fake AI reply so the panel is testable offline
        setTimeout(() => {
          window.postMessage({ action: 'aiReply', data: { id: JSON.parse(opts.body).id,
            ok: true, text: JSON.stringify({ reply: 'Mock: switched the accent to Volt and enabled news.', ops: [
              { path: 'theme.accent', value: '#C8FF00' },
              { path: 'widgets.news.on', value: true },
            ] }) } }, '*');
        }, 900);
      }
      return Promise.resolve(new Response('{}', { status: 200 }));
    }
    return origFetch(url, opts);
  };
})();
