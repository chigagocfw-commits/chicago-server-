// APEX LOADING (design state. One JSON document describes the entire
// loading screen: theme, background, music, exit behaviour and widgets.
// The creator edits it, the server stores it (data/design.json) and every
// connecting player receives it through deferrals.handover.
(function () {
  window.APX = window.APX || {};

  const REV = 1;

  const DEFAULT = {
    "rev": 1,
    "theme": {
        "accent": "#E32636",
        "radius": 14,
        "glass": true,
        "font": "geist",
        "uiScale": 1,
        "surface": 0.8,
        "shadow": 1.2,
        "textColor": "#FFFFFF",
        "mutedColor": "#A5A5A5",
        "entrance": "rise",
        "entranceSpeed": 1
    },
    "background": {
        "mode": "video",
        "images": [],
        "interval": 9,
        "kenburns": true,
        "transition": "fade",
        "video": {
            "url": "media/chicago.video.mp4",
            "loop": true,
            "audio": false,
            "volume": 0.35
        },
        "gradient": {
            "from": "#090909",
            "to": "#8B101D",
            "angle": 160,
            "animated": true
        },
        "solid": "#090909",
        "overlay": {
            "dim": 0.35,
            "vignette": 0.65,
            "grain": true,
            "scanlines": false,
            "bars": false,
            "tint": {
                "color": "#E32636",
                "amount": 0.06
            },
            "sweep": true
        },
        "particles": {
            "mode": "shapes",
            "density": 0.6,
            "speed": 0.8,
            "color": "accent"
        }
    },
    "music": {
        "enabled": true,
        "tracks": [
            {
                "title": "Chicago Roleplay Anthem",
                "url": "media/chicago_anthem.mp3"
            }
        ],
        "volume": 0.35,
        "shuffle": false,
        "visualizer": true,
        "keys": true,
        "osd": true
    },
    "exit": {
        "hold": true,
        "minSeconds": 0
    },
    "text": {
        "enterHint": "PRESS ENTER TO JOIN CHICAGO RP",
        "tipCap": "COMMUNITY RULES",
        "nowPlaying": "NOW PLAYING",
        "noMusic": "No music",
        "online": "online",
        "consoleCap": "LOADING CHICAGO RP",
        "stages": {
            "connecting": "Connecting to Chicago Roleplay...",
            "core": "Starting core services...",
            "beforeMap": "Preparing Chicago environment...",
            "afterMap": "Finalising street data...",
            "session": "Joining Chicago session...",
            "map": "Loading map...",
            "streaming": "Streaming assets..."
        }
    },
    "widgets": {
        "logo": {
            "on": true,
            "pos": {
                "ax": 0.5,
                "ay": 0.2
            },
            "scale": 1,
            "archetype": "glow",
            "url": "assets/Logo.png",
            "accent": null,
            "opacity": 1,
            "width": 9.5
        },
        "title": {
            "on": true,
            "pos": {
                "ax": 0.5,
                "ay": 0.36
            },
            "scale": 1,
            "archetype": "gradient",
            "text": "CHICAGO ROLEPLAY",
            "sub": "WELCOME TO CHICAGO CITY",
            "accent": null,
            "opacity": 1,
            "size": 3.4,
            "tracking": 0.14,
            "weight": 800,
            "upper": true
        },
        "progress": {
            "on": true,
            "pos": {
                "ax": 0.5,
                "ay": 0.88
            },
            "scale": 1,
            "archetype": "bar",
            "showPercent": true,
            "showStage": true,
            "accent": null,
            "opacity": 1,
            "width": 46,
            "thickness": 0.65,
            "sheen": true
        },
        "tips": {
            "on": true,
            "pos": {
                "ax": 0.5,
                "ay": 0.77
            },
            "scale": 1,
            "archetype": "card",
            "interval": 6,
            "items": [
                "STAY IN CHARACTER: Roleplay is mandatory at all times. Breaking character ruins immersion for everyone. Use /ooc for out-of-character communication.",
                "NO RDM / VDM: Attacking or running over players without justifiable roleplay initiation is strictly bannable.",
                "VALUE YOUR LIFE: Fear roleplay is required \u2014 value your character's life realistically during armed conflict.",
                "NO METAGAMING: Information gained outside the city (Discord, streams, OOC) cannot be used in character.",
                "COMMUNITY RESPECT: Toxicity, discrimination, and disrespect are not tolerated under any circumstances."
            ]
        },
        "music": {
            "on": true,
            "pos": {
                "ax": 0.045,
                "ay": 0.93
            },
            "scale": 1,
            "archetype": "pill"
        },
        "socials": {
            "on": true,
            "pos": {
                "ax": 0.955,
                "ay": 0.93
            },
            "scale": 1,
            "archetype": "chips",
            "items": [
                {
                    "icon": "discord",
                    "label": "discord.gg/chicago-rp"
                },
                {
                    "icon": "globe",
                    "label": "chicagoroleplay.net"
                }
            ]
        },
        "greeting": {
            "on": true,
            "pos": {
                "ax": 0.045,
                "ay": 0.06
            },
            "scale": 1,
            "archetype": "chip",
            "text": "Welcome to Chicago"
        },
        "stats": {
            "on": true,
            "pos": {
                "ax": 0.955,
                "ay": 0.06
            },
            "scale": 1,
            "archetype": "duo"
        },
        "keybinds": {
            "on": true,
            "pos": {
                "ax": 0.5,
                "ay": 0.65
            },
            "scale": 1,
            "archetype": "row",
            "items": [
                {
                    "key": "M",
                    "label": "Mute Music"
                },
                {
                    "key": "\u2191 \u2193",
                    "label": "Volume"
                },
                {
                    "key": "N",
                    "label": "Next Track"
                },
                {
                    "key": "ENTER",
                    "label": "Join City"
                }
            ]
        },
        "news": {
            "on": false,
            "pos": {
                "ax": 0.045,
                "ay": 0.48
            },
            "scale": 1,
            "archetype": "list",
            "title": "LATEST UPDATES",
            "items": []
        },
        "staff": {
            "on": true,
            "pos": {
                "ax": 0.955,
                "ay": 0.48
            },
            "scale": 1,
            "archetype": "cards",
            "title": "CHICAGO ROLEPLAY TEAM",
            "categories": [
                {
                    "category": "OWNER",
                    "badge": "OWNER",
                    "color": "#E32636",
                    "members": [
                        {
                            "name": "BLACK GHOST",
                            "role": "OWNER"
                        }
                    ]
                },
                {
                    "category": "CO-OWNER",
                    "badge": "CO-OWNER",
                    "color": "#D12030",
                    "members": [
                        {
                            "name": "MR ALPHA",
                            "role": "CO OWNER"
                        }
                    ]
                },
                {
                    "category": "DEVELOPER",
                    "badge": "DEVELOPER",
                    "color": "#B51B2A",
                    "members": [
                        {
                            "name": "SOUH4IL",
                            "role": "Developer"
                        }
                    ]
                }
            ],
            "items": [
                {
                    "name": "BLACK GHOST",
                    "role": "OWNER"
                },
                {
                    "name": "MR ALPHA",
                    "role": "CO OWNER"
                },
                {
                    "name": "SOUH4IL",
                    "role": "Developer"
                }
            ]
        },
        "log": {
            "on": false,
            "pos": {
                "ax": 0.045,
                "ay": 0.78
            },
            "scale": 1,
            "archetype": "console"
        },
        "clock": {
            "on": false,
            "pos": {
                "ax": 0.5,
                "ay": 0.06
            },
            "scale": 1,
            "archetype": "mono"
        }
    }
};

  const THEMES = [
    { id: 'apex',     label: 'Apex',     accent: '#E32636' },
    { id: 'volt',     label: 'Volt',     accent: '#C8FF00' },
    { id: 'ember',    label: 'Ember',    accent: '#FF6B2C' },
    { id: 'orchid',   label: 'Orchid',   accent: '#C084FC' },
    { id: 'mint',     label: 'Mint',     accent: '#34D399' },
    { id: 'crimson',  label: 'Crimson',  accent: '#F43F5E' },
    { id: 'ice',      label: 'Ice',      accent: '#7DD3FC' },
    { id: 'gold',     label: 'Gold',     accent: '#F5C542' },
  ];

  // ── layout presets (models + placement + background mood, keep content) ──
  const PRESETS = [
    {
      id: 'signature', label: 'Signature', desc: 'Logo hero, gradient sky, centre bar',
      apply(d) {
        d.background.mode = 'gradient';
        d.background.gradient = { from: '#090909', to: '#8B101D', angle: 160, animated: true };
        d.background.particles = { mode: 'shapes', density: 0.55, speed: 1, color: 'accent' };
        d.background.overlay = { dim: 0.35, vignette: 0.55, grain: true, scanlines: false, bars: false,
                                 tint: { color: '#E32636', amount: 0 }, sweep: true };
        setW(d, 'logo',     { on: true, archetype: 'glow',    pos: { ax: 0.5, ay: 0.24 } });
        setW(d, 'title',    { on: true, archetype: 'gradient', pos: { ax: 0.5, ay: 0.40 } });
        setW(d, 'progress', { on: true, archetype: 'bar',     pos: { ax: 0.5, ay: 0.87 } });
        setW(d, 'tips',     { on: true, archetype: 'card',    pos: { ax: 0.5, ay: 0.76 } });
        setW(d, 'music',    { on: true, archetype: 'pill',    pos: { ax: 0.045, ay: 0.93 } });
        setW(d, 'socials',  { on: true, archetype: 'chips',   pos: { ax: 0.955, ay: 0.93 } });
        setW(d, 'greeting', { on: true, archetype: 'chip',    pos: { ax: 0.045, ay: 0.06 } });
        setW(d, 'stats',    { on: true, archetype: 'duo',     pos: { ax: 0.955, ay: 0.06 } });
        setW(d, 'news',     { on: false }); setW(d, 'staff', { on: false });
        setW(d, 'log',      { on: false }); setW(d, 'keybinds', { on: false });
      },
    },
    {
      id: 'cinematic', label: 'Cinematic', desc: 'Letterbox bars, bottom line, quiet chrome',
      apply(d) {
        d.background.overlay = { dim: 0.25, vignette: 0.7, grain: true, scanlines: false, bars: true,
                                 tint: { color: '#0A1428', amount: 0.16 }, sweep: false };
        d.background.particles = { mode: 'dust', density: 0.5, speed: 0.6, color: 'white' };
        setW(d, 'logo',     { on: false });
        setW(d, 'title',    { on: true, archetype: 'outline', pos: { ax: 0.075, ay: 0.855 } });
        setW(d, 'progress', { on: true, archetype: 'pulseline', pos: { ax: 0.5, ay: 0.985 } });
        setW(d, 'tips',     { on: true, archetype: 'inline',  pos: { ax: 0.925, ay: 0.875 } });
        setW(d, 'music',    { on: true, archetype: 'mini',    pos: { ax: 0.075, ay: 0.075 } });
        setW(d, 'socials',  { on: true, archetype: 'bar',     pos: { ax: 0.925, ay: 0.075 } });
        setW(d, 'greeting', { on: false });
        setW(d, 'stats',    { on: false });
        setW(d, 'news',     { on: false }); setW(d, 'staff', { on: false });
        setW(d, 'log',      { on: false }); setW(d, 'keybinds', { on: false });
      },
    },
    {
      id: 'command', label: 'Command', desc: 'Info-dense: news, staff, console, ring',
      apply(d) {
        d.background.particles = { mode: 'embers', density: 0.4, speed: 1.2, color: 'accent' };
        d.background.overlay = { dim: 0.5, vignette: 0.5, grain: false, scanlines: true, bars: false,
                                 tint: { color: '#E32636', amount: 0.08 }, sweep: false };
        setW(d, 'logo',     { on: true, archetype: 'still',  pos: { ax: 0.5, ay: 0.115 }, scale: 0.8 });
        setW(d, 'title',    { on: true, archetype: 'stack',  pos: { ax: 0.5, ay: 0.245 } });
        setW(d, 'progress', { on: true, archetype: 'ring',   pos: { ax: 0.5, ay: 0.545 } });
        setW(d, 'tips',     { on: true, archetype: 'ticker', pos: { ax: 0.5, ay: 0.700 } });
        setW(d, 'news',     { on: true, archetype: 'list',   pos: { ax: 0.045, ay: 0.5 } });
        setW(d, 'staff',    { on: true, archetype: 'cards',  pos: { ax: 0.955, ay: 0.5 } });
        setW(d, 'log',      { on: true, archetype: 'console', pos: { ax: 0.045, ay: 0.845 } });
        setW(d, 'music',    { on: true, archetype: 'card',   pos: { ax: 0.955, ay: 0.845 } });
        setW(d, 'greeting', { on: true, archetype: 'inline', pos: { ax: 0.045, ay: 0.06 } });
        setW(d, 'stats',    { on: true, archetype: 'inline', pos: { ax: 0.955, ay: 0.06 } });
        setW(d, 'socials',  { on: false }); setW(d, 'keybinds', { on: false });
      },
    },
    {
      id: 'minimal', label: 'Minimal', desc: 'Almost nothing: name, percent, keys',
      apply(d) {
        d.background.mode = 'solid';
        d.background.solid = '#08080A';
        d.background.particles = { mode: 'stars', density: 0.7, speed: 0.5, color: 'white' };
        d.background.overlay = { dim: 0, vignette: 0.35, grain: false, scanlines: false, bars: false,
                                 tint: { color: '#E32636', amount: 0 }, sweep: false };
        setW(d, 'logo',     { on: false });
        setW(d, 'title',    { on: true, archetype: 'glow',   pos: { ax: 0.5, ay: 0.46 } });
        setW(d, 'progress', { on: true, archetype: 'digits', pos: { ax: 0.5, ay: 0.575 } });
        setW(d, 'tips',     { on: false });
        setW(d, 'music',    { on: true, archetype: 'mini',   pos: { ax: 0.5, ay: 0.94 } });
        setW(d, 'keybinds', { on: true, archetype: 'row',    pos: { ax: 0.5, ay: 0.885 } });
        setW(d, 'socials',  { on: false }); setW(d, 'greeting', { on: false });
        setW(d, 'stats',    { on: false }); setW(d, 'news', { on: false });
        setW(d, 'staff',    { on: false }); setW(d, 'log', { on: false });
      },
    },
    {
      id: 'festival', label: 'Festival', desc: 'Slideshow, big greeting, segments',
      apply(d) {
        d.background.mode = d.background.images.length ? 'slideshow' : 'gradient';
        d.background.gradient = { from: '#1A0A2E', to: '#0A1F3E', angle: 135, animated: true };
        d.background.particles = { mode: 'bokeh', density: 0.8, speed: 0.8, color: 'accent' };
        d.background.transition = 'zoom';
        d.background.overlay = { dim: 0.4, vignette: 0.5, grain: false, scanlines: false, bars: false,
                                 tint: { color: '#C084FC', amount: 0.12 }, sweep: true };
        setW(d, 'logo',     { on: true, archetype: 'float', pos: { ax: 0.5, ay: 0.20 } });
        setW(d, 'greeting', { on: true, archetype: 'hero',  pos: { ax: 0.5, ay: 0.40 } });
        setW(d, 'title',    { on: false });
        setW(d, 'progress', { on: true, archetype: 'segments', pos: { ax: 0.5, ay: 0.87 } });
        setW(d, 'tips',     { on: true, archetype: 'card',  pos: { ax: 0.5, ay: 0.76 } });
        setW(d, 'music',    { on: true, archetype: 'card',  pos: { ax: 0.045, ay: 0.9 } });
        setW(d, 'socials',  { on: true, archetype: 'stack', pos: { ax: 0.955, ay: 0.88 } });
        setW(d, 'stats',    { on: true, archetype: 'card',  pos: { ax: 0.955, ay: 0.075 } });
        setW(d, 'news',     { on: false }); setW(d, 'staff', { on: false });
        setW(d, 'log',      { on: false }); setW(d, 'keybinds', { on: false });
      },
    },
  ];

  function setW(d, id, patch) {
    const w = d.widgets[id];
    if (!w) return;
    for (const k in patch) {
      if (k === 'pos') { w.pos = { ax: patch.pos.ax, ay: patch.pos.ay }; }
      else w[k] = patch[k];
    }
  }

  const clone = (o) => JSON.parse(JSON.stringify(o));

  // deep-merge saved state over defaults so new fields never come up missing
  function merge(base, over) {
    if (typeof over !== 'object' || over === null || Array.isArray(over)) {
      return over === undefined ? base : over;
    }
    const out = Array.isArray(base) ? [] : clone(base || {});
    for (const k in over) {
      out[k] = merge(base ? base[k] : undefined, over[k]);
    }
    return out;
  }

  const Store = {
    state: clone(DEFAULT),
    THEMES: THEMES,
    PRESETS: PRESETS,

    defaults() { return clone(DEFAULT); },

    load(saved) {
      if (typeof saved === 'string') {
        try { saved = JSON.parse(saved); } catch (e) { saved = null; }
      }
      if (saved && typeof saved === 'object') {
        this.state = merge(clone(DEFAULT), saved);
        this.migrate();
      } else {
        this.state = clone(DEFAULT);
      }
      return this.state;
    },

    migrate() {
      const s = this.state;
      if (typeof s.rev !== 'number') s.rev = 0;
      // future revisions patch here
      s.rev = REV;
    },

    get(path) {
      let node = this.state;
      for (const part of path.split('.')) {
        if (node == null) return undefined;
        node = node[part];
      }
      return node;
    },

    set(path, value) {
      const parts = path.split('.');
      let node = this.state;
      for (let i = 0; i < parts.length - 1; i++) {
        if (typeof node[parts[i]] !== 'object' || node[parts[i]] === null) node[parts[i]] = {};
        node = node[parts[i]];
      }
      node[parts[parts.length - 1]] = value;
    },

    applyPreset(id) {
      const p = PRESETS.find((x) => x.id === id);
      if (p) p.apply(this.state);
    },

    exportCode() {
      const json = JSON.stringify(this.state);
      let b64 = '';
      try { b64 = btoa(unescape(encodeURIComponent(json))); } catch (e) { return ''; }
      return 'APXL1.' + b64;
    },

    importCode(code) {
      if (typeof code !== 'string') return false;
      code = code.trim();
      if (!code.startsWith('APXL1.')) return false;
      try {
        const json = decodeURIComponent(escape(atob(code.slice(6))));
        const parsed = JSON.parse(json);
        if (!parsed || typeof parsed !== 'object' || !parsed.widgets) return false;
        this.load(parsed);
        return true;
      } catch (e) { return false; }
    },
  };

  APX.Store = Store;

  // ── NUI callbacks ────────────────────────────────────────────────────────
  // The callback host is the resource's own name, so a renamed folder keeps
  // working instead of every button silently posting into the void.
  const RES = (typeof window.GetParentResourceName === 'function' && window.GetParentResourceName()) ||
    'apex_loading';
  APX.nuiUrl = function (name) { return 'https://' + RES + '/' + name; };
  APX.nuiPost = function (name, body) {
    return fetch(APX.nuiUrl(name), {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body || {}),
    }).then((r) => r.text()).then((t) => {
      try { return JSON.parse(t); } catch (e) { return {}; }
    });
  };

  // JSON with every non-ASCII character written as \uXXXX: the same document,
  // but one byte per character everywhere, so it can be cut into parts at
  // any point and its length means the same thing in JS, Lua and on the wire.
  APX.asciiJson = function (obj) {
    return JSON.stringify(obj).replace(/[\u007f-￿]/g,
      (c) => '\\u' + ('0000' + c.charCodeAt(0).toString(16)).slice(-4));
  };

  // T('tipCap') / T('stages.core'): every on-screen string resolves through
  // the design first, so the creator owns all of them.
  APX.T = function (path, fallback) {
    const v = Store.get('text.' + path);
    return (typeof v === 'string' && v !== '') ? v : (fallback || '');
  };
})();
