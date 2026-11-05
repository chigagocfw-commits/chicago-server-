// Apex Chat — Settings panel logic.

(function () {
    'use strict';

    const DEFAULT_FEATURES = {
        EmojiPicker:          true,
        GifSelector:          true,
        CommandSuggestions:   true,
        MessageLengthCounter: true,
        MessageHistory:       true,
    };

    const state = {
        prefs:  null,
        config: null,
    };

    function $(sel, root) { return (root || document).querySelector(sel); }
    function $$(sel, root) { return Array.from((root || document).querySelectorAll(sel)); }

    /* ───────── Chat layout themes (design, not just colour) ───────── */
    const DESIGNS = [
        { id: 'apex',     name: 'ApexTheme',    desc: 'Classic stacked layout, clean spacing and soft colors.' },
        { id: 'glass',    name: 'Glass',        desc: 'Frosted glass cards with transparency and rounded corners.' },
        { id: 'neon',     name: 'Neon',         desc: 'Left accent border on every line. Electric and sharp.' },
        { id: 'bubble',   name: 'Bubble',       desc: 'Chat bubbles. Warm, casual and familiar.' },
        { id: 'cards',    name: 'Cards',        desc: 'Each message in its own card. Structured and readable.' },
        { id: 'minimal',  name: 'Minimalistic', desc: 'Ultra-flat GTA5 style. Left gradient fade. Clean text.' },
        { id: 'terminal', name: 'Terminal',     desc: 'Monospace font, row separators. For those who know.' },
        { id: 'compact',  name: 'Compact',      desc: 'Dense and compact — ideal for heavy chat.' },
        { id: 'outline',  name: 'Outline',      desc: 'Colored outline only, transparent background.' },
        { id: 'aurora',   name: 'Aurora',       desc: 'Soft colorful gradient on every message.' },
        { id: 'pill',     name: 'Pill',         desc: 'Messages in fully rounded capsules.' },
        { id: 'crt',      name: 'CRT',          desc: 'Green CRT terminal with retro glow.' },
        { id: 'midnight', name: 'Midnight',     desc: 'Deep blue, elegant and dark.' },
        { id: 'holo',     name: 'Hologram',     desc: 'Cyan holographic, futuristic and sharp.' },
        { id: 'sticky',   name: 'Sticky',       desc: 'Sticky notes, slightly tilted.' },
        { id: 'ticket',   name: 'Ticket',       desc: 'Receipt/ticket style with dashed border.' },
        { id: 'frost',    name: 'Frost',        desc: 'Bright frosted glass with heavy blur.' },
        { id: 'slate',    name: 'Slate',        desc: 'Matte slate, sober and minimal.' },
        { id: 'imessage', name: 'iMessage',     desc: 'Rounded bubbles; your own messages in blue.' },
        { id: 'mono',     name: 'Mono Ink',     desc: 'Black and white, high contrast, strong type.' },
        { id: 'sunset',   name: 'Sunset',       desc: 'Warm orange/pink gradient on every bubble.' },
        { id: 'forest',   name: 'Forest',       desc: 'Natural green, calm and organic.' },
        { id: 'vaporwave', name: 'Vaporwave',   desc: '80s retro-futuristic pink and cyan.' },
    ];
    function applyDesignLive(id) {
        const root = document.getElementById('apex-chat');
        if (root) root.dataset.design = id || 'apex';
    }
    // The colour theme is owned by themes.js (separate state). Pull the live
    // selection into our prefs before ANY save, so saving other settings never
    // reverts a theme the user just picked.
    function syncTheme() {
        if (!state.prefs) return;
        if (window.ApexThemes && window.ApexThemes.selectedId) {
            const t = window.ApexThemes.selectedId();
            if (t) state.prefs.theme = t;
        }
    }
    function savePrefs() { syncTheme(); ApexBus.post('apex_save_prefs', state.prefs); }
    function miniPreview(id) {
        const row = () => `
            <div class="dp-msg">
                <span class="dp-av"></span>
                <div class="dp-lines"><span class="dp-name"></span><span class="dp-txt"></span></div>
            </div>`;
        return `<div class="design-prev" data-design="${id}">${row()}${row()}${row()}</div>`;
    }
    function renderDesigns() {
        const host = $('#design-grid'); if (!host) return;
        const cur = state.prefs.chatDesign || 'apex';
        host.innerHTML = '';
        DESIGNS.forEach(d => {
            const card = document.createElement('div');
            card.className = 'design-card' + (d.id === cur ? ' is-active' : '');
            card.innerHTML = `
                ${miniPreview(d.id)}
                <div class="design-meta">
                    <strong>${escapeHtml(d.name)}${d.id === cur ? ' <i class="fas fa-check tick"></i>' : ''}</strong>
                    <small>${escapeHtml(d.desc)}</small>
                </div>`;
            card.addEventListener('click', () => {
                state.prefs.chatDesign = d.id;
                applyDesignLive(d.id);
                renderDesigns();
                savePrefs();  // persist immediately (keeps the active theme)
            });
            host.appendChild(card);
        });
    }

    function renderColors() {
        const host = $('#color-grid'); host.innerHTML = '';
        (state.config.presets || []).forEach(p => {
            const el = document.createElement('button');
            el.type = 'button';
            el.className = 'swatch';
            el.dataset.preset = p.id;
            el.style.background = p.hex;
            if (state.prefs.selectedColor === p.id) el.classList.add('is-active');
            el.addEventListener('click', () => {
                state.prefs.selectedColor = p.id;
                state.prefs.accentOverride = true;
                $$('.color-grid .swatch').forEach(s => s.classList.toggle('is-active', s === el));
                applyAccent(p.hex);
            });
            host.appendChild(el);
        });
    }

    function applyAccent(hex) {
        // Drive both the panel accent and the live chat accent.
        document.documentElement.style.setProperty('--apex-accent', hex);
        document.documentElement.style.setProperty('--accent', hex);
        const m = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(String(hex || ''));
        if (m) {
            document.documentElement.style.setProperty('--accentSoft',
                `rgba(${parseInt(m[1],16)},${parseInt(m[2],16)},${parseInt(m[3],16)},.16)`);
        }
    }

    function renderTheme() {
        document.documentElement.classList.toggle('ac-light', !state.prefs.theme && state.prefs.themeMode === 'light');
        $$('.theme-card').forEach(card => {
            card.classList.toggle('is-active', card.dataset.mode === state.prefs.themeMode);
            card.onclick = () => {
                state.prefs.themeMode = card.dataset.mode;
                document.documentElement.classList.toggle('ac-light', !state.prefs.theme && card.dataset.mode === 'light');
                $$('.theme-card').forEach(c => c.classList.toggle('is-active', c === card));
            };
        });
    }

    function renderSize() {
        $$('.size-card').forEach(card => {
            card.classList.toggle('is-active', card.dataset.size === state.prefs.chatSize);
            card.onclick = () => {
                state.prefs.chatSize = card.dataset.size;
                $$('.size-card').forEach(c => c.classList.toggle('is-active', c === card));
            };
        });
    }

    function renderFreeHand() {
        const input = $('#opt-freehand');
        input.checked = !!state.prefs.freeHand;
        input.parentElement.querySelector('.apex-toggle-label').textContent = input.checked ? 'Enabled' : 'Disabled';
        input.onchange = () => {
            state.prefs.freeHand = input.checked;
            input.parentElement.querySelector('.apex-toggle-label').textContent = input.checked ? 'Enabled' : 'Disabled';
        };
    }

    function renderPosition() {
        $$('#position-grid .pos').forEach(btn => {
            btn.classList.toggle('is-active', btn.dataset.pos === state.prefs.position);
            btn.onclick = () => {
                state.prefs.position = btn.dataset.pos;
                $$('#position-grid .pos').forEach(b => b.classList.toggle('is-active', b === btn));
            };
        });
    }

    function renderVisibility() {
        $$('.vis-card').forEach(card => {
            card.classList.toggle('is-active', card.dataset.vis === state.prefs.visibility);
            const tick = card.querySelector('.tick');
            if (tick) tick.remove();
            if (card.classList.contains('is-active')) {
                const i = document.createElement('i'); i.className = 'fas fa-check tick';
                card.querySelector('strong').appendChild(i);
            }
            card.onclick = () => {
                state.prefs.visibility = card.dataset.vis;
                renderVisibility();
            };
        });
    }

    function renderFeatures() {
        const host = $('#features-grid'); host.innerHTML = '';
        const features = Object.assign({}, DEFAULT_FEATURES, state.prefs.features || {});
        delete features.DiceButton;
        delete features.TryButton;
        state.prefs.features = features;
        Object.keys(features).forEach(key => {
            const row = document.createElement('label');
            row.className = 'feature-toggle';
            row.innerHTML = `
                <span>${key.replace(/([A-Z])/g, ' $1').trim()}</span>
                <span class="apex-toggle">
                    <input type="checkbox" ${features[key] ? 'checked' : ''}>
                    <span class="apex-toggle-track"><span class="apex-toggle-thumb"></span></span>
                </span>`;
            row.querySelector('input').addEventListener('change', (e) => {
                features[key] = e.target.checked;
            });
            host.appendChild(row);
        });
    }

    function renderNumbers() {
        $('#opt-maxlen').value  = state.prefs.maxMessageLength  || 300;
        $('#opt-maxhist').value = state.prefs.maxHistoryMessages || 10;
        $('#opt-bub-dur').value = state.prefs.bubbleDurationMs   || 8000;
        $('#opt-bub-dist').value = state.prefs.bubbleMaxDistance || 50;

        const sync = (id, key, asInt = true) => {
            const el = $(id);
            el.addEventListener('change', () => {
                state.prefs[key] = asInt ? parseInt(el.value, 10) : parseFloat(el.value);
            });
        };
        sync('#opt-maxlen',  'maxMessageLength');
        sync('#opt-maxhist', 'maxHistoryMessages');
        sync('#opt-bub-dur', 'bubbleDurationMs');
        sync('#opt-bub-dist','bubbleMaxDistance');
    }

    /* ───────────── Shortcuts UI ───────────── */
    function renderShortcuts() {
        const list = $('#shortcut-list'); list.innerHTML = '';
        state.prefs.shortcuts = state.prefs.shortcuts || [];

        state.prefs.shortcuts.forEach((sc, idx) => {
            const item = document.createElement('div');
            item.className = 'shortcut-item';
            const keysLabel = Array.isArray(sc.keys) ? sc.keys.join('+') : (sc.keys || '—');
            item.innerHTML = `
                <div class="shortcut-item-head">
                    <span class="shortcut-key">${escapeHtml(keysLabel)}</span>
                    <input class="shortcut-label" value="${escapeHtml(sc.label || ('Shortcut #' + (idx + 1)))}" placeholder="Label">
                    <button class="shortcut-remove" title="Remove"><i class="fas fa-trash"></i></button>
                </div>
                <div class="shortcut-cmd"><i class="fas fa-terminal"></i><input value="${escapeHtml(sc.commands?.[0] || '')}" placeholder="me carry"></div>
                <div class="shortcut-cmd"><i class="fas fa-terminal"></i><input value="${escapeHtml(sc.commands?.[1] || '')}" placeholder="me carries the subject on his back"></div>
            `;
            const [labelInp, cmd1, cmd2] = item.querySelectorAll('input');
            labelInp.addEventListener('input', () => { sc.label = labelInp.value; });
            cmd1.addEventListener('input',     () => { sc.commands = [cmd1.value, cmd2.value].filter(Boolean); });
            cmd2.addEventListener('input',     () => { sc.commands = [cmd1.value, cmd2.value].filter(Boolean); });
            item.querySelector('.shortcut-remove').addEventListener('click', () => {
                state.prefs.shortcuts.splice(idx, 1);
                renderShortcuts();
            });
            list.appendChild(item);
        });

        $('#add-shortcut').onclick = () => captureChord((keys) => {
            state.prefs.shortcuts.push({ keys, label: 'New shortcut', commands: [] });
            renderShortcuts();
        });
    }

    function captureChord(cb) {
        const btn = $('#add-shortcut');
        const original = btn.innerHTML;
        btn.innerHTML = '<i class="fas fa-circle-notch fa-spin"></i><span>Press any key combination…</span><small>Esc to cancel</small>';
        const onKey = (e) => {
            e.preventDefault();
            if (e.key === 'Escape') {
                cleanup(); return;
            }
            const mods = [];
            if (e.ctrlKey)  mods.push('Ctrl');
            if (e.shiftKey) mods.push('Shift');
            if (e.altKey)   mods.push('Alt');
            const k = e.key.length === 1 ? e.key.toUpperCase() : e.key;
            if (['Control', 'Shift', 'Alt'].includes(k)) return;
            const keys = mods.concat(k);
            cleanup();
            cb(keys);
        };
        const cleanup = () => {
            document.removeEventListener('keydown', onKey, true);
            btn.innerHTML = original;
        };
        document.addEventListener('keydown', onKey, true);
    }

    function escapeHtml(s) {
        return String(s || '').replace(/[&<>"']/g, c => ({ '&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;' }[c]));
    }

    /* ───────────── Message display options ───────────── */
    function applyDisplayLive() {
        const root = document.getElementById('apex-chat');
        if (!root) return;
        root.dataset.time    = state.prefs.showTime      === false ? 'off' : 'on';
        root.dataset.id      = state.prefs.showId        === false ? 'off' : 'on';
        root.dataset.avatars = state.prefs.showAvatars   === false ? 'off' : 'on';
        root.dataset.tags    = state.prefs.showTags      === false ? 'off' : 'on';
        root.dataset.mine    = state.prefs.highlightMine === false ? 'off' : 'on';
        root.dataset.font    = state.prefs.fontSize || 'md';
        root.dataset.density = state.prefs.density  || 'cozy';
    }

    function renderDisplay() {
        const tog = (id, key) => {
            const inp = $(id); if (!inp) return;
            inp.checked = state.prefs[key] !== false;      // default ON
            inp.onchange = () => { state.prefs[key] = inp.checked; applyDisplayLive(); };
        };
        tog('#opt-showtime',      'showTime');
        tog('#opt-showid',        'showId');
        tog('#opt-showavatars',   'showAvatars');
        tog('#opt-showtags',      'showTags');
        tog('#opt-highlightmine', 'highlightMine');

        // Master enable/disable-all for the display toggles above.
        const allHost = $('#opt-display-all');
        if (allHost) {
            $$('button', allHost).forEach(b => {
                b.onclick = () => {
                    const on = b.dataset.all === 'on';
                    ['showTime', 'showId', 'showAvatars', 'showTags', 'highlightMine'].forEach(k => { state.prefs[k] = on; });
                    renderDisplay();  // re-sync the checkboxes + apply live
                };
            });
        }

        const snd = $('#opt-sound');
        if (snd) {
            snd.checked = state.prefs.sound === true;       // default OFF
            snd.onchange = () => { state.prefs.sound = snd.checked; };
        }

        const seg = (id, key, def) => {
            const host = $(id); if (!host) return;
            const cur = state.prefs[key] || def;
            $$('button', host).forEach(b => {
                b.classList.toggle('is-active', b.dataset.val === cur);
                b.onclick = () => {
                    state.prefs[key] = b.dataset.val;
                    $$('button', host).forEach(x => x.classList.toggle('is-active', x === b));
                    applyDisplayLive();
                };
            });
        };
        seg('#opt-fontsize',   'fontSize',   'md');
        seg('#opt-density',    'density',    'cozy');
        seg('#opt-timeformat', 'timeFormat', '24');

        applyDisplayLive();
    }

    /* ───────────── Blocked (muted users / hidden chats) ───────────── */
    function blockedRow(icon, label, sub, onRemove) {
        const el = document.createElement('div');
        el.className = 'blocked-row';
        el.innerHTML = `<span class="blocked-ic"><i class="${icon}"></i></span>
            <div class="blocked-meta"><strong></strong><small></small></div>
            <button class="blocked-unblock" type="button"><i class="fas fa-xmark"></i> Unblock</button>`;
        el.querySelector('strong').textContent = label;
        el.querySelector('small').textContent = sub;
        el.querySelector('.blocked-unblock').addEventListener('click', onRemove);
        return el;
    }
    function renderBlocked() {
        const B = window.ApexBlocks;
        const users = $('#blocked-users'), chats = $('#blocked-chats');
        if (!users || !chats) return;
        const muted = B ? B.muted() : [];
        const blocked = B ? B.blocked() : [];
        users.innerHTML = '';
        if (!muted.length) users.innerHTML = '<div class="blocked-empty">Nobody muted.</div>';
        else muted.forEach(u => users.appendChild(blockedRow('fas fa-user-slash', u.name, 'Muted user',
            () => { if (B) B.unmute(u.id); renderBlocked(); })));
        chats.innerHTML = '';
        if (!blocked.length) chats.innerHTML = '<div class="blocked-empty">No blocked chats.</div>';
        else blocked.forEach(c => chats.appendChild(blockedRow('fas fa-comment-slash', c.label, 'Hidden chat',
            () => { if (B) B.unblock(c.cat); renderBlocked(); })));
    }
    // Keep the list fresh when a block is added/removed from the chat window.
    if (window.ApexBlocks && window.ApexBlocks.onChange) window.ApexBlocks.onChange(renderBlocked);
    // Re-render when the Blocked tab is opened.
    document.addEventListener('click', (e) => {
        if (e.target.closest('.apex-tab[data-tab="blocked"]')) renderBlocked();
    });

    /* ───────────── Mount / Save / Reset ───────────── */
    function mount(payload) {
        state.prefs  = JSON.parse(JSON.stringify(payload.prefs || {}));
        state.config = payload.config || {};
        const preset = (state.config.presets || []).find(p => p.id === state.prefs.selectedColor);
        if (preset && state.prefs.accentOverride) applyAccent(preset.hex);
        renderColors();
        renderDesigns();
        applyDesignLive(state.prefs.chatDesign || 'apex');
        renderTheme();
        renderSize();
        renderFreeHand();
        renderPosition();
        renderVisibility();
        renderFeatures();
        renderNumbers();
        renderShortcuts();
        renderDisplay();
        renderBlocked();
    }

    document.addEventListener('click', function (e) {
        const btn = e.target.closest('[data-act]');
        if (!btn) return;
        if (btn.dataset.act === 'save') {
            const admin = document.documentElement.classList.contains('ac-admin-mode');
            const activeBody = $('.apex-tabbody.is-active', $('#panel-settings'));
            const onThemes = activeBody && activeBody.dataset.body === 'themes';
            if (admin) {
                // Admin: apply the current design (theme + accent) for EVERYONE.
                const theme = (window.ApexThemes && window.ApexThemes.selectedId && window.ApexThemes.selectedId())
                    || state.prefs.theme || null;
                ApexBus.post('apex_theme_broadcast', { theme: theme, accent: currentAccentHex() });
            }
            if (onThemes && window.ApexThemes && window.ApexThemes.saveSelected) {
                window.ApexThemes.saveSelected().then(() => ApexUI.close());
            } else {
                syncTheme();
                ApexBus.post('apex_save_prefs', state.prefs).then(() => ApexUI.close());
            }
            return;
        }
        if (btn.dataset.act === 'reset') {
            ApexBus.post('apex_reset_prefs').then((r) => {
                if (r && r.prefs) mount({ prefs: r.prefs, config: state.config });
            });
        }
    });

    function currentAccentHex() {
        const preset = (state.config.presets || []).find(p => p.id === state.prefs.selectedColor);
        if (preset && state.prefs.accentOverride) return preset.hex;
        if (state.prefs.accentOverride && state.prefs.customAccent) return state.prefs.customAccent;
        return null;
    }

    window.ApexSettings = { mount, applyAccent };

    /* ───────── Auto-persist: every setting change sticks + applies live ─────────
       The render handlers update state.prefs, then this debounced commit saves
       them (which round-trips through applyPrefs so the chat updates instantly).
       No need to press SAVE for a change to take effect. */
    let commitTimer = null;
    function commitPrefs() {
        if (!state.prefs) return;
        clearTimeout(commitTimer);
        commitTimer = setTimeout(() => { savePrefs(); }, 250);
    }
    const settingsPanel = document.getElementById('panel-settings');
    if (settingsPanel) {
        // Bubble phase: runs AFTER each control's own handler updated state.prefs.
        settingsPanel.addEventListener('change', () => commitPrefs());
        settingsPanel.addEventListener('click', (e) => {
            // Skip footer actions (save/reset) and tab switches — they handle themselves.
            if (e.target.closest('[data-act]') || e.target.closest('.apex-tab')) return;
            // The THEMES tab has its own save flow (colour themes preview live and
            // are committed via SAVE; design tiles self-persist), so don't auto-commit
            // there — it would revert an unsaved colour-theme preview.
            if (e.target.closest('.apex-tabbody[data-body="themes"]')) return;
            commitPrefs();
        });
    }
})();
