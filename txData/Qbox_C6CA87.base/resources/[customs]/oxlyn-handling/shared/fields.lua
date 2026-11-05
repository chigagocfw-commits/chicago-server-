

-- ════════════════════════════════════════════════════════════════════════
--  OXLYN-HANDLING  •  shared/fields.lua
--  The complete handling schema the editor exposes (46 CHandlingData fields).
--
--  Per field:
--    name  exact native field name (case-sensitive — yes, fCamberStiffnesss
--          really has three s's in the game data)
--    type  'float' | 'int' | 'vector'
--    cat   category id (locale key = cat_<id>)
--    adv   true → only visible when the ADVANCED toggle is on
--    unit  display suffix shown in the UI ('kg', '°', 'L', '%', 'm')
--    min/max/step/dec   slider range + input precision (handling.meta units)
--
--  UNITS — verified against the CFX source (HandlingLoader.cpp): BOTH
--  Get/SetVehicleHandlingFloat work in handling.meta units. GET converts the
--  raw memory value back to meta on read (fSteeringLock rad→deg, MaxFlatVel
--  ×3.6, biases ÷2, damping ×10, drag ×10000…) and SET applies the inverse on
--  write — they are symmetric in META space. Therefore this schema needs NO
--  conversion factors: what you read is meta, what you write is meta, and all
--  ranges below are plain handling.meta numbers. (An earlier `conv` column
--  assumed GET returned raw values — that made the server-side range clamp
--  crush fSteeringLock stock 35° down to ~2.4°, which was the "car stops
--  steering after save" bug.)
--
--  All reads/writes still go through client/handlingio.lua, which verifies
--  every write by reading it back (auto-corrects scale quirks, blacklists
--  fields that don't round-trip). Only CHandlingData is exposed — for unknown
--  classes/fields the natives return false, and sub-handling data is not
--  reliably editable.
--
--  Locale keys per field:  f_<name> = label   •   d_<name> = description
-- ════════════════════════════════════════════════════════════════════════

HandlingCategories = { 'transmission', 'physics', 'brakes', 'traction', 'suspension', 'damage', 'misc' }

HandlingFields = {
    -- ── Transmission ────────────────────────────────────────────────────
    { name = 'fDriveBiasFront',              type = 'float', cat = 'transmission', min = 0.0,   max = 1.0,   step = 0.01,  dec = 2 },
    { name = 'nInitialDriveGears',           type = 'int',   cat = 'transmission', min = 1,     max = 7,     step = 1,     dec = 0 },  -- engine clamps to 7 (CFX source)
    { name = 'fInitialDriveForce',           type = 'float', cat = 'transmission', min = 0.0,   max = 3.0,   step = 0.005, dec = 3 },
    { name = 'fDriveInertia',                type = 'float', cat = 'transmission', min = 0.01,  max = 3.0,   step = 0.01,  dec = 2 },
    { name = 'fClutchChangeRateScaleUpShift',   type = 'float', cat = 'transmission', min = 0.1, max = 20.0, step = 0.1,  dec = 1 },
    { name = 'fClutchChangeRateScaleDownShift', type = 'float', cat = 'transmission', min = 0.1, max = 20.0, step = 0.1,  dec = 1 },
    { name = 'fInitialDriveMaxFlatVel',      type = 'float', cat = 'transmission', min = 10.0,  max = 400.0, step = 0.5,   dec = 1, unit = 'km/h' },

    -- ── Physics (mass & aero) ───────────────────────────────────────────
    { name = 'fMass',                        type = 'float', cat = 'physics', min = 100.0, max = 20000.0, step = 10.0,  dec = 1, unit = 'kg' },
    { name = 'fInitialDragCoeff',            type = 'float', cat = 'physics', min = 0.0,   max = 50.0,    step = 0.1,   dec = 2 },
    { name = 'fDownforceModifier',           type = 'float', cat = 'physics', min = 0.0,   max = 300.0,   step = 0.5,   dec = 2 },
    { name = 'fPercentSubmerged',            type = 'float', cat = 'physics', min = 10.0,  max = 120.0,   step = 1.0,   dec = 0, unit = '%', adv = true },
    { name = 'vecCentreOfMassOffset',        type = 'vector', cat = 'physics', min = -5.0, max = 5.0,     step = 0.01,  dec = 2, unit = 'm' },
    { name = 'vecInertiaMultiplier',         type = 'vector', cat = 'physics', min = 0.1,  max = 10.0,    step = 0.05,  dec = 2, adv = true },

    -- ── Brakes ──────────────────────────────────────────────────────────
    { name = 'fBrakeForce',                  type = 'float', cat = 'brakes', min = 0.0, max = 5.0, step = 0.01, dec = 2 },
    { name = 'fBrakeBiasFront',              type = 'float', cat = 'brakes', min = 0.0, max = 1.0, step = 0.01, dec = 2 },
    { name = 'fHandBrakeForce',              type = 'float', cat = 'brakes', min = 0.0, max = 5.0, step = 0.01, dec = 2 },

    -- ── Steering & Traction ─────────────────────────────────────────────
    { name = 'fSteeringLock',                type = 'float', cat = 'traction', min = 10.0, max = 90.0, step = 0.5,  dec = 1, unit = '°' },
    { name = 'fTractionCurveMax',            type = 'float', cat = 'traction', min = 0.0,  max = 5.0,  step = 0.01, dec = 2 },
    { name = 'fTractionCurveMin',            type = 'float', cat = 'traction', min = 0.0,  max = 5.0,  step = 0.01, dec = 2 },
    { name = 'fTractionCurveLateral',        type = 'float', cat = 'traction', min = 5.0,  max = 60.0, step = 0.5,  dec = 1, unit = '°' },
    { name = 'fTractionSpringDeltaMax',      type = 'float', cat = 'traction', min = 0.0,  max = 1.0,  step = 0.005, dec = 3, adv = true },
    { name = 'fLowSpeedTractionLossMult',    type = 'float', cat = 'traction', min = 0.0,  max = 5.0,  step = 0.05, dec = 2 },
    { name = 'fCamberStiffnesss',            type = 'float', cat = 'traction', min = -1.0, max = 2.0,  step = 0.01, dec = 2 },
    { name = 'fTractionBiasFront',           type = 'float', cat = 'traction', min = 0.0,  max = 1.0,  step = 0.01, dec = 2 },
    { name = 'fTractionLossMult',            type = 'float', cat = 'traction', min = 0.0,  max = 5.0,  step = 0.05, dec = 2 },

    -- ── Suspension ──────────────────────────────────────────────────────
    { name = 'fSuspensionForce',             type = 'float', cat = 'suspension', min = 0.0,  max = 10.0, step = 0.05,  dec = 2 },
    { name = 'fSuspensionCompDamp',          type = 'float', cat = 'suspension', min = 0.0,  max = 10.0, step = 0.05,  dec = 2 },
    { name = 'fSuspensionReboundDamp',       type = 'float', cat = 'suspension', min = 0.0,  max = 10.0, step = 0.05,  dec = 2 },
    { name = 'fSuspensionUpperLimit',        type = 'float', cat = 'suspension', min = -0.5, max = 1.0,  step = 0.005, dec = 3, unit = 'm', adv = true },
    { name = 'fSuspensionLowerLimit',        type = 'float', cat = 'suspension', min = -1.0, max = 0.5,  step = 0.005, dec = 3, unit = 'm', adv = true },
    { name = 'fSuspensionRaise',             type = 'float', cat = 'suspension', min = -0.5, max = 0.5,  step = 0.005, dec = 3, unit = 'm' },
    { name = 'fSuspensionBiasFront',         type = 'float', cat = 'suspension', min = 0.0,  max = 1.0,  step = 0.01,  dec = 2 },
    { name = 'fAntiRollBarForce',            type = 'float', cat = 'suspension', min = 0.0,  max = 5.0,  step = 0.05,  dec = 2 },
    { name = 'fAntiRollBarBiasFront',        type = 'float', cat = 'suspension', min = 0.0,  max = 1.0,  step = 0.01,  dec = 2 },
    { name = 'fRollCentreHeightFront',       type = 'float', cat = 'suspension', min = -1.0, max = 1.0,  step = 0.01,  dec = 2, unit = 'm', adv = true },
    { name = 'fRollCentreHeightRear',        type = 'float', cat = 'suspension', min = -1.0, max = 1.0,  step = 0.01,  dec = 2, unit = 'm', adv = true },

    -- ── Damage ──────────────────────────────────────────────────────────
    { name = 'fCollisionDamageMult',         type = 'float', cat = 'damage', min = 0.0, max = 5.0,   step = 0.05, dec = 2 },
    { name = 'fWeaponDamageMult',            type = 'float', cat = 'damage', min = 0.0, max = 5.0,   step = 0.05, dec = 2 },
    { name = 'fDeformationDamageMult',       type = 'float', cat = 'damage', min = 0.0, max = 5.0,   step = 0.05, dec = 2 },
    { name = 'fEngineDamageMult',            type = 'float', cat = 'damage', min = 0.0, max = 5.0,   step = 0.05, dec = 2 },
    { name = 'fPetrolTankVolume',            type = 'float', cat = 'damage', min = 0.0, max = 200.0, step = 1.0,  dec = 0, unit = 'L' },
    { name = 'fOilVolume',                   type = 'float', cat = 'damage', min = 0.0, max = 20.0,  step = 0.5,  dec = 1, unit = 'L', adv = true },

    -- ── Misc ────────────────────────────────────────────────────────────
    { name = 'fSeatOffsetDistX',             type = 'float', cat = 'misc', min = -1.0, max = 1.0,      step = 0.01, dec = 2, unit = 'm', adv = true },
    { name = 'fSeatOffsetDistY',             type = 'float', cat = 'misc', min = -1.0, max = 1.0,      step = 0.01, dec = 2, unit = 'm', adv = true },
    { name = 'fSeatOffsetDistZ',             type = 'float', cat = 'misc', min = -1.0, max = 1.0,      step = 0.01, dec = 2, unit = 'm', adv = true },
    { name = 'nMonetaryValue',               type = 'int',   cat = 'misc', min = 0,    max = 10000000, step = 1000, dec = 0, adv = true },
}

-- Fast lookup map (name → def), used by client apply + server validation.
-- Also the whitelist: field names NOT in this map (e.g. CCarHandlingData
-- entries from older saves) are silently ignored everywhere.
HandlingFieldMap = {}
for _, f in ipairs(HandlingFields) do
    HandlingFieldMap[f.name] = f
end

