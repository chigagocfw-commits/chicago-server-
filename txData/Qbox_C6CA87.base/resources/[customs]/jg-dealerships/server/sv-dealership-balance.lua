DealershipBalance = DealershipBalance or {}
DealershipBalance.Server = DealershipBalance.Server or {}

function DealershipBalance.Server.GetBalance(dealershipId)
  if Config.UseFrameworkJobs then
    local dealership = Locations.Server.GetById(dealershipId)
    if not dealership or not dealership.job_name or dealership.job_name == "" then
      return nil
    end

    return Framework.Server.GetSocietyBalance(dealership.job_name, "job")
  end

  return MySQL.scalar.await("SELECT balance FROM dealership_locations WHERE id = ?", { dealershipId })
end

lib.callback.register("jg-dealerships:server:dealership-balance:get", function(playerSource, dealershipId)
  if not Employees.Server.IsEmployee(playerSource, dealershipId) then
    return false
  end

  return DealershipBalance.Server.GetBalance(dealershipId)
end)

function DealershipBalance.Server.Add(dealershipId, amount)
  if amount < 0 then
    return false, "Amount must be positive"
  end

  if Config.UseFrameworkJobs then
    local dealership = Locations.Server.GetById(dealershipId)
    if not dealership or not dealership.job_name or dealership.job_name == "" then
      return false, "Dealership has no job configured"
    end

    Framework.Server.AddToSocietyFund(dealership.job_name, "job", amount)
  else
    MySQL.update.await("UPDATE dealership_locations SET balance = balance + ? WHERE id = ?", {
      amount,
      dealershipId,
    })
  end

  return true
end

function DealershipBalance.Server.Remove(dealershipId, amount)
  if amount < 0 then
    return false, "Amount must be positive"
  end

  if Config.UseFrameworkJobs then
    local dealership = Locations.Server.GetById(dealershipId)
    if not dealership or not dealership.job_name or dealership.job_name == "" then
      return false, "Dealership has no job configured"
    end

    Framework.Server.RemoveFromSocietyFund(dealership.job_name, "job", amount)
  else
    MySQL.update.await("UPDATE dealership_locations SET balance = balance - ? WHERE id = ?", {
      amount,
      dealershipId,
    })
  end

  return true
end

function DealershipBalance.Server.HasFunds(dealershipId, amount)
  local balance = DealershipBalance.Server.GetBalance(dealershipId)
  if balance == nil then
    return false, nil
  end

  return amount <= balance, balance
end

exports("getDealershipBalance", function(dealershipId)
  if type(dealershipId) ~= "string" then
    return false, "dealershipId must be a string"
  end

  local balance = DealershipBalance.Server.GetBalance(dealershipId)
  if balance == nil then
    return false, "dealership not found or has no balance configured"
  end

  return balance
end)

exports("addDealershipBalance", function(dealershipId, amount)
  if type(dealershipId) ~= "string" then
    return false, "dealershipId must be a string"
  end

  if type(amount) ~= "number" or amount <= 0 then
    return false, "amount must be a positive number"
  end

  return DealershipBalance.Server.Add(dealershipId, amount)
end)

exports("removeDealershipBalance", function(dealershipId, amount)
  if type(dealershipId) ~= "string" then
    return false, "dealershipId must be a string"
  end

  if type(amount) ~= "number" or amount <= 0 then
    return false, "amount must be a positive number"
  end

  return DealershipBalance.Server.Remove(dealershipId, amount)
end)
