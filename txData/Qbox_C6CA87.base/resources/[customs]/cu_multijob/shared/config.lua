return {
    framework = "qbox", -- auto | LEGACYCORE | es_extended | qb-core | qbox | nd_core | ox_core | custom
    maxJobs = 50,
    allowedGroups = {
        ["admin"] = true,
        ["mod"] = true,
    },
    defaultJob = {
        name = "unemployed",
        label = "Unemployed",
        grade = 0,
        gradeLabel = "Unemployed",
    },
    command = "multijob",
    keybind = "J",
    locale = "en",
    locales = {
        en = {
            title = "Job selection",
            hintClose = "Close",
            hintSelect = "Select",
            hintResign = "Resign",
            keyClose = "ESC",
            keySelect = "ENTER",
            keyResign = "RMB",
            keybindLabel = "Open multijob menu",
        },
    },
    jobIcons = {
        police = "Shield",
        ambulance = "Stethoscope",
        mechanic = "Wrench",
        taxi = "Car",
        unemployed = "User",
    },
    jobColors = {
        police = "#3b82f6",
        ambulance = "#ef4444",
        mechanic = "#f59e0b",
        taxi = "#fbbf24",
        unemployed = "#9ca3af",
    },
    defaultIcon = "Briefcase",
    defaultColor = "#94a3b8",
}
