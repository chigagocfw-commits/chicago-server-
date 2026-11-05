if not Config or not Config.Societies or not Config.Societies.Enabled then
  return
end

Society = Society or {}

function Society:Init()
  self.enabled = Config and Config.Societies and Config.Societies.Enabled or false
  self.jobs = Config and Config.Societies and Config.Societies.Jobs or {}

  if self.enabled then
    self:ensureConfiguredAccounts()
  end
end

function Society:getJobConfig(jobName)
  if not jobName or type(self.jobs) ~= "table" then
    return nil
  end

  return self.jobs[jobName]
end

function Society:ensureConfiguredAccounts()
  for _, jobConfig in pairs(self.jobs or {}) do
    local accountNumber = jobConfig.AccountNumber
    local accountLabel = jobConfig.Label or (Translate and Translate("SOCIETY_ACCOUNT")) or "Society Account"

    if accountNumber and accountNumber ~= "" then
      local account = MySQL.query.await(
        "SELECT account_number FROM bablo_bank_accounts WHERE account_number = ? LIMIT 1",
        { accountNumber }
      )

      if not account or not account[1] then
        MySQL.insert.await([[
INSERT INTO bablo_bank_accounts (account_number, owner, name, balance, type, is_default, is_frozen)
				VALUES (?, NULL, ?, 0, 'shared', 0, 0)]], { accountNumber, accountLabel })
      end
    end
  end
end

local function getPlayerJob(source)
  local player = Framework and Framework.fetchPlayer and Framework:fetchPlayer(source)
  if not player then
    return nil
  end

  if Framework and Framework.getPlayerJobData then
    return Framework:getPlayerJobData(player)
  end

  if player.PlayerData and player.PlayerData.job then
    local job = player.PlayerData.job
    local grade = (job.grade and job.grade.level) or job.grade or 0
    local gradeName = (job.grade and job.grade.name) or tostring(job.grade_name or job.grade or "")

    return {
      name = job.name,
      label = job.label or job.name,
      grade = grade,
      gradeName = gradeName,
      isBoss = job.isboss == true
    }
  end

  if player.job then
    return {
      name = player.job.name,
      label = player.job.label or player.job.name,
      grade = player.job.grade or 0,
      gradeName = player.job.grade_name or tostring(player.job.grade or ""),
      isBoss = player.job.grade_name == "boss"
    }
  end

  return nil
end

function Society:hasAccess(source, jobName)
  if not self.enabled then
    return false
  end

  local jobConfig = self:getJobConfig(jobName)
  if not jobConfig then
    return false
  end

  local playerJob = getPlayerJob(source)
  if not playerJob or playerJob.name ~= jobName then
    return false
  end

  if playerJob.isBoss then
    return true
  end

  local accessRules = jobConfig.Access or {}
  local grade = tonumber(playerJob.grade or 0) or 0
  local gradeName = tostring(playerJob.gradeName or ""):lower()

  for _, rule in ipairs(accessRules) do
    if type(rule) == "number" and rule <= grade then
      return true
    end

    if type(rule) == "string" then
      local normalizedRule = rule:lower()

      if normalizedRule == gradeName then
        return true
      end

      if normalizedRule == "boss" and playerJob.isBoss then
        return true
      end

      local numericRule = tonumber(rule)
      if numericRule and grade >= numericRule then
        return true
      end
    end
  end

  return false
end

function Society:getAccountNumber(jobName)
  local jobConfig = self:getJobConfig(jobName)
  return jobConfig and jobConfig.AccountNumber or nil
end

function Society:getAccountLabel(jobName)
  local jobConfig = self:getJobConfig(jobName)
  return (jobConfig and jobConfig.Label) or (Translate and Translate("SOCIETY_ACCOUNT")) or "Society Account"
end

function Society:syncForSource(source)
  if not self.enabled then
    return
  end

  local playerJob = getPlayerJob(source)
  if not playerJob or not playerJob.name then
    return
  end

  local player = Framework and Framework.fetchPlayer and Framework:fetchPlayer(source)
  local identifier = player and Framework and Framework.getCharacterIdentifier and Framework:getCharacterIdentifier(player)
  if not identifier then
    return
  end

  for jobName, jobConfig in pairs(self.jobs or {}) do
    local accountNumber = jobConfig.AccountNumber

    if accountNumber and accountNumber ~= "" then
      if jobName == playerJob.name and self:hasAccess(source, jobName) then
        local accountUser = MySQL.query.await(
          "SELECT 1 FROM bablo_bank_account_users WHERE account_number = ? AND identifier = ? LIMIT 1",
          { accountNumber, identifier }
        )

        if not accountUser or not accountUser[1] then
          MySQL.insert.await(
            "INSERT INTO bablo_bank_account_users (account_number, identifier) VALUES (?, ?)",
            { accountNumber, identifier }
          )
        end

        local permission = MySQL.query.await(
          "SELECT can_view FROM bablo_bank_account_permissions WHERE account_number = ? AND identifier = ? LIMIT 1",
          { accountNumber, identifier }
        )

        if not permission or not permission[1] then
          MySQL.insert.await([[
INSERT INTO bablo_bank_account_permissions (account_number, identifier, can_view, can_deposit, can_withdraw, can_transfer, can_manage_members, can_manage_cards)
					VALUES (?, ?, 1, 1, 1, 1, 0, 0)]], { accountNumber, identifier })
        end

        MySQL.query.await(
          "DELETE FROM bablo_bank_account_user_roles WHERE account_number = ? AND identifier = ?",
          { accountNumber, identifier }
        )

        MySQL.insert.await(
          "INSERT INTO bablo_bank_account_user_roles (account_number, identifier, role) VALUES (?, ?, ?)",
          { accountNumber, identifier, playerJob.isBoss and "owner" or "admin" }
        )
      else
        MySQL.query.await(
          "DELETE FROM bablo_bank_account_permissions WHERE account_number = ? AND identifier = ?",
          { accountNumber, identifier }
        )
        MySQL.query.await(
          "DELETE FROM bablo_bank_account_user_roles WHERE account_number = ? AND identifier = ?",
          { accountNumber, identifier }
        )
        MySQL.query.await(
          "DELETE FROM bablo_bank_account_users WHERE account_number = ? AND identifier = ?",
          { accountNumber, identifier }
        )
      end
    end
  end
end

function Society:getBalance(jobName)
  local accountNumber = self:getAccountNumber(jobName)
  if not accountNumber then
    return 0
  end

  local result = MySQL.query.await(
    "SELECT balance FROM bablo_bank_accounts WHERE account_number = ? LIMIT 1",
    { accountNumber }
  )

  return result and result[1] and tonumber(result[1].balance) or 0
end

function Society:addMoney(jobName, amount)
  if not amount or amount <= 0 then
    return false
  end

  local accountNumber = self:getAccountNumber(jobName)
  if not accountNumber then
    return false
  end

  return MySQL.query.await(
    "UPDATE bablo_bank_accounts SET balance = balance + ? WHERE account_number = ?",
    { amount, accountNumber }
  ) ~= nil
end

function Society:removeMoney(jobName, amount)
  if not amount or amount <= 0 then
    return false
  end

  local accountNumber = self:getAccountNumber(jobName)
  if not accountNumber then
    return false
  end

  return MySQL.query.await(
    "UPDATE bablo_bank_accounts SET balance = GREATEST(0, balance - ?) WHERE account_number = ?",
    { amount, accountNumber }
  ) ~= nil
end
