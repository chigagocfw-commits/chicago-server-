// Apex Chat — Theme engine + Theme Manager.
// Applies a theme as CSS custom properties on :root so the whole
// chat + manager recolour instantly (live switching & preview).

(function () {
    'use strict';

    const state = {
        themes:   [],     // [{ id, name, vars }]
        applied:  null,   // currently applied id
        selected: null,   // selection inside the manager (pre-save)
        saved:    null,
    };

    const VAR_KEYS = ['bg','panel','panelRaised','border','borderHi','text','textSub','accent','accentSoft','accentText','surface0','surface1','surface2','surface3','surface4','surface5','line1','line2','line3','line4','brand300','brand400','brand500','brand600'];
    const VAR_ALIASES = {
        surface0: 'surface-0',
        surface1: 'surface-1',
        surface2: 'surface-2',
        surface3: 'surface-3',
        surface4: 'surface-4',
        surface5: 'surface-5',
        line1: 'line-1',
        line2: 'line-2',
        line3: 'line-3',
        line4: 'line-4',
        brand300: 'brand-300',
        brand400: 'brand-400',
        brand500: 'brand-500',
        brand600: 'brand-600',
    };

    function byId(id) { return state.themes.find(t => t.id === id) || state.themes[0]; }
    function hexToRgbParts(hex) {
        const m = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(String(hex || ''));
        if (!m) return '59,130,246';
        return `${parseInt(m[1],16)},${parseInt(m[2],16)},${parseInt(m[3],16)}`;
    }

    function apply(id) {
        const t = byId(id);
        if (!t) return;
        const root = document.documentElement.style;
        VAR_KEYS.forEach(k => {
            if (t.vars[k] != null) {
                const cssName = VAR_ALIASES[k] || k.replace(/[A-Z]/g, m => '-' + m.toLowerCase());
                root.setProperty('--' + cssName, t.vars[k]);
            }
        });
        if (t.vars.accent) root.setProperty('--apex-accent', t.vars.accent);
        document.documentElement.classList.remove('ac-light');
        state.applied = t.id;
    }
    function saveSelected() {
        return ApexBus.post('apex_save_theme', { theme: state.selected, accentOverride: false }).then((res) => {
            if (!res || res.ok !== false) state.saved = state.selected;
            return res;
        });
    }
    function revertPreview() {
        if (state.saved && state.applied !== state.saved) apply(state.saved);
    }
    function isAdminMode() { return document.documentElement.classList.contains('ac-admin-mode'); }
    window.ApexThemes = { apply, mountManager, saveSelected, revertPreview, selectedId: () => state.selected };

    function escapeHtml(s) {
        return String(s || '').replace(/[&<>"']/g, c => ({ '&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;' }[c]));
    }

    function renderPreview() {
        const host = document.getElementById('theme-preview');
        if (!host) return;
        const theme = byId(state.selected);
        const rgb = hexToRgbParts(theme && theme.vars && theme.vars.accent);
        host.innerHTML = `
            <div class="ac-msg" style="--cat: var(--accent);--cat-rgb: ${rgb}">
                <div class="ac-avatar">ML</div>
                <div class="ac-body">
                    <div class="ac-meta"><span class="ac-name">Mike Lowery</span><span class="ac-time">14:32</span></div>
                    <div class="ac-text">Live preview of this theme — clean message flow.</div>
                </div>
            </div>
            <div class="ac-inputrow" style="margin-top:4px">
                <span class="ac-prefix"><i class="fas fa-globe"></i><span>GLOBAL</span></span>
                <span style="flex:1;color:var(--textSub);font-size:13px">Type a message…</span>
            </div>`;
    }

    function renderTiles() {
        const host = document.getElementById('theme-list');
        if (!host) return;
        host.innerHTML = '';
        state.themes.forEach(t => {
            const tile = document.createElement('div');
            tile.className = 'theme-tile' + (t.id === state.selected ? ' is-active' : '');
            tile.innerHTML = `
                <div class="theme-tile-head">
                    <strong>${escapeHtml(t.name)}</strong>
                    ${t.id === state.selected ? '<i class="fas fa-check tick"></i>' : ''}
                </div>
                <div class="theme-dots">
                    <span style="background:${escapeHtml(t.vars.accent)}"></span>
                    <span style="background:${escapeHtml(t.vars.panelRaised)}"></span>
                    <span style="background:${escapeHtml(t.vars.panel)}"></span>
                    <span style="background:${escapeHtml(t.vars.text)}"></span>
                </div>`;
            tile.addEventListener('click', () => {
                state.selected = t.id;
                apply(t.id);          // live across the whole UI
                renderTiles();
                renderPreview();
                // Persist immediately so the theme sticks without a separate
                // SAVE press (and close no longer reverts it).
                ApexBus.post('apex_save_theme', { theme: t.id, accentOverride: false });
                state.saved = t.id;
            });
            host.appendChild(tile);
        });
    }

    function mountManager(payload) {
        if (payload && payload.config && Array.isArray(payload.config.themes)) state.themes = payload.config.themes;
        state.saved = (payload && payload.prefs && payload.prefs.theme) || state.applied || (state.themes[0] && state.themes[0].id);
        state.selected = state.saved;
        apply(state.selected);
        renderTiles();
        renderPreview();
    }

    document.addEventListener('click', function (e) {
        if (e.target.closest('#theme-save')) {
            if (isAdminMode()) {
                // Apply this theme for EVERYONE (admin).
                ApexBus.post('apex_theme_broadcast', { theme: state.selected });
                if (window.ApexUI) ApexUI.close();
            } else {
                // Apply only for me.
                saveSelected().then(() => ApexUI.close());
            }
        }
    });

    // Boot: receive themes + apply the saved one immediately.
    window.addEventListener('message', function (e) {
        const d = e.data || {};
        if (d.action === 'apex_init') {
            if (d.config && Array.isArray(d.config.themes)) state.themes = d.config.themes;
            const themeId = (d.prefs && d.prefs.theme) || (state.themes[0] && state.themes[0].id);
            if (themeId) apply(themeId);
        }
        // Admin pushed a theme / design "for everyone" — apply it live.
        if (d.action === 'apex_apply_theme') {
            if (d.theme) { apply(d.theme); state.saved = d.theme; }
            if (d.accent && window.ApexSettings && window.ApexSettings.applyAccent) window.ApexSettings.applyAccent(d.accent);
        }
    });
})();
