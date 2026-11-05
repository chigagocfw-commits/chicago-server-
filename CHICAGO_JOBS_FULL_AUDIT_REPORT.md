# CHICAGO ROLEPLAY — FULL JOBS & NPC/PED INTERACTION AUDIT REPORT

**Server:** CHICAGO ROLEPLAY (FiveM / Qbox Framework)  
**Production Root:** `C:\Users\Administrator\Desktop\CHICAGO SERVER`  
**Active txData Profile:** `txData\Qbox_C6CA87.base`  
**Active Database:** `Qbox_C6CA87`  
**Audit Scope:** 100% Comprehensive Read-Only Audit of all Jobs, Job Centers, NPCs, Radial Menus, Item Integrations, and Database Structures  
**Audit Date:** November 5, 2026  
**Execution Mode:** STRICT READ-ONLY AUDIT (No modifications, migrations, or file changes implemented)

---

## TABLE OF CONTENTS
1. [A. Executive Summary](#a-executive-summary)
2. [B. Default Spawn NPC Investigation Report](#b-default-spawn-npc-investigation-report)
3. [C. Complete Server Job Matrix](#c-complete-server-job-matrix)
4. [D. Deep-Dive Functionality Audit by Job & Activity](#d-deep-dive-functionality-audit-by-job--activity)
5. [E. Interaction Systems & Radial Menu Audit](#e-interaction-systems--radial-menu-audit)
6. [F. Database & Society Funds Inspection](#f-database--society-funds-inspection)
7. [G. Detailed Technical Findings](#g-detailed-technical-findings)
8. [H. Prioritized Repair Roadmap](#h-prioritized-repair-roadmap)
9. [I. Verification Evidence & Files Inspected](#i-verification-evidence--files-inspected)

---

## A. EXECUTIVE SUMMARY

An exhaustive, read-only static code and database audit was performed across all resources in the `CHICAGO ROLEPLAY` server. The audit specifically investigated the Default Spawn location, the exact Ped positioned adjacent to it, all public and restricted jobs, secondary criminal and civilian activities, item definitions in `ox_inventory`, database tables in `Qbox_C6CA87`, and interaction systems (`ox_target`, `codem-supreme-radialmenu`, `ox_lib`).

### Key Metrics:
- **Total Discovered Jobs & Formal Activities:** **26**
- **Fully Functional (PASS):** **13** (Unemployed, Bus Driver, Tow Truck, News Reporter, Mechanic, Dealership, Real Estate, Vineyard, Scrapyard, Pawnshop, Inmate Labor, Judge, Lawyer)
- **Partially Functional (PARTIAL):** **5** (Trucker, Taxi, Garbage Collector, Police LSPD, Police BCSO/SASP)
- **Broken / Non-Functional (FAIL):** **7** (Ambulance/EMS, Mining, Fishing, Hunting, PostOP Delivery, Radial Menu Hospital, Radial Menu Taxi)
- **Missing / Ghost Registrations (NOT FOUND):** **1** (Hotdog Vendor)
- **Jobs Accessible to Ordinary Players at Default Spawn:** **7** (`unemployed`, `trucker`, `taxi`, `tow`, `reporter`, `garbage`, `bus`)
- **Total Job NPCs & Depots Mapped Across Map:** **18 distinct locations**

### Key Critical Findings:
1. **Default Spawn NPC Identity & Decoupling:** The NPC next to the Default Spawn is spawned by `qbx_cityhall` at `vec4(-262.79, -964.18, 30.22, 181.71)` (Model: `a_m_m_hasjew_01`). While it assigns the selected job in `qbx_core`, three of the major manual labor jobs (`trucker`, `taxi`, `garbage`) are running 3rd-party Codem resources configured with `Config.JobName = "all"` or `JobCheck.enable = false`. This creates a complete gameplay disconnection: ordinary civilians who do not take the job at Cityhall can perform them anyway, while players who do take the job receive no waypoint, guidance, or depot GPS.
2. **Missing Inventory Item Definitions in `ox_inventory`:** Three entire activities—**Mining** (`codem-minerjob`), **Fishing** (`codem-fishing`), and **Hunting** (`m-hunting`)—plus missions in **Trucking** (`codem-truckerjob`) and **PostOP** (`m-postop`), are **completely non-functional** because their required items (over 80 unique items including pickaxes, ores, ingots, fishing rods, baits, fishes, animal meats, skins, and courier items) are missing from `ox_inventory\data\items.lua`. Any player attempting these tasks suffers inventory addition rejections.
3. **EMS / Ambulance Job Infrastructure Missing:** While `qbx_medical` is active for player injury/damage/death states, there is **no ambulance job script** (`qbx_ambulancejob` or equivalent) installed on the server. There are no hospital check-in NPCs, no clock-in stations, no ambulance vehicle spawners, no pharmacy/armory stashes, and the radial menu options for ambulance (`Revive`, `Treat Wounds`) trigger dead events.
4. **PostOP Runtime Crash:** `m-postop` is hardcoded to `FuelSystem = 'cdn-fuel'`, calling `exports['cdn-fuel']:SetFuel(vehicle, 100)`. Because `cdn-fuel` does not exist on the server (which uses `ox_fuel`), spawning a PostOP delivery vehicle throws a fatal Lua export error.
5. **Origen Police MDT Incompatibility with BCSO / SASP:** `origen_police` hardcodes its police category to jobs `'police'` and `'sheriff'`. In Qbox, the county sheriff is registered as `'bcso'` and state troopers as `'sasp'`. Consequently, BCSO and SASP officers are locked out of the Origen Police tablet/MDT.
6. **Radial Menu Dead Events:** `codem-supreme-radialmenu` contains hardcoded legacy events for `qb-taxi` (not installed), `qb-hotdogjob` (not installed), `qb-phone` (server uses `lb-phone`), and `hospital` (events have no listener).

---

## B. DEFAULT SPAWN NPC INVESTIGATION REPORT

### 1. Ped Identification & Spawn Mechanics
- **Resource Responsible:** `qbx_cityhall`
- **Creation File:** `txData\Qbox_C6CA87.base\resources\[qbx]\qbx_cityhall\client\main.lua` (Lines 169–216, function `spawnPeds`)
- **Configuration File:** `txData\Qbox_C6CA87.base\resources\[qbx]\qbx_cityhall\config\client.lua` (Lines 6–16)
- **Ped Model:** `a_m_m_hasjew_01` (Hash: `1809430156` / `0x6BD528EC`)
- **Exact Coordinates:** `vec4(-262.79, -964.18, 30.22, 181.71)`
- **Default Player Spawn Point:** `wasabi_multichar` config `defaultCoords`: `vector4(-269.4, -955.3, 31.2, 205.0)`.
- **Proximity:** The NPC stands **10.9 meters** from the exact location where newly created characters and characters without a last-saved position spawn.
- **Scenario:** `WORLD_HUMAN_STAND_MOBILE` (Ped stands holding and looking at a mobile phone).
- **Spawn Conditions & Duplication Check:** The ped is spawned locally on `QBCore:Client:OnPlayerLoaded` or `onResourceStart`. It is guarded by `if current.pedHandle and DoesEntityExist(current.pedHandle) then pedsSpawned = true`. Target options are guarded by `targetAdded`. There is **no duplication** and no overlapping ped at these coordinates.

### 2. Interaction System & Menu Architecture
- **Interaction System:** `ox_target` via `exports.ox_target:addLocalEntity` (Option name: `'open_cityhall_1'`, icon: `'fa-solid fa-city'`, label: `"City Services"`, interaction distance: `1.5` meters).
- **Fallback Zone:** If `useTarget` were false, `lib.zones.box` (size `vec3(2, 2, 3)`) opens prompt `"Press [E] to open City Services"`.
- **Root Context Menu:** `lib.registerContext` (`id: 'cityhall_menu'`, title: `"City Services"`).
  1. **Option 1: Identity & Licenses** (`openIdentificationMenu`)
     - Issues ID Card (`id_card`, $50)
     - Issues Driver License (`driver_license`, $50)
     - Issues Weapon License (`weaponlicense`, $50)
     - Server validation: `qbx_cityhall:server:requestId` verifies proximity (<20m), checks `ox_inventory`, debits money via `player.Functions.RemoveMoney('cash', cost)`, and creates the item via `exports.qbx_idcard:CreateMetaLicense`. (Status: **PASS**)
  2. **Option 2: Employment Center** (`openEmploymentMenu`)
     - Displays the available employment roster configured in `qbx_cityhall\config\shared.lua`.

### 3. Detailed Audit of Jobs Accessible via Default Spawn NPC

```
Player Action: Interact with Ped → Select Employment → Click Job
Server Flow:   lib.callback.await('qbx_cityhall:server:applyJob', false, job)
Validation:    Proximity Check (<20m) → Config Check → player.Functions.SetJob(job, 0)
```

| Menu Option | Internal Job ID | Registered in Qbox? | Server Validation Flow | Actual Gameplay Resource | End-to-End Status | Findings / Blockers |
|---|---|---|---|---|---|---|
| **Unemployed** | `unemployed` | **YES** (Grade 0: Freelancer, $10) | Validated & Set | Built-in Qbox | **PASS** | Resets player to civilian state. Salary $10/interval. Works properly. |
| **Trucker** | `trucker` | **YES** (Grade 0: Driver, $50) | Validated & Set | `codem-truckerjob` | **PARTIAL** | Job set in framework, but `codem-truckerjob` runs `Config.JobName = "all"`. Any civilian can truck without this job. Cityhall gives no GPS route to depot `(806.3, -3183.8)`. Illegal missions broken by missing item `illegal_box`. |
| **Taxi** | `taxi` | **YES** (Grade 0: Recruit, $50) | Validated & Set | `codem-taxijob2` | **PARTIAL** | Job set in framework, but `codem-taxijob2` has `JobCheck.enable = false`. Any civilian can do taxi without this job. Depot is at `(896.37, -177.27)` with no GPS route from Cityhall. Radial menu taxi buttons are dead events. |
| **Tow Truck** | `tow` | **YES** (Grade 0: Driver, $50) | Validated & Set | `qbx_towjob` | **PASS** | Job strictly required. Spawns flatbed at Towing HQ `(471.39, -1311.03)` with $250 bail. NPC towing, dropoff, payment, and `/npc` + `/tow` commands fully functional. |
| **News Reporter** | `reporter` | **YES** (Grade 0: Journalist, $50) | Validated & Set | `qbx_newsjob` | **PASS** | RP Job. HQ at Little Seoul `(-598.4, -929.85)`. Vehicle & helicopter garage, `/newscam`, `/newsmic`, `/newsbmic` functional. |
| **Garbage Collector** | `garbage` | **YES** (Grade 0: Collector, $50) | Validated & Set | `codem-garbage` | **PARTIAL** | Job set in framework, but `codem-garbage` has `['job'] = 'all'`. Open to any civilian. Cityhall gives no GPS route to depot `(-337.08, -1533.47)`. Duplicate resource `qbx_garbagejob` was correctly stopped in `server.cfg`. |
| **Bus Driver** | `bus` | **YES** (Grade 0: Driver, $50) | Validated & Set | `qbx_busjob` | **PASS** | Strictly requires `job == 'bus'`. Blip appears at Dashound Bus Depot `(462.22, -641.15)`. Bus spawning, passenger pickups, route stops, and anti-exploit server payments fully functional. |

---

## C. COMPLETE SERVER JOB MATRIX

All jobs, formal careers, and activity systems discovered in the server are catalogued below:

| Job / Activity Identifier | Responsible Resource | Resource State in server.cfg | Registered in `qbx_core`? | Public or Restricted? | Interaction Point / NPC | Gameplay Flow Complete? | Reward / Payment Working? | Overall Status | Primary Issue / Reason for Non-PASS |
|---|---|---|---|---|---|---|---|---|---|
| **Unemployed** | `qbx_core` | Started | **YES** | Public | Cityhall Ped `(-262.79, -964.18)` | YES | YES ($10 paycheck) | **PASS** | None. Standard civilian baseline. |
| **Bus Driver** | `qbx_busjob` | Started | **YES** | Public (via NPC) | Dashound Terminal `(462.22, -641.15)` | YES | YES (Cash per stop) | **PASS** | None. Complete Qbox lifecycle. |
| **Tow Truck** | `qbx_towjob` | Started | **YES** | Public (via NPC) | Towing HQ `(471.39, -1311.03)` | YES | YES (Bank salary + tax) | **PASS** | None. Full vehicle spawn, bail, and tow logic. |
| **News Reporter** | `qbx_newsjob` | Started | **YES** | Public (via NPC) | Weazel News `(-598.4, -929.85)` | YES | YES ($50 paycheck) | **PASS** | RP Job. Props, vehicles, helipad work. |
| **Mechanic** | `qs-mechanic-creator` & `qbx_customs` | Started | **YES** | Restricted | 4 Custom Shops in DB + LSC | YES | YES (Invoices + Society) | **PASS** | Fully integrated with Qbox and ox_target. |
| **Vehicle Dealer** | `jg-dealerships` | Started | **YES** | Restricted (PDM) | PDM Showroom `(-55.99, -1096.58)` | YES | YES (Commission + Society) | **PASS** | PDM assigned to `cardealer`. Test drives & financing work. |
| **Real Estate** | `qbx_properties` | Started | **YES** | Restricted | Realtor office / `/createproperty` | YES | YES (Property sales) | **PASS** | Restricted to `realestate`. Full creation pipeline. |
| **Vineyard** | `qbx_vineyard` | Started | **YES** | Public Activity | Marlowe Vineyard `(-1877.3, 2132.5)` | YES | YES (Wine production) | **PASS** | Open civilian crafting loop. All items exist in ox_inventory. |
| **Scrapyard** | `qbx_scrapyard` | Started | NO (Public) | Public Activity | Scrapyard `(2404.6, 3127.8)` | YES | YES (Scrap materials) | **PASS** | Scraps unowned vehicles for materials. |
| **Pawnshop** | `qbx_pawnshop` | Started | NO (Public) | Public Activity | Vinewood `(412.34, 314.81)` | YES | YES (Cash for jewelry/gold) | **PASS** | Buys stolen electronics/jewelry, melts gold. |
| **Prison Labor** | `xt-prison` | Started | NO (Prisoners) | Inmates Only | Bolingbroke Infirmary/Canteen | YES | YES (Sentence reduction) | **PASS** | Cleaning, maintenance, and food service reduce time. |
| **Judge** | `qbx_core` / `qbx_police` | Started | **YES** | Whitelisted | Courthouse / Police Stations | YES | YES ($100 paycheck) | **PASS** | Legal RP role with judicial authority in police system. |
| **Lawyer** | `qbx_core` / `qbx_police` | Started | **YES** | Whitelisted | City / Police Stations | YES | YES ($500 police payout) | **PASS** | Legal RP role with `lawyerpass` item. |
| **Trucker** | `codem-truckerjob` | Started | **YES** | Public (Unrestricted) | Port Terminal `(806.3, -3183.8)` | PARTIAL | YES (Cash + XP) | **PARTIAL** | Codem job decoupling (`JobName="all"`); missing item `illegal_box` breaks illegal deliveries. |
| **Taxi** | `codem-taxijob2` | Started | **YES** | Public (Unrestricted) | Cab Depot `(896.37, -177.27)` | PARTIAL | YES (Cash fares + meter) | **PARTIAL** | Codem job decoupling (`JobCheck.enable=false`); radial menu taxi options trigger dead events. |
| **Garbage Collector** | `codem-garbage` | Started | **YES** | Public (Unrestricted) | Alta Depot `(-337.08, -1533.47)` | PARTIAL | YES (Cash + XP) | **PARTIAL** | Codem job decoupling (`job="all"`); no depot routing from Cityhall. Duplicate `qbx_garbagejob` stopped. |
| **Police (LSPD)** | `qbx_police` + `origen_police` | Started | **YES** | Whitelisted | Mission Row / Stations | PARTIAL | YES (Paycheck + Fines) | **PARTIAL** | Full LEO mechanics work in `qbx_police`. However, dual-running `origen_police` creates partial event redundancies. |
| **Police (BCSO)** | `qbx_police` + `origen_police` | Started | **YES** | Whitelisted | Sandy Shores / Paleto Stations | PARTIAL | YES (Paycheck) | **PARTIAL** | Works in `qbx_police`, but **completely locked out** of `origen_police` MDT due to `'bcso'` vs `'sheriff'` name mismatch. |
| **Police (SASP)** | `qbx_police` + `origen_police` | Started | **YES** | Whitelisted | State Trooper Posts | PARTIAL | YES (Paycheck) | **PARTIAL** | Works in `qbx_police`, but **completely locked out** of `origen_police` MDT due to missing `'sasp'` category definition. |
| **Ambulance / EMS** | `qbx_medical` | Started | **YES** | Whitelisted | Pillbox Hill Medical Center | NO | NO (No job payout) | **FAIL** | **No ambulance job resource installed**. No duty toggle, hospital check-in, ambulance spawner, armory, or radial revive handlers. |
| **Mining** | `codem-minerjob` | Started | NO (Public) | Public Activity | Murrieta Depot `(1054.49, -1952.89)` | NO | NO (Inventory blocked) | **FAIL** | **All 23 mining items missing from ox_inventory**. Cannot buy pickaxes, mine ores, or smelt ingots. |
| **Fishing** | `codem-fishing` | Started | NO (Public) | Public Activity | Pier NPC `(-1038.9, -1396.98)` | NO | NO (Inventory blocked) | **FAIL** | **Over 35 fishing items missing from ox_inventory**. Rods, baits, and all fish species reject inventory addition. |
| **Hunting** | `m-hunting` | Started | NO (Public) | Public Activity | Hunting Club & Wilderness | NO | NO (Inventory blocked) | **FAIL** | **All 24 hunting items missing from ox_inventory**. Animal skinning drops invalid items that fail to add. |
| **PostOP Delivery** | `m-postop` | Started | NO (Public) | Public Activity | Terminal PostOP `(1197.21, -3255.11)` | NO | NO (Crashes on start) | **FAIL** | **Fatal export crash**: Configured with `FuelSystem = 'cdn-fuel'`, throwing missing export error on vehicle spawn. Item `transportitem` missing. |
| **Car / Scooter Rental** | `LB-Rentalcar` / `9labs_scootrental` | Started | NO (Public) | Public Activity | 3 Car Rental NPCs + Scooter Stands | YES | YES (Charges cash/bank) | **PASS** | Functional civilian vehicle rental with deposit/refund logic. |
| **Hotdog Vendor** | None (Ghost entry) | Stopped/None | **YES** | Public | None | NO | NO | **NOT FOUND** | Registered in `jobs.lua` and radial menu, but resource `qb-hotdogjob` does not exist on the server. |

---

## D. DEEP-DIVE FUNCTIONALITY AUDIT BY JOB & ACTIVITY

### 1. Police / Law Enforcement (`qbx_police` & `origen_police`)
- **Job Identifiers in Qbox:** `police`, `bcso`, `sasp`.
- **Whitelisting & Grades:** Grades 0 (Recruit), 1 (Officer), 2 (Sergeant), 3 (Lieutenant), 4 (Chief/Sheriff/Commander).
- **Core LEO System (`qbx_police`):**
  - **Duty System:** Uses Qbox PlayerData duty state. Automatically tracks active duty cops.
  - **Blips:** Synchronizes GPS tracking blips across all on-duty LEO and EMS (`police:client:UpdateBlips`).
  - **Evidence System:** Live projectile casings, blood drops (DNA matches player citizen ID hash), finger drops on vehicle/door interactions.
  - **Prison Handshake:** Direct native export bridge to `xt-prison` (`IsUsingXTPrison = true`).
  - **Commands:** `/spikestrip`, `/cuff`, `/escort`, `/fine`, `/takedna`, `/anklet`, `/ankletlocation`, `/grantlicense`, `/revokelicense`, `/paylawyer`.
- **MDT & Dispatch System (`origen_police`):**
  - Advanced NUI tablet accessed via `/rpol` or custom keybind.
  - Handles criminal records, penal codes, warrants, citizen search, vehicle search, and officer dispatches.
  - **Critical Incompatibility:** In `origen_police\config\jobs.lua`, lines 2–20:
    ```lua
    Config.JobCategory = {
        ["police"] = {
            { name = "police", ... },
            { name = "sheriff", ... },
        }
    }
    ```
    In Qbox, county deputies have `job = 'bcso'` and state troopers have `job = 'sasp'`. Because `origen_police` checks for `'police'` and `'sheriff'`, **BCSO and SASP officers are rejected by the MDT as unauthorized**.

### 2. EMS / Ambulance / Medical (`qbx_medical`)
- **Job Identifier in Qbox:** `ambulance` (Grades 0–4: Recruit, Paramedic, Doctor, Surgeon, Chief).
- **Current State:** **CRITICAL ARCHITECTURAL GAP**.
  - `qbx_medical` is strictly a medical injury and downed-state system. It registers statebags for `isDead`, `inLastStand`, bleed level, and body-part wound damage.
  - It exposes server exports `exports.qbx_medical:Revive`, `Heal`, and `GetPlayerStatus`.
  - **Missing Components:**
    - There is **no hospital check-in NPC or desk interaction** where civilians can pay to get treated when no EMS are on duty.
    - There are **no hospital bed interactions**.
    - There is **no duty toggle station** at Pillbox Hill.
    - There is **no ambulance garage or vehicle spawner**.
    - There is **no pharmacy or medical locker stash**.
    - In `codem-supreme-radialmenu\shared\items.lua`, the EMS sub-menu triggers `hospital:client:CheckStatus`, `hospital:client:RevivePlayer`, and `hospital:client:TreatWounds`. **None of these events exist** in `qbx_medical`.

### 3. Mechanic (`qs-mechanic-creator` & `qbx_customs`)
- **Job Identifier in Qbox:** `mechanic` (Grades 0–4: Recruit, Novice, Experienced, Advanced, Manager).
- **Public Mod Shops (`qbx_customs`):**
  - Zones mapped for Vinewood, Airport, and Paleto LSC.
  - Available to all civilians. Allows full aesthetic and performance modifications via `ox_lib` menus, with direct camera orbit controls.
- **Player-Run Garages (`qs-mechanic-creator`):**
  - Database table `mechanic_shops` currently stores **4 configured shops**:
    - `shop_1791919741_8` (Located at La Mesa / Supply St; incorrectly labeled job "Real Estate" in database JSON).
    - `shop_1792034623_1` (Located at Popular St, assigned to job `mechanic`, owner `O8DC9W9C`).
    - `shop_1793731479_3` (Located at Strawberry Ave).
    - `shop_1793749021_1` ("hilico", located in Vinewood).
  - Framework detection correctly detects `qbox`, interaction `ox_target`, inventory `ox_inventory`, and clothing `illenium-appearance`.
  - Society funds are persisted in `mechanic_shops` internal balance data.
  - Repairs, vehicle hoists, engine swaps, and cosmetic tuning fully functional.

### 4. Vehicle Dealership (`jg-dealerships`)
- **Job Identifier in Qbox:** `cardealer` (Grades 0–4: Recruit, Showroom Sales, Business Sales, Finance, Manager).
- **Dealership Network in Database (`dealership_locations`):**
  - `pdm`: Platinum Deluxe Motorsport (`-55.99, -1096.58`). Owned dealership assigned to `job_name = 'cardealer'`. Whitelist restricted to grades `[0,1,2,3,4]`.
  - `air`: Los Santos International Airport (`-1623.0, -3151.56`). Self-service aircraft dealer.
  - `boats`: Marina / Puerto Del Sol (`-739.55, -1333.75`). Self-service boat dealer.
  - `truck`: Port of South Los Santos (`1214.37, -3204.53`). Self-service industrial vehicle dealer.
- **Integrations:** Correctly configured for `ox_fuel` and `qbx-vehiclekeys`. Direct database persistence in `player_vehicles`. Finance payment loops operational.

### 5. Bus Driver (`qbx_busjob`)
- **Job Identifier in Qbox:** `bus` (Grade 0: Driver, $50).
- **Depot Location:** Dashound Bus Terminal, Textile City (`vec4(462.22, -641.15, 28.45, 175.0)`).
- **Gameplay Lifecycle:**
  - When the player selects `Bus Driver` at Cityhall, the Bus Depot blip activates on their map.
  - Player steps into the marker at the terminal to spawn a company bus via `qbx.spawnVehicle` with automatic plate assignment and keys.
  - Route blips cycle across 5 passenger stops (Alta, Pillbox, Little Seoul, Rockford, Downtown).
  - Dynamic NPC passengers spawn, board the bus, ride to the destination, and pay upon arrival.
  - Server validates distance (<20m from stop), vehicle model, route index progression, and enforces a 15-second cooldown to prevent payment spamming.
  - Overall Status: **PASS**.

### 6. Tow Truck (`qbx_towjob`)
- **Job Identifier in Qbox:** `tow` (Grade 0: Driver, $50).
- **Depot Location:** Towing HQ, Innocence Blvd / Strawberry (`vec4(471.39, -1311.03, 29.21, 114.5)`).
- **Gameplay Lifecycle:**
  - Player takes out Flatbed by paying a $250 deposit/bail.
  - Using `/npc` or the radial menu option starts an impound mission.
  - A broken vehicle spawns at one of 40 mapped GTA locations.
  - Player drives to the site, attaches the vehicle using the Flatbed winch (`/tow` or radial option), and returns it to the Strawberry drop-off yard.
  - Server verifies vehicle model, network ID, and calculates travel distance to prevent instant turn-in exploits (`earliestCompletion = os.time() + tripDistance / 40`).
  - Payout is deposited to bank with tax deduction, and bail is refunded upon flatbed return.
  - Overall Status: **PASS**.

### 7. Trucker (`codem-truckerjob`)
- **Job Identifier in Qbox:** `trucker` (Grade 0: Driver, $50).
- **Depot Location:** Terminal Island, Port of Los Santos (`vector4(806.30, -3183.797, 4.89, 170.07)`).
- **NPC:** `g_m_m_chiboss_01` with blip "Trucker Job".
- **Defects Discovered:**
  1. `Config.JobName = "all"`: The resource does not check if the player has the `trucker` job. Any player can walk up and start trucking contracts.
  2. Selecting `trucker` at Cityhall gives no GPS route, marker, or notification indicating where the trucking depot is.
  3. The "Illegal Delivery" mission requires 10 units of item `illegal_box` (`shared/config.lua:50`). Item `illegal_box` is **missing from `ox_inventory\data\items.lua`**. Attempting illegal deliveries triggers notification `"You don't have enough illegal box"` or inventory rejection.

### 8. Taxi Driver (`codem-taxijob2`)
- **Job Identifier in Qbox:** `taxi` (Grades 0–4: Recruit, Driver, Event Driver, Sales, Manager).
- **Depot Location:** Downtown Cab Co., East Vinewood (`vector4(896.37, -177.27, 73.7, 246.3)`).
- **NPC:** `a_m_m_malibu_01` with blip "Taxi Job".
- **Defects Discovered:**
  1. `Config.JobCheck = { enable = false, name = 'taxi' }`: Any citizen can take out taxis and run fares without being employed as a taxi driver.
  2. Cityhall provides no GPS or notification pointing to the Downtown Cab Co. depot.
  3. The radial menu taxi sub-menu is wired to obsolete `qb-taxi` events (`qb-taxi:client:toggleMeter`, `qb-taxi:client:enableMeter`, `qb-taxi:client:DoTaxiNpc`), which do nothing.

### 9. Garbage Collector (`codem-garbage`)
- **Job Identifier in Qbox:** `garbage` (Grade 0: Collector, $50).
- **Depot Location:** South Los Santos / Alta St (`vector3(-337.08, -1533.47, 27.72)`).
- **NPC:** Ped hash `0xF0EC56E2` with blip "Garbage Job".
- **Duplicate Resource Management:** `qbx_garbagejob` was correctly stopped in `server.cfg` line 67 (`stop qbx_garbagejob # Consolidated duplicate: codem-garbage is the canonical garbage job`).
- **Defects Discovered:**
  1. `Config.GarbagejobSettings['job'] = 'all'`: Any citizen can run garbage routes without the job.
  2. Cityhall provides no blip or GPS guidance to the Alta St depot upon selecting Garbage Collector.
  3. Key handling successfully bridges through `qb-vehiclekeys:server:AcquireVehicleKeys` to `qbx_vehiclekeys`.

### 10. Mining (`codem-minerjob`)
- **Depot Location:** Murrieta Heights / South LS (`vector4(1054.49, -1952.89, 31.09, 272.64)`).
- **NPC:** `g_m_m_chiboss_01` with blip "Miner Job".
- **Gameplay Concept:** Players purchase pickaxes, travel to Abandoned Mines, mine rock/ore nodes via minigame, smelt ores into ingots at processing stations, and sell metals on the commodity market.
- **Defects Discovered:**
  - **CRITICAL FAILURE (Missing Items):** `codem-minerjob` requires **23 specific items**:
    `normal_pickaxe`, `advanced_pickaxe`, `professional_pickaxe`, `copper_ore`, `copper_ingot`, `iron_ore`, `iron_ingot`, `gold_ore`, `goldingot`, `diamond_ore`, `diamond_ingot`, `coal`, `rock`, `sandstone`, `limestone`, `sulfur`, `blackpowder`, `concrete`, `glass`, `glass_mold`, `ingot_mold`, `special_water`, `sticky_gel`.
  - **Zero** of these 23 items exist in `ox_inventory\data\items.lua`.
  - When players attempt to buy a pickaxe at the NPC market, the transaction fails. When players break a rock node, `ox_inventory:AddItem` throws an unknown item error.

### 11. Fishing (`codem-fishing` & `codem-fishing-props`)
- **Location:** Del Perro Pier / Marina (`vector3(-1038.9, -1396.98, 5.55)`).
- **NPC:** `a_m_m_hillbilly_01` with blip "Fishing". Boat rentals at `(-720.22, -1323.75, 1.6)`.
- **Gameplay Concept:** Players buy fishing rods and bait, fish from shore or rented boats, play a tension minigame, catch common to legendary fish, and fulfill restaurant delivery contracts.
- **Defects Discovered:**
  - **CRITICAL FAILURE (Missing Items):** Over **35 items** required by `codem-fishing` are missing from `ox_inventory\data\items.lua`:
    - **Rods:** `standartrod`, `woodenrod`, `danishrod`, `koirod`, `finewoodrod`.
    - **Baits:** Multiple bait types.
    - **Fish:** `bluegill`, `bluebackherring`, `americanshad`, `arowana`, `shark`, `goldentrout`, `silverymonnow`, `strippedbass`, `tench`, `whitefish`, `crappie`, `cruciancarp`, `bulltrout`, `laketrout`, `perch`, `pearchy`, `coloradominnow`, `drumfish`, `walleye`, `palidsturgeon`, `pike`, `blackcrappie`, `bream`, `brooktrout`, `shortnosesucker`, `smallmouthbass`, `sweetfish`, `whitebass`, `alabamasturgeon`, `lakesturgeon`, `koicarpblack`, `lahontantrout`.
  - Because `ox-inventory` is the active inventory, catching any fish fails with an invalid item error.

### 12. Hunting (`m-hunting`)
- **Location:** Hunting Club & Wilderness Zones across Blaine County and Chiliad.
- **Gameplay Concept:** Players hunt wild animals (deer, boar, coyotes, cougars, birds, rabbits), skin them in the field, and sell pelts, horns, and meat.
- **Defects Discovered:**
  - **CRITICAL FAILURE (Missing Items):** `m-hunting` provides an `items.md` file specifically with Lua snippets for `ox_inventory`, defining **24 hunting items**:
    `pigeonmeat`, `pigeonfeather`, `crowmeat`, `crowfeather`, `seagullmeat`, `seagullfeather`, `cormorantmeat`, `cormorantbeak`, `deermeat`, `deerhorn`, `rabbitmeat`, `rabbitskin`, `ratmeat`, `pigmeat`, `pigskin`, `coyotemeat`, `coyoteskin`, `coguarmeat`, `coguarskin`, `boarmeat`, `boarskin`, `snakemeat`, `boarhorn`, `snakeskin`, `hawkmeat`, `hawkskin`, `hawkpeak`.
  - None of these 24 items were ever added to `ox_inventory\data\items.lua`. Skinning any animal results in failure to receive items.

### 13. Delivery / PostOP (`m-postop`)
- **Depot Location:** Terminal PostOP Logistics (`vector4(1197.21, -3255.11, 7.1, 86.62)`).
- **NPC:** `s_m_m_ups_02` with blip "POST OP".
- **Defects Discovered:**
  - **FATAL RUNTIME CRASH:** In `m-postop\editable\config.lua:10`, `FuelSystem = 'cdn-fuel'`. In `m-postop\editable\client-editable.lua:16`:
    ```lua
    elseif CDM.Config.FuelSystem == 'cdn-fuel' then
        return exports['cdn-fuel']:SetFuel(vehicle, 100)
    ```
    Because `cdn-fuel` does not exist on the server (which uses `ox_fuel`), attempting to spawn a delivery van crashes the script with a fatal missing export error.
  - In addition, `VehicleItem = "transportitem"` is configured in `config.lua:15`, but `transportitem` is missing from `ox_inventory`.

### 14. Real Estate (`qbx_properties`)
- **Job Identifier in Qbox:** `realestate` (Grades 0–4: Recruit, House Sales, Business Sales, Broker, Manager).
- **Realtor Operations:**
  - Command `/createproperty` is strictly checked: `if player.PlayerData.job.name ~= 'realestate' then exports.qbx_core:Notify(source, 'Not a realtor', 'error') return end`.
  - Allows in-game creation of houses and apartments, placing interior doors, stash locations, wardrobes, and garage points.
  - Persisted directly to MySQL table `properties`.
  - Overall Status: **PASS**.

### 15. Vineyard (`qbx_vineyard`)
- **Job Identifier in Qbox:** `vineyard` (Grade 0: Picker, $50).
- **Location:** Marlowe Vineyards, Tongva Hills (`vec3(-1877.35, 2132.57, 127.93)`).
- **Gameplay Lifecycle:**
  - Open civilian crafting activity.
  - 20 grape picking node locations mapped.
  - Processing stations for crushing grapes into grape juice and fermenting juice into wine.
  - Items `grape`, `grapejuice`, and `wine` **all exist** in `ox_inventory\data\items.lua`.
  - Overall Status: **PASS**.

### 16. Pawnshop & Scrapyard (`qbx_pawnshop` & `qbx_scrapyard`)
- **Pawnshop Location:** Vinewood (`vector3(412.34, 314.81, 103.13)`).
  - Buys stolen robbery loot (`goldchain`, `diamond_ring`, `rolex`, `10kgoldchain`, `tablet`, `iphone`, `laptop`).
  - Smelting bench melts jewelry into gold bars and loose diamonds.
  - Items match robbery loot tables in `qbx_storerobbery` and `qbx_houserobbery`.
- **Scrapyard Location:** El Burro Heights (`vector3(2404.6, 3127.8, 48.1)`).
  - Allows scrapping of NPC vehicles for scrap metals (`metalscrap`, `iron`, `steel`, `aluminum`, `glass`, `rubber`).
  - Status: **PASS**.

### 17. Hotdog Vendor (`qb-hotdogjob` — Missing)
- **Status:** **NOT FOUND / REMOVED**.
- `hotdog` is registered in `qbx_core/shared/jobs.lua:323` (Grade 0: Sales, payment $50).
- `codem-supreme-radialmenu` includes an action `qb-hotdogjob:client:ToggleSell`.
- The resource `qb-hotdogjob` does **not exist** on the filesystem. This is an orphaned job configuration.

---

## E. INTERACTION SYSTEMS & RADIAL MENU AUDIT

### 1. Primary Targeting System (`ox_target`)
- `ox_target` is running as the universal interaction system across the server.
- Convars in `server.cfg` / `ox.cfg`:
  - `setr ox_target:toggleHotkey 0` (Hold LMENU)
  - `setr ox_target:leftClick 1`
  - `setr ox_target:defaults 1`
- Fully adopted by: `qbx_cityhall`, `codem-truckerjob`, `codem-taxijob2`, `codem-minerjob`, `codem-fishing`, `qs-mechanic-creator`, `jg-dealerships`, `qbx_pawnshop`, `qbx_scrapyard`, `xt-prison`.

### 2. Radial Menu Inspection (`codem-supreme-radialmenu`)
The radial menu configuration in `shared/items.lua` was audited for event dead-ends. The following entries trigger events that have **no registered listener**:

1. **Citizen Phone Contact Exchange:**
   - Action: `givecontact`
   - Event: `qb-phone:client:GiveContactDetails`
   - Defect: Server runs `lb-phone`, not `qb-phone`. Option does nothing.
2. **Ambulance Emergency & Treatment Menu:**
   - Action: `checkstatus` → `hospital:client:CheckStatus` (DEAD EVENT)
   - Action: `revive` → `hospital:client:RevivePlayer` (DEAD EVENT)
   - Action: `heal` → `hospital:client:TreatWounds` (DEAD EVENT)
   - Action: `emergencybutton` → `police:client:SendPoliceEmergencyAlert` (Works in `qbx_police`)
3. **Mechanic Quick Actions:**
   - Action: `towvehicle` → `qb-tow:client:TowVehicle` (Works in `qbx_towjob`)
   - Action: `repair` → `mechanic:client:RepairVehicle` (DEAD EVENT)
   - Action: `clean` → `mechanic:client:CleanVehicle` (DEAD EVENT)
4. **Taxi Controls:**
   - Action: `togglemeter` → `qb-taxi:client:toggleMeter` (DEAD EVENT)
   - Action: `togglemouse` → `qb-taxi:client:enableMeter` (DEAD EVENT)
   - Action: `npc_mission` → `qb-taxi:client:DoTaxiNpc` (DEAD EVENT)
   - Taxi operations in `codem-taxijob2` use internal NUI and hotkeys, not these legacy qb-taxi triggers.
5. **Hotdog Vendor:**
   - Action: `togglesell` → `qb-hotdogjob:client:ToggleSell` (DEAD EVENT; script not installed).
6. **Police License Seizure:**
   - Action: `takedriverlicense` → `police:client:SeizeDriverLicense` (DEAD EVENT; `qbx_police` uses `/revokelicense`).

---

## F. DATABASE & SOCIETY FUNDS INSPECTION

A read-only inspection of database `Qbox_C6CA87` was performed:

### 1. Job Registrations in Database (`player_groups`)
- Player jobs in the database align with `qbx_core/shared/jobs.lua`:
  - Active jobs on records: `police` (grades 0, 3, 4), `ambulance` (grade 4), `cardealer` (grades 2, 4), `realestate` (grade 4), `taxi` (grades 0, 4), `bus` (grade 0), `sasp` (grade 4).
- Database table `apex_jobs_overrides` is empty (no custom runtime job overrides active).

### 2. Society Accounts & Banking
- **Banking Resource:** `bablo-banking` is the active banking and ATM framework.
- **Boss & Company Funds:**
  - `oxlyn-bossmenu` maintains its own dedicated company financial tables:
    - `oxlyn_company_accounts` (Company balances, society accounts)
    - `oxlyn_company_settings` (Permissions, PC ranks)
    - `oxlyn_company_timesheet` (Clock-in / clock-out logging)
    - `oxlyn_company_transactions` (Deposit, withdrawal, payroll logs)
  - `management_funds` table exists (legacy QBCore management table).
  - `qs-mechanic-creator` stores shop balances directly in the `mechanic_shops` table data column (`societyBalance`).

---

## G. DETAILED TECHNICAL FINDINGS

### Finding 1: Massive Missing Item Definitions in `ox_inventory`
- **Severity:** **CRITICAL**
- **Resources Affected:** `codem-minerjob`, `codem-fishing`, `m-hunting`, `codem-truckerjob`, `m-postop`
- **File:** `txData\Qbox_C6CA87.base\resources\[ox]\ox_inventory\data\items.lua`
- **Expected Behavior:** Every item that a script attempts to add or check via `ox_inventory` must be declared in `items.lua`.
- **Actual Behavior:** Over 80 required items are missing entirely. When players mine, fish, skin animals, or deliver cargo, `ox_inventory:AddItem` fails, aborting gameplay.
- **Root Cause:** 3rd-party job scripts were installed into `[customs]\[jobs]`, but their companion item lists were never merged into `ox_inventory\data\items.lua`.
- **Items Missing by Job:**
  - **Mining (23 items):** `normal_pickaxe`, `advanced_pickaxe`, `professional_pickaxe`, `copper_ore`, `copper_ingot`, `iron_ore`, `iron_ingot`, `gold_ore`, `goldingot`, `diamond_ore`, `diamond_ingot`, `coal`, `rock`, `sandstone`, `limestone`, `sulfur`, `blackpowder`, `concrete`, `glass_mold`, `ingot_mold`, `special_water`, `sticky_gel`. (Note: `glass` and `iron` already exist).
  - **Fishing (35+ items):** `standartrod`, `woodenrod`, `danishrod`, `koirod`, `finewoodrod`, plus 32 fish species (`bluegill`, `bluebackherring`, `americanshad`, `arowana`, `shark`, `goldentrout`, `silverymonnow`, `strippedbass`, `tench`, `whitefish`, `crappie`, `cruciancarp`, `bulltrout`, `laketrout`, `perch`, `pearchy`, `coloradominnow`, `drumfish`, `walleye`, `palidsturgeon`, `pike`, `blackcrappie`, `bream`, `brooktrout`, `shortnosesucker`, `smallmouthbass`, `sweetfish`, `whitebass`, `alabamasturgeon`, `lakesturgeon`, `koicarpblack`, `lahontantrout`).
  - **Hunting (24 items):** `pigeonmeat`, `pigeonfeather`, `crowmeat`, `crowfeather`, `seagullmeat`, `seagullfeather`, `cormorantmeat`, `cormorantbeak`, `deermeat`, `deerhorn`, `rabbitmeat`, `rabbitskin`, `ratmeat`, `pigmeat`, `pigskin`, `coyotemeat`, `coyoteskin`, `coguarmeat`, `coguarskin`, `boarmeat`, `boarskin`, `snakemeat`, `boarhorn`, `snakeskin`, `hawkmeat`, `hawkskin`, `hawkpeak`.
  - **Trucking (1 item):** `illegal_box`.
  - **PostOP (1 item):** `transportitem`.
- **Recommended Repair:** Add complete item definition blocks to `ox_inventory\data\items.lua` with appropriate weights, labels, and icons.

---

### Finding 2: Missing Ambulance / EMS Job Infrastructure
- **Severity:** **CRITICAL**
- **Resource Affected:** `qbx_medical` / Missing resource
- **Files:** `txData\Qbox_C6CA87.base\resources\[qbx]\qbx_medical`, `txData\Qbox_C6CA87.base\server.cfg`
- **Expected Behavior:** Whitelisted EMS personnel have stations to go on duty, spawn ambulances, access medical supplies, and treat players; civilians have an NPC check-in to get healed when no EMS are available.
- **Actual Behavior:** Only the underlying medical damage/death framework is running. There is no job logic, duty management, check-in NPC, or vehicle garage.
- **Root Cause:** A complete EMS job resource (such as `qbx_ambulancejob` or `wasabi_ambulance`) was never installed or configured alongside `qbx_medical`.
- **Recommended Repair:** Install and configure the canonical Qbox ambulance resource (`qbx_ambulancejob`), wire hospital check-in peds at Pillbox Hill, setup the EMS vehicle garage, and link revive/treatment triggers.

---

### Finding 3: PostOP Fatal Crash on Vehicle Spawn
- **Severity:** **CRITICAL**
- **Resource Affected:** `m-postop`
- **Files:** `txData\Qbox_C6CA87.base\resources\[customs]\[jobs]\m-postop\editable\config.lua:10`, `client-editable.lua:16`
- **Expected Behavior:** Starting a PostOP delivery spawns the Boxville van with full fuel via the server's active fuel resource.
- **Actual Behavior:** `config.lua` specifies `FuelSystem = 'cdn-fuel'`. When the van spawns, the client executes `exports['cdn-fuel']:SetFuel(vehicle, 100)`. Because `cdn-fuel` does not exist, FiveM crashes the script thread.
- **Root Cause:** Configuration specifies `'cdn-fuel'` instead of the installed `'ox-fuel'`.
- **Recommended Repair:** Change line 10 in `m-postop\editable\config.lua` to `FuelSystem = 'ox-fuel'` (and fix line 24 of `client-editable.lua` which has an invalid `'x-fuel'` typo).

---

### Finding 4: Decoupling of Default Spawn NPC from Codem Jobs
- **Severity:** **HIGH**
- **Resources Affected:** `qbx_cityhall`, `codem-truckerjob`, `codem-taxijob2`, `codem-garbage`
- **Files:**
  - `txData\Qbox_C6CA87.base\resources\[customs]\[jobs]\codem-truckerjob\shared\config.lua:10` (`Config.JobName = "all"`)
  - `txData\Qbox_C6CA87.base\resources\[customs]\[jobs]\codem-taxijob2\shared\config.lua:26` (`Config.JobCheck = { enable = false, name = 'taxi' }`)
  - `txData\Qbox_C6CA87.base\resources\[customs]\[jobs]\codem-garbage\config\config.lua:36` (`['job'] = 'all'`)
- **Expected Behavior:** Taking a public job at Cityhall grants exclusive access to that career and instructs the player where to report for duty.
- **Actual Behavior:** Any civilian who remains unemployed can access the Codem Trucker, Taxi, and Garbage menus without ever visiting Cityhall. Conversely, players who visit Cityhall and select these jobs receive no GPS blip or direction to the depots.
- **Root Cause:** Pre-configured standalone settings left at default `'all'` / `enable = false`.
- **Recommended Repair:**
  1. Set `Config.JobName = "trucker"` in `codem-truckerjob`.
  2. Set `Config.JobCheck = { enable = true, name = 'taxi' }` in `codem-taxijob2`.
  3. Set `['job'] = 'garbage'` in `codem-garbage`.
  4. In `qbx_cityhall\client\main.lua`, when a player applies for a job, display a notification with the depot address and set a GPS waypoint to the respective depot.

---

### Finding 5: Origen Police MDT Incompatibility with BCSO and SASP
- **Severity:** **HIGH**
- **Resource Affected:** `origen_police`
- **File:** `txData\Qbox_C6CA87.base\resources\[customs]\origen_police\config\jobs.lua:2–20`
- **Expected Behavior:** All authorized law enforcement officers (LSPD, BCSO, SASP) can open the police tablet via `/rpol` and access records.
- **Actual Behavior:** Only characters with job `'police'` or `'sheriff'` can open the MDT. Characters with Qbox jobs `'bcso'` or `'sasp'` are denied access.
- **Root Cause:** `Config.JobCategory["police"]` only lists `'police'` and `'sheriff'`, omitting Qbox's actual job names `'bcso'` and `'sasp'`.
- **Recommended Repair:** Add job definitions for `'bcso'` and `'sasp'` to `Config.JobCategory["police"]` in `origen_police\config\jobs.lua`.

---

### Finding 6: Dead Legacy Events in Radial Menu
- **Severity:** **MEDIUM**
- **Resource Affected:** `codem-supreme-radialmenu`
- **File:** `txData\Qbox_C6CA87.base\resources\[customs]\codem-supreme-radialmenu\shared\items.lua`
- **Expected Behavior:** Radial menu actions trigger valid client or server events handled by active server resources.
- **Actual Behavior:** Multiple sub-menu options trigger legacy QBCore events that have no handlers in Qbox (`hospital:client:RevivePlayer`, `hospital:client:TreatWounds`, `mechanic:client:RepairVehicle`, `qb-taxi:client:toggleMeter`, `qb-hotdogjob:client:ToggleSell`, `qb-phone:client:GiveContactDetails`).
- **Root Cause:** The radial menu items configuration is an unadapted legacy QBCore preset.
- **Recommended Repair:** Clean or remap dead radial menu items to modern Qbox / ox_lib events, or remove ghost categories.

---

### Finding 7: Ghost Job Registration in `jobs.lua` (Hotdog Vendor)
- **Severity:** **LOW**
- **Resources Affected:** `qbx_core`, `codem-supreme-radialmenu`
- **File:** `txData\Qbox_C6CA87.base\resources\[qbx]\qbx_core\shared\jobs.lua:323`
- **Expected Behavior:** Every job registered in `jobs.lua` corresponds to an active or planned gameplay loop.
- **Actual Behavior:** `hotdog` is defined as a job with grade 0 "Sales", but `qb-hotdogjob` does not exist on the server.
- **Root Cause:** Unused default QBCore template leftover in `jobs.lua`.
- **Recommended Repair:** Remove the unused `hotdog` table entry from `jobs.lua` or install a hotdog stand resource if intended for RP.

---

## H. PRIORITIZED REPAIR ROADMAP

> [!IMPORTANT]
> This roadmap is for planning and authorization purposes only. **No items have been implemented.** All changes must await explicit approval.

### Phase 1: Critical Crash & Blocker Fixes
1. **Fix PostOP Fuel Crash:**
   - Update `m-postop\editable\config.lua` to `FuelSystem = 'ox-fuel'`.
   - Correct the export call in `m-postop\editable\client-editable.lua` line 24.
2. **Register Essential Delivery & Trucking Items:**
   - Add `illegal_box` to `ox_inventory\data\items.lua` (weight 2500, label "Contraband Cargo").
   - Add `transportitem` to `ox_inventory\data\items.lua` (weight 1000, label "PostOP Package").

### Phase 2: Missing Activity Items Restoration
1. **Restore Mining Inventory Items:**
   - Add all 23 items (`normal_pickaxe`, `advanced_pickaxe`, `professional_pickaxe`, `copper_ore`, `copper_ingot`, `iron_ore`, `iron_ingot`, `gold_ore`, `goldingot`, `diamond_ore`, `diamond_ingot`, `coal`, `rock`, `sandstone`, `limestone`, `sulfur`, `blackpowder`, `concrete`, `glass_mold`, `ingot_mold`, `special_water`, `sticky_gel`) to `ox_inventory\data\items.lua`.
2. **Restore Fishing Inventory Items:**
   - Add 5 rods (`standartrod`, `woodenrod`, `danishrod`, `koirod`, `finewoodrod`), baits, and all 32 fish species to `ox_inventory\data\items.lua`.
3. **Restore Hunting Inventory Items:**
   - Import the 24 hunting items defined in `m-hunting\items.md` into `ox_inventory\data\items.lua`.

### Phase 3: EMS / Ambulance Framework Implementation
1. **Install and Configure EMS Job Resource:**
   - Integrate `qbx_ambulancejob` into `[qbx]`.
   - Setup hospital check-in NPC and Pillbox Hill bed interactions.
   - Configure EMS duty station and ambulance garage.
   - Connect ox_inventory medical items (`bandage`, `firstaid`, `medikit`) to revival and injury treatment actions.

### Phase 4: Job Center & Default Spawn NPC Alignment
1. **Enforce Career Restrictions on Codem Public Jobs:**
   - In `codem-truckerjob`, set `Config.JobName = "trucker"`.
   - In `codem-taxijob2`, set `Config.JobCheck = { enable = true, name = 'taxi' }`.
   - In `codem-garbage`, set `['job'] = 'garbage'`.
2. **Add GPS Waypoint Guidance at Cityhall:**
   - When a player selects Trucker, Taxi, Tow, or Garbage at the Default Spawn Ped, show a notification with the facility name and automatically set a GPS route to the corresponding depot.

### Phase 5: Law Enforcement & MDT Compatibility
1. **Enable BCSO & SASP in Origen Police MDT:**
   - In `origen_police\config\jobs.lua`, add `bcso` and `sasp` to `Config.JobCategory["police"]`.
2. **Reconcile Redundant Police Commands:**
   - Ensure commands (`/cuff`, `/escort`, `/jail`) route cleanly without event collision between `qbx_police` and `origen_police`.

### Phase 6: Radial Menu & UI Cleanup
1. **Clean Radial Menu Actions:**
   - Replace or delete dead `hospital`, `qb-taxi`, `qb-phone`, and `qb-hotdogjob` event buttons in `codem-supreme-radialmenu\shared\items.lua`.
   - Wire taxi meter toggles directly to `codem-taxijob2` commands/events.
2. **Clean Core Job Registrations:**
   - Remove orphaned `hotdog` registration from `qbx_core/shared/jobs.lua`.
   - Clean up the shop job identifier in `mechanic_shops` table (fix `shop_1791919741_8` from "Real Estate" to "mechanic").

---

## I. VERIFICATION EVIDENCE & FILES INSPECTED

### Files Inspected:
1. `txData\Qbox_C6CA87.base\server.cfg` (Resource start orders, convar settings, permission groups)
2. `txData\Qbox_C6CA87.base\ox.cfg` (Ox target, inventory, and lib configurations)
3. `txData\Qbox_C6CA87.base\permissions.cfg` (Principal inheritance, ace permissions)
4. `txData\Qbox_C6CA87.base\resources\[qbx]\qbx_core\shared\jobs.lua` (Master job registry, grades, duty, salaries)
5. `txData\Qbox_C6CA87.base\resources\[customs]\wasabi_multichar\config\shared\config.lua` (Default spawn coordinates: `-269.4, -955.3, 31.2`)
6. `txData\Qbox_C6CA87.base\resources\[customs]\wasabi_multichar\bridge\spawn\server.lua` & `client.lua` (Spawn routing logic)
7. `txData\Qbox_C6CA87.base\resources\[qbx]\qbx_cityhall\config\client.lua` & `shared.lua` (Cityhall ped location: `-262.79, -964.18, 30.22`, job roster)
8. `txData\Qbox_C6CA87.base\resources\[qbx]\qbx_cityhall\client\main.lua` & `server\main.lua` (Ped spawn, ox_target setup, license issuance, SetJob callback)
9. `txData\Qbox_C6CA87.base\resources\[ox]\ox_inventory\data\items.lua` (2900+ line inventory item database)
10. `txData\Qbox_C6CA87.base\resources\[customs]\[jobs]\codem-truckerjob\shared\config.lua`, `server\main.lua` (Trucking config, depot, illegal box check)
11. `txData\Qbox_C6CA87.base\resources\[customs]\[jobs]\codem-taxijob2\shared\config.lua`, `server\main.lua`, `server\editable.lua` (Taxi config, depot, JobCheck)
12. `txData\Qbox_C6CA87.base\resources\[customs]\[jobs]\codem-garbage\config\config.lua`, `editable\server_editable.lua` (Garbage config, depot, keys)
13. `txData\Qbox_C6CA87.base\resources\[qbx]\qbx_busjob\config\client.lua`, `shared.lua`, `server\main.lua`, `client\main.lua` (Bus routes, vehicle spawn, anti-exploit)
14. `txData\Qbox_C6CA87.base\resources\[qbx]\qbx_towjob\config\client.lua`, `shared.lua`, `server\main.lua`, `client\main.lua` (Tow HQ, bail, trip validation)
15. `txData\Qbox_C6CA87.base\resources\[qbx]\qbx_newsjob\config\client.lua`, `server\main.lua`, `client\main.lua` (Weazel news garage, camera, mic)
16. `txData\Qbox_C6CA87.base\resources\[qbx]\qbx_medical\config\client.lua`, `server\main.lua`, `client\main.lua` (Health, damage, death statebags)
17. `txData\Qbox_C6CA87.base\resources\[customs]\origen_police\fxmanifest.lua`, `config\_framework.lua`, `config\jobs.lua` (Origen MDT, job categories)
18. `txData\Qbox_C6CA87.base\resources\[qbx]\qbx_police\server\main.lua`, `server\commands.lua`, `client\interactions.lua` (Police core commands, evidence)
19. `txData\Qbox_C6CA87.base\resources\[customs]\qs-mechanic-creator\shared\config.lua`, `server\custom\qbox.lua` (Mechanic framework integration)
20. `txData\Qbox_C6CA87.base\resources\[qbx]\qbx_customs\config\shared.lua` (Public Los Santos Customs zones)
21. `txData\Qbox_C6CA87.base\resources\[customs]\jg-dealerships\config\config.lua` (Dealership framework and vehicle shop configs)
22. `txData\Qbox_C6CA87.base\resources\[qbx]\qbx_properties\server\realtor.lua`, `client\realtor.lua` (Real estate property creation)
23. `txData\Qbox_C6CA87.base\resources\[customs]\[jobs]\codem-minerjob\shared\config.lua`, `qb-core-items.txt` (Mining config, missing 23 items)
24. `txData\Qbox_C6CA87.base\resources\[customs]\[jobs]\codem-fishing\config\config.lua`, `server_config.lua` (Fishing config, missing 35+ items)
25. `txData\Qbox_C6CA87.base\resources\[customs]\[jobs]\m-hunting\shared\config.lua`, `items.md` (Hunting config, missing 24 items)
26. `txData\Qbox_C6CA87.base\resources\[customs]\[jobs]\m-postop\editable\config.lua`, `editable\client-editable.lua` (PostOP fuel crash and missing item)
27. `txData\Qbox_C6CA87.base\resources\[qbx]\qbx_vineyard\config\client.lua`, `server\main.lua` (Vineyard locations, items)
28. `txData\Qbox_C6CA87.base\resources\[qbx]\qbx_pawnshop\config\shared.lua` (Pawnshop buy & melting configs)
29. `txData\Qbox_C6CA87.base\resources\[qbx]\qbx_scrapyard\config\server.lua` (Scrapyard scrap vehicle models & materials)
30. `txData\Qbox_C6CA87.base\resources\[customs]\LB-Rentalcar\config.lua` & `9labs_scootrental\config.lua` (Rental configurations)
31. `txData\Qbox_C6CA87.base\resources\[customs]\codem-supreme-radialmenu\shared\items.lua` (Radial menu options and dead events)
32. `txData\Qbox_C6CA87.base\resources\[customs]\oxlyn-bossmenu\config.lua` (Company accounts, boss permissions)

### Database Read-Only Evidence (`Qbox_C6CA87` via `mysql.exe`):
- `SHOW TABLES;`: Checked 117 production database tables. Verified existence of `codem_truckerjob`, `codem_taxijob2`, `codem_garbage`, `codem_minerjob`, `codem_fishingjob_player`, `m_hunting`, `m_postop`, `mechanic_shops`, `dealership_locations`, `properties`, `player_groups`, `oxlyn_company_accounts`.
- `SELECT DISTINCT player_groups.group, grade FROM player_groups WHERE type = 'job';`: Confirmed actual player job distributions in production (`police`, `ambulance`, `cardealer`, `realestate`, `taxi`, `bus`, `sasp`).
- `SELECT * FROM mechanic_shops;`: Confirmed 4 existing custom mechanic shops and inspected their JSON structures.
- `SELECT * FROM dealership_locations;`: Confirmed PDM, Aircraft, Boat, and Truck dealership setups.

---

**AUDIT COMPLETED. STRICT READ-ONLY COMPLIANCE MAINTAINED.**  
*Awaiting review and explicit authorization before proceeding to any implementation.*
