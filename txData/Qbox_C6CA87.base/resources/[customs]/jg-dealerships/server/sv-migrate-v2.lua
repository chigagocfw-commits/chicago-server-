Migrate = Migrate or {}
Migrate.Server = Migrate.Server or {}

local function splitString(input, separator)
  local parts = {}

  for part in input:gmatch(("([^%s]+)"):format(separator)) do
    parts[#parts + 1] = part:gsub("^%s*(.-)%s*$", "%1")
  end

  return parts
end

function Migrate.Server.RunV2Migration()
  print("1. Running migration-v2.sql...")

  local success = pcall(function()
    local file = assert(io.open(GetResourcePath(GetCurrentResourceName()) .. "/install/migration-v2.sql", "rb"))
    local sqlContents = file:read("*all")
    file:close()

    MySQL.transaction.await(splitString(sqlContents, ";"))
  end)

  if not success then
    print("^1[SQL ERROR] There was an error while running migration-v2.sql. Please run it manually from the 'install' folder.^0")
    return
  end

  print("migration-v2.sql executed successfully")

  local useRGBColors = Config.UseRGBColors
  local vehicleColourOptions = Config.VehicleColourOptions

  print("2. Migrating display vehicles... (dealership_dispveh)")

  if vehicleColourOptions then
    local displayVehicles = MySQL.query.await("SELECT * FROM dealership_dispveh")

    if displayVehicles and #displayVehicles > 0 then
      for _, displayVehicle in ipairs(displayVehicles) do
        local colorIndex = displayVehicle.color and tonumber(displayVehicle.color)
        local colorOption = colorIndex and vehicleColourOptions[colorIndex]
        local migratedColor

        if colorOption then
          if useRGBColors and colorOption.hex then
            local r, g, b = lib.math.hextorgb(colorOption.hex)
            migratedColor = json.encode({ r = r, g = g, b = b })
          elseif colorOption.index then
            migratedColor = colorOption.index
          end
        end

        if migratedColor then
          MySQL.update.await("UPDATE dealership_dispveh SET color = ? WHERE id = ?", {
            migratedColor,
            displayVehicle.id,
          })
        end
      end
    end
  end

  print("Migration complete")
end
