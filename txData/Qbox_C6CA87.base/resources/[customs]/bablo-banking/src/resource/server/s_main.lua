while not eventName do
  Wait(0)
end

if GetCurrentResourceName() ~= "bablo-banking" then
  error("Resource name must be 'bablo-banking'")
  return
end

local function syncSocietyAccounts(playerSource)
  if Society and Society.Init then
    Society:Init()
    Society:syncForSource(playerSource)
  end
end

RegisterServerEvent(eventName .. "server:characterLoaded")
AddEventHandler(eventName .. "server:characterLoaded", function()
  local playerSource = source
  local player = Framework:fetchPlayer(playerSource)

  if not player then
    Trace("Character not found for source: " .. tostring(playerSource))
    return
  end

  local identifier = Framework:getCharacterIdentifier(player)
  if not identifier then
    Trace("Identifier not found for character: " .. tostring(player.PlayerData.citizenid))
    return
  end

  local pendingTransfers = MySQL.query.await([[
		SELECT id, amount FROM bablo_bank_pending_transfers
		WHERE owner_identifier = ? AND status = 'pending'
	]], { identifier })

  if pendingTransfers and #pendingTransfers > 0 then
    local appliedAmount = 0

    for _, transfer in ipairs(pendingTransfers) do
      local amount = tonumber(transfer.amount) or 0

      if Framework:addPlayerMoney(player, "bank", amount) then
        MySQL.query.await(" DELETE FROM bablo_bank_pending_transfers WHERE id = ? ", { transfer.id })
        appliedAmount = appliedAmount + amount
      end
    end

    if appliedAmount > 0 then
      TriggerClientEvent(
        eventName .. "client:sendNotify",
        playerSource,
        ("Applied $%s pending transfers"):format(tostring(appliedAmount))
      )
    end
  end

  local accountCount = MySQL.query.await([[
            SELECT COUNT(*) as count FROM bablo_bank_accounts WHERE owner = ? AND is_default = 1
        ]], { identifier })

  if accountCount[1] and accountCount[1].count > 0 then
    Trace("Main account already exists for identifier: " .. identifier)
    syncSocietyAccounts(playerSource)
    return
  end

  local accountNumber = GenerateAccountNumber()
  local accountLabel = Translate("MAIN_ACCOUNT_LABEL")

  local accountInsert, accountError = MySQL.insert.await([[
            INSERT INTO bablo_bank_accounts (account_number, owner, name, balance, type, is_default)
            VALUES (?, ?, ?, 0, 'personal', 1)
        ]], { accountNumber, identifier, accountLabel })

  if not accountInsert then
    Trace("Failed to create main account for identifier: " .. identifier .. " Error: " .. tostring(accountError))
    return
  end

  local userInsert, userError = MySQL.insert.await([[
            INSERT INTO bablo_bank_account_users (account_number, identifier)
            VALUES (?, ?)
        ]], { accountNumber, identifier })

  if not userInsert then
    Trace("Failed to link main account to user for identifier: " .. identifier .. " Error: " .. tostring(userError))
    return
  end

  local roleInsert, roleError = MySQL.insert.await([[
            INSERT INTO bablo_bank_account_user_roles (account_number, identifier, role)
            VALUES (?, ?, 'owner')
        ]], { accountNumber, identifier })

  if not roleInsert then
    Trace("Failed to assign owner role for main account for identifier: " .. identifier .. " Error: " .. tostring(roleError))
    return
  end

  Trace("Main account created successfully for identifier: " .. identifier .. " Account Number: " .. accountNumber)
  syncSocietyAccounts(playerSource)
end)

RegisterServerEvent(eventName .. "server:playerLoaded")
AddEventHandler(eventName .. "server:playerLoaded", function()
  TriggerEvent(eventName .. "server:characterLoaded")
end)

Citizen.CreateThread(function()
  if not Config.DEBUG then
    return
  end

  local function debugContacts(accountNumber)
    return {
      {
        iban = accountNumber,
        firstName = "Me",
        lastName = "Main",
        id = accountNumber,
        accountName = "Main",
        isOwned = true,
        ownerName = ""
      },
      {
        iban = "B111111111",
        firstName = "Alex",
        lastName = "Rivera",
        id = "B111111111",
        accountName = "Alex Personal",
        isOwned = false,
        ownerName = "Alex Rivera"
      },
      {
        iban = "B222222222",
        firstName = "Brooke",
        lastName = "Kim",
        id = "B222222222",
        accountName = "Brooke Personal",
        isOwned = false,
        ownerName = "Brooke Kim"
      },
      {
        iban = "B333333333",
        firstName = "Chris",
        lastName = "Ng",
        id = "B333333333",
        accountName = "Chris Personal",
        isOwned = false,
        ownerName = "Chris Ng"
      }
    }
  end

  RegisterCommand("bb_debug_contacts", function(playerSource)
    if playerSource == 0 then
      return
    end

    local accountNumber = Main:getDefaultAccountNumberForSource(playerSource)
    if not accountNumber then
      return
    end

    local player = Framework:fetchPlayer(playerSource)
    local identifier = player and Framework:getCharacterIdentifier(player)
    if not identifier then
      return
    end

    TriggerClientEvent(eventName .. "client:saveRecentContacts", playerSource, identifier, debugContacts(accountNumber))
    TriggerClientEvent(eventName .. "client:sendNotify", playerSource, "Debug contacts created")
  end, false)

  RegisterCommand("bb_debug_all", function(playerSource)
    local accountNumber = Main:getDefaultAccountNumberForSource(playerSource)
    if not accountNumber then
      Trace("No default account for source " .. tostring(playerSource))
      return
    end

    Main:createDebugTransactionsTwoWeeks(accountNumber)

    if playerSource ~= 0 then
      local player = Framework:fetchPlayer(playerSource)
      local identifier = player and Framework:getCharacterIdentifier(player)

      TriggerClientEvent(eventName .. "client:saveRecentContacts", playerSource, identifier, debugContacts(accountNumber))
      TriggerClientEvent(eventName .. "client:sendNotify", playerSource, "Debug data created")
    end
  end, false)

  RegisterCommand("createdebugtransactions", function(playerSource, args)
    if playerSource == 0 then
      local accountNumber = args[1] or "B831742542"
      Trace("Creating debug transactions for account: " .. accountNumber)
      Main:createDebugTransactions(accountNumber)
      return
    end

    local player = Framework:fetchPlayer(playerSource)
    local identifier = player and Framework:getCharacterIdentifier(player)

    if identifier then
      local accountNumber = args[1] or "B831742542"
      Trace("Player " .. tostring(playerSource) .. " creating debug transactions for account: " .. accountNumber .. "^0")
      Main:createDebugTransactions(accountNumber)
    end
  end, true)
end)
