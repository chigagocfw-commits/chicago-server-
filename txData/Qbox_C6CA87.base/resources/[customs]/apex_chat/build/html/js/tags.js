// Apex Chat — Tag Manager (create/customise tags + assign to players, offline-capable).
(function () {
    'use strict';

    const state = { tags: [], isManager: false, selectedPlayer: null, searchTimer: null };
    const $ = id => document.getElementById(id);
    function esc(s) { return String(s == null ? '' : s).replace(/[&<>"']/g, c => ({ '&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;' }[c])); }

    function hexRgb(hex) {
        const m = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(String(hex || ''));
        return m ? `${parseInt(m[1],16)},${parseInt(m[2],16)},${parseInt(m[3],16)}` : '59,130,246';
    }
    // Shared pill renderer — also used by chat.js to render tags inline in messages.
    // Colours are inlined as rgba() (no color-mix dependency) so it works on any CEF.
    function pillHTML(t) {
        if (!t || !t.label) return '';
        const color = t.color || '#3B82F6';
        const tc    = t.textColor || '#FFFFFF';
        const rgb   = hexRgb(color);
        const icon  = t.icon ? `<i class="${esc(t.icon)}"></i>` : '';
        const label = esc(t.label);
        switch (t.style || 'badge') {
            case 'icon': return `<span class="ac-tag ac-tag-icon" style="color:${esc(color)};background:rgba(${rgb},.16)">${icon || '<i class="fas fa-tag"></i>'}</span>`;
            case 'text': return `<span class="ac-tag ac-tag-text" style="color:${esc(color)}">${label}</span>`;
            case 'full': return `<span class="ac-tag ac-tag-full" style="background:${esc(color)};color:${esc(tc)}">${icon}<span>${label}</span></span>`;
            default:     return `<span class="ac-tag ac-tag-badge" style="color:${esc(color)};background:rgba(${rgb},.14);border-color:rgba(${rgb},.45)">${icon}<span>${label}</span></span>`;
        }
    }
    window.ApexTagPill = pillHTML;

    // ── editor ──
    function editorTag() {
        return {
            id:        $('tag-id').value || '',
            label:     $('tag-label').value,
            color:     $('tag-color').value,
            textColor: $('tag-textcolor').value,
            icon:      $('tag-icon').value.trim(),
            style:     $('tag-style').value,
            priority:  parseInt($('tag-priority').value, 10) || 0,
        };
    }
    function fillEditor(t) {
        $('tag-id').value        = t.id || '';
        $('tag-label').value     = t.label || '';
        $('tag-color').value     = t.color || '#3B82F6';
        $('tag-textcolor').value = t.textColor || '#FFFFFF';
        $('tag-icon').value      = t.icon || '';
        $('tag-style').value     = t.style || 'badge';
        $('tag-priority').value  = t.priority || 0;
        renderPreview();
    }
    function clearEditor() { fillEditor({ color: '#3B82F6', textColor: '#FFFFFF', style: 'badge', priority: 0 }); }

    function renderPreview() {
        const host = $('tag-preview'); if (!host) return;
        host.innerHTML = pillHTML(editorTag()) || '<span class="tag-empty">…</span>';
    }

    function renderList() {
        const host = $('tag-list'); if (!host) return;
        if (!state.tags.length) { host.innerHTML = '<div class="tag-empty">Sem tags ainda.</div>'; return; }
        host.innerHTML = '';
        state.tags.forEach(t => {
            const row = document.createElement('div');
            row.className = 'tag-row';
            row.innerHTML =
                `<div class="tag-row-pill">${pillHTML(t)}</div>` +
                `<div class="tag-row-meta"><strong>${esc(t.label)}</strong><small>${esc(t.style || 'badge')} · p${t.priority || 0}</small></div>` +
                `<button class="tag-row-del" title="Apagar"><i class="fas fa-trash"></i></button>`;
            row.querySelector('.tag-row-pill').addEventListener('click', () => fillEditor(t));
            row.querySelector('.tag-row-meta').addEventListener('click', () => fillEditor(t));
            row.querySelector('.tag-row-del').addEventListener('click', (e) => { e.stopPropagation(); ApexBus.post('apex_tags_delete', { id: t.id }); });
            host.appendChild(row);
        });
    }

    // ── player search + assign ──
    function renderResults(rows) {
        const host = $('tag-results'); if (!host) return;
        if (!rows || !rows.length) { host.innerHTML = '<div class="tag-empty">No players found.</div>'; return; }
        host.innerHTML = '';
        rows.forEach(p => {
            const row = document.createElement('div');
            row.className = 'tag-result';
            row.innerHTML =
                `<div class="tag-result-info"><strong>${esc(p.name)}</strong><small>${esc(p.steam || p.identifier)}</small></div>` +
                `<div class="tag-result-tags">${(p.tags || []).map(pillHTML).join('')}</div>`;
            row.addEventListener('click', () => selectPlayer(p));
            host.appendChild(row);
        });
    }
    function selectPlayer(p) {
        state.selectedPlayer = p;
        $('tag-assign-box').hidden = false;
        $('tag-assign-name').textContent = p.name || 'Player';
        $('tag-assign-id').textContent = p.steam ? (p.steam + ' · ' + p.identifier) : p.identifier;
        renderAssign(p.tags || []);
    }
    function renderAssign(current) {
        const cur = $('tag-assign-current'), pool = $('tag-assign-pool');
        const has = new Set(current.map(t => t.id));
        cur.innerHTML = current.length ? '' : '<div class="tag-empty">Sem tags.</div>';
        current.forEach(t => {
            const chip = document.createElement('div');
            chip.className = 'tag-assigned';
            chip.innerHTML = `${pillHTML(t)}<button title="Remover"><i class="fas fa-xmark"></i></button>`;
            chip.querySelector('button').addEventListener('click', () => assign(t.id, false));
            cur.appendChild(chip);
        });
        pool.innerHTML = '';
        state.tags.filter(t => !has.has(t.id)).forEach(t => {
            const chip = document.createElement('button');
            chip.className = 'tag-pool-chip';
            chip.innerHTML = `${pillHTML(t)}<i class="fas fa-plus"></i>`;
            chip.addEventListener('click', () => assign(t.id, true));
            pool.appendChild(chip);
        });
    }
    function assign(tagId, add) {
        if (!state.selectedPlayer) return;
        ApexBus.post('apex_tags_assign', { identifier: state.selectedPlayer.identifier, tagId, add });
    }

    // ── bind / mount ──
    let bound = false;
    function bind() {
        ['tag-label','tag-color','tag-textcolor','tag-icon','tag-style','tag-priority'].forEach(id => {
            const el = $(id); if (el) el.addEventListener('input', renderPreview);
        });
        const save = $('tag-save'); if (save) save.addEventListener('click', () => {
            const t = editorTag();
            if (!t.label.trim()) { $('tag-label').focus(); return; }
            ApexBus.post('apex_tags_save', t);
        });
        const nw = $('tag-new'); if (nw) nw.addEventListener('click', clearEditor);
        const search = $('tag-search'); if (search) search.addEventListener('input', () => {
            clearTimeout(state.searchTimer);
            const term = search.value.trim();
            if (term.length < 2) { $('tag-results').innerHTML = ''; return; }
            state.searchTimer = setTimeout(() => ApexBus.post('apex_tags_search', { term }), 280);
        });
    }
    function mount() {
        if (!bound) { bind(); bound = true; }
        ApexBus.post('apex_tags_list');
        clearEditor();
    }
    window.ApexTagMgr = { mount };

    window.addEventListener('message', function (e) {
        const d = e.data || {};
        if (d.action === 'apex_tags_sync') {
            state.tags = (d.data && d.data.tags) || [];
            state.isManager = !!(d.data && d.data.isManager);
            // The player is an admin/manager → reveal the "Admin Mode" toggle.
            document.documentElement.classList.toggle('ac-is-admin', state.isManager);
            renderList();
            if (state.selectedPlayer) renderAssign(state.selectedPlayer.tags || []);
        } else if (d.action === 'apex_tags_results') {
            renderResults(d.data || []);
        } else if (d.action === 'apex_tags_player') {
            const data = d.data || {};
            if (state.selectedPlayer && state.selectedPlayer.identifier === data.identifier) {
                state.selectedPlayer.tags = data.tags || [];
                renderAssign(state.selectedPlayer.tags);
            }
        }
    });
})();
