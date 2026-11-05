// Apex Chat — Category Manager (create / edit / delete channels live).

(function () {
    'use strict';

    function $(s, r) { return (r || document).querySelector(s); }
    function $$(s, r) { return Array.from((r || document).querySelectorAll(s)); }
    function escapeHtml(s) {
        return String(s || '').replace(/[&<>"']/g, c => ({ '&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;' }[c]));
    }
    function toArr(s) { return String(s || '').split(',').map(x => x.trim()).filter(Boolean); }
    function fromArr(a) { return Array.isArray(a) ? a.join(', ') : ''; }
    function uuid() { return (crypto.randomUUID && crypto.randomUUID()) || ('cat_' + Date.now()); }

    const state = { all: [], current: null };

    function newDef() {
        return {
            id: uuid(), label: '', command: '', icon: 'fas fa-comment', color: '#3B82F6',
            webhook: '',
            identity: 'rp', area: 0, visibility: 'all', order: 10, enabled: true, _isNew: true,
            rule: { type: 'open', jobs: [], minGrade: 0, groups: [], ace: '', identifiers: [] },
        };
    }

    /* ───── List ───── */
    function renderList() {
        const host = $('#cat-list'); if (!host) return;
        host.innerHTML = '';
        $('#cat-count').textContent      = state.all.length + ' categories';
        $('#cat-side-count').textContent = state.all.length + ' categor' + (state.all.length === 1 ? 'y' : 'ies');
        state.all.forEach(def => {
            const li = document.createElement('li');
            if (state.current && state.current.id === def.id) li.classList.add('is-active');
            li.innerHTML = `
                <div class="cc-head">
                    <span class="cc-icon" style="background:${escapeHtml(def.color || '#3B82F6')}"><i class="${escapeHtml(def.icon || 'fas fa-comment')}"></i></span>
                    <span class="cc-name">/${escapeHtml(def.command)}</span>
                </div>
                <div class="cc-type">${escapeHtml(def.label)} · ${escapeHtml(def.rule ? def.rule.type : 'open')}${def.area > 0 ? ' · ' + def.area + 'm' : ''}</div>
                <div class="cc-meta">
                    ${def.builtin ? '<span class="cc-badge">BUILT-IN</span>' : ''}
                    ${def.webhook ? '<span class="cc-badge"><i class="fab fa-discord"></i> LOG</span>' : ''}
                    ${def.enabled ? '' : '<span class="cc-badge" style="background:var(--apex-error)">OFF</span>'}
                    <i class="fas fa-eye"></i> ${escapeHtml(def.visibility)}
                </div>`;
            li.addEventListener('click', () => edit(def));
            host.appendChild(li);
        });
    }

    /* ───── Form ───── */
    function ruleFieldVisibility(type) {
        $('#cat-jobs-field').classList.toggle('hidden',   !(type === 'job' || type === 'grade'));
        $('#cat-grade-field').classList.toggle('hidden',  type !== 'grade');
        $('#cat-groups-field').classList.toggle('hidden', !(type === 'staff' || type === 'role'));
        $('#cat-ace-field').classList.toggle('hidden',    type !== 'role');
        $('#cat-idents-field').classList.toggle('hidden', type !== 'role');
    }

    function fillForm(d) {
        $('#cat-label').value     = d.label || '';
        $('#cat-command').value   = d.command || '';
        $('#cat-enabled').checked = d.enabled !== false;
        $('#cat-icon').value      = d.icon || '';
        $('#cat-color').value     = (d.color && /^#/.test(d.color)) ? d.color : '#3B82F6';
        $('#cat-webhook').value   = d.webhook || '';
        $('#cat-identity').value  = d.identity || 'rp';
        $('#cat-visibility').value = d.visibility || 'all';
        $('#cat-area').value      = d.area || 0;
        $('#cat-order').value     = d.order || 10;

        const rule = d.rule || { type: 'open' };
        $$('.rule-grid .dur-card[data-rule]').forEach(c => c.classList.toggle('is-active', c.dataset.rule === rule.type));
        $('#cat-jobs').value     = fromArr(rule.jobs);
        $('#cat-mingrade').value = rule.minGrade || 0;
        $('#cat-groups').value   = fromArr(rule.groups);
        $('#cat-ace').value      = rule.ace || '';
        $('#cat-idents').value   = fromArr(rule.identifiers);
        ruleFieldVisibility(rule.type || 'open');

        renderPreview();
    }

    function syncFromForm() {
        if (!state.current) return;
        const d = state.current;
        d.label      = $('#cat-label').value.trim();
        d.command    = $('#cat-command').value.trim().toLowerCase().replace(/\s+/g, '');
        d.enabled    = $('#cat-enabled').checked;
        d.icon       = $('#cat-icon').value.trim() || 'fas fa-comment';
        d.color      = $('#cat-color').value;
        d.webhook    = $('#cat-webhook').value.trim();
        d.identity   = $('#cat-identity').value;
        d.visibility = $('#cat-visibility').value;
        d.area       = parseFloat($('#cat-area').value) || 0;
        d.order      = parseInt($('#cat-order').value, 10) || 10;
        d.rule = {
            type:        $$('.rule-grid .dur-card[data-rule].is-active')[0]?.dataset.rule || 'open',
            jobs:        toArr($('#cat-jobs').value),
            minGrade:    parseInt($('#cat-mingrade').value, 10) || 0,
            groups:      toArr($('#cat-groups').value),
            ace:         $('#cat-ace').value.trim(),
            identifiers: toArr($('#cat-idents').value),
        };
    }

    function renderPreview() {
        if (!state.current) return;
        const d = state.current;
        const label = (d.label || d.command || 'CHANNEL').toUpperCase();
        const hex = d.color || '#3B82F6';
        const m = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
        const rgb = m ? `${parseInt(m[1],16)},${parseInt(m[2],16)},${parseInt(m[3],16)}` : '59,130,246';
        $('#cat-preview').innerHTML = `
            <div class="ac-msg" style="--cat:${escapeHtml(hex)};--cat-rgb:${rgb}">
                <div class="ac-avatar" style="background:${escapeHtml(d.color || '#3B82F6')}">JD</div>
                <div class="ac-body">
                    <div class="ac-meta">
                        <span class="ac-chip"><i class="${escapeHtml(d.icon || 'fas fa-comment')}"></i> ${escapeHtml(label)}</span>
                        <span class="ac-name">John Doe</span><span class="ac-time">12:34</span>
                    </div>
                    <div class="ac-text">Sample message in this channel.</div>
                </div>
            </div>`;
    }

    function edit(def) {
        state.current = JSON.parse(JSON.stringify(def));
        renderList();
        fillForm(state.current);
    }

    function mount() {
        ApexBus.post('apex_cat_list');           // list arrives via apex_cats message
        if (!state.current) state.current = newDef();
        fillForm(state.current);
        renderList();
    }
    window.ApexCategories = { mount, setAll };

    function setAll(list) {
        state.all = (list || []).slice().sort((a, b) => (a.order || 999) - (b.order || 999));
        if (state.current && state.current.id && !state.current._isNew) {
            const m = state.all.find(x => x.id === state.current.id);
            if (m) { state.current = JSON.parse(JSON.stringify(m)); fillForm(state.current); }
        }
        renderList();
    }

    /* ───── Events ───── */
    document.addEventListener('input', (e) => {
        if (!e.target.closest('[data-body="categories"]')) return;
        syncFromForm(); renderPreview();
    });

    document.addEventListener('click', (e) => {
        const rule = e.target.closest('.rule-grid .dur-card[data-rule]');
        if (rule) {
            $$('.rule-grid .dur-card[data-rule]').forEach(c => c.classList.toggle('is-active', c === rule));
            ruleFieldVisibility(rule.dataset.rule);
            syncFromForm(); renderPreview();
        }
        if (e.target.closest('#cat-new') || e.target.closest('#cat-create-tile')) {
            state.current = newDef(); fillForm(state.current); renderList();
        }
        if (e.target.closest('#cat-save')) {
            syncFromForm();
            if (!state.current.command) return;
            ApexBus.post('apex_cat_save', state.current);
        }
        if (e.target.closest('#cat-delete')) {
            if (state.current && state.current.id) ApexBus.post('apex_cat_delete', { id: state.current.id });
        }
    });

    // Receives the authoritative list (managers get payload.all).
    window.addEventListener('message', (e) => {
        const d = e.data || {};
        if (d.action === 'apex_cats' && Array.isArray(d.all)) setAll(d.all);
    });
})();
