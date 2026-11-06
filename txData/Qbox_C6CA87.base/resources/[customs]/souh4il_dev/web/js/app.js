// SOUH4IL-DEV — Full Master Pro Dashboard Controller
// Author: SOUH4IL / Antigravity

let currentTab = 'dashboard';
let isOwner = false;
let onlinePlayersCache = [];
let currentItemFilter = 'all';
let currentVehFilter = 'all';
let allServerItems = [];
let allServerVehicles = [];

// Curated Fallback Vehicles Catalog
const FALLBACK_VEHICLES = [
    { model: 'nero', name: 'Nero', brand: 'Truffade', category: 'super' },
    { model: 'nero2', name: 'Nero Custom', brand: 'Truffade', category: 'super' },
    { model: 't20', name: 'T20', brand: 'Progen', category: 'super' },
    { model: 'zentorno', name: 'Zentorno', brand: 'Pegassi', category: 'super' },
    { model: 'adder', name: 'Adder', brand: 'Truffade', category: 'super' },
    { model: 'tempesta', name: 'Tempesta', brand: 'Pegassi', category: 'super' },
    { model: 'krieger', name: 'Krieger', brand: 'Benefactor', category: 'super' },
    { model: 'emerus', name: 'Emerus', brand: 'Progen', category: 'super' },
    { model: 'sultan', name: 'Sultan', brand: 'Karin', category: 'sports' },
    { model: 'sultanrs', name: 'Sultan RS', brand: 'Karin', category: 'sports' },
    { model: 'elegy', name: 'Elegy RH8', brand: 'Annis', category: 'sports' },
    { model: 'elegy2', name: 'Elegy Retro Custom', brand: 'Annis', category: 'sports' },
    { model: 'jester', name: 'Jester', brand: 'Dinka', category: 'sports' },
    { model: 'massacro', name: 'Massacro', brand: 'Dewbauchee', category: 'sports' },
    { model: 'kuruma', name: 'Kuruma (Armored)', brand: 'Karin', category: 'sports' },
    { model: 'dominator', name: 'Dominator', brand: 'Vapid', category: 'muscle' },
    { model: 'gauntlet', name: 'Gauntlet Hellfire', brand: 'Bravado', category: 'muscle' },
    { model: 'buffalo4', name: 'Buffalo STX', brand: 'Bravado', category: 'muscle' },
    { model: 'toros', name: 'Toros', brand: 'Pegassi', category: 'suvs' },
    { model: 'novak', name: 'Novak', brand: 'Lampadati', category: 'suvs' },
    { model: 'rebla', name: 'Rebla GTS', brand: 'Ubermacht', category: 'suvs' },
    { model: 'schafter3', name: 'Schafter V12', brand: 'Benefactor', category: 'sedans' },
    { model: 'tailgater2', name: 'Tailgater S', brand: 'Obey', category: 'sedans' },
    { model: 'bf400', name: 'BF400', brand: 'Nagasaki', category: 'motorcycles' },
    { model: 'bati', name: 'Bati 801', brand: 'Pegassi', category: 'motorcycles' },
    { model: 'shinobi', name: 'Shinobi', brand: 'Nagasaki', category: 'motorcycles' },
    { model: 'draugur', name: 'Draugur', brand: 'Declasse', category: 'offroad' },
    { model: 'kamacho', name: 'Kamacho', brand: 'Canis', category: 'offroad' },
    { model: 'police', name: 'Police Cruiser', brand: 'Vapid', category: 'emergency' },
    { model: 'police2', name: 'Police Buffalo', brand: 'Bravado', category: 'emergency' },
    { model: 'police3', name: 'Police Interceptor', brand: 'Vapid', category: 'emergency' },
    { model: 'ambulance', name: 'Ambulance EMS', brand: 'Brute', category: 'emergency' },
    { model: 'firetruk', name: 'Fire Truck', brand: 'MTL', category: 'emergency' },
];

// Curated Visual Items Catalog (Fallback)
const VISUAL_ITEMS = [
    // Weapons
    { name: 'weapon_combatpistol', label: 'Combat Pistol', category: 'weapon' },
    { name: 'weapon_appistol', label: 'AP Pistol', category: 'weapon' },
    { name: 'weapon_pistol50', label: 'Pistol .50', category: 'weapon' },
    { name: 'weapon_carbinerifle', label: 'Carbine Rifle (M4)', category: 'weapon' },
    { name: 'weapon_specialcarbine', label: 'Special Carbine (G36)', category: 'weapon' },
    { name: 'weapon_assaultrifle', label: 'Assault Rifle (AK47)', category: 'weapon' },
    { name: 'weapon_smg', label: 'Micro SMG (MP5)', category: 'weapon' },
    { name: 'weapon_combatpdw', label: 'Combat PDW', category: 'weapon' },
    { name: 'weapon_heavysniper', label: 'Heavy Sniper', category: 'weapon' },
    { name: 'weapon_pumpshotgun', label: 'Pump Shotgun', category: 'weapon' },
    { name: 'weapon_knife', label: 'Combat Knife', category: 'weapon' },
    { name: 'weapon_bat', label: 'Baseball Bat', category: 'weapon' },
    { name: 'weapon_katana', label: 'Katana', category: 'weapon' },

    // Ammo
    { name: 'ammo-9', label: '9mm Ammo', category: 'ammo' },
    { name: 'ammo-45', label: '.45 ACP Ammo', category: 'ammo' },
    { name: 'ammo-rifle', label: '5.56 Rifle Ammo', category: 'ammo' },
    { name: 'ammo-shotgun', label: '12-Gauge Shells', category: 'ammo' },
    { name: 'ammo-sniper', label: 'Sniper Rounds', category: 'ammo' },

    // Food & Drink
    { name: 'burger', label: 'Burger', category: 'food' },
    { name: 'testburger', label: 'Test Burger', category: 'food' },
    { name: 'sandwich', label: 'Sandwich', category: 'food' },
    { name: 'taco', label: 'Taco', category: 'food' },
    { name: 'donut', label: 'Donut', category: 'food' },
    { name: 'hotdog', label: 'Hotdog', category: 'food' },
    { name: 'water', label: 'Water Bottle', category: 'food' },
    { name: 'cola', label: 'eCola', category: 'food' },
    { name: 'sprunk', label: 'Sprunk', category: 'food' },
    { name: 'coffee', label: 'Coffee Cup', category: 'food' },

    // Medical & Armor
    { name: 'bandage', label: 'Medical Bandage', category: 'medical' },
    { name: 'medikit', label: 'Medikit Case', category: 'medical' },
    { name: 'painkillers', label: 'Painkillers', category: 'medical' },
    { name: 'firstaid', label: 'First Aid Kit', category: 'medical' },
    { name: 'armor', label: 'Heavy Kevlar Armor', category: 'medical' },

    // Tools & Valuables
    { name: 'money', label: 'Cash Money ($)', category: 'tool' },
    { name: 'lockpick', label: 'Lockpick', category: 'tool' },
    { name: 'advancedlockpick', label: 'Advanced Lockpick', category: 'tool' },
    { name: 'repairkit', label: 'Vehicle Repair Kit', category: 'tool' },
    { name: 'advancedkit', label: 'Advanced Repair Kit', category: 'tool' },
    { name: 'phone', label: 'Smartphone', category: 'tool' },
    { name: 'radio', label: 'Radio Transmitter', category: 'tool' },
    { name: 'handcuffs', label: 'Police Handcuffs', category: 'tool' },
    { name: 'parachute', label: 'Parachute', category: 'tool' },
    { name: 'drill', label: 'Bank Heist Drill', category: 'tool' },
    { name: 'thermite', label: 'Thermite Bomb', category: 'tool' },
];

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
            postNUI('fetchPlayers');
            postNUI('fetchAllItems');
            postNUI('fetchAllVehicles');
            renderVisualItems();
            renderVisualVehicles();
        } else {
            app.style.display = 'none';
        }
    } else if (data.action === 'updateStatus') {
        updateSecurityStatus(data.status);
    } else if (data.action === 'updateLogs') {
        renderAuditLogs(data.logs);
    } else if (data.action === 'updatePlayers') {
        renderPlayers(data.players);
    } else if (data.action === 'updateAllItems') {
        if (data.items && Array.isArray(data.items) && data.items.length > 0) {
            allServerItems = data.items;
            const query = document.getElementById('item-search-input')?.value.toLowerCase().trim() || '';
            renderVisualItems(query);
        }
    } else if (data.action === 'updateAllVehicles') {
        if (data.vehicles && Array.isArray(data.vehicles) && data.vehicles.length > 0) {
            allServerVehicles = data.vehicles;
            const query = document.getElementById('veh-search-input')?.value.toLowerCase().trim() || '';
            renderVisualVehicles(query);
        }
    } else if (data.action === 'updateCoordsDisplay') {
        const el = document.getElementById('current-coords-display');
        if (el && data.text) el.innerText = data.text;
    } else if (data.action === 'syncToggles') {
        if (data.toggles) {
            syncToggles(data.toggles);
        }
    }
});

function syncToggles(t) {
    const setCheck = (id, val) => {
        const el = document.getElementById(id);
        if (el) el.checked = !!val;
    };
    setCheck('toggle-godmode', t.godmode);
    setCheck('toggle-noclip', t.noclip);
    setCheck('toggle-invis', t.invis);
    setCheck('toggle-ammo', t.ammo);
    setCheck('toggle-damage', t.damage);
    setCheck('toggle-wanted', t.wanted);
    setCheck('toggle-thermal', t.thermal);
    setCheck('toggle-nightvision', t.nightvision);
    setCheck('toggle-sprint', t.sprint);
    setCheck('toggle-jump', t.jump);
    setCheck('toggle-vehgod', t.vehgod);
    setCheck('toggle-vehboost', t.vehboost);
    setCheck('toggle-inspector', t.inspector);
    setCheck('toggle-hidehud', t.hidehud);
    setCheck('toggle-blackout', t.blackout);
}

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
        } else if (tab === 'players' || tab === 'teleport') {
            postNUI('fetchPlayers');
        } else if (tab === 'items') {
            const query = document.getElementById('item-search-input')?.value.toLowerCase().trim() || '';
            renderVisualItems(query);
        } else if (tab === 'vehicles') {
            const query = document.getElementById('veh-search-input')?.value.toLowerCase().trim() || '';
            renderVisualVehicles(query);
        } else if (tab === 'devtools') {
            postNUI('requestCoordsDisplay');
        }
    });
});

// Guaranteed Bulletproof Close Handler
function closePanel() {
    const app = document.getElementById('app');
    if (app) app.style.display = 'none';
    const modal = document.getElementById('ban-modal');
    if (modal) modal.style.display = 'none';
    const jobModal = document.getElementById('job-modal');
    if (jobModal) jobModal.style.display = 'none';
    postNUI('close');
}

document.getElementById('close-btn')?.addEventListener('click', (e) => {
    e.preventDefault();
    e.stopPropagation();
    closePanel();
});

window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        const modal = document.getElementById('ban-modal');
        const jobModal = document.getElementById('job-modal');
        if (modal && modal.style.display !== 'none') {
            modal.style.display = 'none';
        } else if (jobModal && jobModal.style.display !== 'none') {
            jobModal.style.display = 'none';
        } else {
            closePanel();
        }
    }
});

// Quick Actions
document.getElementById('qa-revive')?.addEventListener('click', () => postNUI('quickAction', { action: 'revive' }));
document.getElementById('qa-heal')?.addEventListener('click', () => postNUI('quickAction', { action: 'heal' }));
document.getElementById('qa-armor')?.addEventListener('click', () => postNUI('quickAction', { action: 'armor' }));
document.getElementById('qa-repair')?.addEventListener('click', () => postNUI('quickAction', { action: 'repair' }));
document.getElementById('qa-clean')?.addEventListener('click', () => postNUI('quickAction', { action: 'clean' }));
document.getElementById('qa-tpm')?.addEventListener('click', () => postNUI('quickAction', { action: 'tpm' }));
document.getElementById('qa-dv')?.addEventListener('click', () => postNUI('quickAction', { action: 'dv' }));
document.getElementById('qa-cash')?.addEventListener('click', () => postNUI('giveMoney', { amount: 50000, moneyType: 'cash' }));

// Full Super Powers Suite Toggles
const registerToggle = (id, power) => {
    document.getElementById(id)?.addEventListener('change', (e) => {
        postNUI('togglePower', { power, state: e.target.checked });
    });
};

registerToggle('toggle-godmode', 'godmode');
registerToggle('toggle-noclip', 'noclip');
registerToggle('toggle-invis', 'invis');
registerToggle('toggle-ammo', 'ammo');
registerToggle('toggle-damage', 'damage');
registerToggle('toggle-wanted', 'wanted');
registerToggle('toggle-thermal', 'thermal');
registerToggle('toggle-nightvision', 'nightvision');
registerToggle('toggle-sprint', 'sprint');
registerToggle('toggle-jump', 'jump');
registerToggle('toggle-vehgod', 'vehgod');
registerToggle('toggle-vehboost', 'vehboost');
registerToggle('toggle-inspector', 'inspector');
registerToggle('toggle-hidehud', 'hidehud');
registerToggle('toggle-blackout', 'blackout');

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

// Teleport: Refresh Players
document.getElementById('btn-tp-refresh-players')?.addEventListener('click', () => postNUI('fetchPlayers'));

document.getElementById('tp-player-search')?.addEventListener('input', (e) => {
    filterTeleportPlayers(e.target.value.toLowerCase().trim());
});

// Visual Items Rendering & Categories (Dynamic ox_inventory Catalog)
function renderVisualItems(searchQuery = '') {
    const container = document.getElementById('visual-items-container');
    if (!container) return;

    const sourceList = (allServerItems && allServerItems.length > 0) ? allServerItems : VISUAL_ITEMS;

    const filtered = sourceList.filter(item => {
        const cat = (item.category || 'tool').toLowerCase();
        let matchesCategory = false;
        if (currentItemFilter === 'all') {
            matchesCategory = true;
        } else if (currentItemFilter === 'weapon') {
            matchesCategory = cat === 'weapon' || item.name.toLowerCase().startsWith('weapon_');
        } else if (currentItemFilter === 'ammo') {
            matchesCategory = cat === 'ammo' || item.name.toLowerCase().includes('ammo');
        } else if (currentItemFilter === 'food') {
            matchesCategory = cat === 'food';
        } else if (currentItemFilter === 'medical') {
            matchesCategory = cat === 'medical';
        } else if (currentItemFilter === 'tool') {
            matchesCategory = cat === 'tool' || (!cat.includes('weapon') && !cat.includes('ammo') && !cat.includes('food') && !cat.includes('medical'));
        }

        const q = searchQuery.toLowerCase().trim();
        const matchesSearch = !q || 
            item.name.toLowerCase().includes(q) || 
            (item.label && item.label.toLowerCase().includes(q));

        return matchesCategory && matchesSearch;
    });

    if (filtered.length === 0) {
        container.innerHTML = '<div class="table-empty" style="grid-column: 1 / -1;">No matching items found.</div>';
        return;
    }

    // Limit initial DOM nodes to 150 for fluid 60FPS UI response
    const renderChunk = filtered.slice(0, 150);

    container.innerHTML = renderChunk.map(item => {
        const itemName = item.name.toLowerCase();
        const itemLabel = item.label || item.name;
        const imgSrc = `https://cfx-nui-ox_inventory/web/images/${itemName}.png`;
        const fallbackSrc = `nui://ox_inventory/web/images/${itemName}.png`;
        return `
            <div class="visual-item-card">
                <div class="item-thumb-wrapper">
                    <img class="item-thumb" src="${imgSrc}" onerror="this.onerror=null; this.src='${fallbackSrc}'; this.parentElement.innerHTML='<span style=\\'font-size:24px\\'>📦</span>';">
                </div>
                <div class="item-label" title="${escapeHtml(itemLabel)}">${escapeHtml(itemLabel)}</div>
                <div class="item-name-tag">${itemName}</div>
                <div class="item-qty-row">
                    <button class="qty-btn" onclick="giveItemDirect('${itemName}', 1)">+1</button>
                    <button class="qty-btn" onclick="giveItemDirect('${itemName}', 5)">+5</button>
                    <button class="qty-btn" onclick="giveItemDirect('${itemName}', 20)">+20</button>
                </div>
            </div>
        `;
    }).join('');
}

window.giveItemDirect = function(itemName, count) {
    postNUI('giveCustomItem', { item: itemName, count });
};

document.querySelectorAll('.filter-chip').forEach(chip => {
    chip.addEventListener('click', () => {
        document.querySelectorAll('.filter-chip').forEach(c => c.classList.remove('active'));
        chip.classList.add('active');
        currentItemFilter = chip.getAttribute('data-cat');
        const query = document.getElementById('item-search-input')?.value.toLowerCase().trim() || '';
        renderVisualItems(query);
    });
});

document.getElementById('item-search-input')?.addEventListener('input', (e) => {
    renderVisualItems(e.target.value.toLowerCase().trim());
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

// Visual Vehicles Rendering & Categories (Dynamic Qbox Vehicles Catalog)
function renderVisualVehicles(searchQuery = '') {
    const container = document.getElementById('visual-vehicles-container');
    if (!container) return;

    const sourceList = (allServerVehicles && allServerVehicles.length > 0) ? allServerVehicles : FALLBACK_VEHICLES;

    const filtered = sourceList.filter(veh => {
        const cat = (veh.category || '').toLowerCase();
        let matchesCategory = false;
        if (currentVehFilter === 'all') {
            matchesCategory = true;
        } else if (currentVehFilter === 'super') {
            matchesCategory = cat.includes('super');
        } else if (currentVehFilter === 'sports') {
            matchesCategory = cat.includes('sport');
        } else if (currentVehFilter === 'muscle') {
            matchesCategory = cat.includes('muscle');
        } else if (currentVehFilter === 'suvs') {
            matchesCategory = cat.includes('suv');
        } else if (currentVehFilter === 'sedans') {
            matchesCategory = cat.includes('sedan') || cat.includes('coupe') || cat.includes('compact');
        } else if (currentVehFilter === 'emergency') {
            matchesCategory = cat.includes('emerg') || cat.includes('police') || cat.includes('fire') || cat.includes('medic');
        } else if (currentVehFilter === 'motorcycles') {
            matchesCategory = cat.includes('motor') || cat.includes('bike') || cat.includes('cycle');
        } else if (currentVehFilter === 'offroad') {
            matchesCategory = cat.includes('off') || cat.includes('road');
        } else if (currentVehFilter === 'vans') {
            matchesCategory = cat.includes('van') || cat.includes('commercial') || cat.includes('industrial');
        }

        const q = searchQuery.toLowerCase().trim();
        const matchesSearch = !q || 
            veh.model.toLowerCase().includes(q) || 
            (veh.name && veh.name.toLowerCase().includes(q)) ||
            (veh.brand && veh.brand.toLowerCase().includes(q));

        return matchesCategory && matchesSearch;
    });

    if (filtered.length === 0) {
        container.innerHTML = '<div class="table-empty" style="grid-column: 1 / -1;">No matching vehicles found.</div>';
        return;
    }

    // Limit to 120 items per page/view for fast rendering
    const renderChunk = filtered.slice(0, 120);

    container.innerHTML = renderChunk.map(veh => {
        const model = veh.model.toLowerCase();
        const name = veh.name || model;
        const brand = veh.brand || '';
        const cat = veh.category || 'Vehicle';
        const imgFiveM = `https://docs.fivem.net/vehicles/${model}.webp`;
        const imgFallback = `https://raw.githubusercontent.com/root-cause/v-vehicle-hashes/master/images/${model}.png`;

        return `
            <div class="visual-veh-card">
                <div class="veh-thumb-wrapper">
                    ${brand ? `<span class="veh-brand-tag">${escapeHtml(brand)}</span>` : ''}
                    <span class="veh-cat-tag">${escapeHtml(cat)}</span>
                    <img class="veh-thumb" src="${imgFiveM}" onerror="this.onerror=null; this.src='${imgFallback}'; this.onerror=function(){ this.parentElement.innerHTML='<span style=\\'font-size:38px;opacity:0.7;\\'>🚘</span>'; };">
                </div>
                <div class="veh-title" title="${escapeHtml(name)}">${escapeHtml(name)}</div>
                <div class="veh-model-sub">${model}</div>
                <button class="veh-spawn-btn" onclick="spawnVehicleDirect('${model}')">Spawn Driver</button>
            </div>
        `;
    }).join('');
}

window.spawnVehicleDirect = function(model) {
    const maxTune = document.getElementById('veh-max-tune')?.checked ?? true;
    postNUI('spawnVehicle', { model, maxTune });
};

document.querySelectorAll('.filter-chip-veh').forEach(chip => {
    chip.addEventListener('click', () => {
        document.querySelectorAll('.filter-chip-veh').forEach(c => c.classList.remove('active'));
        chip.classList.add('active');
        currentVehFilter = chip.getAttribute('data-cat');
        const query = document.getElementById('veh-search-input')?.value.toLowerCase().trim() || '';
        renderVisualVehicles(query);
    });
});

document.getElementById('veh-search-input')?.addEventListener('input', (e) => {
    renderVisualVehicles(e.target.value.toLowerCase().trim());
});

// Vehicles Spawner & Workshop
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

document.getElementById('btn-set-plate')?.addEventListener('click', () => {
    const input = document.getElementById('veh-plate-input');
    const plate = input?.value.trim();
    if (plate) {
        postNUI('setVehiclePlate', { plate });
        input.value = '';
    }
});

document.getElementById('btn-flip-veh')?.addEventListener('click', () => postNUI('flipVehicle'));
document.getElementById('veh-action-tune')?.addEventListener('click', () => postNUI('quickAction', { action: 'maxmod' }));
document.getElementById('veh-action-repair')?.addEventListener('click', () => postNUI('quickAction', { action: 'repair' }));
document.getElementById('veh-action-delete')?.addEventListener('click', () => postNUI('quickAction', { action: 'dv' }));

document.getElementById('veh-doors-all')?.addEventListener('click', () => postNUI('toggleDoors', { door: 'all' }));
document.getElementById('veh-doors-hood')?.addEventListener('click', () => postNUI('toggleDoors', { door: 'hood' }));
document.getElementById('veh-doors-trunk')?.addEventListener('click', () => postNUI('toggleDoors', { door: 'trunk' }));

document.querySelectorAll('.color-chip').forEach(chip => {
    chip.addEventListener('click', () => {
        const color = parseInt(chip.getAttribute('data-color'));
        postNUI('setVehicleColor', { color });
    });
});

// Developer Tools: Coords
document.getElementById('btn-copy-vec3')?.addEventListener('click', () => postNUI('copyCoords', { format: 'vec3' }));
document.getElementById('btn-copy-vec4')?.addEventListener('click', () => postNUI('copyCoords', { format: 'vec4' }));
document.getElementById('btn-copy-heading')?.addEventListener('click', () => postNUI('copyCoords', { format: 'heading' }));

// Developer Tools: Area Cleaning
document.getElementById('btn-clear-veh')?.addEventListener('click', () => postNUI('clearArea', { type: 'vehicles' }));
document.getElementById('btn-clear-peds')?.addEventListener('click', () => postNUI('clearArea', { type: 'peds' }));
document.getElementById('btn-clear-props')?.addEventListener('click', () => postNUI('clearArea', { type: 'props' }));
document.getElementById('btn-clear-all')?.addEventListener('click', () => postNUI('clearArea', { type: 'all' }));

// Developer Tools: Skins
document.querySelectorAll('[data-skin]').forEach(btn => {
    btn.addEventListener('click', () => {
        const skin = btn.getAttribute('data-skin');
        postNUI('setPedModel', { model: skin });
    });
});

document.getElementById('btn-apply-skin')?.addEventListener('click', () => {
    const input = document.getElementById('custom-skin-input');
    const skin = input?.value.trim();
    if (skin) {
        postNUI('setPedModel', { model: skin });
        input.value = '';
    }
});

// World: Time of Day
document.querySelectorAll('[data-time-h]').forEach(btn => {
    btn.addEventListener('click', () => {
        const hour = parseInt(btn.getAttribute('data-time-h'));
        const minute = parseInt(btn.getAttribute('data-time-m')) || 0;
        postNUI('setTime', { hour, minute });
    });
});

// World: Broadcast Announcement
document.getElementById('btn-send-broadcast')?.addEventListener('click', () => {
    const input = document.getElementById('broadcast-msg-input');
    const msg = input?.value.trim();
    if (msg) {
        postNUI('broadcastAnnouncement', { message: msg });
        input.value = '';
    }
});

// World: Weather
document.querySelectorAll('.weather-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        const weather = btn.getAttribute('data-weather');
        postNUI('setWeather', { weather });
    });
});

// Logs Refresh
document.getElementById('btn-refresh-logs')?.addEventListener('click', () => postNUI('fetchLogs'));

// Players Roster & Teleport List
document.getElementById('btn-refresh-players')?.addEventListener('click', () => postNUI('fetchPlayers'));

document.getElementById('player-search')?.addEventListener('input', (e) => {
    filterPlayers(e.target.value.toLowerCase().trim());
});

function renderPlayers(players) {
    onlinePlayersCache = players || [];
    const countElem = document.getElementById('dash-player-count');
    if (countElem) countElem.innerText = onlinePlayersCache.length;
    filterPlayers('');
    filterTeleportPlayers('');
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
                    <button class="p-btn spectate" onclick="playerAction('spectate', ${p.id})">Spectate</button>
                    <button class="p-btn setjob" onclick="openJobModal(${p.id}, '${escapeHtml(p.name)}')">Set Job</button>
                    <button class="p-btn clearinv" onclick="playerAction('clearinv', ${p.id}, '${escapeHtml(p.name)}')">Clear Inv</button>
                    <button class="p-btn kick" onclick="playerAction('kick', ${p.id}, '${escapeHtml(p.name)}')">Kick</button>
                    <button class="p-btn ban" onclick="openBanModal(${p.id}, '${escapeHtml(p.name)}')">Ban</button>
                </div>
            </td>
        </tr>
    `).join('');
}

function filterTeleportPlayers(query) {
    const container = document.getElementById('tp-players-container');
    if (!container) return;

    const filtered = onlinePlayersCache.filter(p => {
        if (!query) return true;
        return (
            p.id.toString().includes(query) ||
            p.name.toLowerCase().includes(query) ||
            p.charName.toLowerCase().includes(query)
        );
    });

    if (filtered.length === 0) {
        container.innerHTML = '<div class="table-empty" style="grid-column: 1 / -1;">No players online to teleport to.</div>';
        return;
    }

    container.innerHTML = filtered.map(p => `
        <div class="tp-player-card">
            <div class="tp-player-info">
                <span class="tp-player-id">#${p.id}</span>
                <span class="tp-player-name">${escapeHtml(p.name)}</span>
                <span class="tp-player-char">${escapeHtml(p.charName)} (${escapeHtml(p.job)})</span>
            </div>
            <div class="tp-player-btns">
                <button class="p-btn goto" onclick="playerAction('goto', ${p.id})">Warp To (Goto)</button>
                <button class="p-btn bring" onclick="playerAction('bring', ${p.id})">Summon (Bring)</button>
            </div>
        </div>
    `).join('');
}

// Global player action triggers
window.playerAction = function(action, targetId, name) {
    if (action === 'kick') {
        const reason = prompt(`Enter kick reason for [${targetId}] ${name}:`, 'Violating Chicago RP rules');
        if (reason) {
            postNUI('kickPlayer', { targetId, reason });
        }
    } else if (action === 'clearinv') {
        if (confirm(`Are you sure you want to completely clear inventory of [${targetId}] ${name}?`)) {
            postNUI('clearPlayerInventory', { targetId });
        }
    } else if (action === 'freeze') {
        postNUI('freezePlayer', { targetId });
    } else if (action === 'spectate') {
        postNUI('spectatePlayer', { targetId });
    } else {
        postNUI('teleportAction', { action, targetId });
    }
};

// Ban Modal
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

// Set Job Modal
window.openJobModal = function(targetId, name) {
    const modal = document.getElementById('job-modal');
    document.getElementById('job-target-id').value = targetId;
    document.getElementById('job-target-info').innerText = `ID: #${targetId} — ${name}`;
    modal.style.display = 'flex';
};

document.getElementById('job-modal-close')?.addEventListener('click', () => {
    document.getElementById('job-modal').style.display = 'none';
});

document.getElementById('btn-cancel-job')?.addEventListener('click', () => {
    document.getElementById('job-modal').style.display = 'none';
});

document.getElementById('btn-confirm-job')?.addEventListener('click', () => {
    const targetId = document.getElementById('job-target-id').value;
    const job = document.getElementById('job-select').value;
    const grade = document.getElementById('job-grade-select').value;

    postNUI('setPlayerJob', { targetId, job, grade });
    document.getElementById('job-modal').style.display = 'none';
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
