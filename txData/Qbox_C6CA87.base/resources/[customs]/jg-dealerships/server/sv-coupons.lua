Coupons = Coupons or {}
Coupons.Server = Coupons.Server or {}

local function generateCouponCode()
  local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  local code = ""

  for _ = 1, 4 do
    local index = math.random(1, #charset)
    code = code .. charset:sub(index, index)
  end

  code = code .. "-"

  for _ = 1, 4 do
    local index = math.random(1, #charset)
    code = code .. charset:sub(index, index)
  end

  return code
end

local function isCouponCodeAvailable(code, dealershipId)
  local existingCouponId = MySQL.scalar.await(
    "SELECT id FROM dealership_coupons WHERE code = ? AND dealership_id = ?",
    { code, dealershipId }
  )

  return not existingCouponId
end

local function notifyNoPermission(playerSource)
  Framework.Server.Notify(playerSource, Locale.employeePermissionsError, "error")
  return { error = true }
end

local function encodeRestrictionList(list)
  return list and json.encode(list) or nil
end

local function decodeCouponRestrictions(coupon)
  if coupon.vehicle_restrictions then
    coupon.vehicle_restrictions = json.decode(coupon.vehicle_restrictions)
  end

  if coupon.category_restrictions then
    coupon.category_restrictions = json.decode(coupon.category_restrictions)
  end

  return coupon
end

lib.callback.register("jg-dealerships:server:get-coupons", function(playerSource, data)
  if not Employees.Server.IsEmployee(playerSource, data.dealershipId, "MANAGE_INVENTORY") then
    DebugPrint("[DEBUG] IsEmployee check failed")
    return notifyNoPermission(playerSource)
  end

  local page = data.page or 1
  local limit = data.limit or 10
  local search = data.search or ""
  local offset = (page - 1) * limit
  local searchPattern = "%" .. search .. "%"

  local coupons = MySQL.query.await([[
    SELECT * FROM dealership_coupons
    WHERE dealership_id = ? AND code LIKE ?
    ORDER BY created_at DESC
    LIMIT ? OFFSET ?
  ]], { data.dealershipId, searchPattern, limit, offset }) or {}

  DebugPrint(("[COUPONS] Coupons query returned: %s rows"):format(#coupons))

  local total = MySQL.scalar.await([[
    SELECT COUNT(*) FROM dealership_coupons
    WHERE dealership_id = ? AND code LIKE ?
  ]], { data.dealershipId, searchPattern }) or 0

  DebugPrint(("[COUPONS] Total count: %s"):format(total))

  for _, coupon in ipairs(coupons) do
    decodeCouponRestrictions(coupon)
  end

  local result = {
    coupons = coupons,
    total = total,
  }

  DebugPrint(("[COUPONS] Returning result: %s"):format(json.encode(result)))
  return result
end)

lib.callback.register("jg-dealerships:server:create-coupon", function(playerSource, data)
  if not Employees.Server.IsEmployee(playerSource, data.dealershipId, "MANAGE_INVENTORY") then
    return notifyNoPermission(playerSource)
  end

  local playerIdentifier = Framework.Server.GetPlayerIdentifier(playerSource)
  if not playerIdentifier then
    return { error = true, message = "Failed to get player info" }
  end

  if not isCouponCodeAvailable(data.code, data.dealershipId) then
    Framework.Server.Notify(playerSource, Locale.couponCodeAlreadyExists, "error")
    return { error = true, message = "Coupon code already exists" }
  end

  local createdAt = os.time() * 1000
  local couponId = MySQL.insert.await([[
    INSERT INTO dealership_coupons
    (code, dealership_id, discount_type, discount_value, max_uses, per_player_limit,
     expiry_date, vehicle_restrictions, category_restrictions, allow_finance, created_at, created_by)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  ]], {
    data.code,
    data.dealershipId,
    data.discount_type,
    data.discount_value,
    data.max_uses,
    data.per_player_limit,
    data.expiry_date,
    encodeRestrictionList(data.vehicle_restrictions),
    encodeRestrictionList(data.category_restrictions),
    data.allow_finance and 1 or 0,
    createdAt,
    playerIdentifier,
  })

  if not couponId then
    Framework.Server.Notify(playerSource, Locale.failedToCreateCoupon, "error")
    return { error = true }
  end

  Framework.Server.Notify(playerSource, Locale.couponCreatedSuccessfully, "success")

  return {
    id = couponId,
    code = data.code,
    dealership_id = data.dealershipId,
    discount_type = data.discount_type,
    discount_value = data.discount_value,
    max_uses = data.max_uses,
    current_uses = 0,
    per_player_limit = data.per_player_limit,
    expiry_date = data.expiry_date,
    vehicle_restrictions = data.vehicle_restrictions,
    category_restrictions = data.category_restrictions,
    allow_finance = data.allow_finance,
    active = true,
    created_at = createdAt,
    created_by = playerIdentifier,
  }
end)

lib.callback.register("jg-dealerships:server:update-coupon", function(playerSource, data)
  if not Employees.Server.IsEmployee(playerSource, data.dealershipId, "MANAGE_INVENTORY") then
    return notifyNoPermission(playerSource)
  end

  local existingCoupon = MySQL.single.await(
    "SELECT * FROM dealership_coupons WHERE id = ? AND dealership_id = ?",
    { data.id, data.dealershipId }
  )

  if not existingCoupon then
    Framework.Server.Notify(playerSource, Locale.couponNotFound, "error")
    return { error = true }
  end

  if data.code ~= existingCoupon.code and not isCouponCodeAvailable(data.code, data.dealershipId) then
    Framework.Server.Notify(playerSource, Locale.couponCodeAlreadyExists, "error")
    return { error = true, message = "Coupon code already exists" }
  end

  MySQL.update.await([[
    UPDATE dealership_coupons
    SET code = ?, discount_type = ?, discount_value = ?, max_uses = ?,
        per_player_limit = ?, expiry_date = ?, vehicle_restrictions = ?,
        category_restrictions = ?, allow_finance = ?, active = ?
    WHERE id = ? AND dealership_id = ?
  ]], {
    data.code,
    data.discount_type,
    data.discount_value,
    data.max_uses,
    data.per_player_limit,
    data.expiry_date,
    encodeRestrictionList(data.vehicle_restrictions),
    encodeRestrictionList(data.category_restrictions),
    data.allow_finance and 1 or 0,
    data.active and 1 or 0,
    data.id,
    data.dealershipId,
  })

  Framework.Server.Notify(playerSource, Locale.couponUpdatedSuccessfully, "success")

  return {
    id = data.id,
    code = data.code,
    dealership_id = data.dealershipId,
    discount_type = data.discount_type,
    discount_value = data.discount_value,
    max_uses = data.max_uses,
    current_uses = existingCoupon.current_uses,
    per_player_limit = data.per_player_limit,
    expiry_date = data.expiry_date,
    vehicle_restrictions = data.vehicle_restrictions,
    category_restrictions = data.category_restrictions,
    allow_finance = data.allow_finance,
    active = data.active,
    created_at = existingCoupon.created_at,
    created_by = existingCoupon.created_by,
  }
end)

lib.callback.register("jg-dealerships:server:delete-coupon", function(playerSource, data)
  if not Employees.Server.IsEmployee(playerSource, data.dealershipId, "MANAGE_INVENTORY") then
    return notifyNoPermission(playerSource)
  end

  local result = MySQL.query.await(
    "DELETE FROM dealership_coupons WHERE id = ? AND dealership_id = ?",
    { data.id, data.dealershipId }
  )

  if not result then
    Framework.Server.Notify(playerSource, Locale.failedToDeleteCoupon, "error")
    return { error = true }
  end

  Framework.Server.Notify(playerSource, Locale.couponDeletedSuccessfully, "success")
  return { success = true }
end)

lib.callback.register("jg-dealerships:server:generate-coupon-code", function(playerSource, data)
  if not Employees.Server.IsEmployee(playerSource, data.dealershipId, "MANAGE_INVENTORY") then
    return { error = true }
  end

  local code
  local attempts = 0

  repeat
    code = generateCouponCode()
    attempts = attempts + 1
  until isCouponCodeAvailable(code, data.dealershipId) or attempts >= 100

  if attempts >= 100 then
    return { error = true, message = "Failed to generate unique code" }
  end

  return { code = code }
end)

function Coupons.Server.ValidateAndApplyCoupon(playerSource, dealershipId, code, vehicleSpawnCode, vehicleCategory, isFinanced, price, targetPlayer)
  if not code or code == "" then
    return { valid = false, message = "No coupon code provided" }
  end

  local coupon = MySQL.single.await([[
    SELECT * FROM dealership_coupons
    WHERE code = ? AND dealership_id = ? AND active = 1
  ]], { code, dealershipId })

  if not coupon then
    return { valid = false, message = "Invalid coupon code" }
  end

  if coupon.expiry_date and coupon.expiry_date < os.time() * 1000 then
    return { valid = false, message = "Coupon has expired" }
  end

  if coupon.max_uses and coupon.current_uses >= coupon.max_uses then
    return { valid = false, message = "Coupon has reached maximum uses" }
  end

  if not coupon.allow_finance and isFinanced then
    return { valid = false, message = "This coupon cannot be used with financed purchases" }
  end

  local playerId = targetPlayer or playerSource
  local playerIdentifier = Framework.Server.GetPlayerIdentifier(playerId)
  if not playerIdentifier then
    return { valid = false, message = "Failed to get player info" }
  end

  if coupon.per_player_limit then
    local usageCount = MySQL.scalar.await([[
      SELECT COUNT(*) FROM dealership_coupon_usage
      WHERE coupon_id = ? AND player_identifier = ?
    ]], { coupon.id, playerIdentifier })

    if usageCount >= coupon.per_player_limit then
      return { valid = false, message = "You have reached the usage limit for this coupon" }
    end
  end

  if coupon.vehicle_restrictions then
    local vehicleRestrictions = json.decode(coupon.vehicle_restrictions)
    local isAllowedVehicle = false

    for _, restrictedVehicle in ipairs(vehicleRestrictions) do
      if restrictedVehicle:lower() == vehicleSpawnCode:lower() then
        isAllowedVehicle = true
        break
      end
    end

    if not isAllowedVehicle then
      return { valid = false, message = "This coupon is not valid for this vehicle" }
    end
  end

  if coupon.category_restrictions then
    local categoryRestrictions = json.decode(coupon.category_restrictions)
    local isAllowedCategory = false

    for _, category in ipairs(categoryRestrictions) do
      if category == vehicleCategory then
        isAllowedCategory = true
        break
      end
    end

    if not isAllowedCategory then
      return { valid = false, message = "This coupon is not valid for this vehicle category" }
    end
  end

  local discount = coupon.discount_type == "percent"
    and price * (coupon.discount_value / 100)
    or coupon.discount_value

  discount = math.min(discount, price)

  return {
    valid = true,
    discount = discount,
    coupon = coupon,
  }
end

function Coupons.Server.RecordCouponUsage(couponId, playerIdentifier, vehicleSpawnCode, purchaseType, wasFinanced, discountApplied)
  MySQL.insert.await([[
    INSERT INTO dealership_coupon_usage
    (coupon_id, player_identifier, vehicle_spawn_code, purchase_type, was_financed, discount_applied, used_at)
    VALUES (?, ?, ?, ?, ?, ?, ?)
  ]], {
    couponId,
    playerIdentifier,
    vehicleSpawnCode,
    purchaseType,
    wasFinanced and 1 or 0,
    discountApplied,
    os.time() * 1000,
  })

  MySQL.update.await([[
    UPDATE dealership_coupons
    SET current_uses = current_uses + 1
    WHERE id = ?
  ]], { couponId })

  DebugPrint("Coupon usage recorded", "debug", {
    couponId = couponId,
    player = playerIdentifier,
    vehicle = vehicleSpawnCode,
    discount = discountApplied,
  })
end

exports("createCoupon", function(dealershipId, data)
  if type(dealershipId) ~= "string" then
    return false, "dealershipId must be a string"
  end

  if type(data) ~= "table" then
    return false, "data must be a table"
  end

  if data.discount_type ~= "percent" and data.discount_type ~= "fixed" then
    return false, "discount_type must be 'percent' or 'fixed'"
  end

  if type(data.discount_value) ~= "number" or data.discount_value <= 0 then
    return false, "discount_value must be a positive number"
  end

  local code = data.code

  if code then
    if not isCouponCodeAvailable(code, dealershipId) then
      return false, "coupon code already exists for this dealership"
    end
  else
    local attempts = 0

    repeat
      code = generateCouponCode()
      attempts = attempts + 1
    until isCouponCodeAvailable(code, dealershipId) or attempts >= 100

    if attempts >= 100 then
      return false, "failed to generate a unique coupon code"
    end
  end

  local createdAt = os.time() * 1000
  local couponId = MySQL.insert.await([[
    INSERT INTO dealership_coupons
    (code, dealership_id, discount_type, discount_value, max_uses, per_player_limit,
     expiry_date, vehicle_restrictions, category_restrictions, allow_finance, created_at, created_by)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  ]], {
    code,
    dealershipId,
    data.discount_type,
    data.discount_value,
    data.max_uses,
    data.per_player_limit,
    data.expiry_date,
    encodeRestrictionList(data.vehicle_restrictions),
    encodeRestrictionList(data.category_restrictions),
    data.allow_finance and 1 or 0,
    createdAt,
    "api",
  })

  if not couponId then
    return false, "failed to insert coupon into database"
  end

  return {
    id = couponId,
    code = code,
    dealership_id = dealershipId,
    discount_type = data.discount_type,
    discount_value = data.discount_value,
    max_uses = data.max_uses,
    current_uses = 0,
    per_player_limit = data.per_player_limit,
    expiry_date = data.expiry_date,
    vehicle_restrictions = data.vehicle_restrictions,
    category_restrictions = data.category_restrictions,
    allow_finance = data.allow_finance or false,
    active = true,
    created_at = createdAt,
    created_by = "api",
  }
end)

exports("validateCoupon", function(code, dealershipId, vehicleSpawnCode, vehicleCategory, isFinanced)
  if type(code) ~= "string" or type(dealershipId) ~= "string" then
    return { valid = false, message = "code and dealershipId must be strings" }
  end

  local coupon = MySQL.single.await([[
    SELECT * FROM dealership_coupons
    WHERE code = ? AND dealership_id = ? AND active = 1
  ]], { code, dealershipId })

  if not coupon then
    return { valid = false, message = "invalid coupon code" }
  end

  if coupon.expiry_date and coupon.expiry_date < os.time() * 1000 then
    return { valid = false, message = "coupon has expired" }
  end

  if coupon.max_uses and coupon.current_uses >= coupon.max_uses then
    return { valid = false, message = "coupon has reached maximum uses" }
  end

  if isFinanced and not coupon.allow_finance then
    return { valid = false, message = "coupon cannot be used with financed purchases" }
  end

  if vehicleSpawnCode and coupon.vehicle_restrictions then
    local vehicleRestrictions = json.decode(coupon.vehicle_restrictions)

    if vehicleRestrictions and #vehicleRestrictions > 0 then
      local isAllowedVehicle = false

      for _, restrictedVehicle in ipairs(vehicleRestrictions) do
        if restrictedVehicle:lower() == vehicleSpawnCode:lower() then
          isAllowedVehicle = true
          break
        end
      end

      if not isAllowedVehicle then
        return { valid = false, message = "coupon is not valid for this vehicle" }
      end
    end
  end

  if vehicleCategory and coupon.category_restrictions then
    local categoryRestrictions = json.decode(coupon.category_restrictions)

    if categoryRestrictions and #categoryRestrictions > 0 then
      local isAllowedCategory = false

      for _, category in ipairs(categoryRestrictions) do
        if category == vehicleCategory then
          isAllowedCategory = true
          break
        end
      end

      if not isAllowedCategory then
        return { valid = false, message = "coupon is not valid for this vehicle category" }
      end
    end
  end

  local discount = 0
  local vehiclePrice = 0

  if vehicleSpawnCode then
    local stockVehicle = MySQL.single.await(
      "SELECT price FROM dealership_stock WHERE vehicle = ? AND dealership = ?",
      { vehicleSpawnCode, dealershipId }
    )

    if stockVehicle then
      vehiclePrice = stockVehicle.price
    end
  end

  if vehiclePrice > 0 then
    discount = coupon.discount_type == "percent"
      and vehiclePrice * (coupon.discount_value / 100)
      or coupon.discount_value

    discount = math.min(discount, vehiclePrice)
  end

  return {
    valid = true,
    discount = discount,
    discount_type = coupon.discount_type,
    discount_value = coupon.discount_value,
  }
end)
