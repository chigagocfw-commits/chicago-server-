-- =====================================================
--  Fixed by Reddev Development
--  Support: https://discord.gg/MJH5zX7NSg
--  Cleaned By Reddev Using Codex 5.5
--  Files Provided From Rip_Bytecode
-- =====================================================
Config = {} -- Reddev: reviewed config line.
Config.Target = false -- Whether to use target or text UI.

-- You can ignore this if you use target.
-- This cannot be changed on clients that already cached this.
Config.Keybinds = { -- Reddev: reviewed config line.
    'E', 'G', 'C' -- Reddev: reviewed config line.
} -- Reddev: reviewed config line.

Config.Dispatch = { -- Reddev: reviewed config line.
    Enable = true, -- Enable dispatch
    Type = 'normal', -- ['normal'/'cd_dispatch'/'qs-dispatch'/'ps-dispatch'/'rcore_dispatch'/'tk_dispatch']
	Jobs = { -- Reddev: reviewed config line.
		'police', -- Reddev: reviewed config line.
		'sheriff' -- Reddev: reviewed config line.
	} -- Reddev: reviewed config line.
} -- Reddev: reviewed config line.

-- The distance at which peds and props get loaded in for players
Config.SpawnDistance = 100.0 -- Reddev: reviewed config line.

-- The built-in 3D prompts
Config.Prompts = { -- Reddev: reviewed config line.
	Enabled = true, -- Reddev: reviewed config line.
	RenderDistance = 3.0, -- Don't put this to more than 5.0 to avoid issues
	SpriteSize = 0.0170, -- Reddev: reviewed config line.
	SpriteColor = { r = 170, g = 170, b = 255, a = 255 }, -- Reddev: reviewed config line.
	---@type 'prompt' | 'prompt_old'
	Dict = 'prompt' -- Choose the one you like
} -- Reddev: reviewed config line.

-- This will map addAccountMoney calls to your dirty money item
-- You can use your black_money item as an account in our scripts due to this
Config.BlackMoney = { -- Reddev: reviewed config line.
	-- You can change it to whatever your dirty money item name is
	ItemName = 'black_money', -- Reddev: reviewed config line.

	-- marked_bills use metadata in some moneywashing scripts, this is up to you
	-- Beware that you can only use the dirty money item as a reward when this is set to true
	-- I don't recommend using this if you're not 100% sure
	UsesMetadata = false -- Reddev: reviewed config line.
} -- Reddev: reviewed config line.