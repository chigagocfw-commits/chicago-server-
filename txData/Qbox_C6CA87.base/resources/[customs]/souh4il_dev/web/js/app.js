// SOUH4IL-DEV — Full Dashboard Controller
// Author: SOUH4IL / Antigravity

let currentTab = 'dashboard';
let isOwner = false;
let onlinePlayersCache = [];

// Listen for NUI Messages from Client Lua
window.addEventListener('message', (event) => {
    const data = event.data;

    if (data.action === 'setVisible') {
        const app = document.getElementById('app');
        if (data.visible) {
            app.style.display = 'flex';
            if (data.status) {
                updateSecurityStatus(data.status);
            }
            // Fetch online players on open
            postNUI('fetchPlayers');
        } else {
            app.style.display = 'none';
        }
    } else if (data.action === 'updateStatus') {
        updateSecurityStatus(data.status);
    } else if (data.action === 'updateLogs') {
        renderAuditLogs(data.logs);
    } else if (data.action === 'updatePlayers') {
        renderPlayers(data.players);
    } else if (data.action === 'syncToggles') {
        if (data.toggles) {
            if (document.getElementById('toggle-godmode')) document.getElementById('toggle-godmode').checked = !!data.toggles.godmode;
            if (document.getElementById('toggle-noclip')) document.getElementById('toggle-noclip').checked = !!data.toggles.noclip;
            if (document.getElementById('toggle-invis')) document.getElementById('toggle-invis').checked = !!data.toggles.invis;
            if (document.getElementById('toggle-sprint')) document.getElementById('toggle-sprint').checked = !!data.toggles.sprint;
            if (document.getElementById('toggle-jump')) document.getElementById('toggle-jump').checked = !!data.toggles.jump;
        }
    }
});

function updateSecurityStatus(status) {
    if (!status) return;
    isOwner = status.isOwner;

    const badge = document.getElementById('profile-badge');
    const roleElem = document.getElementById('dash-role');
    const authElem = document.getElementById('dash-auth');
    const telemAuth = document.getElementById('telemetry-auth');

    if (badge) badge.innerText = status.role || 'STAFF';
    if (roleElem) roleElem.innerText = status.role || 'STAFF';

    if (status.isOwner) {
        if (authElem) authElem.innerText = 'Dual-Key Confirmed';
        if (telemAuth) telemAuth.innerText = 'DUAL-KEY ACTIVE';
        if (badge) {
            badge.className = 'profile-badge owner';
            badge.innerText = 'OWNER';
        }
    } else {
        if (authElem) authElem.innerText = 'Staff Verified';
        if (telemAuth) telemAuth.innerText = 'STAFF AUTHENTICATED';
        if (badge) {
            badge.className = 'profile-badge admin';
            badge.innerText = status.role || 'STAFF';
        }
    }
}

// Tab Switching
document.querySelectorAll('.nav-item').forEach(btn => {
    btn.addEventListener('click', () => {
        const tab = btn.getAttribute('data-tab');
        if (!tab) return;

        document.querySelectorAll('.nav-item').forEach(b => b.classList.remove('active'));
        document.querySelectorAll('.tab-pane').forEach(p => p.classList.remove('active'));

        btn.classList.add('active');
        const targetPane = document.getElementById(`pane-${tab}`);
        if (targetPane) targetPane.classList.add('active');

        const titleElem = document.getElementById('current-tab-title');
        if (titleElem) titleElem.innerText = btn.querySelector('span').innerText;

        currentTab = tab;

        if (tab === 'logs') {
            postNUI('fetchLogs');
        } else if (tab === 'players') {
            postNUI('fetchPlayers');
        }
    });
});

// Close Panel Handler (Button and ESC)
function closePanel() {
    postNUI('close');
}

document.getElementById('close-btn')?.addEventListener('click', closePanel);

window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        const modal = document.getElementById('ban-modal');
        if (modal && modal.style.display !== 'none') {
            modal.style.display = 'none';
        } else {
            closePanel();
        }
    }
});

// Quick Actions
document.getElementById('qa-revive')?.addEventListener('click', () => postNUI('quickAction', { action: 'revive' }));
document.getElementById('qa-heal')?.addEventListener('click', () => postNUI('quickAction', { action: 'heal' }));
document.getElementById('qa-repair')?.addEventListener('click', () => postNUI('quickAction', { action: 'repair' }));
document.getElementById('qa-clean')?.addEventListener('click', () => postNUI('quickAction', { action: 'clean' }));
document.getElementById('qa-tpm')?.addEventListener('click', () => postNUI('quickAction', { action: 'tpm' }));
document.getElementById('qa-dv')?.addEventListener('click', () => postNUI('quickAction', { action: 'dv' }));
document.getElementById('qa-cash')?.addEventListener('click', () => postNUI('giveMoney', { amount: 50000, moneyType: 'cash' }));
document.getElementById('qa-armor')?.addEventListener('click', () => postNUI('quickAction', { action: 'armor' }));

// God Power Toggles
document.getElementById('toggle-godmode')?.addEventListener('change', (e) => {
    postNUI('togglePower', { power: 'godmode', state: e.target.checked });
});
document.getElementById('toggle-noclip')?.addEventListener('change', (e) => {
    postNUI('togglePower', { power: 'noclip', state: e.target.checked });
});
document.getElementById('toggle-invis')?.addEventListener('change', (e) => {
    postNUI('togglePower', { power: 'invis', state: e.target.checked });
});
document.getElementById('toggle-sprint')?.addEventListener('change', (e) => {
    postNUI('togglePower', { power: 'sprint', state: e.target.checked });
});
document.getElementById('toggle-jump')?.addEventListener('change', (e) => {
    postNUI('togglePower', { power: 'jump', state: e.target.checked });
});

// Teleport Destinations
document.querySelectorAll('.teleport-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        const loc = btn.getAttribute('data-loc');
        postNUI('teleportPreset', { location: loc });
    });
});

document.getElementById('btn-tp-coords')?.addEventListener('click', () => {
    const x = parseFloat(document.getElementById('tp-x').value);
    const y = parseFloat(document.getElementById('tp-y').value);
    const z = parseFloat(document.getElementById('tp-z').value);
    if (!isNaN(x) && !isNaN(y) && !isNaN(z)) {
        postNUI('teleportCoords', { x, y, z });
    }
});

// Items & Weapons
document.querySelectorAll('.item-pack-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        const pack = btn.getAttribute('data-pack');
        postNUI('giveItemPack', { pack });
    });
});

document.getElementById('btn-spawn-item')?.addEventListener('click', () => {
    const input = document.getElementById('custom-item-name');
    const countInput = document.getElementById('custom-item-count');
    const itemName = input?.value.trim();
    const count = parseInt(countInput?.value) || 1;
    if (itemName) {
        postNUI('giveCustomItem', { item: itemName, count });
        input.value = '';
    }
});

// Vehicles
document.getElementById('btn-spawn-veh')?.addEventListener('click', () => {
    const input = document.getElementById('veh-model-input');
    const maxTune = document.getElementById('veh-max-tune')?.checked ?? true;
    const model = input?.value.trim();
    if (model) {
        postNUI('spawnVehicle', { model, maxTune });
        input.value = '';
    }
});

document.querySelectorAll('.quick-veh-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        const model = btn.getAttribute('data-model');
        const maxTune = document.getElementById('veh-max-tune')?.checked ?? true;
        postNUI('spawnVehicle', { model, maxTune });
    });
});

document.getElementById('veh-action-tune')?.addEventListener('click', () => postNUI('quickAction', { action: 'maxmod' }));
document.getElementById('veh-action-repair')?.addEventListener('click', () => postNUI('quickAction', { action: 'repair' }));
document.getElementById('veh-action-delete')?.addEventListener('click', () => postNUI('quickAction', { action: 'dv' }));

// Weather
document.querySelectorAll('.weather-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        const weather = btn.getAttribute('data-weather');
        postNUI('setWeather', { weather });
    });
});

// Logs Refresh
document.getElementById('btn-refresh-logs')?.addEventListener('click', () => {
    postNUI('fetchLogs');
});

// Players Roster
document.getElementById('btn-refresh-players')?.addEventListener('click', () => {
    postNUI('fetchPlayers');
});

document.getElementById('player-search')?.addEventListener('input', (e) => {
    const query = e.target.value.toLowerCase().trim();
    filterPlayers(query);
});

function renderPlayers(players) {
    onlinePlayersCache = players || [];
    const countElem = document.getElementById('dash-player-count');
    if (countElem) countElem.innerText = onlinePlayersCache.length;
    filterPlayers('');
}

function filterPlayers(query) {
    const tbody = document.getElementById('player-table-body');
    if (!tbody) return;

    const filtered = onlinePlayersCache.filter(p => {
        if (!query) return true;
        return (
            p.id.toString().includes(query) ||
            p.name.toLowerCase().includes(query) ||
            p.charName.toLowerCase().includes(query) ||
            p.job.toLowerCase().includes(query)
        );
    });

    if (filtered.length === 0) {
        tbody.innerHTML = '<tr><td colspan="6" class="table-empty">No matching players online.</td></tr>';
        return;
    }

    tbody.innerHTML = filtered.map(p => `
        <tr>
            <td><strong>#${p.id}</strong></td>
            <td>${escapeHtml(p.name)}</td>
            <td>${escapeHtml(p.charName)}</td>
            <td><span class="role-badge">${escapeHtml(p.job)}</span></td>
            <td>${p.ping}ms</td>
            <td>
                <div class="player-actions">
                    <button class="p-btn goto" onclick="playerAction('goto', ${p.id})">Goto</button>
                    <button class="p-btn bring" onclick="playerAction('bring', ${p.id})">Bring</button>
                    <button class="p-btn freeze" onclick="playerAction('freeze', ${p.id})">Freeze</button>
                    <button class="p-btn kick" onclick="playerAction('kick', ${p.id}, '${escapeHtml(p.name)}')">Kick</button>
                    <button class="p-btn ban" onclick="openBanModal(${p.id}, '${escapeHtml(p.name)}')">Ban</button>
                </div>
            </td>
        </tr>
    `).join('');
}

// Global player action triggers
window.playerAction = function(action, targetId, name) {
    if (action === 'kick') {
        const reason = prompt(`Enter kick reason for [${targetId}] ${name}:`, 'Violating Chicago RP rules');
        if (reason) {
            postNUI('kickPlayer', { targetId, reason });
        }
    } else if (action === 'freeze') {
        postNUI('freezePlayer', { targetId });
    } else {
        postNUI('teleportAction', { action, targetId });
    }
};

window.openBanModal = function(targetId, name) {
    const modal = document.getElementById('ban-modal');
    document.getElementById('ban-target-id').value = targetId;
    document.getElementById('ban-target-info').innerText = `ID: #${targetId} — ${name}`;
    document.getElementById('ban-reason').value = '';
    modal.style.display = 'flex';
};

document.getElementById('modal-close')?.addEventListener('click', () => {
    document.getElementById('ban-modal').style.display = 'none';
});

document.getElementById('btn-cancel-ban')?.addEventListener('click', () => {
    document.getElementById('ban-modal').style.display = 'none';
});

document.getElementById('btn-confirm-ban')?.addEventListener('click', () => {
    const targetId = document.getElementById('ban-target-id').value;
    const reason = document.getElementById('ban-reason').value.trim() || 'Violating server rules';
    const duration = document.getElementById('ban-duration').value;

    postNUI('banPlayer', { targetId, reason, duration });
    document.getElementById('ban-modal').style.display = 'none';
});

// Logs Rendering
function renderAuditLogs(logs) {
    const container = document.getElementById('logs-container');
    if (!container) return;

    if (!logs || logs.length === 0) {
        container.innerHTML = '<div class="log-entry">No audit records found.</div>';
        return;
    }

    container.innerHTML = logs.map(l => `
        <div class="log-entry">
            <strong>[#${l.id}] ${l.timestamp}</strong> — <span style="color: var(--accent-cyan)">${l.action}</span>
            <br>Executor: ${escapeHtml(l.executor_name)} (${l.executor_license})
            ${l.target_name ? `<br>Target: ${escapeHtml(l.target_name)} (${l.target_license || 'N/A'})` : ''}
            <br>Status: <span style="color: ${l.status === 'SUCCESS' ? 'var(--accent-green)' : 'var(--accent-red)'}">${l.status}</span>
        </div>
    `).join('');
}

function escapeHtml(text) {
    if (!text) return '';
    return text.toString()
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;")
        .replace(/'/g, "&#039;");
}

// NUI Post Helper
function postNUI(endpoint, payload = {}) {
    const resourceName = window.GetParentResourceName ? window.GetParentResourceName() : 'souh4il_dev';
    fetch(`https://${resourceName}/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
    }).catch(err => {
        console.warn('NUI callback error:', err);
    });
}
