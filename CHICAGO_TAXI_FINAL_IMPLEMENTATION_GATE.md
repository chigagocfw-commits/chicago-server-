# CHICAGO ROLEPLAY — TAXI FINAL IMPLEMENTATION GATE & VERIFICATION AUDIT

**Document Identifier:** `CHICAGO-GATE-TAXI-01`  
**Target Resource:** `[customs]/[jobs]/codem-taxijob2`  
**Framework Environment:** Qbox (`qbx_core`, `qbx_vehiclekeys`, `ox_inventory`, `oxmysql`)  
**Audit Mode:** STRICT READ-ONLY. No code modifications, no database writes, no resource restarts.

---

## 1. DUPLICATE PAYMENT HANDLERS FORENSIC PROOF

A line-by-line inspection of [`server/main.lua`](file:///C:/Users/Administrator/Desktop/CHICAGO%20SERVER/txData/Qbox_C6CA87.base/resources/[customs]/[jobs]/codem-taxijob2/server/main.lua) and [`server/editable.lua`](file:///C:/Users/Administrator/Desktop/CHICAGO%20SERVER/txData/Qbox_C6CA87.base/resources/[customs]/[jobs]/codem-taxijob2/server/editable.lua) was performed to determine the exact runtime execution path of `codem-taxijob:Pay`.

### A. Execution Order & Table Sharing
1. **Shared Memory Space:**  
   The global table `fares = {}` is declared at line 156 of `server/main.lua`. In FiveM server runtimes, all files in `server_scripts` share the global environment (`_G`). Both `server/editable.lua` and `server/main.lua` read and mutate the exact same `fares` table in memory.
2. **File Loading Sequence:**  
   In [`fxmanifest.lua:20`](file:///C:/Users/Administrator/Desktop/CHICAGO%20SERVER/txData/Qbox_C6CA87.base/resources/[customs]/[jobs]/codem-taxijob2/fxmanifest.lua#L20), the declaration is `'server/*.lua'`. FiveM loads server files in alphabetical order:
   - File 1: `server/botToken.lua`
   - File 2: `server/editable.lua` (Registers Handler 1)
   - File 3: `server/main.lua` (Registers Handler 2)
3. **Execution Trace of Single Trigger:**  
   When a client triggers `TriggerServerEvent('codem-taxijob:Pay', amount, xp, key, header)`:
   - **Step 1 (Handler 1 — `editable.lua`):**  
     Runs synchronously on the main thread.
     - Checks `clientkey ~= key`.
     - Checks `fares[src] ~= amount`.
     - **Clears state:** `fares[src] = nil` (Line 12).
     - Calls `AddMoney(src, amount)`.
     - Handler 1 completes synchronously.
   - **Step 2 (Handler 2 — `main.lua`):**  
     Runs immediately next on the main thread.
     - Checks `securityKey ~= key`.
     - Checks `if fares[playerId] ~= amount` (Line 618).
     - **Result:** Because Handler 1 already set `fares[src] = nil` in the shared table, `fares[playerId]` is `nil`. The check `nil ~= amount` evaluates to **true**!
     - Prints to server console: `'Player tried to execute pay trigger with wrong amount'`.
     - Returns immediately without calling `AddMoney`.

### B. Confirmed Conclusion on Double Payment:
- **Actual Double Payment Does NOT Occur in the Unmodified Resource.** Handler 1 consumes and clears `fares[src]` before Handler 2 executes, causing Handler 2 to reject the payout and emit a false "cheat/wrong amount" console warning on every single legitimate ride completion.
- **Why Handler Duplication is Unacceptable:**  
  If any asynchronous callback (`await`) or delayed database verification were introduced into Handler 1 without clearing `fares[src]` first, both handlers would execute `AddMoney`, causing genuine double payments.
- **Canonical Handler Determination:**  
  `server/main.lua` contains the full implementation including `ExecuteSql(updateQuery)`, stats synchronization, and error handling. `server/editable.lua` contains ONLY lines 1–26 (the duplicate handler).  
  **Decision:** Remove the duplicate event registration from `server/editable.lua`, retaining `server/main.lua` as the sole, authoritative payment handler.

---

## 2. SERVER-AUTHORITATIVE MISSION DATA

To eliminate arbitrary client-crafted payouts, the client must never be trusted with mission parameters.

### Current Exploitability:
In the current code ([`client/main.lua:601-602`](file:///C:/Users/Administrator/Desktop/CHICAGO%20SERVER/txData/Qbox_C6CA87.base/resources/[customs]/[jobs]/codem-taxijob2/client/main.lua#L601-L602)):
- The client generates `payment = math.random(minPayment, maxPayment)`.
- The client selects `finishLocation` from `missionConfig.finishLocations`.
- The client transmits both to the server via `SetFare`.

### Authoritative Server-Side Architecture:
Under the final architecture, the client sends only a request to start work. The server dispenses all authoritative parameters:

| Mission Parameter | Authoritative Source | Verification Mechanism |
| :--- | :--- | :--- |
| **Pickup Coordinates** | `Config.Missions[areaIndex].npcSpawnLocations` | Server randomly selects coordinate index from trusted config. Client receives waypoint. |
| **Destination Coordinates** | `Config.Missions[areaIndex].finishLocations` | Server randomly selects destination index from trusted config. Client receives destination upon pickup. |
| **Fare Amount** | Server calculation based on `minPayment` and `maxPayment` | Generated on server upon dispatch; client parameter is completely ignored. |
| **XP Reward** | Server calculation based on `minXP` and `maxXP` | Generated on server upon completion; client parameter is completely ignored. |
| **VIP Missions** | `Config.VipMissions[missionId]` | Server verifies driver level $\ge$ `reqLevel` and reads fixed `payment`, `finishLocation`, and `minxp`/`maxxp`. |

---

## 3. RIDE COMPLETION VALIDATION & NPC LIMITATIONS

### A. What the Server CAN Prove Authoritatively:
1. **Driver Job Integrity:** Server verifies `player.PlayerData.job.name == 'taxi'` at dispatch, pickup, completion, and payment.
2. **Vehicle Legitimacy:** Server verifies the player is inside an authorized taxi model from `Config.Vehicles` (`taxi`, `stretch`) via `GetEntityModel(GetVehiclePedIsIn(ped, false))`.
3. **Vehicle Identity Binding:** Server binds `vehicleNetId = NetworkGetNetworkIdFromEntity(vehicle)` to the session upon dispatch and ensures the driver remains in the same vehicle at pickup and arrival.
4. **Spatial Transit Proof:**
   - At pickup: `#(driverCoords - session.pickupCoords) <= 25.0m`.
   - At destination: `#(driverCoords - session.destCoords) <= 25.0m`.
5. **Temporal Transit Proof (Anti-Teleport):**
   - Server calculates minimum straight-line distance $D = \#(\text{pickupCoords} - \text{destCoords})$.
   - Imposes a minimum transit threshold: $T_{\text{min}} = \max\left(15, \lfloor D / 35.0 \rfloor\right)$ seconds (based on a high-speed vehicle cap of 125 km/h). Trips completed faster than $T_{\text{min}}$ are flagged and rejected.
6. **Strict Stage Ordering:** The sequence `ASSIGNED` $\rightarrow$ `PICKED_UP` $\rightarrow$ `ARRIVED` $\rightarrow$ `PAID` cannot be bypassed or inverted.

### B. What Remains Client-Trusted (NPC Virtualization Limitations):
- **Client-Side Ped Entity:** In `codem-taxijob2`, passenger NPCs are created locally via native `CreatePed()`. They are not networked server entities.
- **Limitation:** The server cannot verify whether the visual 3D ped entered seat 1 or is physically sitting inside the vehicle. The server relies on the client's trigger to signal `ConfirmPickup`.
- **Honest Security Assessment:** Server proximity checks and minimum transit durations prove **driver presence and vehicular transit between authoritative checkpoints**, but do **not** constitute mathematical proof of passenger physical presence. This is an inherent architectural constraint of client-side NPC job scripts in FiveM.

---

## 4. PAYMENT AND TRANSACTIONAL RECOVERY

### A. Qbox `AddMoney` Return Behavior:
Inspection of [`qbx_core/server/player.lua:1321`](file:///C:/Users/Administrator/Desktop/CHICAGO%20SERVER/txData/Qbox_C6CA87.base/resources/[qbx]/qbx_core/server/player.lua#L1321) proves that Qbox `AddMoney` returns a boolean synchronously:
- Returns `true` if cash was credited.
- Returns `false` if the player object is invalid, amount is negative/invalid, or an event hook canceled the transaction.

### B. Transactional State Engine & Recovery Matrix:

```lua
-- Session States:
-- 'ASSIGNED' -> 'PICKED_UP' -> 'ARRIVED' -> 'PAYING' -> 'PAID'
```

| Scenario | State Transition | System Behavior | Driver Impact |
| :--- | :--- | :--- | :--- |
| **Normal Execution** | `ARRIVED` $\rightarrow$ `PAYING` $\rightarrow$ `PAID` | Money credited, stats updated, session destroyed. | Receives cash and XP immediately. |
| **Qbox Wallet Rejection** (`AddMoney` returns `false`) | `PAYING` $\rightarrow$ `ARRIVED` | Zero cash credited. Session reverted to `ARRIVED`. Logged in console. | Driver can retry or contact staff; earnings are NOT lost. |
| **Database Failure After Payment** (`AddMoney` returned `true`, but SQL query crashes) | `PAYING` $\rightarrow$ `PAID` $\rightarrow$ `nil` | **CRITICAL RULE:** Session is NEVER reverted to `ARRIVED` because cash is already in the player's wallet. Stat error logged. | Driver keeps cash; no duplicate payment exploit possible. |
| **Disconnect During `PAYING`** | Player drops mid-execution | `AddMoney` completes or aborts before drop. Session purged via `playerDropped`. | No stuck locks or ghost sessions in server memory. |
| **Concurrent Double-Spend Attack** | Thread 1: `PAYING`  
Thread 2: Rejected | Atomic lock rejects Thread 2 because state is no longer `ARRIVED`. | Single payout guaranteed. |

---

## 5. FILE SCOPE RECONCILIATION

### Reconciling the 2-File vs 4-File Contradiction:
In the previous report draft, the text initially referenced "two files" while the table listed four. This contradiction is formally resolved:

**The exact, definitive scope of modification is FOUR (4) files:**

1. **`[customs]/[jobs]/codem-taxijob2/server/main.lua` (Primary Server Logic):**  
   *Why required:* Implements the authoritative ride session state table (`activeTaxiSessions`), verification callbacks (`StartRide`, `ConfirmPickup`, `CompleteRide`, `ClaimPayout`), and checks `AddMoney` return booleans.
2. **`[customs]/[jobs]/codem-taxijob2/server/editable.lua` (Duplicate Cleanup):**  
   *Why required:* Must have the duplicate `RegisterServerEvent('codem-taxijob:Pay')` removed so that only `server/main.lua` handles payments.
3. **`[customs]/[jobs]/codem-taxijob2/client/main.lua` (Client Lifecycle & Cleanup):**  
   *Why required:* Removes the leftover `/triggerpay` debug command (Line 722) and connects client pickup/arrival prompts to the new server callbacks.
4. **`[customs]/[jobs]/codem-taxijob2/shared/config.lua` (Security Configuration):**  
   *Why required:* Enforces `Config.JobCheck = { enable = true, name = 'taxi' }` so that client UI and interactions align with server authorization.

---

## 6. VERIFICATION & TEST MATRIX

| Test ID | Test Vector | Injection / Action | Expected Result | Pass Criteria |
| :--- | :--- | :--- | :--- | :--- |
| **TC-01** | Arbitrary Fare Injection | Client invokes `TriggerServerEvent('codem-taxijob:Pay', 999999)` | Server has no session for driver; rejects payload immediately. | Zero cash credited. |
| **TC-02** | Instant Ride Teleport | Client triggers `StartRide` then `CompleteRide` within 1 second. | Rejection by minimum transit duration check ($T_{\text{min}}$). | Blocked, warning logged. |
| **TC-03** | Out-of-Bounds Destination | Client triggers `CompleteRide` at Legion Square while dest is Paleto. | Rejection by coordinate distance check ($> 25\text{m}$). | Blocked. |
| **TC-04** | Replay Payout Packet | Client captures and replays valid `ClaimPayout` packet. | First call marks session `PAID` and clears it. Second call finds no session. | Exactly-once payment. |
| **TC-05** | Unauthorized Vehicle | Player starts taxi job while driving personal supercar. | Server checks vehicle hash against `Config.Vehicles`; rejects dispatch. | Ride not started. |
| **TC-06** | Job Loss Mid-Ride | Driver gets fired or changes job to `unemployed` mid-route. | Checked at `CompleteRide` and `ClaimPayout`; payment denied. | Zero cash credited. |
| **TC-07** | Duplicate Handler Elimination | Trigger payment and monitor server console. | Exactly one handler executes; zero "wrong amount" console spam. | Clean console output. |
| **TC-08** | Transaction Abort Recovery | Simulate `AddMoney` returning `false`. | Session reverts to `ARRIVED`; driver progress intact. | Zero duplicate risk. |

---

## 7. BACKUP & ROLLBACK REQUIREMENTS

Before applying any changes to production files:

1. **Backup Directory:**  
   `C:\backups\CHICAGO_JOBS_SECURITY\codem-taxijob2_prepatch_\`
2. **Files to Snapshot:**
   - `[customs]/[jobs]/codem-taxijob2/server/main.lua`
   - `[customs]/[jobs]/codem-taxijob2/server/editable.lua`
   - `[customs]/[jobs]/codem-taxijob2/client/main.lua`
   - `[customs]/[jobs]/codem-taxijob2/shared/config.lua`
3. **Rollback Verification:**  
   Documented hash and byte verification to allow instant one-command restoration if any edge case emerges.

---

## 8. STATUS & OWNER AUTHORIZATION GATE

- **Current State:** STRICT READ-ONLY AUDIT COMPLETE.
- **Production Files Modified:** ZERO (0).
- **Awaiting:** Explicit owner review and authorization of `CHICAGO_TAXI_FINAL_IMPLEMENTATION_GATE.md` before taking any further action.

