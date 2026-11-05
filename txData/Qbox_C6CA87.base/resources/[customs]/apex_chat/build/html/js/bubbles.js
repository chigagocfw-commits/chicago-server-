// Apex Chat — 3D bubble renderer
// Receives apex_bubble_* actions from client/modules/bubbles3d.lua
// and positions absolutely-positioned divs at sx*vw, sy*vh.

(function () {
    'use strict';

    const layer = document.getElementById('apex-bubble-layer');
    const bubbles = new Map(); // id -> { el, type, text }

    // /me shows a white chat glyph instead of a "ME" label; /do /try keep text.
    const PREFIX = { me: '<i class="fas fa-comment-dots"></i>', do: 'DO', try: 'TRY' };

    function ensure(id, text, type) {
        let entry = bubbles.get(id);
        if (entry) return entry;
        const el = document.createElement('div');
        el.className = 'apex-bubble type-' + (type || 'me');
        // Park it off-screen until the first show() so a not-yet-positioned
        // bubble never flashes in the top-left corner.
        el.style.left = '-9999px';
        el.style.top  = '-9999px';
        const t = String(type || 'me');
        el.innerHTML = '<span class="apex-bubble-prefix">' + (PREFIX[t] || t.toUpperCase()) + '</span><span class="apex-bubble-text"></span>';
        el.querySelector('.apex-bubble-text').textContent = text || '';
        layer.appendChild(el);
        entry = { el, type, text };
        bubbles.set(id, entry);
        return entry;
    }

    function remove(id) {
        const entry = bubbles.get(id);
        if (!entry) return;
        entry.el.remove();
        bubbles.delete(id);
    }

    window.ApexBubbles = {
        add(id, text, type) { ensure(id, text, type); },
        remove(id)          { remove(id); },
        show(id, x, y, scale, opacity) {
            const entry = bubbles.get(id);
            if (!entry) return;
            const w = window.innerWidth;
            const h = window.innerHeight;
            entry.el.style.left      = (x * w) + 'px';
            entry.el.style.top       = (y * h) + 'px';
            entry.el.style.transform = 'translate(-50%, -100%) scale(' + (scale || 1) + ')';
            entry.el.style.opacity   = String(opacity ?? 1);
            entry.el.classList.add('is-visible');
        },
        hide(id) {
            const entry = bubbles.get(id);
            if (!entry) return;
            entry.el.classList.remove('is-visible');
            entry.el.style.opacity = '0';
        },
    };

    window.addEventListener('message', function (e) {
        const d = e.data || {};
        switch (d.action) {
            case 'apex_bubble_add':    ApexBubbles.add(d.id, d.text, d.type); break;
            case 'apex_bubble_show':   ApexBubbles.show(d.id, d.x, d.y, d.scale, d.opacity); break;
            case 'apex_bubble_hide':   ApexBubbles.hide(d.id); break;
            case 'apex_bubble_remove': ApexBubbles.remove(d.id); break;
        }
    });
})();
