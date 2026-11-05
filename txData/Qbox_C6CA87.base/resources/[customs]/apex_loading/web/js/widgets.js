// APEX LOADING: widget registry. Every widget renders from the design and
// anchors to a screen fraction (ax/ay 0..1): left/top use the fraction and
// the translate uses the SAME fraction, so a widget at ax=1 hangs from its
// right edge and one at ax=0.5 from its centre: responsive at any
// resolution or aspect with zero pixel positions anywhere.
(function () {
  window.APX = window.APX || {};

  const esc = (s) => String(s == null ? '' : s)
    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');

  function el(html) {
    const t = document.createElement('template');
    t.innerHTML = html.trim();
    return t.content.firstChild;
  }

  function icon(name) {
    return APX.icon ? APX.icon(name) : '';
  }

  // per-widget overrides that apply to EVERY widget: its own accent (which
  // re-derives the whole tint ramp locally) and its own opacity
  function applyWidgetStyle(node, w) {
    node.style.opacity = w.opacity == null ? 1 : w.opacity;
    if (w.accent) {
      const a = w.accent;
      node.style.setProperty('--acc', a);
      node.style.setProperty('--acc-ink', APX.theme.inkFor(a));
      node.style.setProperty('--acc-300', APX.theme.mix(a, '#FFFFFF', 0.35));
      node.style.setProperty('--acc-600', APX.theme.mix(a, '#000000', 0.25));
      node.style.setProperty('--acc-a12', APX.theme.alpha(a, 0.12));
      node.style.setProperty('--acc-a22', APX.theme.alpha(a, 0.22));
      node.style.setProperty('--acc-a40', APX.theme.alpha(a, 0.40));
      node.style.setProperty('--acc-a55', APX.theme.alpha(a, 0.55));
      node.style.setProperty('--glow', '0 0 22px ' + APX.theme.alpha(a, 0.45));
      node.style.setProperty('--glow-soft', '0 0 14px ' + APX.theme.alpha(a, 0.3));
    }
  }

  function place(node, w) {
    const ax = w.pos && w.pos.ax != null ? w.pos.ax : 0.5;
    const ay = w.pos && w.pos.ay != null ? w.pos.ay : 0.5;
    node.style.left = (ax * 100) + '%';
    node.style.top = (ay * 100) + '%';
    node.style.transform =
      'translate(' + (-ax * 100) + '%,' + (-ay * 100) + '%) scale(' + (w.scale || 1) + ')';
    node.style.transformOrigin = (ax * 100) + '% ' + (ay * 100) + '%';
  }

  const W = {};

  // ── LOGO ──────────────────────────────────────────────────────────────────
  W.logo = {
    label: 'Logo',
    archetypes: ['still', 'glow', 'float', 'ring'],
    build(host, w) {
      const url = esc(w.url || 'assets/Logo.png');
      if (w.archetype === 'ring') {
        host.innerHTML = '<div class="lg lg-ring"><i></i><img src="' + url + '" alt=""></div>';
      } else {
        host.innerHTML = '<div class="lg lg-' + esc(w.archetype || 'glow') + '"><img src="' + url + '" alt=""></div>';
      }
      if (w.width) host.querySelector('.lg').style.setProperty('--lg-w', w.width + 'rem');
    },
  };

  // ── TITLE ─────────────────────────────────────────────────────────────────
  W.title = {
    label: 'Title',
    archetypes: ['gradient', 'glow', 'outline', 'stack', 'typewriter', 'shine', 'glitch'],
    build(host, w) {
      const text = esc(w.text || 'YOUR SERVER');
      const sub = esc(w.sub || '');
      const a = w.archetype || 'gradient';
      if (a === 'shine') {
        // a highlight sweeps across the letters on a loop
        host.innerHTML = '<div class="tt tt-shine"><b data-t="' + text + '">' + text + '</b>' +
          (sub ? '<span class="tt-sub">' + sub + '</span>' : '') + '</div>';
      } else if (a === 'glitch') {
        // two offset colour copies flicker behind the real text
        host.innerHTML = '<div class="tt tt-glitch"><b data-t="' + text + '">' + text + '</b>' +
          (sub ? '<span class="tt-sub">' + sub + '</span>' : '') + '</div>';
      } else if (a === 'stack') {
        host.innerHTML = '<div class="tt tt-stack"><b>' + text + '</b>' +
          (sub ? '<span class="tt-subchip mono">' + sub + '</span>' : '') + '</div>';
      } else if (a === 'typewriter') {
        host.innerHTML = '<div class="tt tt-type"><b class="mono"></b><i class="tt-caret"></i>' +
          (sub ? '<span class="tt-sub">' + sub + '</span>' : '') + '</div>';
        const target = w.text || 'YOUR SERVER';
        const b = host.querySelector('b');
        let i = 0;
        const step = () => {
          if (!b.isConnected) return;
          b.textContent = target.slice(0, i);
          i++;
          if (i <= target.length) setTimeout(step, 70);
        };
        step();
      } else {
        host.innerHTML = '<div class="tt tt-' + a + '"><b>' + text + '</b>' +
          (sub ? '<span class="tt-sub">' + sub + '</span>' : '') + '</div>';
      }
      const tt = host.querySelector('.tt');
      if (tt) {
        if (w.size) tt.style.setProperty('--tt-size', w.size + 'rem');
        if (w.tracking != null) tt.style.setProperty('--tt-track', w.tracking + 'em');
        if (w.weight) tt.style.setProperty('--tt-weight', w.weight);
        tt.style.setProperty('--tt-case', w.upper === false ? 'none' : 'uppercase');
      }
    },
  };

  // ── PROGRESS ──────────────────────────────────────────────────────────────
  W.progress = {
    label: 'Progress',
    archetypes: ['bar', 'pulseline', 'segments', 'ring', 'digits', 'slim'],
    build(host, w) {
      const a = w.archetype || 'bar';
      const pct = w.showPercent !== false;
      const stage = w.showStage !== false;
      if (a === 'ring') {
        host.innerHTML =
          '<div class="pg pg-ring"><svg viewBox="0 0 120 120">' +
          '<circle class="pg-rt" cx="60" cy="60" r="52"/>' +
          '<circle class="pg-rf" cx="60" cy="60" r="52"/></svg>' +
          '<div class="pg-rc"><b class="mono">0%</b>' + (stage ? '<span></span>' : '') + '</div></div>';
      } else if (a === 'segments') {
        let segs = '';
        for (let i = 0; i < 24; i++) segs += '<i></i>';
        host.innerHTML = '<div class="pg pg-seg">' + (stage ? '<span class="pg-stage"></span>' : '') +
          '<div class="pg-segrow">' + segs + '</div>' +
          (pct ? '<b class="pg-pct mono">0%</b>' : '') + '</div>';
      } else if (a === 'digits') {
        host.innerHTML = '<div class="pg pg-digits"><b class="mono">0</b><em>%</em>' +
          (stage ? '<span class="pg-stage"></span>' : '') + '</div>';
      } else if (a === 'pulseline') {
        host.innerHTML = '<div class="pg pg-line"><div class="pg-linefill"><i></i></div>' +
          (pct ? '<b class="pg-pct mono">0%</b>' : '') + '</div>';
      } else {
        host.innerHTML = '<div class="pg pg-' + a + '">' +
          (stage ? '<span class="pg-stage"></span>' : '') +
          '<div class="pg-track"><div class="pg-fill"><i class="pg-sheen"></i></div>' +
          (pct ? '<b class="pg-knobpct mono">0%</b>' : '') + '</div></div>';
      }
      const pgRoot = host.querySelector('.pg');
      if (pgRoot) {
        if (w.width) pgRoot.style.setProperty('--pg-w', w.width + 'rem');
        if (w.thickness) pgRoot.style.setProperty('--pg-h', w.thickness + 'rem');
        if (w.sheen === false) pgRoot.classList.add('no-sheen');
      }
      const refs = {
        fill: host.querySelector('.pg-fill') || host.querySelector('.pg-linefill'),
        pct: host.querySelector('.pg-pct') || host.querySelector('.pg-knobpct') ||
             host.querySelector('.pg-rc b') || host.querySelector('.pg-digits b'),
        stage: host.querySelector('.pg-stage') || host.querySelector('.pg-rc span') ||
               host.querySelector('.pg-digits .pg-stage'),
        ringFill: host.querySelector('.pg-rf'),
        segs: host.querySelectorAll('.pg-segrow i'),
      };
      const C = 2 * Math.PI * 52;
      if (refs.ringFill) {
        refs.ringFill.style.strokeDasharray = C;
        refs.ringFill.style.strokeDashoffset = C;
      }
      const paint = (P) => {
        if (!host.isConnected) return;
        const f = P.shown;
        if (refs.fill) refs.fill.style.width = (f * 100) + '%';
        if (refs.pct) refs.pct.textContent = Math.round(f * 100) + (a === 'digits' ? '' : '%');
        if (refs.stage) refs.stage.textContent = P.stage;
        if (refs.ringFill) refs.ringFill.style.strokeDashoffset = C * (1 - f);
        if (refs.segs && refs.segs.length) {
          const lit = Math.round(f * refs.segs.length);
          for (let i = 0; i < refs.segs.length; i++) refs.segs[i].classList.toggle('on', i < lit);
        }
      };
      APX.progress.onChange(paint, host);
      paint(APX.progress);
    },
  };

  // ── TIPS ──────────────────────────────────────────────────────────────────
  W.tips = {
    label: 'Tips',
    archetypes: ['card', 'inline', 'ticker'],
    build(host, w) {
      const items = (w.items || []).filter(Boolean);
      if (!items.length) { host.innerHTML = ''; return; }
      const a = w.archetype || 'card';
      if (a === 'ticker') {
        const line = items.map(esc).join('&nbsp;&nbsp;&nbsp;·&nbsp;&nbsp;&nbsp;');
        host.innerHTML = '<div class="tp tp-ticker"><div class="tp-marq"><span>' + line +
          '</span><span>' + line + '</span></div></div>';
        return;
      }
      host.innerHTML = '<div class="tp tp-' + a + '">' +
        (a === 'card' ? '<span class="tp-cap mono">' + esc(APX.T('tipCap', 'TIP')) + '</span>' : '') +
        '<p></p></div>';
      const p = host.querySelector('p');
      let i = 0;
      const show = () => {
        if (!p.isConnected) return;
        p.classList.remove('tp-in');
        void p.offsetWidth;
        p.textContent = items[i % items.length];
        p.classList.add('tp-in');
        i++;
      };
      show();
      const iv = setInterval(() => {
        if (!p.isConnected) { clearInterval(iv); return; }
        show();
      }, Math.max(3, w.interval || 6) * 1000);
    },
  };

  // ── MUSIC ─────────────────────────────────────────────────────────────────
  W.music = {
    label: 'Music',
    archetypes: ['pill', 'mini', 'card'],
    build(host, w) {
      const a = w.archetype || 'pill';
      let bars = '';
      for (let i = 0; i < 12; i++) bars += '<i></i>';
      if (a === 'mini') {
        host.innerHTML = '<div class="mu mu-mini">' + icon('music') +
          '<span class="mu-title"></span><b class="mu-vol mono"></b></div>';
      } else if (a === 'card') {
        host.innerHTML = '<div class="mu mu-card"><div class="mu-eq mu-eq-lg">' + bars + '</div>' +
          '<div class="mu-meta"><span class="mu-cap mono">' + esc(APX.T('nowPlaying', 'NOW PLAYING')) + '</span>' +
          '<span class="mu-title"></span></div><b class="mu-vol mono"></b></div>';
      } else {
        host.innerHTML = '<div class="mu mu-pill"><div class="mu-eq">' + bars + '</div>' +
          '<span class="mu-title"></span><b class="mu-vol mono"></b></div>';
      }
      // the key hints live with the sound, so players discover them without
      // needing the separate keys widget switched on
      if (w.keys !== false) {
        host.querySelector('.mu').insertAdjacentHTML('beforeend',
          '<span class="mu-keys mono"><i>M</i><i>&uarr;&darr;</i></span>');
      }

      const refs = {
        root: host.querySelector('.mu'),
        title: host.querySelector('.mu-title'),
        vol: host.querySelector('.mu-vol'),
        eq: host.querySelectorAll('.mu-eq i'),
      };
      const paint = () => {
        if (!host.isConnected) return;
        const t = APX.music.current();
        if (refs.title) {
          refs.title.textContent = t ? (t.title || 'Track') : APX.T('noMusic', 'No music');
        }
        const A = APX.audio;
        if (refs.vol) refs.vol.textContent = A.muted ? 'MUTE' : Math.round(A.vol * 100) + '%';
        if (refs.root) refs.root.classList.toggle('is-muted', A.muted);
      };
      APX.music.onChange(paint, host);
      APX.audio.onChange(paint, host);
      paint();
      if (refs.eq.length) {
        const anim = () => {
          if (!host.isConnected) return;
          const b = APX.music.bars();
          for (let i = 0; i < refs.eq.length; i++) {
            refs.eq[i].style.height = Math.max(8, b[i] * 100) + '%';
          }
          requestAnimationFrame(anim);
        };
        requestAnimationFrame(anim);
      }
    },
  };

  // ── SOCIALS ───────────────────────────────────────────────────────────────
  W.socials = {
    label: 'Socials',
    archetypes: ['chips', 'bar', 'stack'],
    build(host, w) {
      const items = w.items || [];
      const a = w.archetype || 'chips';
      let html = '<div class="so so-' + a + '">';
      for (const it of items) {
        html += '<span class="so-item">' + icon(it.icon || 'globe') +
          '<b>' + esc(it.label || '') + '</b></span>';
      }
      host.innerHTML = html + '</div>';
    },
  };

  // ── GREETING (handover: the connecting player's name) ─────────────────────
  W.greeting = {
    label: 'Greeting',
    archetypes: ['chip', 'inline', 'hero'],
    build(host, w, data) {
      const name = esc((data && data.name) || 'Player');
      const txt = esc(w.text || 'Welcome back');
      const a = w.archetype || 'chip';
      if (a === 'hero') {
        host.innerHTML = '<div class="gr gr-hero"><span>' + txt + ',</span><b>' + name + '</b></div>';
      } else if (a === 'inline') {
        host.innerHTML = '<div class="gr gr-inline">' + icon('user') + '<span>' + txt +
          ', <b>' + name + '</b></span></div>';
      } else {
        host.innerHTML = '<div class="gr gr-chip">' + icon('user') + '<span>' + txt +
          '</span><b>' + name + '</b></div>';
      }
    },
  };

  // ── STATS (handover: players / max / server name) ─────────────────────────
  W.stats = {
    label: 'Server stats',
    archetypes: ['duo', 'inline', 'card'],
    build(host, w, data) {
      const players = data && data.players != null ? data.players : '-';
      const max = data && data.max ? data.max : '-';
      const server = esc((data && data.server) || '');
      const a = w.archetype || 'duo';
      if (a === 'inline') {
        host.innerHTML = '<div class="st st-inline">' + icon('users') +
          '<span>' + players + ' / ' + max + ' ' + esc(APX.T('online', 'online')) + '</span></div>';
      } else if (a === 'card') {
        host.innerHTML = '<div class="st st-card">' +
          (server ? '<span class="st-srv">' + server + '</span>' : '') +
          '<div class="st-row">' + icon('users') + '<b class="mono">' + players + '</b>' +
          '<em>/ ' + max + '</em></div></div>';
      } else {
        host.innerHTML = '<div class="st st-duo">' +
          '<span class="st-chip">' + icon('users') + '<b class="mono">' + players + '/' + max + '</b></span>' +
          (server ? '<span class="st-chip st-name">' + server + '</span>' : '') + '</div>';
      }
    },
  };

  // ── NEWS ──────────────────────────────────────────────────────────────────
  W.news = {
    label: 'News',
    archetypes: ['list', 'cards'],
    build(host, w) {
      const items = w.items || [];
      const a = w.archetype || 'list';
      let html = '<div class="nw nw-' + a + '">' +
        (w.title ? '<span class="nw-cap mono">' + esc(w.title) + '</span>' : '');
      for (const it of items) {
        html += '<div class="nw-item">' +
          (it.tag ? '<i class="nw-tag mono">' + esc(it.tag) + '</i>' : '') +
          '<span>' + esc(it.text || '') + '</span></div>';
      }
      host.innerHTML = html + '</div>';
    },
  };

  // ── STAFF (CATEGORIZED CHICAGO ROLEPLAY TEAM) ────────────────────────────
  W.staff = {
    label: 'Staff',
    archetypes: ['cards', 'row'],
    build(host, w) {
      const a = w.archetype || 'cards';
      let html = '<div class="sf sf-' + a + '">' +
        (w.title ? '<span class="sf-cap mono">' + esc(w.title) + '</span>' : '');
      if (w.categories && w.categories.length) {
        for (const cat of w.categories) {
          html += '<div class="sf-cat-section">' +
            '<div class="sf-cat-header"><span class="sf-cat-badge" style="background:' + (cat.color || 'var(--acc)') + ';">' + esc(cat.category) + '</span></div>';
          for (const it of (cat.members || [])) {
            const initials = esc(String(it.name || '?').slice(0, 2).toUpperCase());
            html += '<div class="sf-item"><i class="sf-av mono" style="border-color:' + (cat.color || 'var(--acc)') + ';color:#FFFFFF;background:rgba(227,38,54,0.18);">' + initials + '</i>' +
              '<div class="sf-meta"><b>' + esc(it.name || '') + '</b><span>' + esc(it.role || '') +
              '</span></div></div>';
          }
          html += '</div>';
        }
      } else {
        const items = w.items || [];
        for (const it of items) {
          const initials = esc(String(it.name || '?').slice(0, 2).toUpperCase());
          html += '<div class="sf-item"><i class="sf-av mono">' + initials + '</i>' +
            '<div class="sf-meta"><b>' + esc(it.name || '') + '</b><span>' + esc(it.role || '') +
            '</span></div></div>';
        }
      }
      host.innerHTML = html + '</div>';
    },
  };

  // ── LOG (streamed asset names: the "hacker console") ─────────────────────
  W.log = {
    label: 'Load log',
    archetypes: ['console', 'minimal'],
    build(host, w) {
      const a = w.archetype || 'console';
      host.innerHTML = '<div class="lo lo-' + a + '">' +
        (a === 'console' ? '<span class="lo-cap mono">' + esc(APX.T('consoleCap', 'LOADING')) + '</span>' : '') +
        '<div class="lo-lines mono"></div></div>';
      const box = host.querySelector('.lo-lines');
      const paint = (P) => {
        if (!box.isConnected) return;
        const n = a === 'minimal' ? 1 : 6;
        box.innerHTML = P.logLines.slice(-n).map((l) => '<span>' + esc(l) + '</span>').join('');
      };
      APX.progress.onChange(paint, host);
      paint(APX.progress);
    },
  };

  // ── CLOCK ─────────────────────────────────────────────────────────────────
  W.clock = {
    label: 'Clock',
    archetypes: ['mono', 'chip'],
    build(host, w) {
      const a = w.archetype || 'mono';
      host.innerHTML = '<div class="ck ck-' + a + '">' + (a === 'chip' ? icon('clock') : '') +
        '<b class="mono"></b></div>';
      const b = host.querySelector('b');
      const paint = () => {
        if (!b.isConnected) return;
        const d = new Date();
        b.textContent = String(d.getHours()).padStart(2, '0') + ':' +
          String(d.getMinutes()).padStart(2, '0');
        setTimeout(paint, 5000);
      };
      paint();
    },
  };

  // ── KEYBINDS ──────────────────────────────────────────────────────────────
  W.keybinds = {
    label: 'Keys',
    archetypes: ['row', 'grid'],
    build(host, w) {
      const items = w.items || [];
      let html = '<div class="kb kb-' + esc(w.archetype || 'row') + '">';
      for (const it of items) {
        html += '<span class="kb-item"><i class="kcap mono">' + esc(it.key || '?') + '</i>' +
          '<b>' + esc(it.label || '') + '</b></span>';
      }
      host.innerHTML = html + '</div>';
    },
  };

  // ── screen renderer ───────────────────────────────────────────────────────
  // data = handover payload { name, players, max, server }
  function renderScreen(stage, design, data) {
    APX.theme.apply(design.theme || {});
    let bgHost = stage.querySelector('.ls-bg');
    let wgHost = stage.querySelector('.ls-widgets');
    if (!bgHost) {
      bgHost = el('<div class="ls-bg"></div>');
      stage.appendChild(bgHost);
    }
    if (!wgHost) {
      wgHost = el('<div class="ls-widgets"></div>');
      stage.appendChild(wgHost);
    }
    APX.bg.build(bgHost, design.background || {});
    wgHost.innerHTML = '';
    // safety: whatever happens to the entrance animation, end fully visible
    wgHost.classList.remove('settled');
    clearTimeout(APX._wgSettle);
    APX._wgSettle = setTimeout(() => wgHost.classList.add('settled'), 1700);
    for (const id in W) {
      const w = design.widgets[id];
      if (!w || !w.on) continue;
      const node = el('<div class="ls-widget" data-id="' + id + '"></div>');
      place(node, w);
      applyWidgetStyle(node, w);
      wgHost.appendChild(node);
      try {
        W[id].build(node, w, data);
      } catch (e) {
        node.innerHTML = '<span class="ls-err mono">' + esc(id + ': ' + (e.message || e)) + '</span>';
      }
    }
  }

  APX.widgets = W;
  APX.place = place;
  APX.renderScreen = renderScreen;

  // locale helper: populated by runtime/creator from Lua or defaults
  APX.locales = APX.locales || {};
  APX.L = function (key, fallback) {
    return (APX.locales && APX.locales[key]) || fallback || key;
  };
})();
