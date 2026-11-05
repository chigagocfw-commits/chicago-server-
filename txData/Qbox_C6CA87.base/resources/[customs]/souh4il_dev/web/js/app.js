// SOUH4IL-DEV — NUI Controller
// Handles tab navigation, UI lifecycle, action triggers, and ESC closing

let currentTab = 'dashboard';
let isOwner = false;

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
        } else {
            app.style.display = 'none';
        }
    } else if (data.action === 'updateStatus') {
        updateSecurityStatus(data.status);
    } else if (data.action === 'updateLogs') {
        renderAuditLogs(data.logs);
    }
});

function updateSecurityStatus(status) {
    if (!status) return;

    isOwner = status.isOwner;
    const badge = document.getElementById('profile-badge');
    const roleElem = document.getElementById('dash-role');
    const authElem = document.getElementById('dash-auth');
    const arsenalNav = document.getElementById('nav-arsenal');

    if (badge) badge.innerText = status.role || 'PLAYER';
    if (roleElem) roleElem.innerText = status.role || 'PLAYER';
    
    if (status.isOwner) {
        if (authElem) authElem.innerText = 'Dual-Key Confirmed';
        if (badge) {
            badge.className = 'profile-badge owner';
            badge.innerText = 'OWNER';
        }
        if (arsenalNav) arsenalNav.style.display = 'flex';
    } else {
        if (authElem) authElem.innerText = 'Standard Role';
        if (badge) {
            badge.className = 'profile-badge admin';
        }
        // Hide Owner Arsenal completely for non-owners
        if (arsenalNav) arsenalNav.style.display = 'none';
    }
}

// Tab Switching
document.querySelectorAll('.nav-item').forEach(btn => {
    btn.addEventListener('click', () => {
        const tab = btn.getAttribute('data-tab');
        if (!tab) return;

        // Non-owners cannot click Arsenal
        if (tab === 'arsenal' && !isOwner) {
            return;
        }

        switchTab(tab);
    });
});

function switchTab(tabName) {
    currentTab = tabName;

    // Update active nav button
    document.querySelectorAll('.nav-item').forEach(btn => {
        btn.classList.toggle('active', btn.getAttribute('data-tab') === tabName);
    });

    // Update breadcrumb
    const titleElem = document.getElementById('current-tab-title');
    if (titleElem) {
        titleElem.innerText = tabName.charAt(0).toUpperCase() + tabName.slice(1);
    }

    // Update active pane
    document.querySelectorAll('.tab-pane').forEach(pane => {
        pane.classList.toggle('active', pane.id === `pane-${tabName}`);
    });

    // Trigger data fetch if entering logs
    if (tabName === 'logs') {
        postNUI('fetchLogs');
    }
}

// Close Panel Function
function closePanel() {
    const app = document.getElementById('app');
    app.style.display = 'none';
    postNUI('close');
}

// Close on Button Click
document.getElementById('close-btn')?.addEventListener('click', closePanel);

// Close on ESC Key
window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' || e.keyCode === 27) {
        closePanel();
    }
});

// Quick Actions Listeners
document.getElementById('qa-revive')?.addEventListener('click', () => postNUI('quickAction', { action: 'revive' }));
document.getElementById('qa-heal')?.addEventListener('click', () => postNUI('quickAction', { action: 'heal' }));
document.getElementById('qa-repair')?.addEventListener('click', () => postNUI('quickAction', { action: 'repair' }));
document.getElementById('qa-clean')?.addEventListener('click', () => postNUI('quickAction', { action: 'clean' }));
document.getElementById('qa-tpm')?.addEventListener('click', () => postNUI('quickAction', { action: 'tpm' }));
document.getElementById('qa-dv')?.addEventListener('click', () => postNUI('quickAction', { action: 'dv' }));

// Weather Buttons
document.querySelectorAll('.weather-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        const weather = btn.getAttribute('data-weather');
        postNUI('setWeather', { weather });
    });
});

// Loadout Buttons
document.querySelectorAll('.loadout-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        const loadout = btn.getAttribute('data-loadout');
        postNUI('requestLoadout', { loadout });
    });
});

// Vehicle Spawn
document.getElementById('btn-spawn-veh')?.addEventListener('click', () => {
    const input = document.getElementById('veh-model-input');
    const model = input?.value.trim();
    if (model) {
        postNUI('spawnVehicle', { model });
        input.value = '';
    }
});

// Render Logs
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
            <br>Executor: ${l.executor_name} (${l.executor_license})
            ${l.target_name ? `<br>Target: ${l.target_name} (${l.target_license || 'N/A'})` : ''}
            <br>Status: <span style="color: ${l.status === 'SUCCESS' ? 'var(--accent-green)' : 'var(--accent-red)'}">${l.status}</span>
        </div>
    `).join('');
}

// Helper to post message to FiveM client
function postNUI(endpoint, payload = {}) {
    const resourceName = window.GetParentResourceName ? window.GetParentResourceName() : 'souh4il_dev';
    fetch(`https://${resourceName}/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; credentials' },
        body: JSON.stringify(payload)
    }).catch(err => {
        console.warn('NUI callback error (Normal in browser preview):', err);
    });
}

