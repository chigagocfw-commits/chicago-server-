Employees = Employees or {}
Employees.Server = Employees.Server or {}

local function hasPermission(permissions, permission)
  for _, grantedPermission in ipairs(permissions) do
    if grantedPermission == permission then
      return true
    end
  end

  return false
end

local function syncFrameworkJob(identifier, dealershipId, role)
  local dealership = Locations.Server.GetById(dealershipId)
  if not dealership or not dealership.job_name or dealership.job_name == "" then
    return false
  end

  local jobRankMapping = dealership.job_rank_mapping
  if not jobRankMapping or type(jobRankMapping) ~= "table" or next(jobRankMapping) == nil then
    return false
  end

  local jobName
  local grade

  if role then
    grade = GetCaseInsensitive(jobRankMapping, role)
    if grade == nil then
      return false
    end

    jobName = dealership.job_name
  else
    jobName = "unemployed"
    grade = 0
  end

  local playerSource = Framework.Server.GetPlayerFromIdentifier(identifier)
  if playerSource then
    DebugPrint(("Setting job for %s(%s) to %s with rank %s"):format(identifier, playerSource, jobName, grade), "debug")
    Framework.Server.PlayerSetJob(playerSource, jobName, grade)
    return true
  end

  Framework.Server.PlayerSetJobOffline(identifier, jobName, grade)
  return false
end

local function notifyEmployeeStatusChanged(identifier, dealershipId)
  local playerSource = Framework.Server.GetPlayerFromIdentifier(identifier)
  if playerSource then
    TriggerClientEvent("jg-dealerships:client:employee-status-changed", playerSource, dealershipId)
  end
end

local function getEmployeePermissions(playerSource, dealershipId, includeServerAdmins)
  if includeServerAdmins == nil then
    includeServerAdmins = true
  end

  if includeServerAdmins and Framework.Server.IsAdmin(playerSource) then
    DebugPrint(playerSource .. " returned as server admin", "debug")
    return { "ADMIN" }, "serverAdmin"
  end

  local playerIdentifier = Framework.Server.GetPlayerIdentifier(playerSource)
  if not playerIdentifier then
    return false, false
  end

  if Config.UseFrameworkJobs then
    local dealership = Locations.Server.GetById(dealershipId)
    if not dealership or not dealership.job_name or dealership.job_name == "" then
      DebugPrint("Dealership " .. dealershipId .. " has no job_name configured", "debug")
      return false, false
    end

    local playerJob = Framework.Server.GetPlayerJob(playerSource)
    if not playerJob or not playerJob.name then
      DebugPrint("Could not get job for player " .. playerSource, "debug")
      return false, false
    end

    if playerJob.name ~= dealership.job_name then
      DebugPrint(("%s job (%s) does not match dealership job (%s)"):format(playerIdentifier, playerJob.name, dealership.job_name), "debug")
      return false, false
    end

    local rankPermissions = dealership.job_rank_permissions
    if not rankPermissions or type(rankPermissions) ~= "table" then
      DebugPrint("No job_rank_permissions configured for dealership " .. dealershipId, "warning")
      return {}, playerJob.gradeLabel or ("Grade " .. tostring(playerJob.grade))
    end

    local playerGrade = tonumber(playerJob.grade) or 0
    local permissions = rankPermissions[tostring(playerGrade)]
    if not permissions then
      DebugPrint(("No permissions mapped for grade %s at dealership %s"):format(playerGrade, dealershipId), "debug")
      return {}, playerJob.gradeLabel or ("Grade " .. tostring(playerJob.grade))
    end

    DebugPrint(("%s has framework job %s grade %s at %s"):format(playerIdentifier, playerJob.name, playerGrade, dealershipId), "debug")
    return permissions, playerJob.gradeLabel or ("Grade " .. tostring(playerJob.grade))
  end

  local employee = MySQL.single.await(
    "SELECT * FROM dealership_employees WHERE identifier = ? AND dealership = ?",
    { playerIdentifier, dealershipId }
  )

  if not employee then
    DebugPrint(playerIdentifier .. " is not an employee at " .. dealershipId, "debug")
    return false, false
  end

  local permissions = GetCaseInsensitive(Config.EmployeePermissions, employee.role)
  if not permissions then
    DebugPrint("No permissions configured for role: " .. employee.role, "warning")
    return {}, employee.role
  end

  DebugPrint(("%s is an employee at %s with role %s"):format(playerIdentifier, dealershipId, employee.role), "debug")
  return permissions, employee.role
end

function Employees.Server.IsEmployee(playerSource, dealershipId, requiredPermission, includeServerAdmins)
  local permissions, role = getEmployeePermissions(playerSource, dealershipId, includeServerAdmins)
  if not permissions then
    return false
  end

  if hasPermission(permissions, "ADMIN") then
    return role
  end

  if not requiredPermission then
    return role
  end

  if type(requiredPermission) == "string" then
    if not hasPermission(permissions, requiredPermission) then
      return false
    end
  elseif type(requiredPermission) == "table" then
    local hasAnyPermission = false
    for _, permission in ipairs(requiredPermission) do
      if hasPermission(permissions, permission) then
        hasAnyPermission = true
        break
      end
    end

    if not hasAnyPermission then
      return false
    end
  end

  return role
end

local function playerHasPermission(playerSource, dealershipId, permission)
  local permissions = getEmployeePermissions(playerSource, dealershipId)
  if not permissions then
    return false
  end

  return hasPermission(permissions, "ADMIN") or hasPermission(permissions, permission)
end

function Employees.Server.GetPermissions(playerSource, dealershipId, includeServerAdmins)
  local permissions = getEmployeePermissions(playerSource, dealershipId, includeServerAdmins or false)
  if not permissions then
    return {}
  end

  if hasPermission(permissions, "ADMIN") then
    return {
      "ADMIN",
      "MANAGE_EMPLOYEES",
      "MANAGE_INVENTORY",
      "MANAGE_FINANCES",
      "SELL",
      "DELIVER",
      "VIEW_RECORDS",
    }
  end

  return permissions
end

function Employees.Server.GetEmployees(dealershipId)
  return MySQL.query.await(
    "SELECT * FROM dealership_employees WHERE dealership = ? ORDER BY joined DESC",
    { dealershipId }
  ) or {}
end

function Employees.Server.HireEmployee(identifier, dealershipId, role)
  local existingEmployee = MySQL.single.await(
    "SELECT id FROM dealership_employees WHERE identifier = ? AND dealership = ?",
    { identifier, dealershipId }
  )

  if existingEmployee then
    return false
  end

  MySQL.insert.await(
    "INSERT INTO dealership_employees (identifier, dealership, role) VALUES (?, ?, ?)",
    { identifier, dealershipId, role }
  )

  if not syncFrameworkJob(identifier, dealershipId, role) then
    notifyEmployeeStatusChanged(identifier, dealershipId)
  end

  return true
end

function Employees.Server.FireEmployee(identifier, dealershipId)
  local existingEmployee = MySQL.single.await(
    "SELECT id FROM dealership_employees WHERE identifier = ? AND dealership = ?",
    { identifier, dealershipId }
  )

  if not existingEmployee then
    return false
  end

  MySQL.query.await(
    "DELETE FROM dealership_employees WHERE identifier = ? AND dealership = ?",
    { identifier, dealershipId }
  )

  if not syncFrameworkJob(identifier, dealershipId, nil) then
    notifyEmployeeStatusChanged(identifier, dealershipId)
  end

  return true
end

function Employees.Server.UpdateRole(identifier, dealershipId, role)
  local existingEmployee = MySQL.single.await(
    "SELECT id FROM dealership_employees WHERE identifier = ? AND dealership = ?",
    { identifier, dealershipId }
  )

  if not existingEmployee then
    return false
  end

  MySQL.query.await(
    "UPDATE dealership_employees SET role = ? WHERE identifier = ? AND dealership = ?",
    { role, identifier, dealershipId }
  )

  if not syncFrameworkJob(identifier, dealershipId, role) then
    notifyEmployeeStatusChanged(identifier, dealershipId)
  end

  return true
end

function Employees.Server.GetEmployeesWithInfo(playerSource, dealershipId)
  if not playerHasPermission(playerSource, dealershipId, "MANAGE_EMPLOYEES") then
    Framework.Server.Notify(playerSource, Locale.employeePermissionsError, "error")
    return { error = true }
  end

  local employees = Employees.Server.GetEmployees(dealershipId)
  local playerIdentifier = Framework.Server.GetPlayerIdentifier(playerSource)

  for _, employee in ipairs(employees) do
    local playerInfo = Framework.Server.GetPlayerInfoFromIdentifier(employee.identifier)
    employee.name = playerInfo and playerInfo.name or employee.identifier
    employee.me = employee.identifier == playerIdentifier
  end

  return employees
end

lib.callback.register("jg-dealerships:server:is-employee", function(playerSource, dealershipId, includeServerAdmins)
  local employeeRole = Employees.Server.IsEmployee(playerSource, dealershipId, nil, includeServerAdmins)
  if not employeeRole then
    return { isEmployee = false }
  end

  local playerInfo = Framework.Server.GetPlayerInfo(playerSource)
  return {
    isEmployee = true,
    employeeName = playerInfo and playerInfo.name or "",
    employeeRole = employeeRole,
    permissions = Employees.Server.GetPermissions(playerSource, dealershipId, includeServerAdmins),
  }
end)

lib.callback.register("jg-dealerships:server:get-dealership-employees", function(playerSource, data)
  return Employees.Server.GetEmployeesWithInfo(playerSource, data.dealershipId)
end)

RegisterNetEvent("jg-dealerships:server:request-hire-employee", function(data)
  local playerSource = source

  if not playerHasPermission(playerSource, data.dealershipId, "MANAGE_EMPLOYEES") then
    Framework.Server.Notify(playerSource, Locale.employeePermissionsError, "error")
    return
  end

  if data.selfHire and data.playerId == playerSource then
    if not Framework.Server.IsAdmin(playerSource) then
      Framework.Server.Notify(playerSource, Locale.onlyServerAdminsCanSelfHire, "error")
      return
    end

    local identifier = Framework.Server.GetPlayerIdentifier(playerSource)
    if not identifier then
      Framework.Server.Notify(playerSource, Locale.playerNotFound, "error")
      return
    end

    if not Employees.Server.HireEmployee(identifier, data.dealershipId, data.role) then
      Framework.Server.Notify(playerSource, Locale.failedToHireEmployee, "error")
      return
    end

    SendWebhook(playerSource, Webhooks.Dealership, "Dealership: Employee Self-Hired", "success", {
      { key = "Dealership", value = (Locations.Server.GetById(data.dealershipId) or {}).name or data.dealershipId },
      { key = "Role", value = data.role },
    })

    Framework.Server.Notify(playerSource, Locale.employeeHiredMsg, "success")
    TriggerClientEvent("jg-dealerships:client:employee-hire-response", playerSource, {
      accepted = true,
      playerName = data.playerName,
      identifier = identifier,
      role = data.role,
    })
    return
  end

  data.requesterId = playerSource
  TriggerClientEvent("jg-dealerships:client:show-confirm-employment", data.playerId, data)
end)

RegisterNetEvent("jg-dealerships:server:employee-hire-rejected", function(requesterId, playerName)
  Framework.Server.Notify(requesterId, Locale.employeeRejectedMsg, "error")
  TriggerClientEvent("jg-dealerships:client:employee-hire-response", requesterId, {
    accepted = false,
    playerName = playerName,
  })
end)

RegisterNetEvent("jg-dealerships:server:hire-employee", function(data)
  local playerSource = source
  local identifier = Framework.Server.GetPlayerIdentifier(data.playerId)

  if not identifier then
    Framework.Server.Notify(data.requesterId, Locale.playerNotFound, "error")
    TriggerClientEvent("jg-dealerships:client:employee-hire-response", data.requesterId, {
      accepted = false,
      playerName = data.playerName,
    })
    return
  end

  DebugPrint(("Hiring employee %s(%s) at %s with role %s"):format(identifier, data.playerId, data.dealershipId, data.role), "debug")

  if not Employees.Server.HireEmployee(identifier, data.dealershipId, data.role) then
    Framework.Server.Notify(data.requesterId, Locale.failedToHireEmployee, "error")
    TriggerClientEvent("jg-dealerships:client:employee-hire-response", data.requesterId, {
      accepted = false,
      playerName = data.playerName,
    })
    return
  end

  local playerInfo = Framework.Server.GetPlayerInfo(data.playerId)
  SendWebhook(playerSource, Webhooks.Dealership, "Dealership: Employee Hired", "success", {
    { key = "Dealership", value = (Locations.Server.GetById(data.dealershipId) or {}).name or data.dealershipId },
    { key = "Employee", value = playerInfo and playerInfo.name or identifier },
    { key = "Role", value = data.role },
  })

  Framework.Server.Notify(data.requesterId, Locale.employeeHiredMsg, "success")
  TriggerClientEvent("jg-dealerships:client:employee-hire-response", data.requesterId, {
    accepted = true,
    playerName = data.playerName,
    identifier = identifier,
    role = data.role,
  })
end)

RegisterNetEvent("jg-dealerships:server:fire-employee", function(identifier, dealershipId)
  local playerSource = source

  if not playerHasPermission(playerSource, dealershipId, "MANAGE_EMPLOYEES") then
    Framework.Server.Notify(playerSource, Locale.employeePermissionsError, "error")
    return
  end

  local playerInfo = Framework.Server.GetPlayerInfoFromIdentifier(identifier)
  local employeePlayerSource = Framework.Server.GetPlayerFromIdentifier(identifier)

  if not Employees.Server.FireEmployee(identifier, dealershipId) then
    Framework.Server.Notify(playerSource, Locale.failedToFireEmployee, "error")
    return
  end

  if employeePlayerSource then
    Framework.Server.Notify(
      employeePlayerSource,
      Locale.firedNotification:gsub("%%{value}", dealershipId),
      "error"
    )
  end

  SendWebhook(playerSource, Webhooks.Dealership, "Dealership: Employee Fired", "danger", {
    { key = "Dealership", value = (Locations.Server.GetById(dealershipId) or {}).name or dealershipId },
    { key = "Employee", value = playerInfo and playerInfo.name or identifier },
  })
end)

RegisterNetEvent("jg-dealerships:server:update-employee-role", function(identifier, dealershipId, role)
  local playerSource = source

  if not playerHasPermission(playerSource, dealershipId, "MANAGE_EMPLOYEES") then
    Framework.Server.Notify(playerSource, Locale.employeePermissionsError, "error")
    return
  end

  if not Employees.Server.UpdateRole(identifier, dealershipId, role) then
    Framework.Server.Notify(playerSource, Locale.failedToUpdateEmployeeRole, "error")
    return
  end

  local playerInfo = Framework.Server.GetPlayerInfoFromIdentifier(identifier)
  SendWebhook(playerSource, Webhooks.Dealership, "Dealership: Employee Updated", nil, {
    { key = "Dealership", value = (Locations.Server.GetById(dealershipId) or {}).name or dealershipId },
    { key = "Employee", value = playerInfo and playerInfo.name or identifier },
    { key = "New role", value = role },
  })
end)

exports("isEmployee", function(playerSource, dealershipId)
  if type(playerSource) ~= "number" or type(dealershipId) ~= "string" then
    return false
  end

  return Employees.Server.IsEmployee(playerSource, dealershipId)
end)

exports("hasPermission", function(playerSource, dealershipId, permission)
  if type(playerSource) ~= "number" or type(dealershipId) ~= "string" or type(permission) ~= "string" then
    return false
  end

  return Employees.Server.IsEmployee(playerSource, dealershipId, permission) ~= false
end)

exports("getEmployees", function(dealershipId)
  if type(dealershipId) ~= "string" then
    return {}
  end

  return Employees.Server.GetEmployees(dealershipId)
end)
