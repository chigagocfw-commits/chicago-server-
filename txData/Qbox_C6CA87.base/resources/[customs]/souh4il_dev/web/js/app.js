// SOUH4IL-DEV — Full Master Pro Dashboard Controller
// Author: SOUH4IL / Antigravity

let currentTab = 'dashboard';
let isOwner = false;
let onlinePlayersCache = [];
let currentItemFilter = 'all';
let currentVehFilter = 'all';
let currentPedFilter = 'all';
let currentJobFilter = 'all';
let allServerItems = [];
let allServerVehicles = [];
let allServerJobs = [];

// Curated Characters & Peds Catalog (Top GTA V / FiveM Ped Models)
const VISUAL_PEDS = [
    // VIP & Story Characters
    { model: 'player_zero', label: 'Michael De Santa', category: 'vip' },
    { model: 'player_one', label: 'Franklin Clinton', category: 'vip' },
    { model: 'player_two', label: 'Trevor Philips', category: 'vip' },
    { model: 'ig_lestercrest', label: 'Lester Crest', category: 'vip' },
    { model: 'ig_lamardavis', label: 'Lamar Davis', category: 'vip' },
    { model: 'cs_martinmadrazo', label: 'Martin Madrazo', category: 'vip' },
    { model: 'ig_bankman', label: 'Bank Manager', category: 'vip' },
    { model: 'ig_solomon', label: 'Solomon Richards', category: 'vip' },
    { model: 'ig_beverly', label: 'Beverly Felton', category: 'vip' },
    { model: 'ig_davenorton', label: 'Dave Norton (FIB)', category: 'vip' },
    { model: 'ig_stevehains', label: 'Steve Haines (FIB)', category: 'vip' },
    { model: 'ig_siemonyetarian', label: 'Simeon Yetarian', category: 'vip' },
    { model: 'ig_drfriedlander', label: 'Dr. Friedlander', category: 'vip' },

    // Emergency & Law Enforcement
    { model: 's_m_y_cop_01', label: 'Police Officer', category: 'emergency' },
    { model: 's_f_y_cop_01', label: 'Female Police Officer', category: 'emergency' },
    { model: 's_m_y_sheriff_01', label: 'Sheriff Deputy', category: 'emergency' },
    { model: 's_f_y_sheriff_01', label: 'Female Sheriff', category: 'emergency' },
    { model: 's_m_y_swat_01', label: 'SWAT Tactical Unit', category: 'emergency' },
    { model: 's_m_y_hwaycop_01', label: 'Highway Patrol Trooper', category: 'emergency' },
    { model: 's_m_m_paramedic_01', label: 'EMS Paramedic', category: 'emergency' },
    { model: 's_m_y_fireman_01', label: 'Firefighter', category: 'emergency' },
    { model: 's_m_m_doctor_01', label: 'Doctor / Surgeon', category: 'emergency' },
    { model: 's_m_m_security_01', label: 'Armed Security Guard', category: 'emergency' },
    { model: 's_m_m_prisguard_01', label: 'Prison Guard', category: 'emergency' },
    { model: 's_m_m_fiboffice_01', label: 'FIB Special Agent', category: 'emergency' },
    { model: 's_m_m_armoured_01', label: 'Gruppe 6 Cash Transit', category: 'emergency' },

    // Gangs & Street Soldiers
    { model: 'g_m_y_ballasout_01', label: 'Ballas Leader', category: 'gang' },
    { model: 'g_m_y_ballaorig_01', label: 'Ballas Original', category: 'gang' },
    { model: 'g_m_y_famca_01', label: 'Families Gang Member', category: 'gang' },
    { model: 'g_m_y_famdn_01', label: 'Families Enforcer', category: 'gang' },
    { model: 'g_m_y_salvaboss_01', label: 'Vagos / Marabunta Boss', category: 'gang' },
    { model: 'g_m_y_salvagoon_01', label: 'Vagos Street Soldier', category: 'gang' },
    { model: 'g_m_y_mexgoon_01', label: 'Cartel Hitman', category: 'gang' },
    { model: 'g_m_y_lost_01', label: 'The Lost MC Biker', category: 'gang' },
    { model: 'g_m_y_lost_02', label: 'The Lost MC Road Captain', category: 'gang' },
    { model: 'g_m_y_korean_01', label: 'Triad / Korean Mobster', category: 'gang' },
    { model: 'g_m_y_strpunk_01', label: 'Street Punk Rebel', category: 'gang' },
    { model: 'g_m_m_armboss_01', label: 'Armenian Mob Boss', category: 'gang' },

    // Civilians & Business
    { model: 'a_m_m_business_01', label: 'Wall Street Executive', category: 'civilian' },
    { model: 'a_f_m_business_02', label: 'Corporate Woman', category: 'civilian' },
    { model: 'a_m_y_business_01', label: 'Young Businessman', category: 'civilian' },
    { model: 'a_m_y_hipster_01', label: 'Downtown Hipster', category: 'civilian' },
    { model: 'a_m_y_skater_01', label: 'Venice Beach Skater', category: 'civilian' },
    { model: 's_m_y_autopep_01', label: 'Mechanic / Tuner', category: 'civilian' },
    { model: 's_m_m_bouncer_01', label: 'Nightclub Bouncer', category: 'civilian' },
    { model: 's_m_y_bartender_01', label: 'Bar Lounge Tender', category: 'civilian' },
    { model: 's_m_y_chef_01', label: 'Restaurant Chef', category: 'civilian' },
    { model: 's_m_y_construct_01', label: 'Construction Worker', category: 'civilian' },
    { model: 's_m_m_postal_01', label: 'PostOP Delivery Driver', category: 'civilian' },
    { model: 's_m_m_trucker_01', label: 'Highway Trucker', category: 'civilian' },

    // Animals & Pets
    { model: 'a_c_chop', label: 'Chop (Rottweiler)', category: 'animal' },
    { model: 'a_c_husky', label: 'Husky Dog', category: 'animal' },
    { model: 'a_c_retriever', label: 'Golden Retriever', category: 'animal' },
    { model: 'a_c_poodle', label: 'White Poodle', category: 'animal' },
    { model: 'a_c_pug', label: 'Pug Dog', category: 'animal' },
    { model: 'a_c_cat_01', label: 'House Cat', category: 'animal' },
    { model: 'a_c_chimp', label: 'Chimpanzee', category: 'animal' },
    { model: 'a_c_coyote', label: 'Wild Coyote', category: 'animal' },
    { model: 'a_c_deer', label: 'Forest Deer', category: 'animal' },
    { model: 'a_c_mountainlion', label: 'Mountain Cougar', category: 'animal' },

    // Multiplayer Characters
    { model: 'mp_m_freemode_01', label: 'Male MP Custom Character', category: 'multiplayer' },
    { model: 'mp_f_freemode_01', label: 'Female MP Custom Character', category: 'multiplayer' },
];

// Curated Fallback Jobs Catalog
const FALLBACK_JOBS = [
    { name: 'police', label: 'Chicago Police Department', category: 'emergency', type: 'leo', grades: [
        { grade: 0, name: 'Cadet', payment: 50 },
        { grade: 1, name: 'Officer', payment: 100 },
        { grade: 2, name: 'Sergeant', payment: 150 },
        { grade: 3, name: 'Lieutenant', payment: 200 },
        { grade: 4, name: 'Chief of Police', payment: 300, isBoss: true }
    ]},
    { name: 'ambulance', label: 'EMS Medical Services', category: 'emergency', type: 'ems', grades: [
        { grade: 0, name: 'Intern', payment: 45 },
        { grade: 1, name: 'Paramedic', payment: 95 },
        { grade: 2, name: 'Doctor', payment: 160 },
        { grade: 3, name: 'Hospital Director', payment: 280, isBoss: true }
    ]},
    { name: 'mechanic', label: 'Customs & Tuning Shop', category: 'business', type: 'mechanic', grades: [
        { grade: 0, name: 'Apprentice', payment: 40 },
        { grade: 1, name: 'Mechanic', payment: 85 },
        { grade: 2, name: 'Lead Tuner', payment: 140 },
        { grade: 3, name: 'Shop Owner', payment: 250, isBoss: true }
    ]},
    { name: 'cardealer', label: 'Luxury Motors Dealership', category: 'business', type: 'dealer', grades: [
        { grade: 0, name: 'Trainee', payment: 40 },
        { grade: 1, name: 'Salesman', payment: 90 },
        { grade: 2, name: 'General Manager', payment: 220, isBoss: true }
    ]},
    { name: 'realestate', label: 'Dynasty8 Real Estate', category: 'business', type: 'realestate', grades: [
        { grade: 0, name: 'Agent', payment: 50 },
        { grade: 1, name: 'Broker', payment: 120 },
        { grade: 2, name: 'CEO', payment: 250, isBoss: true }
    ]},
    { name: 'taxi', label: 'Downtown Cab Co.', category: 'public', type: 'taxi', grades: [
        { grade: 0, name: 'Driver', payment: 50 },
        { grade: 1, name: 'Fleet Manager', payment: 120, isBoss: true }
    ]},
    { name: 'lawyer', label: 'Department of Justice', category: 'emergency', type: 'legal', grades: [
        { grade: 0, name: 'Paralegal', payment: 60 },
        { grade: 1, name: 'Attorney', payment: 150 },
        { grade: 2, name: 'District Judge', payment: 320, isBoss: true }
    ]},
    { name: 'reporter', label: 'Weazel News Media', category: 'public', type: 'news', grades: [
        { grade: 0, name: 'Camera Operator', payment: 45 },
        { grade: 1, name: 'Investigative Journalist', payment: 110 },
        { grade: 2, name: 'News Anchor / Editor', payment: 220, isBoss: true }
    ]},
    { name: 'garbage', label: 'Sanitation Waste Dept', category: 'public', type: 'sanitation', grades: [
        { grade: 0, name: 'Sanitation Worker', payment: 60 },
        { grade: 1, name: 'Route Supervisor', payment: 130, isBoss: true }
    ]},
    { name: 'tow', label: 'Impound & Tow Services', category: 'public', type: 'tow', grades: [
        { grade: 0, name: 'Tow Operator', payment: 55 },
        { grade: 1, name: 'Impound Director', payment: 140, isBoss: true }
    ]},
    { name: 'ballas', label: 'Ballas Street Syndicate', category: 'gang', type: 'gang', grades: [
        { grade: 0, name: 'Runner', payment: 0 },
        { grade: 1, name: 'Shooter', payment: 0 },
        { grade: 2, name: 'OG / Leader', payment: 0, isBoss: true }
    ]},
    { name: 'vagos', label: 'Los Santos Vagos Cartel', category: 'gang', type: 'gang', grades: [
        { grade: 0, name: 'Soldado', payment: 0 },
        { grade: 1, name: 'Sicario', payment: 0 },
        { grade: 2, name: 'El Patron', payment: 0, isBoss: true }
    ]},
    { name: 'families', label: 'Grove Street Families', category: 'gang', type: 'gang', grades: [
        { grade: 0, name: 'Baby Gangster', payment: 0 },
        { grade: 1, name: 'Enforcer', payment: 0 },
        { grade: 2, name: 'Top Dog', payment: 0, isBoss: true }
    ]},
    { name: 'unemployed', label: 'Unemployed Civilian', category: 'public', type: 'none', grades: [
        { grade: 0, name: 'Freelancer', payment: 10 }
    ]}
];

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
            postNUI('fetchAllJobs');
            renderVisualItems();
            renderVisualVehicles();
            renderVisualCharacters();
            renderVisualJobs();
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
    } else if (data.action === 'updateAllJobs') {
        if (data.jobs && Array.isArray(data.jobs) && data.jobs.length > 0) {
            allServerJobs = data.jobs;
            const query = document.getElementById('job-search-input')?.value.toLowerCase().trim() || '';
            renderVisualJobs(query);
        }
    } else if (data.action === 'updateCoordsDisplay') {
        const el = document.getElementById('current-coords-display');
        if (el && data.text) el.innerText = data.text;
    } else if (data.action === 'syncToggles') {
        if (data.toggles) {
            syncToggles(data.toggles);
        }
    } else if (data.action === 'showPlayerDetails') {
        const d = data.details;
        const content = document.getElementById('info-modal-content');
        if (content && d) {
            content.innerHTML = `
                <div class="player-info-card">
                    <div class="info-grid">
                        <div class="info-row"><span class="info-k">Server ID:</span><span class="info-v highlight">#${d.id}</span></div>
                        <div class="info-row"><span class="info-k">Player Name:</span><span class="info-v">${escapeHtml(d.name)}</span></div>
                        <div class="info-row"><span class="info-k">Citizen ID:</span><span class="info-v font-mono">${escapeHtml(d.citizenid)}</span></div>
                        <div class="info-row"><span class="info-k">Cash Money:</span><span class="info-v text-green">$${Number(d.cash).toLocaleString()}</span></div>
                        <div class="info-row"><span class="info-k">Bank Balance:</span><span class="info-v text-green">$${Number(d.bank).toLocaleString()}</span></div>
                        <div class="info-row"><span class="info-k">Job / Grade:</span><span class="info-v">${escapeHtml(d.job)} (${escapeHtml(d.jobGrade)})</span></div>
                        <div class="info-row"><span class="info-k">Gang / Grade:</span><span class="info-v">${escapeHtml(d.gang)} (${escapeHtml(d.gangGrade)})</span></div>
                        <div class="info-row"><span class="info-k">Phone Number:</span><span class="info-v font-mono">${escapeHtml(d.phone)}</span></div>
                        <div class="info-row"><span class="info-k">Ping / IP:</span><span class="info-v">${d.ping}ms (${d.ip})</span></div>
                        <div class="info-row" style="grid-column: 1 / -1;"><span class="info-k">Rockstar License:</span><span class="info-v font-mono text-muted" style="word-break: break-all;">${escapeHtml(d.license)}</span></div>
                        <div class="info-row" style="grid-column: 1 / -1;"><span class="info-k">Discord ID:</span><span class="info-v font-mono text-muted">${escapeHtml(d.discord)}</span></div>
                    </div>
                </div>
            `;
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
        } else if (tab === 'characters') {
            const query = document.getElementById('ped-search-input')?.value.toLowerCase().trim() || '';
            renderVisualCharacters(query);
        } else if (tab === 'jobs') {
            const query = document.getElementById('job-search-input')?.value.toLowerCase().trim() || '';
            renderVisualJobs(query);
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

// Extended Owner Toggles
const registerExtendedToggle = (id, power) => {
    document.getElementById(id)?.addEventListener('change', (e) => {
        postNUI('toggleExtendedPower', { power, state: e.target.checked });
    });
};

registerExtendedToggle('toggle-admintag', 'admintag');
registerExtendedToggle('toggle-names', 'names');
registerExtendedToggle('toggle-blips', 'blips');
registerExtendedToggle('toggle-minimap', 'minimap');
registerExtendedToggle('toggle-coordshud', 'coordshud');
registerExtendedToggle('toggle-noclip2', 'noclip2');
registerExtendedToggle('toggle-infammo', 'infammo');

// Quick Master Action Helpers
const bindClientAction = (id, action) => {
    document.getElementById(id)?.addEventListener('click', () => {
        postNUI('clientAction', { action });
    });
};

bindClientAction('btn-clothes-menu', 'clothes');
bindClientAction('btn-bennys-tune', 'bennys');
bindClientAction('btn-refuel-tank', 'refuel');
bindClientAction('btn-toggle-duty', 'duty');
bindClientAction('btn-remove-stress', 'stress');
bindClientAction('btn-revive-radius', 'revive_radius');
bindClientAction('btn-revive-all', 'revive_all');
bindClientAction('btn-clear-veh', 'clear_veh');
bindClientAction('btn-clear-peds', 'clear_peds');
bindClientAction('btn-clear-props', 'clear_props');
bindClientAction('btn-veh-lock', 'veh_lock');
bindClientAction('btn-veh-unlock', 'veh_unlock');
bindClientAction('btn-veh-engine', 'veh_engine');
bindClientAction('btn-veh-freeze', 'veh_freeze');

// Prop Spawner
document.getElementById('btn-spawn-prop-object')?.addEventListener('click', () => {
    const prop = document.getElementById('prop-model-input')?.value.trim();
    if (prop) postNUI('clientAction', { action: 'spawn_prop', prop });
});

// Custom Click / Command Runner
document.getElementById('btn-exec-custom-click')?.addEventListener('click', () => {
    const cmd = document.getElementById('custom-click-input')?.value.trim();
    if (cmd) postNUI('quickAction', { action: cmd });
});

// Custom Job & Gang Stash Builder
document.getElementById('btn-create-custom-stash')?.addEventListener('click', () => {
    const stashId = document.getElementById('stash-id-input')?.value.trim();
    const label = document.getElementById('stash-label-input')?.value.trim() || 'Custom Stash';
    if (stashId) postNUI('playerDetailedAction', { action: 'create_stash', stashId, label });
});

// Offline Ban & Unban Handlers
document.getElementById('btn-ban-offline')?.addEventListener('click', () => {
    const identifier = document.getElementById('offline-ban-id')?.value.trim();
    const reason = document.getElementById('offline-ban-reason')?.value.trim() || 'Offline ban by Administrator';
    if (identifier) postNUI('playerDetailedAction', { action: 'ban_offline', identifier, reason });
});

document.getElementById('btn-unban-player')?.addEventListener('click', () => {
    const query = document.getElementById('unban-id-input')?.value.trim();
    if (query) postNUI('playerDetailedAction', { action: 'unban', identifier: query });
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

// Characters & Skins Rendering (Visual Peds Catalog)
function renderVisualCharacters(searchQuery = '') {
    const container = document.getElementById('visual-characters-container');
    if (!container) return;

    const filtered = VISUAL_PEDS.filter(ped => {
        const matchesCategory = (currentPedFilter === 'all' || ped.category === currentPedFilter);
        const q = searchQuery.toLowerCase().trim();
        const matchesSearch = !q || 
            ped.model.toLowerCase().includes(q) || 
            ped.label.toLowerCase().includes(q);
        return matchesCategory && matchesSearch;
    });

    if (filtered.length === 0) {
        container.innerHTML = '<div class="table-empty" style="grid-column: 1 / -1;">No matching characters found.</div>';
        return;
    }

    container.innerHTML = filtered.map(ped => {
        const model = ped.model.toLowerCase();
        const label = ped.label || model;
        const imgFiveM = `https://docs.fivem.net/peds/${model}.webp`;
        const imgFallback = `https://raw.githubusercontent.com/root-cause/v-ped-hashes/master/images/${model}.png`;
        const isAnimal = ped.category === 'animal';

        return `
            <div class="visual-ped-card">
                <div class="ped-thumb-wrapper">
                    <img class="ped-thumb" src="${imgFiveM}" onerror="this.onerror=null; this.src='${imgFallback}'; this.onerror=function(){ this.parentElement.innerHTML='<span style=\\'font-size:32px;opacity:0.7;\\'>${isAnimal ? '🐾' : '👤'}</span>'; };">
                </div>
                <div class="ped-title" title="${escapeHtml(label)}">${escapeHtml(label)}</div>
                <div class="ped-model-sub">${model}</div>
                <button class="ped-apply-btn" onclick="applyPedDirect('${model}')">Apply Skin</button>
            </div>
        `;
    }).join('');
}

window.applyPedDirect = function(model) {
    postNUI('setPedModel', { model });
};

document.querySelectorAll('.filter-chip-ped').forEach(chip => {
    chip.addEventListener('click', () => {
        document.querySelectorAll('.filter-chip-ped').forEach(c => c.classList.remove('active'));
        chip.classList.add('active');
        currentPedFilter = chip.getAttribute('data-cat');
        const query = document.getElementById('ped-search-input')?.value.toLowerCase().trim() || '';
        renderVisualCharacters(query);
    });
});

document.getElementById('ped-search-input')?.addEventListener('input', (e) => {
    renderVisualCharacters(e.target.value.toLowerCase().trim());
});

document.getElementById('btn-reset-ped')?.addEventListener('click', () => {
    applyPedDirect('mp_m_freemode_01');
});

document.getElementById('btn-apply-custom-skin')?.addEventListener('click', () => {
    const input = document.getElementById('custom-skin-input');
    const model = input?.value.trim();
    if (model) {
        applyPedDirect(model);
        input.value = '';
    }
});

// Jobs & Careers Rendering (Dynamic Qbox Jobs Catalog)
function renderVisualJobs(searchQuery = '') {
    const container = document.getElementById('visual-jobs-container');
    if (!container) return;

    const sourceList = (allServerJobs && allServerJobs.length > 0) ? allServerJobs : FALLBACK_JOBS;

    const filtered = sourceList.filter(job => {
        const cat = (job.category || 'public').toLowerCase();
        let matchesCategory = false;
        if (currentJobFilter === 'all') {
            matchesCategory = true;
        } else if (currentJobFilter === 'emergency') {
            matchesCategory = cat === 'emergency';
        } else if (currentJobFilter === 'public') {
            matchesCategory = cat === 'public';
        } else if (currentJobFilter === 'business') {
            matchesCategory = cat === 'business';
        } else if (currentJobFilter === 'gang') {
            matchesCategory = cat === 'gang';
        }

        const q = searchQuery.toLowerCase().trim();
        const matchesSearch = !q || 
            job.name.toLowerCase().includes(q) || 
            (job.label && job.label.toLowerCase().includes(q));

        return matchesCategory && matchesSearch;
    });

    if (filtered.length === 0) {
        container.innerHTML = '<div class="table-empty" style="grid-column: 1 / -1;">No matching jobs found.</div>';
        return;
    }

    container.innerHTML = filtered.map(job => {
        const jName = job.name.toLowerCase();
        const jTitle = job.label || jName;
        const selectId = `grade-sel-${jName.replace(/[^a-zA-Z0-9]/g, '_')}`;

        let icon = '💼';
        if (job.category === 'emergency' || jName.includes('police') || jName.includes('sheriff')) icon = '👮';
        else if (jName.includes('ambulance') || jName.includes('ems') || jName.includes('doctor')) icon = '🚑';
        else if (jName.includes('mechanic') || jName.includes('tuner')) icon = '🔧';
        else if (jName.includes('taxi')) icon = '🚕';
        else if (jName.includes('lawyer') || jName.includes('judge')) icon = '⚖️';
        else if (jName.includes('cardealer')) icon = '🏎️';
        else if (jName.includes('realestate')) icon = '🏢';
        else if (job.category === 'gang') icon = '🔫';

        const grades = (job.grades && job.grades.length > 0) ? job.grades : [{ grade: 0, name: 'Employee', payment: 0 }];
        const gradeOptions = grades.map(g => {
            const bossTag = g.isBoss ? ' ★ BOSS' : '';
            const salaryTag = g.payment ? ` ($${g.payment})` : '';
            return `<option value="${g.grade}">${g.grade}: ${escapeHtml(g.name)}${salaryTag}${bossTag}</option>`;
        }).join('');

        return `
            <div class="visual-job-card">
                <div class="job-card-header">
                    <div class="job-badge-icon">${icon}</div>
                    <div class="job-card-info">
                        <div class="job-title" title="${escapeHtml(jTitle)}">${escapeHtml(jTitle)}</div>
                        <div class="job-name-tag">${jName}</div>
                    </div>
                </div>
                <div class="form-group" style="margin: 0;">
                    <select id="${selectId}" class="job-grades-select">
                        ${gradeOptions}
                    </select>
                </div>
                <button class="job-apply-btn" onclick="setMyJobDirect('${jName}', '${selectId}')">Set My Job</button>
            </div>
        `;
    }).join('');
}

window.setMyJobDirect = function(jobName, selectId) {
    const sel = document.getElementById(selectId);
    const grade = parseInt(sel?.value) || 0;
    postNUI('setMyJob', { job: jobName, grade });
};

document.querySelectorAll('.filter-chip-job').forEach(chip => {
    chip.addEventListener('click', () => {
        document.querySelectorAll('.filter-chip-job').forEach(c => c.classList.remove('active'));
        chip.classList.add('active');
        currentJobFilter = chip.getAttribute('data-cat');
        const query = document.getElementById('job-search-input')?.value.toLowerCase().trim() || '';
        renderVisualJobs(query);
    });
});

document.getElementById('job-search-input')?.addEventListener('input', (e) => {
    renderVisualJobs(e.target.value.toLowerCase().trim());
});

// Owner Arsenal & Economy
window.equipArsenalDirect = function(loadout) {
    postNUI('equipLoadout', { loadout });
};

document.getElementById('btn-give-quick-cash')?.addEventListener('click', () => {
    const amt = parseInt(document.getElementById('quick-cash-amount')?.value) || 100000;
    postNUI('giveMoney', { amount: amt, moneyType: 'cash' });
});

document.getElementById('btn-give-quick-bank')?.addEventListener('click', () => {
    const amt = parseInt(document.getElementById('quick-cash-amount')?.value) || 100000;
    postNUI('giveMoney', { amount: amt, moneyType: 'bank' });
});

// Traffic & NPC Population Density
document.querySelectorAll('.density-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        document.querySelectorAll('.density-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        const density = parseFloat(btn.getAttribute('data-density'));
        postNUI('setTrafficDensity', { density });
    });
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
                    <button class="p-btn" style="background: var(--accent-cyan); color: #000; font-weight: 700; padding: 4px 10px;" onclick="openPlayerManageModal(${p.id}, '${escapeHtml(p.name)}')">⚡ Manage</button>
                    <button class="p-btn goto" onclick="playerAction('goto', ${p.id})">Goto</button>
                    <button class="p-btn bring" onclick="playerAction('bring', ${p.id})">Bring</button>
                    <button class="p-btn freeze" onclick="playerAction('freeze', ${p.id})">Freeze</button>
                    <button class="p-btn spectate" onclick="playerAction('spectate', ${p.id})">Spectate</button>
                    <button class="p-btn info" style="background: rgba(255,255,255,0.08); padding: 4px 8px;" onclick="openPlayerInfoModal(${p.id})">ℹ️ Info</button>
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

// Master Player Manage Modal
window.openPlayerManageModal = function(targetId, name) {
    const modal = document.getElementById('player-manage-modal');
    document.getElementById('manage-target-id').value = targetId;
    document.getElementById('manage-target-name').value = name;
    document.getElementById('manage-target-info').innerText = `TARGET: [#${targetId}] ${name}`;
    modal.style.display = 'flex';
};

document.getElementById('manage-modal-close')?.addEventListener('click', () => {
    document.getElementById('player-manage-modal').style.display = 'none';
});
document.getElementById('manage-modal-close-btn')?.addEventListener('click', () => {
    document.getElementById('player-manage-modal').style.display = 'none';
});

window.execPlayerDetailed = function(action, extra = {}) {
    const targetId = document.getElementById('manage-target-id').value;
    const name = document.getElementById('manage-target-name').value;
    const payload = { action, targetId, ...extra };

    if (action === 'set_gang') {
        payload.gang = document.getElementById('manage-gang-name')?.value.trim() || 'none';
        payload.grade = document.getElementById('manage-gang-grade')?.value.trim() || 0;
    } else if (action === 'message') {
        payload.message = document.getElementById('manage-pm-msg')?.value.trim();
        if (!payload.message) return;
    } else if (action === 'warn') {
        payload.reason = document.getElementById('manage-warn-msg')?.value.trim() || 'Official staff warning';
    } else if (action === 'wipe') {
        if (!confirm(`Are you SURE you want to execute ${extra.wipeType.toUpperCase()} wipe on [#${targetId}] ${name}? This cannot be undone!`)) {
            return;
        }
    } else if (action === 'clear_inv') {
        if (!confirm(`Are you sure you want to completely clear inventory of [#${targetId}] ${name}?`)) {
            return;
        }
    }

    postNUI('playerDetailedAction', payload);
};

// Player Info Modal
window.openPlayerInfoModal = function(targetId) {
    const modal = document.getElementById('player-info-modal');
    const content = document.getElementById('info-modal-content');
    content.innerHTML = '<div class="table-empty">Retrieving player records...</div>';
    modal.style.display = 'flex';

    postNUI('playerDetailedAction', { action: 'get_details', targetId });
};

document.getElementById('info-modal-close')?.addEventListener('click', () => {
    document.getElementById('player-info-modal').style.display = 'none';
});
document.getElementById('info-modal-close-btn')?.addEventListener('click', () => {
    document.getElementById('player-info-modal').style.display = 'none';
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
