// Apex Chat — Live chat window app.
// Structured + legacy messages, input bar with emoji/GIF/dice/try
// tools, command suggestions, history, avatars, image embeds,
// theme accent + light mode, free-hand drag and auto-hide.

(function () {
    'use strict';

    const MAX_DOM = 150;
    const EMOJIS = ['😀','😃','😄','😁','😆','😅','😂','🤣','😊','😇','🙂','🙃','😉','😍','😘','😋','😜','🤔','🤨','😎','🥳','😏','😢','😭','😡','🤬','😱','🥶','👍','👎','👌','✌️','🤞','🙏','💪','👀','🔥','💯','✅','❌','⚠️','🎉','🎯','💀','☠️','🚓','🚑','🚗','🏠','📱','💬','💰','💊','🍺','❤️','🧡','💛','💚','💙','💜','🖤','🤍'];

    const DEFAULT_FEATURES = {
        EmojiPicker: true, GifSelector: true,
        CommandSuggestions: true, MessageLengthCounter: true, MessageHistory: true,
    };
    const REACTION_EMOJIS = EMOJIS;

    const el = {
        root:    document.getElementById('apex-chat'),
        hiddenbar: document.getElementById('ac-hiddenbar'),
        channel: document.getElementById('ac-channel'),
        menu:    document.getElementById('ac-channel-menu'),
        quick:   document.getElementById('ac-quickchats'),
        feed:    document.getElementById('ac-feed'),
        inputwrap: document.getElementById('ac-inputwrap'),
        suggest: document.getElementById('ac-suggest'),
        pop:     document.getElementById('ac-pop'),
        tools:   document.getElementById('ac-tools'),
        field:   document.getElementById('ac-field'),
        prefix:  document.getElementById('ac-prefix'),
        send:    document.getElementById('ac-send'),
        clear:   document.getElementById('ac-clear'),
        counter: document.getElementById('ac-counter'),
        replybar: document.getElementById('ac-replybar'),
        replyName: document.getElementById('ac-reply-name'),
        replyText: document.getElementById('ac-reply-text'),
        replyCancel: document.getElementById('ac-reply-cancel'),
        typing:   document.getElementById('ac-typing'),
        typingText: document.getElementById('ac-typing-text'),
        mention:  document.getElementById('ac-mention'),
    };

    const state = {
        prefs:    {},
        config:   {},
        features: Object.assign({}, DEFAULT_FEATURES),
        cats:     [],
        active:   'global',
        isManager: false,
        legacySugg: {},
        templates: {},
        avatars:  {},
        avatarPending: {},
        avatarMisses: {},
        history:  [],
        histIdx:  -1,
        suggList: [],
        suggIdx:  -1,
        open:     false,
        hidden:   false,   // /hide — overlay off, server stops delivering
        hideTimer: null,
        messages: {},
        reactions: {},
        replyTo: null,
        editing: null,
        typers: {},
        roster: [],
        mentionList: [],
        mentionIdx: -1,
        mentionAt: -1,
        mutedSenders: {},
        blockedCats: {},
    };

    /* ── Bridge for the settings "Blocked" tab ── */
    let onBlocksChange = null;
    function notifyBlocks() { if (typeof onBlocksChange === 'function') onBlocksChange(); }
    window.ApexBlocks = {
        muted:   () => Object.keys(state.mutedSenders).map(id => ({ id, name: (state.mutedSenders[id] && state.mutedSenders[id].name) || ('ID ' + id) })),
        blocked: () => Object.keys(state.blockedCats).map(cat => ({ cat, label: (state.blockedCats[cat] && state.blockedCats[cat].label) || cat })),
        unmute:  (id)  => { delete state.mutedSenders[id]; notifyBlocks(); },
        unblock: (cat) => { delete state.blockedCats[cat]; notifyBlocks(); },
        onChange: (fn) => { onBlocksChange = fn; },
    };

    const QUICK_CATS = [];
    const QUICK_COMMANDS = [
        { cmd: '/me ', label: '/me', icon: 'fas fa-user' },
    ];
    const LEGACY_META = {
        twitter:       { label: 'X', command: 'x', icon: 'fab fa-x-twitter', color: '#C9CDD1' },
        youtube:       { label: 'YouTube', command: 'youtube', icon: 'fab fa-youtube', color: '#E5564B' },
        twitch:        { label: 'Twitch', command: 'twitch', icon: 'fab fa-twitch', color: '#9C70DE' },
        advertisement: { label: 'Ad', command: 'ad', icon: 'fas fa-rectangle-ad', color: '#34C77B' },
        anonymous:     { label: 'Anonymous', command: 'anon', icon: 'fas fa-user-secret', color: '#8E8E93' },
        ooc:           { label: 'OOC', command: 'ooc', icon: 'fas fa-comments', color: '#8E8E93' },
        pm:            { label: 'PM', command: 'pm', icon: 'fas fa-envelope', color: '#1F5EFF' },
        police:        { label: 'Police', command: 'police', icon: 'fas fa-bullhorn', color: '#1F5EFF' },
        ambulance:     { label: 'EMS', command: 'ambulance', icon: 'fas fa-truck-medical', color: '#E5A93C' },
        jobchat:       { label: 'Job', command: 'jobc', icon: 'fas fa-briefcase', color: '#4E9CE5' },
        staff:         { label: 'Staff', command: 'staff', icon: 'fas fa-shield-halved', color: '#34C77B' },
        staffonly:     { label: 'Staff', command: 'staffo', icon: 'fas fa-lock', color: '#34C77B' },
        system:        { label: 'System', command: '', icon: 'fas fa-circle-info', color: '#E5A93C' },
        'server-msg':  { label: 'Server', command: 'sa', icon: 'fas fa-bullhorn', color: '#E5564B' },
        muted:         { label: 'Muted', command: '', icon: 'fas fa-volume-xmark', color: '#E5A93C' },
    };

    function esc(s) {
        return String(s == null ? '' : s).replace(/[&<>"']/g, c => ({ '&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;' }[c]));
    }
    function shortText(s, max) {
        s = String(s == null ? '' : s).replace(/\s+/g, ' ').trim();
        return s.length > max ? s.slice(0, max - 1) + '…' : s;
    }
    function tpl(t, args) {
        args = args || [];
        return String(t).replace(/\{(\d+)\}/g, (m, i) => (args[i] != null ? args[i] : ''));
    }
    function hexToRgba(hex, a) {
        const m = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(String(hex || ''));
        if (!m) return 'var(--accentSoft)';
        return `rgba(${parseInt(m[1],16)},${parseInt(m[2],16)},${parseInt(m[3],16)},${a})`;
    }
    function hexToRgbParts(hex) {
        const m = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(String(hex || ''));
        if (!m) return '255,115,250';
        return `${parseInt(m[1],16)},${parseInt(m[2],16)},${parseInt(m[3],16)}`;
    }
    function chipStyle(color) {
        const c = color && /^#?[a-f\d]{6}$/i.test(color) ? (color[0] === '#' ? color : '#' + color) : null;
        return c ? `background:${hexToRgba(c, .16)};color:${c}` : '';
    }
    function hashString(input) {
        let h = 0;
        const s = String(input || '');
        for (let i = 0; i < s.length; i++) h = ((h << 5) - h + s.charCodeAt(i)) | 0;
        return Math.abs(h).toString(36);
    }

    /* ───────── Prefs (size / position / visibility / theme) ───────── */
    function applyPrefs(p) {
        state.prefs = p || {};
        state.features = Object.assign({}, DEFAULT_FEATURES, state.prefs.features || {});
        el.root.dataset.size = p.chatSize || 'medium';
        el.root.dataset.vis  = p.visibility || 'when-message';
        el.root.dataset.design = p.chatDesign || 'apex';   // chat layout theme
        // Message-display preferences (survive the className reset below via data-*).
        el.root.dataset.time    = p.showTime      === false ? 'off' : 'on';
        el.root.dataset.id      = p.showId        === false ? 'off' : 'on';
        el.root.dataset.avatars = p.showAvatars   === false ? 'off' : 'on';
        el.root.dataset.tags    = p.showTags      === false ? 'off' : 'on';
        el.root.dataset.mine    = p.highlightMine === false ? 'off' : 'on';
        el.root.dataset.font    = p.fontSize || 'md';
        el.root.dataset.density = p.density  || 'cozy';

        // Free-hand drag overrides anchored positions.
        if (p.freeHand && p.rect && (p.rect.x != null)) {
            el.root.className = 'apex-chat is-free';
            el.root.style.left = p.rect.x + 'px';
            el.root.style.top  = p.rect.y + 'px';
        } else {
            el.root.className = 'apex-chat is-pos-' + (p.position || 'top-left');
            el.root.style.left = ''; el.root.style.top = '';
        }
        // Rewriting className above drops the runtime state classes.
        if (state.hidden) el.root.classList.add('ac-hidden', 'ac-feedhidden');
        if (p.activeCategory) state.active = p.activeCategory;

        // Theme = palette (bg/panel/text); color preset = accent on top.
        if (window.ApexThemes && p.theme) window.ApexThemes.apply(p.theme);
        if (p.accentOverride && p.selectedColor) applyAccent(p.selectedColor);
        document.documentElement.classList.toggle('ac-light', !p.theme && p.themeMode === 'light');

        // Message length.
        const maxLen = parseInt(p.maxMessageLength, 10) || 300;
        el.field.maxLength = maxLen;

        applyFeatures();
        tickVisibility();
    }

    function applyAccent(presetId) {
        const presets = state.config.presets || [];
        const hit = presets.find(x => x.id === presetId);
        if (hit && hit.hex) {
            document.documentElement.style.setProperty('--accent', hit.hex);
            document.documentElement.style.setProperty('--accentSoft', hexToRgba(hit.hex, .16));
        }
    }

    // Time formatting (24h default, optional 12h AM/PM).
    function fmtTime(t) {
        const s = String(t || '');
        if (state.prefs.timeFormat !== '12') return s;
        const m = /^(\d{1,2}):(\d{2})(.*)$/.exec(s);
        if (!m) return s;
        let h = parseInt(m[1], 10);
        const ap = h >= 12 ? 'PM' : 'AM';
        h = h % 12; if (h === 0) h = 12;
        return `${h}:${m[2]} ${ap}`;
    }

    // Optional soft "pop" when a new message arrives (Web Audio, no asset).
    let audioCtx = null, soundReady = false;
    setTimeout(() => { soundReady = true; }, 3000); // skip the initial history replay
    function beep() {
        if (!state.prefs.sound || !soundReady) return;
        try {
            audioCtx = audioCtx || new (window.AudioContext || window.webkitAudioContext)();
            const o = audioCtx.createOscillator(), g = audioCtx.createGain();
            o.type = 'sine'; o.frequency.value = 660;
            g.gain.value = 0.045;
            o.connect(g); g.connect(audioCtx.destination);
            o.start();
            g.gain.exponentialRampToValueAtTime(0.0001, audioCtx.currentTime + 0.18);
            o.stop(audioCtx.currentTime + 0.2);
        } catch (_) { /* audio unavailable */ }
    }

    // Two-tone chime for @mentions — plays even with the normal message
    // sound off (disable with prefs.mentionSound = false).
    function mentionBeep() {
        if (state.prefs.mentionSound === false || !soundReady) return;
        try {
            audioCtx = audioCtx || new (window.AudioContext || window.webkitAudioContext)();
            [660, 990].forEach((f, i) => {
                const o = audioCtx.createOscillator(), g = audioCtx.createGain();
                o.type = 'sine'; o.frequency.value = f;
                o.connect(g); g.connect(audioCtx.destination);
                const t0 = audioCtx.currentTime + i * 0.12;
                g.gain.setValueAtTime(0.06, t0);
                g.gain.exponentialRampToValueAtTime(0.0001, t0 + 0.16);
                o.start(t0);
                o.stop(t0 + 0.18);
            });
        } catch (_) { /* audio unavailable */ }
    }

    function applyFeatures() {
        const f = state.features;
        const show = (tool, on) => {
            const b = el.tools.querySelector(`.ac-tool[data-tool="${tool}"]`);
            if (b) b.hidden = !on;
        };
        show('emoji', f.EmojiPicker);
        show('gif',   f.GifSelector);
        el.counter.style.display = f.MessageLengthCounter ? '' : 'none';
    }

    /* ───────── Visibility (okok-style auto-hide) ───────── */
    let lastActivity = -1e7;  // start hidden until the first message
    function nowMs() { return (window.performance && performance.now) ? performance.now() : Date.now(); }
    function showFeed() { lastActivity = nowMs(); if (!state.hidden) el.root.classList.remove('ac-feedhidden'); }
    function tickVisibility() {
        if (state.hidden) { el.root.classList.add('ac-feedhidden'); return; }
        const mode = state.prefs.visibility || 'when-message';
        // "Open" only counts if the NUI actually holds focus, so a lost
        // focus without a proper close still lets the chat auto-hide.
        const reallyOpen = state.open && document.hasFocus();
        if (reallyOpen || mode === 'always') { el.root.classList.remove('ac-feedhidden'); return; }
        const hideMs = mode === 'when-active' ? (state.prefs.inactiveHideMs || 10000) : (state.prefs.visibilityHideMs || 8000);
        if (nowMs() - lastActivity > hideMs) el.root.classList.add('ac-feedhidden');
        else el.root.classList.remove('ac-feedhidden');
    }
    setInterval(tickVisibility, 400);

    /* ───────── Tabs ───────── */
    function activeCat() { return state.cats.find(c => c.id === state.active) || state.cats[0]; }
    function findCat(idOrCommand) {
        const key = String(idOrCommand || '').toLowerCase();
        if (!key) return null;
        return state.cats.find(c => String(c.id || '').toLowerCase() === key || String(c.command || '').toLowerCase() === key) || null;
    }
    function resolveLegacyMeta(kind) {
        const base = Object.assign({
            label: 'Chat',
            command: '',
            icon: 'fas fa-comment',
            color: '#1F5EFF',
        }, LEGACY_META[kind] || {});
        const cat = findCat(kind) || findCat(base.command);
        if (cat) {
            base.cat = cat.id;
            base.label = cat.label || base.label;
            base.command = cat.command || base.command;
            base.icon = cat.icon || base.icon;
            base.color = cat.color || base.color;
        } else {
            base.cat = kind || base.command || 'legacy';
        }
        return base;
    }
    function renderTabs() {
        el.menu.innerHTML = '';
        state.cats.forEach(c => {
            const b = document.createElement('button');
            b.type = 'button';
            b.className = 'ac-channel-item' + (c.id === state.active ? ' is-active' : '');
            b.style.setProperty('--cat', c.color || 'var(--accent)');
            b.style.setProperty('--cat-rgb', hexToRgbParts(c.color));
            b.innerHTML = `<i class="${esc(c.icon || 'fas fa-comment')}"></i><span>${esc(c.label)}</span>`;
            b.addEventListener('click', () => setActive(c.id));
            el.menu.appendChild(b);
        });
        updatePrefix();
        renderQuickChats();
    }
    function renderQuickChats() {
        if (!el.quick) return;
        el.quick.innerHTML = '';
        QUICK_CATS.forEach(id => {
            const c = state.cats.find(cat => cat.id === id || cat.command === id);
            if (!c) return;

            const b = document.createElement('button');
            b.type = 'button';
            b.className = 'ac-quick' + (c.id === state.active ? ' is-active' : '');
            b.style.setProperty('--cat', c.color || 'var(--accent)');
            b.style.setProperty('--cat-rgb', hexToRgbParts(c.color));
            b.innerHTML = `<i class="${esc(c.icon || 'fas fa-comment')}"></i><span>${esc(c.label)}</span>`;
            b.addEventListener('click', () => setActive(c.id));
            el.quick.appendChild(b);
        });
        QUICK_COMMANDS.forEach(item => {
            const b = document.createElement('button');
            b.type = 'button';
            b.className = 'ac-quick ac-quick-command';
            b.innerHTML = `<i class="${esc(item.icon)}"></i><span>${esc(item.label)}</span>`;
            b.addEventListener('click', () => {
                openChat(item.cmd);
                setTimeout(() => {
                    el.field.setSelectionRange(el.field.value.length, el.field.value.length);
                    el.field.focus();
                }, 0);
            });
            el.quick.appendChild(b);
        });
    }
    function setActive(id) {
        if (!state.cats.some(c => c.id === id)) return;
        state.active = id;
        renderTabs();
        closeChannelMenu();
        ApexBus.post('apex_chat_active_cat', { cat: id });
        if (state.open) el.field.focus();
    }
    function cycleTab(dir) {
        if (!state.cats.length) return;
        let i = state.cats.findIndex(c => c.id === state.active);
        i = (i + dir + state.cats.length) % state.cats.length;
        setActive(state.cats[i].id);
    }
    function updatePrefix() {
        const c = activeCat();
        if (!c) { el.prefix.innerHTML = '<i class="fas fa-comment"></i><span>CHAT</span><i class="fas fa-chevron-down ac-chev"></i>'; return; }
        el.prefix.innerHTML = `<i class="${esc(c.icon || 'fas fa-comment')}"></i><span>${esc(c.label.toUpperCase())}</span><i class="fas fa-chevron-down ac-chev"></i>`;
        // The composer (input ring + send button) keeps a fixed theme-brand
        // colour on purpose — it must not follow the active channel.
        // Header shows the active channel as a coloured badge + name.
        const hb = document.getElementById('ac-head-badge');
        const hn = document.getElementById('ac-head-name');
        if (hb) {
            hb.style.setProperty('--cat', c.color || 'var(--accent)');
            hb.innerHTML = `<i class="${esc(c.icon || 'fas fa-comment')}"></i>`;
        }
        if (hn) hn.textContent = (c.label || 'CHAT').toUpperCase();
    }

    function openChannelMenu() {
        if (!state.cats.length) return;
        el.channel.classList.add('is-open');
        el.menu.hidden = false;
    }
    function closeChannelMenu() {
        el.channel.classList.remove('is-open');
        el.menu.hidden = true;
    }
    function toggleChannelMenu() {
        if (el.menu.hidden) openChannelMenu();
        else closeChannelMenu();
    }

    /* ───────── Messages ───────── */
    function initials(name) {
        const clean = String(name || '?').replace(/\s*\[\d+\]\s*$/, '').trim();
        const parts = clean.split(/\s+/).filter(Boolean);
        const a = (parts[0] || '?')[0] || '?';
        const b = parts.length > 1 ? (parts[parts.length - 1][0] || '') : '';
        return (a + b).toUpperCase();
    }
    function trimFeed() { while (el.feed.children.length > MAX_DOM) el.feed.removeChild(el.feed.firstChild); }
    function atBottom() { return (el.feed.scrollHeight - el.feed.scrollTop - el.feed.clientHeight) < 40; }
    // Pin to the bottom now AND again after the browser reflows (images /
    // fonts can grow the feed a frame later). Runs even when the chat is
    // closed so the newest message is always visible without opening it.
    function scrollDown(force) {
        if (!(force || atBottom())) return;
        el.feed.scrollTop = el.feed.scrollHeight;
        requestAnimationFrame(() => { el.feed.scrollTop = el.feed.scrollHeight; });
    }
    // Track whether the feed is pinned to the bottom so late-loading images
    // (which grow the feed) keep the newest message in view unless the user
    // has scrolled up to read history.
    let stickBottom = true;
    el.feed.addEventListener('scroll', () => { stickBottom = atBottom(); });

    // Turn URLs into links, image/GIF URLs into thumbnails, and
    // highlight @mentions.
    function richText(raw) {
        let s = esc(raw);
        s = s.replace(/(https?:\/\/[^\s<]+)/g, (url) => {
            if (/\.(gif|png|jpe?g|webp)(\?[^\s]*)?$/i.test(url) || /(giphy\.com\/media|tenor\.com|media\.tenor)/i.test(url)) {
                return `<img class="ac-img" src="${url}" alt="">`;
            }
            return `<a href="${url}" target="_blank">${url}</a>`;
        });
        s = s.replace(/(^|[\s(])@([\wÀ-ÿ][\wÀ-ÿ.\-]*)/g, '$1<span class="ac-mention">@$2</span>');
        return s;
    }

    function renderReactionList(list) {
        list = Array.isArray(list) ? list : [];
        return list.filter(r => r && r.count > 0 && REACTION_EMOJIS.includes(r.type))
            .map(r => `<button class="ac-reaction-pill" type="button" data-react="${esc(r.type)}"><span class="ac-reaction-emoji">${esc(r.type)}</span><span>${esc(r.count)}</span></button>`)
            .join('');
    }

    function bindReactionButtons(container, id, node) {
        if (!container || !id) return;
        container.querySelectorAll('[data-react]').forEach(btn => {
            if (btn.dataset.bound === '1') return;
            btn.dataset.bound = '1';
            btn.addEventListener('click', (e) => {
                e.stopPropagation();
                sendReaction(id, btn.dataset.react);
                if (node) {
                    node.classList.add('has-reactions');
                    node.classList.remove('is-reacting');
                }
                closeReactionPickers();
            });
        });
    }

    function updateReactionRow(id, reactions) {
        if (!id) return;
        state.reactions[id] = reactions || [];
        Array.from(el.feed.querySelectorAll('.ac-msg[data-msg-id]')).forEach(node => {
            if (node.dataset.msgId !== String(id)) return;
            const row = node.querySelector('[data-reactions]');
            const html = renderReactionList(state.reactions[id]);
            if (row) row.innerHTML = html;
            node.classList.toggle('has-reactions', html !== '');
            bindReactionButtons(row, id, node);
        });
    }

    function clearFeed() {
        el.feed.innerHTML = '';
        state.messages = {};
        state.reactions = {};
        closeReactionPickers();
        closeMessageMenus();
        showFeed();
    }

    function copyText(text) {
        text = String(text == null ? '' : text);
        if (navigator.clipboard && navigator.clipboard.writeText) {
            navigator.clipboard.writeText(text).catch(() => {});
            return;
        }
        const area = document.createElement('textarea');
        area.value = text;
        area.style.position = 'fixed';
        area.style.opacity = '0';
        document.body.appendChild(area);
        area.select();
        try { document.execCommand('copy'); } catch (_) {}
        area.remove();
    }

    function closeMessageMenus(except) {
        el.feed.querySelectorAll('.ac-msg-menu').forEach(menu => {
            if (menu !== except) {
                menu.hidden = true;
                const msg = menu.closest('.ac-msg');
                if (msg) msg.classList.remove('is-menu-open');
            }
        });
    }

    // Scroll the feed to a message by id and flash-highlight it.
    let flashTimer = null;
    function jumpToMessage(id) {
        if (!id) return;
        const target = el.feed.querySelector(`.ac-msg[data-msg-id="${CSS.escape(String(id))}"]`);
        if (!target) return;
        target.scrollIntoView({ block: 'center', behavior: 'smooth' });
        el.feed.querySelectorAll('.ac-msg.ac-flash').forEach(n => n.classList.remove('ac-flash'));
        void target.offsetWidth;  // restart the animation if re-jumping
        target.classList.add('ac-flash');
        clearTimeout(flashTimer);
        flashTimer = setTimeout(() => target.classList.remove('ac-flash'), 1400);
    }

    function renderReplyBar() {
        if (state.editing) {
            el.replyName.textContent = 'Editing message (admin)';
            el.replyText.textContent = shortText(state.editing.text || '', 90);
            el.replybar.hidden = false;
            return;
        }
        if (!state.replyTo) {
            el.replybar.hidden = true;
            el.replyName.textContent = 'Reply';
            el.replyText.textContent = '';
            return;
        }
        el.replyName.textContent = 'Replying to ' + (state.replyTo.sender || 'message');
        el.replyText.textContent = shortText(state.replyTo.text || '', 90);
        el.replybar.hidden = false;
    }

    function clearReply() {
        state.replyTo = null;
        state.editing = null;
        renderReplyBar();
    }

    // Admin: edit a message for everyone (server re-broadcasts the text).
    function startEdit(msg) {
        if (!msg || !msg.id || !state.isManager) return;
        state.replyTo = null;
        state.editing = { id: msg.id, text: msg.text || '' };
        renderReplyBar();
        if (!state.open) openChat(msg.text || '');
        else { el.field.value = msg.text || ''; updateCounter(); el.field.focus(); }
    }

    function startReply(msg) {
        if (!msg || !msg.id) return;
        const cat = findCat(msg.cat) || findCat(msg.command);
        state.replyTo = {
            id: msg.id,
            sender: msg.sender || '',
            text: msg.text || '',
            cat: cat ? cat.id : (msg.cat || ''),
            command: msg.command || (cat && cat.command) || '',
        };
        renderReplyBar();
        if (cat) setActive(cat.id);
        if (!state.open) openChat();
        else setTimeout(() => el.field.focus(), 0);
    }

    function sendReaction(id, type) {
        if (!id || !REACTION_EMOJIS.includes(type)) return;
        ApexBus.post('apex_chat_react', { id, type });
    }

    function replyCategory() {
        if (!state.replyTo) return activeCat();
        return findCat(state.replyTo.cat) || findCat(state.replyTo.command) || activeCat();
    }

    function commandFallbackText(text) {
        if (!state.replyTo || !state.replyTo.command || text.startsWith('/')) return text;
        if (findCat(state.replyTo.cat) || findCat(state.replyTo.command)) return text;
        return '/' + state.replyTo.command + ' ' + text;
    }

    function applyAvatar(id) {
        const url = state.avatars[id];
        if (!url) return;
        el.feed.querySelectorAll(`.ac-msg[data-sender="${id}"] .ac-avatar`).forEach(av => {
            av.innerHTML = `<img src="${esc(url)}" data-mug="${esc(id)}" alt="" loading="lazy" onerror="this.remove()">`;
        });
    }

    function hydrateAvatar(id, force) {
        if (!id) return;
        if (state.avatars[id]) { applyAvatar(id); return; }
        if (state.avatarPending[id]) return;
        if (state.avatarMisses[id] && !force) return;

        state.avatarPending[id] = true;
        ApexBus.post('apex_chat_mugshot', { id }).then(r => {
            state.avatarPending[id] = false;
            if (r && r.ok && r.url) {
                state.avatars[id] = r.url;
                state.avatarMisses[id] = false;
                applyAvatar(id);
            } else {
                state.avatarMisses[id] = true;
            }
        }).catch(() => {
            state.avatarPending[id] = false;
            state.avatarMisses[id] = true;
        });
    }

    function closeReactionPickers(except) {
        el.feed.querySelectorAll('.ac-reaction-picker').forEach(picker => {
            if (picker !== except) {
                picker.hidden = true;
                const msg = picker.closest('.ac-msg');
                if (msg) msg.classList.remove('is-reacting');
            }
        });
    }

    // Open a floating panel upward when it would extend past the feed's
    // visible bottom (an absolutely-positioned panel below the last
    // message would otherwise grow the feed's scroll height).
    function autoFlip(panel) {
        panel.classList.remove('is-up');
        const fr = el.feed.getBoundingClientRect();
        if (panel.getBoundingClientRect().bottom > fr.bottom - 4) panel.classList.add('is-up');
    }

    function bindMessageActions(node, msg) {
        const reply = node.querySelector('[data-act="reply"]');
        if (reply) reply.addEventListener('click', () => startReply(msg));
        const jump = node.querySelector('.ac-reply-preview[data-jump]');
        if (jump) jump.addEventListener('click', (e) => {
            e.stopPropagation();
            jumpToMessage(jump.dataset.jump);
        });
        const pickerButton = node.querySelector('[data-act="react-picker"]');
        const picker = node.querySelector('.ac-reaction-picker');
        const menuButton = node.querySelector('[data-act="message-menu"]');
        const menu = node.querySelector('.ac-msg-menu');
        if (pickerButton && picker) {
            pickerButton.addEventListener('click', (e) => {
                e.stopPropagation();
                const willOpen = picker.hidden;
                closeMessageMenus();
                closeReactionPickers(picker);
                picker.hidden = !willOpen;
                node.classList.toggle('is-reacting', willOpen);
                if (willOpen) autoFlip(picker);
            });
        }
        if (menuButton && menu) {
            menuButton.addEventListener('click', (e) => {
                e.stopPropagation();
                const willOpen = menu.hidden;
                closeReactionPickers();
                closeMessageMenus(menu);
                menu.hidden = !willOpen;
                node.classList.toggle('is-menu-open', willOpen);
                if (willOpen) autoFlip(menu);
            });
            menu.addEventListener('click', (e) => {
                const item = e.target.closest('[data-menu-act]');
                if (!item) return;
                e.stopPropagation();
                const act = item.dataset.menuAct;
                if (act === 'react') {
                    if (pickerButton) pickerButton.click();
                    return;
                }
                if (act === 'copy') copyText(msg.text || '');
                else if (act === 'call') openChat(msg.senderId ? `/call ${msg.senderId} ` : '/call ');
                else if (act === 'edit') startEdit(msg);
                else if (act === 'delete') ApexBus.post('apex_chat_admin', { act: 'remove', id: msg.id });
                else if (act === 'mute' && msg.senderId) {
                    state.mutedSenders[msg.senderId] = { name: (msg.sender || ('ID ' + msg.senderId)).replace(/\s*\[\d+\]\s*$/, '').trim() || ('ID ' + msg.senderId) };
                    el.feed.querySelectorAll('.ac-msg[data-sender]').forEach(n => {
                        if (n.dataset.sender === String(msg.senderId)) n.remove();
                    });
                    notifyBlocks();
                } else if (act === 'block' && msg.cat) {
                    state.blockedCats[msg.cat] = { label: msg.catLabel || (findCat(msg.cat) && findCat(msg.cat).label) || String(msg.cat) };
                    el.feed.querySelectorAll('.ac-msg[data-cat]').forEach(n => {
                        if (n.dataset.cat === String(msg.cat)) n.remove();
                    });
                    notifyBlocks();
                }
                closeMessageMenus();
                node.classList.remove('is-menu-open');
            });
        }
        bindReactionButtons(node, msg.id, node);
    }

    function renderStructured(m) {
        if (m.senderId && state.mutedSenders[m.senderId]) return;
        if (m.cat && state.blockedCats[m.cat]) return;
        const node = document.createElement('div');
        const initialReactions = renderReactionList(m.reactions || state.reactions[m.id]);
        node.className = 'ac-msg'
            + (m.mine ? ' is-mine' : '')
            + (m.showAvatar ? '' : ' no-avatar')
            + (m.mention && !m.mine ? ' is-mention' : '')
            + (initialReactions ? ' has-reactions' : '');
        node.style.setProperty('--cat', m.color || 'var(--accent)');
        node.style.setProperty('--cat-rgb', hexToRgbParts(m.color));
        if (m.id) {
            node.dataset.msgId = m.id;
            state.messages[m.id] = {
                id: m.id,
                sender: m.sender,
                text: m.text,
            };
        }
        if (m.cat) node.dataset.cat = m.cat;
        if (m.senderId) node.dataset.sender = m.senderId;
        const avatarUrl = m.showAvatar && m.senderId && state.avatars[m.senderId];
        const ini = initials(m.sender);
        const avatarInner = avatarUrl
            ? `<img src="${esc(avatarUrl)}" data-mug="${esc(m.senderId)}" alt="" loading="lazy" onerror="this.remove()">`
            : (m.avatarIcon ? `<i class="${esc(m.avatarIcon)}"></i>`
                : (ini && ini !== '?' ? esc(ini) : '<i class="fas fa-comment-dots"></i>'));
        const replyHtml = m.replyTo ? `
                <button class="ac-reply-preview" type="button" data-jump="${esc(m.replyTo.id || '')}" title="Go to message">
                    <i class="fas fa-reply"></i>
                    <strong>${esc(m.replyTo.sender || 'Reply')}</strong>
                    <span>${esc(shortText(m.replyTo.text || '', 110))}</span>
                </button>` : '';
        const imageHtml = m.image ? `<img class="ac-img ac-photo-img" src="${esc(m.image)}" alt="" loading="lazy">` : '';
        const chCat = findCat(m.cat);
        const chLabel = (m.catLabel || (chCat && chCat.label) || '').toString();
        const chIcon = (chCat && chCat.icon) || m.avatarIcon || '';
        const chipHtml = chLabel
            ? `<span class="ac-chip">${chIcon ? `<i class="${esc(chIcon)}"></i>` : ''}<span>${esc(chLabel)}</span></span>`
            : '';
        const tagsHtml = (window.ApexTagPill && Array.isArray(m.tags)) ? m.tags.map(window.ApexTagPill).join('') : '';
        // Split a trailing " [123]" server id off the name so it can be toggled
        // independently (data-id on the root).
        const senderStr = String(m.sender == null ? '' : m.sender);
        const idM = /\s*\[(\d+)\]\s*$/.exec(senderStr);
        const dispName = idM ? senderStr.slice(0, idM.index) : senderStr;
        const idHtml = idM ? `<span class="ac-msgid">[${esc(idM[1])}]</span>` : '';
        // Real (server-broadcast) edit/delete are admin-only actions.
        const adminHtml = (state.isManager && !m.legacy && m.id) ? `
                    <hr>
                    <button type="button" data-menu-act="edit"><i class="fas fa-pen"></i><span>Edit (admin)</span></button>
                    <button type="button" data-menu-act="delete" class="is-danger"><i class="fas fa-trash"></i><span>Delete (admin)</span></button>` : '';
        node.innerHTML = `
            <div class="ac-avatar">${avatarInner}</div>
            <div class="ac-body">
                <div class="ac-meta">
                    <span class="ac-name">${esc(dispName)}</span>${idHtml}
                    ${tagsHtml}
                    ${chipHtml}
                    <span class="ac-time">${esc(fmtTime(m.time))}</span>
                </div>
                <div class="ac-msg-menu" hidden>
                    <button type="button" data-menu-act="react"><i class="far fa-face-smile"></i><span>Add reaction</span></button>
                    <button type="button" data-menu-act="copy"><i class="fas fa-copy"></i><span>Copy text</span></button>
                    <button type="button" data-menu-act="call"><i class="fas fa-phone"></i><span>Start call</span></button>
                    <hr>
                    <button type="button" data-menu-act="mute"><i class="fas fa-bell-slash"></i><span>Mute user</span></button>
                    <button type="button" data-menu-act="block" class="is-danger"><i class="fas fa-ban"></i><span>Block Chat</span></button>
                    ${adminHtml}
                </div>
                ${replyHtml}
                <div class="ac-text">${richText(m.text)}</div>
                ${imageHtml}
            </div>
            <div class="ac-reactions" data-reactions>${initialReactions}</div>
            <div class="ac-msg-actions">
                <button class="ac-msg-action" type="button" data-act="reply" title="Reply"><i class="fas fa-reply"></i></button>
                <button class="ac-msg-action" type="button" data-act="react-picker" title="React"><i class="far fa-face-smile"></i></button>
                <button class="ac-msg-action" type="button" data-act="message-menu" title="More"><i class="fas fa-bars"></i></button>
                <div class="ac-reaction-picker" hidden>
                    ${REACTION_EMOJIS.map(emoji => `<button class="ac-reaction-option" type="button" data-react="${esc(emoji)}">${esc(emoji)}</button>`).join('')}
                </div>
            </div>`;
        bindMessageActions(node, m);
        push(node);
        if (!m.mine) {
            if (m.mention) mentionBeep();
            else beep();
        }
        if (m.showAvatar && m.senderId) hydrateAvatar(m.senderId);
    }

    function iconClasses(icon) {
        if (!icon) return '';
        return Array.from(icon.classList || [])
            .filter(c => c === 'fa' || c === 'fas' || c === 'far' || c === 'fab' || c.indexOf('fa-') === 0)
            .join(' ');
    }

    function textFromClone(node, removeSender) {
        if (!node) return '';
        const clone = node.cloneNode(true);
        clone.querySelectorAll('style,script,.time,i').forEach(n => n.remove());
        if (removeSender) {
            const sender = clone.querySelector('b,strong');
            if (sender) sender.remove();
        }
        return clone.textContent.replace(/\s+/g, ' ').trim();
    }

    function legacyToStructured(msg, html) {
        const host = document.createElement('div');
        host.innerHTML = html || '';
        if (host.querySelector('style') && !host.textContent.trim()) return null;

        const bubble = host.querySelector('.chat-message') || host.firstElementChild || host;
        const classes = Array.from(bubble.classList || []);
        const kind = classes.find(c => LEGACY_META[c]) || '';
        const meta = resolveLegacyMeta(kind);
        const icon = iconClasses(bubble.querySelector('i')) || meta.icon;
        const timeEl = bubble.querySelector('.time');
        const time = timeEl ? timeEl.textContent.trim() : '';
        const messageEl = bubble.querySelector('.message') || bubble;
        const senderEl = bubble.querySelector('b,strong');

        let sender = senderEl ? senderEl.textContent.replace(time, '').replace(/\s+/g, ' ').trim() : '';
        if (!sender || sender.length > 48) sender = meta.label;

        let text = textFromClone(messageEl, !!senderEl);
        if (!text) text = textFromClone(bubble, !!senderEl);
        if (!text) text = typeof msg === 'string' ? msg : '';

        const idSeed = [
            meta.cat,
            meta.command,
            sender,
            text,
            time,
            html,
        ].join('|');

        return {
            id: (msg && (msg._apexId || msg.id)) || ('legacy-' + hashString(idSeed)),
            cat: meta.cat,
            catLabel: meta.label,
            command: meta.command,
            color: meta.color,
            icon: icon,
            avatarIcon: icon,
            identity: 'legacy',
            sender: sender,
            senderId: false,
            text: text,
            time: time,
            showAvatar: true,
            legacy: true,
        };
    }

    function renderLegacy(msg) {
        let html;
        if (msg && msg.templateId === 'apex_chat_inject_vars') return;
        if (msg && msg.templateId && state.templates[msg.templateId]) html = tpl(state.templates[msg.templateId], msg.args || []);
        else if (msg && msg.template) html = tpl(msg.template, msg.args || []);
        else if (msg && Array.isArray(msg.args)) {
            const color = Array.isArray(msg.color) ? `rgb(${msg.color.join(',')})` : 'var(--accent)';
            const head = msg.args.length > 1 ? `<b style="color:${color}">${esc(msg.args[0])}</b> ` : '';
            const body = esc(msg.args.length > 1 ? msg.args.slice(1).join(' ') : (msg.args[0] || ''));
            html = `<div class="chat-message"><div class="message">${head}${body}</div></div>`;
        } else html = `<div class="chat-message"><div class="message">${esc(typeof msg === 'string' ? msg : '')}</div></div>`;

        const structured = legacyToStructured(msg, html);
        if (structured) renderStructured(structured);
    }

    function push(node) {
        el.feed.appendChild(node);
        trimFeed();
        stickBottom = true;
        scrollDown(true);
        showFeed();
        // Slow images (GIFs / photos) only get their real height once loaded,
        // AFTER we first scrolled — which left them cut off until the chat was
        // reopened. Re-pin to the bottom as each image in a fresh message
        // finishes (or fails) loading, even while the chat is closed.
        const imgs = node.querySelectorAll ? node.querySelectorAll('img') : [];
        imgs.forEach(img => {
            if (img.complete) return;
            const pin = () => {
                if (node === el.feed.lastElementChild || stickBottom) {
                    el.feed.scrollTop = el.feed.scrollHeight;
                }
            };
            img.addEventListener('load', pin, { once: true });
            img.addEventListener('error', pin, { once: true });
        });
    }
    function setAvatar(id, url) {
        state.avatars[id] = url;
        applyAvatar(id);
    }

    /* ───────── Suggestions ───────── */
    function allSuggestions() {
        const out = [];
        state.cats.forEach(c => out.push({ cmd: '/' + c.command, help: c.label + ' chat', params: 'message' }));
        Object.keys(state.legacySugg).forEach(name => {
            const s = state.legacySugg[name];
            out.push({ cmd: name.startsWith('/') ? name : '/' + name, help: s.help || '', params: (s.params || []).map(p => p.name).join(' ') });
        });
        return out;
    }
    function refreshSuggest() {
        if (!state.features.CommandSuggestions) { hideSuggest(); return; }
        const v = el.field.value;
        if (!v.startsWith('/')) { hideSuggest(); return; }
        closePop();
        const q = v.slice(1).toLowerCase();
        state.suggList = allSuggestions().filter(s => s.cmd.slice(1).toLowerCase().startsWith(q));
        if (!state.suggList.length) { hideSuggest(); return; }
        // Nothing highlighted until the player presses ↓/↑ — so a plain Enter
        // sends the command as typed instead of picking a suggestion.
        state.suggIdx = -1;
        el.suggest.hidden = false;
        el.suggest.innerHTML = '';
        state.suggList.forEach((s, i) => {
            const row = document.createElement('div');
            row.className = 'ac-sugg-item';
            row.innerHTML = `<span class="ac-sugg-cmd">${esc(s.cmd)}</span><span class="ac-sugg-help">${esc(s.help)}</span>${s.params ? `<span class="ac-sugg-params">${esc(s.params)}</span>` : ''}`;
            row.addEventListener('click', () => { applySuggest(i); el.field.focus(); });
            el.suggest.appendChild(row);
        });
    }
    function hideSuggest() { el.suggest.hidden = true; state.suggList = []; state.suggIdx = -1; }
    function moveSuggest(d) {
        if (!state.suggList.length) return;
        const n = state.suggList.length;
        // From "no selection" (-1), ↓ starts at the first, ↑ at the last.
        state.suggIdx = state.suggIdx < 0 ? (d > 0 ? 0 : n - 1) : (state.suggIdx + d + n) % n;
        Array.from(el.suggest.children).forEach((c, i) => c.classList.toggle('is-active', i === state.suggIdx));
    }
    function applySuggest(i) {
        const s = state.suggList[i != null ? i : state.suggIdx];
        if (!s) return;
        el.field.value = s.cmd + ' ';
        hideSuggest(); updateCounter();
    }

    /* ───────── @mention autocomplete (online players) ───────── */
    function hideMention() {
        if (el.mention) el.mention.hidden = true;
        state.mentionList = []; state.mentionIdx = -1; state.mentionAt = -1;
    }
    // The @token being typed at the caret, or null. Returns {token, at}.
    function mentionToken() {
        const f = el.field;
        const caret = f.selectionStart != null ? f.selectionStart : f.value.length;
        const left = f.value.slice(0, caret);
        // @ must start the string or follow whitespace/( ; token has no spaces.
        const m = /(^|[\s(])@([\wÀ-ÿ.\-]*)$/.exec(left);
        if (!m) return null;
        return { token: m[2], at: caret - m[2].length - 1 };
    }
    function refreshMention() {
        if (!el.mention || (state.config.Mentions && state.config.Mentions.enabled === false)) { hideMention(); return; }
        const info = mentionToken();
        if (!info || !state.roster.length) { hideMention(); return; }
        closePop(); hideSuggest();
        const q = info.token.toLowerCase();
        // Match players whose full name OR first name starts with the query.
        const list = state.roster.filter(p => {
            const nm = (p.name || '').toLowerCase();
            const fn = (p.first || '').toLowerCase();
            return nm.startsWith(q) || fn.startsWith(q);
        }).slice(0, 8);
        if (!list.length) { hideMention(); return; }
        state.mentionList = list;
        state.mentionAt = info.at;
        state.mentionIdx = 0;
        el.mention.hidden = false;
        el.mention.innerHTML = '';
        list.forEach((p, i) => {
            const row = document.createElement('div');
            row.className = 'ac-sugg-item ac-mention-item' + (i === 0 ? ' is-active' : '');
            row.innerHTML = `<span class="ac-mention-at">@</span><span class="ac-sugg-cmd">${esc(p.name)}</span><span class="ac-sugg-params">${esc(p.id)}</span>`;
            row.addEventListener('mousedown', (e) => { e.preventDefault(); applyMention(i); });
            el.mention.appendChild(row);
        });
    }
    function moveMention(d) {
        if (!state.mentionList.length) return;
        state.mentionIdx = (state.mentionIdx + d + state.mentionList.length) % state.mentionList.length;
        Array.from(el.mention.children).forEach((c, i) => c.classList.toggle('is-active', i === state.mentionIdx));
    }
    function applyMention(i) {
        const p = state.mentionList[i != null ? i : state.mentionIdx];
        if (!p || state.mentionAt < 0) return;
        const f = el.field;
        const caret = f.selectionStart != null ? f.selectionStart : f.value.length;
        // Insert @FirstName (single token, matches the server's name/first-name
        // matcher and the client highlight) then a trailing space.
        const insert = '@' + (p.first || p.name) + ' ';
        f.value = f.value.slice(0, state.mentionAt) + insert + f.value.slice(caret);
        const pos = state.mentionAt + insert.length;
        f.setSelectionRange(pos, pos);
        hideMention(); updateCounter(); f.focus();
    }

    /* ───────── Tools: emoji / gif / dice / try ───────── */
    function insertAtCursor(text) {
        const f = el.field, start = f.selectionStart || f.value.length, end = f.selectionEnd || f.value.length;
        f.value = f.value.slice(0, start) + text + f.value.slice(end);
        const pos = start + text.length;
        f.setSelectionRange(pos, pos);
        f.focus(); updateCounter();
    }
    function closePop() { el.pop.hidden = true; el.pop.innerHTML = ''; }
    function openEmoji() {
        if (!el.pop.hidden && el.pop.dataset.kind === 'emoji') { closePop(); return; }
        hideSuggest();
        el.pop.dataset.kind = 'emoji';
        el.pop.innerHTML = '<div class="ac-emoji-grid">' + EMOJIS.map(e => `<button class="ac-emoji" type="button">${e}</button>`).join('') + '</div>';
        el.pop.hidden = false;
        el.pop.querySelectorAll('.ac-emoji').forEach(b => b.addEventListener('click', () => { insertAtCursor(b.textContent); }));
    }
    function rollDice() { insertAtCursor(`🎲 rolled ${Math.floor(Math.random() * 100) + 1}/100`); closePop(); }
    // Optional caption typed inside the photo/GIF popover (falls back to the
    // main composer text). A leading "/" is ignored so a command isn't sent
    // as a caption.
    function popCaption() {
        const capEl = el.pop.querySelector('.ac-cap-input');
        let cap = capEl ? capEl.value.trim() : '';
        if (!cap) cap = el.field.value.trim();
        if (cap.startsWith('/')) cap = '';
        return cap;
    }
    function openPhoto() {
        if (!el.pop.hidden && el.pop.dataset.kind === 'photo') { closePop(); return; }
        hideSuggest();
        el.pop.dataset.kind = 'photo';
        el.pop.innerHTML = `
            <div class="ac-gifbox">
                <span>In-game photo</span>
                <input class="ac-cap-input" type="text" maxlength="200" placeholder="Message (optional)…" autocomplete="off" spellcheck="false">
                <button type="button" class="ac-gifadd ac-photo-shot"><i class="fas fa-camera"></i> Take photo</button>
                <small class="ac-photo-status">The chat closes and you can aim the camera — ENTER/click captures, BACKSPACE cancels.</small>
            </div>`;
        el.pop.hidden = false;
        const btn = el.pop.querySelector('.ac-photo-shot');
        const status = el.pop.querySelector('.ac-photo-status');
        const cap = el.pop.querySelector('.ac-cap-input');
        if (cap) {
            setTimeout(() => cap.focus(), 0);
            cap.addEventListener('keydown', (e) => { if (e.key === 'Enter') { e.preventDefault(); btn.click(); } });
        }
        btn.addEventListener('click', () => {
            btn.disabled = true;
            btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Capturing';
            status.textContent = 'Capturing in-game photo...';
            const cat = replyCategory();
            const payload = { cat: cat ? cat.id : state.active, text: popCaption() };
            if (state.replyTo) payload.replyTo = state.replyTo;
            ApexBus.post('apex_chat_send_photo', payload).then((res) => {
                if (!res || res.ok !== false) return;
                btn.disabled = false;
                btn.innerHTML = '<i class="fas fa-camera"></i> Take photo';
                status.textContent = res.error || 'Photo failed.';
            }).catch(() => {
                btn.disabled = false;
                btn.innerHTML = '<i class="fas fa-camera"></i> Take photo';
                status.textContent = 'Photo failed.';
            });
        });
    }
    function doTry() { el.field.value = '/try '; closePop(); refreshSuggest(); el.field.focus(); }

    // ───────── GIF picker (Giphy — server-side search, no CORS) ─────────
    let gifTimer = null;
    let gifGrid  = null;   // active grid awaiting incoming results
    function sendGif(url) {
        const cat = replyCategory();
        // Include the optional caption typed in the GIF popover (or composer).
        const payload = { cat: cat ? cat.id : state.active, text: popCaption(), image: url };
        if (state.replyTo) payload.replyTo = state.replyTo;
        ApexBus.post('apex_chat_send', payload);
        closePop(); closeChat();
    }
    function renderGifResults(items) {
        if (!gifGrid) return;
        if (!Array.isArray(items) || !items.length) {
            gifGrid.innerHTML = '<div class="ac-gif-loading">No results.</div>'; return;
        }
        gifGrid.innerHTML = '';
        items.forEach(g => {
            if (!g || !g.thumb || !g.full) return;
            const cell = document.createElement('button');
            cell.type = 'button'; cell.className = 'ac-gif-cell';
            cell.innerHTML = `<img src="${esc(g.thumb)}" loading="lazy" alt="">`;
            cell.addEventListener('click', () => sendGif(g.full));
            gifGrid.appendChild(cell);
        });
        if (!gifGrid.children.length) gifGrid.innerHTML = '<div class="ac-gif-loading">No results.</div>';
    }
    function searchGif(q) {
        if (gifGrid) gifGrid.innerHTML = '<div class="ac-gif-loading">Loading…</div>';
        ApexBus.post('apex_gif_search', { term: q || '' });
    }
    function openGif() {
        if (!el.pop.hidden && el.pop.dataset.kind === 'gif') { closePop(); return; }
        hideSuggest();
        el.pop.dataset.kind = 'gif';
        el.pop.innerHTML = `
            <div class="ac-gifbox ac-gifsearch">
                <div class="ac-gif-head">
                    <i class="fas fa-magnifying-glass"></i>
                    <input class="ac-gif-input" type="text" placeholder="Search GIFs…" autocomplete="off" spellcheck="false">
                </div>
                <div class="ac-gif-grid"><div class="ac-gif-loading">Loading…</div></div>
            </div>`;
        el.pop.hidden = false;
        const input = el.pop.querySelector('.ac-gif-input');
        gifGrid = el.pop.querySelector('.ac-gif-grid');
        searchGif('');
        input.addEventListener('input', () => {
            clearTimeout(gifTimer);
            const q = input.value.trim();
            gifTimer = setTimeout(() => searchGif(q), 320);
        });
        setTimeout(() => input.focus(), 0);
    }

    el.tools.addEventListener('click', (e) => {
        const b = e.target.closest('.ac-tool'); if (!b) return;
        if (b.dataset.open) {
            if (state.open) { ApexBus.post('apex_chat_blur'); closeChat(); }
            ApexBus.post('apex_open_req', { panel: b.dataset.open });
            return;
        }
        const t = b.dataset.tool;
        if (t === 'emoji') openEmoji();
        else if (t === 'giphy') openGif();
        else if (t === 'gif') openPhoto();
    });

    /* ───────── Image lightbox (click an inline image to expand) ───────── */
    function lightboxEl() {
        let lb = document.getElementById('ac-lightbox');
        if (!lb) {
            lb = document.createElement('div');
            lb.id = 'ac-lightbox';
            lb.hidden = true;
            lb.innerHTML = '<img alt="">';
            lb.addEventListener('click', () => { lb.hidden = true; });
            document.body.appendChild(lb);
        }
        return lb;
    }
    function openLightbox(src) {
        if (!src) return;
        const lb = lightboxEl();
        lb.querySelector('img').src = src;
        lb.hidden = false;
    }
    function closeLightbox() {
        const lb = document.getElementById('ac-lightbox');
        if (lb && !lb.hidden) { lb.hidden = true; return true; }
        return false;
    }
    el.feed.addEventListener('click', (e) => {
        const img = e.target.closest('.ac-img');
        if (img && state.open) { e.stopPropagation(); openLightbox(img.src); }
    });
    // Images load after the message is appended — re-stick the feed to the
    // bottom so a fresh photo/GIF is never left cut off below the fold
    // (unless the user has scrolled up to read older messages).
    el.feed.addEventListener('load', (e) => {
        if (e.target && e.target.tagName === 'IMG' && stickBottom) {
            el.feed.scrollTop = el.feed.scrollHeight;
        }
    }, true);

    /* ───────── Input ───────── */
    document.addEventListener('click', (e) => {
        if (!e.target.closest('.ac-msg-actions')) closeReactionPickers();
        if (!e.target.closest('.ac-msg-menu') && !e.target.closest('[data-act="message-menu"]')) closeMessageMenus();
    });

    function updateCounter() {
        if (!state.features.MessageLengthCounter) { el.counter.textContent = ''; return; }
        const max = el.field.maxLength || 300, n = el.field.value.length;
        el.counter.textContent = n > max - 40 ? (max - n) : '';
        el.counter.classList.toggle('is-warn', n > max - 40);
    }
    /* /hide — the whole overlay goes dark: the feed (and its history) stays
       collapsed even while open, and the composer shows how to restore it.
       Opening still works so the player can type /hide a second time. */
    function setHidden(on) {
        state.hidden = !!on;
        el.root.classList.toggle('ac-hidden', state.hidden);
        el.root.classList.toggle('ac-feedhidden', state.hidden);
        if (el.hiddenbar) el.hiddenbar.hidden = !state.hidden;
        if (state.hidden) { closePop(); hideSuggest(); hideMention(); }
        else showFeed();
    }
    function flashHidden() {
        if (!el.hiddenbar) return;
        el.hiddenbar.classList.remove('is-flash');
        void el.hiddenbar.offsetWidth;   // restart the animation
        el.hiddenbar.classList.add('is-flash');
    }

    function openChat(prefill) {
        state.open = true;
        el.root.dataset.open = 'true';
        if (!state.hidden) el.root.classList.remove('ac-feedhidden');
        el.field.value = prefill || '';
        updateCounter(); refreshSuggest(); scrollDown(true);
        ApexBus.post('apex_chat_roster');   // refresh online names for @mentions
        setTimeout(() => el.field.focus(), 0);
    }
    function closeChat() {
        state.open = false;
        el.root.dataset.open = 'false';
        el.field.value = '';
        el.field.blur();
        closeChannelMenu();
        closeLightbox();
        hideSuggest(); hideMention(); closePop();
        clearReply();
        state.histIdx = -1;
        showFeed();  // keep visible briefly after closing, then auto-hide
    }
    function escapeChat() {
        if (!state.open) return;
        if (closeLightbox()) return;
        if (!el.menu.hidden) { closeChannelMenu(); return; }
        if (!el.pop.hidden) { closePop(); return; }
        closeReactionPickers();
        closeMessageMenus();
        ApexBus.post('apex_chat_blur');
        closeChat();
    }
    function submit() {
        const text = el.field.value.trim();
        // Admin edit-in-place: patch the original message instead of sending.
        if (state.editing) {
            if (text && !text.startsWith('/')) {
                ApexBus.post('apex_chat_admin', { act: 'edit', id: state.editing.id, text });
            }
            closeChat();
            return;
        }
        // While hidden, only commands go through — a normal message would be
        // dropped by the server anyway, so say why instead of eating it.
        if (state.hidden && text && !text.startsWith('/')) { flashHidden(); return; }
        if (text) {
            state.history.unshift(text);
            state.history = state.history.slice(0, state.prefs.maxHistoryMessages || 20);
        }
        const cat = replyCategory();
        const payload = { cat: cat ? cat.id : state.active, text: commandFallbackText(text) };
        if (state.replyTo) payload.replyTo = state.replyTo;
        ApexBus.post('apex_chat_send', payload);
        closeChat();
    }

    el.prefix.addEventListener('mousedown', (e) => e.preventDefault());
    el.prefix.addEventListener('click', (e) => { e.stopPropagation(); toggleChannelMenu(); });
    document.addEventListener('click', (e) => {
        if (!el.channel.contains(e.target)) closeChannelMenu();
    });

    /* ───────── Typing indicator ───────── */
    let typingLastSent = 0;
    function noteTyper(p) {
        if (!p || !p.cat || p.id == null) return;
        const cat = String(p.cat);
        state.typers[cat] = state.typers[cat] || {};
        state.typers[cat][p.id] = { name: p.name || '???', until: Date.now() + 3500 };
        renderTyping();
    }
    function renderTyping() {
        if (!el.typing) return;
        const bucket = state.typers[state.active] || {};
        const now = Date.now();
        const names = [];
        Object.keys(bucket).forEach(k => {
            if (bucket[k].until < now) delete bucket[k];
            else names.push(bucket[k].name);
        });
        if (!names.length) { el.typing.hidden = true; return; }
        el.typingText.textContent =
            names.length === 1 ? names[0] + ' is typing…' :
            names.length === 2 ? names[0] + ' and ' + names[1] + ' are typing…' :
            'Several people are typing…';
        el.typing.hidden = false;
    }
    setInterval(renderTyping, 600);

    el.field.addEventListener('input', () => {
        updateCounter(); refreshSuggest(); refreshMention();
        const v = el.field.value;
        if (v && !v.startsWith('/')) {
            const now = Date.now();
            if (now - typingLastSent > 1200) {
                typingLastSent = now;
                ApexBus.post('apex_chat_typing', { cat: state.active });
            }
        }
    });
    // Re-evaluate the @mention token when the caret moves without typing.
    el.field.addEventListener('keyup', (e) => {
        if (e.key === 'ArrowLeft' || e.key === 'ArrowRight' || e.key === 'Home' || e.key === 'End') refreshMention();
    });
    el.field.addEventListener('click', () => refreshMention());
    el.send.addEventListener('mousedown', (e) => e.preventDefault());
    el.send.addEventListener('click', submit);
    el.replyCancel.addEventListener('mousedown', (e) => e.preventDefault());
    el.replyCancel.addEventListener('click', clearReply);
    if (el.clear) {
        el.clear.addEventListener('mousedown', (e) => e.preventDefault());
        el.clear.addEventListener('click', clearFeed);
    }
    el.field.addEventListener('keydown', (e) => {
        // @mention dropdown takes precedence over everything else while open.
        if (el.mention && !el.mention.hidden && state.mentionList.length) {
            if (e.key === 'Enter' || e.key === 'Tab') { e.preventDefault(); applyMention(); return; }
            if (e.key === 'ArrowUp')   { e.preventDefault(); moveMention(-1); return; }
            if (e.key === 'ArrowDown') { e.preventDefault(); moveMention(1);  return; }
            if (e.key === 'Escape')    { e.preventDefault(); hideMention();   return; }
        }
        if (e.key === 'Enter') {
            e.preventDefault();
            // Enter only picks a suggestion if the player has actually navigated
            // the list with ↓/↑ (suggIdx >= 0). Otherwise it just sends what was
            // typed — the suggestion list is a passive hint until you arrow into it.
            if (!el.suggest.hidden && state.suggList.length && state.suggIdx >= 0) {
                const s = state.suggList[state.suggIdx];
                if (s) {
                    if (!s.params) {
                        el.field.value = s.cmd;
                        hideSuggest(); updateCounter();
                        submit();
                    } else {
                        applySuggest();
                    }
                    return;
                }
            }
            hideSuggest();
            submit();
        } else if (e.key === 'Escape') {
            e.preventDefault();
            escapeChat();
        } else if (e.key === 'Tab') {
            e.preventDefault();
            // Tab = complete: the highlighted one, or the first if none navigated.
            if (!el.suggest.hidden && state.suggList.length) applySuggest(state.suggIdx >= 0 ? state.suggIdx : 0);
            else cycleTab(e.shiftKey ? -1 : 1);
        } else if (e.key === 'ArrowUp') {
            if (!el.suggest.hidden) { e.preventDefault(); moveSuggest(-1); }
            else if (state.features.MessageHistory && state.history.length) {
                e.preventDefault();
                state.histIdx = Math.min(state.histIdx + 1, state.history.length - 1);
                el.field.value = state.history[state.histIdx] || ''; updateCounter();
            }
        } else if (e.key === 'ArrowDown') {
            if (!el.suggest.hidden) { e.preventDefault(); moveSuggest(1); }
            else if (state.features.MessageHistory && state.history.length) {
                e.preventDefault();
                state.histIdx = Math.max(state.histIdx - 1, -1);
                el.field.value = state.histIdx === -1 ? '' : (state.history[state.histIdx] || ''); updateCounter();
            }
        }
    });

    document.addEventListener('keydown', (e) => {
        if (e.key !== 'Escape' || !state.open) return;
        e.preventDefault();
        e.stopPropagation();
        escapeChat();
    }, true);

    // Manager buttons.
    el.root.querySelectorAll('.ac-iconbtn[data-open]').forEach(btn => {
        btn.addEventListener('click', () => {
            if (state.open) { ApexBus.post('apex_chat_blur'); closeChat(); }
            ApexBus.post('apex_open_req', { panel: btn.dataset.open });
        });
    });

    /* ───────── Free-hand drag ─────────
       With free-hand ON, drag the whole window (grab any non-interactive
       spot while the chat is open). It only moves when you actually drag —
       enabling free-hand or opening the chat never repositions it. */
    (function () {
        let dragging = false, ox = 0, oy = 0;
        const INTERACTIVE = 'input, textarea, button, a, [contenteditable], .ac-reaction-pill, .ac-reaction-option, .ac-channel, .ac-msg-menu, .ac-emoji, .ac-gif-cell, .ac-tool, .ac-send, .ac-msg-action, .ac-prefix';
        el.root.addEventListener('mousedown', (e) => {
            if (!state.prefs.freeHand || !state.open) return;
            if (e.target.closest(INTERACTIVE)) return;   // let controls work
            dragging = true;
            const r = el.root.getBoundingClientRect();
            ox = e.clientX - r.left; oy = e.clientY - r.top;
            el.root.className = 'apex-chat is-free' + (state.hidden ? ' ac-hidden ac-feedhidden' : '');
            el.root.style.left = r.left + 'px';   // pin current spot, no jump
            el.root.style.top  = r.top + 'px';
            el.root.classList.add('is-dragging');
            e.preventDefault();
        });
        window.addEventListener('mousemove', (e) => {
            if (!dragging) return;
            el.root.style.left = Math.max(0, e.clientX - ox) + 'px';
            el.root.style.top  = Math.max(0, e.clientY - oy) + 'px';
        });
        window.addEventListener('mouseup', () => {
            if (!dragging) return;
            dragging = false;
            el.root.classList.remove('is-dragging');
            const r = el.root.getBoundingClientRect();
            state.prefs.rect = Object.assign({}, state.prefs.rect, { x: Math.round(r.left), y: Math.round(r.top) });
            ApexBus.post('apex_save_prefs', state.prefs);
        });
    })();

    /* ───────── Category sync ───────── */
    function setCategories(payload) {
        state.cats = (payload.tabs || []).slice().sort((a, b) => (a.order || 999) - (b.order || 999));
        state.isManager = !!payload.isManager;
        el.root.querySelectorAll('.ac-mgr').forEach(btn => { btn.hidden = !state.isManager; });
        const want = payload.active || state.active || payload.default;
        state.active = state.cats.some(c => c.id === want) ? want
            : (state.cats.some(c => c.id === payload.default) ? payload.default : (state.cats[0] && state.cats[0].id));
        renderTabs();
    }

    /* ───────── Message bus ───────── */
    window.addEventListener('message', function (e) {
        const d = e.data || {};
        switch (d.action) {
            case 'apex_init':       if (d.config) state.config = d.config; if (d.prefs) applyPrefs(d.prefs); break;
            case 'apex_prefs':      if (d.prefs) applyPrefs(d.prefs); break;
            case 'apex_msg':        renderStructured(d.msg || {}); break;
            case 'apex_legacy':     renderLegacy(d.msg); break;
            case 'apex_clear':      clearFeed(); break;
            case 'apex_cats':       setCategories(d); break;
            case 'apex_chat_open':  openChat(d.prefill); break;
            case 'apex_chat_close': closeChat(); break;
            case 'apex_chat_hidden': setHidden(!!d.hidden); break;
            case 'apex_screen':
                el.root.classList.toggle('ac-screenhidden', !!d.shouldHide);
                if (d.shouldHide) closeChat();
                break;
            case 'apex_sugg_add':     state.legacySugg[d.name] = { help: d.help, params: d.params }; break;
            case 'apex_sugg_remove':  delete state.legacySugg[d.name]; break;
            case 'apex_sugg_addmany': (d.suggestions || []).forEach(s => { state.legacySugg[s.name] = { help: s.help, params: s.params }; }); break;
            case 'apex_template':   if (d.id) state.templates[d.id] = d.html; break;
            case 'apex_reaction':   updateReactionRow(d.id, d.reactions); break;
            case 'apex_gif_results': renderGifResults(d.results || d.data || []); break;
            case 'apex_typing':     noteTyper(d.data || {}); break;
            case 'apex_roster':     state.roster = Array.isArray(d.players) ? d.players : []; break;
            case 'apex_photo_frame': {
                const pf = document.getElementById('ac-photoframe');
                if (pf) pf.hidden = !d.show;
                break;
            }
            case 'apex_msg_remove': {
                const id = String(d.id || '');
                if (!id) break;
                el.feed.querySelectorAll('.ac-msg[data-msg-id]').forEach(n => {
                    if (n.dataset.msgId === id) n.remove();
                });
                delete state.messages[id];
                delete state.reactions[id];
                break;
            }
            case 'apex_msg_edit': {
                const id = String(d.id || '');
                if (!id) break;
                el.feed.querySelectorAll('.ac-msg[data-msg-id]').forEach(n => {
                    if (n.dataset.msgId !== id) return;
                    const t = n.querySelector('.ac-text');
                    if (t) t.innerHTML = richText(d.text || '') + '<span class="ac-edited">(edited)</span>';
                });
                if (state.messages[id]) state.messages[id].text = d.text || '';
                break;
            }
        }
    });

    ApexBus.post('apex_nui_ready');
})();
