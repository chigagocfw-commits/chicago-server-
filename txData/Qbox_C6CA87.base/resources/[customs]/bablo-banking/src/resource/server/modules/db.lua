local migrations = {
  [[
        CREATE TABLE IF NOT EXISTS bablo_bank_accounts
        (
            account_number VARCHAR(20) NOT NULL,
            owner VARCHAR(50) DEFAULT NULL,
            name VARCHAR(50) NOT NULL,
            balance INT(11) DEFAULT NULL,
            type VARCHAR(20) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            is_default INT(1) NOT NULL DEFAULT 0,
            is_frozen INT(1) NOT NULL DEFAULT 0,
            PRIMARY KEY (account_number)
        );
    ]],
  [[
        CREATE TABLE IF NOT EXISTS bablo_bank_account_users
        (
            account_number VARCHAR(20) NOT NULL,
            identifier VARCHAR(50) DEFAULT NULL,
            added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    ]],
  [[
        CREATE TABLE IF NOT EXISTS bablo_bank_account_user_roles
        (
            account_number VARCHAR(20) NOT NULL,
            identifier VARCHAR(50) DEFAULT NULL,
            role VARCHAR(20) NOT NULL
        );
    ]],
  [[
        CREATE TABLE IF NOT EXISTS bablo_bank_account_permissions
        (
            account_number VARCHAR(20) NOT NULL,
            identifier VARCHAR(50) NOT NULL,
            can_view TINYINT(1) NOT NULL DEFAULT 1,
            can_deposit TINYINT(1) NOT NULL DEFAULT 0,
            can_withdraw TINYINT(1) NOT NULL DEFAULT 0,
            can_transfer TINYINT(1) NOT NULL DEFAULT 0,
            can_manage_members TINYINT(1) NOT NULL DEFAULT 0,
            can_manage_cards TINYINT(1) NOT NULL DEFAULT 0,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        );
    ]],
  [[
        CREATE TABLE IF NOT EXISTS bablo_bank_transactions
        (
            account_number VARCHAR(20) NOT NULL,
            card_number VARCHAR(20) NOT NULL DEFAULT '',
            type VARCHAR(10) DEFAULT NULL,
            text VARCHAR(50) NOT NULL,
            amount INT(11) DEFAULT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    ]],
  [[
        CREATE TABLE IF NOT EXISTS bablo_bank_cards
        (
            card_number VARCHAR(20) NOT NULL,
            account_number VARCHAR(20) NOT NULL,
            pin INT(4) NOT NULL,
            state INT(1) NOT NULL DEFAULT 0,
            credit_limit INT(11) NOT NULL DEFAULT 0,
            credit_used INT(11) NOT NULL DEFAULT 0,
            provider VARCHAR(20) DEFAULT NULL,
            type VARCHAR(10) DEFAULT NULL,
            expiry VARCHAR(5) DEFAULT NULL,
            cvv VARCHAR(4) DEFAULT NULL,
            name VARCHAR(50) DEFAULT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (card_number)
        );
    ]],
  [[
        ALTER TABLE bablo_bank_cards
            ADD COLUMN IF NOT EXISTS credit_limit INT(11) NOT NULL DEFAULT 0,
            ADD COLUMN IF NOT EXISTS credit_used INT(11) NOT NULL DEFAULT 0,
            ADD COLUMN IF NOT EXISTS provider VARCHAR(20) DEFAULT NULL,
            ADD COLUMN IF NOT EXISTS type VARCHAR(10) DEFAULT NULL,
            ADD COLUMN IF NOT EXISTS expiry VARCHAR(5) DEFAULT NULL,
            ADD COLUMN IF NOT EXISTS cvv VARCHAR(4) DEFAULT NULL,
            ADD COLUMN IF NOT EXISTS name VARCHAR(50) DEFAULT NULL;
    ]],
  [[
        ALTER TABLE bablo_bank_cards
            MODIFY COLUMN card_number VARCHAR(20) NOT NULL;
    ]],
  [[
        ALTER TABLE bablo_bank_transactions
            MODIFY COLUMN card_number VARCHAR(20) NOT NULL DEFAULT '';
    ]],
  [[
		ALTER TABLE bablo_bank_transactions
			MODIFY COLUMN text LONGTEXT NOT NULL;
	]],
  [[
		CREATE TABLE IF NOT EXISTS bablo_bank_pending_transfers
		(
			id INT AUTO_INCREMENT PRIMARY KEY,
			owner_identifier VARCHAR(50) NOT NULL,
			dest_account_number VARCHAR(20) NOT NULL,
			amount INT(11) NOT NULL,
			description VARCHAR(100) DEFAULT NULL,
			status VARCHAR(10) NOT NULL DEFAULT 'pending',
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			processed_at TIMESTAMP NULL
		);
	]]
}

-- Required schema definition for verification (all 7 tables and runtime columns)
local requiredSchema = {
  bablo_bank_accounts = { "account_number", "owner", "name", "balance", "type", "created_at", "updated_at", "is_default", "is_frozen" },
  bablo_bank_account_users = { "account_number", "identifier", "added_at" },
  bablo_bank_account_user_roles = { "account_number", "identifier", "role" },
  bablo_bank_account_permissions = { "account_number", "identifier", "can_view", "can_deposit", "can_withdraw", "can_transfer", "can_manage_members", "can_manage_cards", "updated_at" },
  bablo_bank_transactions = { "account_number", "card_number", "type", "text", "amount", "created_at" },
  bablo_bank_cards = { "card_number", "account_number", "pin", "state", "credit_limit", "credit_used", "provider", "type", "expiry", "cvv", "name", "created_at", "updated_at" },
  bablo_bank_pending_transfers = { "id", "owner_identifier", "dest_account_number", "amount", "description", "status", "created_at", "processed_at" }
}

local function verifyBankingSchema()
  local missing = {}

  local rows = MySQL.query.await([[
    SELECT TABLE_NAME, COLUMN_NAME
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME LIKE 'bablo_bank_%'
  ]])

  local existingSchema = {}
  for _, row in ipairs(rows or {}) do
    local tbl = row.TABLE_NAME
    local col = row.COLUMN_NAME
    if not existingSchema[tbl] then
      existingSchema[tbl] = {}
    end
    existingSchema[tbl][col] = true
  end

  for tbl, requiredCols in pairs(requiredSchema) do
    if not existingSchema[tbl] then
      table.insert(missing, ("Missing table: %s"):format(tbl))
    else
      for _, col in ipairs(requiredCols) do
        if not existingSchema[tbl][col] then
          table.insert(missing, ("Missing column: %s.%s"):format(tbl, col))
        end
      end
    end
  end

  return #missing == 0, missing
end

MySQL.ready(function()
  Trace("Verifying database schema...")
  local ok, schemaValid, missingItems = pcall(verifyBankingSchema)

  if not ok then
    Trace("^1[ERROR] Failed to execute banking schema verification: %s^7", tostring(schemaValid))
    Trace("^3Banking initialization halted safely.^7")
    return
  end

  if not schemaValid or #missingItems > 0 then
    Trace("^1[ERROR] Banking schema verification failed! Missing schema elements:^7")
    for _, item in ipairs(missingItems) do
      Trace("  - %s", item)
    end
    Trace("^3Please run database migrations under DBA credentials. Banking initialization halted safely.^7")
    return
  end

  Trace("Database schema verified successfully (all 7 tables and required columns present).")
  Main:Init()
end)
