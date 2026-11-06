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
let allServerCharacters = [];
let currentPedLimit = 120;
let currentVehLimit = 120;
let currentItemLimit = 120;

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
            postNUI('fetchAllCharacters');
            postNUI('fetchAllJobs');
            renderVisualItems();
            renderVisualVehicles();
            renderVisualCharacters();
            renderVisualJobs();
        } else {
            app.style.display = 'none';
        }
    } else if (data.action === 'updateStatus' || data.action === 'updatePermissions') {
        updateSecurityStatus(data.status);
    } else if (data.action === 'updateLogs') {
        renderAuditLogs(data.logs);
    } else if (data.action === 'updatePlayers') {
        renderPlayers(data.players);
    } else if (data.action === 'updateAllItems') {
        if (data.items && Array.isArray(data.items) && data.items.length > 0) {
            allServerItems = data.items;
            const badge = document.getElementById('total-items-badge');
            if (badge) badge.innerText = `${allServerItems.length} ITEMS`;
            const query = document.getElementById('item-search-input')?.value.toLowerCase().trim() || '';
            renderVisualItems(query);
        }
    } else if (data.action === 'updateAllVehicles') {
        if (data.vehicles && Array.isArray(data.vehicles) && data.vehicles.length > 0) {
            allServerVehicles = data.vehicles;
            const badge = document.getElementById('total-vehs-badge');
            if (badge) badge.innerText = `${allServerVehicles.length} CARS`;
            const query = document.getElementById('veh-search-input')?.value.toLowerCase().trim() || '';
            renderVisualVehicles(query);
        }
    } else if (data.action === 'updateAllCharacters') {
        if (data.characters && Array.isArray(data.characters) && data.characters.length > 0) {
            allServerCharacters = data.characters;
            const badge = document.getElementById('total-chars-badge');
            if (badge) badge.innerText = `${allServerCharacters.length} PEDS`;
            const query = document.getElementById('ped-search-input')?.value.toLowerCase().trim() || '';
            renderVisualCharacters(query);
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
            const vehCount = (d.vehicles || []).length;
            const propCount = (d.properties || []).length;
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
                        <div class="info-row"><span class="info-k">Véhicules Garage:</span><span class="info-v highlight">${vehCount} possédé(s)</span></div>
                        <div class="info-row"><span class="info-k">Propriétés / Maisons:</span><span class="info-v highlight">${propCount} possédée(s)</span></div>
                        <div class="info-row" style="grid-column: 1 / -1;"><span class="info-k">Rockstar License:</span><span class="info-v font-mono text-muted" style="word-break: break-all;">${escapeHtml(d.license)}</span></div>
                        <div class="info-row" style="grid-column: 1 / -1;"><span class="info-k">Discord ID:</span><span class="info-v font-mono text-muted">${escapeHtml(d.discord)}</span></div>
                    </div>
                </div>
            `;
        }
        // Update live stats in player-manage-modal if target matches
        const currManageId = document.getElementById('manage-target-id')?.value;
        if (d && currManageId == d.id) {
            const cashEl = document.getElementById('manage-live-cash');
            const bankEl = document.getElementById('manage-live-bank');
            const jobEl = document.getElementById('manage-live-job');
            const gangEl = document.getElementById('manage-live-gang');
            const cidEl = document.getElementById('manage-target-cid-display');
            if (cashEl) cashEl.innerText = `$${Number(d.cash).toLocaleString()}`;
            if (bankEl) bankEl.innerText = `$${Number(d.bank).toLocaleString()}`;
            if (jobEl) jobEl.innerText = `${d.job} (${d.jobGrade})`;
            if (gangEl) gangEl.innerText = `${d.gang} (${d.gangGrade})`;
            if (cidEl) cidEl.innerText = `CID: ${d.citizenid} • Ping: ${d.ping}ms • IP: ${d.ip}`;
            // Render Vehicles & Properties
            renderPlayerAssets(d);
        }
    } else if (data.action === 'updateTargetLiveMoney') {
        const cashEl = document.getElementById('manage-live-cash');
        const bankEl = document.getElementById('manage-live-bank');
        if (cashEl && data.cash !== undefined) cashEl.innerText = `$${Number(data.cash).toLocaleString()}`;
        if (bankEl && data.bank !== undefined) bankEl.innerText = `$${Number(data.bank).toLocaleString()}`;
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
    setCheck('toggle-antiragdoll', t.antiragdoll);
    setCheck('toggle-infoxygen', t.infoxygen);
    setCheck('toggle-infstamina', t.infstamina);
    setCheck('toggle-exppunch', t.exppunch);
    setCheck('toggle-expammo', t.expammo);
    setCheck('toggle-vehjump', t.vehjump);
    setCheck('toggle-vehdrift', t.vehdrift);
    setCheck('toggle-autoflip', t.autoflip);
    setCheck('toggle-fastswim', t.fastswim);
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

    // Dynamic Role-Based / Granular Permissions Tab Filtering ("nkhtar chkon user les iban lih ou nkhtar bach i9dr ikhdm")
    const perms = status.permissions || {};
    let activeTabVisible = false;

    document.querySelectorAll('.nav-item').forEach(btn => {
        const tab = btn.getAttribute('data-tab');
        if (!tab) return;
        if (tab === 'dashboard') {
            btn.style.display = '';
            if (currentTab === 'dashboard') activeTabVisible = true;
            return;
        }

        if (status.isOwner) {
            btn.style.display = '';
            if (currentTab === tab) activeTabVisible = true;
            return;
        }

        // Check if user has permission for this module
        const hasPerm = perms[tab] === true;
        btn.style.display = hasPerm ? '' : 'none';
        if (currentTab === tab && hasPerm) {
            activeTabVisible = true;
        }
    });

    // If current active tab was hidden due to lack of permission, fallback to dashboard
    if (!activeTabVisible) {
        const dashBtn = document.querySelector('.nav-item[data-tab="dashboard"]');
        if (dashBtn) dashBtn.click();
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
            if (!allServerVehicles || allServerVehicles.length === 0) postNUI('fetchAllVehicles');
            const query = document.getElementById('veh-search-input')?.value.toLowerCase().trim() || '';
            renderVisualVehicles(query);
        } else if (tab === 'characters') {
            if (!allServerCharacters || allServerCharacters.length === 0) postNUI('fetchAllCharacters');
            const query = document.getElementById('ped-search-input')?.value.toLowerCase().trim() || '';
            renderVisualCharacters(query);
        } else if (tab === 'jobs') {
            const query = document.getElementById('job-search-input')?.value.toLowerCase().trim() || '';
            renderVisualJobs(query);
        } else if (tab === 'devtools') {
            postNUI('requestCoordsDisplay');
        } else if (tab === 'events') {
            checkEventState();
        } else if (tab === 'staff') {
            fetchStaffData();
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
    const staffModal = document.getElementById('staff-modal');
    if (staffModal) staffModal.style.display = 'none';
    const pedModal = document.getElementById('ped-picker-modal');
    if (pedModal) pedModal.style.display = 'none';
    const vehModal = document.getElementById('veh-picker-modal');
    if (vehModal) vehModal.style.display = 'none';
    const manageModal = document.getElementById('player-manage-modal');
    if (manageModal) manageModal.style.display = 'none';
    postNUI('close');
}

document.getElementById('close-btn')?.addEventListener('click', (e) => {
    e.preventDefault();
    e.stopPropagation();
    closePanel();
});

window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        const pedModal = document.getElementById('ped-picker-modal');
        const vehModal = document.getElementById('veh-picker-modal');
        const modal = document.getElementById('ban-modal');
        const jobModal = document.getElementById('job-modal');
        const staffModal = document.getElementById('staff-modal');
        const manageModal = document.getElementById('player-manage-modal');

        if (pedModal && pedModal.style.display !== 'none') {
            pedModal.style.display = 'none';
        } else if (vehModal && vehModal.style.display !== 'none') {
            vehModal.style.display = 'none';
        } else if (modal && modal.style.display !== 'none') {
            modal.style.display = 'none';
        } else if (jobModal && jobModal.style.display !== 'none') {
            jobModal.style.display = 'none';
        } else if (staffModal && staffModal.style.display !== 'none') {
            staffModal.style.display = 'none';
        } else if (manageModal && manageModal.style.display !== 'none') {
            manageModal.style.display = 'none';
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
registerToggle('toggle-antiragdoll', 'antiragdoll');
registerToggle('toggle-infoxygen', 'infoxygen');
registerToggle('toggle-infstamina', 'infstamina');
registerToggle('toggle-exppunch', 'exppunch');
registerToggle('toggle-expammo', 'expammo');
registerToggle('toggle-vehjump', 'vehjump');
registerToggle('toggle-vehdrift', 'vehdrift');
registerToggle('toggle-autoflip', 'autoflip');
registerToggle('toggle-fastswim', 'fastswim');

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
bindClientAction('btn-clean-ped', 'clean_ped');
bindClientAction('btn-flip-car', 'flip_car');
bindClientAction('btn-fix-wash-car', 'fix_wash_car');
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

// =========================================================================
// FAVORITES SYSTEM (Persistent in LocalStorage)
// =========================================================================
const Favorites = {
    _data: {
        vehicles: new Set(JSON.parse(localStorage.getItem('sdev_fav_vehicles') || '[]')),
        characters: new Set(JSON.parse(localStorage.getItem('sdev_fav_characters') || '[]')),
        items: new Set(JSON.parse(localStorage.getItem('sdev_fav_items') || '[]')),
    },
    has(type, id) {
        if (!id) return false;
        return this._data[type]?.has(id.toLowerCase()) ?? false;
    },
    toggle(type, id) {
        const set = this._data[type];
        if (!set || !id) return false;
        const key = id.toLowerCase();
        let added = false;
        if (set.has(key)) {
            set.delete(key);
            added = false;
        } else {
            set.add(key);
            added = true;
        }
        localStorage.setItem(`sdev_fav_${type}`, JSON.stringify(Array.from(set)));
        return added;
    }
};

window.toggleFavorite = function(type, id) {
    Favorites.toggle(type, id);
    if (type === 'vehicles') {
        const q = document.getElementById('veh-search-input')?.value || '';
        renderVisualVehicles(q);
    } else if (type === 'characters') {
        const q = document.getElementById('ped-search-input')?.value || '';
        renderVisualCharacters(q);
    } else if (type === 'items') {
        const q = document.getElementById('item-search-input')?.value || '';
        renderVisualItems(q);
    }
};

// Visual Items Rendering & Categories (Dynamic ox_inventory Catalog)
function renderVisualItems(searchQuery = '') {
    const container = document.getElementById('visual-items-container');
    if (!container) return;

    const sourceList = (allServerItems && allServerItems.length > 0) ? allServerItems : VISUAL_ITEMS;
    const q = searchQuery.toLowerCase().trim();
    const isSearching = q.length > 0;

    const filtered = sourceList.filter(item => {
        const itemName = item.name.toLowerCase();
        const itemLabel = (item.label || item.name).toLowerCase();
        const cat = (item.category || 'tool').toLowerCase();

        // 1. Instant 1st letter match check
        const matchesSearch = !isSearching || itemName.includes(q) || itemLabel.includes(q);
        if (!matchesSearch) return false;

        // 2. Favorites category check
        if (currentItemFilter === 'favorites') {
            return Favorites.has('items', itemName);
        }

        // When actively searching, search across all categories automatically
        if (isSearching) return true;

        if (currentItemFilter === 'all') return true;
        if (currentItemFilter === 'weapon') return cat === 'weapon' || itemName.startsWith('weapon_');
        if (currentItemFilter === 'ammo') return cat === 'ammo' || itemName.includes('ammo');
        if (currentItemFilter === 'food') return cat === 'food';
        if (currentItemFilter === 'medical') return cat === 'medical';
        if (currentItemFilter === 'tool') return cat === 'tool' || (!cat.includes('weapon') && !cat.includes('ammo') && !cat.includes('food') && !cat.includes('medical'));

        return true;
    });

    // Rank prefix matches at the top (Starts with `q` appears first)
    if (isSearching) {
        filtered.sort((a, b) => {
            const aName = a.name.toLowerCase();
            const bName = b.name.toLowerCase();
            const aLabel = (a.label || a.name).toLowerCase();
            const bLabel = (b.label || b.name).toLowerCase();

            const aStarts = aName.startsWith(q) || aLabel.startsWith(q);
            const bStarts = bName.startsWith(q) || bLabel.startsWith(q);

            if (aStarts && !bStarts) return -1;
            if (!aStarts && bStarts) return 1;
            return aName.localeCompare(bName);
        });
    }

    if (filtered.length === 0) {
        container.innerHTML = '<div class="table-empty" style="grid-column: 1 / -1;">No matching items found.</div>';
        return;
    }

    const renderChunk = filtered.slice(0, isSearching ? 250 : 150);

    container.innerHTML = renderChunk.map(item => {
        const itemName = item.name.toLowerCase();
        const itemLabel = item.label || item.name;
        const imgSrc = `https://cfx-nui-ox_inventory/web/images/${itemName}.png`;
        const fallbackSrc = `nui://ox_inventory/web/images/${itemName}.png`;
        const isFav = Favorites.has('items', itemName);

        return `
            <div class="visual-item-card ${isFav ? 'is-favorite' : ''}">
                <button class="fav-star-btn ${isFav ? 'active' : ''}" onclick="event.stopPropagation(); toggleFavorite('items', '${escapeHtml(itemName)}')" title="${isFav ? 'Retirer des favoris' : 'Ajouter aux favoris'}">
                    ${isFav ? '★' : '☆'}
                </button>
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
        const query = document.getElementById('item-search-input')?.value || '';
        renderVisualItems(query);
    });
});

['input', 'keyup'].forEach(evt => {
    document.getElementById('item-search-input')?.addEventListener(evt, (e) => {
        renderVisualItems(e.target.value);
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

// Vehicle & Character Image Handlers with Graceful Multi-Stage Fallback
window.handleVehImgError = function(img, model) {
    const stage = parseInt(img.getAttribute('data-stage') || '0', 10);
    if (stage === 0) {
        // Stage 1: Try local oxlyn-garage NUI
        img.setAttribute('data-stage', '1');
        img.src = `https://cfx-nui-oxlyn-garage/images/vehicles/${model}.webp`;
    } else if (stage === 1) {
        // Stage 2: Try docs.fivem.net CDN
        img.setAttribute('data-stage', '2');
        img.src = `https://docs.fivem.net/vehicles/${model}.webp`;
    } else {
        // Stage 3: Hide broken img, display clean placeholder box
        img.onerror = null;
        img.style.display = 'none';
        const parent = img.parentElement;
        if (parent) {
            const placeholder = parent.querySelector('.veh-placeholder-box');
            if (placeholder) placeholder.style.display = 'flex';
        }
    }
};

window.handlePedImgError = function(img, model) {
    const stage = parseInt(img.getAttribute('data-stage') || '0', 10);
    if (stage === 0) {
        img.setAttribute('data-stage', '1');
        img.src = `https://docs.fivem.net/peds/${model}.webp`;
    } else {
        img.onerror = null;
        img.style.display = 'none';
        const parent = img.parentElement;
        if (parent) {
            const placeholder = parent.querySelector('.ped-placeholder-box');
            if (placeholder) placeholder.style.display = 'flex';
        }
    }
};

window.spawnVehicleDirect = function(model) {
    if (!model) return;
    const maxTune = document.getElementById('veh-max-tune')?.checked ?? true;
    postNUI('spawnVehicle', { model, maxTune });
};

window.applyPedDirect = function(model) {
    if (!model) return;
    postNUI('setPedModel', { model });
};

// Visual Vehicles Rendering & Categories (Dynamic Qbox Vehicles Catalog)
function renderVisualVehicles(searchQuery = '') {
    const container = document.getElementById('visual-vehicles-container');
    if (!container) return;

    const sourceList = (allServerVehicles && allServerVehicles.length > 0) ? allServerVehicles : FALLBACK_VEHICLES;
    const q = searchQuery.toLowerCase().trim();
    const isSearching = q.length > 0;

    const filtered = sourceList.filter(veh => {
        const model = veh.model.toLowerCase();
        const name = (veh.name || '').toLowerCase();
        const brand = (veh.brand || '').toLowerCase();
        const cat = (veh.category || '').toLowerCase();

        // 1. Instant 1st letter search check
        const matchesSearch = !isSearching || 
            model.includes(q) || 
            name.includes(q) || 
            brand.includes(q) ||
            cat.includes(q);

        if (!matchesSearch) return false;

        // 2. Favorites category check
        if (currentVehFilter === 'favorites') {
            return Favorites.has('vehicles', model);
        }

        // When actively typing a search query, search across ALL categories automatically
        if (isSearching) {
            return true;
        }

        if (currentVehFilter === 'all') return true;
        if (currentVehFilter === 'super') return cat.includes('super');
        if (currentVehFilter === 'sports') return cat.includes('sport');
        if (currentVehFilter === 'muscle') return cat.includes('muscle');
        if (currentVehFilter === 'suvs') return cat.includes('suv');
        if (currentVehFilter === 'sedans') return cat.includes('sedan') || cat.includes('coupe') || cat.includes('compact');
        if (currentVehFilter === 'emergency') return cat.includes('emerg') || cat.includes('police') || cat.includes('fire') || cat.includes('medic');
        if (currentVehFilter === 'motorcycles') return cat.includes('motor') || cat.includes('bike') || cat.includes('cycle');
        if (currentVehFilter === 'offroad') return cat.includes('off') || cat.includes('road');
        if (currentVehFilter === 'vans') return cat.includes('van') || cat.includes('commercial') || cat.includes('industrial');
        if (currentVehFilter === 'air') return cat.includes('heli') || cat.includes('plane') || cat.includes('boat');

        return true;
    });

    // 3. Prefix Ranking: Models starting with `q` appear at the very top!
    if (isSearching) {
        filtered.sort((a, b) => {
            const aMod = a.model.toLowerCase();
            const bMod = b.model.toLowerCase();
            const aName = (a.name || '').toLowerCase();
            const bName = (b.name || '').toLowerCase();

            const aStarts = aMod.startsWith(q) || aName.startsWith(q);
            const bStarts = bMod.startsWith(q) || bName.startsWith(q);

            if (aStarts && !bStarts) return -1;
            if (!aStarts && bStarts) return 1;

            return aMod.localeCompare(bMod);
        });
    }

    if (filtered.length === 0) {
        container.innerHTML = '<div class="table-empty" style="grid-column: 1 / -1;">No matching vehicles found.</div>';
        return;
    }

    const limit = isSearching ? Math.max(currentVehLimit, 250) : currentVehLimit;
    const renderChunk = filtered.slice(0, limit);

    let html = renderChunk.map(veh => {
        const model = veh.model.toLowerCase();
        const name = veh.name || model;
        const brand = veh.brand || '';
        const cat = veh.category || 'Vehicle';
        const localImg = `images/vehicles/${model}.webp`;
        const isFav = Favorites.has('vehicles', model);

        return `
            <div class="visual-veh-card ${isFav ? 'is-favorite' : ''}" onclick="spawnVehicleDirect('${escapeHtml(model)}')">
                <button class="fav-star-btn ${isFav ? 'active' : ''}" onclick="event.stopPropagation(); toggleFavorite('vehicles', '${escapeHtml(model)}')" title="${isFav ? 'Retirer des favoris' : 'Ajouter aux favoris'}">
                    ${isFav ? '★' : '☆'}
                </button>
                <div class="veh-thumb-wrapper">
                    ${brand ? `<span class="veh-brand-tag">${escapeHtml(brand)}</span>` : ''}
                    <span class="veh-cat-tag">${escapeHtml(cat)}</span>
                    <img class="veh-thumb" src="${localImg}" loading="lazy" onerror="handleVehImgError(this, '${escapeHtml(model)}')" alt="${escapeHtml(name)}">
                    <div class="veh-placeholder-box" style="display: none;">
                        <svg viewBox="0 0 24 24" width="38" height="38" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">
                            <path d="M5 17h14M5 17a2 2 0 0 1-2-2V9a2 2 0 0 1 2-2h1.5l1.5-3h8l1.5 3H19a2 2 0 0 1 2 2v6a2 2 0 0 1-2 2M5 17l.5 2.5a1 1 0 0 0 1 .5h1a1 1 0 0 0 1-.8L9 17m10 0l-.5 2.5a1 1 0 0 1-1 .5h-1a1 1 0 0 1-1-.8L15 17"></path>
                            <circle cx="7.5" cy="12.5" r="1.5"></circle>
                            <circle cx="16.5" cy="12.5" r="1.5"></circle>
                        </svg>
                        <span class="veh-placeholder-label">CUSTOM ADDON</span>
                    </div>
                </div>
                <div class="veh-title" title="${escapeHtml(name)}">${escapeHtml(name)}</div>
                <div class="veh-model-sub">${model}</div>
                <button class="veh-spawn-btn" onclick="event.stopPropagation(); spawnVehicleDirect('${escapeHtml(model)}')">Spawn Driver</button>
            </div>
        `;
    }).join('');

    if (filtered.length > limit) {
        html += `<button class="load-more-btn" onclick="loadMoreVehicles()">➕ Afficher plus de véhicules (${limit} sur ${filtered.length})</button>`;
    }

    container.innerHTML = html;
}

window.loadMoreVehicles = function() {
    currentVehLimit += 120;
    const q = document.getElementById('veh-search-input')?.value || '';
    renderVisualVehicles(q);
};

document.querySelectorAll('.filter-chip-veh').forEach(chip => {
    chip.addEventListener('click', () => {
        document.querySelectorAll('.filter-chip-veh').forEach(c => c.classList.remove('active'));
        chip.classList.add('active');
        currentVehFilter = chip.getAttribute('data-cat');
        const query = document.getElementById('veh-search-input')?.value || '';
        renderVisualVehicles(query);
    });
});

['input', 'keyup'].forEach(evt => {
    document.getElementById('veh-search-input')?.addEventListener(evt, (e) => {
        renderVisualVehicles(e.target.value);
    });
});

// Characters & Skins Rendering (Dynamic illenium-appearance 1,051+ Peds Catalog)
function renderVisualCharacters(searchQuery = '') {
    const container = document.getElementById('visual-characters-container');
    if (!container) return;

    const sourceList = (allServerCharacters && allServerCharacters.length > 0) ? allServerCharacters : VISUAL_PEDS;
    const q = searchQuery.toLowerCase().trim();
    const isSearching = q.length > 0;

    const filtered = sourceList.filter(ped => {
        const model = ped.model.toLowerCase();
        const label = (ped.label || '').toLowerCase();
        const cat = (ped.category || '').toLowerCase();

        // 1. Instant 1st letter search check
        const matchesSearch = !isSearching || 
            model.includes(q) || 
            label.includes(q) ||
            cat.includes(q);

        if (!matchesSearch) return false;

        // 2. Favorites category check
        if (currentPedFilter === 'favorites') {
            return Favorites.has('characters', model);
        }

        // When actively typing a search query, search across ALL categories automatically
        if (isSearching) return true;

        if (currentPedFilter === 'all') return true;
        if (currentPedFilter === 'story' || currentPedFilter === 'vip') return cat === 'story' || cat === 'vip';
        if (currentPedFilter === 'emergency') return cat === 'emergency';
        if (currentPedFilter === 'gangs' || currentPedFilter === 'gang') return cat === 'gangs' || cat === 'gang';
        if (currentPedFilter === 'male' || currentPedFilter === 'civilian') return cat === 'male' || cat === 'civilian';
        if (currentPedFilter === 'female') return cat === 'female';
        if (currentPedFilter === 'animals' || currentPedFilter === 'animal') return cat === 'animals' || cat === 'animal';
        if (currentPedFilter === 'multiplayer') return cat === 'multiplayer';

        return true;
    });

    // 3. Prefix Ranking: Characters starting with `q` appear at the very top!
    if (isSearching) {
        filtered.sort((a, b) => {
            const aMod = a.model.toLowerCase();
            const bMod = b.model.toLowerCase();
            const aStarts = aMod.startsWith(q) || (a.label && a.label.toLowerCase().startsWith(q));
            const bStarts = bMod.startsWith(q) || (b.label && b.label.toLowerCase().startsWith(q));
            if (aStarts && !bStarts) return -1;
            if (!aStarts && bStarts) return 1;
            return aMod.localeCompare(bMod);
        });
    }

    if (filtered.length === 0) {
        container.innerHTML = '<div class="table-empty" style="grid-column: 1 / -1;">No matching characters found.</div>';
        return;
    }

    const limit = isSearching ? Math.max(currentPedLimit, 250) : currentPedLimit;
    const renderChunk = filtered.slice(0, limit);

    let html = renderChunk.map(ped => {
        const model = ped.model.toLowerCase();
        const label = ped.label || model;
        const imgFiveM = `https://docs.fivem.net/peds/${model}.webp`;
        const isAnimal = ped.category === 'animals' || ped.category === 'animal';
        const isFav = Favorites.has('characters', model);

        return `
            <div class="visual-ped-card ${isFav ? 'is-favorite' : ''}" onclick="applyPedDirect('${escapeHtml(model)}')">
                <button class="fav-star-btn ${isFav ? 'active' : ''}" onclick="event.stopPropagation(); toggleFavorite('characters', '${escapeHtml(model)}')" title="${isFav ? 'Retirer des favoris' : 'Ajouter aux favoris'}">
                    ${isFav ? '★' : '☆'}
                </button>
                <div class="ped-thumb-wrapper">
                    <img class="ped-thumb" src="${imgFiveM}" loading="lazy" onerror="handlePedImgError(this, '${escapeHtml(model)}')" alt="${escapeHtml(label)}">
                    <div class="ped-placeholder-box" style="display: none;">
                        <span style="font-size: 32px; opacity: 0.85;">${isAnimal ? '🐾' : '👤'}</span>
                        <span class="ped-placeholder-label">PED MODEL</span>
                    </div>
                </div>
                <div class="ped-title" title="${escapeHtml(label)}">${escapeHtml(label)}</div>
                <div class="ped-model-sub">${model}</div>
                <button class="ped-apply-btn" onclick="event.stopPropagation(); applyPedDirect('${escapeHtml(model)}')">Apply Skin</button>
            </div>
        `;
    }).join('');

    if (filtered.length > limit) {
        html += `<button class="load-more-btn" onclick="loadMorePeds()">➕ Afficher plus de personnages (${limit} sur ${filtered.length})</button>`;
    }

    container.innerHTML = html;
}

window.loadMorePeds = function() {
    currentPedLimit += 120;
    const q = document.getElementById('ped-search-input')?.value || '';
    renderVisualCharacters(q);
};

document.querySelectorAll('.filter-chip-ped').forEach(chip => {
    chip.addEventListener('click', () => {
        document.querySelectorAll('.filter-chip-ped').forEach(c => c.classList.remove('active'));
        chip.classList.add('active');
        currentPedFilter = chip.getAttribute('data-cat');
        const query = document.getElementById('ped-search-input')?.value || '';
        renderVisualCharacters(query);
    });
});

['input', 'keyup'].forEach(evt => {
    document.getElementById('ped-search-input')?.addEventListener(evt, (e) => {
        renderVisualCharacters(e.target.value);
    });
});

// Jobs & Careers Rendering (Dynamic Qbox Jobs Catalog)
function renderVisualJobs(searchQuery = '') {
    const container = document.getElementById('visual-jobs-container');
    if (!container) return;

    const sourceList = (allServerJobs && allServerJobs.length > 0) ? allServerJobs : FALLBACK_JOBS;
    const q = searchQuery.toLowerCase().trim();
    const isSearching = q.length > 0;

    const filtered = sourceList.filter(job => {
        const cat = (job.category || 'public').toLowerCase();
        const jName = job.name.toLowerCase();
        const jTitle = (job.label || jName).toLowerCase();

        const matchesSearch = !isSearching || jName.includes(q) || jTitle.includes(q);
        if (!matchesSearch) return false;

        if (isSearching) return true;

        if (currentJobFilter === 'all') return true;
        if (currentJobFilter === 'emergency') return cat === 'emergency';
        if (currentJobFilter === 'public') return cat === 'public';
        if (currentJobFilter === 'business') return cat === 'business';
        if (currentJobFilter === 'gang') return cat === 'gang';

        return true;
    });

    if (isSearching) {
        filtered.sort((a, b) => {
            const aName = a.name.toLowerCase();
            const bName = b.name.toLowerCase();
            const aStarts = aName.startsWith(q) || (a.label && a.label.toLowerCase().startsWith(q));
            const bStarts = bName.startsWith(q) || (b.label && b.label.toLowerCase().startsWith(q));
            if (aStarts && !bStarts) return -1;
            if (!aStarts && bStarts) return 1;
            return aName.localeCompare(bName);
        });
    }

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

['input', 'keyup'].forEach(evt => {
    document.getElementById('job-search-input')?.addEventListener(evt, (e) => {
        renderVisualJobs(e.target.value);
    });
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

window.openPlayerManageModal = function(targetId, targetName) {
    const modal = document.getElementById('player-manage-modal');
    if (!modal) return;

    document.getElementById('manage-target-id').value = targetId;
    document.getElementById('manage-target-name').value = targetName;
    document.getElementById('manage-target-name-display').innerText = targetName;
    document.getElementById('manage-target-id-badge').innerText = `ID: #${targetId}`;
    document.getElementById('manage-target-avatar').innerText = (targetName || 'P').substring(0, 2).toUpperCase();
    document.getElementById('manage-target-cid-display').innerText = 'Chargement des données joueur...';

    // Populate Friend / Online players dropdown (exclude current target)
    const select = document.getElementById('manage-friend-select');
    if (select) {
        select.innerHTML = '<option value="">-- Choisir un joueur connecté pour le transfert --</option>';
        onlinePlayersCache.forEach(p => {
            if (p.id != targetId) {
                const opt = document.createElement('option');
                opt.value = p.id;
                opt.innerText = `#${p.id} - ${p.name} (${p.charName || p.job || 'Player'})`;
                select.appendChild(opt);
            }
        });
    }

    // Reset inputs
    const elIds = ['manage-money-amount', 'manage-item-name', 'manage-item-count', 'manage-job-name', 'manage-job-grade', 'manage-gang-name', 'manage-gang-grade', 'manage-ped-model', 'manage-pm-msg', 'manage-warn-msg', 'manage-giveveh-model', 'manage-giveveh-plate'];
    elIds.forEach(id => {
        const el = document.getElementById(id);
        if (el && id.includes('count')) el.value = '1';
        else if (el && id.includes('grade')) el.value = '0';
        else if (el) el.value = '';
    });
    const garageInput = document.getElementById('manage-giveveh-garage');
    if (garageInput) garageInput.value = 'motel';

    const vehBox = document.getElementById('manage-vehicles-container');
    if (vehBox) vehBox.innerHTML = '<div class="asset-empty-state">Chargement des véhicules enregistrés...</div>';
    const propBox = document.getElementById('manage-properties-container');
    if (propBox) propBox.innerHTML = '<div class="asset-empty-state">Chargement des propriétés enregistrées...</div>';

    clearVehSelection();
    renderPedQuickStrip();

    modal.style.display = 'flex';

    // Fetch live details
    postNUI('playerDetailedAction', { action: 'get_details', targetId });
};

window.execPlayerDetailed = function(action, extra = {}) {
    const targetId = document.getElementById('manage-target-id').value;
    const name = document.getElementById('manage-target-name').value;
    const friendId = document.getElementById('manage-friend-select')?.value;

    let payload = { action, targetId, ...extra };

    if (action === 'send_to_friend') {
        if (!friendId) {
            alert('Veuillez sélectionner un joueur / ami dans la liste déroulante !');
            return;
        }
        payload = { action: 'teleport_to_friend', fromId: targetId, toId: friendId };
    } else if (action === 'bring_friend_here') {
        if (!friendId) {
            alert('Veuillez sélectionner un joueur / ami dans la liste déroulante !');
            return;
        }
        payload = { action: 'teleport_to_friend', fromId: friendId, toId: targetId };
    } else if (action === 'goto_target') {
        postNUI('teleportAction', { type: 'goto', target: targetId });
        return;
    } else if (action === 'bring_target') {
        postNUI('teleportAction', { type: 'bring', target: targetId });
        return;
    } else if (action === 'tp_preset') {
        postNUI('teleportPreset', { location: extra.location, targetId });
        return;
    } else if (action === 'money_give' || action === 'money_remove' || action === 'money_set') {
        const amount = parseInt(document.getElementById('manage-money-amount')?.value) || 0;
        const moneyType = document.getElementById('manage-money-type')?.value || 'cash';
        if (amount <= 0 && action !== 'money_set') {
            alert('Veuillez spécifier un montant valide supérieur à 0 !');
            return;
        }
        const mAction = action === 'money_give' ? 'give' : (action === 'money_remove' ? 'remove' : 'set');
        payload = { action: 'manage_money', targetId, moneyAction: mAction, moneyType, amount };
    } else if (action === 'give_item_direct') {
        const item = document.getElementById('manage-item-name')?.value.trim();
        const count = parseInt(document.getElementById('manage-item-count')?.value) || 1;
        if (!item) {
            alert('Veuillez entrer le nom technique de l\'item ox_inventory (ex: bandage, burger, weapon_pistol) !');
            return;
        }
        payload = { action: 'give_item_target', targetId, item, count };
    } else if (action === 'set_job') {
        const job = document.getElementById('manage-job-name')?.value.trim() || 'unemployed';
        const grade = parseInt(document.getElementById('manage-job-grade')?.value) || 0;
        payload = { action: 'set_job_direct', targetId, job, grade };
    } else if (action === 'set_gang') {
        const gang = document.getElementById('manage-gang-name')?.value.trim() || 'none';
        const grade = parseInt(document.getElementById('manage-gang-grade')?.value) || 0;
        payload = { action: 'set_gang', targetId, gang, grade };
    } else if (action === 'vitals_control') {
        payload = { action: 'vitals', targetId, vitalsType: extra.vitalsType };
    } else if (action === 'vehicle_action') {
        payload = { action: 'vehicle_control', targetId, vehAction: extra.vehAction };
    } else if (action === 'apply_ped_target') {
        const model = document.getElementById('manage-ped-model')?.value.trim();
        if (!model) {
            alert('Veuillez saisir un modèle de ped valide (ex: s_m_y_cop_01, player_zero, a_c_chop) !');
            return;
        }
        payload = { action: 'appearance_control', targetId, appType: 'set_ped', model };
    } else if (action === 'clothing_menu') {
        payload = { action: 'appearance_control', targetId, appType: 'clothing_menu' };
    } else if (action === 'clean_ped') {
        payload = { action: 'appearance_control', targetId, appType: 'clean_ped' };
    } else if (action === 'message') {
        payload.message = document.getElementById('manage-pm-msg')?.value.trim();
        if (!payload.message) return;
    } else if (action === 'warn') {
        payload.reason = document.getElementById('manage-warn-msg')?.value.trim() || 'Official staff warning';
    } else if (action === 'wipe') {
        if (!confirm(`Êtes-vous sûr de vouloir effectuer un WIPE ${extra.wipeType.toUpperCase()} sur [#${targetId}] ${name} ? Cette action est irréversible !`)) {
            return;
        }
    } else if (action === 'clear_inv') {
        if (!confirm(`Êtes-vous sûr de vouloir vider complètement l'inventaire de [#${targetId}] ${name} ?`)) {
            return;
        }
    } else if (action === 'give_owned_vehicle') {
        const model = document.getElementById('manage-giveveh-model')?.value.trim();
        const plate = document.getElementById('manage-giveveh-plate')?.value.trim();
        const garage = document.getElementById('manage-giveveh-garage')?.value.trim() || 'motel';
        if (!model) {
            alert('Veuillez spécifier le modèle du véhicule (ex: sultan, adder, schafter2) !');
            return;
        }
        payload = { action: 'give_owned_vehicle', targetId, model, plate, garage };
    }

    postNUI('playerDetailedAction', payload);
};

// Render Player Owned Assets (Vehicles & Properties)
function renderPlayerAssets(d) {
    const countBadge = document.getElementById('manage-assets-count');
    const vehBox = document.getElementById('manage-vehicles-container');
    const propBox = document.getElementById('manage-properties-container');

    const vehs = d.vehicles || [];
    const props = d.properties || [];

    if (countBadge) {
        countBadge.innerText = `${vehs.length} Voitures • ${props.length} Maisons`;
    }

    if (vehBox) {
        if (vehs.length === 0) {
            vehBox.innerHTML = '<div class="asset-empty-state">🚫 Ce joueur ne possède aucun véhicule enregistré dans ses garages.</div>';
        } else {
            vehBox.innerHTML = vehs.map(v => {
                const stateLabel = v.state === 1 ? 'Rentré Garage' : (v.state === 0 ? 'Sorti en Ville' : 'Fourrière');
                const stateColor = v.state === 1 ? 'green' : (v.state === 0 ? 'gold' : 'orange');
                const plateText = (v.plate || '').trim();
                const vModel = (v.vehicle || 'Vehicule').toLowerCase();
                const imgPath = `images/vehicles/${vModel}.webp`;
                const fallbackImg = `https://docs.fivem.net/vehicles/${vModel}.webp`;

                return `
                    <div class="asset-item-card">
                        <div class="asset-item-details">
                            <div class="asset-item-icon" style="overflow: hidden; padding: 2px;">
                                <img src="${imgPath}" onerror="this.onerror=null; this.src='${fallbackImg}'; this.onerror=function(){ this.style.display='none'; this.nextElementSibling.style.display='flex'; };" style="width: 100%; height: 100%; object-fit: contain;">
                                <span style="display: none; font-size: 1.2rem;">🚗</span>
                            </div>
                            <div class="asset-info-col">
                                <div class="asset-item-title">
                                    <span>${escapeHtml(vModel.toUpperCase())}</span>
                                    <span class="asset-plate-badge">${escapeHtml(plateText || 'NO PLATE')}</span>
                                </div>
                                <div class="asset-meta-row">
                                    <span>📍 Garage: <strong>${escapeHtml(v.garage || 'motel')}</strong></span>
                                    <span class="asset-tag ${stateColor}">${stateLabel}</span>
                                    <span>⛽ ${v.fuel || 100}%</span>
                                    <span>⚙️ ${Math.round((v.engine || 1000) / 10)}%</span>
                                </div>
                            </div>
                        </div>
                        <div class="asset-item-actions" style="display: flex; flex-wrap: wrap; gap: 4px; justify-content: flex-end; max-width: 480px;">
                            <button class="asset-action-btn btn-keys" onclick="execAssetAction('give_keys', { targetId: ${d.id}, plate: '${escapeHtml(plateText)}' })" title="Donner les clés au joueur">🔑 Clés</button>
                            <button class="asset-action-btn btn-bring" onclick="execAssetAction('bring_veh', { targetId: ${d.id}, plate: '${escapeHtml(plateText)}', model: '${escapeHtml(vModel)}' })" title="Téléporter ou sortir la voiture devant vous">📍 Bring</button>
                            <button class="asset-action-btn btn-stash" onclick="execAssetAction('open_veh_trunk', { targetId: ${d.id}, plate: '${escapeHtml(plateText)}' })" title="Ouvrir le coffre (Trunk)">🧰 Coffre</button>
                            <button class="asset-action-btn btn-stash" onclick="execAssetAction('open_veh_glovebox', { targetId: ${d.id}, plate: '${escapeHtml(plateText)}' })" title="Ouvrir la boîte à gants">📂 G-Box</button>
                            <button class="asset-action-btn btn-repair" onclick="execAssetAction('repair_veh', { targetId: ${d.id}, plate: '${escapeHtml(plateText)}' })" title="Réparer & Laver à 100%">🔧 Réparer</button>
                            <button class="asset-action-btn btn-transfer" onclick="execAssetAction('transfer_veh', { targetId: ${d.id}, plate: '${escapeHtml(plateText)}' })" title="Transférer la voiture à un autre joueur">🔄 Transférer</button>
                            <button class="asset-action-btn btn-danger" onclick="execAssetAction('seize_vehicle', { targetId: ${d.id}, plate: '${escapeHtml(plateText)}', citizenid: '${escapeHtml(d.citizenid)}' })" title="Saisir et supprimer définitivement ce véhicule">🗑️ Saisir</button>
                        </div>
                    </div>
                `;
            }).join('');
        }
    }

    if (propBox) {
        if (props.length === 0) {
            propBox.innerHTML = '<div class="asset-empty-state">🏠 Ce joueur ne possède aucune propriété ou maison enregistrée.</div>';
        } else {
            propBox.innerHTML = props.map(p => {
                const isRent = p.rent_interval && p.rent_interval > 0;
                return `
                    <div class="asset-item-card property-card">
                        <div class="asset-item-details">
                            <div class="asset-item-icon" style="background: rgba(255, 215, 0, 0.05); border-color: rgba(255, 215, 0, 0.2);">🏠</div>
                            <div class="asset-info-col">
                                <div class="asset-item-title">
                                    <span>${escapeHtml(p.property_name || 'Propriété #' + p.id)}</span>
                                    <span class="asset-tag gold">ID #${p.id}</span>
                                </div>
                                <div class="asset-meta-row">
                                    <span>💵 Valeur: <strong style="color: #00e676;">$${Number(p.price || 0).toLocaleString()}</strong></span>
                                    <span class="asset-tag ${isRent ? 'orange' : 'green'}">${isRent ? 'Location' : 'Propriété Définitive'}</span>
                                    ${p.interior ? `<span class="asset-tag">Inter: ${escapeHtml(p.interior)}</span>` : ''}
                                </div>
                            </div>
                        </div>
                        <div class="asset-item-actions" style="display: flex; flex-wrap: wrap; gap: 4px; justify-content: flex-end;">
                            <button class="asset-action-btn btn-stash" onclick="execAssetAction('open_house_stash', { targetId: ${d.id}, propertyName: '${escapeHtml(p.property_name)}' })" title="Ouvrir le coffre / stash de cette maison">📦 Ouvrir Coffre</button>
                            <button class="asset-action-btn btn-tp" onclick="execAssetAction('tp_property', { targetId: ${d.id}, propertyId: ${p.id} })" title="Se téléporter à l'entrée de cette maison">📍 TP Maison</button>
                            <button class="asset-action-btn btn-keys" onclick="execAssetAction('reset_property_keys', { targetId: ${d.id}, propertyId: ${p.id} })" title="Réinitialiser tous les doubles de clés">🔑 Reset Clés</button>
                            <button class="asset-action-btn btn-transfer" onclick="execAssetAction('transfer_property', { targetId: ${d.id}, propertyId: ${p.id} })" title="Transférer la propriété à un autre joueur">🔄 Transférer</button>
                            <button class="asset-action-btn btn-danger" onclick="execAssetAction('seize_property', { targetId: ${d.id}, propertyId: ${p.id}, name: '${escapeHtml(p.property_name || '#' + p.id)}', citizenid: '${escapeHtml(d.citizenid)}' })" title="Saisir la maison et la remettre en vente">🏠 Saisir Maison</button>
                        </div>
                    </div>
                `;
            }).join('');
        }
    }
}

// Global Asset Action Dispatcher (Houses & Cars Full Control)
window.execAssetAction = function(action, params) {
    if (action === 'seize_vehicle') {
        if (!confirm(`⚠️ ACTION DE SAISIE STAFF :\n\nÊtes-vous sûr de vouloir SAISIR et SUPPRIMER définitivement le véhicule [${params.plate}] de ce joueur ?\n\n• Le véhicule sera supprimé de son garage\n• S'il est actuellement sorti en ville, il disparaîtra\n• Les clés seront révoquées`)) {
            return;
        }
        postNUI('playerDetailedAction', { action: 'seize_vehicle', ...params });
    } else if (action === 'seize_property') {
        if (!confirm(`⚠️ ACTION DE SAISIE IMMOBILIÈRE :\n\nÊtes-vous sûr de vouloir SAISIR et RÉVOQUER la propriété "${params.name}" ?\n\n• Le joueur perdra son statut de propriétaire\n• Les clés et coffres seront révoqués\n• La propriété sera remise sur le marché pour la vente`)) {
            return;
        }
        postNUI('playerDetailedAction', { action: 'seize_property', ...params });
    } else if (action === 'give_keys') {
        postNUI('playerDetailedAction', { action: 'give_keys', ...params });
    } else if (action === 'open_house_stash') {
        postNUI('playerDetailedAction', { action: 'open_house_stash', ...params });
    } else if (action === 'tp_property') {
        postNUI('playerDetailedAction', { action: 'tp_property', ...params });
    } else if (action === 'reset_property_keys') {
        if (!confirm(`Confirmer la révocation de TOUS les doubles de clés de cette propriété ? Seul le propriétaire légitime conservera l'accès.`)) return;
        postNUI('playerDetailedAction', { action: 'reset_property_keys', ...params });
    } else if (action === 'transfer_property') {
        const toPlayer = prompt(`Entrez l'ID Serveur du nouveau propriétaire pour cette propriété :`);
        if (!toPlayer || isNaN(toPlayer)) return;
        postNUI('playerDetailedAction', { action: 'transfer_property', propertyId: params.propertyId, toPlayerId: parseInt(toPlayer) });
    } else if (action === 'open_veh_trunk') {
        postNUI('playerDetailedAction', { action: 'open_veh_trunk', ...params });
    } else if (action === 'open_veh_glovebox') {
        postNUI('playerDetailedAction', { action: 'open_veh_glovebox', ...params });
    } else if (action === 'bring_veh') {
        postNUI('playerDetailedAction', { action: 'bring_veh', ...params });
    } else if (action === 'repair_veh') {
        postNUI('playerDetailedAction', { action: 'repair_veh', ...params });
    } else if (action === 'transfer_veh') {
        const toPlayer = prompt(`Entrez l'ID Serveur du nouveau propriétaire pour le véhicule [${params.plate}] :`);
        if (!toPlayer || isNaN(toPlayer)) return;
        postNUI('playerDetailedAction', { action: 'transfer_veh', plate: params.plate, toPlayerId: parseInt(toPlayer) });
    }
};

// ==========================================================================
// Visual Ped & Skin Selector Logic (With Pictures)
// ==========================================================================
let currentPedPickerFilter = 'all';

window.openPedPickerModal = function() {
    const modal = document.getElementById('ped-picker-modal');
    if (!modal) return;
    modal.style.display = 'flex';
    currentPedPickerFilter = 'all';
    document.querySelectorAll('#ped-picker-filters .picker-filter-btn').forEach(btn => {
        btn.classList.toggle('active', btn.getAttribute('data-filter') === 'all');
    });
    const searchInput = document.getElementById('ped-picker-search');
    if (searchInput) searchInput.value = '';
    renderPedPickerGrid('');
};

function renderPedPickerGrid(searchQuery = '') {
    const grid = document.getElementById('ped-picker-grid');
    const countBadge = document.getElementById('ped-picker-count');
    if (!grid) return;

    const sourceList = (allServerCharacters && allServerCharacters.length > 0) ? allServerCharacters : VISUAL_PEDS;
    const q = searchQuery.toLowerCase().trim();
    const isSearching = q.length > 0;

    const filtered = sourceList.filter(p => {
        const model = p.model.toLowerCase();
        const label = (p.label || '').toLowerCase();
        const cat = (p.category || '').toLowerCase();
        if (isSearching) {
            return model.includes(q) || label.includes(q) || cat.includes(q);
        }
        if (currentPedPickerFilter === 'all') return true;
        if (currentPedPickerFilter === 'vip') return cat === 'vip' || cat === 'story';
        if (currentPedPickerFilter === 'emergency') return cat === 'emergency';
        if (currentPedPickerFilter === 'gang') return cat === 'gang' || cat === 'gangs';
        if (currentPedPickerFilter === 'civilian') return cat === 'civilian' || cat === 'male' || cat === 'female';
        if (currentPedPickerFilter === 'animal') return cat === 'animal' || cat === 'animals';
        if (currentPedPickerFilter === 'multiplayer') return cat === 'multiplayer';
        return true;
    });

    if (countBadge) countBadge.innerText = `${filtered.length} Peds`;

    if (filtered.length === 0) {
        grid.innerHTML = '<div class="asset-empty-state" style="grid-column: 1 / -1;">Aucun ped correspondant trouvé.</div>';
        return;
    }

    grid.innerHTML = filtered.map(p => {
        const model = p.model.toLowerCase();
        const label = p.label || model;
        const imgFiveM = `https://docs.fivem.net/peds/${model}.webp`;
        const isAnimal = p.category === 'animal' || p.category === 'animals';
        return `
            <div class="picker-item-card" onclick="selectPedModel('${escapeHtml(model)}', '${escapeHtml(label)}')">
                <div class="picker-item-img-wrapper">
                    <img class="picker-item-img" src="${imgFiveM}" loading="lazy" onerror="this.onerror=null; this.src=''; this.style.display='none'; this.nextElementSibling.style.display='flex';" alt="${escapeHtml(label)}">
                    <div style="display: none; align-items: center; justify-content: center; font-size: 28px;">${isAnimal ? '🐾' : '👤'}</div>
                </div>
                <div class="picker-item-title" title="${escapeHtml(label)}">${escapeHtml(label)}</div>
                <div class="picker-item-sub">${escapeHtml(model)}</div>
            </div>
        `;
    }).join('');
}

window.selectPedModel = function(model, label) {
    const input = document.getElementById('manage-ped-model');
    if (input) input.value = model;
    const modal = document.getElementById('ped-picker-modal');
    if (modal) modal.style.display = 'none';
    // Immediately apply to player!
    execPlayerDetailed('apply_ped_target');
};

function renderPedQuickStrip() {
    const strip = document.getElementById('manage-ped-quickstrip');
    if (!strip) return;
    const topPeds = [
        { model: 'player_zero', label: 'Michael' },
        { model: 'player_one', label: 'Franklin' },
        { model: 'player_two', label: 'Trevor' },
        { model: 's_m_y_cop_01', label: 'Police' },
        { model: 's_m_y_sheriff_01', label: 'Sheriff' },
        { model: 's_m_y_swat_01', label: 'SWAT' },
        { model: 's_m_m_paramedic_01', label: 'EMS' },
        { model: 'g_m_y_ballasout_01', label: 'Ballas' },
        { model: 'a_c_chop', label: 'Chop 🐕' },
        { model: 'mp_m_freemode_01', label: 'MP Male' },
        { model: 'mp_f_freemode_01', label: 'MP Female' },
    ];
    strip.innerHTML = topPeds.map(p => `
        <div class="ped-quick-item" onclick="selectPedModel('${p.model}', '${p.label}')" title="Appliquer ${p.label}">
            <img src="https://docs.fivem.net/peds/${p.model}.webp" onerror="this.style.display='none'">
            <span>${p.label}</span>
        </div>
    `).join('');
}

// ==========================================================================
// Visual Vehicle Catalog & Picker Logic (With Pictures)
// ==========================================================================
let currentVehPickerFilter = 'all';

window.openVehPickerModal = function() {
    const modal = document.getElementById('veh-picker-modal');
    if (!modal) return;
    modal.style.display = 'flex';
    currentVehPickerFilter = 'all';
    document.querySelectorAll('#veh-picker-filters .picker-filter-btn').forEach(btn => {
        btn.classList.toggle('active', btn.getAttribute('data-filter') === 'all');
    });
    const searchInput = document.getElementById('veh-picker-search');
    if (searchInput) searchInput.value = '';
    renderVehPickerGrid('');
};

function renderVehPickerGrid(searchQuery = '') {
    const grid = document.getElementById('veh-picker-grid');
    const countBadge = document.getElementById('veh-picker-count');
    if (!grid) return;

    const sourceList = (allServerVehicles && allServerVehicles.length > 0) ? allServerVehicles : FALLBACK_VEHICLES;
    const q = searchQuery.toLowerCase().trim();
    const isSearching = q.length > 0;

    const filtered = sourceList.filter(v => {
        const model = v.model.toLowerCase();
        const name = (v.name || '').toLowerCase();
        const brand = (v.brand || '').toLowerCase();
        const cat = (v.category || '').toLowerCase();
        if (isSearching) {
            return model.includes(q) || name.includes(q) || brand.includes(q) || cat.includes(q);
        }
        if (currentVehPickerFilter === 'all') return true;
        if (currentVehPickerFilter === 'super') return cat === 'super';
        if (currentVehPickerFilter === 'sports') return cat === 'sports' || cat === 'sport';
        if (currentVehPickerFilter === 'sedans') return cat === 'sedans' || cat === 'coupes' || cat === 'compacts';
        if (currentVehPickerFilter === 'suvs') return cat === 'suvs' || cat === 'offroad';
        if (currentVehPickerFilter === 'muscle') return cat === 'muscle';
        if (currentVehPickerFilter === 'emergency') return cat === 'emergency';
        if (currentVehPickerFilter === 'motorcycles') return cat === 'motorcycles';
        return true;
    });

    if (countBadge) countBadge.innerText = `${filtered.length} Véhicules`;

    if (filtered.length === 0) {
        grid.innerHTML = '<div class="asset-empty-state" style="grid-column: 1 / -1;">Aucun véhicule correspondant trouvé.</div>';
        return;
    }

    grid.innerHTML = filtered.slice(0, 150).map(v => {
        const model = v.model.toLowerCase();
        const name = v.name || model;
        const brand = v.brand ? v.brand.toUpperCase() : '';
        const imgPath = `images/vehicles/${model}.webp`;
        const fallbackImg = `https://docs.fivem.net/vehicles/${model}.webp`;
        return `
            <div class="picker-item-card" onclick="selectVehModel('${escapeHtml(model)}', '${escapeHtml(name)}', '${escapeHtml(brand)}')">
                <div class="picker-item-img-wrapper">
                    <img class="picker-item-img" src="${imgPath}" loading="lazy" onerror="this.onerror=null; this.src='${fallbackImg}'; this.onerror=function(){ this.style.display='none'; this.nextElementSibling.style.display='flex'; };" alt="${escapeHtml(name)}">
                    <div style="display: none; align-items: center; justify-content: center; font-size: 28px;">🚗</div>
                </div>
                <div class="picker-item-title" title="${escapeHtml(name)}">${escapeHtml(name)}</div>
                <div class="picker-item-sub">${brand ? brand + ' • ' : ''}${escapeHtml(model)}</div>
            </div>
        `;
    }).join('');
}

window.selectVehModel = function(model, name, brand) {
    const input = document.getElementById('manage-giveveh-model');
    if (input) input.value = model;
    const previewBox = document.getElementById('manage-giveveh-preview-box');
    if (previewBox) {
        const imgPath = `images/vehicles/${model}.webp`;
        previewBox.style.display = 'flex';
        previewBox.innerHTML = `
            <img src="${imgPath}" onerror="this.src='https://docs.fivem.net/vehicles/${model}.webp'; this.onerror=function(){ this.style.display='none'; }">
            <div style="display: flex; flex-direction: column; gap: 2px;">
                <div style="font-size: 0.82rem; font-weight: 700; color: #fff;">${escapeHtml(brand ? brand + ' ' + name : name)}</div>
                <div style="font-size: 0.7rem; color: var(--accent-cyan); font-family: monospace;">SPAWN: ${escapeHtml(model.toUpperCase())}</div>
            </div>
            <button class="secondary-btn" style="margin-left: auto; padding: 2px 8px; font-size: 0.7rem;" onclick="clearVehSelection()">&times;</button>
        `;
    }
    const modal = document.getElementById('veh-picker-modal');
    if (modal) modal.style.display = 'none';
};

window.clearVehSelection = function() {
    const input = document.getElementById('manage-giveveh-model');
    if (input) input.value = '';
    const previewBox = document.getElementById('manage-giveveh-preview-box');
    if (previewBox) {
        previewBox.style.display = 'none';
        previewBox.innerHTML = '';
    }
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

// Ped Picker Modal Close & Search Listeners
document.getElementById('ped-picker-close')?.addEventListener('click', () => {
    document.getElementById('ped-picker-modal').style.display = 'none';
});
document.getElementById('ped-picker-close-btn')?.addEventListener('click', () => {
    document.getElementById('ped-picker-modal').style.display = 'none';
});
document.getElementById('ped-picker-search')?.addEventListener('input', (e) => {
    renderPedPickerGrid(e.target.value);
});
document.querySelectorAll('#ped-picker-filters .picker-filter-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        document.querySelectorAll('#ped-picker-filters .picker-filter-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        currentPedPickerFilter = btn.getAttribute('data-filter') || 'all';
        const q = document.getElementById('ped-picker-search')?.value || '';
        renderPedPickerGrid(q);
    });
});

// Vehicle Picker Modal Close & Search Listeners
document.getElementById('veh-picker-close')?.addEventListener('click', () => {
    document.getElementById('veh-picker-modal').style.display = 'none';
});
document.getElementById('veh-picker-close-btn')?.addEventListener('click', () => {
    document.getElementById('veh-picker-modal').style.display = 'none';
});
document.getElementById('veh-picker-search')?.addEventListener('input', (e) => {
    renderVehPickerGrid(e.target.value);
});
document.querySelectorAll('#veh-picker-filters .picker-filter-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        document.querySelectorAll('#veh-picker-filters .picker-filter-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        currentVehPickerFilter = btn.getAttribute('data-filter') || 'all';
        const q = document.getElementById('veh-picker-search')?.value || '';
        renderVehPickerGrid(q);
    });
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

// Staff & Granular Permissions Suite
let cachedStaffList = [];
let cachedOnlinePlayers = [];
let staffViewMode = 'members'; // 'members' = ga3 les joueurs, 'staff' = only staff

let rolePresetPerms = {
    owner: { god: true, teleport: true, items: true, vehicles: true, characters: true, jobs: true, arsenal: true, players: true, punishments: true, devtools: true, world: true, logs: true, events: true, staff: true },
    developer: { god: false, teleport: true, items: false, vehicles: true, characters: true, jobs: false, arsenal: false, players: true, punishments: false, devtools: true, world: true, logs: true, events: true, staff: false },
    admin: { god: false, teleport: true, items: true, vehicles: true, characters: true, jobs: true, arsenal: false, players: true, punishments: true, devtools: false, world: true, logs: true, events: true, staff: false },
    moderator: { god: false, teleport: true, items: false, vehicles: true, characters: false, jobs: false, arsenal: false, players: true, punishments: false, devtools: false, world: false, logs: false, events: false, staff: false },
    custom: { god: false, teleport: true, items: false, vehicles: false, characters: false, jobs: false, arsenal: false, players: true, punishments: false, devtools: false, world: false, logs: false, events: false, staff: false }
};

const ALL_PERM_KEYS = ['players', 'teleport', 'vehicles', 'punishments', 'items', 'characters', 'jobs', 'world', 'devtools', 'arsenal', 'god', 'logs', 'events', 'staff'];

async function fetchNUI(endpoint, payload = {}) {
    const resourceName = window.GetParentResourceName ? window.GetParentResourceName() : 'souh4il_dev';
    try {
        const resp = await fetch(`https://${resourceName}/${endpoint}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });
        return await resp.json();
    } catch (err) {
        console.warn(`NUI error on ${endpoint}:`, err);
        return null;
    }
}

async function fetchStaffData() {
    const container = document.getElementById('staff-list-container');
    if (container) container.innerHTML = '<div class="table-empty">Chargement de la liste des membres...</div>';

    const res = await fetchNUI('getStaffData');
    if (!res || !res.success) {
        if (container) container.innerHTML = `<div class="table-empty" style="color: var(--accent-red);">${res && res.error === 'ACCESS_DENIED' ? 'Accès refusé : Seul le Propriétaire ou les Administrateurs autorisés peuvent gérer le staff.' : 'Erreur lors du chargement des staffs.'}</div>`;
        return;
    }

    cachedStaffList = res.staff || [];
    cachedOnlinePlayers = res.onlinePlayers || [];
    if (res.defaultPerms) {
        rolePresetPerms = { ...rolePresetPerms, ...res.defaultPerms };
    }

    // Update metrics
    const totalMembersElem = document.getElementById('metric-total-members');
    const totalStaffElem = document.getElementById('metric-total-staff');
    if (totalMembersElem) totalMembersElem.innerText = cachedOnlinePlayers.length;
    if (totalStaffElem) totalStaffElem.innerText = cachedStaffList.length;

    // Populate online players dropdown in modal
    const playerSelect = document.getElementById('staff-select-player');
    if (playerSelect) {
        playerSelect.innerHTML = '<option value="">-- Choisir un joueur connecté (ou entrer la License ci-dessous) --</option>';
        cachedOnlinePlayers.forEach(p => {
            const opt = document.createElement('option');
            opt.value = p.license;
            opt.dataset.name = p.name;
            opt.dataset.cid = p.citizenid;
            opt.innerText = `[ID: ${p.source}] ${p.name} (CID: ${p.citizenid}) - ${p.hasAccess ? p.role : 'Member'}`;
            playerSelect.appendChild(opt);
        });
    }

    renderStaffView();
}

function renderStaffView() {
    const query = document.getElementById('staff-search-input')?.value.trim() || '';
    if (staffViewMode === 'members') {
        renderMembersList(cachedOnlinePlayers, query);
    } else {
        renderStaffList(cachedStaffList, query);
    }
}

function renderMembersList(list, filter = '') {
    const container = document.getElementById('staff-list-container');
    if (!container) return;

    const filtered = list.filter(p => {
        if (!filter) return true;
        const q = filter.toLowerCase();
        return (p.name && p.name.toLowerCase().includes(q)) ||
               (p.license && p.license.toLowerCase().includes(q)) ||
               (p.citizenid && p.citizenid.toLowerCase().includes(q)) ||
               (p.source && p.source.toString().includes(q)) ||
               (p.job && p.job.toLowerCase().includes(q)) ||
               (p.gang && p.gang.toLowerCase().includes(q));
    });

    if (filtered.length === 0) {
        container.innerHTML = '<div class="table-empty">Aucun joueur connecté trouvé dans le serveur.</div>';
        return;
    }

    let html = '';
    filtered.forEach(p => {
        const initials = (p.name || 'PL').substring(0, 2).toUpperCase();
        const roleLower = (p.role || 'member').toLowerCase();
        const roleClass = `role-${roleLower}`;
        const hasAccess = !!p.hasAccess;

        // Build active perms tags
        const perms = p.permissions || {};
        let permsTagsHtml = '';
        if (hasAccess) {
            ALL_PERM_KEYS.forEach(k => {
                if (perms[k] === true) {
                    const label = k.charAt(0).toUpperCase() + k.slice(1);
                    permsTagsHtml += `<span class="perm-tag active">${label}</span>`;
                }
            });
        }
        if (!permsTagsHtml) {
            permsTagsHtml = '<span class="perm-tag" style="color: var(--text-muted);">Membre Standard (Aucun Accès Panel)</span>';
        }

        const safeLicense = escapeHtml(p.license || '');
        const displayLic = safeLicense.length > 25 ? `${safeLicense.substring(0, 16)}...${safeLicense.substring(safeLicense.length - 6)}` : safeLicense;

        html += `
        <div class="staff-card ${p.isOwner ? 'owner-card' : ''}" style="${!hasAccess ? 'border-style: dashed; opacity: 0.9;' : ''}">
            <div class="staff-top">
                <div class="staff-identity">
                    <div class="staff-avatar" style="${hasAccess ? 'border-color: var(--accent-cyan);' : 'background: rgba(255,255,255,0.05);'}">${initials}</div>
                    <div>
                        <div class="staff-name">
                            <span class="status-dot online" title="En ligne"></span>
                            <span>${escapeHtml(p.name || 'Player')}</span>
                            <span style="font-size: 0.72rem; color: var(--accent-green); font-weight: 700;">[ID: ${p.source}]</span>
                        </div>
                        <div class="staff-license" title="${safeLicense}">
                            ${displayLic} • CID: ${escapeHtml(p.citizenid || 'N/A')}
                        </div>
                    </div>
                </div>
                <span class="role-badge ${hasAccess ? roleClass : 'role-custom'}" style="${!hasAccess ? 'background: rgba(255,255,255,0.05); color: var(--text-muted); border-color: rgba(255,255,255,0.1);' : ''}">
                    ${hasAccess ? escapeHtml(p.role) : 'MEMBER'}
                </span>
            </div>

            <div style="font-size: 0.72rem; color: var(--text-muted); display: flex; gap: 14px;">
                <span>💼 Job : <b style="color: var(--text-secondary);">${escapeHtml(p.job || 'Civilian')}</b></span>
                <span>🔥 Gang : <b style="color: var(--text-secondary);">${escapeHtml(p.gang || 'None')}</b></span>
            </div>

            <div>
                <div style="font-size: 0.68rem; color: var(--text-muted); text-transform: uppercase; margin-bottom: 4px; letter-spacing: 0.04em;">Accès SOUH4IL-DEV :</div>
                <div class="perm-tags-container">
                    ${permsTagsHtml}
                </div>
            </div>

            <div class="staff-actions">
                ${p.isOwner ? `
                    <span style="font-size: 0.75rem; color: #ffd700; font-weight: 700; padding: 6px;">👑 PROPRIÉTAIRE CANONIQUE</span>
                ` : hasAccess ? `
                    <button class="secondary-btn" onclick="openEditStaff('${safeLicense}')">✏️ Modifier Perms</button>
                    <button class="primary-btn danger-btn" onclick="removeStaffMember('${safeLicense}', '${escapeHtml(p.name)}')">🗑️ Révoquer</button>
                ` : `
                    <button class="primary-btn" style="background: rgba(0, 229, 255, 0.2); border-color: var(--accent-cyan); color: var(--accent-cyan);" onclick="openGrantMemberModal('${safeLicense}', '${escapeHtml(p.name)}')">➕ Configurer les accès (Grant Access)</button>
                `}
            </div>
        </div>
        `;
    });

    container.innerHTML = html;
}

function renderStaffList(list, filter = '') {
    const container = document.getElementById('staff-list-container');
    if (!container) return;

    const filtered = list.filter(s => {
        if (!filter) return true;
        const q = filter.toLowerCase();
        return (s.name && s.name.toLowerCase().includes(q)) ||
               (s.license && s.license.toLowerCase().includes(q)) ||
               (s.role && s.role.toLowerCase().includes(q));
    });

    if (filtered.length === 0) {
        container.innerHTML = '<div class="table-empty">Aucun membre du staff trouvé.</div>';
        return;
    }

    let html = '';
    filtered.forEach(s => {
        const isOnline = !!s.online;
        const roleLower = (s.role || 'moderator').toLowerCase();
        const roleClass = `role-${roleLower}`;
        const initials = (s.name || 'ST').substring(0, 2).toUpperCase();

        // Build active perms tags
        const perms = s.permissions || {};
        let permsTagsHtml = '';
        ALL_PERM_KEYS.forEach(k => {
            if (perms[k] === true) {
                const label = k.charAt(0).toUpperCase() + k.slice(1);
                permsTagsHtml += `<span class="perm-tag active">${label}</span>`;
            }
        });
        if (!permsTagsHtml) {
            permsTagsHtml = '<span class="perm-tag">Aucune permission active</span>';
        }

        const safeLicense = escapeHtml(s.license || '');
        const displayLic = safeLicense.length > 25 ? `${safeLicense.substring(0, 16)}...${safeLicense.substring(safeLicense.length - 6)}` : safeLicense;

        html += `
        <div class="staff-card ${s.isOwner ? 'owner-card' : ''}">
            <div class="staff-top">
                <div class="staff-identity">
                    <div class="staff-avatar">${initials}</div>
                    <div>
                        <div class="staff-name">
                            <span class="status-dot ${isOnline ? 'online' : 'offline'}" title="${isOnline ? 'En ligne (ID: ' + s.source + ')' : 'Hors ligne'}"></span>
                            <span>${escapeHtml(s.name || 'Staff')}</span>
                            ${isOnline ? `<span style="font-size: 0.7rem; color: var(--accent-green); font-weight: 600;">[ID: ${s.source}]</span>` : ''}
                        </div>
                        <div class="staff-license" title="${safeLicense}">
                            ${displayLic}
                        </div>
                    </div>
                </div>
                <span class="role-badge ${roleClass}">${escapeHtml(s.role || 'STAFF')}</span>
            </div>

            <div style="font-size: 0.72rem; color: var(--text-muted);">
                Attribué par : <b style="color: var(--text-secondary);">${escapeHtml(s.granted_by || 'Owner')}</b>
            </div>

            <div>
                <div style="font-size: 0.7rem; color: var(--text-muted); text-transform: uppercase; margin-bottom: 5px; letter-spacing: 0.04em;">Pouvoirs autorisés :</div>
                <div class="perm-tags-container">
                    ${permsTagsHtml}
                </div>
            </div>

            <div class="staff-actions">
                ${s.isOwner ? `
                    <span style="font-size: 0.75rem; color: #ffd700; font-weight: 700; padding: 6px;">👑 PROPRIÉTAIRE CANONIQUE</span>
                ` : `
                    <button class="secondary-btn" onclick="openEditStaff('${safeLicense}')">✏️ Modifier Perms</button>
                    <button class="primary-btn danger-btn" onclick="removeStaffMember('${safeLicense}', '${escapeHtml(s.name || 'Staff')}')">🗑️ Révoquer</button>
                `}
            </div>
        </div>
        `;
    });

    container.innerHTML = html;
}

function openGrantMemberModal(license, name) {
    const modal = document.getElementById('staff-modal');
    if (!modal) return;

    document.getElementById('staff-modal-title').innerText = `🛡️ Configurer les accès pour : ${name}`;
    document.getElementById('staff-select-player').value = license;
    document.getElementById('staff-input-name').value = name;
    document.getElementById('staff-input-license').value = license;
    document.getElementById('staff-input-license').readOnly = true;
    document.getElementById('staff-select-role').value = 'moderator';

    applyRolePresetToCheckboxes('moderator');
    highlightPresetButton('preset-btn-mod');
    modal.style.display = 'flex';
}

function openAddStaffModal() {
    const modal = document.getElementById('staff-modal');
    if (!modal) return;

    document.getElementById('staff-modal-title').innerText = '🛡️ Grant New Staff Access';
    document.getElementById('staff-select-player').value = '';
    document.getElementById('staff-input-name').value = '';
    document.getElementById('staff-input-license').value = '';
    document.getElementById('staff-input-license').readOnly = false;
    document.getElementById('staff-select-role').value = 'moderator';

    applyRolePresetToCheckboxes('moderator');
    highlightPresetButton('preset-btn-mod');
    modal.style.display = 'flex';
}

function openEditStaff(license) {
    const staff = cachedStaffList.find(s => s.license === license) || cachedOnlinePlayers.find(p => p.license === license);
    if (!staff) return;

    const modal = document.getElementById('staff-modal');
    if (!modal) return;

    document.getElementById('staff-modal-title').innerText = `✏️ Modifier les permissions : ${staff.name}`;
    document.getElementById('staff-select-player').value = staff.license;
    document.getElementById('staff-input-name').value = staff.name || '';
    document.getElementById('staff-input-license').value = staff.license || '';
    document.getElementById('staff-input-license').readOnly = true;

    const roleLower = (staff.role || 'moderator').toLowerCase();
    document.getElementById('staff-select-role').value = rolePresetPerms[roleLower] ? roleLower : 'custom';

    const perms = staff.permissions || {};
    ALL_PERM_KEYS.forEach(k => {
        const chk = document.getElementById(`perm-${k}`);
        if (chk) chk.checked = !!perms[k];
    });

    const btnMap = {
        moderator: 'preset-btn-mod',
        admin: 'preset-btn-admin',
        developer: 'preset-btn-dev',
        owner: 'preset-btn-owner'
    };
    highlightPresetButton(btnMap[roleLower] || '');
    modal.style.display = 'flex';
}

function applyRolePresetToCheckboxes(role) {
    const preset = rolePresetPerms[role] || rolePresetPerms.moderator;
    ALL_PERM_KEYS.forEach(k => {
        const chk = document.getElementById(`perm-${k}`);
        if (chk) chk.checked = !!preset[k];
    });
}

function closeStaffModal() {
    const modal = document.getElementById('staff-modal');
    if (modal) modal.style.display = 'none';
}

async function saveStaff() {
    const license = document.getElementById('staff-input-license')?.value.trim();
    const name = document.getElementById('staff-input-name')?.value.trim() || 'Staff';
    const role = document.getElementById('staff-select-role')?.value || 'moderator';

    if (!license) {
        alert('Veuillez sélectionner un joueur ou renseigner une Rockstar License valide !');
        return;
    }

    const permissions = {};
    ALL_PERM_KEYS.forEach(k => {
        const chk = document.getElementById(`perm-${k}`);
        permissions[k] = chk ? chk.checked : false;
    });

    const res = await fetchNUI('saveStaffMember', {
        license: license,
        name: name,
        role: role,
        permissions: permissions
    });

    if (res && res.success) {
        closeStaffModal();
        fetchStaffData();
    } else {
        alert('Erreur lors de la sauvegarde : ' + (res && res.error ? res.error : 'Serveur inaccessible'));
    }
}

async function removeStaffMember(license, name) {
    if (!confirm(`Êtes-vous sûr de vouloir révoquer tous les accès SOUH4IL-DEV pour ${name} ?`)) {
        return;
    }

    const res = await fetchNUI('removeStaffMember', { license: license });
    if (res && res.success) {
        fetchStaffData();
    } else {
        alert('Erreur lors de la révocation : ' + (res && res.error ? res.error : 'Erreur inconnue'));
    }
}

// Event Manager Presets & Functions
const EVENT_PRESETS = {
    fight: {
        eventType: 'fight',
        title: '🥊 FIGHT NIGHT TOURNAMENT',
        message: 'Rejoignez le ring à Legion Square ! Matchs de boxe et cash prizes pour le vainqueur !',
        coords: { x: 215.76, y: -910.0, z: 30.69 },
        radius: 60,
        blipColor: 1,
        blipSprite: 38
    },
    race: {
        eventType: 'race',
        title: '🏎️ UNDERGROUND DRAG RACE',
        message: 'Course de vitesse illégale à l\'aéroport ! Véhicules sur la ligne de départ !',
        coords: { x: -1037.0, y: -2982.0, z: 13.95 },
        radius: 250,
        blipColor: 5,
        blipSprite: 227
    },
    purge: {
        eventType: 'purge',
        title: '💀 THE PURGE NIGHT (15 MINUTES)',
        message: 'L\'alarme retentit ! Tous les crimes sont autorisés pendant 15 minutes !',
        coords: { x: 215.76, y: -910.0, z: 30.69 },
        radius: 500,
        blipColor: 1,
        blipSprite: 84,
        weather: 'HALLOWEEN',
        time: { hour: 0, minute: 0 }
    },
    airdrop: {
        eventType: 'airdrop',
        title: '🎁 MYSTERY AIRDROP SUPPLY DROP',
        message: 'Une caisse de ravitaillement VIP a été larguée à Sandy Shores ! Sécurisez le loot !',
        coords: { x: 1734.55, y: 3710.98, z: 34.14 },
        radius: 100,
        blipColor: 2,
        blipSprite: 501
    },
    derby: {
        eventType: 'derby',
        title: '💥 DEMOLITION DERBY ARENA',
        message: 'Arène de destruction totale ouverte à Sandy Shores ! Que le plus solide gagne !',
        coords: { x: 1734.55, y: 3710.98, z: 34.14 },
        radius: 120,
        blipColor: 27,
        blipSprite: 38
    }
};

async function launchPresetEvent(presetKey) {
    const preset = EVENT_PRESETS[presetKey];
    if (!preset) return;

    if (!confirm(`Confirmer le lancement de l'événement : ${preset.title} ?`)) {
        return;
    }

    const res = await fetchNUI('startEvent', preset);
    if (res && res.success) {
        checkEventState();
    } else {
        alert('Erreur lors du lancement : ' + (res && res.error ? res.error : 'Serveur inaccessible'));
    }
}

async function launchCustomEvent() {
    const title = document.getElementById('custom-event-title')?.value.trim() || 'Événement Spécial';
    const type = document.getElementById('custom-event-type')?.value || 'custom';
    const msg = document.getElementById('custom-event-msg')?.value.trim() || 'Un nouvel événement a commencé !';
    const locKey = document.getElementById('custom-event-loc')?.value || 'legion';
    const radius = parseInt(document.getElementById('custom-event-radius')?.value) || 120;
    const color = parseInt(document.getElementById('custom-event-color')?.value) || 1;

    let coords = null;
    const PRESET_COORDS = {
        legion: { x: 215.76, y: -910.0, z: 30.69 },
        airport: { x: -1037.0, y: -2982.0, z: 13.95 },
        sandy: { x: 1734.55, y: 3710.98, z: 34.14 },
        mazebank: { x: -75.0, y: -818.0, z: 326.0 }
    };
    if (locKey !== 'my_coords') {
        coords = PRESET_COORDS[locKey];
    }

    const res = await fetchNUI('startEvent', {
        eventType: type,
        title: title,
        message: msg,
        coords: coords,
        radius: radius,
        blipColor: color
    });

    if (res && res.success) {
        checkEventState();
    } else {
        alert('Erreur lors du lancement : ' + (res && res.error ? res.error : 'Serveur inaccessible'));
    }
}

async function stopActiveEvent() {
    if (!confirm('Êtes-vous sûr de vouloir stopper l\'événement en cours ?')) return;

    const res = await fetchNUI('stopEvent');
    if (res && res.success) {
        checkEventState();
    } else {
        alert('Erreur : ' + (res && res.error ? res.error : 'Erreur inconnue'));
    }
}

async function checkEventState() {
    const res = await fetchNUI('getEventState');
    const dot = document.getElementById('event-status-dot');
    const title = document.getElementById('event-status-title');
    const sub = document.getElementById('event-status-subtitle');
    const badge = document.getElementById('event-badge');
    const stopBtn = document.getElementById('btn-stop-active-event');

    if (res && res.activeEvent) {
        const ev = res.activeEvent;
        if (dot) { dot.className = 'status-dot online'; }
        if (title) { title.innerText = `ÉVÉNEMENT EN COURS : ${ev.title}`; }
        if (sub) { sub.innerText = `Lancé à ${ev.startedAt} par ${ev.startedBy} • Rayon: ${ev.radius}m`; }
        if (badge) {
            badge.innerText = 'EN DIRECT (LIVE)';
            badge.className = 'role-badge role-admin';
        }
        if (stopBtn) { stopBtn.style.display = 'block'; }
    } else {
        if (dot) { dot.className = 'status-dot offline'; }
        if (title) { title.innerText = 'AUCUN ÉVÉNEMENT EN COURS'; }
        if (sub) { sub.innerText = 'Sélectionnez un événement ci-dessous pour le démarrer.'; }
        if (badge) {
            badge.innerText = 'IDLE';
            badge.className = 'role-badge role-custom';
        }
        if (stopBtn) { stopBtn.style.display = 'none'; }
    }
}

// Staff & View Mode Event Listeners
document.getElementById('btn-open-add-staff')?.addEventListener('click', openAddStaffModal);
document.getElementById('btn-refresh-staff')?.addEventListener('click', fetchStaffData);
document.getElementById('staff-modal-close')?.addEventListener('click', closeStaffModal);
document.getElementById('btn-cancel-staff')?.addEventListener('click', closeStaffModal);
document.getElementById('btn-save-staff')?.addEventListener('click', saveStaff);

document.getElementById('btn-view-members')?.addEventListener('click', () => {
    staffViewMode = 'members';
    const btnM = document.getElementById('btn-view-members');
    const btnS = document.getElementById('btn-view-staff');
    if (btnM) {
        btnM.style.background = 'rgba(0, 229, 255, 0.15)';
        btnM.style.borderColor = 'var(--accent-cyan)';
        btnM.style.color = 'var(--accent-cyan)';
    }
    if (btnS) {
        btnS.style.background = '';
        btnS.style.borderColor = '';
        btnS.style.color = '';
    }
    const hint = document.getElementById('staff-view-hint');
    if (hint) hint.innerText = '💡 Tous les membres connectés au serveur. Cliquez sur un joueur pour configurer ou modifier ses accès.';
    renderStaffView();
});

document.getElementById('btn-view-staff')?.addEventListener('click', () => {
    staffViewMode = 'staff';
    const btnM = document.getElementById('btn-view-members');
    const btnS = document.getElementById('btn-view-staff');
    if (btnS) {
        btnS.style.background = 'rgba(0, 229, 255, 0.15)';
        btnS.style.borderColor = 'var(--accent-cyan)';
        btnS.style.color = 'var(--accent-cyan)';
    }
    if (btnM) {
        btnM.style.background = '';
        btnM.style.borderColor = '';
        btnM.style.color = '';
    }
    const hint = document.getElementById('staff-view-hint');
    if (hint) hint.innerText = '💡 Liste restreinte des staffs et administrateurs ayant des permissions dans SOUH4IL-DEV.';
    renderStaffView();
});

document.getElementById('staff-select-player')?.addEventListener('change', (e) => {
    const sel = e.target;
    const selectedOpt = sel.options[sel.selectedIndex];
    if (selectedOpt && selectedOpt.value) {
        document.getElementById('staff-input-license').value = selectedOpt.value;
        document.getElementById('staff-input-name').value = selectedOpt.dataset.name || '';
    }
});

document.getElementById('staff-select-role')?.addEventListener('change', (e) => {
    const role = e.target.value;
    if (role !== 'custom') {
        applyRolePresetToCheckboxes(role);
    }
});

ALL_PERM_KEYS.forEach(k => {
    document.getElementById(`perm-${k}`)?.addEventListener('change', () => {
        const roleSel = document.getElementById('staff-select-role');
        if (roleSel) roleSel.value = 'custom';
    });
});

document.getElementById('staff-search-input')?.addEventListener('input', () => {
    renderStaffView();
});

// Event Manager Button Listeners
document.getElementById('btn-refresh-event')?.addEventListener('click', checkEventState);
document.getElementById('btn-stop-active-event')?.addEventListener('click', stopActiveEvent);
document.getElementById('btn-launch-custom-event')?.addEventListener('click', launchCustomEvent);

// Preset Buttons & Modal Helpers
function highlightPresetButton(activeId) {
    ['preset-btn-mod', 'preset-btn-admin', 'preset-btn-dev', 'preset-btn-owner', 'preset-btn-clear'].forEach(id => {
        const btn = document.getElementById(id);
        if (btn) {
            if (id === activeId) btn.classList.add('active');
            else btn.classList.remove('active');
        }
    });
}

document.getElementById('preset-btn-mod')?.addEventListener('click', () => {
    document.getElementById('staff-select-role').value = 'moderator';
    applyRolePresetToCheckboxes('moderator');
    highlightPresetButton('preset-btn-mod');
});
document.getElementById('preset-btn-admin')?.addEventListener('click', () => {
    document.getElementById('staff-select-role').value = 'admin';
    applyRolePresetToCheckboxes('admin');
    highlightPresetButton('preset-btn-admin');
});
document.getElementById('preset-btn-dev')?.addEventListener('click', () => {
    document.getElementById('staff-select-role').value = 'developer';
    applyRolePresetToCheckboxes('developer');
    highlightPresetButton('preset-btn-dev');
});
document.getElementById('preset-btn-owner')?.addEventListener('click', () => {
    document.getElementById('staff-select-role').value = 'owner';
    applyRolePresetToCheckboxes('owner');
    highlightPresetButton('preset-btn-owner');
});
document.getElementById('preset-btn-clear')?.addEventListener('click', () => {
    document.getElementById('staff-select-role').value = 'custom';
    ALL_PERM_KEYS.forEach(k => {
        const chk = document.getElementById(`perm-${k}`);
        if (chk) chk.checked = false;
    });
    highlightPresetButton('preset-btn-clear');
});

document.getElementById('staff-select-role')?.addEventListener('change', (e) => {
    const role = e.target.value;
    if (role !== 'custom') {
        applyRolePresetToCheckboxes(role);
        const btnMap = {
            moderator: 'preset-btn-mod',
            admin: 'preset-btn-admin',
            developer: 'preset-btn-dev',
            owner: 'preset-btn-owner'
        };
        highlightPresetButton(btnMap[role] || '');
    } else {
        highlightPresetButton('');
    }
});
