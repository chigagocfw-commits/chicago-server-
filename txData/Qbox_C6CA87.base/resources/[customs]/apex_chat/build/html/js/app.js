// Apex Chat — NUI core: resource bus + manager-overlay router.

(function () {
    'use strict';

    const RES = (function () {
        try { return window.GetParentResourceName ? GetParentResourceName() : 'apex_chat'; }
        catch (_) { return 'apex_chat'; }
    })();

    window.ApexBus = {
        post(action, body) {
            return fetch(`https://${RES}/${action}`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                body: JSON.stringify(body || {}),
            }).then(r => (r.ok ? r.json() : { ok: false })).catch(() => ({ ok: false }));
        },
    };

    const overlay  = document.getElementById('apex-overlay');
    const sections = {
        settings:   document.getElementById('panel-settings'),
    };

    function show(panel) {
        overlay.hidden = false;
        Object.keys(sections).forEach(k => { if (sections[k]) sections[k].hidden = (k !== panel); });
    }
    function hide() {
        overlay.hidden = true;
        Object.values(sections).forEach(s => { if (s) s.hidden = true; });
    }

    function activateTab(root, key) {
        if (!root || !key) return;
        root.querySelectorAll('.apex-tab[data-tab]').forEach(t => t.classList.toggle('is-active', t.dataset.tab === key));
        root.querySelectorAll('.apex-tabbody[data-body]').forEach(b => b.classList.toggle('is-active', b.dataset.body === key));
    }

    window.ApexUI = {
        open(panel, payload) {
            const requested = panel;
            if (panel === 'themes') panel = 'settings';
            show(panel);
            if (panel === 'settings' && window.ApexSettings) window.ApexSettings.mount(payload);
            if (panel === 'settings' && window.ApexThemes) {
                window.ApexThemes.mountManager(payload);
                activateTab(sections.settings, requested === 'themes' ? 'themes' : 'design');
            }
            if (panel === 'settings' && window.ApexTagMgr) window.ApexTagMgr.mount(payload);
            if (panel === 'settings' && window.ApexCategories) window.ApexCategories.mount(payload);
        },
        close() {
            if (window.ApexThemes && window.ApexThemes.revertPreview) window.ApexThemes.revertPreview();
            hide();
            ApexBus.post('apex_close');
        },
    };

    // Universal close button.
    document.addEventListener('click', function (e) {
        const closer = e.target.closest('[data-act="close"]');
        if (closer) { e.preventDefault(); ApexUI.close(); }
    });
    // Esc closes an open manager overlay (chat input handles its own Esc).
    document.addEventListener('keydown', function (e) {
        if (e.key === 'Escape' && !overlay.hidden) { e.preventDefault(); ApexUI.close(); }
    });

    // Tabs shared by the settings panel.
    document.addEventListener('click', function (e) {
        const tab = e.target.closest('.apex-tab');
        if (!tab) return;
        const root = tab.closest('section') || document;
        const key  = tab.dataset.tab;
        if (!key) return;
        activateTab(root, key);
    });

    // Admin Mode toggle → reveal admin-only tabs/controls (Tags, Categories, apply-for-everyone).
    const adminChk = document.getElementById('opt-admin-mode');
    if (adminChk) adminChk.addEventListener('change', function () {
        document.documentElement.classList.toggle('ac-admin-mode', adminChk.checked);
    });

    // Tab-styled buttons that launch a separate panel (e.g. the Categories manager).
    document.addEventListener('click', function (e) {
        const launch = e.target.closest('[data-launch]');
        if (launch) { e.preventDefault(); if (window.ApexUI) window.ApexUI.open(launch.dataset.launch); }
    });

    /* ───────── Font Awesome icon picker (dropdown for icon fields) ───────── */
    const PICK_ICONS = [
        'fas fa-crown','fas fa-star','fas fa-shield-halved','fas fa-gem','fas fa-bolt','fas fa-fire',
        'fas fa-heart','fas fa-skull','fas fa-user','fas fa-users','fas fa-user-shield','fas fa-user-secret',
        'fas fa-user-tie','fas fa-user-ninja','fas fa-briefcase','fas fa-gavel','fas fa-bullhorn','fas fa-comment',
        'fas fa-comments','fas fa-headset','fas fa-medal','fas fa-trophy','fas fa-award','fas fa-certificate',
        'fas fa-ghost','fas fa-mask','fas fa-dragon','fas fa-paw','fas fa-leaf','fas fa-anchor','fas fa-rocket',
        'fas fa-gamepad','fas fa-dice','fas fa-music','fas fa-camera','fas fa-video','fas fa-microphone',
        'fas fa-wrench','fas fa-hammer','fas fa-screwdriver-wrench','fas fa-car','fas fa-motorcycle','fas fa-plane',
        'fas fa-truck','fas fa-truck-medical','fas fa-money-bill','fas fa-coins','fas fa-sack-dollar','fas fa-gift',
        'fas fa-key','fas fa-lock','fas fa-star-of-life','fas fa-heart-pulse','fas fa-globe','fas fa-tag','fas fa-flag',
        'fas fa-bell','fas fa-terminal','fas fa-code','fas fa-hashtag','fas fa-circle-info','fas fa-triangle-exclamation',
        'fab fa-twitch','fab fa-youtube','fab fa-discord','fab fa-x-twitter','fab fa-instagram','fab fa-tiktok',
    ];
    let iconPop = null;
    function closeIconPop() { if (iconPop) { iconPop.remove(); iconPop = null; } }
    document.addEventListener('click', function (e) {
        const btn = e.target.closest('.ac-iconpick');
        if (btn) {
            e.preventDefault(); e.stopPropagation();
            if (iconPop) { closeIconPop(); return; }
            const input = document.getElementById(btn.dataset.target);
            if (!input) return;
            iconPop = document.createElement('div');
            iconPop.className = 'ac-iconpop';
            iconPop.innerHTML = PICK_ICONS.map(ic =>
                `<button type="button" class="ac-iconpop-item" data-ic="${ic}" title="${ic}"><i class="${ic}"></i></button>`).join('');
            document.body.appendChild(iconPop);
            const r = btn.getBoundingClientRect();
            iconPop.style.left = Math.max(8, Math.min(r.left, window.innerWidth - 288)) + 'px';
            iconPop.style.top  = (r.bottom + 6) + 'px';
            iconPop.querySelectorAll('.ac-iconpop-item').forEach(it => {
                it.addEventListener('click', (ev) => {
                    ev.stopPropagation();
                    input.value = it.dataset.ic;
                    input.dispatchEvent(new Event('input', { bubbles: true }));
                    closeIconPop();
                });
            });
            return;
        }
        if (iconPop && !e.target.closest('.ac-iconpop')) closeIconPop();
    });

    /* ───────── i18n ─────────
       The active locale pack (config.locale) arrives from the server; any
       element with data-i18n / data-i18n-title / data-i18n-ph is translated.
       Add data-i18n="key" to a new element and it localizes automatically. */
    window.APEX_I18N = {};
    window.T = function (key, fallback) {
        return (window.APEX_I18N && window.APEX_I18N[key]) || fallback || key;
    };
    function applyI18n(root) {
        root = root || document;
        root.querySelectorAll('[data-i18n]').forEach(el => {
            const v = window.APEX_I18N[el.getAttribute('data-i18n')];
            if (v) el.textContent = v;
        });
        root.querySelectorAll('[data-i18n-title]').forEach(el => {
            const v = window.APEX_I18N[el.getAttribute('data-i18n-title')];
            if (v) el.title = v;
        });
        root.querySelectorAll('[data-i18n-ph]').forEach(el => {
            const v = window.APEX_I18N[el.getAttribute('data-i18n-ph')];
            if (v) el.placeholder = v;
        });
    }
    window.ApexI18n = { apply: applyI18n };

    // Manager open/close messages from Lua.
    window.addEventListener('message', function (e) {
        const d = e.data || {};
        if ((d.action === 'apex_init' || d.action === 'apex_open_panel') && d.config && d.config.locale) {
            window.APEX_I18N = d.config.locale;
            applyI18n(document);
        }
        if (d.action === 'apex_open_panel')  { window.ApexUI.open(d.panel, d); applyI18n(document); }
        if (d.action === 'apex_close_panel') { hide(); }
    });
})();
