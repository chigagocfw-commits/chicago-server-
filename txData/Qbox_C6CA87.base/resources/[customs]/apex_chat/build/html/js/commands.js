// Apex Chat — Command Creator logic.

(function () {
    'use strict';

    function $(sel, root) { return (root || document).querySelector(sel); }
    function $$(sel, root) { return Array.from((root || document).querySelectorAll(sel)); }

    const state = {
        list:    [],
        current: null,  // currently edited def (working copy)
    };

    function newDef() {
        return {
            id:          (crypto.randomUUID && crypto.randomUUID()) || ('id_' + Date.now()),
            name:        '',
            description: '',
            native:      true,
            duration:    'permanent',
            durationMs:  30000,
            style: {
                background: 'linear-gradient(90deg, rgba(26,25,30,.92) 0%, rgba(255,115,250,.55) 100%)',
                icon:       'fas fa-bolt',
                iconBg:     '#FF73FA',
                titleColor: '#F4F4F5',
                title:      'CUSTOM',
            },
            logic: { type: 'broadcast', job: '', distance: 20 },
        };
    }

    function escapeHtml(s) {
        return String(s || '').replace(/[&<>"']/g, c => ({ '&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;' }[c]));
    }

    function fmtRelative(ts) {
        if (!ts) return '';
        const d = new Date(ts);
        return d.toLocaleDateString(undefined, { month: 'short', day: 'numeric' }) +
               ', ' + d.toLocaleTimeString(undefined, { hour: '2-digit', minute: '2-digit' });
    }

    function renderList() {
        const host = $('#cc-list'); host.innerHTML = '';
        $('#cc-count').textContent      = state.list.length + ' commands';
        $('#cc-side-count').textContent = state.list.length + ' command' + (state.list.length === 1 ? '' : 's') + ' created';
        state.list.forEach(def => {
            const li = document.createElement('li');
            if (state.current && state.current.id === def.id) li.classList.add('is-active');
            li.innerHTML = `
                <div class="cc-head">
                    <span class="cc-icon"><i class="${escapeHtml(def.style?.icon || 'fas fa-bolt')}"></i></span>
                    <span class="cc-name">/${escapeHtml(def.name)}</span>
                </div>
                <div class="cc-type">Custom command</div>
                <div class="cc-desc">${escapeHtml(def.description || '')}</div>
                <div class="cc-meta">
                    ${def._isNew ? '<span class="cc-badge">NEW</span>' : ''}
                    <i class="fas fa-clock"></i>
                    ${escapeHtml(fmtRelative(def._createdAt || Date.now()))}
                </div>`;
            li.addEventListener('click', () => edit(def));
            host.appendChild(li);
        });
    }

    function fillForm(def) {
        $('#cc-editing').textContent     = def.name ? def.name : '—';
        $('#cc-editing-label').style.display = def.name ? '' : 'none';
        $('#cc-name').value              = def.name || '';
        $('#cc-desc').value              = def.description || '';
        $('#cc-native').checked          = def.native !== false;
        $('#cc-native-label').textContent = def.native ? 'ON' : 'OFF';

        $$('.dur-card[data-dur]').forEach(c => c.classList.toggle('is-active', c.dataset.dur === def.duration));
        const tickReset = (root) => $$(root + ' .tick').forEach(t => t.remove());
        tickReset('.duration-grid');
        $$('.duration-grid .dur-card.is-active').forEach(c => {
            const i = document.createElement('i'); i.className = 'fas fa-check tick';
            c.querySelector('strong').appendChild(i);
        });
        $('#cc-dur-ms-field').classList.toggle('hidden', def.duration !== 'auto-remove');
        $('#cc-dur-ms').value = def.durationMs || 30000;

        // Style
        $('#cc-title').value       = def.style?.title || '';
        $('#cc-icon').value        = def.style?.icon || '';
        $('#cc-iconbg').value      = def.style?.iconBg || '#1F5EFF';
        $('#cc-titlecolor').value  = def.style?.titleColor || '#F4F4F5';
        $('#cc-bg').value          = def.style?.background || '';

        // Logic
        $$('.logic-grid .dur-card[data-logic]').forEach(c => c.classList.toggle('is-active', c.dataset.logic === (def.logic?.type || 'broadcast')));
        $('#cc-logic-job-field').classList.toggle('hidden', def.logic?.type !== 'job');
        $('#cc-logic-dist-field').classList.toggle('hidden', def.logic?.type !== 'distance');
        $('#cc-logic-job').value  = def.logic?.job || '';
        $('#cc-logic-dist').value = def.logic?.distance || 20;

        renderPreview();
    }

    function edit(def) {
        state.current = JSON.parse(JSON.stringify(def));
        renderList();
        fillForm(state.current);
    }

    function syncFromForm() {
        if (!state.current) return;
        const d = state.current;
        d.name        = $('#cc-name').value.trim().toLowerCase().replace(/\s+/g, '');
        d.description = $('#cc-desc').value.trim();
        d.native      = $('#cc-native').checked;
        d.duration    = $$('.duration-grid .dur-card[data-dur].is-active')[0]?.dataset.dur || 'permanent';
        d.durationMs  = parseInt($('#cc-dur-ms').value, 10) || 30000;
        d.style = {
            title:      $('#cc-title').value || (d.name || 'CUSTOM').toUpperCase(),
            icon:       $('#cc-icon').value || 'fas fa-bolt',
            iconBg:     $('#cc-iconbg').value,
            titleColor: $('#cc-titlecolor').value,
            background: $('#cc-bg').value,
        };
        d.logic = {
            type:     $$('.logic-grid .dur-card[data-logic].is-active')[0]?.dataset.logic || 'broadcast',
            job:      $('#cc-logic-job').value || '',
            distance: parseFloat($('#cc-logic-dist').value) || 20,
        };
    }

    function renderPreview() {
        if (!state.current) return;
        const d = state.current;
        const html = `
            <div class="chat-message apex-custom" style="background:${escapeHtml(d.style?.background || '#1A1A1B')}">
                <i class="${escapeHtml(d.style?.icon || 'fas fa-bolt')}" style="color:#fff;background-color:${escapeHtml(d.style?.iconBg || '#1F5EFF')};padding:5px;border-radius:5px;"></i>
                <b><span style="color:${escapeHtml(d.style?.titleColor || '#fff')}">[${escapeHtml((d.style?.title || d.name || 'CUSTOM').toUpperCase())}] John Doe [1]</span>&nbsp;<span class="time">12:34</span></b>
                <div class="message">${escapeHtml('Sample message text — this is what players will see.')}</div>
            </div>`;
        $('#cc-preview').innerHTML = html;
    }

    /* ───────────── Wire-up ───────────── */
    function mount() {
        ApexBus.post('apex_cc_list').then(() => { /* list comes via apex_cc_list event */ });
        if (!state.current) { state.current = newDef(); state.current._isNew = true; }
        fillForm(state.current);
    }

    document.addEventListener('input', (e) => {
        if (!e.target.closest('[data-ccbody]')) return;
        syncFromForm(); renderPreview();
    });

    document.addEventListener('change', (e) => {
        if (e.target.id === 'cc-native') {
            $('#cc-native-label').textContent = e.target.checked ? 'ON' : 'OFF';
        }
    });

    document.addEventListener('click', (e) => {
        const card = e.target.closest('.duration-grid .dur-card[data-dur]');
        if (card) {
            $$('.duration-grid .dur-card[data-dur]').forEach(c => c.classList.toggle('is-active', c === card));
            $('#cc-dur-ms-field').classList.toggle('hidden', card.dataset.dur !== 'auto-remove');
            syncFromForm(); renderPreview();
        }

        const logic = e.target.closest('.logic-grid .dur-card[data-logic]');
        if (logic) {
            $$('.logic-grid .dur-card[data-logic]').forEach(c => c.classList.toggle('is-active', c === logic));
            $('#cc-logic-job-field').classList.toggle('hidden', logic.dataset.logic !== 'job');
            $('#cc-logic-dist-field').classList.toggle('hidden', logic.dataset.logic !== 'distance');
            syncFromForm(); renderPreview();
        }

        if (e.target.closest('#cc-new') || e.target.closest('#cc-create-tile')) {
            state.current = newDef(); state.current._isNew = true; state.current._createdAt = Date.now();
            renderList(); fillForm(state.current);
        }
        if (e.target.closest('#cc-save')) {
            syncFromForm();
            if (!state.current.name) { return; }
            ApexBus.post('apex_cc_save', state.current);
        }
        if (e.target.closest('#cc-delete')) {
            if (!state.current || !state.current.id) return;
            ApexBus.post('apex_cc_delete', { id: state.current.id });
        }
    });

    window.addEventListener('message', (e) => {
        const d = e.data || {};
        if (d.action !== 'apex_cc_list') return;
        state.list = (d.list || []).map(x => Object.assign({ _createdAt: Date.now() }, x));
        if (state.current && state.current.id) {
            const match = state.list.find(x => x.id === state.current.id);
            if (match) state.current = JSON.parse(JSON.stringify(match));
        }
        renderList();
    });

    window.ApexCommands = { mount };
})();
