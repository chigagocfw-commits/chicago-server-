// APEX LOADING: background engine: gradient / slideshow / video / solid,
// plus the overlay stack (dim, vignette, grain, scanlines, letterbox) and a
// canvas particle layer. Everything degrades to nothing when disabled.
(function () {
  window.APX = window.APX || {};

  let host = null;
  let slideTimer = null;
  let slideIdx = 0;
  let raf = null;
  let parts = [];
  let canvas = null, ctx = null;

  // whatever the current video background owns: the node in the DOM, the media
  // element or bridge player inside it, and the master-audio registration
  let vid = null;
  let made = null;    // filled in by videoNode() for the build below

  function el(html) {
    const t = document.createElement('template');
    t.innerHTML = html.trim();
    return t.content.firstChild;
  }

  // timers and the particle loop: everything that is cheap to rebuild
  function stopFx() {
    clearInterval(slideTimer);
    slideTimer = null;
    if (raf) { cancelAnimationFrame(raf); raf = null; }
    parts = [];
  }

  // ⚠⚠ A background that is merely removed from the DOM can keep playing:
  // a <video> holds its source and an iframe keeps running. The creator lives
  // on the ui_page, which FiveM never destroys, so anything left alive here
  // plays over the game forever.
  function killVideo() {
    if (!vid) return;
    if (vid.timer) clearTimeout(vid.timer);
    if (vid.cancel) vid.cancel();
    if (vid.target && APX.audio) APX.audio.forget(vid.target);
    if (vid.yt) { try { vid.yt.destroy(); } catch (e) {} }
    if (vid.el) {
      try { vid.el.pause(); vid.el.removeAttribute('src'); vid.el.load(); } catch (e) {}
    }
    if (vid.node && vid.node.parentNode) vid.node.parentNode.removeChild(vid.node);
    vid = null;
  }

  function stop() {
    stopFx();
    killVideo();
  }

  function build(root, bg) {
    stopFx();
    host = root;

    // ⚠ Re-inserting an iframe RELOADS it, and the creator calls build() on
    // every slider move: so a video whose settings did not change is left
    // untouched in place and everything else is wiped around it. Without this
    // the background restarts (and a YouTube bridge re-handshakes) constantly.
    const sig = (bg.mode === 'video' && bg.video && bg.video.url)
      ? JSON.stringify(bg.video) : null;
    const keep = (sig && vid && vid.sig === sig && vid.node.parentNode === host) ? vid.node : null;
    if (!keep) killVideo();
    Array.prototype.slice.call(host.children).forEach((c) => {
      if (c !== keep) host.removeChild(c);
    });

    // ── base layer ─────────────────────────────────────────────────────────
    if (bg.mode === 'solid') {
      host.appendChild(el('<div class="bg-solid" style="background:' + (bg.solid || '#0A0A0C') + '"></div>'));
    } else if (bg.mode === 'gradient' || (bg.mode === 'slideshow' && !(bg.images || []).length)
               || (bg.mode === 'video' && !(bg.video && bg.video.url))) {
      const g = bg.gradient || {};
      const from = g.from || '#090909', to = g.to || '#8B101D', angle = g.angle != null ? g.angle : 160;
      const grad = el('<div class="bg-grad' + (g.animated !== false ? ' bg-grad-anim' : '') + '"></div>');
      grad.style.background = 'linear-gradient(' + angle + 'deg,' + from + ' 0%,' + to + ' 100%)';
      host.appendChild(grad);
      if (g.animated !== false) {
        const blobA = el('<div class="bg-blob bg-blob-a"></div>');
        const blobB = el('<div class="bg-blob bg-blob-b"></div>');
        blobA.style.background = 'radial-gradient(circle, ' + APX.theme.alpha(to, 0.55) + ' 0%, transparent 70%)';
        blobB.style.background = 'radial-gradient(circle, ' + APX.theme.alpha(from, 0.7) + ' 0%, transparent 70%)';
        host.appendChild(blobA);
        host.appendChild(blobB);
      }
    } else if (bg.mode === 'slideshow') {
      // the transition lives on .bg-slide and the ken-burns motion on the
      // inner <i>, so the two never fight over `transform`
      const tr = bg.transition || 'fade';
      const wrap = el('<div class="bg-slides tr-' + tr + '"></div>');
      const imgs = bg.images || [];
      imgs.forEach((it, i) => {
        const s = el('<div class="bg-slide"><i></i></div>');
        const img = s.firstChild;
        img.style.backgroundImage = 'url("' + String(it.url || '').replace(/"/g, '') + '")';
        if (bg.kenburns !== false) {
          img.classList.add('kb');
          // stagger the phase so consecutive slides pan differently
          img.style.animationDelay = '-' + (i * 7) + 's';
        }
        if (i === 0) s.classList.add('on');
        wrap.appendChild(s);
      });
      host.appendChild(wrap);
      slideIdx = 0;
      if (imgs.length > 1) {
        slideTimer = setInterval(() => {
          const slides = wrap.children;
          slides[slideIdx].classList.remove('on');
          slides[slideIdx].classList.add('out');
          const prev = slideIdx;
          setTimeout(() => slides[prev] && slides[prev].classList.remove('out'), 1500);
          slideIdx = (slideIdx + 1) % slides.length;
          slides[slideIdx].classList.add('on');
        }, Math.max(3, bg.interval || 9) * 1000);
      }
    } else if (bg.mode === 'video') {
      if (!keep) {
        made = { el: null, yt: null, target: null, cancel: null, timer: null };
        const node = videoNode(bg.video || {}, bg.gradient);
        if (node) {
          host.appendChild(node);
          vid = { sig: sig, node: node, el: made.el, yt: made.yt, target: made.target, cancel: made.cancel, timer: made.timer };
        }
        made = null;
      }
    }

    // ── particles ──────────────────────────────────────────────────────────
    const P = bg.particles || {};
    if (P.mode && P.mode !== 'none') {
      canvas = el('<canvas class="bg-parts"></canvas>');
      host.appendChild(canvas);
      startParticles(P.mode, P.density != null ? P.density : 0.55,
        P.speed != null ? P.speed : 1, P.color || 'accent');
    }

    // ── overlay stack ──────────────────────────────────────────────────────
    const O = bg.overlay || {};
    if ((O.dim || 0) > 0) {
      const dim = el('<div class="bg-dim"></div>');
      dim.style.background = 'rgba(0,0,0,' + O.dim + ')';
      host.appendChild(dim);
    }
    if ((O.vignette || 0) > 0) {
      const vg = el('<div class="bg-vignette"></div>');
      vg.style.background = 'radial-gradient(ellipse at center, transparent 42%, rgba(0,0,0,' + (O.vignette * 0.9) + ') 100%)';
      host.appendChild(vg);
    }
    // colour wash: grades the whole background towards one hue
    if (O.tint && (O.tint.amount || 0) > 0) {
      const t = el('<div class="bg-tint"></div>');
      t.style.background = APX.theme.alpha(O.tint.color || '#E32636', O.tint.amount);
      host.appendChild(t);
    }
    // a soft light beam that crosses the screen every few seconds
    if (O.sweep) host.appendChild(el('<div class="bg-sweep"><i></i></div>'));
    if (O.grain) host.appendChild(el('<div class="bg-grain"></div>'));
    if (O.scanlines) host.appendChild(el('<div class="bg-scan"></div>'));
    if (O.bars) {
      host.appendChild(el('<div class="bg-bar bg-bar-t"></div>'));
      host.appendChild(el('<div class="bg-bar bg-bar-b"></div>'));
    }
  }

  // ── video backgrounds ────────────────────────────────────────────────────
  // Takes a direct media file, a YouTube link in any of its shapes, a Vimeo
  // link, or any other embeddable URL. A real <video> is used whenever the
  // URL is a file, because an iframe cannot be muted-autoplayed as reliably.
  // `gradient` is the design's gradient, painted whenever an embed gives up.
  function videoNode(cfg, gradient) {
    const url = String(cfg.url || '').trim();
    if (!url) return null;
    const loop = cfg.loop !== false;

    const wantAudio = cfg.audio === true;
    const vol = cfg.volume == null ? 0.6 : cfg.volume;

    if (/\.(mp4|webm|ogv|ogg|mov|m4v)(\?|#|$)/i.test(url) || /^data:video/i.test(url)) {
      const g = gradient || {};
      const videoWrap = el('<div class="bg-video-wrap"></div>');
      videoWrap.style.background = 'linear-gradient(' + (g.angle != null ? g.angle : 160) + 'deg,' +
        (g.from || '#090909') + ' 0%,' + (g.to || '#8B101D') + ' 100%)';
      const v = el('<video class="bg-video" autoplay playsinline muted' +
        (loop ? ' loop' : '') + '></video>');
      v.style.display = 'block';
      v.muted = true;
      v.defaultMuted = true;
      v.setAttribute('muted', '');
      v.setAttribute('autoplay', '');
      v.setAttribute('playsinline', '');
      let ready = false;
      let failed = false;
      let audioTarget = null;
      let timeout = null;
      let cancelled = false;
      const clearTimeoutIfReady = () => {
        ready = true;
        if (timeout) {
          clearTimeout(timeout);
          timeout = null;
          if (made) made.timer = null;
        }
      };
      const fallback = (reason) => {
        if (failed || cancelled) return;
        failed = true;
        const errDetail = reason || (v.error ? ('code ' + v.error.code + ': ' + (v.error.message || 'error')) : 'media error');
        console.warn('[APEX] Background video failed; using configured gradient.', errDetail);
        if (APX.diag) APX.diag('Video failed: ' + errDetail + ' | src=' + url);
        if (timeout) {
          clearTimeout(timeout);
          timeout = null;
          if (made) made.timer = null;
        }
        if (audioTarget && APX.audio) APX.audio.forget(audioTarget);
        v.pause();
        v.removeAttribute('src');
        v.load();
        v.hidden = true;
        v.style.display = 'none';
      };
      if (made) made.cancel = () => { cancelled = true; };
      v.addEventListener('loadeddata', () => {
        clearTimeoutIfReady();
        if (APX.diag) APX.diag('Video loadeddata ready: ' + url);
      }, { once: true });
      v.addEventListener('error', () => {
        fallback(v.error ? ('media error code ' + v.error.code + ': ' + (v.error.message || '')) : 'error event');
      });
      videoWrap.appendChild(v);
      v.src = url;
      if (made) made.el = v;
      timeout = setTimeout(() => {
        if (!ready) fallback('media load timeout (exceeded 60s)');
      }, 60000);
      if (made) made.timer = timeout;
      const tryPlay = () => {
        try {
          const p = v.play();
          if (p && p.catch) p.catch((e) => {
            console.warn('[APEX] Autoplay note:', e && e.message);
          });
        } catch (e) {}
      };
      v.addEventListener('canplay', tryPlay, { once: true });
      tryPlay();
      if (wantAudio && APX.audio) {
        // start muted (the only state autoplay is guaranteed in) then lift it
        const wake = () => {
          v.muted = APX.audio.muted;
          const p = v.play();
          if (p && p.catch) p.catch(() => {});
        };
        v.addEventListener('canplay', wake, { once: true });
        setTimeout(wake, 300);
        document.addEventListener('keydown', wake, { once: true });
        // the player's own volume keys drive it from here on; `vol` is only
        // the ceiling the designer set for this background
        audioTarget = {
          setVolume: (mv) => { v.volume = Math.max(0, Math.min(1, mv * vol)); },
          setMuted: (m) => { v.muted = m; },
        };
        APX.audio.register(audioTarget);
        if (made) made.target = audioTarget;
      }
      return videoWrap;
    }

    // YouTube goes through the bridge player (js/yt.js + web/yt.html): the
    // bridge page has a real http(s) origin, so YouTube gets the referrer
    // the nui:// loadscreen cannot send. Same path in the preview and in
    // game, so what the owner hears in the creator is what players get.
    if (APX.yt && APX.yt.isYouTube(url)) {
      const box = el('<div class="bg-embed bg-embed-api"></div>');
      // If every bridge origin fails, tear the embed out and paint the
      // gradient instead: an error card must never be what the server's
      // loading screen shows.
      const fallback = () => {
        if (!box.isConnected) return;
        box.innerHTML = '';
        box.classList.add('bg-embed-dead');
        const g = gradient || {};
        const grad = el('<div class="bg-grad"></div>');
        grad.style.background = 'linear-gradient(' + (g.angle != null ? g.angle : 160) + 'deg,' +
          (g.from || '#090909') + ' 0%,' + (g.to || '#8B101D') + ' 100%)';
        box.appendChild(grad);
      };
      const h = APX.yt.create(box, {
        url: url,
        loop: loop,
        muted: !wantAudio || (APX.audio && APX.audio.muted),
        volume: (APX.audio ? APX.audio.vol : 1) * vol,
        onFail: fallback,
      });
      if (made) made.yt = h;
      if (wantAudio && h && APX.audio) {
        const target = {
          setVolume: (mv) => h.setVolume(mv * vol),
          setMuted: (m) => { if (m) h.mute(); else { h.unMute(); h.setVolume(APX.audio.vol * vol); } },
        };
        APX.audio.register(target);
        if (made) made.target = target;
      }
      return box;
    }

    let src = null;
    {
      const vm = url.match(/vimeo\.com\/(?:video\/)?(\d+)/i);
      if (vm) {
        src = 'https://player.vimeo.com/video/' + vm[1] +
          '?autoplay=1&muted=1&background=1&dnt=1' + (loop ? '&loop=1' : '');
      } else if (/^https?:\/\//i.test(url)) {
        src = url;   // Streamable, Twitch clips, a self-hosted player…
      }
    }
    if (!src) return null;

    const wrap = el('<div class="bg-embed"><iframe frameborder="0" scrolling="no" ' +
      'allow="autoplay; encrypted-media; picture-in-picture"></iframe></div>');
    wrap.firstChild.src = src;
    return wrap;
  }

  // ── particle system (one rAF, cheap shapes, resolution-aware) ───────────
  // Density scales with the viewport area and is hard-capped: a 4K screen
  // must not quietly spawn four times the work of a 1080p one.
  const DENSITY_DIVISOR = { rain: 16000, snow: 22000, dust: 20000, stars: 14000,
                            bokeh: 90000, embers: 26000, fireflies: 30000, shapes: 28000 };

  function startParticles(mode, density, speed, colorMode) {
    ctx = canvas.getContext('2d');
    const fit = () => {
      canvas.width = canvas.clientWidth;
      canvas.height = canvas.clientHeight;
    };
    fit();
    window.addEventListener('resize', fit);

    const div = DENSITY_DIVISOR[mode] || 28000;
    const count = Math.min(320, Math.round((canvas.width * canvas.height) / div * density) + 6);
    const acc = getComputedStyle(document.documentElement).getPropertyValue('--acc').trim() || '#E32636';
    const tint = colorMode === 'white' ? '#FFFFFF'
      : (colorMode && colorMode.charAt(0) === '#') ? colorMode : acc;
    const sp = Math.max(0.2, Math.min(3, speed || 1));

    parts = [];
    for (let i = 0; i < count; i++) parts.push(spawn(mode, tint, true));

    let last = performance.now();
    const tick = (now) => {
      const dt = Math.min(50, now - last) / 16.7;
      last = now;
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      for (let i = 0; i < parts.length; i++) {
        const p = parts[i];
        p.x += p.vx * dt * sp;
        p.y += p.vy * dt * sp;
        p.t += dt;
        if (mode === 'fireflies' || mode === 'shapes' || mode === 'dust') {
          p.x += Math.sin(p.t / 40 + p.ph) * 0.3 * dt;
        }
        const m = p.s + 30;
        if (p.y > canvas.height + m || p.y < -m || p.x < -m || p.x > canvas.width + m) {
          parts[i] = spawn(mode, tint, false);
          continue;
        }
        draw(p, mode);
      }
      raf = requestAnimationFrame(tick);
    };
    raf = requestAnimationFrame(tick);
  }

  function spawn(mode, tint, anywhere) {
    const W = canvas.width, H = canvas.height;
    const r = Math.random;
    const base = { t: r() * 100, ph: r() * Math.PI * 2, acc: tint };
    if (mode === 'snow') {
      return Object.assign(base, { x: r() * W, y: anywhere ? r() * H : -10,
        vx: (r() - 0.5) * 0.4, vy: 0.5 + r() * 0.9, s: 1 + r() * 2.2, o: 0.35 + r() * 0.45 });
    }
    if (mode === 'rain') {
      return Object.assign(base, { x: r() * W, y: anywhere ? r() * H : -20,
        vx: -0.6, vy: 9 + r() * 6, s: 8 + r() * 10, o: 0.12 + r() * 0.18 });
    }
    if (mode === 'embers') {
      return Object.assign(base, { x: r() * W, y: anywhere ? r() * H : H + 10,
        vx: (r() - 0.5) * 0.5, vy: -(0.4 + r() * 0.9), s: 1 + r() * 2, o: 0.25 + r() * 0.5 });
    }
    if (mode === 'fireflies') {
      return Object.assign(base, { x: r() * W, y: r() * H,
        vx: (r() - 0.5) * 0.25, vy: (r() - 0.5) * 0.25, s: 1 + r() * 1.8, o: 0.2 + r() * 0.55 });
    }
    if (mode === 'dust') {
      // motes hanging in a sunbeam: barely moving, mostly drifting up
      return Object.assign(base, { x: r() * W, y: anywhere ? r() * H : H + 10,
        vx: (r() - 0.5) * 0.14, vy: -(0.05 + r() * 0.22), s: 0.6 + r() * 1.6, o: 0.12 + r() * 0.35 });
    }
    if (mode === 'stars') {
      // a still field that twinkles; a slow drift keeps it from looking dead
      return Object.assign(base, { x: r() * W, y: r() * H,
        vx: (r() - 0.5) * 0.03, vy: (r() - 0.5) * 0.03, s: 0.7 + r() * 1.6,
        o: 0.4 + r() * 0.6, tw: 0.5 + r() * 2.2 });
    }
    if (mode === 'bokeh') {
      // big soft out-of-focus lights rising slowly
      return Object.assign(base, { x: r() * W, y: anywhere ? r() * H : H + 60,
        vx: (r() - 0.5) * 0.12, vy: -(0.08 + r() * 0.2), s: 18 + r() * 60, o: 0.05 + r() * 0.1 });
    }
    // shapes: slow drifting rounded squares/rings in the accent
    return Object.assign(base, { x: r() * W, y: anywhere ? r() * H : H + 20,
      vx: (r() - 0.5) * 0.2, vy: -(0.15 + r() * 0.35), s: 3 + r() * 9, o: 0.05 + r() * 0.12,
      kind: r() < 0.5 ? 'ring' : 'sq', rot: r() * Math.PI });
  }

  function draw(p, mode) {
    if (mode === 'stars') {
      ctx.globalAlpha = p.o * (0.35 + 0.65 * Math.abs(Math.sin(p.t / (12 * p.tw) + p.ph)));
    } else if (mode === 'fireflies') {
      ctx.globalAlpha = p.o * (0.5 + 0.5 * Math.sin(p.t / 14 + p.ph));
    } else {
      ctx.globalAlpha = p.o;
    }

    if (mode === 'rain') {
      ctx.strokeStyle = '#9FB6D8';
      ctx.lineWidth = 1;
      ctx.beginPath();
      ctx.moveTo(p.x, p.y);
      ctx.lineTo(p.x + p.vx * 2, p.y + p.s);
      ctx.stroke();
    } else if (mode === 'shapes') {
      ctx.strokeStyle = p.acc;
      ctx.lineWidth = 1.2;
      ctx.save();
      ctx.translate(p.x, p.y);
      ctx.rotate(p.rot + p.t / 90);
      if (p.kind === 'ring') {
        ctx.beginPath();
        ctx.arc(0, 0, p.s, 0, Math.PI * 2);
        ctx.stroke();
      } else {
        ctx.strokeRect(-p.s / 2, -p.s / 2, p.s, p.s);
      }
      ctx.restore();
    } else if (mode === 'bokeh') {
      // radial fade = the out-of-focus look, without any blur filter
      const g = ctx.createRadialGradient(p.x, p.y, 0, p.x, p.y, p.s);
      g.addColorStop(0, p.acc);
      g.addColorStop(0.55, APX.theme.alpha(p.acc, 0.35));
      g.addColorStop(1, APX.theme.alpha(p.acc, 0));
      ctx.fillStyle = g;
      ctx.beginPath();
      ctx.arc(p.x, p.y, p.s, 0, Math.PI * 2);
      ctx.fill();
    } else {
      ctx.fillStyle = (mode === 'embers' || mode === 'dust' || mode === 'stars') ? p.acc : '#FFFFFF';
      ctx.beginPath();
      ctx.arc(p.x, p.y, p.s, 0, Math.PI * 2);
      ctx.fill();
    }
    ctx.globalAlpha = 1;
  }

  APX.bg = { build: build, stop: stop };
})();
