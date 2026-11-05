// APEX LOADING: AI assistant. The creator sends natural language ("make it
// cyberpunk purple with news and calm music"); the server proxies the request
// to the configured provider (the API key never reaches any client); the
// model answers STRICT JSON with `ops`: path/value patches over the design -
// which are applied on top of an undo snapshot.
(function () {
  window.APX = window.APX || {};

  // Compact schema card the model receives. Kept in one place so it never
  // drifts from store.js.
  function schemaCard() {
    const W = APX.widgets;
    const lines = [];
    for (const id in W) {
      lines.push(id + ': archetypes [' + W[id].archetypes.join(', ') + ']');
    }
    return [
      'You edit a FiveM loading screen design (JSON). Reply with STRICT JSON only:',
      '{"reply":"<short friendly sentence about what you changed>","ops":[{"path":"<dot.path>","value":<json>}]}',
      'No markdown, no code fences, nothing outside the JSON object.',
      '',
      'DESIGN PATHS you may set:',
      'theme.accent (hex color) · theme.radius (4-22) · theme.glass (bool)',
      'theme.{font: geist|sans|mono|serif, uiScale 0.6-1.6, surface 0.15-1, shadow 0-2}',
      'theme.{textColor, mutedColor} (hex) · theme.entrance: rise|fade|zoom|none',
      'theme.entranceSpeed 0.3-3',
      'ANY widget also takes: widgets.<id>.accent (hex, or null to follow the theme)',
      'and widgets.<id>.opacity 0.2-1',
      'widgets.title.{size 1.2-7, tracking -0.05-0.5, weight 400|600|800|900, upper bool}',
      'widgets.logo.width 3-24 · widgets.progress.{width 14-80, thickness 0.15-2, sheen bool}',
      'background.mode: gradient|slideshow|video|solid',
      'background.gradient.{from,to,angle,animated} · background.solid (hex)',
      'background.images (array of {url}) · background.interval · background.kenburns',
      'background.video.url',
      'background.transition: fade|slide|zoom (slideshow only)',
      'background.overlay.{dim 0-0.8, vignette 0-1, grain bool, scanlines bool, bars bool}',
      'background.overlay.tint.{color hex, amount 0-0.6}: a colour wash over everything',
      'background.overlay.sweep (bool): a slow light beam crossing the screen',
      'background.particles.mode: none|dust|stars|bokeh|shapes|embers|fireflies|snow|rain',
      'background.particles.{density 0.1-1, speed 0.2-3, color: "accent"|"white"|"#hex"}',
      'music.{enabled,volume 0-1,shuffle,visualizer} · music.tracks (array of {title,url})',
      'exit.hold (bool: wait for ENTER) · exit.minSeconds',
      'text.{enterHint,tipCap,nowPlaying,noMusic,online,consoleCap}: on-screen labels',
      'text.stages.{connecting,core,beforeMap,streaming,map,afterMap,session}: what the',
      '  progress widget says at each step of the load (great for themed servers)',
      'widgets.<id>.on (bool) · widgets.<id>.archetype · widgets.<id>.scale (0.6-1.6)',
      'widgets.<id>.pos {"ax":0..1,"ay":0..1} (screen fraction, 0.5=center)',
      'widgets.title.{text,sub} · widgets.greeting.text',
      'widgets.tips.{items (array of strings), interval}',
      'widgets.news.{title, items (array of {tag,text})}',
      'widgets.staff.{title, items (array of {name,role})}',
      'widgets.socials.items (array of {icon: discord|globe|users|music|clock|user, label})',
      'widgets.keybinds.items (array of {key,label})',
      'widgets.progress.{showPercent,showStage}',
      '',
      'WIDGETS AND THEIR ARCHETYPES:',
      lines.join('\n'),
      '',
      'Values like "upload:0" are images the owner uploaded: keep them exactly as',
      'they are when you rewrite a list, and never invent new ones.',
      'Rules: keep positions inside 0.03..0.97. Never remove content the user',
      'did not ask to remove. When asked for a mood/style, change theme accent,',
      'background, particles and overlay together so the result feels designed.',
      'If the request is unrelated to the loading screen, answer in "reply" and',
      'return "ops": [].',
    ].join('\n');
  }

  let seq = 0;
  const pending = {};
  const blobsFor = {};   // request id -> the uploaded images it left out

  // ⚠ Uploaded images live inside the design as data: URLs, often a megabyte
  // each. Sending them would blow the request past the network event limit
  // (and the model has no use for base64). They go out as short "upload:N"
  // tokens and are put back if the model hands a token back in an op.
  const UPLOAD_RE = /^upload:(\d+)$/;

  function compactDesign(state) {
    const blobs = [];
    const json = JSON.stringify(state, (k, v) => {
      if (typeof v === 'string' && v.length > 256 && /^data:/i.test(v)) {
        blobs.push(v);
        return 'upload:' + (blobs.length - 1);
      }
      return v;
    });
    return { json: json, blobs: blobs };
  }

  function restoreUploads(v, blobs) {
    if (typeof v === 'string') {
      const m = v.match(UPLOAD_RE);
      return (m && blobs[+m[1]] !== undefined) ? blobs[+m[1]] : v;
    }
    if (Array.isArray(v)) return v.map((x) => restoreUploads(x, blobs));
    if (v && typeof v === 'object') {
      const out = {};
      for (const k in v) out[k] = restoreUploads(v[k], blobs);
      return out;
    }
    return v;
  }

  const AI = {
    history: [],   // { role: 'user'|'ai', text }

    ask(question, done) {
      const id = 'q' + (++seq) + '_' + Date.now();
      pending[id] = done;
      this.history.push({ role: 'user', text: question });
      const compact = compactDesign(APX.Store.state);
      blobsFor[id] = compact.blobs;
      const payload = {
        id: id,
        system: schemaCard(),
        user: 'CURRENT DESIGN:\n' + compact.json +
              '\n\nREQUEST:\n' + question,
      };
      if (payload.user.length > 150000) {
        this.resolve(id, false, null, APX.L('ai_toobig', 'This design is too large to send to the AI.'));
        return;
      }
      APX.nuiPost('aiAsk', payload).catch(() => {
        this.resolve(id, false, null, APX.L('ai_net', 'Could not reach the server.'));
      });
      // hard timeout so the panel never hangs
      setTimeout(() => this.resolve(id, false, null, APX.L('ai_timeout', 'The AI took too long.')), 30000);
    },

    // called by the router when Lua relays the provider response
    onReply(d) {
      if (!d || !pending[d.id]) return;
      if (!d.ok) {
        this.resolve(d.id, false, null, d.error || APX.L('ai_err', 'The AI request failed.'));
        return;
      }
      let parsed = null;
      try {
        // tolerate models that wrap JSON in fences despite instructions
        let text = String(d.text || '').trim();
        const m = text.match(/\{[\s\S]*\}/);
        if (m) text = m[0];
        parsed = JSON.parse(text);
      } catch (e) {}
      if (!parsed || typeof parsed !== 'object') {
        this.resolve(d.id, false, null, APX.L('ai_badjson', 'The AI answer was not valid JSON.'));
        return;
      }
      this.resolve(d.id, true, parsed, null);
    },

    resolve(id, ok, parsed, err) {
      const done = pending[id];
      if (!done) return;
      delete pending[id];
      const blobs = blobsFor[id] || [];
      delete blobsFor[id];
      if (!ok) {
        this.history.push({ role: 'ai', text: err, error: true });
        done(false, err, 0);
        return;
      }
      const ops = Array.isArray(parsed.ops) ? parsed.ops : [];
      let applied = 0;
      const paths = [];
      for (const op of ops) {
        if (!op || typeof op.path !== 'string' || op.value === undefined) continue;
        if (!this.allowed(op.path)) continue;
        try {
          APX.Store.set(op.path, restoreUploads(op.value, blobs));
          applied++;
          paths.push(op.path);
        } catch (e) {}
      }
      const reply = typeof parsed.reply === 'string' && parsed.reply
        ? parsed.reply : APX.L('ai_done', 'Done.');
      // the panel shows what was touched and offers to take it back, so an
      // answer is never a black box
      this.history.push({ role: 'ai', text: reply, applied: applied, paths: paths });
      done(true, reply, applied);
    },

    // whitelist: the AI may only touch design paths, nothing else
    allowed(path) {
      return /^(theme|background|music|exit|widgets)\./.test(path) || path === 'background.mode';
    },
  };

  APX.ai = AI;
})();
