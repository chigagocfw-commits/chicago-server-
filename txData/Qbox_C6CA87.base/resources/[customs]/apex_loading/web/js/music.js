// APEX LOADING: music player. Playlist with keyboard controls (the mouse
// does not exist on a real loading screen), a WebAudio visualizer with an
// automatic fake fallback (cross-origin audio without CORS headers feeds the
// analyser silence: we detect that and animate bars from time instead).
(function () {
  window.APX = window.APX || {};

  // ── master audio ─────────────────────────────────────────────────────────
  // The sound belongs to the PLAYER, not to the design: one volume and one
  // mute govern the music player and any sound coming from a video
  // background, they are driven from the keyboard (the loading screen has no
  // mouse), and they are remembered: someone who mutes once stays muted on
  // every future join.
  const PREF_KEY = 'apex_loading:audio';

  const AUDIO = {
    vol: 0.35,
    muted: false,
    osd: true,
    keys: true,
    targets: [],
    listeners: [],

    init(cfg) {
      cfg = cfg || {};
      this.vol = cfg.volume == null ? 0.35 : cfg.volume;
      this.osd = cfg.osd !== false;
      this.keys = cfg.keys !== false;
      // a stored preference always wins over the design's starting volume
      try {
        const p = JSON.parse(localStorage.getItem(PREF_KEY) || 'null');
        if (p && typeof p.v === 'number') {
          this.vol = Math.max(0, Math.min(1, p.v));
          this.muted = !!p.m;
        }
      } catch (e) {}
      // ⚠ init runs again every time the creator opens; wiring the keys twice
      // would move the volume 10% per press instead of 5%
      if (this.keys && !this.keysWired) { this.keysWired = true; this.wireKeys(); }
      this.apply();
    },

    save() {
      try { localStorage.setItem(PREF_KEY, JSON.stringify({ v: this.vol, m: this.muted })); } catch (e) {}
    },

    // a target is anything that makes noise: { setVolume(v), setMuted(m) }
    register(t) {
      this.targets.push(t);
      try { t.setVolume(this.vol); t.setMuted(this.muted); } catch (e) {}
    },
    forget(t) {
      const i = this.targets.indexOf(t);
      if (i >= 0) this.targets.splice(i, 1);
    },

    apply() {
      for (const t of this.targets) {
        try { t.setVolume(this.vol); t.setMuted(this.muted); } catch (e) {}
      }
      this.prune();
      for (const l of this.listeners.slice()) { try { l.fn(this); } catch (e) {} }
    },

    // widgets are replaced wholesale on every creator edit; their listeners go
    // with them (see the same note in progress.js)
    prune() {
      let dead = false;
      for (const l of this.listeners) { if (l.owner && !l.owner.isConnected) { dead = true; break; } }
      if (dead) this.listeners = this.listeners.filter((l) => !l.owner || l.owner.isConnected);
    },

    setVolume(v, quiet) {
      const next = Math.max(0, Math.min(1, Math.round(v * 20) / 20));
      // raising the volume off zero is also an unmute: nobody expects to
      // press "up" three times and still hear nothing
      if (next > 0 && this.muted) this.muted = false;
      this.vol = next;
      this.save();
      this.apply();
      if (!quiet) this.flash();
    },
    nudge(d) { this.setVolume(this.vol + d); },

    toggleMute() {
      this.muted = !this.muted;
      this.save();
      this.apply();
      this.flash();
    },

    onChange(fn, owner) {
      if (owner) this.prune();
      this.listeners.push({ fn: fn, owner: owner || null });
    },
    offChange(fn) {
      this.listeners = this.listeners.filter((l) => l.fn !== fn);
    },

    wireKeys() {
      document.addEventListener('keydown', (e) => {
        if (APX.runtimeEditing) return;               // the creator owns the keys
        if (e.target && e.target.closest && e.target.closest('input, textarea')) return;
        if (e.key === 'ArrowUp') { e.preventDefault(); this.nudge(0.05); }
        else if (e.key === 'ArrowDown') { e.preventDefault(); this.nudge(-0.05); }
        else if (e.key === 'm' || e.key === 'M') { e.preventDefault(); this.toggleMute(); }
        else if (e.key === 'n' || e.key === 'N') { APX.music.next(); this.flash(); }
      });
    },

    // a short on-screen readout, so the player can see the key worked
    flash() {
      if (!this.osd) return;
      let o = document.getElementById('audioOsd');
      if (!o) {
        o = document.createElement('div');
        o.id = 'audioOsd';
        o.innerHTML = '<i class="ao-ic"></i><span class="ao-bar"><b></b></span><em class="ao-val mono"></em>';
        document.body.appendChild(o);
      }
      const pct = this.muted ? 0 : Math.round(this.vol * 100);
      o.querySelector('.ao-bar b').style.width = pct + '%';
      o.querySelector('.ao-val').textContent = this.muted ? 'MUTED' : pct + '%';
      o.classList.toggle('is-muted', this.muted);
      o.querySelector('.ao-ic').innerHTML = APX.icon
        ? APX.icon(this.muted ? 'micOff' : 'music') : '';
      o.classList.add('on');
      clearTimeout(this._osdT);
      this._osdT = setTimeout(() => o.classList.remove('on'), 1600);
    },
  };

  APX.audio = AUDIO;

  const M = {
    cfg: null,
    audio: null,
    order: [],
    idx: 0,
    analyser: null,
    audioCtx: null,
    fake: true,
    listeners: [],

    onChange(fn, owner) {
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
      for (const l of this.listeners.slice()) { try { l.fn(this); } catch (e) {} }
    },

    start(cfg) {
      this.stop();               // never stack two players on top of each other
      this.cfg = cfg;
      if (!cfg || cfg.enabled === false || !(cfg.tracks || []).length) return;
      this.order = cfg.tracks.map((_, i) => i);
      if (cfg.shuffle) {
        for (let i = this.order.length - 1; i > 0; i--) {
          const j = Math.floor(Math.random() * (i + 1));
          const t = this.order[i]; this.order[i] = this.order[j]; this.order[j] = t;
        }
      }
      this.idx = 0;
      this.failStreak = 0;
      this.audio = new Audio();
      this.audio.crossOrigin = 'anonymous';
      this.audio.addEventListener('ended', () => this.next());
      this.audio.addEventListener('error', () => this.next(true));
      // the master control owns volume and mute from here on
      this.target = {
        setVolume: (v) => {
          if (this.audio) this.audio.volume = v;
          if (this.yt) this.yt.setVolume(AUDIO.muted ? 0 : v);
        },
        setMuted: (m) => {
          if (this.audio) this.audio.muted = m;
          if (this.yt) { if (m) this.yt.mute(); else { this.yt.unMute(); this.yt.setVolume(AUDIO.vol); } }
        },
      };
      AUDIO.register(this.target);
      this.changed = () => this.emit();
      AUDIO.onChange(this.changed);
      this.play();
      if (cfg.visualizer !== false) this.wireAnalyser();
    },

    // ⚠⚠ The creator lives on the ui_page, which FiveM NEVER destroys: it is
    // rendered for as long as the resource runs, whether the creator is open
    // or not. So closing the creator has to tear the sound down by hand or a
    // YouTube track keeps playing over the game until the resource restarts.
    // Everything here is safe to call at any time, including twice.
    stop() {
      this.killYt();
      if (this.ytHost && this.ytHost.parentNode) this.ytHost.parentNode.removeChild(this.ytHost);
      this.ytHost = null;
      if (this.audio) {
        // pause is not enough: without dropping the source the element keeps
        // buffering, and a media element with a src can resume on its own
        try {
          this.audio.pause();
          this.audio.removeAttribute('src');
          this.audio.load();
        } catch (e) {}
      }
      this.audio = null;
      if (this.target) { AUDIO.forget(this.target); this.target = null; }
      if (this.changed) { AUDIO.offChange(this.changed); this.changed = null; }
      if (this.audioCtx) { try { this.audioCtx.close(); } catch (e) {} }
      this.audioCtx = null;
      this.analyser = null;
      this.fake = true;
      this.cfg = null;
      this.order = [];
      this.idx = 0;
      this.failStreak = 0;
      this.emit();
    },

    current() {
      if (!this.cfg) return null;
      return this.cfg.tracks[this.order[this.idx]] || null;
    },

    // A track can be a direct audio file OR a YouTube link. YouTube plays
    // through a hidden bridge player (js/yt.js + web/yt.html): the bridge
    // page has a real http(s) origin, so YouTube gets the referrer the
    // nui:// loadscreen cannot send: same path in the preview and in game.
    yt: null,
    ytHost: null,

    killYt() {
      if (this.yt) { this.yt.destroy(); this.yt = null; }
    },

    play() {
      const t = this.current();
      if (!t) return;
      const url = String(t.url || '');

      if (APX.yt && APX.yt.isYouTube(url)) {
        if (this.audio) { try { this.audio.pause(); } catch (e) {} }
        if (!this.ytHost) {
          this.ytHost = document.createElement('div');
          this.ytHost.className = 'mu-ythost';
          document.body.appendChild(this.ytHost);
        }
        if (this.yt && this.yt.ready) {
          this.yt.load(url);
          this.yt.setVolume(AUDIO.muted ? 0 : AUDIO.vol);
          this.emit();
          return;
        }
        this.killYt();
        this.yt = APX.yt.create(this.ytHost, {
          url: url,
          loop: false,
          muted: AUDIO.muted,
          volume: AUDIO.vol,
          onEnd: () => this.next(),
          onStall: () => this.next(true),
          onFail: () => this.next(true),
        });
        this.emit();
        return;
      }

      this.killYt();
      if (!this.audio) return;
      this.audio.src = url;
      const p = this.audio.play();
      if (p && p.catch) {
        p.catch((err) => {
          if (APX.diag) APX.diag('track did not start: ' + url.slice(0, 90) + ': ' + (err && err.name));
        });
      }
      this.emit();
    },

    vol() { return AUDIO.vol; },

    // `failed` = the track never started (dead link, refused embed…). A
    // playlist where every entry fails would otherwise spin up a new player
    // forever, so one full lap of failures stops the music instead.
    next(failed) {
      if (!this.cfg || !this.cfg.tracks.length) return;
      if (!failed) {
        this.failStreak = 0;
      } else {
        this.failStreak = (this.failStreak || 0) + 1;
        if (this.failStreak >= this.order.length) {
          if (APX.diag) APX.diag('music: no track would play (' + this.order.length + ' tried): stopping');
          this.killYt();
          this.emit();
          return;
        }
      }
      this.idx = (this.idx + 1) % this.order.length;
      this.play();
    },

    // kept as thin aliases so anything still calling them lands on the
    // master control instead of drifting out of sync with it
    setVolume(v) { AUDIO.setVolume(v); },
    toggleMute() { AUDIO.toggleMute(); },
    get muted() { return AUDIO.muted; },

    wireAnalyser() {
      try {
        const Ctx = window.AudioContext || window.webkitAudioContext;
        this.audioCtx = new Ctx();
        const srcNode = this.audioCtx.createMediaElementSource(this.audio);
        this.analyser = this.audioCtx.createAnalyser();
        this.analyser.fftSize = 64;
        srcNode.connect(this.analyser);
        this.analyser.connect(this.audioCtx.destination);
        this.fake = false;
      } catch (e) {
        this.fake = true;
      }
    },

    // 12 bar heights in 0..1: real spectrum when available, alive otherwise
    bars() {
      const out = new Array(12).fill(0);
      if (this.analyser && !this.fake) {
        const data = new Uint8Array(this.analyser.frequencyBinCount);
        this.analyser.getByteFrequencyData(data);
        let sum = 0;
        for (let i = 0; i < 12; i++) {
          const v = (data[i + 1] || 0) / 255;
          out[i] = v;
          sum += v;
        }
        if (sum > 0.05) return out;   // real signal
      }
      // fallback: pleasant fake driven by time (also used when muted CORS)
      const t = performance.now() / 1000;
      // a YouTube track never reaches the analyser, so it drives the fake bars
      const playing = !this.muted &&
        ((this.audio && !this.audio.paused && this.audio.src) || (this.yt && this.yt.ready));
      for (let i = 0; i < 12; i++) {
        out[i] = playing
          ? 0.25 + 0.65 * Math.abs(Math.sin(t * (1.4 + i * 0.17) + i * 1.3))
          : 0.06;
      }
      return out;
    },
  };

  APX.music = M;
})();
