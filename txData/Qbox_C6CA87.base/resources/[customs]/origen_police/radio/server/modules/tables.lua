-- Simple frequency system
-- Structure: Frecs[frequency] = { [playerId] = true, ... }
Frecs = {}

-- Multi-frequency system (unit-based)
-- Structure: MultiFrecs[group][unit][playerId] = { name, muted, ready, grade, job }
MultiFrecs = {
    [Config.PoliceJobName] = {
        entrada = {}  -- Default entry channel for police
    },
    none = {
        none = {}  -- Disconnected state
    }
}