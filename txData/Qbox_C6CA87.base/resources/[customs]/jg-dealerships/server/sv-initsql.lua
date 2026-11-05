local function splitString(input, separator)
  local parts = {}

  for part in input:gmatch(("([^%s]+)"):format(separator)) do
    parts[#parts + 1] = part:gsub("^%s*(.-)%s*$", "%1")
  end

  return parts
end

local function initSQL()
  if not Config.AutoRunSQL then
    return
  end

  local success = pcall(function()
    local sqlFileName = (Config.Framework == "QBCore" or Config.Framework == "Qbox") and "run-qb.sql" or "run-esx.sql"
    local file = assert(io.open(GetResourcePath(GetCurrentResourceName()) .. "/install/" .. sqlFileName, "rb"))
    local sqlContents = file:read("*all")
    file:close()

    MySQL.transaction.await(splitString(sqlContents, ";"))
  end)

  if not success then
    print("^1[SQL ERROR] There was an error while automatically running the required SQL. Don't worry, you just need to run the SQL file for your framework, found in the 'install' folder manually. If you've already ran the SQL code previously, and this error is annoying you, set Config.AutoRunSQL = false^0")
  end
end

InitSQL = initSQL
