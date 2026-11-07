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

let allServerEmotes = [];
let currentEmoteLimit = 120;

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
            const s = data.status || {};
            const p = s.permissions || {};
            const isO = s.isOwner === true;

            if (isO || p.view_players || p.player_teleport || p.dances_emotes || p.players) postNUI('fetchPlayers');
            if (isO || p.logs) postNUI('fetchLogs');
            if (isO || p.world_control || p.npc_control || p.world) postNUI('getNpcConfig');
            if (isO || p.spawn_items || p.items) postNUI('fetchAllItems');
            if (isO || p.spawn_vehicles || p.manage_assets || p.vehicles) postNUI('fetchAllVehicles');
            if (isO || p.manage_skins || p.characters) postNUI('fetchAllCharacters');
            if (isO || p.manage_jobs || p.jobs) postNUI('fetchAllJobs');
            if (isO || p.dances_emotes || p.manage_trolls || p.manage_skins || p.characters) postNUI('fetchAllEmotes');
            renderVisualItems();
            renderVisualVehicles();
            renderVisualCharacters();
            renderVisualJobs();
            if (typeof renderTpBookmarks === 'function') renderTpBookmarks();
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
            const inlineQuery = document.getElementById('manage-inline-ped-search')?.value || '';
            renderManageInlinePedGrid(inlineQuery);
        }
    } else if (data.action === 'updateAllEmotes') {
        if (data.emotes && Array.isArray(data.emotes) && data.emotes.length > 0) {
            allServerEmotes = data.emotes;
            const badge = document.getElementById('emote-total-badge');
            if (badge) badge.innerText = `${allServerEmotes.length.toLocaleString()} DANCES & EMOTES`;
            if (typeof renderEmotes === 'function') renderEmotes();
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
    } else if (data.action === 'syncNpcConfig') {
        if (data.config) {
            syncNpcConfigUI(data.config);
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

    // Dynamic Role-Based / Granular Permissions Tab Filtering (Master Tab + Sub-Perms)
    const perms = status.permissions || {};

    // Helper: check if user has ANY of these granular permission keys
    const hasAny = (...keys) => keys.some(k => perms[k] === true);

    // Granular tab → permission mapping:
    // If explicit master key `tab_<name>` is boolean (true/false), obey it directly!
    // Otherwise (legacy DB record without `tab_<name>`), fallback to checking sub-permissions.
    const checkTabVisible = (tabKey, ...fallbackSubKeys) => {
        const masterKey = `tab_${tabKey}`;
        if (typeof perms[masterKey] === 'boolean') {
            return perms[masterKey];
        }
        return hasAny(...fallbackSubKeys);
    };

    const TAB_PERM_MAP = {
        'dashboard':  () => checkTabVisible('dashboard', 'dash_metrics', 'self_actions', 'dash_self_veh', 'dash_self_tp', 'dash_self_cash', 'mass_actions', 'dash_purge_cops', 'dash_announce', 'dash_logs_feed', 'view_players', 'logs'),
        'god':        () => checkTabVisible('god', 'god_powers', 'noclip_power', 'admin_esp', 'combat_powers', 'veh_powers', 'god_self_utils', 'god_area_clean', 'self_actions', 'god'),
        'players':    () => checkTabVisible('players', 'view_players', 'players_view_money', 'players_btn_manage', 'player_teleport', 'player_spectate', 'player_freeze', 'player_heal', 'player_inventory', 'punish_kicks', 'punish_bans', 'players'),
        'manage':     () => checkTabVisible('manage', 'manage_tp', 'manage_freeze', 'manage_money', 'manage_give_item', 'manage_inv', 'manage_jobs', 'manage_heal', 'player_vehicles', 'manage_assets', 'manage_properties', 'player_clothing', 'manage_skins', 'manage_trolls', 'manage_force_dance', 'player_pm', 'manage_warn_kick', 'manage_ban', 'manage_wipes', 'view_players', 'player_teleport', 'player_heal', 'player_inventory', 'spawn_items', 'dances_emotes', 'punish_kicks', 'punish_bans', 'players'),
        'teleport':   () => checkTabVisible('teleport', 'world_teleport', 'tp_players', 'tp_locations', 'tp_bookmarks', 'tp_coords', 'player_teleport', 'teleport'),
        'items':      () => checkTabVisible('items', 'spawn_items', 'items_weapons', 'items_give_others', 'items_custom_spawn', 'items_weapon_tint', 'items'),
        'vehicles':   () => checkTabVisible('vehicles', 'spawn_vehicles', 'veh_manual_spawn', 'veh_workshop', 'veh_save_garage', 'vehicles'),
        'characters': () => checkTabVisible('characters', 'chars_catalog', 'chars_custom_hash', 'manage_skins', 'characters'),
        'jobs':       () => checkTabVisible('jobs', 'jobs_catalog', 'manage_jobs', 'jobs'),
        'arsenal':    () => checkTabVisible('arsenal', 'arsenal', 'arsenal_give_others', 'arsenal_economy'),
        'world':      () => checkTabVisible('world', 'world_control', 'world_announce', 'npc_control', 'world_props_cmd', 'world_offline_ban', 'world'),
        'devtools':   () => checkTabVisible('devtools', 'devtools', 'devtools_clean', 'devtools_skins'),
        'events':     () => checkTabVisible('events', 'events', 'events_custom'),
        'emotes':     () => checkTabVisible('emotes', 'dances_emotes', 'emotes_target_player', 'emotes_target_all'),
        'logs':       () => checkTabVisible('logs', 'logs'),
        'staff':      () => checkTabVisible('staff', 'staff_management', 'staff'),
    };

    let activeTabVisible = false;
    let firstVisibleNavBtn = null;

    document.querySelectorAll('.nav-item').forEach(btn => {
        const tab = btn.getAttribute('data-tab');
        if (!tab) return;

        if (status.isOwner) {
            btn.style.display = '';
            if (!firstVisibleNavBtn) firstVisibleNavBtn = btn;
            if (currentTab === tab) activeTabVisible = true;
            return;
        }

        const checker = TAB_PERM_MAP[tab];
        const hasPerm = checker ? checker() : false;
        btn.style.display = hasPerm ? '' : 'none';
        if (hasPerm && !firstVisibleNavBtn) {
            firstVisibleNavBtn = btn;
        }
        if (currentTab === tab && hasPerm) {
            activeTabVisible = true;
        }
    });

    // Hide sidebar section labels (.nav-section-label) if all nav items under them are hidden
    const sidebarMenu = document.querySelector('.sidebar-menu');
    if (sidebarMenu) {
        const children = Array.from(sidebarMenu.children);
        for (let i = 0; i < children.length; i++) {
            const el = children[i];
            if (el.classList.contains('nav-section-label')) {
                let anyVisibleInGroup = false;
                for (let j = i + 1; j < children.length; j++) {
                    if (children[j].classList.contains('nav-section-label')) break;
                    if (children[j].classList.contains('nav-item') && children[j].style.display !== 'none') {
                        anyVisibleInGroup = true;
                        break;
                    }
                }
                el.style.display = anyVisibleInGroup ? '' : 'none';
            }
        }
    }

    // Store active perms globally for filterPlayers & manage cards before switching tabs
    window._activePerms = perms;
    window._isOwner = status.isOwner;

    // If current active tab was hidden due to lack of permission, switch to first allowed tab
    if (!activeTabVisible && firstVisibleNavBtn) {
        firstVisibleNavBtn.click();
    }

    // Dynamic Manage tab cards + Dashboard + God Powers + Teleport + Items + Vehicles + World visibility
    renderManageSectionVisibility(perms, status.isOwner);
    renderAllPanesGranularVisibility(perms, status.isOwner);
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

        if (tab === 'dashboard') {
            const isO = window._isOwner === true;
            const p = window._activePerms || {};
            if (isO || p.view_players || p.players) postNUI('fetchPlayers');
            if (isO || p.logs) postNUI('fetchLogs');
            if (isO || p.world_control || p.npc_control || p.world) postNUI('getNpcConfig');
        } else if (tab === 'logs') {
            postNUI('fetchLogs');
        } else if (tab === 'players' || tab === 'teleport') {
            postNUI('fetchPlayers');
            if (tab === 'teleport' && typeof renderTpBookmarks === 'function') renderTpBookmarks();
        } else if (tab === 'manage') {
            postNUI('fetchPlayers');
            if (!allServerCharacters || allServerCharacters.length === 0) postNUI('fetchAllCharacters');
            if (!allServerVehicles || allServerVehicles.length === 0) postNUI('fetchAllVehicles');
            renderManagePlayerSelectorStrip('');
            renderManageInlinePedGrid('');
            const curTarget = document.getElementById('manage-target-id')?.value;
            if (!curTarget && onlinePlayersCache && onlinePlayersCache.length > 0) {
                selectManageTargetPlayer(onlinePlayersCache[0].id, onlinePlayersCache[0].name);
            } else if (curTarget) {
                postNUI('playerDetailedAction', { action: 'get_details', targetId: curTarget });
            }
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
        } else if (tab === 'world') {
            postNUI('getNpcConfig');
        } else if (tab === 'devtools') {
            postNUI('requestCoordsDisplay');
        } else if (tab === 'events') {
            checkEventState();
        } else if (tab === 'staff') {
            fetchStaffData();
        } else if (tab === 'emotes') {
            postNUI('fetchPlayers');
            if (!allServerEmotes || allServerEmotes.length === 0) postNUI('fetchAllEmotes');
            renderEmotes();
        }
    });
});

// Guaranteed Bulletproof Close Handler
function closePanel() {
    const app = document.getElementById('app');
    if (app) app.style.display = 'none';
    ['ban-modal', 'kick-modal', 'job-modal', 'staff-modal', 'ped-picker-modal', 'veh-picker-modal', 'player-manage-modal', 'player-info-modal', 'asset-action-modal'].forEach(id => {
        const m = document.getElementById(id);
        if (m) m.style.display = 'none';
    });
    postNUI('close');
}

document.getElementById('close-btn')?.addEventListener('click', (e) => {
    e.preventDefault();
    e.stopPropagation();
    closePanel();
});

window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        const modalIds = ['asset-action-modal', 'ped-picker-modal', 'veh-picker-modal', 'ban-modal', 'kick-modal', 'job-modal', 'staff-modal', 'player-info-modal', 'player-manage-modal'];
        for (const id of modalIds) {
            const m = document.getElementById(id);
            if (m && m.style.display !== 'none' && m.style.display !== '') {
                m.style.display = 'none';
                return;
            }
        }
        closePanel();
    }
});

// In-Panel High-Tech Floating Toast Notification System
window.showToast = function(title, message = '', type = 'info', duration = 3000) {
    const container = document.getElementById('toast-container');
    if (!container) return;

    const toast = document.createElement('div');
    toast.className = `toast-item toast-${type}`;

    const icons = {
        success: `<svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"></polyline></svg>`,
        error: `<svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>`,
        warning: `<svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>`,
        info: `<svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2.5"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line></svg>`
    };
    const icon = icons[type] || icons.info;

    toast.innerHTML = `
        <div class="toast-icon">${icon}</div>
        <div class="toast-content">
            <div class="toast-title">${title}</div>
            ${message ? `<div class="toast-message">${message}</div>` : ''}
        </div>
        <button class="toast-close" type="button">&times;</button>
        <div class="toast-progress" style="animation-duration: ${duration}ms"></div>
    `;

    toast.querySelector('.toast-close').addEventListener('click', () => {
        toast.classList.remove('toast-show');
        toast.classList.add('toast-hide');
        setTimeout(() => toast.remove(), 250);
    });

    container.appendChild(toast);
    requestAnimationFrame(() => toast.classList.add('toast-show'));

    setTimeout(() => {
        if (toast.parentElement) {
            toast.classList.remove('toast-show');
            toast.classList.add('toast-hide');
            setTimeout(() => toast.remove(), 250);
        }
    }, duration);
};

// Quick Actions with Instant Feedback
document.getElementById('qa-revive')?.addEventListener('click', () => {
    postNUI('quickAction', { action: 'revive' });
    showToast('Auto-Réanimation', 'Santé et réanimation appliquées.', 'success');
});
document.getElementById('qa-heal')?.addEventListener('click', () => {
    postNUI('quickAction', { action: 'heal' });
    showToast('Santé Maximale', 'Points de vie restaurés à 100%.', 'success');
});
document.getElementById('qa-armor')?.addEventListener('click', () => {
    postNUI('quickAction', { action: 'armor' });
    showToast('Gilet Pare-balles', 'Armure restaurée à 100%.', 'success');
});
document.getElementById('qa-repair')?.addEventListener('click', () => {
    postNUI('quickAction', { action: 'repair' });
    showToast('Réparation Véhicule', 'Moteur et carrosserie réparés.', 'success');
});
document.getElementById('qa-clean')?.addEventListener('click', () => {
    postNUI('quickAction', { action: 'clean' });
    showToast('Nettoyage Véhicule', 'Véhicule lavé et nettoyé.', 'success');
});
document.getElementById('qa-tpm')?.addEventListener('click', () => {
    postNUI('quickAction', { action: 'tpm' });
    showToast('Téléportation Waypoint', 'Téléporté au marqueur GPS.', 'info');
});
document.getElementById('qa-dv')?.addEventListener('click', () => {
    postNUI('quickAction', { action: 'dv' });
    showToast('Suppression Véhicule', 'Véhicule supprimé de la zone.', 'warning');
});
document.getElementById('qa-cash')?.addEventListener('click', () => {
    postNUI('giveMoney', { amount: 50000, moneyType: 'cash' });
    showToast('Injection Économie', '+50,000$ cash ajouté.', 'success');
});

// Full Super Powers Suite Toggles with Feedback
const registerToggle = (id, power) => {
    document.getElementById(id)?.addEventListener('change', (e) => {
        postNUI('togglePower', { power, state: e.target.checked });
        const pLabel = power.replace(/^is/, '').replace(/([A-Z])/g, ' $1').trim().toUpperCase();
        showToast(pLabel, e.target.checked ? 'Pouvoir activé' : 'Pouvoir désactivé', e.target.checked ? 'success' : 'info', 2200);
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

// Teleport Destinations & Map Waypoint
document.getElementById('btn-tp-waypoint')?.addEventListener('click', () => {
    postNUI('teleportWaypoint');
});

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
        emotes: new Set(JSON.parse(localStorage.getItem('sdev_fav_emotes') || '[]')),
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
    } else if (type === 'emotes') {
        renderEmotes();
    }
};

// Visual Items Rendering & Categories (Dynamic ox_inventory Catalog)
function renderVisualItems(searchQuery = '') {
    const container = document.getElementById('visual-items-container');
    if (!container) return;

    const sourceList = (allServerItems && allServerItems.length > 0) ? allServerItems : VISUAL_ITEMS;
    const q = searchQuery.toLowerCase().trim();
    const isSearching = q.length > 0;

    const gp = window._activePerms || {};
    const ow = window._isOwner || false;
    const allowGeneralItems = ow || gp.spawn_items === true || gp.items === true;
    const allowWeaponsAmmo  = ow || gp.items_weapons === true || (typeof gp.items_weapons === 'undefined' && allowGeneralItems);

    const filtered = sourceList.filter(item => {
        const itemName = item.name.toLowerCase();
        const itemLabel = (item.label || item.name).toLowerCase();
        const cat = (item.category || 'tool').toLowerCase();
        const isWeaponOrAmmo = cat === 'weapon' || cat === 'ammo' || itemName.startsWith('weapon_') || itemName.includes('ammo');

        // Sub-permission filtering inside Items & Weapons tab
        if (isWeaponOrAmmo && !allowWeaponsAmmo) return false;
        if (!isWeaponOrAmmo && !allowGeneralItems) return false;

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
    const targetId = document.getElementById('items-target-player-select')?.value;
    if (targetId) {
        postNUI('playerDetailedAction', { action: 'give_item_target', targetId: parseInt(targetId), item: itemName, count });
        showToast('Inventaire', `Don de ${count}x ${itemName} au joueur #${targetId}`, 'success');
    } else {
        postNUI('giveCustomItem', { item: itemName, count });
        showToast('Inventaire', `Ajout de ${count}x ${itemName} dans votre inventaire`, 'success');
    }
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
    const targetId = document.getElementById('items-target-player-select')?.value;
    if (itemName) {
        if (targetId) {
            postNUI('playerDetailedAction', { action: 'give_item_target', targetId: parseInt(targetId), item: itemName, count });
        } else {
            postNUI('giveCustomItem', { item: itemName, count });
        }
        input.value = '';
    }
});

// Vehicle & Character Image Handlers with Graceful Multi-Stage Fallback
window.handleVehImgError = function(img, model) {
    const stage = parseInt(img.getAttribute('data-stage') || '0', 10);
    if (stage === 0) {
        // Stage 1: Try local oxlyn-garage NUI resource (no external request)
        img.setAttribute('data-stage', '1');
        img.src = `https://cfx-nui-oxlyn-garage/images/vehicles/${model}.webp`;
    } else {
        // Stage 2: No more fallback — hide img, show placeholder box
        // (docs.fivem.net removed: external CDN would leak staff IPs)
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
    // No external CDN fallback — hide img immediately to avoid IP leaks
    img.onerror = null;
    img.style.display = 'none';
    const parent = img.parentElement;
    if (parent) {
        const placeholder = parent.querySelector('.ped-placeholder-box');
        if (placeholder) placeholder.style.display = 'flex';
    }
};

window.spawnVehicleDirect = function(model) {
    if (!model) return;
    const maxTune = document.getElementById('veh-max-tune')?.checked ?? true;
    postNUI('spawnVehicle', { model, maxTune });
    showToast('Véhicule Spawner', `Génération du modèle '${model.toUpperCase()}'...`, 'info', 2200);
};

window.applyPedDirect = function(model) {
    if (!model) return;
    postNUI('setPedModel', { model });
    showToast('Skin / Ped', `Apparence changée en '${model}'`, 'success', 2200);
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
    const targetId = document.getElementById('arsenal-target-player-select')?.value;
    postNUI('equipLoadout', { loadout, targetId: targetId ? parseInt(targetId) : null });
};

document.getElementById('btn-give-quick-cash')?.addEventListener('click', () => {
    const amt = parseInt(document.getElementById('quick-cash-amount')?.value) || 100000;
    postNUI('giveMoney', { amount: amt, moneyType: 'cash' });
});

document.getElementById('btn-give-quick-bank')?.addEventListener('click', () => {
    const amt = parseInt(document.getElementById('quick-cash-amount')?.value) || 100000;
    postNUI('giveMoney', { amount: amt, moneyType: 'bank' });
});

// ==========================================================================
// Smart Police NPC & Global Population Controller (JS)
// ==========================================================================
function syncNpcConfigUI(cfg) {
    if (!cfg) return;

    const copsBadge = document.getElementById('npc-real-cops-badge');
    if (copsBadge) {
        copsBadge.innerText = `👮 Policiers RP en service: ${cfg.realCopsOnDuty || 0}`;
    }

    const dashNpcState = document.getElementById('dash-npccop-state');
    if (dashNpcState) {
        if (cfg.policeNpcEnabled) {
            dashNpcState.innerText = cfg.autoMode ? 'AUTO (ON)' : 'ON';
            dashNpcState.style.color = '#00e676';
        } else {
            dashNpcState.innerText = cfg.autoMode ? 'COUPÉE (RP)' : 'OFF';
            dashNpcState.style.color = '#ff5252';
        }
    }

    const statusBadge = document.getElementById('npc-police-status-badge');
    if (statusBadge) {
        if (cfg.policeNpcEnabled) {
            statusBadge.className = 'npc-status-pill on';
            statusBadge.innerText = cfg.autoMode ? '🟢 Police NPC: ACTIVE (Auto)' : '🟢 Police NPC: ACTIVE (Manuel)';
        } else {
            statusBadge.className = 'npc-status-pill off';
            statusBadge.innerText = cfg.autoMode ? '🔴 Police NPC: COUPÉE (RP Actif)' : '🔴 Police NPC: DÉSACTIVÉE';
        }
    }

    const tPolice = document.getElementById('toggle-npc-police');
    if (tPolice) tPolice.checked = !!cfg.policeNpcEnabled;

    const tAuto = document.getElementById('toggle-npc-auto-mode');
    if (tAuto) tAuto.checked = !!cfg.autoMode;

    const tStars = document.getElementById('toggle-npc-stars');
    if (tStars) tStars.checked = !!cfg.wantedStarsEnabled;

    const tEms = document.getElementById('toggle-npc-ems');
    if (tEms) tEms.checked = !!cfg.emsNpcEnabled;

    const minCopsInput = document.getElementById('npc-min-cops-input');
    if (minCopsInput && cfg.minCopsThreshold !== undefined) {
        minCopsInput.value = cfg.minCopsThreshold;
    }

    if (cfg.pedDensity !== undefined) {
        const pPct = Math.round(cfg.pedDensity * 100);
        const sPed = document.getElementById('slider-ped-density');
        const lPed = document.getElementById('lbl-ped-density');
        if (sPed) sPed.value = pPct;
        if (lPed) lPed.innerText = `${pPct}%`;
    }

    if (cfg.trafficDensity !== undefined) {
        const tPct = Math.round(cfg.trafficDensity * 100);
        const sTraf = document.getElementById('slider-traffic-density');
        const lTraf = document.getElementById('lbl-traffic-density');
        if (sTraf) sTraf.value = tPct;
        if (lTraf) lTraf.innerText = `${tPct}%`;
    }

    if (cfg.parkedDensity !== undefined) {
        const pkPct = Math.round(cfg.parkedDensity * 100);
        const sPark = document.getElementById('slider-parked-density');
        const lPark = document.getElementById('lbl-parked-density');
        if (sPark) sPark.value = pkPct;
        if (lPark) lPark.innerText = `${pkPct}%`;
    }
}

document.getElementById('toggle-npc-police')?.addEventListener('change', (e) => {
    postNUI('updateNpcConfig', { policeNpcEnabled: e.target.checked, autoMode: false });
});

document.getElementById('toggle-npc-auto-mode')?.addEventListener('change', (e) => {
    const threshold = parseInt(document.getElementById('npc-min-cops-input')?.value) || 1;
    postNUI('updateNpcConfig', { autoMode: e.target.checked, minCopsThreshold: threshold });
});

document.getElementById('toggle-npc-stars')?.addEventListener('change', (e) => {
    postNUI('updateNpcConfig', { wantedStarsEnabled: e.target.checked });
});

document.getElementById('toggle-npc-ems')?.addEventListener('change', (e) => {
    postNUI('updateNpcConfig', { emsNpcEnabled: e.target.checked });
});

document.getElementById('btn-save-cops-threshold')?.addEventListener('click', () => {
    const threshold = parseInt(document.getElementById('npc-min-cops-input')?.value) || 1;
    postNUI('updateNpcConfig', { autoMode: true, minCopsThreshold: threshold });
});

window.setQuickCopsThreshold = function(val) {
    const input = document.getElementById('npc-min-cops-input');
    if (input) input.value = val;
    postNUI('updateNpcConfig', { autoMode: true, minCopsThreshold: val });
};

document.getElementById('btn-clean-npc-cops')?.addEventListener('click', () => {
    postNUI('cleanNpcCopsNow', {});
});

// Live Slider Labels
document.getElementById('slider-ped-density')?.addEventListener('input', (e) => {
    const lbl = document.getElementById('lbl-ped-density');
    if (lbl) lbl.innerText = `${e.target.value}%`;
});
document.getElementById('slider-traffic-density')?.addEventListener('input', (e) => {
    const lbl = document.getElementById('lbl-traffic-density');
    if (lbl) lbl.innerText = `${e.target.value}%`;
});
document.getElementById('slider-parked-density')?.addEventListener('input', (e) => {
    const lbl = document.getElementById('lbl-parked-density');
    if (lbl) lbl.innerText = `${e.target.value}%`;
});

document.getElementById('btn-apply-npc-sliders')?.addEventListener('click', () => {
    const pedD = (parseInt(document.getElementById('slider-ped-density')?.value) || 0) / 100.0;
    const trafD = (parseInt(document.getElementById('slider-traffic-density')?.value) || 0) / 100.0;
    const parkD = (parseInt(document.getElementById('slider-parked-density')?.value) || 0) / 100.0;
    postNUI('updateNpcConfig', { pedDensity: pedD, trafficDensity: trafD, parkedDensity: parkD });
});

// Traffic & NPC Population Density Quick Presets
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
document.getElementById('btn-copy-vec3')?.addEventListener('click', () => {
    postNUI('copyCoords', { format: 'vec3' });
    showToast('Coordonnées', 'Format vector3 copié dans le presse-papier.', 'success');
});
document.getElementById('btn-copy-vec4')?.addEventListener('click', () => {
    postNUI('copyCoords', { format: 'vec4' });
    showToast('Coordonnées', 'Format vector4 copié dans le presse-papier.', 'success');
});
document.getElementById('btn-copy-heading')?.addEventListener('click', () => {
    postNUI('copyCoords', { format: 'heading' });
    showToast('Orientation (Heading)', 'Cap copié dans le presse-papier.', 'success');
});

// Developer Tools: Area Cleaning
document.getElementById('btn-clear-veh')?.addEventListener('click', () => {
    postNUI('clearArea', { type: 'vehicles' });
    showToast('Nettoyage Zone', 'Véhicules abandonnés nettoyés.', 'warning');
});
document.getElementById('btn-clear-peds')?.addEventListener('click', () => {
    postNUI('clearArea', { type: 'peds' });
    showToast('Nettoyage Zone', 'PNJs errants nettoyés.', 'warning');
});
document.getElementById('btn-clear-props')?.addEventListener('click', () => {
    postNUI('clearArea', { type: 'props' });
    showToast('Nettoyage Zone', 'Objets et props nettoyés.', 'warning');
});
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

let currentPlayersRoleFilter = 'all';

window.setPlayersRoleFilter = function(role) {
    currentPlayersRoleFilter = role || 'all';
    document.querySelectorAll('#players-role-filters .picker-filter-btn').forEach(btn => {
        btn.classList.toggle('active', btn.getAttribute('data-role') === currentPlayersRoleFilter);
    });
    const q = document.getElementById('player-search')?.value.toLowerCase().trim() || '';
    filterPlayers(q);
};

function renderPlayers(players) {
    onlinePlayersCache = players || [];
    const countElem = document.getElementById('dash-player-count');
    if (countElem) countElem.innerText = onlinePlayersCache.length;
    const topbarPlayers = document.getElementById('topbar-players-count');
    if (topbarPlayers) topbarPlayers.innerText = `${onlinePlayersCache.length} ONLINE`;

    // Live RP Service & Duty Counters on Dashboard
    let copsCount = 0;
    let emsCount = 0;
    let mechCount = 0;
    onlinePlayersCache.forEach(p => {
        const j = (p.jobName || p.job || '').toLowerCase();
        const isDuty = p.onDuty !== false;
        if (isDuty && (j.includes('police') || j.includes('sheriff') || j.includes('bcso') || j.includes('sasp') || j.includes('trooper'))) {
            copsCount++;
        } else if (isDuty && (j.includes('ambulance') || j.includes('ems') || j.includes('doctor'))) {
            emsCount++;
        } else if (isDuty && (j.includes('mechanic') || j.includes('bennys') || j.includes('tuner'))) {
            mechCount++;
        }
    });
    const copsEl = document.getElementById('dash-cops-count');
    const emsEl = document.getElementById('dash-ems-count');
    const mechEl = document.getElementById('dash-mech-count');
    if (copsEl) copsEl.innerText = copsCount;
    if (emsEl) emsEl.innerText = emsCount;
    if (mechEl) mechEl.innerText = mechCount;

    // Populate Items & Arsenal Target Player Selectors
    ['items-target-player-select', 'arsenal-target-player-select'].forEach(selId => {
        const sel = document.getElementById(selId);
        if (!sel) return;
        const prevVal = sel.value;
        const defaultText = selId.includes('arsenal')
            ? '👤 Moi-même (Équiper sur mon personnage)'
            : '👤 Moi-même (Mon Inventaire)';
        sel.innerHTML = `<option value="">${defaultText}</option>`;
        onlinePlayersCache.forEach(p => {
            const opt = document.createElement('option');
            opt.value = p.id;
            opt.innerText = `#${p.id} — ${p.name} (${p.charName || p.job || 'Player'})`;
            if (String(p.id) === String(prevVal)) opt.selected = true;
            sel.appendChild(opt);
        });
    });

    // Populate Emotes Target Player Selector
    const emoteSel = document.getElementById('emote-target-select');
    if (emoteSel) {
        const prevEmoteVal = emoteSel.value || 'self';
        const gp = window._activePerms || {};
        const ow = window._isOwner || false;
        const canAllDance = ow || gp.mass_actions === true || gp.manage_trolls === true;
        const canTargetDance = ow || gp.manage_trolls === true || gp.dances_emotes === true;
        emoteSel.innerHTML = `<option value="self">👤 Moi-même (Mon Personnage)</option>`;
        if (canAllDance) {
            emoteSel.innerHTML += `<option value="all" ${prevEmoteVal === 'all' ? 'selected' : ''}>🌐 Tout le Serveur (Force Dance Party)</option>`;
        }
        if (canTargetDance) {
            onlinePlayersCache.forEach(p => {
                const opt = document.createElement('option');
                opt.value = p.id;
                opt.innerText = `🎯 #${p.id} — ${p.name} (${p.charName || p.job || 'Player'})`;
                if (String(p.id) === String(prevEmoteVal)) opt.selected = true;
                emoteSel.appendChild(opt);
            });
        }
    }

    const curSearch = document.getElementById('player-search')?.value.toLowerCase().trim() || '';
    filterPlayers(curSearch);
    filterTeleportPlayers('');
    renderManagePlayerSelectorStrip(document.getElementById('manage-player-quicksearch')?.value || '');

    // Auto-select first online player in Manage tab if none selected yet
    const curTarget = document.getElementById('manage-target-id')?.value;
    if (!curTarget && onlinePlayersCache.length > 0) {
        selectManageTargetPlayer(onlinePlayersCache[0].id, onlinePlayersCache[0].name);
    }
}

function filterPlayers(query) {
    const tbody = document.getElementById('player-table-body');
    if (!tbody) return;

    const filtered = onlinePlayersCache.filter(p => {
        const j = (p.jobName || p.job || '').toLowerCase();
        const g = (p.gangName || '').toLowerCase();
        const r = (p.role || 'NONE').toUpperCase();
        const isStaffMember = r !== 'NONE' && r !== 'USER' && r !== 'MEMBER' && r !== '';

        if (currentPlayersRoleFilter === 'police') {
            if (!(j.includes('police') || j.includes('sheriff') || j.includes('bcso') || j.includes('sasp'))) return false;
        } else if (currentPlayersRoleFilter === 'ems') {
            if (!(j.includes('ambulance') || j.includes('ems') || j.includes('doctor'))) return false;
        } else if (currentPlayersRoleFilter === 'gang') {
            if (!g || g === 'none') return false;
        } else if (currentPlayersRoleFilter === 'staff') {
            if (!isStaffMember) return false;
        }

        if (!query) return true;
        return (
            p.id.toString().includes(query) ||
            (p.name || '').toLowerCase().includes(query) ||
            (p.charName || '').toLowerCase().includes(query) ||
            (p.job || '').toLowerCase().includes(query) ||
            g.includes(query) ||
            r.toLowerCase().includes(query)
        );
    });

    if (filtered.length === 0) {
        tbody.innerHTML = '<tr><td colspan="7" class="table-empty">Aucun joueur correspondant en ligne.</td></tr>';
        return;
    }

    tbody.innerHTML = filtered.map(p => {
        const cashFormatted = `$${Number(p.cash || 0).toLocaleString()}`;
        const bankFormatted = `$${Number(p.bank || 0).toLocaleString()}`;
        const gangBadge = (p.gangName && p.gangName !== 'none')
            ? `<span class="role-badge" style="background: rgba(179,136,255,0.12); color: #b388ff; border-color: rgba(179,136,255,0.3); margin-left: 4px;">🔫 ${escapeHtml(p.gangName)}</span>`
            : '';
        const rUpper = (p.role || 'NONE').toUpperCase();
        const staffBadge = (rUpper !== 'NONE' && rUpper !== 'USER' && rUpper !== 'MEMBER' && rUpper !== '')
            ? `<span class="role-badge" style="background: rgba(255,215,0,0.15); color: #ffd700; border-color: rgba(255,215,0,0.4); margin-left: 4px;">🛡️ ${escapeHtml(rUpper)}</span>`
            : '';

        let statePill = `<span style="color: #00e676; font-weight: 700; font-size: 0.72rem;">🟢 À Pied</span>`;
        if (p.isFrozen) {
            statePill = `<span style="color: #38bdf8; font-weight: 800; font-size: 0.72rem;">❄️ Freezé</span>`;
        } else if (p.isDead) {
            statePill = `<span style="color: #ff5252; font-weight: 700; font-size: 0.72rem;">💀 Coma/Mort</span>`;
        } else if (p.inVehicle) {
            statePill = `<span style="color: #00e5ff; font-weight: 700; font-size: 0.72rem;">🚗 Véhicule</span>`;
        }

        const freezeBtnLabel = p.isFrozen ? '❄️ Unfreeze' : 'Freeze';
        const freezeBtnStyle = p.isFrozen ? 'background: rgba(56,189,248,0.22); border-color: #38bdf8; color: #38bdf8; font-weight: 800;' : '';

        // Granular permission-based button & money visibility inside Players tab
        const gp = window._activePerms || {};
        const ow = window._isOwner || false;
        const canSeeMoney = ow || gp.manage_money === true || gp.players_view_money === true;
        const canHeal     = ow || gp.player_heal === true || gp.players === true;
        const canInv      = ow || gp.player_inventory === true || gp.items === true;
        const canTp       = ow || gp.player_teleport === true || gp.teleport === true || gp.players === true;
        const canFreeze   = ow || gp.player_freeze === true || gp.players === true;
        const canSpectate = ow || gp.player_spectate === true || gp.players === true;
        const canKick     = ow || gp.punish_kicks === true || gp.punishments === true;
        const canBan      = ow || gp.punish_bans === true;
        const canInfo     = ow || gp.view_players === true || gp.players === true;
        const manageTabAllowed = ow || (typeof gp.tab_manage === 'boolean' ? gp.tab_manage : true);
        const canManage   = manageTabAllowed && (ow || gp.players_btn_manage === true || (typeof gp.players_btn_manage === 'undefined' && canInfo));

        const moneyCellHtml = canSeeMoney
            ? `<div style="font-size: 0.74rem; line-height: 1.3;">
                    <span style="color: #00e676; font-weight: 700;">💵 ${cashFormatted}</span><br>
                    <span style="color: #ffd700; font-weight: 600;">🏦 ${bankFormatted}</span>
               </div>`
            : `<span style="font-size: 0.72rem; color: var(--text-muted); font-style: italic;">🔒 Masqué</span>`;

        return `
        <tr>
            <td><strong>#${p.id}</strong></td>
            <td>${escapeHtml(p.name)} ${staffBadge}</td>
            <td>${escapeHtml(p.charName)}</td>
            <td>
                <span class="role-badge">${escapeHtml(p.job)}</span>
                ${gangBadge}
            </td>
            <td>
                ${moneyCellHtml}
            </td>
            <td>
                <div style="display: flex; flex-direction: column; gap: 2px;">
                    ${statePill}
                    <span style="font-size: 0.7rem; color: var(--text-muted);">${p.ping}ms</span>
                </div>
            </td>
            <td>
                <div class="player-actions" style="flex-wrap: wrap; gap: 4px;">
                    ${canManage ? `<button class="p-btn" style="background: var(--accent-cyan); color: #000; font-weight: 700; padding: 4px 10px;" onclick="openPlayerManageModal(${p.id}, '${escapeHtml(p.name)}')">⚡ Manage</button>` : ''}
                    ${canHeal ? `<button class="p-btn" style="background: rgba(0,230,118,0.16); color: #00e676; border: 1px solid rgba(0,230,118,0.35); font-weight: 700;" onclick="playerAction('heal', ${p.id})" title="Revive & Heal 100%">❤️ Revive</button>` : ''}
                    ${canInv ? `<button class="p-btn" style="background: rgba(250,204,21,0.14); color: #facc15; border: 1px solid rgba(250,204,21,0.35); font-weight: 700;" onclick="playerAction('open_inv', ${p.id})" title="Ouvrir Inventaire">🎒 Inv</button>` : ''}
                    ${canTp ? `<button class="p-btn goto" onclick="playerAction('goto', ${p.id})">Goto</button>` : ''}
                    ${canTp ? `<button class="p-btn bring" onclick="playerAction('bring', ${p.id})">Bring</button>` : ''}
                    ${canFreeze ? `<button class="p-btn freeze" style="${freezeBtnStyle}" onclick="playerAction('freeze', ${p.id})">${freezeBtnLabel}</button>` : ''}
                    ${canSpectate ? `<button class="p-btn spectate" onclick="playerAction('spectate', ${p.id})">Spectate</button>` : ''}
                    ${canManage ? `<button class="p-btn info" style="background: rgba(255,255,255,0.08); padding: 4px 8px;" onclick="openPlayerInfoModal(${p.id})">ℹ️ Info</button>` : ''}
                    ${canKick ? `<button class="p-btn kick" onclick="openKickModal(${p.id}, '${escapeHtml(p.name)}')">Kick</button>` : ''}
                    ${canBan ? `<button class="p-btn ban" onclick="openBanModal(${p.id}, '${escapeHtml(p.name)}')">Ban</button>` : ''}
                </div>
            </td>
        </tr>
    `;
    }).join('');
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
        openKickModal(targetId, name || `Player #${targetId}`);
    } else if (action === 'heal') {
        postNUI('playerDetailedAction', { action: 'heal', targetId });
        setTimeout(() => postNUI('fetchPlayers'), 350);
    } else if (action === 'open_inv') {
        postNUI('playerDetailedAction', { action: 'open_inv', targetId });
    } else if (action === 'clearinv') {
        postNUI('clearPlayerInventory', { targetId });
    } else if (action === 'freeze') {
        postNUI('freezePlayer', { targetId });
    } else if (action === 'spectate') {
        postNUI('spectatePlayer', { targetId });
    } else {
        postNUI('teleportAction', { action, targetId });
    }
};

// Kick Modal (Replaces blocked CEF window.prompt)
window.openKickModal = function(targetId, name) {
    const modal = document.getElementById('kick-modal');
    if (!modal) return;
    document.getElementById('kick-target-id').value = targetId;
    document.getElementById('kick-target-info').innerText = `ID: #${targetId} — ${name || 'Joueur'}`;
    const reasonInput = document.getElementById('kick-reason');
    if (reasonInput) reasonInput.value = 'Non-respect des règles du serveur';
    modal.style.display = 'flex';
    setTimeout(() => reasonInput?.focus(), 60);
};

document.getElementById('kick-modal-close')?.addEventListener('click', () => {
    const modal = document.getElementById('kick-modal');
    if (modal) modal.style.display = 'none';
});

document.getElementById('btn-cancel-kick')?.addEventListener('click', () => {
    const modal = document.getElementById('kick-modal');
    if (modal) modal.style.display = 'none';
});

document.getElementById('btn-confirm-kick')?.addEventListener('click', () => {
    const targetId = document.getElementById('kick-target-id')?.value;
    const reason = document.getElementById('kick-reason')?.value.trim() || 'Expulsé par le Staff';
    if (targetId) {
        postNUI('kickPlayer', { targetId: parseInt(targetId), reason });
    }
    const modal = document.getElementById('kick-modal');
    if (modal) modal.style.display = 'none';
});

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

// Dedicated Manage Player Full-Page Tab & Live Switcher
window.refreshManagePlayersBar = function() {
    postNUI('fetchPlayers');
    const curTarget = document.getElementById('manage-target-id')?.value;
    if (curTarget) {
        postNUI('playerDetailedAction', { action: 'get_details', targetId: curTarget });
    }
};

function renderManagePlayerSelectorStrip(searchQuery = '') {
    const strip = document.getElementById('manage-online-pills-strip');
    const topSelect = document.getElementById('manage-top-player-select');
    const curTargetId = document.getElementById('manage-target-id')?.value;
    const q = (searchQuery || '').toLowerCase().trim();

    if (topSelect) {
        topSelect.innerHTML = '<option value="">-- Choisir un joueur en ligne --</option>';
        onlinePlayersCache.forEach(p => {
            const opt = document.createElement('option');
            opt.value = p.id;
            opt.dataset.name = p.name;
            opt.innerText = `#${p.id} — ${p.name} (${p.charName || p.job || 'Player'})`;
            if (String(p.id) === String(curTargetId)) opt.selected = true;
            topSelect.appendChild(opt);
        });
    }

    if (!strip) return;

    const filtered = onlinePlayersCache.filter(p => {
        if (!q) return true;
        return (
            String(p.id).includes(q) ||
            (p.name || '').toLowerCase().includes(q) ||
            (p.charName || '').toLowerCase().includes(q) ||
            (p.job || '').toLowerCase().includes(q)
        );
    });

    if (filtered.length === 0) {
        strip.innerHTML = '<div style="font-size: 0.78rem; color: var(--text-muted); padding: 6px 10px;">Aucun joueur correspondant en ligne.</div>';
        return;
    }

    strip.innerHTML = filtered.map(p => {
        const isActive = String(p.id) === String(curTargetId);
        const initials = (p.name || 'P').substring(0, 2).toUpperCase();
        return `
            <button type="button" class="manage-player-pill ${isActive ? 'active' : ''}" onclick="selectManageTargetPlayer(${p.id}, '${escapeHtml(p.name)}')">
                <div class="manage-pill-avatar">${escapeHtml(initials)}</div>
                <div class="manage-pill-info">
                    <span class="manage-pill-name">#${p.id} ${escapeHtml(p.name)}</span>
                    <span class="manage-pill-sub">${escapeHtml(p.charName || 'Citoyen')} • ${escapeHtml(p.job || 'unemployed')}</span>
                </div>
            </button>
        `;
    }).join('');
}

document.getElementById('manage-player-quicksearch')?.addEventListener('input', (e) => {
    renderManagePlayerSelectorStrip(e.target.value);
});

document.getElementById('manage-top-player-select')?.addEventListener('change', (e) => {
    const val = e.target.value;
    if (!val) return;
    const found = onlinePlayersCache.find(p => String(p.id) === String(val));
    selectManageTargetPlayer(val, found ? found.name : `Player #${val}`);
});

window.selectManageTargetPlayer = function(targetId, targetName) {
    if (!targetId) return;
    const found = onlinePlayersCache.find(p => String(p.id) === String(targetId));
    const resolvedName = targetName || (found ? found.name : `Player #${targetId}`);

    const idInput = document.getElementById('manage-target-id');
    const nameInput = document.getElementById('manage-target-name');
    if (idInput) idInput.value = targetId;
    if (nameInput) nameInput.value = resolvedName;

    const nameDisp = document.getElementById('manage-target-name-display');
    const idBadge = document.getElementById('manage-target-id-badge');
    const avatarEl = document.getElementById('manage-target-avatar');
    const cidDisp = document.getElementById('manage-target-cid-display');

    if (nameDisp) nameDisp.innerText = resolvedName;
    if (idBadge) idBadge.innerText = `ID: #${targetId}`;
    if (avatarEl) avatarEl.innerText = (resolvedName || 'P').substring(0, 2).toUpperCase();
    if (cidDisp) cidDisp.innerText = 'Chargement des données joueur en direct...';

    // Update active state on pills & dropdown
    renderManagePlayerSelectorStrip(document.getElementById('manage-player-quicksearch')?.value || '');

    // Populate Friend / Online players dropdown (exclude current target)
    const select = document.getElementById('manage-friend-select');
    if (select) {
        select.innerHTML = '<option value="">-- Choisir un joueur connecté pour le transfert --</option>';
        onlinePlayersCache.forEach(p => {
            if (String(p.id) !== String(targetId)) {
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
    if (!allServerCharacters || allServerCharacters.length === 0) {
        postNUI('fetchAllCharacters');
    }
    if (!allServerVehicles || allServerVehicles.length === 0) {
        postNUI('fetchAllVehicles');
    }
    renderManageInlinePedGrid(document.getElementById('manage-inline-ped-search')?.value || '');

    // Fetch live details
    postNUI('playerDetailedAction', { action: 'get_details', targetId });
};

window.openPlayerManageModal = function(targetId, targetName) {
    const manageNavBtn = document.getElementById('nav-btn-manage') || document.querySelector('.nav-item[data-tab="manage"]');
    if (manageNavBtn) {
        manageNavBtn.click();
    }
    selectManageTargetPlayer(targetId, targetName);
    switchManageSection('all');
};

window.quickFillManageItem = function(item, count = 1) {
    const itemEl = document.getElementById('manage-item-name');
    const countEl = document.getElementById('manage-item-count');
    if (itemEl) itemEl.value = item;
    if (countEl) countEl.value = count;
    execPlayerDetailed('give_item_direct');
};

window.quickFillManageJob = function(job, grade = 0) {
    const jobEl = document.getElementById('manage-job-name');
    const gradeEl = document.getElementById('manage-job-grade');
    if (jobEl) jobEl.value = job;
    if (gradeEl) gradeEl.value = grade;
    execPlayerDetailed('set_job');
};

window.switchManageSection = function(sec) {
    document.querySelectorAll('#manage-subnav .manage-subnav-btn').forEach(btn => {
        btn.classList.toggle('active', btn.getAttribute('data-section') === sec);
    });
    const grid = document.getElementById('manage-sections-grid');
    const inlinePedGrid = document.getElementById('manage-inline-ped-grid');
    if (grid) {
        grid.style.gridTemplateColumns = (sec === 'all' || sec === 'sec-char') ? 'repeat(2, 1fr)' : '1fr';
    }
    if (inlinePedGrid) {
        inlinePedGrid.style.maxHeight = (sec === 'sec-skins') ? '560px' : '410px';
    }
    document.querySelectorAll('#manage-sections-grid .manage-sec-card').forEach(card => {
        if (sec === 'all') {
            // Show only cards not hidden by permissions
            card.style.display = card.dataset.permHidden === '1' ? 'none' : '';
        } else {
            const match = card.getAttribute('data-sec') === sec;
            card.style.display = (match && card.dataset.permHidden !== '1') ? '' : 'none';
        }
    });
};

// Granular Permission-Based Manage Card Visibility
// Hides entire cards, subnav tabs, and sub-buttons in the Manage tab based on what the staff member can actually do
function renderManageSectionVisibility(perms, isOwnerFlag) {
    if (!perms && !isOwnerFlag) return;
    const gp = perms || {};
    const ow = isOwnerFlag || false;
    const hasAny = (...keys) => ow || keys.some(k => gp[k] === true);

    const secRules = {
        'sec-tp':     () => hasAny('manage_tp', 'manage_freeze', 'player_teleport', 'player_freeze', 'manage_trolls', 'teleport', 'players'),
        'sec-econ':   () => hasAny('manage_money', 'manage_give_item', 'manage_inv', 'spawn_items', 'player_inventory', 'items'),
        'sec-char':   () => hasAny('manage_jobs', 'manage_heal', 'player_heal', 'god_powers', 'manage_trolls', 'jobs', 'players'),
        'sec-veh':    () => hasAny('player_vehicles', 'spawn_vehicles', 'vehicles'),
        'sec-assets': () => hasAny('manage_assets', 'manage_properties', 'vehicles', 'characters'),
        'sec-skins':  () => hasAny('manage_skins', 'player_clothing', 'characters'),
        'sec-trolls': () => hasAny('manage_trolls', 'manage_force_dance', 'manage_warn_kick', 'manage_ban', 'manage_wipes', 'punish_kicks', 'punish_bans', 'player_pm', 'dances_emotes', 'god'),
    };

    Object.entries(secRules).forEach(([secKey, checkFn]) => {
        const allowed = checkFn();
        document.querySelectorAll(`.manage-sec-card[data-sec="${secKey}"]`).forEach(c => {
            c.dataset.permHidden = allowed ? '0' : '1';
        });
        document.querySelectorAll(`#manage-subnav .manage-subnav-btn[data-section="${secKey}"]`).forEach(btn => {
            btn.style.display = allowed ? '' : 'none';
        });
    });

    // Apply now to currently visible cards
    const activeSecBtn = document.querySelector('#manage-subnav .manage-subnav-btn.active');
    const activeSec = activeSecBtn ? activeSecBtn.getAttribute('data-section') : 'all';
    document.querySelectorAll('#manage-sections-grid .manage-sec-card').forEach(card => {
        if (activeSec === 'all') {
            card.style.display = card.dataset.permHidden === '1' ? 'none' : '';
        } else {
            const match = card.getAttribute('data-sec') === activeSec;
            card.style.display = (match && card.dataset.permHidden !== '1') ? '' : 'none';
        }
    });

    // Individual button & sub-box gating: elements with data-requires-perm are hidden if
    // the staff member lacks that specific granular permission (supports comma-separated OR keys).
    document.querySelectorAll('[data-requires-perm]').forEach(el => {
        const raw = el.getAttribute('data-requires-perm') || '';
        const keys = raw.split(',').map(s => s.trim()).filter(Boolean);
        const allowed = ow || keys.some(k => gp[k] === true);
        el.style.display = allowed ? '' : 'none';
    });

    // Hide Cash/Bank chips in Dossier header if staff lacks manage_money & players_view_money
    const canSeeMoneyInDossier = hasAny('manage_money', 'players_view_money');
    const cashChip = document.getElementById('manage-live-cash')?.closest('.dossier-stat-chip');
    const bankChip = document.getElementById('manage-live-bank')?.closest('.dossier-stat-chip');
    if (cashChip) cashChip.style.display = canSeeMoneyInDossier ? '' : 'none';
    if (bankChip) bankChip.style.display = canSeeMoneyInDossier ? '' : 'none';
}

// Comprehensive Granular UI Visibility across ALL Panes (Dashboard, God, Teleport, Items, Vehicles, Characters, Jobs, Arsenal, World, DevTools, Events, Emotes)
function renderAllPanesGranularVisibility(perms, isOwnerFlag) {
    const gp = perms || {};
    const ow = isOwnerFlag || false;
    const hasAny = (...keys) => ow || keys.some(k => gp[k] === true);
    // Helper that checks explicit sub-key first if boolean, or falls back to legacy/shared keys
    const checkSub = (primaryKey, ...fallbackKeys) => {
        if (ow) return true;
        if (typeof gp[primaryKey] === 'boolean') return gp[primaryKey];
        return hasAny(...fallbackKeys);
    };
    const setVis = (el, show) => { if (el) el.style.display = show ? '' : 'none'; };

    // 1. DASHBOARD (#pane-dashboard)
    const canDashMetrics  = checkSub('dash_metrics', 'view_players', 'self_actions');
    const canSelfHeal     = checkSub('self_actions', 'player_heal', 'god_powers', 'god');
    const canSelfVeh      = checkSub('dash_self_veh', 'self_actions', 'spawn_vehicles', 'veh_powers', 'vehicles');
    const canSelfTp       = checkSub('dash_self_tp', 'world_teleport', 'self_actions', 'teleport');
    const canSelfCash     = checkSub('dash_self_cash', 'manage_money');
    const canMass         = checkSub('mass_actions', 'world_control', 'world');
    const canPurgeCops    = checkSub('dash_purge_cops', 'npc_control', 'mass_actions', 'world_control');
    const canDashAnnounce = checkSub('dash_announce', 'mass_actions', 'world_announce', 'world_control');
    const canDashLogs     = checkSub('dash_logs_feed', 'logs');

    setVis(document.querySelector('#pane-dashboard .metrics-grid'), canDashMetrics);
    setVis(document.querySelector('#pane-dashboard .dash-services-strip'), canDashMetrics);

    ['qa-revive', 'qa-heal', 'qa-armor'].forEach(id => setVis(document.getElementById(id), canSelfHeal));
    ['qa-repair', 'qa-clean', 'qa-dv'].forEach(id => setVis(document.getElementById(id), canSelfVeh));
    setVis(document.getElementById('qa-tpm'), canSelfTp);
    setVis(document.getElementById('qa-cash'), canSelfCash);

    const qaCard = document.getElementById('qa-revive')?.closest('.section-card');
    if (qaCard) {
        setVis(qaCard, canSelfHeal || canSelfVeh || canSelfTp || canSelfCash);
    }

    const dashMassCard = document.getElementById('dash-quick-announce')?.closest('.section-card');
    if (dashMassCard) {
        dashMassCard.querySelectorAll('.quick-actions-grid button').forEach(btn => {
            const oc = btn.getAttribute('onclick') || '';
            if (oc.includes('cleanNpcCopsNow')) {
                setVis(btn, canPurgeCops);
            } else {
                setVis(btn, canMass);
            }
        });
        const announceRow = document.getElementById('dash-quick-announce')?.parentElement;
        setVis(announceRow, canDashAnnounce);
        setVis(dashMassCard, canMass || canPurgeCops || canDashAnnounce);
    }

    const dashLogsCard = document.getElementById('dash-recent-logs')?.closest('.section-card');
    setVis(dashLogsCard, canDashLogs);

    // 2. GOD POWERS & SELF TOOLS (#pane-god)
    const godTogglePerms = {
        'toggle-godmode':     () => hasAny('god_powers', 'god'),
        'toggle-invis':       () => hasAny('god_powers', 'god'),
        'toggle-wanted':      () => hasAny('god_powers', 'npc_control', 'god'),
        'toggle-thermal':     () => hasAny('god_powers', 'admin_esp', 'god'),
        'toggle-nightvision': () => hasAny('god_powers', 'admin_esp', 'god'),
        'toggle-antiragdoll': () => hasAny('god_powers', 'god'),
        'toggle-infoxygen':   () => hasAny('god_powers', 'god'),
        'toggle-infstamina':  () => hasAny('god_powers', 'god'),
        'toggle-fastswim':    () => hasAny('god_powers', 'god'),
        'toggle-hidehud':     () => hasAny('devtools', 'god_powers', 'self_actions', 'god'),
        'toggle-noclip':      () => hasAny('noclip_power', 'god_powers', 'god'),
        'toggle-noclip2':     () => hasAny('noclip_power', 'god_powers', 'god'),
        'toggle-admintag':    () => hasAny('admin_esp', 'god_powers', 'god'),
        'toggle-names':       () => hasAny('admin_esp', 'god_powers', 'god'),
        'toggle-blips':       () => hasAny('admin_esp', 'god_powers', 'god'),
        'toggle-minimap':     () => hasAny('admin_esp', 'god_powers', 'god'),
        'toggle-coordshud':   () => hasAny('admin_esp', 'devtools', 'god_powers', 'god'),
        'toggle-ammo':        () => hasAny('combat_powers', 'god_powers', 'god'),
        'toggle-infammo':     () => hasAny('combat_powers', 'god_powers', 'god'),
        'toggle-damage':      () => hasAny('combat_powers', 'god_powers', 'god'),
        'toggle-sprint':      () => hasAny('combat_powers', 'god_powers', 'god'),
        'toggle-jump':        () => hasAny('combat_powers', 'god_powers', 'god'),
        'toggle-exppunch':    () => hasAny('combat_powers', 'god_powers', 'god'),
        'toggle-expammo':     () => hasAny('combat_powers', 'god_powers', 'god'),
        'toggle-vehgod':      () => hasAny('veh_powers', 'god_powers', 'god'),
        'toggle-vehboost':    () => hasAny('veh_powers', 'god_powers', 'god'),
        'toggle-vehjump':     () => hasAny('veh_powers', 'god_powers', 'god'),
        'toggle-vehdrift':    () => hasAny('veh_powers', 'god_powers', 'god'),
        'toggle-autoflip':    () => hasAny('veh_powers', 'god_powers', 'god'),
        'toggle-inspector':   () => hasAny('devtools', 'god_powers', 'god'),
        'toggle-blackout':    () => hasAny('world_control', 'god_powers', 'world', 'god'),
    };

    let anyGodToggleVisible = false;
    Object.entries(godTogglePerms).forEach(([inputId, checkFn]) => {
        const el = document.getElementById(inputId);
        const card = el?.closest('.toggle-card') || el?.closest('.power-toggle-card');
        const vis = checkFn();
        setVis(card, vis);
        if (vis && card?.closest('#pane-god')) anyGodToggleVisible = true;
    });
    const godFirstCard = document.querySelector('#pane-god .section-card:first-child');
    setVis(godFirstCard, anyGodToggleVisible);

    const canGodUtils = checkSub('god_self_utils', 'self_actions', 'veh_powers', 'god_powers');
    const canGodArea  = checkSub('god_area_clean', 'devtools_clean', 'devtools', 'mass_actions', 'god_powers');

    const godBtnPerms = {
        'btn-clothes-menu':  () => canGodUtils || hasAny('player_clothing', 'manage_skins'),
        'btn-bennys-tune':   () => canGodUtils || hasAny('veh_powers', 'spawn_vehicles'),
        'btn-refuel-tank':   () => canGodUtils || hasAny('veh_powers', 'spawn_vehicles'),
        'btn-clean-ped':     () => canGodUtils || hasAny('self_actions', 'player_heal'),
        'btn-flip-car':      () => canGodUtils || hasAny('veh_powers', 'spawn_vehicles'),
        'btn-fix-wash-car':  () => canGodUtils || hasAny('veh_powers', 'spawn_vehicles'),
        'btn-toggle-duty':   () => canGodUtils || hasAny('manage_jobs', 'self_actions'),
        'btn-remove-stress': () => canGodUtils || hasAny('self_actions', 'player_heal'),
        'btn-revive-radius': () => canGodArea || hasAny('player_heal', 'mass_actions'),
        'btn-revive-all':    () => canGodArea || hasAny('mass_actions', 'world_control'),
        'btn-veh-lock':      () => canGodUtils || hasAny('veh_powers', 'spawn_vehicles'),
        'btn-veh-unlock':    () => canGodUtils || hasAny('veh_powers', 'spawn_vehicles'),
        'btn-veh-engine':    () => canGodUtils || hasAny('veh_powers', 'spawn_vehicles'),
        'btn-veh-freeze':    () => canGodUtils || hasAny('veh_powers', 'spawn_vehicles'),
    };
    let anyGodBtnVisible = false;
    Object.entries(godBtnPerms).forEach(([btnId, checkFn]) => {
        const vis = checkFn();
        setVis(document.getElementById(btnId), vis);
        if (vis) anyGodBtnVisible = true;
    });
    // Also handle area clear buttons inside #pane-god
    document.querySelectorAll('#pane-god #btn-clear-veh, #pane-god #btn-clear-peds, #pane-god #btn-clear-props').forEach(btn => {
        setVis(btn, canGodArea);
        if (canGodArea) anyGodBtnVisible = true;
    });
    const godSecondCard = document.getElementById('btn-clothes-menu')?.closest('.section-card');
    setVis(godSecondCard, anyGodBtnVisible);

    // 3. TELEPORT (#pane-teleport)
    const canTpWaypoint  = checkSub('world_teleport', 'teleport');
    const canTpPlayers   = checkSub('tp_players', 'player_teleport', 'teleport', 'players');
    const canTpLocations = checkSub('tp_locations', 'world_teleport', 'teleport');
    const canTpBookmarks = checkSub('tp_bookmarks', 'world_teleport', 'teleport');
    const canTpCoords    = checkSub('tp_coords', 'world_teleport', 'teleport');

    setVis(document.getElementById('btn-tp-waypoint')?.closest('.section-card'), canTpWaypoint);
    setVis(document.getElementById('tp-players-container')?.closest('.section-card'), canTpPlayers);
    setVis(document.querySelector('#pane-teleport .teleport-btn[data-loc="legion"]')?.closest('.section-card'), canTpLocations);
    setVis(document.getElementById('tp-bookmarks-container')?.closest('.section-card'), canTpBookmarks);
    setVis(document.getElementById('tp-x')?.closest('.section-card'), canTpCoords);

    // 4. ITEMS & WEAPONS (#pane-items)
    const canItemsGeneral = checkSub('spawn_items', 'items');
    const canItemsWeapons = checkSub('items_weapons', 'spawn_items', 'items');
    const canItemsOthers  = checkSub('items_give_others', 'manage_give_item', 'player_inventory', 'spawn_items');
    const canItemsCustom  = checkSub('items_custom_spawn', 'spawn_items', 'items');
    const canItemsTint    = checkSub('items_weapon_tint', 'items_weapons', 'combat_powers', 'arsenal');

    setVis(document.getElementById('visual-items-container')?.closest('.section-card'), canItemsGeneral || canItemsWeapons);
    setVis(document.getElementById('items-target-player-select'), canItemsOthers);
    setVis(document.querySelector('#pane-items .filter-chip[data-cat="weapon"]'), canItemsWeapons);
    setVis(document.querySelector('#pane-items .filter-chip[data-cat="ammo"]'), canItemsWeapons);
    setVis(document.querySelector('#pane-items .filter-chip[data-cat="food"]'), canItemsGeneral);
    setVis(document.querySelector('#pane-items .filter-chip[data-cat="medical"]'), canItemsGeneral);
    setVis(document.querySelector('#pane-items .filter-chip[data-cat="tool"]'), canItemsGeneral);
    setVis(document.getElementById('custom-item-name')?.closest('.section-card'), canItemsCustom);
    setVis(document.querySelector('#pane-items button[onclick*="upgradeCurrentWeapon"]')?.closest('.section-card'), canItemsTint);
    if (currentTab === 'items') {
        renderVisualItems(document.getElementById('item-search-input')?.value || '');
    }

    // 5. VEHICLES & WORKSHOP (#pane-vehicles)
    const canVehShowcase = checkSub('spawn_vehicles', 'vehicles');
    const canVehManual   = checkSub('veh_manual_spawn', 'spawn_vehicles', 'vehicles');
    const canVehWorkshop = checkSub('veh_workshop', 'veh_powers', 'spawn_vehicles', 'vehicles');
    const canVehSaveGar  = checkSub('veh_save_garage', 'manage_assets', 'spawn_vehicles');

    setVis(document.getElementById('visual-vehicles-container')?.closest('.section-card'), canVehShowcase);
    setVis(document.getElementById('veh-model-input')?.closest('.section-card'), canVehManual);
    setVis(document.getElementById('veh-plate-input')?.closest('.section-card'), canVehWorkshop || canVehSaveGar);
    setVis(document.querySelector('#pane-vehicles button[onclick*="saveCurrentVehToMyGarage"]'), canVehSaveGar);

    // 6. CHARACTERS & SKINS (#pane-characters)
    const canCharsCatalog = checkSub('chars_catalog', 'manage_skins', 'characters');
    const canCharsCustom  = checkSub('chars_custom_hash', 'manage_skins', 'characters');
    setVis(document.getElementById('visual-characters-container')?.closest('.section-card'), canCharsCatalog);
    setVis(document.getElementById('btn-apply-custom-skin')?.closest('.section-card'), canCharsCustom);

    // 7. JOBS & RANKS (#pane-jobs)
    const canJobsCatalog = checkSub('jobs_catalog', 'manage_jobs', 'jobs');
    setVis(document.getElementById('visual-jobs-container')?.closest('.section-card'), canJobsCatalog);

    // 8. OWNER ARSENAL (#pane-arsenal)
    const canArsenalKits   = checkSub('arsenal');
    const canArsenalOthers = checkSub('arsenal_give_others', 'arsenal');
    const canArsenalEcon   = checkSub('arsenal_economy', 'manage_money');
    setVis(document.querySelector('#pane-arsenal .arsenal-grid')?.closest('.section-card'), canArsenalKits);
    setVis(document.getElementById('arsenal-target-player-select'), canArsenalOthers);
    setVis(document.getElementById('quick-cash-amount')?.closest('.section-card'), canArsenalEcon);

    // 9. WORLD & WEATHER (#pane-world)
    const canWorldTimeWeather = checkSub('world_control', 'world');
    const canWorldAnnounce    = checkSub('world_announce', 'world_control', 'mass_actions', 'world');
    const canWorldNpc         = checkSub('npc_control', 'world_control', 'world');
    const canWorldPropsCmd    = checkSub('world_props_cmd', 'devtools');
    const canWorldOfflineBan  = checkSub('world_offline_ban', 'punish_bans');

    setVis(document.querySelector('#pane-world button[data-time-h]')?.closest('.section-card'), canWorldTimeWeather);
    setVis(document.querySelector('#pane-world .weather-btn')?.closest('.section-card'), canWorldTimeWeather);
    setVis(document.getElementById('broadcast-msg-input')?.closest('.section-card'), canWorldAnnounce);
    setVis(document.getElementById('toggle-npc-police')?.closest('.section-card'), canWorldNpc);
    setVis(document.getElementById('slider-ped-density')?.closest('.section-card'), canWorldNpc);
    setVis(document.getElementById('prop-model-input')?.closest('.section-card'), canWorldPropsCmd);
    setVis(document.getElementById('custom-click-input')?.closest('.section-card'), canWorldPropsCmd);
    setVis(document.getElementById('stash-id-input')?.closest('.section-card'), canWorldPropsCmd);
    setVis(document.getElementById('offline-ban-id')?.closest('.section-card'), canWorldOfflineBan);

    // 10. DEV TOOLS (#pane-devtools)
    const canDevInspector = checkSub('devtools');
    const canDevClean     = checkSub('devtools_clean', 'devtools', 'mass_actions');
    const canDevSkins     = checkSub('devtools_skins', 'manage_skins', 'devtools');
    setVis(document.getElementById('btn-copy-vec3')?.closest('.section-card'), canDevInspector);
    setVis(document.querySelector('#pane-devtools #btn-clear-all')?.closest('.section-card'), canDevClean);
    setVis(document.getElementById('btn-apply-skin')?.closest('.section-card'), canDevSkins);
    setVis(document.querySelector('#pane-devtools #toggle-inspector')?.closest('.section-card'), canDevInspector);

    // 11. EVENT MANAGER (#pane-events)
    const canEventsPresets = checkSub('events');
    const canEventsCustom  = checkSub('events_custom', 'events');
    const eventPresetGrid = document.querySelector('#pane-events button[onclick*="launchPresetEvent"]')?.closest('.quick-actions-grid');
    setVis(eventPresetGrid, canEventsPresets);
    setVis(eventPresetGrid?.previousElementSibling, canEventsPresets);
    const customEventTitleInput = document.getElementById('custom-event-title');
    if (customEventTitleInput) {
        const customEventRow1 = customEventTitleInput.closest('div[style*="grid-template-columns"]');
        const customEventHeader = customEventRow1?.previousElementSibling;
        const customEventMsg = document.getElementById('custom-event-msg')?.closest('.form-group');
        const customEventRow2 = document.getElementById('custom-event-loc')?.closest('div[style*="grid-template-columns"]');
        const customEventBtnRow = document.getElementById('btn-launch-custom-event')?.parentElement;
        [customEventHeader, customEventRow1, customEventMsg, customEventRow2, customEventBtnRow].forEach(el => setVis(el, canEventsCustom));
    }

    // 12. DANCES & EMOTES (#pane-emotes)
    const canEmotesTargetPlayer = checkSub('emotes_target_player', 'manage_force_dance', 'dances_emotes');
    const canEmotesTargetAll    = checkSub('emotes_target_all', 'mass_actions');
    const emoteTargetSel = document.getElementById('emote-target-select');
    if (emoteTargetSel) {
        setVis(emoteTargetSel, canEmotesTargetPlayer || canEmotesTargetAll);
        const allOpt = emoteTargetSel.querySelector('option[value="all"]');
        if (allOpt) allOpt.style.display = canEmotesTargetAll ? '' : 'none';
    }
}

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
    } else if (action === 'barber_menu') {
        payload = { action: 'appearance_control', targetId, appType: 'barber_menu' };
    } else if (action === 'reload_skin') {
        payload = { action: 'appearance_control', targetId, appType: 'reload_skin' };
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
    } else if (action === 'give_property') {
        const propId = document.getElementById('manage-giveprop-select')?.value;
        if (!propId) {
            alert('Veuillez choisir une propriété / maison dans la liste déroulante !');
            return;
        }
        payload = { action: 'give_property', targetId, propertyId: parseInt(propId) };
    }

    postNUI('playerDetailedAction', payload);

    // Auto-refresh live dossier stats after state-modifying actions
    if (['money_give', 'money_remove', 'money_set', 'set_job', 'set_gang', 'give_owned_vehicle', 'give_property', 'give_item_direct', 'clear_inv', 'wipe'].includes(action)) {
        setTimeout(() => {
            if (targetId) {
                postNUI('playerDetailedAction', { action: 'get_details', targetId });
                postNUI('fetchPlayers');
            }
        }, 450);
    }
};

window.execManageInvItem = function(mode, itemName, count = 1, slot = null) {
    const targetId = document.getElementById('manage-target-id')?.value;
    if (!targetId || !itemName) return;
    if (mode === 'give') {
        postNUI('playerDetailedAction', { action: 'give_item_target', targetId, item: itemName, count });
    } else if (mode === 'remove') {
        postNUI('playerDetailedAction', { action: 'remove_item_target', targetId, item: itemName, count, slot });
    }
    setTimeout(() => {
        postNUI('playerDetailedAction', { action: 'get_details', targetId });
    }, 350);
};

// Render Player Owned Assets (Vehicles, Properties & Live Pocket Inventory)
function renderPlayerAssets(d) {
    const countBadge = document.getElementById('manage-assets-count');
    const vehBox = document.getElementById('manage-vehicles-container');
    const propBox = document.getElementById('manage-properties-container');
    const invGrid = document.getElementById('manage-live-inventory-grid');
    const invCountBadge = document.getElementById('manage-live-inv-count');
    const propSelect = document.getElementById('manage-giveprop-select');

    const vehs = d.vehicles || [];
    const props = d.properties || [];
    const inv = d.inventory || [];
    const availProps = d.availableProperties || [];

    if (countBadge) {
        countBadge.innerText = `${vehs.length} Voitures • ${props.length} Maisons`;
    }

    // Render Live Pocket Inventory Grid in Card 02
    if (invCountBadge) {
        invCountBadge.innerText = `${inv.length} Items`;
    }
    if (invGrid) {
        if (inv.length === 0) {
            invGrid.innerHTML = '<div class="asset-empty-state" style="grid-column: 1 / -1; padding: 12px;">🎒 Les poches de ce joueur sont actuellement vides.</div>';
        } else {
            invGrid.innerHTML = inv.map(it => {
                const iName = (it.name || '').toLowerCase();
                const iLabel = it.label || it.name;
                const imgSrc = `https://cfx-nui-ox_inventory/web/images/${iName}.png`;
                const fallbackSrc = `nui://ox_inventory/web/images/${iName}.png`;
                return `
                    <div class="live-inv-slot-card" title="Slot #${it.slot} — ${escapeHtml(iLabel)} (${escapeHtml(iName)})">
                        <span class="live-inv-count-tag">x${it.count}</span>
                        <img class="live-inv-img" src="${imgSrc}" onerror="this.onerror=null; this.src='${fallbackSrc}'; this.onerror=function(){ this.style.display='none'; };">
                        <div class="live-inv-label">${escapeHtml(iLabel)}</div>
                        <div class="live-inv-actions">
                            <button type="button" class="live-inv-btn add" onclick="execManageInvItem('give', '${escapeHtml(iName)}', 1)" title="Ajouter +1">+1</button>
                            <button type="button" class="live-inv-btn del" onclick="execManageInvItem('remove', '${escapeHtml(iName)}', ${it.count}, ${it.slot})" title="Retirer cet item des poches">🗑️</button>
                        </div>
                    </div>
                `;
            }).join('');
        }
    }

    // Populate Available Properties Select in Card 05
    if (propSelect) {
        propSelect.innerHTML = '<option value="">-- Choisir une propriété serveur à attribuer au joueur --</option>';
        availProps.forEach(ap => {
            const ownerTag = ap.owner ? ` (Possédé: ${ap.owner})` : ' (Libre - En vente)';
            const opt = document.createElement('option');
            opt.value = ap.id;
            opt.innerText = `#${ap.id} — ${ap.property_name || 'Propriété'} ($${Number(ap.price || 0).toLocaleString()})${ownerTag}`;
            propSelect.appendChild(opt);
        });
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
                        <div class="asset-item-actions" style="display: flex; flex-wrap: wrap; gap: 4px; justify-content: flex-end; max-width: 520px;">
                            <button class="asset-action-btn btn-keys" onclick="execAssetAction('give_keys', { targetId: ${d.id}, plate: '${escapeHtml(plateText)}', model: '${escapeHtml(vModel)}' })" title="Donner les clés au joueur et à vous-même">🔑 Clés</button>
                            <button class="asset-action-btn btn-bring" onclick="execAssetAction('bring_veh', { targetId: ${d.id}, plate: '${escapeHtml(plateText)}', model: '${escapeHtml(vModel)}' })" title="Téléporter ou sortir la voiture devant vous">📍 Bring</button>
                            <button class="asset-action-btn btn-tp" onclick="execAssetAction('store_veh', { targetId: ${d.id}, plate: '${escapeHtml(plateText)}' })" title="Ranger la voiture au garage (State = 1)">📥 Garage</button>
                            <button class="asset-action-btn btn-stash" onclick="execAssetAction('open_veh_trunk', { targetId: ${d.id}, plate: '${escapeHtml(plateText)}', model: '${escapeHtml(vModel)}' })" title="Ouvrir le coffre (Trunk)">🧰 Coffre</button>
                            <button class="asset-action-btn btn-stash" onclick="execAssetAction('open_veh_glovebox', { targetId: ${d.id}, plate: '${escapeHtml(plateText)}', model: '${escapeHtml(vModel)}' })" title="Ouvrir la boîte à gants">📂 G-Box</button>
                            <button class="asset-action-btn btn-repair" onclick="execAssetAction('repair_veh', { targetId: ${d.id}, plate: '${escapeHtml(plateText)}' })" title="Réparer & Laver à 100%">🔧 Réparer</button>
                            <button class="asset-action-btn btn-transfer" onclick="execAssetAction('transfer_veh', { targetId: ${d.id}, plate: '${escapeHtml(plateText)}', model: '${escapeHtml(vModel)}' })" title="Transférer la voiture à un autre joueur">🔄 Transférer</button>
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
                const khList = Array.isArray(p.keyholders) ? p.keyholders : [];
                const khEncoded = encodeURIComponent(JSON.stringify(khList));
                const ownershipLabel = p.isKeyholderOnly ? '🔑 Accès Clé (Double)' : (isRent ? 'Location' : 'Propriété Définitive');
                const ownershipColor = p.isKeyholderOnly ? 'gold' : (isRent ? 'orange' : 'green');
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
                                    <span class="asset-tag ${ownershipColor}">${ownershipLabel}</span>
                                    <span class="asset-tag">🔑 ${khList.length} Double(s)</span>
                                    ${p.interior ? `<span class="asset-tag">Inter: ${escapeHtml(p.interior)}</span>` : ''}
                                </div>
                            </div>
                        </div>
                        <div class="asset-item-actions" style="display: flex; flex-wrap: wrap; gap: 4px; justify-content: flex-end; max-width: 520px;">
                            <button class="asset-action-btn btn-stash" onclick="execAssetAction('open_house_stash', { targetId: ${d.id}, propertyId: ${p.id}, propertyName: '${escapeHtml(p.property_name)}' })" title="Ouvrir le coffre / stash de cette maison">📦 Coffre</button>
                            <button class="asset-action-btn btn-tp" onclick="execAssetAction('tp_property', { targetId: ${d.id}, propertyId: ${p.id} })" title="Se téléporter à l'entrée de cette maison">📍 TP Maison</button>
                            <button class="asset-action-btn btn-keys" onclick="execAssetAction('give_property_key', { targetId: ${d.id}, propertyId: ${p.id}, name: '${escapeHtml(p.property_name || '#' + p.id)}', keyholders: '${khEncoded}' })" title="Donner un double des clés de cette maison à un joueur">🔑 Donner Clé</button>
                            <button class="asset-action-btn btn-repair" onclick="execAssetAction('reset_property_keys', { targetId: ${d.id}, propertyId: ${p.id}, name: '${escapeHtml(p.property_name || '#' + p.id)}' })" title="Réinitialiser tous les doubles de clés">🧹 Reset Clés</button>
                            <button class="asset-action-btn btn-transfer" onclick="execAssetAction('transfer_property', { targetId: ${d.id}, propertyId: ${p.id}, name: '${escapeHtml(p.property_name || '#' + p.id)}' })" title="Transférer la propriété à un autre joueur">🔄 Transférer</button>
                            <button class="asset-action-btn btn-danger" onclick="execAssetAction('seize_property', { targetId: ${d.id}, propertyId: ${p.id}, name: '${escapeHtml(p.property_name || '#' + p.id)}', citizenid: '${escapeHtml(d.citizenid)}' })" title="Saisir la maison et la remettre en vente">🏠 Saisir</button>
                        </div>
                    </div>
                `;
            }).join('');
        }
    }
}

// Patrimoine Interactive Modal State & Controllers (Replaces blocked CEF prompt/confirm)
let pendingAssetModalAction = null;

function populateAssetModalPlayers(excludeId) {
    const sel = document.getElementById('asset-modal-player-select');
    const idInput = document.getElementById('asset-modal-player-id');
    if (!sel) return;
    sel.innerHTML = '<option value="">-- Choisir un joueur connecté --</option>';
    (onlinePlayersCache || []).forEach(p => {
        const opt = document.createElement('option');
        opt.value = p.id;
        opt.innerText = `[#${p.id}] ${p.charName || p.name} (${p.citizenid || 'Online'})`;
        sel.appendChild(opt);
    });
    if (idInput) idInput.value = '';
}

window.openAssetActionModal = function(config) {
    pendingAssetModalAction = config;
    const modal = document.getElementById('asset-action-modal');
    const titleEl = document.getElementById('asset-modal-title');
    const descEl = document.getElementById('asset-modal-desc');
    const playerBox = document.getElementById('asset-modal-player-box');
    const khBox = document.getElementById('asset-modal-keyholders-box');
    const khListEl = document.getElementById('asset-modal-keyholders-list');
    const confirmBtn = document.getElementById('asset-modal-confirm-btn');

    if (!modal) return;
    if (titleEl) titleEl.innerText = config.title || 'Action Patrimoine';
    if (descEl) descEl.innerHTML = config.desc || '';
    if (playerBox) {
        playerBox.style.display = config.requirePlayer ? 'flex' : 'none';
        if (config.requirePlayer) populateAssetModalPlayers(config.targetId);
    }
    if (khBox && khListEl) {
        if (config.keyholders && config.keyholders.length > 0) {
            khBox.style.display = 'flex';
            khListEl.innerHTML = config.keyholders.map(cid => `<span class="asset-tag gold" style="padding: 3px 8px;">🔑 ${escapeHtml(String(cid))}</span>`).join('');
        } else {
            khBox.style.display = 'none';
            khListEl.innerHTML = '';
        }
    }
    if (confirmBtn) {
        confirmBtn.innerText = config.confirmText || '✅ Confirmer';
        confirmBtn.className = config.danger ? 'primary-btn danger-btn' : 'primary-btn';
    }
    modal.style.display = 'flex';
};

window.closeAssetActionModal = function() {
    pendingAssetModalAction = null;
    const modal = document.getElementById('asset-action-modal');
    if (modal) modal.style.display = 'none';
};

window.confirmAssetActionModal = function() {
    if (!pendingAssetModalAction) return;
    const cfg = pendingAssetModalAction;
    if (cfg.requirePlayer) {
        const chosenId = parseInt(document.getElementById('asset-modal-player-id')?.value || document.getElementById('asset-modal-player-select')?.value);
        if (!chosenId || isNaN(chosenId)) {
            const idInput = document.getElementById('asset-modal-player-id');
            if (idInput) idInput.style.borderColor = '#ff3366';
            return;
        }
        cfg.onConfirm(chosenId);
    } else if (cfg.onConfirm) {
        cfg.onConfirm();
    }
    closeAssetActionModal();
};

// Global Asset Action Dispatcher (Houses & Cars Full Control)
window.execAssetAction = function(action, params) {
    if (action === 'seize_vehicle') {
        openAssetActionModal({
            title: `🗑️ Saisir le Véhicule [${params.plate}]`,
            desc: `Êtes-vous sûr de vouloir <strong>SAISIR et SUPPRIMER définitivement</strong> le véhicule <strong>[${escapeHtml(params.plate)}]</strong> de ce joueur ?<br><br>• Supprimé de son garage (player_vehicles)<br>• S'il est sorti en ville, il sera supprimé<br>• Les clés seront révoquées`,
            requirePlayer: false,
            danger: true,
            confirmText: '🗑️ Confirmer la Saisie',
            onConfirm: () => postNUI('playerDetailedAction', { action: 'seize_vehicle', ...params })
        });
    } else if (action === 'seize_property') {
        openAssetActionModal({
            title: `🏠 Saisir la Propriété "${params.name}"`,
            desc: `Êtes-vous sûr de vouloir <strong>SAISIR et RÉVOQUER</strong> la propriété <strong>"${escapeHtml(params.name)}"</strong> ?<br><br>• Le joueur perdra son statut de propriétaire<br>• Tous les doubles de clés seront révoqués<br>• La maison sera remise en vente`,
            requirePlayer: false,
            danger: true,
            confirmText: '🏠 Confirmer la Saisie',
            onConfirm: () => postNUI('playerDetailedAction', { action: 'seize_property', ...params })
        });
    } else if (action === 'give_keys') {
        postNUI('playerDetailedAction', { action: 'give_keys', ...params });
    } else if (action === 'store_veh') {
        postNUI('playerDetailedAction', { action: 'store_veh', ...params });
    } else if (action === 'open_house_stash') {
        postNUI('playerDetailedAction', { action: 'open_house_stash', ...params });
    } else if (action === 'tp_property') {
        postNUI('playerDetailedAction', { action: 'tp_property', ...params });
    } else if (action === 'give_property_key') {
        let khList = [];
        try { khList = JSON.parse(decodeURIComponent(params.keyholders || '[]')); } catch (e) {}
        openAssetActionModal({
            title: `🔑 Donner un Double des Clés — ${params.name}`,
            desc: `Sélectionnez le joueur connecté à qui vous souhaitez donner un <strong>double officiel des clés</strong> pour la propriété <strong>"${escapeHtml(params.name)}"</strong> (accès porte + coffre maison).`,
            requirePlayer: true,
            keyholders: khList,
            danger: false,
            confirmText: '🔑 Donner la Clé',
            onConfirm: (toPlayerId) => postNUI('playerDetailedAction', { action: 'give_property_key', targetId: params.targetId, propertyId: params.propertyId, toPlayerId })
        });
    } else if (action === 'reset_property_keys') {
        openAssetActionModal({
            title: `🧹 Réinitialiser les Clés — ${params.name || 'Propriété'}`,
            desc: `Confirmer la révocation de <strong>TOUS les doubles de clés</strong> de cette propriété ?<br>Seul le propriétaire principal conservera l'accès.`,
            requirePlayer: false,
            danger: true,
            confirmText: '🧹 Révoquer les Doubles',
            onConfirm: () => postNUI('playerDetailedAction', { action: 'reset_property_keys', ...params })
        });
    } else if (action === 'transfer_property') {
        openAssetActionModal({
            title: `🔄 Transférer la Propriété — ${params.name || '#' + params.propertyId}`,
            desc: `Sélectionnez le <strong>nouveau propriétaire</strong> pour la maison <strong>"${escapeHtml(params.name || '#' + params.propertyId)}"</strong>.<br>L'acte de propriété et l'accès au coffre lui seront transférés immédiatement.`,
            requirePlayer: true,
            danger: false,
            confirmText: '🔄 Transférer la Maison',
            onConfirm: (toPlayerId) => postNUI('playerDetailedAction', { action: 'transfer_property', targetId: params.targetId, propertyId: params.propertyId, toPlayerId })
        });
    } else if (action === 'open_veh_trunk') {
        postNUI('playerDetailedAction', { action: 'open_veh_trunk', ...params });
    } else if (action === 'open_veh_glovebox') {
        postNUI('playerDetailedAction', { action: 'open_veh_glovebox', ...params });
    } else if (action === 'bring_veh') {
        postNUI('playerDetailedAction', { action: 'bring_veh', ...params });
    } else if (action === 'repair_veh') {
        postNUI('playerDetailedAction', { action: 'repair_veh', ...params });
    } else if (action === 'transfer_veh') {
        openAssetActionModal({
            title: `🔄 Transférer le Véhicule [${params.plate}]`,
            desc: `Sélectionnez le <strong>nouveau propriétaire</strong> pour le véhicule <strong>${escapeHtml((params.model || '').toUpperCase())} [${escapeHtml(params.plate)}]</strong>.<br>La carte grise (garage) et les clés lui seront transférées immédiatement.`,
            requirePlayer: true,
            danger: false,
            confirmText: '🔄 Transférer le Véhicule',
            onConfirm: (toPlayerId) => postNUI('playerDetailedAction', { action: 'transfer_veh', targetId: params.targetId, plate: params.plate, toPlayerId })
        });
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

let currentInlinePedFilter = 'popular';
const POPULAR_RP_PEDS = [
    { model: 'mp_m_freemode_01', label: 'MP Freemode Homme', category: 'multiplayer' },
    { model: 'mp_f_freemode_01', label: 'MP Freemode Femme', category: 'multiplayer' },
    { model: 'player_zero', label: 'Michael De Santa', category: 'vip' },
    { model: 'player_one', label: 'Franklin Clinton', category: 'vip' },
    { model: 'player_two', label: 'Trevor Philips', category: 'vip' },
    { model: 's_m_y_cop_01', label: 'Officier Police LSPD', category: 'emergency' },
    { model: 's_f_y_cop_01', label: 'Officière Police LSPD', category: 'emergency' },
    { model: 's_m_y_sheriff_01', label: 'Sheriff Deputy', category: 'emergency' },
    { model: 's_m_y_swat_01', label: 'Unité SWAT Tactique', category: 'emergency' },
    { model: 's_m_y_hwaycop_01', label: 'Police Autoroute Moto', category: 'emergency' },
    { model: 's_m_m_paramedic_01', label: 'Ambulancier EMS', category: 'emergency' },
    { model: 's_m_m_doctor_01', label: 'Chirurgien / Docteur', category: 'emergency' },
    { model: 's_m_y_fireman_01', label: 'Sapeur-Pompier', category: 'emergency' },
    { model: 's_m_m_fiboffice_01', label: 'Agent Spécial FBI', category: 'emergency' },
    { model: 's_m_m_ciasec_01', label: 'Agent Secret CIA', category: 'emergency' },
    { model: 's_m_m_highsec_01', label: 'Garde du Corps VIP', category: 'civilian' },
    { model: 's_m_m_armoured_01', label: 'Convoyeur de Fonds', category: 'civilian' },
    { model: 'g_m_y_ballasout_01', label: 'Gangster Ballas', category: 'gang' },
    { model: 'g_m_y_famca_01', label: 'Gangster Families', category: 'gang' },
    { model: 'g_m_y_mexgoon_01', label: 'Membre Cartel Vagos', category: 'gang' },
    { model: 'g_m_y_lost_01', label: 'Biker The Lost MC', category: 'gang' },
    { model: 'g_m_m_chiboss_01', label: 'Boss Triade / Mafia', category: 'gang' },
    { model: 'ig_lestercrest', label: 'Lester Crest (Hacker)', category: 'vip' },
    { model: 'ig_lamardavis', label: 'Lamar Davis', category: 'vip' },
    { model: 'ig_avon', label: 'Avon Hertz (Milliardaire)', category: 'vip' },
    { model: 's_m_y_dealer_01', label: 'Dealer de Rue', category: 'gang' },
    { model: 's_m_y_xmech_01', label: 'Chef Mécanicien', category: 'civilian' },
    { model: 'a_c_chop', label: 'Chien Rottweiler (Chop)', category: 'animal' },
    { model: 'a_c_shepherd', label: 'Berger Allemand K9', category: 'animal' },
    { model: 'a_c_husky', label: 'Chien Husky', category: 'animal' },
    { model: 'a_c_rottweiler', label: 'Rottweiler Garde', category: 'animal' },
    { model: 'a_c_mtlion', label: 'Puma / Lion des Montagnes', category: 'animal' },
];

function renderManageInlinePedGrid(searchQuery = '') {
    const grid = document.getElementById('manage-inline-ped-grid');
    const countBadge = document.getElementById('manage-inline-ped-count');
    if (!grid) return;

    const fullList = (allServerCharacters && allServerCharacters.length > 0) ? allServerCharacters : VISUAL_PEDS;
    const q = searchQuery.toLowerCase().trim();
    const isSearching = q.length > 0;

    let filtered = [];
    if (isSearching) {
        filtered = fullList.filter(p => {
            const model = (p.model || '').toLowerCase();
            const label = (p.label || '').toLowerCase();
            const cat = (p.category || '').toLowerCase();
            return model.includes(q) || label.includes(q) || cat.includes(q);
        });
    } else if (currentInlinePedFilter === 'popular') {
        filtered = POPULAR_RP_PEDS;
    } else {
        filtered = fullList.filter(p => {
            const cat = (p.category || '').toLowerCase();
            if (currentInlinePedFilter === 'all') return true;
            if (currentInlinePedFilter === 'vip') return cat === 'vip' || cat === 'story';
            if (currentInlinePedFilter === 'emergency') return cat === 'emergency';
            if (currentInlinePedFilter === 'gang') return cat === 'gang' || cat === 'gangs';
            if (currentInlinePedFilter === 'civilian') return cat === 'civilian' || cat === 'male' || cat === 'female';
            if (currentInlinePedFilter === 'animal') return cat === 'animal' || cat === 'animals';
            if (currentInlinePedFilter === 'multiplayer') return cat === 'multiplayer';
            return true;
        });
    }

    if (countBadge) {
        countBadge.innerText = `${fullList.length} Peds (${filtered.length} affichés)`;
    }

    if (filtered.length === 0) {
        grid.innerHTML = '<div class="asset-empty-state" style="grid-column: 1 / -1;">Aucun Ped trouvé pour cette recherche.</div>';
        return;
    }

    const displaySlice = filtered.slice(0, 120);
    grid.innerHTML = displaySlice.map(p => {
        const model = (p.model || '').toLowerCase();
        const label = p.label || model;
        const imgFiveM = `https://docs.fivem.net/peds/${model}.webp`;
        const isAnimal = p.category === 'animal' || p.category === 'animals';
        return `
            <div class="inline-ped-card" onclick="selectPedModel('${escapeHtml(model)}', '${escapeHtml(label)}')" title="Cliquez pour appliquer ${escapeHtml(label)} (${escapeHtml(model)})">
                <div class="inline-ped-img-box">
                    <img src="${imgFiveM}" loading="lazy" onerror="this.onerror=null; this.style.display='none'; this.nextElementSibling.style.display='flex';" alt="${escapeHtml(label)}">
                    <div style="display: none; align-items: center; justify-content: center; font-size: 36px;">${isAnimal ? '🐾' : '👤'}</div>
                </div>
                <div class="inline-ped-name">${escapeHtml(label)}</div>
                <div class="inline-ped-code">${escapeHtml(model)}</div>
                <div class="inline-ped-apply-badge">🎭 Appliquer Skin</div>
            </div>
        `;
    }).join('');
}

document.getElementById('manage-inline-ped-search')?.addEventListener('input', (e) => {
    renderManageInlinePedGrid(e.target.value);
});

document.querySelectorAll('#manage-inline-ped-filters .picker-filter-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        document.querySelectorAll('#manage-inline-ped-filters .picker-filter-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        currentInlinePedFilter = btn.getAttribute('data-filter') || 'popular';
        const q = document.getElementById('manage-inline-ped-search')?.value || '';
        renderManageInlinePedGrid(q);
    });
});

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

// Logs Rendering & Live Audit Feed
let auditLogsCache = [];

function renderAuditLogs(logs) {
    if (Array.isArray(logs)) {
        auditLogsCache = logs;
    }

    const container = document.getElementById('logs-container');
    const dashFeed = document.getElementById('dash-recent-logs');
    const searchQuery = document.getElementById('logs-search-input')?.value.toLowerCase().trim() || '';

    // 1. Update Dashboard Mini Feed (Top 6 Recent Actions)
    if (dashFeed) {
        if (!auditLogsCache || auditLogsCache.length === 0) {
            dashFeed.innerHTML = '<div style="font-size: 0.78rem; color: var(--text-muted); padding: 8px;">Aucune action enregistrée récemment.</div>';
        } else {
            dashFeed.innerHTML = auditLogsCache.slice(0, 6).map(l => `
                <div style="display: flex; align-items: center; justify-content: space-between; gap: 10px; background: rgba(255,255,255,0.03); border: 1px solid rgba(255,255,255,0.06); border-radius: 7px; padding: 6px 10px; font-size: 0.75rem;">
                    <div style="display: flex; align-items: center; gap: 8px; overflow: hidden;">
                        <span style="color: ${l.status === 'SUCCESS' ? '#00e676' : '#ff5252'}; font-weight: 800;">●</span>
                        <strong style="color: var(--accent-cyan); white-space: nowrap;">${escapeHtml(l.action)}</strong>
                        <span style="color: var(--text-secondary); white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">
                            par <b>${escapeHtml(l.executor_name)}</b> ${l.target_name ? `→ <b>${escapeHtml(l.target_name)}</b>` : ''}
                        </span>
                    </div>
                    <span style="color: var(--text-muted); font-size: 0.68rem; white-space: nowrap;">${escapeHtml(l.timestamp || '')}</span>
                </div>
            `).join('');
        }
    }

    // 2. Update Main Security Logs Container with Instant Filter
    if (!container) return;

    const filtered = (auditLogsCache || []).filter(l => {
        if (!searchQuery) return true;
        return (
            (l.action || '').toLowerCase().includes(searchQuery) ||
            (l.executor_name || '').toLowerCase().includes(searchQuery) ||
            (l.target_name || '').toLowerCase().includes(searchQuery) ||
            (l.status || '').toLowerCase().includes(searchQuery) ||
            String(l.id || '').includes(searchQuery)
        );
    });

    if (filtered.length === 0) {
        container.innerHTML = '<div class="log-entry">Aucun log correspondant trouvé.</div>';
        return;
    }

    container.innerHTML = filtered.map(l => `
        <div class="log-entry">
            <strong>[#${l.id}] ${l.timestamp}</strong> — <span style="color: var(--accent-cyan)">${escapeHtml(l.action)}</span>
            <br>Executor: ${escapeHtml(l.executor_name)} (${escapeHtml(l.executor_license)})
            ${l.target_name ? `<br>Target: ${escapeHtml(l.target_name)} (${escapeHtml(l.target_license || 'N/A')})` : ''}
            <br>Status: <span style="color: ${l.status === 'SUCCESS' ? 'var(--accent-green)' : 'var(--accent-red)'}">${escapeHtml(l.status)}</span>
        </div>
    `).join('');
}

document.getElementById('logs-search-input')?.addEventListener('input', () => {
    renderAuditLogs(auditLogsCache);
});

// Dashboard Mass Server Actions & Quick Announce
window.execMassServerAction = function(massType) {
    postNUI('massServerAction', { massType });
};

window.sendDashQuickAnnounce = function() {
    const input = document.getElementById('dash-quick-announce');
    const msg = input?.value.trim();
    if (!msg) return;
    postNUI('broadcastAnnouncement', { message: msg });
    input.value = '';
};

// Save Current Vehicle to My Garage (1-Click)
window.saveCurrentVehToMyGarage = function() {
    postNUI('saveMyCurrentVehicle', { garage: 'motel' });
};

// Custom Teleport Bookmarks (LocalStorage + Live Coords)
window.renderTpBookmarks = function() {
    const container = document.getElementById('tp-bookmarks-container');
    if (!container) return;
    const list = JSON.parse(localStorage.getItem('sdev_tp_bookmarks') || '[]');
    if (list.length === 0) {
        container.innerHTML = '<span style="font-size: 0.74rem; color: var(--text-muted);">Aucun favori enregistré. Entrez X/Y/Z ou un nom ci-dessus pour sauvegarder un point.</span>';
        return;
    }
    container.innerHTML = list.map((b, idx) => `
        <div style="display: inline-flex; align-items: center; gap: 4px; background: rgba(0,229,255,0.1); border: 1px solid rgba(0,229,255,0.28); border-radius: 7px; padding: 4px 8px;">
            <button type="button" onclick="tpToSavedBookmark(${b.x}, ${b.y}, ${b.z})" style="background: none; border: none; color: #fff; font-weight: 700; font-size: 0.74rem; cursor: pointer;">
                📍 ${escapeHtml(b.name)}
            </button>
            <button type="button" onclick="deleteTpBookmark(${idx})" style="background: none; border: none; color: #ff5252; font-weight: 800; font-size: 0.74rem; cursor: pointer; padding-left: 4px;" title="Supprimer">✕</button>
        </div>
    `).join('');
};

window.saveCurrentTpBookmark = function() {
    const nameInput = document.getElementById('tp-bookmark-name');
    const name = nameInput?.value.trim() || `Spot #${Math.floor(Math.random() * 900 + 100)}`;
    const x = parseFloat(document.getElementById('tp-x')?.value);
    const y = parseFloat(document.getElementById('tp-y')?.value);
    const z = parseFloat(document.getElementById('tp-z')?.value);

    if (isNaN(x) || isNaN(y) || isNaN(z)) {
        alert('Veuillez renseigner les coordonnées X, Y, Z ci-dessus pour sauvegarder ce point dans vos favoris !');
        return;
    }
    const list = JSON.parse(localStorage.getItem('sdev_tp_bookmarks') || '[]');
    list.push({ name, x, y, z });
    localStorage.setItem('sdev_tp_bookmarks', JSON.stringify(list));
    if (nameInput) nameInput.value = '';
    renderTpBookmarks();
};

window.tpToSavedBookmark = function(x, y, z) {
    postNUI('teleportCoords', { x, y, z });
};

window.deleteTpBookmark = function(idx) {
    const list = JSON.parse(localStorage.getItem('sdev_tp_bookmarks') || '[]');
    list.splice(idx, 1);
    localStorage.setItem('sdev_tp_bookmarks', JSON.stringify(list));
    renderTpBookmarks();
};

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

// =========================================================================
// Staff & Tab-by-Tab Granular Permissions Studio
// =========================================================================
let cachedStaffList = [];
let cachedOnlinePlayers = [];
let staffViewMode = 'members'; // 'members' = ga3 les joueurs, 'staff' = only staff
let currentStaffRoleFilter = 'all';
let currentPermStudioTabFilter = 'all';

// Complete 16-Tab Schema: Master Tab Visibility (`tab_*`) + Per-Tab Sub-Permissions
const STAFF_TAB_SCHEMA = [
    {
        tab: 'dashboard',
        masterKey: 'tab_dashboard',
        icon: '📊',
        title: 'Dashboard (Tableau de Bord)',
        subtitle: 'Statistiques serveur, actions rapides personnelles, mass actions et live feed',
        color: '#00e5ff',
        subs: [
            { key: 'dash_metrics',    title: '📈 Compteurs & Services RP',       desc: 'Voir les compteurs (Joueurs en ligne, Police/EMS/Mécano en service)' },
            { key: 'self_actions',    title: '❤️ Soins Rapides (Self)',          desc: 'Boutons Revive Self, Heal & Feed, Max Armor (100)' },
            { key: 'dash_self_veh',   title: '🔧 Véhicule Rapide (Self)',        desc: 'Boutons Repair Vehicle, Clean Vehicle, Delete Vehicle (DV)' },
            { key: 'dash_self_tp',    title: '📍 TP to Waypoint (Self)',         desc: 'Bouton rapide Dashboard pour se téléporter au marqueur GPS' },
            { key: 'dash_self_cash',  title: '💵 Give $50,000 Cash (Self)',      desc: 'Bouton rapide pour se donner $50,000 Cash', badge: 'ÉCONOMIE', badgeType: 'warn' },
            { key: 'mass_actions',    title: '🌐 Actions Globales (Mass)',       desc: 'Revive Tout le Serveur, Heal & Nourrir Tous, Purger Voitures Vides', badge: 'GLOBAL', badgeType: 'warn' },
            { key: 'dash_purge_cops', title: '🚔 Purger Police NPC',             desc: 'Bouton pour supprimer immédiatement tous les policiers PNJ' },
            { key: 'dash_announce',   title: '📢 Annonce Rapide Serveur',        desc: 'Envoyer une annonce globale à tout le serveur depuis le Dashboard' },
            { key: 'dash_logs_feed',  title: '🛡️ Flux d\'Activité Staff (Feed)', desc: 'Voir les 6 dernières actions staff en direct sur le Dashboard' }
        ]
    },
    {
        tab: 'players',
        masterKey: 'tab_players',
        icon: '👥',
        title: 'Players (Liste des Joueurs)',
        subtitle: 'Tableau des joueurs en ligne, soldes Cash/Banque et boutons d\'action rapide sur chaque ligne',
        color: '#38bdf8',
        subs: [
            { key: 'view_players',       title: '👁️ Voir Liste & Bouton Info',   desc: 'Afficher les joueurs connectés, ping, métier, gang et fiche Info' },
            { key: 'players_view_money', title: '💵 Voir Cash & Banque',         desc: 'Afficher la colonne Cash / Banque dans la liste des joueurs', badge: 'CONFIDENTIEL', badgeType: 'warn' },
            { key: 'players_btn_manage', title: '⚡ Bouton « Manage »',          desc: 'Bouton pour ouvrir le joueur dans l\'onglet Manage Player' },
            { key: 'player_heal',        title: '❤️ Bouton Revive / Heal',       desc: 'Réanimer et soigner un joueur en 1 clic depuis la liste' },
            { key: 'player_inventory',   title: '🎒 Bouton Inventaire (Inv)',    desc: 'Ouvrir et fouiller l\'inventaire du joueur depuis la liste' },
            { key: 'player_teleport',    title: '🚀 Boutons Goto & Bring',       desc: 'Se téléporter vers le joueur (Goto) ou l\'amener à soi (Bring)' },
            { key: 'player_freeze',      title: '❄️ Bouton Freeze / Unfreeze',   desc: 'Immobiliser ou débloquer un joueur sur place' },
            { key: 'player_spectate',    title: '🔭 Bouton Spectate',            desc: 'Observer un joueur à distance avec caméra OneSync' },
            { key: 'punish_kicks',       title: '👢 Bouton Kick (Expulser)',     desc: 'Expulser un joueur du serveur avec raison', badge: 'SANCTION', badgeType: 'warn' },
            { key: 'punish_bans',        title: '🚫 Bouton Ban (Bannir)',        desc: 'Bannir temporairement ou définitivement un joueur', badge: 'DANGER', badgeType: 'danger' }
        ]
    },
    {
        tab: 'manage',
        masterKey: 'tab_manage',
        icon: '⚡',
        title: 'Manage Player (Studio Gestion Joueur)',
        subtitle: 'Contrôle détaillé d\'un joueur : TP amis, argent, poches, job, garage, maisons, skins, trolls, kick, ban & wipes',
        color: '#00e676',
        subs: [
            { key: 'manage_tp',          title: '🚀 1. Téléport & Amis',            desc: 'Envoyer chez un ami, Goto, Bring, TP Hôpital Pillbox / Place Legion' },
            { key: 'manage_freeze',      title: '❄️ 1B. Freeze dans Manage',        desc: 'Geler ou dégeler le joueur sélectionné depuis sa fiche Manage' },
            { key: 'manage_money',       title: '💰 2. Donner / Retirer Argent',    desc: 'Ajouter, retirer ou fixer le Cash & la Banque du joueur', badge: 'ÉCONOMIE', badgeType: 'danger' },
            { key: 'manage_give_item',   title: '📦 2B. Donner un Item au Joueur',  desc: 'Donner un item ox_inventory directement dans les poches du joueur' },
            { key: 'manage_inv',         title: '🎒 3. Poches en Direct & Coffres', desc: 'Voir ses poches en direct, retirer un item, ouvrir coffre/boîte à gants ou vider' },
            { key: 'manage_jobs',        title: '💼 4. Changer Métier & Gang',      desc: 'Attribuer un Job, un Gang et le Grade au joueur' },
            { key: 'manage_heal',        title: '❤️ 5. Santé, Armure & Besoins',    desc: 'Heal & Revive, 100% Armure, 100% Faim/Soif, Zéro Stress' },
            { key: 'player_vehicles',    title: '🚘 6. Contrôle Véhicule Actuel',   desc: 'Donner clés, réparer, Max Tune, éjecter, crever pneus ou supprimer sa voiture' },
            { key: 'manage_assets',      title: '🚗 6B. Patrimoine : Garage DB',    desc: 'Voir ses voitures DB, donner un véhicule officiel (+ carte grise), transférer ou saisir', badge: 'PATRIMOINE', badgeType: 'warn' },
            { key: 'manage_properties',  title: '🏠 6C. Patrimoine : Maisons DB',   desc: 'Voir ses maisons, ouvrir coffre maison, donner clés, attribuer ou saisir propriété', badge: 'PATRIMOINE', badgeType: 'warn' },
            { key: 'player_clothing',    title: '👔 7. Menu Vêtements & Coiffeur',  desc: 'Ouvrir le menu vêtements/coiffeur sur le joueur, recharger skin ou nettoyer sang' },
            { key: 'manage_skins',       title: '🎭 7B. Transformer en Ped/Skin',   desc: 'Appliquer n\'importe quel Ped/Skin du catalogue (1051+ modèles) sur le joueur' },
            { key: 'manage_trolls',      title: '🎪 8. Actions Trolls & Cage',      desc: 'Mettre en cage, Slap 50m, mettre en feu, ivre, pipi, caca, cri, tuer (Slay)' },
            { key: 'manage_force_dance', title: '🕺 8B. Forcer une Danse',          desc: 'Faire danser le joueur sur l\'une des 4,800+ animations ou stopper' },
            { key: 'player_pm',          title: '💬 8C. Message Privé Staff (PM)',  desc: 'Afficher un message privé officiel sur l\'écran du joueur' },
            { key: 'manage_warn_kick',   title: '⚠️ 8D. Warn, Déco & Kick',         desc: 'Envoyer un avertissement officiel, forcer déconnexion ou Kick depuis Manage', badge: 'SANCTION', badgeType: 'warn' },
            { key: 'manage_ban',         title: '🚫 8E. Bannir depuis Manage (Ban)',desc: 'Bouton Ban direct dans la fiche Manage Player', badge: 'DANGER', badgeType: 'danger' },
            { key: 'manage_wipes',       title: '💀 8F. Wipe Cash / Inv / Total',   desc: 'Remise à zéro irréversible de l\'argent, de l\'inventaire ou du personnage complet', badge: 'CRITIQUE', badgeType: 'danger' }
        ]
    },
    {
        tab: 'teleport',
        masterKey: 'tab_teleport',
        icon: '📍',
        title: 'Teleport (Téléportation)',
        subtitle: 'Téléportation au marqueur GPS, vers les joueurs, destinations populaires, favoris et coordonnées XYZ',
        color: '#a855f7',
        subs: [
            { key: 'world_teleport', title: '📍 TP au Marqueur GPS (Waypoint)',  desc: 'Se téléporter instantanément au point placé sur la carte GTA' },
            { key: 'tp_players',     title: '👥 TP Rapide Joueurs en Ligne',     desc: 'Cartes Goto / Bring rapides vers tous les joueurs connectés' },
            { key: 'tp_locations',   title: '🌆 Destinations Populaires',        desc: 'Se téléporter en 1 clic à Legion Square, Pillbox, LSPD, Casino, Cayo...' },
            { key: 'tp_bookmarks',   title: '⭐ Mes Positions Favoris',          desc: 'Sauvegarder et utiliser ses propres repères de téléportation' },
            { key: 'tp_coords',      title: '🧭 Coordonnées Exactes (X, Y, Z)',  desc: 'Se téléporter manuellement vers un vecteur X / Y / Z précis' }
        ]
    },
    {
        tab: 'items',
        masterKey: 'tab_items',
        icon: '🎒',
        title: 'Items & Weapons (Catalogue Items & Armes)',
        subtitle: 'Catalogue visuel ox_inventory (392+ items), armes, munitions, don à un joueur et atelier teinte d\'arme',
        color: '#facc15',
        subs: [
            { key: 'spawn_items',        title: '📦 Items Généraux (Nourriture/Outils/Soins)', desc: 'Spawner les items standards (eau, burger, bandage, radio, lockpick...)' },
            { key: 'items_weapons',      title: '🔫 Catégories Armes & Munitions',             desc: 'Afficher et spawner les armes à feu, armes blanches et boîtes de munitions', badge: 'ARMES', badgeType: 'warn' },
            { key: 'items_give_others',  title: '🎯 Cibler & Donner à un Autre Joueur',        desc: 'Sélecteur permettant d\'envoyer les items/armes à un autre joueur connecté' },
            { key: 'items_custom_spawn', title: '⌨️ Spawn Manuel par Code Item',               desc: 'Saisir manuellement le nom technique d\'un item et la quantité (jusqu\'à 1000)' },
            { key: 'items_weapon_tint',  title: '✨ Atelier Arme en Main (Or/Platine + 999)',   desc: 'Appliquer finition Or, Platine ou LSPD + 999 munitions sur l\'arme en main' }
        ]
    },
    {
        tab: 'god',
        masterKey: 'tab_god',
        icon: '⚡',
        title: 'God Powers (Pouvoirs Staff)',
        subtitle: 'Godmode, NoClip, ESP/Blips, Pouvoirs Combat/Véhicule et utilitaires rapides',
        color: '#ffd700',
        subs: [
            { key: 'god_powers',     title: '🛡️ Godmode, Invisibilité & Immunités', desc: 'Invincibilité Godmode, Fantôme Invisible, Never Wanted, Anti-Ragdoll, Stamina/Oxygène', badge: 'GOD', badgeType: 'warn' },
            { key: 'noclip_power',   title: '👻 NoClip & Fast NoClip (5x)',         desc: 'Voler à travers les murs et la carte (sans activer le Godmode)' },
            { key: 'admin_esp',      title: '👁️ ESP Noms, Blips GPS & Tag Admin',   desc: 'Voir les noms/vie au-dessus des joueurs, Blips GPS radar, Tag Admin et Coords HUD' },
            { key: 'combat_powers',  title: '💥 Pouvoirs Combat & Munitions',       desc: 'Infinite Ammo, 1000x Dégâts, Super Sprint, Super Jump, Balles & Poings Explosifs', badge: 'DANGER', badgeType: 'danger' },
            { key: 'veh_powers',     title: '🏎️ Pouvoirs Véhicule Spéciaux',        desc: 'Vehicle Godmode, Rocket Boost, Bunny Hop, Drift Physics, Auto-Flip' },
            { key: 'god_self_utils', title: '🧰 Utilitaires Personnels & Voiture',  desc: 'Clothes Menu, Benny\'s Max, Refuel 100%, Clean Ped, Flip/Repair/Lock Car, Toggle Duty' },
            { key: 'god_area_clean', title: '🧹 Revive Zone / All & Nettoyage 50m', desc: 'Revive Radius 50m, Revive All, Clear Area Vehicles / Peds / Objects' }
        ]
    },
    {
        tab: 'vehicles',
        masterKey: 'tab_vehicles',
        icon: '🚗',
        title: 'Vehicles (Catalogue 971+ Véhicules & Atelier)',
        subtitle: 'Vitrine photo des véhicules du serveur, spawn manuel, customisation plaque/livery/néons et sauvegarde garage',
        color: '#fb923c',
        subs: [
            { key: 'spawn_vehicles',   title: '🖼️ Catalogue Visuel Véhicules (971+)', desc: 'Spawner n\'importe quel véhicule depuis la galerie avec photos' },
            { key: 'veh_manual_spawn', title: '⌨️ Spawn Manuel & Quick Spawns',       desc: 'Spawner un véhicule par son nom de modèle avec option Max Tune' },
            { key: 'veh_workshop',     title: '🔧 Atelier Custom, Plaque & Couleurs', desc: 'Changer plaque, Max Tune, Réparer, Livery, Néons, Vitres teintées, Portes, Couleurs' },
            { key: 'veh_save_garage',  title: '💾 Enregistrer dans mon Garage DB',    desc: 'Bouton pour sauvegarder définitivement le véhicule actuel dans son propre garage', badge: 'DB GARAGE', badgeType: 'warn' }
        ]
    },
    {
        tab: 'characters',
        masterKey: 'tab_characters',
        icon: '🎭',
        title: 'Characters & Skins (Catalogue 1,051+ Peds)',
        subtitle: 'Galerie visuelle de tous les personnages GTA V (Story, Police, Gangs, Animaux) pour soi-même',
        color: '#c084fc',
        subs: [
            { key: 'chars_catalog',     title: '🎭 Galerie Visuelle des Peds (1,051+)', desc: 'Se transformer en n\'importe quel personnage du catalogue photo' },
            { key: 'chars_custom_hash', title: '⌨️ Saisie Modèle Custom & Reset MP',    desc: 'Appliquer un hash de Ped personnalisé ou revenir au personnage MP Freemode' }
        ]
    },
    {
        tab: 'jobs',
        masterKey: 'tab_jobs',
        icon: '💼',
        title: 'Jobs & Ranks (Catalogue Métiers)',
        subtitle: 'Catalogue visuel des métiers et grades du serveur (Police, EMS, Mécano, Entreprises, Gangs)',
        color: '#34d399',
        subs: [
            { key: 'jobs_catalog', title: '💼 Catalogue des Métiers & Grades', desc: 'S\'attribuer un métier et un grade en 1 clic depuis l\'onglet Jobs' }
        ]
    },
    {
        tab: 'arsenal',
        masterKey: 'tab_arsenal',
        icon: '🔫',
        title: 'Owner Arsenal (Packs Tactiques & Économie)',
        subtitle: 'Packs d\'armes complets en 1 clic (SWAT, Juggernaut, Assassin, God) et ajout rapide Cash/Banque',
        color: '#f43f5e',
        subs: [
            { key: 'arsenal',             title: '🔫 Packs d\'Armes Tactiques (Self)',   desc: 'Équiper les packs SWAT Commander, Heavy Juggernaut, Silent Assassin, God Arsenal', badge: 'HAUT NIVEAU', badgeType: 'danger' },
            { key: 'arsenal_give_others', title: '🎯 Donner un Pack Arsenal à un Joueur',desc: 'Sélecteur pour équiper un pack d\'armes complet sur un autre joueur connecté', badge: 'DANGER', badgeType: 'danger' },
            { key: 'arsenal_economy',     title: '💰 Quick Owner Economy (Cash/Banque)', desc: 'Se donner instantanément du Cash ou de l\'argent en Banque', badge: 'ÉCONOMIE', badgeType: 'danger' }
        ]
    },
    {
        tab: 'world',
        masterKey: 'tab_world',
        icon: '🌍',
        title: 'World & Weather (Météo, Heure, Police NPC & Ban Offline)',
        subtitle: 'Contrôle de l\'heure, météo, blackout, annonces globales, Police NPC / densité trafic PNJ et bans hors-ligne',
        color: '#2dd4bf',
        subs: [
            { key: 'world_control',     title: '☀️ Heure, Météo & Blackout',            desc: 'Changer l\'heure (08h, 12h, 18h, 00h), la météo serveur et le Blackout électrique' },
            { key: 'world_announce',    title: '📢 Annonce Globale Serveur (Broadcast)',desc: 'Diffuser une notification importante à tous les joueurs connectés' },
            { key: 'npc_control',       title: '🚔 Police NPC, Mode Auto-RP & Densité', desc: 'Gérer la Police NPC, le seuil de policiers RP, les étoiles GTA et la densité du trafic PNJ' },
            { key: 'world_props_cmd',   title: '📦 Spawner Props, Commandes & Stashs',  desc: 'Spawner des objets/barrières, exécuter une commande ou créer un coffre (Stash) métier/gang', badge: 'AVANCÉ', badgeType: 'warn' },
            { key: 'world_offline_ban', title: '🚫 Ban Offline & Unban par License',    desc: 'Bannir un joueur hors-ligne par License/CID ou révoquer un bannissement actif', badge: 'DANGER', badgeType: 'danger' }
        ]
    },
    {
        tab: 'devtools',
        masterKey: 'tab_devtools',
        icon: '🔧',
        title: 'Dev Tools (Outils Développeur)',
        subtitle: 'Copie de coordonnées Vector3/Vector4, nettoyage de zone 50m, skins rapides et Raycast Laser Inspector',
        color: '#60a5fa',
        subs: [
            { key: 'devtools',       title: '🧭 Coordonnées vec3/vec4 & Laser Inspector', desc: 'Copier Vector3/Vector4/Heading, Raycast Entity Inspector et Mode Cinématique (Hide HUD)' },
            { key: 'devtools_clean', title: '🧹 Outils de Nettoyage de Zone (50m)',       desc: 'Supprimer les véhicules, PNJ, objets ou purger toute la zone dans un rayon de 50m' },
            { key: 'devtools_skins', title: '🎭 Changement Rapide de Skin (Dev)',         desc: 'Boutons rapides Male/Female MP, Police, Paramedic et hash custom dans Dev Tools' }
        ]
    },
    {
        tab: 'events',
        masterKey: 'tab_events',
        icon: '🎪',
        title: 'Event Manager (Événements Serveur)',
        subtitle: 'Lancement et arrêt d\'événements communautaires (Fight Night, Drag Race, Purge, Airdrop, Derby)',
        color: '#f97316',
        subs: [
            { key: 'events',        title: '🥊 Lancer / Stopper Événements Prédéfinis', desc: 'Démarrer ou arrêter Fight Night, Drag Race, Purge Night, Mystery Airdrop, Demolition Derby' },
            { key: 'events_custom', title: '🚀 Créateur d\'Événement Personnalisé',     desc: 'Créer un événement sur-mesure avec titre, annonce, zone GPS et rayon personnalisés' }
        ]
    },
    {
        tab: 'emotes',
        masterKey: 'tab_emotes',
        icon: '🕺',
        title: 'Dances & Emotes (Studio 4,800+ Animations)',
        subtitle: 'Catalogue complet des danses, packs Fortnite, props 3D et postures RP',
        color: '#ec4899',
        subs: [
            { key: 'dances_emotes',        title: '🕺 Jouer les Danses sur Soi-même',        desc: 'Accéder aux 4,800+ danses et animations et les jouer sur son propre personnage' },
            { key: 'emotes_target_player', title: '🎯 Faire Danser un Joueur Ciblé',         desc: 'Choisir un joueur connecté dans la liste déroulante pour le faire danser' },
            { key: 'emotes_target_all',    title: '🌐 Dance Party sur Tout le Serveur',      desc: 'Faire danser simultanément tous les joueurs connectés au serveur', badge: 'GLOBAL', badgeType: 'warn' }
        ]
    },
    {
        tab: 'logs',
        masterKey: 'tab_logs',
        icon: '📜',
        title: 'Security Logs (Journal d\'Audit)',
        subtitle: 'Historique complet et infalsifiable (SHA-256) de toutes les actions exécutées par le staff',
        color: '#a3e635',
        subs: [
            { key: 'logs', title: '📜 Consulter & Filtrer les Security Logs', desc: 'Lire et rechercher dans l\'historique complet des actions staff' }
        ]
    },
    {
        tab: 'staff',
        masterKey: 'tab_staff',
        icon: '🛡️',
        title: 'Staff & Perms (Gestion de l\'Équipe)',
        subtitle: 'Panneau de haute sécurité permettant d\'ajouter, modifier ou révoquer les permissions des membres du staff',
        color: '#ff4d6d',
        subs: [
            { key: 'staff_management', title: '👑 Gérer l\'Équipe Staff & Permissions', desc: 'Autoriser l\'ouverture de cet onglet et la gestion des grades/permissions (Réservé Owner)', badge: 'OWNER ONLY', badgeType: 'danger' }
        ]
    }
];

// Dynamically build ALL_PERM_KEYS and PERM_LABELS from STAFF_TAB_SCHEMA
const ALL_TAB_MASTER_KEYS = STAFF_TAB_SCHEMA.map(t => t.masterKey);
const ALL_SUB_PERM_KEYS = [];
const PERM_LABELS = {};
const TAB_LABELS = {};

STAFF_TAB_SCHEMA.forEach(t => {
    TAB_LABELS[t.masterKey] = `${t.icon} ${t.title.split(' (')[0]}`;
    t.subs.forEach(s => {
        if (!ALL_SUB_PERM_KEYS.includes(s.key)) {
            ALL_SUB_PERM_KEYS.push(s.key);
        }
        PERM_LABELS[s.key] = s.title.replace(/^\S+\s+\d+[A-Z]?\.\s*/, '');
    });
});

const ALL_PERM_KEYS = [...ALL_TAB_MASTER_KEYS, ...ALL_SUB_PERM_KEYS];

let rolePresetPerms = {
    owner: Object.fromEntries(ALL_PERM_KEYS.map(k => [k, true])),
    developer: {
        tab_dashboard: true, tab_god: true, tab_players: true, tab_manage: true,
        tab_teleport: true, tab_items: false, tab_vehicles: true, tab_characters: true,
        tab_jobs: false, tab_arsenal: false, tab_world: true, tab_devtools: true,
        tab_events: true, tab_emotes: true, tab_logs: true, tab_staff: false,
        dash_metrics: true, self_actions: true, dash_self_veh: true, dash_self_tp: true, dash_self_cash: false,
        mass_actions: false, dash_purge_cops: true, dash_announce: false, dash_logs_feed: true,
        view_players: true, players_view_money: false, players_btn_manage: true,
        player_heal: false, player_inventory: false, player_teleport: true, player_freeze: false,
        player_spectate: true, punish_kicks: false, punish_bans: false,
        manage_tp: true, manage_freeze: false, manage_money: false, manage_give_item: false,
        manage_inv: false, manage_jobs: false, manage_heal: false, player_vehicles: true,
        manage_assets: false, manage_properties: false, player_clothing: true, manage_skins: true,
        manage_trolls: false, manage_force_dance: true, player_pm: true, manage_warn_kick: false,
        manage_ban: false, manage_wipes: false,
        world_teleport: true, tp_players: true, tp_locations: true, tp_bookmarks: true, tp_coords: true,
        spawn_items: false, items_weapons: false, items_give_others: false, items_custom_spawn: false, items_weapon_tint: false,
        god_powers: false, noclip_power: true, admin_esp: true, combat_powers: false,
        veh_powers: true, god_self_utils: true, god_area_clean: true,
        spawn_vehicles: true, veh_manual_spawn: true, veh_workshop: true, veh_save_garage: false,
        chars_catalog: true, chars_custom_hash: true,
        jobs_catalog: false,
        arsenal: false, arsenal_give_others: false, arsenal_economy: false,
        world_control: true, world_announce: false, npc_control: true, world_props_cmd: true, world_offline_ban: false,
        devtools: true, devtools_clean: true, devtools_skins: true,
        events: true, events_custom: true,
        dances_emotes: true, emotes_target_player: true, emotes_target_all: false,
        logs: true, staff_management: false
    },
    admin: {
        tab_dashboard: true, tab_god: true, tab_players: true, tab_manage: true,
        tab_teleport: true, tab_items: true, tab_vehicles: true, tab_characters: true,
        tab_jobs: true, tab_arsenal: false, tab_world: true, tab_devtools: false,
        tab_events: true, tab_emotes: true, tab_logs: true, tab_staff: false,
        dash_metrics: true, self_actions: true, dash_self_veh: true, dash_self_tp: true, dash_self_cash: false,
        mass_actions: true, dash_purge_cops: true, dash_announce: true, dash_logs_feed: true,
        view_players: true, players_view_money: true, players_btn_manage: true,
        player_heal: true, player_inventory: true, player_teleport: true, player_freeze: true,
        player_spectate: true, punish_kicks: true, punish_bans: true,
        manage_tp: true, manage_freeze: true, manage_money: false, manage_give_item: true,
        manage_inv: true, manage_jobs: true, manage_heal: true, player_vehicles: true,
        manage_assets: true, manage_properties: true, player_clothing: true, manage_skins: true,
        manage_trolls: false, manage_force_dance: true, player_pm: true, manage_warn_kick: true,
        manage_ban: true, manage_wipes: false,
        world_teleport: true, tp_players: true, tp_locations: true, tp_bookmarks: true, tp_coords: true,
        spawn_items: true, items_weapons: true, items_give_others: true, items_custom_spawn: true, items_weapon_tint: false,
        god_powers: false, noclip_power: true, admin_esp: true, combat_powers: false,
        veh_powers: true, god_self_utils: true, god_area_clean: true,
        spawn_vehicles: true, veh_manual_spawn: true, veh_workshop: true, veh_save_garage: true,
        chars_catalog: true, chars_custom_hash: true,
        jobs_catalog: true,
        arsenal: false, arsenal_give_others: false, arsenal_economy: false,
        world_control: true, world_announce: true, npc_control: true, world_props_cmd: false, world_offline_ban: true,
        devtools: false, devtools_clean: false, devtools_skins: false,
        events: true, events_custom: true,
        dances_emotes: true, emotes_target_player: true, emotes_target_all: true,
        logs: true, staff_management: false
    },
    moderator: {
        tab_dashboard: true, tab_god: true, tab_players: true, tab_manage: true,
        tab_teleport: true, tab_items: false, tab_vehicles: true, tab_characters: false,
        tab_jobs: false, tab_arsenal: false, tab_world: false, tab_devtools: false,
        tab_events: false, tab_emotes: true, tab_logs: false, tab_staff: false,
        dash_metrics: true, self_actions: true, dash_self_veh: true, dash_self_tp: false, dash_self_cash: false,
        mass_actions: false, dash_purge_cops: false, dash_announce: false, dash_logs_feed: false,
        view_players: true, players_view_money: false, players_btn_manage: true,
        player_heal: true, player_inventory: false, player_teleport: true, player_freeze: true,
        player_spectate: true, punish_kicks: true, punish_bans: false,
        manage_tp: true, manage_freeze: true, manage_money: false, manage_give_item: false,
        manage_inv: false, manage_jobs: false, manage_heal: true, player_vehicles: true,
        manage_assets: false, manage_properties: false, player_clothing: true, manage_skins: false,
        manage_trolls: false, manage_force_dance: true, player_pm: true, manage_warn_kick: true,
        manage_ban: false, manage_wipes: false,
        world_teleport: false, tp_players: true, tp_locations: true, tp_bookmarks: false, tp_coords: false,
        spawn_items: false, items_weapons: false, items_give_others: false, items_custom_spawn: false, items_weapon_tint: false,
        god_powers: false, noclip_power: true, admin_esp: true, combat_powers: false,
        veh_powers: false, god_self_utils: true, god_area_clean: false,
        spawn_vehicles: true, veh_manual_spawn: false, veh_workshop: false, veh_save_garage: false,
        chars_catalog: false, chars_custom_hash: false,
        jobs_catalog: false,
        arsenal: false, arsenal_give_others: false, arsenal_economy: false,
        world_control: false, world_announce: false, npc_control: false, world_props_cmd: false, world_offline_ban: false,
        devtools: false, devtools_clean: false, devtools_skins: false,
        events: false, events_custom: false,
        dances_emotes: true, emotes_target_player: false, emotes_target_all: false,
        logs: false, staff_management: false
    },
    custom: {
        tab_dashboard: true, tab_god: false, tab_players: true, tab_manage: true,
        tab_teleport: false, tab_items: false, tab_vehicles: false, tab_characters: false,
        tab_jobs: false, tab_arsenal: false, tab_world: false, tab_devtools: false,
        tab_events: false, tab_emotes: true, tab_logs: false, tab_staff: false,
        dash_metrics: true, self_actions: false, dash_self_veh: false, dash_self_tp: false, dash_self_cash: false,
        mass_actions: false, dash_purge_cops: false, dash_announce: false, dash_logs_feed: false,
        view_players: true, players_view_money: false, players_btn_manage: true,
        player_heal: false, player_inventory: false, player_teleport: true, player_freeze: false,
        player_spectate: false, punish_kicks: false, punish_bans: false,
        manage_tp: true, manage_freeze: false, manage_money: false, manage_give_item: false,
        manage_inv: false, manage_jobs: false, manage_heal: false, player_vehicles: false,
        manage_assets: false, manage_properties: false, player_clothing: false, manage_skins: false,
        manage_trolls: false, manage_force_dance: true, player_pm: true, manage_warn_kick: false,
        manage_ban: false, manage_wipes: false,
        world_teleport: false, tp_players: false, tp_locations: false, tp_bookmarks: false, tp_coords: false,
        spawn_items: false, items_weapons: false, items_give_others: false, items_custom_spawn: false, items_weapon_tint: false,
        god_powers: false, noclip_power: false, admin_esp: false, combat_powers: false,
        veh_powers: false, god_self_utils: false, god_area_clean: false,
        spawn_vehicles: false, veh_manual_spawn: false, veh_workshop: false, veh_save_garage: false,
        chars_catalog: false, chars_custom_hash: false,
        jobs_catalog: false,
        arsenal: false, arsenal_give_others: false, arsenal_economy: false,
        world_control: false, world_announce: false, npc_control: false, world_props_cmd: false, world_offline_ban: false,
        devtools: false, devtools_clean: false, devtools_skins: false,
        events: false, events_custom: false,
        dances_emotes: true, emotes_target_player: false, emotes_target_all: false,
        logs: false, staff_management: false
    }
};

// Render the 16-Tab Permissions Studio Matrix & Filter Pills inside #staff-modal
let permStudioInitialized = false;
function initStaffPermStudioDOM() {
    if (permStudioInitialized) return;
    const pillsContainer = document.getElementById('staff-perm-tab-pills');
    const matrixContainer = document.getElementById('staff-perm-tabs-matrix');
    if (!pillsContainer || !matrixContainer) return;

    // 1. Build Tab Filter Pills
    let pillsHtml = `<button type="button" class="perm-tab-filter-pill active" data-ptab="all" onclick="filterPermStudioByTab('all')">🌐 Tous les Onglets (16)</button>`;
    STAFF_TAB_SCHEMA.forEach(t => {
        const shortName = t.title.split(' (')[0];
        pillsHtml += `<button type="button" class="perm-tab-filter-pill" data-ptab="${t.tab}" onclick="filterPermStudioByTab('${t.tab}')">${t.icon} ${escapeHtml(shortName)}</button>`;
    });
    pillsContainer.innerHTML = pillsHtml;

    // 2. Build the 16 Tab Blocks with Master Switch + Sub-Permission Check Cards
    let matrixHtml = '';
    STAFF_TAB_SCHEMA.forEach((t, idx) => {
        const subsHtml = t.subs.map(s => {
            const badgeHtml = s.badge
                ? `<span class="perm-sub-badge ${s.badgeType === 'danger' ? 'danger' : 'warn'}">${escapeHtml(s.badge)}</span>`
                : '';
            return `
                <label class="perm-check-card perm-sub-card" for="perm-${s.key}" data-sub-key="${s.key}" data-search="${escapeHtml((s.title + ' ' + s.desc + ' ' + s.key).toLowerCase())}">
                    <input type="checkbox" id="perm-${s.key}" data-parent-tab="${t.masterKey}" onchange="onSubPermCheckboxChange('${t.masterKey}', '${s.key}')">
                    <div class="perm-check-card-info">
                        <div style="display: flex; align-items: center; justify-content: space-between; gap: 6px;">
                            <span class="perm-check-card-title">${escapeHtml(s.title)}</span>
                            ${badgeHtml}
                        </div>
                        <span class="perm-check-card-desc">${escapeHtml(s.desc)}</span>
                    </div>
                </label>
            `;
        }).join('');

        matrixHtml += `
            <div class="perm-tab-block" id="perm-block-${t.tab}" data-tab-id="${t.tab}" style="--tab-accent: ${t.color};">
                <div class="perm-tab-master-header">
                    <div class="perm-tab-master-left">
                        <span class="perm-tab-num">${String(idx + 1).padStart(2, '0')}</span>
                        <span class="perm-tab-icon">${t.icon}</span>
                        <div>
                            <div class="perm-tab-title-row">
                                <h4>${escapeHtml(t.title)}</h4>
                                <span class="perm-tab-sub-counter" id="perm-counter-${t.masterKey}">0/${t.subs.length} actifs</span>
                            </div>
                            <p>${escapeHtml(t.subtitle)}</p>
                        </div>
                    </div>
                    <div class="perm-tab-master-actions">
                        <button type="button" class="perm-mini-action-btn" onclick="toggleAllSubPermsInTab('${t.masterKey}', true)" title="Activer toutes les options de cet onglet">✅ Tout cocher</button>
                        <button type="button" class="perm-mini-action-btn clear" onclick="toggleAllSubPermsInTab('${t.masterKey}', false)" title="Décocher toutes les options de cet onglet">🧹 Vider</button>
                        <label class="perm-master-switch-wrap" for="perm-${t.masterKey}" title="Afficher ou masquer complètement cet onglet dans le menu du staff">
                            <span class="perm-master-switch-label" id="perm-master-lbl-${t.masterKey}">ONGLET VISIBLE</span>
                            <input type="checkbox" id="perm-${t.masterKey}" onchange="onMasterTabSwitchChange('${t.masterKey}')">
                            <span class="perm-master-slider"></span>
                        </label>
                    </div>
                </div>
                <div class="perm-cards-grid perm-sub-grid" id="perm-subgrid-${t.masterKey}">
                    ${subsHtml}
                </div>
            </div>
        `;
    });
    matrixContainer.innerHTML = matrixHtml;
    permStudioInitialized = true;
}

window.filterPermStudioByTab = function(tabId) {
    currentPermStudioTabFilter = tabId || 'all';
    document.querySelectorAll('#staff-perm-tab-pills .perm-tab-filter-pill').forEach(btn => {
        btn.classList.toggle('active', btn.getAttribute('data-ptab') === currentPermStudioTabFilter);
    });
    applyPermStudioSearchAndFilter();
};

function applyPermStudioSearchAndFilter() {
    initStaffPermStudioDOM();
    const query = (document.getElementById('staff-perm-search')?.value || '').toLowerCase().trim();

    STAFF_TAB_SCHEMA.forEach(t => {
        const block = document.getElementById(`perm-block-${t.tab}`);
        if (!block) return;

        const tabMatchesFilter = currentPermStudioTabFilter === 'all' || currentPermStudioTabFilter === t.tab;
        if (!tabMatchesFilter) {
            block.style.display = 'none';
            return;
        }

        if (!query) {
            block.style.display = '';
            block.querySelectorAll('.perm-sub-card').forEach(c => { c.style.display = ''; });
            return;
        }

        const headerMatches = t.title.toLowerCase().includes(query) || t.subtitle.toLowerCase().includes(query) || t.tab.includes(query);
        let anySubMatches = false;
        block.querySelectorAll('.perm-sub-card').forEach(card => {
            const hay = card.getAttribute('data-search') || '';
            const match = headerMatches || hay.includes(query);
            card.style.display = match ? '' : 'none';
            if (match) anySubMatches = true;
        });

        block.style.display = (headerMatches || anySubMatches) ? '' : 'none';
    });
}

window.onMasterTabSwitchChange = function(masterKey) {
    const masterChk = document.getElementById(`perm-${masterKey}`);
    const tabSchema = STAFF_TAB_SCHEMA.find(t => t.masterKey === masterKey);
    if (!masterChk || !tabSchema) return;

    // If the owner turns ON a tab that currently has 0 sub-permissions checked,
    // automatically enable the first (default/safe) sub-permission so the tab isn't empty.
    if (masterChk.checked) {
        const anySubChecked = tabSchema.subs.some(s => document.getElementById(`perm-${s.key}`)?.checked);
        if (!anySubChecked && tabSchema.subs.length > 0) {
            const firstSub = document.getElementById(`perm-${tabSchema.subs[0].key}`);
            if (firstSub) firstSub.checked = true;
        }
    }

    const roleSel = document.getElementById('staff-select-role');
    if (roleSel) roleSel.value = 'custom';
    highlightPresetButton('');
    updateStaffPermVisualState();
};

window.onSubPermCheckboxChange = function(masterKey, subKey) {
    const subChk = document.getElementById(`perm-${subKey}`);
    const masterChk = document.getElementById(`perm-${masterKey}`);
    // If a sub-permission is checked, automatically turn ON its parent tab so the staff can see the tab!
    if (subChk && subChk.checked && masterChk && !masterChk.checked) {
        masterChk.checked = true;
    }
    const roleSel = document.getElementById('staff-select-role');
    if (roleSel) roleSel.value = 'custom';
    highlightPresetButton('');
    updateStaffPermVisualState();
};

window.toggleAllSubPermsInTab = function(masterKey, enable) {
    const tabSchema = STAFF_TAB_SCHEMA.find(t => t.masterKey === masterKey);
    if (!tabSchema) return;
    const masterChk = document.getElementById(`perm-${masterKey}`);
    if (masterChk) masterChk.checked = !!enable;

    tabSchema.subs.forEach(s => {
        const chk = document.getElementById(`perm-${s.key}`);
        if (chk) chk.checked = !!enable;
    });

    const roleSel = document.getElementById('staff-select-role');
    if (roleSel) roleSel.value = 'custom';
    highlightPresetButton('');
    updateStaffPermVisualState();
};

function updateStaffPermVisualState() {
    initStaffPermStudioDOM();
    let activeTabsCount = 0;
    let activeSubsCount = 0;

    STAFF_TAB_SCHEMA.forEach(t => {
        const masterChk = document.getElementById(`perm-${t.masterKey}`);
        const isTabOn = !!(masterChk && masterChk.checked);
        if (isTabOn) activeTabsCount++;

        let tabSubActive = 0;
        t.subs.forEach(s => {
            const chk = document.getElementById(`perm-${s.key}`);
            if (chk && chk.checked) {
                tabSubActive++;
                if (isTabOn) activeSubsCount++;
            }
        });

        const block = document.getElementById(`perm-block-${t.tab}`);
        if (block) {
            block.classList.toggle('tab-disabled', !isTabOn);
            block.classList.toggle('tab-enabled', isTabOn);
        }

        const lbl = document.getElementById(`perm-master-lbl-${t.masterKey}`);
        if (lbl) {
            lbl.innerText = isTabOn ? '👁️ ONGLET VISIBLE' : '🚫 ONGLET MASQUÉ';
            lbl.style.color = isTabOn ? '#00e676' : 'var(--text-muted)';
        }

        const counterEl = document.getElementById(`perm-counter-${t.masterKey}`);
        if (counterEl) {
            counterEl.innerText = `${tabSubActive}/${t.subs.length} options`;
            counterEl.className = `perm-tab-sub-counter ${isTabOn && tabSubActive > 0 ? 'active' : ''}`;
        }
    });

    const summaryEl = document.getElementById('staff-perm-live-summary');
    if (summaryEl) {
        summaryEl.innerText = `${activeTabsCount}/16 Onglets Visibles • ${activeSubsCount} Permissions Actives`;
    }
}

window.setStaffRoleFilter = function(role) {
    currentStaffRoleFilter = role || 'all';
    document.querySelectorAll('#staff-role-filter-pills .filter-chip').forEach(btn => {
        btn.classList.toggle('active', btn.getAttribute('data-srole') === currentStaffRoleFilter);
    });
    renderStaffView();
};

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
    initStaffPermStudioDOM();
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
        Object.keys(res.defaultPerms).forEach(rKey => {
            rolePresetPerms[rKey] = { ...(rolePresetPerms[rKey] || {}), ...res.defaultPerms[rKey] };
        });
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

// Build a clean visual summary of Visible Tabs + Key Permissions for a Staff Card
function buildStaffCardPermsSummaryHtml(perms, hasAccess, isOwner) {
    if (!hasAccess && !isOwner) {
        return `<span class="perm-tag" style="color: var(--text-muted);">Joueur Standard — Aucun accès au panel SOUH4IL-DEV</span>`;
    }
    if (isOwner) {
        return `<span class="perm-tag active" style="border-color: #ffd700; color: #ffd700; background: rgba(255,215,0,0.12);">👑 16/16 Onglets Visibles • Accès Intégral Owner</span>`;
    }

    const p = perms || {};
    let visibleTabs = [];
    STAFF_TAB_SCHEMA.forEach(t => {
        const masterVal = p[t.masterKey];
        const isVis = typeof masterVal === 'boolean'
            ? masterVal
            : t.subs.some(s => p[s.key] === true);
        if (isVis) {
            const shortTitle = t.title.split(' (')[0];
            const activeSubs = t.subs.filter(s => p[s.key] === true).length;
            visibleTabs.push(`<span class="perm-tag active" title="${t.title} (${activeSubs}/${t.subs.length} options)">${t.icon} ${escapeHtml(shortTitle)} <small style="opacity:0.75;">(${activeSubs}/${t.subs.length})</small></span>`);
        }
    });

    if (visibleTabs.length === 0) {
        return `<span class="perm-tag" style="color: var(--accent-red);">🚫 Aucun onglet actif</span>`;
    }
    return visibleTabs.join('');
}

function renderMembersList(list, filter = '') {
    const container = document.getElementById('staff-list-container');
    if (!container) return;

    const filtered = list.filter(p => {
        const rLower = (p.role || 'member').toLowerCase();
        if (currentStaffRoleFilter !== 'all') {
            if (!p.hasAccess || rLower !== currentStaffRoleFilter) return false;
        }
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
        container.innerHTML = '<div class="table-empty">Aucun joueur connecté correspondant à ce filtre.</div>';
        return;
    }

    let html = '';
    filtered.forEach(p => {
        const initials = (p.name || 'PL').substring(0, 2).toUpperCase();
        const roleLower = (p.role || 'member').toLowerCase();
        const roleClass = `role-${roleLower}`;
        const hasAccess = !!p.hasAccess;

        const permsTagsHtml = buildStaffCardPermsSummaryHtml(p.permissions, hasAccess, p.isOwner);
        const safeLicense = escapeHtml(p.license || '');
        const displayLic = safeLicense.length > 25 ? `${safeLicense.substring(0, 16)}...${safeLicense.substring(safeLicense.length - 6)}` : safeLicense;

        html += `
        <div class="staff-card ${p.isOwner ? 'owner-card' : ''}" style="${!hasAccess ? 'border-style: dashed; opacity: 0.92;' : ''}">
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
                <div style="font-size: 0.68rem; color: var(--text-muted); text-transform: uppercase; margin-bottom: 5px; letter-spacing: 0.04em;">Onglets & Permissions Visibles :</div>
                <div class="perm-tags-container">
                    ${permsTagsHtml}
                </div>
            </div>

            <div class="staff-actions">
                ${p.isOwner ? `
                    <span style="font-size: 0.75rem; color: #ffd700; font-weight: 700; padding: 6px;">👑 PROPRIÉTAIRE CANONIQUE</span>
                ` : hasAccess ? `
                    <button class="secondary-btn" onclick="openEditStaff('${safeLicense}')">⚙️ Choisir Onglets & Perms</button>
                    <button class="primary-btn danger-btn" onclick="removeStaffMember('${safeLicense}', '${escapeHtml(p.name)}')">🗑️ Révoquer</button>
                ` : `
                    <button class="primary-btn" style="background: rgba(0, 229, 255, 0.2); border-color: var(--accent-cyan); color: var(--accent-cyan);" onclick="openGrantMemberModal('${safeLicense}', '${escapeHtml(p.name)}')">➕ Configurer Onglets & Accès</button>
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
        const rLower = (s.role || 'moderator').toLowerCase();
        if (currentStaffRoleFilter !== 'all' && rLower !== currentStaffRoleFilter) {
            return false;
        }
        if (!filter) return true;
        const q = filter.toLowerCase();
        return (s.name && s.name.toLowerCase().includes(q)) ||
               (s.license && s.license.toLowerCase().includes(q)) ||
               (s.role && s.role.toLowerCase().includes(q));
    });

    if (filtered.length === 0) {
        container.innerHTML = '<div class="table-empty">Aucun membre du staff trouvé pour ce filtre.</div>';
        return;
    }

    let html = '';
    filtered.forEach(s => {
        const isOnline = !!s.online;
        const roleLower = (s.role || 'moderator').toLowerCase();
        const roleClass = `role-${roleLower}`;
        const initials = (s.name || 'ST').substring(0, 2).toUpperCase();

        const permsTagsHtml = buildStaffCardPermsSummaryHtml(s.permissions, true, s.isOwner);
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
                <div style="font-size: 0.7rem; color: var(--text-muted); text-transform: uppercase; margin-bottom: 5px; letter-spacing: 0.04em;">Onglets & Permissions Visibles :</div>
                <div class="perm-tags-container">
                    ${permsTagsHtml}
                </div>
            </div>

            <div class="staff-actions">
                ${s.isOwner ? `
                    <span style="font-size: 0.75rem; color: #ffd700; font-weight: 700; padding: 6px;">👑 PROPRIÉTAIRE CANONIQUE</span>
                ` : `
                    <button class="secondary-btn" onclick="openEditStaff('${safeLicense}')">⚙️ Choisir Onglets & Perms</button>
                    <button class="primary-btn danger-btn" onclick="removeStaffMember('${safeLicense}', '${escapeHtml(s.name || 'Staff')}')">🗑️ Révoquer</button>
                `}
            </div>
        </div>
        `;
    });

    container.innerHTML = html;
}

function resetPermModalFilters() {
    initStaffPermStudioDOM();
    const searchEl = document.getElementById('staff-perm-search');
    if (searchEl) searchEl.value = '';
    filterPermStudioByTab('all');
}

function openGrantMemberModal(license, name) {
    const modal = document.getElementById('staff-modal');
    if (!modal) return;
    resetPermModalFilters();

    document.getElementById('staff-modal-title').innerText = `🛡️ Configurer les Onglets & Permissions : ${name}`;
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
    resetPermModalFilters();

    document.getElementById('staff-modal-title').innerText = '🛡️ Ajouter un Staff & Choisir ses Onglets';
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
    resetPermModalFilters();

    document.getElementById('staff-modal-title').innerText = `⚙️ Permissions & Onglets de : ${staff.name}`;
    document.getElementById('staff-select-player').value = staff.license;
    document.getElementById('staff-input-name').value = staff.name || '';
    document.getElementById('staff-input-license').value = staff.license || '';
    document.getElementById('staff-input-license').readOnly = true;

    const roleLower = (staff.role || 'moderator').toLowerCase();
    document.getElementById('staff-select-role').value = rolePresetPerms[roleLower] ? roleLower : 'custom';

    const perms = staff.permissions || {};
    const fallbackPreset = rolePresetPerms[roleLower] || rolePresetPerms.custom;

    // 1. Populate all sub-permission checkboxes (with smart fallback for newly added sub-keys)
    ALL_SUB_PERM_KEYS.forEach(k => {
        const chk = document.getElementById(`perm-${k}`);
        if (!chk) return;
        if (typeof perms[k] === 'boolean') {
            chk.checked = perms[k];
        } else {
            chk.checked = !!fallbackPreset[k];
        }
    });

    // 2. Populate all 16 master tab switches (if undefined on old DB row, infer from sub-permissions)
    STAFF_TAB_SCHEMA.forEach(t => {
        const masterChk = document.getElementById(`perm-${t.masterKey}`);
        if (!masterChk) return;
        if (typeof perms[t.masterKey] === 'boolean') {
            masterChk.checked = perms[t.masterKey];
        } else {
            masterChk.checked = t.subs.some(s => document.getElementById(`perm-${s.key}`)?.checked);
        }
    });

    const btnMap = {
        moderator: 'preset-btn-mod',
        admin: 'preset-btn-admin',
        developer: 'preset-btn-dev',
        owner: 'preset-btn-owner'
    };
    highlightPresetButton(btnMap[roleLower] || '');
    updateStaffPermVisualState();
    modal.style.display = 'flex';
}

function applyRolePresetToCheckboxes(role) {
    initStaffPermStudioDOM();
    const preset = rolePresetPerms[role] || rolePresetPerms.moderator;
    ALL_PERM_KEYS.forEach(k => {
        const chk = document.getElementById(`perm-${k}`);
        if (chk) chk.checked = !!preset[k];
    });
    updateStaffPermVisualState();
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
        showToast('License Requise', 'Veuillez sélectionner un joueur connecté ou saisir une Rockstar License valide.', 'warning');
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
        showToast('Permissions Enregistrées', `Les onglets et permissions de ${name} (${role.toUpperCase()}) ont été mis à jour en direct !`, 'success');
        closeStaffModal();
        fetchStaffData();
    } else {
        showToast('Erreur de Sauvegarde', (res && res.error ? res.error : 'Serveur inaccessible'), 'error');
    }
}

async function removeStaffMember(license, name) {
    const res = await fetchNUI('removeStaffMember', { license: license });
    if (res && res.success) {
        showToast('Accès Révoqué', `Tous les accès SOUH4IL-DEV de ${name} ont été révoqués immédiatement.`, 'info');
        fetchStaffData();
    } else {
        showToast('Erreur de Révocation', (res && res.error ? res.error : 'Erreur inconnue'), 'error');
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

document.getElementById('staff-search-input')?.addEventListener('input', () => {
    renderStaffView();
});

document.getElementById('staff-perm-search')?.addEventListener('input', () => {
    applyPermStudioSearchAndFilter();
});

// Event Manager Button Listeners
document.getElementById('btn-refresh-event')?.addEventListener('click', checkEventState);
document.getElementById('btn-stop-active-event')?.addEventListener('click', stopActiveEvent);
document.getElementById('btn-launch-custom-event')?.addEventListener('click', launchCustomEvent);

// Preset Buttons & Modal Helpers
function highlightPresetButton(activeId) {
    ['preset-btn-mod', 'preset-btn-admin', 'preset-btn-dev', 'preset-btn-owner', 'preset-btn-all-tabs', 'preset-btn-clear'].forEach(id => {
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
document.getElementById('preset-btn-all-tabs')?.addEventListener('click', () => {
    initStaffPermStudioDOM();
    document.getElementById('staff-select-role').value = 'custom';
    ALL_PERM_KEYS.forEach(k => {
        const chk = document.getElementById(`perm-${k}`);
        if (chk) chk.checked = true;
    });
    updateStaffPermVisualState();
    highlightPresetButton('preset-btn-all-tabs');
});
document.getElementById('preset-btn-clear')?.addEventListener('click', () => {
    initStaffPermStudioDOM();
    document.getElementById('staff-select-role').value = 'custom';
    ALL_PERM_KEYS.forEach(k => {
        const chk = document.getElementById(`perm-${k}`);
        if (chk) chk.checked = false;
    });
    updateStaffPermVisualState();
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


// =========================================================================
// DANCES & EMOTES SYSTEM
// =========================================================================

const EMOTES_LIST = [
    // 💃 DANSES
    { id: 'gangnam',       label: 'Gangnam Style',    emoji: '🐴', cat: 'dance',  dict: 'anim@amb@nightclub@mini@dance@dance_solo@lo_intensity@var_a@',           clip: 'high_intensity',       loop: true },
    { id: 'floss',         label: 'Floss',            emoji: '💃', cat: 'dance',  dict: 'anim@amb@nightclub@mini@dance@dance_solo@lo_intensity@var_a@',           clip: 'low_intensity',        loop: true },
    { id: 'carlton',       label: 'Carlton Dance',    emoji: '🕺', cat: 'dance',  dict: 'anim@amb@nightclub@mini@dance@dance_solo@hi_intensity@var_a@',           clip: 'low_intensity',        loop: true },
    { id: 'robot',         label: 'Robot',            emoji: '🤖', cat: 'dance',  dict: 'anim@amb@nightclub@mini@dance@dance_solo@hi_intensity@var_a@',           clip: 'high_intensity',       loop: true },
    { id: 'twerk',         label: 'Twerk',            emoji: '🍑', cat: 'dance',  dict: 'anim@amb@nightclub@mini@dance@dance_solo@lo_intensity@var_b@',           clip: 'low_intensity',        loop: true },
    { id: 'breakdance',    label: 'Breakdance',       emoji: '🌀', cat: 'dance',  dict: 'anim@amb@nightclub@mini@dance@dance_solo@hi_intensity@var_b@',           clip: 'high_intensity',       loop: true },
    { id: 'shuffle',       label: 'Shuffle',          emoji: '🔀', cat: 'dance',  dict: 'anim@amb@nightclub@mini@dance@dance_solo@lo_intensity@var_c@',           clip: 'low_intensity',        loop: true },
    { id: 'dab',           label: 'Dab',              emoji: '🤙', cat: 'dance',  dict: 'mp_player_int_uppercut',                                                clip: 'mp_player_int_uppercut',loop: false },
    { id: 'salsa',         label: 'Salsa',            emoji: '🌹', cat: 'dance',  dict: 'anim@amb@nightclub@mini@dance@dance_solo@hi_intensity@var_c@',           clip: 'low_intensity',        loop: true },
    { id: 'wave',          label: 'Wave Dance',       emoji: '🌊', cat: 'dance',  dict: 'anim@amb@nightclub@mini@dance@dance_solo@lo_intensity@var_c@',           clip: 'high_intensity',       loop: true },
    { id: 'toprock',       label: 'Top Rock',         emoji: '🔥', cat: 'dance',  dict: 'anim@amb@nightclub@mini@dance@dance_solo@hi_intensity@var_a@',           clip: 'med_intensity',        loop: true },
    { id: 'moonwalk',      label: 'Moonwalk',         emoji: '🌙', cat: 'dance',  dict: 'missheistfbi2finale',                                                   clip: 'intro_loop',            loop: true },
    { id: 'aerobics',      label: 'Aerobics',         emoji: '🏃', cat: 'dance',  dict: 'anim@amb@gym@treadmill@',                                               clip: 'cardio_cycle_base',     loop: true },
    { id: 'clubdance1',    label: 'Club Dance 1',     emoji: '🎶', cat: 'dance',  dict: 'anim@amb@nightclub@mini@dance@dance_solo@lo_intensity@var_b@',           clip: 'high_intensity',        loop: true },
    { id: 'clubdance2',    label: 'Club Dance 2',     emoji: '🎵', cat: 'dance',  dict: 'anim@amb@nightclub@mini@dance@dance_solo@hi_intensity@var_b@',           clip: 'low_intensity',         loop: true },

    // 🪑 ASSIS / SITS
    { id: 'sit_ground',    label: 'Sit Ground',       emoji: '🪑', cat: 'sit',    dict: 'amb@world_human_sit@male@base',                                         clip: 'base',                 loop: true },
    { id: 'sit_bench',     label: 'Sit Bench',        emoji: '🏠', cat: 'sit',    dict: 'amb@world_human_seat_steps@male@idle_a',                                clip: 'idle_a',               loop: true },
    { id: 'lean_wall',     label: 'Lean Wall',        emoji: '🧱', cat: 'sit',    dict: 'amb@world_human_leaning@male@wall@back@hard@idle_a',                    clip: 'idle_a',               loop: true },
    { id: 'crouch',        label: 'Crouch',           emoji: '🤸', cat: 'sit',    dict: 'missfbi4',                                                              clip: 'amb_packing_a_idle',   loop: true },
    { id: 'meditate',      label: 'Meditate',         emoji: '🧘', cat: 'sit',    dict: 'amb@world_human_meditation@male@base',                                  clip: 'base',                 loop: true },
    { id: 'kneel',         label: 'Kneel',            emoji: '🙏', cat: 'sit',    dict: 'rcmnigel3b',                                                            clip: 'rcm_nigel3b_trev_idle', loop: true },

    // 💤 IDLES
    { id: 'smoke',         label: 'Smoke',            emoji: '🚬', cat: 'idle',   dict: 'amb@world_human_smoking@male@idle_a',                                   clip: 'idle_a',               loop: true },
    { id: 'phone_text',    label: 'Phone Text',       emoji: '📱', cat: 'idle',   dict: 'amb@world_human_mobile_film_shocking@male@idle_a',                      clip: 'idle_a',               loop: true },
    { id: 'phone_ear',     label: 'Phone Call',       emoji: '📞', cat: 'idle',   dict: 'amb@world_human_mobile_lester_low@male@idle_a',                         clip: 'idle_a',               loop: true },
    { id: 'drink',         label: 'Drink Beer',       emoji: '🍺', cat: 'idle',   dict: 'amb@world_human_drinking@beer@male@idle_a',                             clip: 'idle_a',               loop: true },
    { id: 'stretch',       label: 'Stretch',          emoji: '🤸', cat: 'idle',   dict: 'amb@world_human_stretching@male@idle_a',                                clip: 'idle_a',               loop: true },
    { id: 'yawn',          label: 'Yawn',             emoji: '😴', cat: 'idle',   dict: 'anim@heists@ornate_bank@ig1@',                                          clip: 'ig1_idle2',            loop: false },
    { id: 'lean_car',      label: 'Lean on Car',      emoji: '🚗', cat: 'idle',   dict: 'amb@world_human_hang_out_street@male_a@idle_a',                         clip: 'idle_a',               loop: true },
    { id: 'beg',           label: 'Beg',              emoji: '🤲', cat: 'idle',   dict: 'amb@world_human_bum_freeway@male@idle_a',                               clip: 'idle_a',               loop: true },
    { id: 'binoculars',    label: 'Binoculars',       emoji: '🔭', cat: 'idle',   dict: 'amb@world_human_binoculars@male@idle_a',                                clip: 'idle_a',               loop: true },
    { id: 'pushups',       label: 'Push-Ups',         emoji: '💪', cat: 'idle',   dict: 'amb@world_human_push_ups@male@base',                                    clip: 'base',                 loop: true },
    { id: 'situps',        label: 'Sit-Ups',          emoji: '🏋️', cat: 'idle',   dict: 'amb@world_human_ab_exercises@male@base',                                clip: 'base',                 loop: true },
    { id: 'weld',          label: 'Welding',          emoji: '🔧', cat: 'idle',   dict: 'amb@world_human_welding@male@idle_a',                                   clip: 'idle_a',               loop: true },

    // 👋 SOCIAL
    { id: 'wave_hand',     label: 'Wave',             emoji: '👋', cat: 'social', dict: 'anim@mp_player_introcelebrations@upper',                                clip: 'wave',                  loop: false },
    { id: 'cheer',         label: 'Cheer',            emoji: '🙌', cat: 'social', dict: 'anim@mp_player_introcelebrations@upper',                                clip: 'cheer',                 loop: false },
    { id: 'salute',        label: 'Salute',           emoji: '🫡', cat: 'social', dict: 'anim@mp_player_introcelebrations@upper',                                clip: 'salute',                loop: false },
    { id: 'point',         label: 'Point',            emoji: '👆', cat: 'social', dict: 'anim@mp_player_introcelebrations@upper',                                clip: 'clap',                  loop: false },
    { id: 'clap',          label: 'Clap',             emoji: '👏', cat: 'social', dict: 'anim@mp_player_introcelebrations@upper',                                clip: 'clap_left',             loop: false },
    { id: 'facepalm',      label: 'Facepalm',         emoji: '🤦', cat: 'social', dict: 'anim@mp_player_introcelebrations@upper',                                clip: 'come_on_1',             loop: false },
    { id: 'thumbsup',      label: 'Thumbs Up',        emoji: '👍', cat: 'social', dict: 'anim@mp_player_introcelebrations@upper',                                clip: 'finger_point',          loop: false },
    { id: 'flex',          label: 'Flex',             emoji: '💪', cat: 'social', dict: 'anim@mp_player_introcelebrations@upper',                                clip: 'slow_clap',             loop: false },
    { id: 'hands_up',      label: 'Hands Up',         emoji: '🙌', cat: 'social', dict: 'missbank1shot4',                                                        clip: 'bh_reaction_idle',      loop: true  },
    { id: 'surrender',     label: 'Surrender',        emoji: '🏳️', cat: 'social', dict: 'missfbi3',                                                              clip: 'fibsurrender_idle',     loop: true  },
    { id: 'talk',          label: 'Talk Phone',       emoji: '📣', cat: 'social', dict: 'random@arrests@busted',                                                 clip: 'idle_d',                loop: true  },

    // 😂 FUNNY
    { id: 'chicken',       label: 'Chicken Dance',    emoji: '🐔', cat: 'funny',  dict: 'amb@world_human_aa_coffee@male@idle_a',                                 clip: 'idle_a',                loop: true  },
    { id: 'drunk',         label: 'Drunk Walk',       emoji: '🍻', cat: 'funny',  dict: 'anim@mp_player_intros@male@',                                           clip: 'intro_0',               loop: false },
    { id: 'scared',        label: 'Scared',           emoji: '😨', cat: 'funny',  dict: 'reaction@intimidation@1h@',                                             clip: 'intro',                 loop: false },
    { id: 'cry',           label: 'Cry',              emoji: '😭', cat: 'funny',  dict: 'missfam5_heistchina_b',                                                 clip: 'a_m_y_skater_01_idle',  loop: false },
    { id: 'laugh',         label: 'Laugh',            emoji: '😂', cat: 'funny',  dict: 'anim@mp_player_introcelebrations@upper',                                clip: 'laugh',                 loop: false },
    { id: 'victory',       label: 'Victory',          emoji: '🏆', cat: 'funny',  dict: 'anim@mp_player_introcelebrations@upper',                                clip: 'victory',               loop: false },
    { id: 'loser',         label: 'Loser',            emoji: '😅', cat: 'funny',  dict: 'anim@mp_player_introcelebrations@upper',                                clip: 'loser',                 loop: false },
    { id: 'rockpapersc',   label: 'Rock Paper Sc.',   emoji: '✂️',  cat: 'funny',  dict: 'anim@mp_player_introcelebrations@upper',                                clip: 'rock_paper_scissors',   loop: false },
    { id: 'shakebutt',     label: 'Shake It',         emoji: '🫣', cat: 'funny',  dict: 'anim@mp_player_introcelebrations@upper',                                clip: 'wiggle',                loop: false },
    { id: 'spook',         label: 'Spook',            emoji: '👻', cat: 'funny',  dict: 'rcmpaparazzo3',                                                         clip: 'a_m_y_juggalo_01_idle', loop: true  },
    { id: 'boxingpose',    label: 'Boxing Pose',      emoji: '🥊', cat: 'funny',  dict: 'anim@mp_player_introcelebrations@upper',                                clip: 'boxing_pose',           loop: false },
];

let currentEmoteCat = 'all';
let currentPlayingEmote = null;

function setEmoteCat(btn, cat) {
    currentEmoteCat = cat;
    currentEmoteLimit = 120;
    document.querySelectorAll('[data-emote-cat]').forEach(b => b.classList.remove('active'));
    if (btn) btn.classList.add('active');
    renderEmotes();
}

window.resetEmoteLimitAndRender = function() {
    currentEmoteLimit = 120;
    renderEmotes();
};

window.loadMoreEmotes = function() {
    currentEmoteLimit += 180;
    renderEmotes();
};

function getCombinedEmotesCatalog() {
    if (allServerEmotes && allServerEmotes.length > 0) {
        return allServerEmotes;
    }
    return EMOTES_LIST;
}

function renderEmotes() {
    const search = (document.getElementById('emote-search')?.value || '').toLowerCase().trim();
    const grid   = document.getElementById('emotes-grid');
    if (!grid) return;

    const sourceList = getCombinedEmotesCatalog();
    const badgeEl = document.getElementById('emote-total-badge');
    if (badgeEl) {
        badgeEl.innerText = `${sourceList.length.toLocaleString()} Animations`;
    }

    const filtered = sourceList.filter(e => {
        const idStr = (e.id || '').toLowerCase();
        const labelStr = (e.label || e.id || '').toLowerCase();
        const catStr = (e.cat || 'dance').toLowerCase();
        const packStr = (e.pack || '').toLowerCase();

        const termOk = !search || labelStr.includes(search) || idStr.includes(search) || catStr.includes(search) || packStr.includes(search);
        if (!termOk) return false;

        if (currentEmoteCat === 'favorites') {
            return Favorites.has('emotes', idStr);
        }
        if (search.length > 0 && currentEmoteCat === 'all') return true;
        if (currentEmoteCat === 'all') return true;
        return catStr === currentEmoteCat;
    });

    if (!filtered.length) {
        grid.innerHTML = '<div style="color:var(--text-muted);padding:24px;text-align:center;grid-column:1/-1;">Aucune danse ou animation trouvée.</div>';
        return;
    }

    const slice = filtered.slice(0, currentEmoteLimit);
    const hasMore = filtered.length > currentEmoteLimit;

    let html = slice.map(e => {
        const isPlaying = currentPlayingEmote === e.id;
        const isFav = Favorites.has('emotes', e.id);
        const safeId = escapeHtml(e.id || '');
        const safeLabel = escapeHtml(e.label || e.id || 'Dance');
        const safeDict = escapeHtml(e.dict || '');
        const safeClip = escapeHtml(e.clip || '');
        const safeScenario = escapeHtml(e.scenario || '');
        const safePack = e.pack ? `<div style="font-size:0.62rem;color:var(--accent-cyan);opacity:0.85;margin-top:2px;">${escapeHtml(e.pack)}</div>` : '';
        const loopBool = e.loop !== false;

        return `<div class="emote-card${isPlaying ? ' playing' : ''}" style="position:relative;" onclick="playEmote('${safeId}','${safeDict}','${safeClip}',${loopBool},'${safeLabel}','${safeScenario}')">
            <button type="button" class="fav-star-btn ${isFav ? 'active' : ''}" onclick="event.stopPropagation(); toggleFavorite('emotes', '${safeId}')" title="Ajouter aux favoris" style="position:absolute;top:6px;right:6px;background:none;border:none;cursor:pointer;font-size:0.9rem;color:${isFav ? '#ffd700' : 'rgba(255,255,255,0.28)'};">★</button>
            <div class="emote-emoji">${e.emoji || '🕺'}</div>
            <div class="emote-name" title="/e ${safeId}">${safeLabel}</div>
            <div style="font-size:0.65rem;color:var(--text-muted);font-family:'JetBrains Mono',monospace;">/e ${safeId}</div>
            ${safePack}
            <div class="emote-cat-badge">${escapeHtml(e.cat || 'dance')}</div>
        </div>`;
    }).join('');

    if (hasMore) {
        const remaining = filtered.length - currentEmoteLimit;
        html += `<div style="grid-column: 1 / -1; text-align: center; padding: 14px;">
            <button type="button" class="secondary-btn" onclick="loadMoreEmotes()" style="padding: 10px 24px; font-weight: 800; border-color: var(--accent-cyan); color: var(--accent-cyan);">
                ➕ Afficher plus de danses (${remaining.toLocaleString()} restantes sur ${filtered.length.toLocaleString()})
            </button>
        </div>`;
    }

    grid.innerHTML = html;
}

function playEmote(id, dict, clip, loop, label, scenario) {
    currentPlayingEmote = id;
    renderEmotes();

    const targetSel = document.getElementById('emote-target-select');
    const target = targetSel ? targetSel.value : 'self';

    const bar = document.getElementById('emote-now-playing');
    const lbl = document.getElementById('emote-now-label');
    if (bar && lbl) {
        bar.style.display = 'block';
        const targetText = target === 'all' ? ' [🌐 TOUT LE SERVEUR]' : (target !== 'self' ? ` [🎯 Joueur #${target}]` : ' [👤 Moi-même]');
        lbl.textContent = `${label} (/e ${id})${targetText}`;
    }

    postNUI('playEmote', { id, dict, clip, loop, label, scenario: scenario || null, target });
}

function stopEmote() {
    currentPlayingEmote = null;
    renderEmotes();
    const targetSel = document.getElementById('emote-target-select');
    const target = targetSel ? targetSel.value : 'self';
    const bar = document.getElementById('emote-now-playing');
    if (bar) bar.style.display = 'none';
    postNUI('stopEmote', { target });
}

// Manage Tab: Force Dance on Managed Player
window.forceDanceOnManagedPlayer = function(presetEmoteId) {
    const targetId = document.getElementById('manage-target-id')?.value;
    if (!targetId) {
        showToast('Force Dance', 'Sélectionnez d’abord un joueur.', 'error');
        return;
    }
    const inputEl = document.getElementById('manage-force-emote-id');
    const query = (presetEmoteId || inputEl?.value || '').trim().toLowerCase();
    if (!query) {
        showToast('Force Dance', 'Entrez le code ou nom d’une danse (ex: dance, siu, twerk).', 'warning');
        return;
    }

    const catalog = getCombinedEmotesCatalog();
    const match = catalog.find(e => (e.id || '').toLowerCase() === query)
               || catalog.find(e => (e.label || '').toLowerCase().includes(query) || (e.id || '').toLowerCase().includes(query));

    const payload = match ? {
        id: match.id,
        dict: match.dict,
        clip: match.clip,
        loop: match.loop !== false,
        label: match.label || match.id,
        scenario: match.scenario || null,
        target: targetId
    } : {
        id: query,
        dict: '',
        clip: '',
        loop: true,
        label: query,
        target: targetId
    };

    postNUI('playEmote', payload);
    showToast('🕺 Force Dance', `Animation "${payload.label}" lancée sur le joueur #${targetId} !`, 'success');
};

window.stopDanceOnManagedPlayer = function() {
    const targetId = document.getElementById('manage-target-id')?.value;
    if (!targetId) return;
    postNUI('stopEmote', { target: targetId });
    showToast('⏹️ Stop Dance', `Animation arrêtée sur le joueur #${targetId}.`, 'info');
};

window.openEmotesTabForManagedPlayer = function() {
    const targetId = document.getElementById('manage-target-id')?.value;
    const emotesNav = document.querySelector('.nav-item[data-tab="emotes"]');
    if (emotesNav) emotesNav.click();
    if (targetId) {
        setTimeout(() => {
            const sel = document.getElementById('emote-target-select');
            if (sel) sel.value = String(targetId);
        }, 120);
    }
};

// Handle Lua -> JS emoteStopped event (player moved)
window.addEventListener('message', function(ev) {
    if (ev.data && ev.data.action === 'emoteStopped') {
        currentPlayingEmote = null;
        const bar = document.getElementById('emote-now-playing');
        if (bar) bar.style.display = 'none';
        if (currentTab === 'emotes') renderEmotes();
    }
});

// ===== end of emotes system =====
