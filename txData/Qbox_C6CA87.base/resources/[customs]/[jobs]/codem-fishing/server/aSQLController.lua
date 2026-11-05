-- SQL Table Definitions
local tableDefinitions = {
  codem_fishingjob_player = [[
        CREATE TABLE IF NOT EXISTS `codem_fishingjob_player` (
            `identifier` char(50) DEFAULT NULL,
            `dailymission` longtext DEFAULT NULL,
            `level` char(50) DEFAULT NULL,
            `xp` char(50) DEFAULT NULL,
            `name` char(50) DEFAULT NULL,
            `profilephoto` longtext DEFAULT NULL,
            `totalearnings` char(50) DEFAULT NULL,
            `totalfishes` char(50) DEFAULT NULL,
            `dailydelivery` longtext DEFAULT NULL,
            UNIQUE KEY `identifier` (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]],
  codem_fishingjob_log = [[
        CREATE TABLE IF NOT EXISTS `codem_fishingjob_log` (
            `identifier` char(50) DEFAULT NULL,
            `log` longtext DEFAULT NULL,
            `last_update` char(50) DEFAULT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]]
}

-- Column Definitions for Table Migrations
local tableColumnDefinitions = {
  codem_fishingjob_player = {
    { column = "identifier",    alterQuery = "ALTER TABLE `codem_fishingjob_player` ADD COLUMN `identifier` char(50) DEFAULT NULL;",     correctType = "char(50)" },
    { column = "dailymission",  alterQuery = "ALTER TABLE `codem_fishingjob_player` ADD COLUMN `dailymission`  longtext DEFAULT NULL;",  correctType = "longtext" },
    { column = "level",         alterQuery = "ALTER TABLE `codem_fishingjob_player` ADD COLUMN `level`  char(50) DEFAULT NULL;",         correctType = "char(50)" },
    { column = "xp",            alterQuery = "ALTER TABLE `codem_fishingjob_player` ADD COLUMN `xp` char(50) DEFAULT NULL;",             correctType = "char(50)" },
    { column = "name",          alterQuery = "ALTER TABLE `codem_fishingjob_player` ADD COLUMN `name`  char(50) DEFAULT NULL;",          correctType = "char(50)" },
    { column = "profilephoto",  alterQuery = "ALTER TABLE `codem_fishingjob_player` ADD COLUMN `profilephoto`  longtext DEFAULT NULL;",  correctType = "longtext" },
    { column = "totalearnings", alterQuery = "ALTER TABLE `codem_fishingjob_player` ADD COLUMN `totalearnings`  char(50) DEFAULT NULL;", correctType = "char(50)" },
    { column = "totalfishes",   alterQuery = "ALTER TABLE `codem_fishingjob_player` ADD COLUMN `totalfishes`  char(50) DEFAULT NULL;",   correctType = "char(50)" },
    { column = "dailydelivery", alterQuery = "ALTER TABLE `codem_fishingjob_player` ADD COLUMN `dailydelivery` longtext DEFAULT NULL;",  correctType = "longtext" }
  },
  codem_fishingjob_log = {
    { column = "identifier",  alterQuery = "ALTER TABLE `codem_fishingjob_log` ADD COLUMN `identifier` char(50) DEFAULT NULL;",  correctType = "char(50)" },
    { column = "log",         alterQuery = "ALTER TABLE `codem_fishingjob_log` ADD COLUMN `log`  longtext DEFAULT NULL;",        correctType = "longtext" },
    { column = "last_update", alterQuery = "ALTER TABLE `codem_fishingjob_log` ADD COLUMN `last_update` char(50) DEFAULT NULL;", correctType = "char(50)" }
  }
}

-- Check and Update Column Type
function CheckAndUpdateColumnType(tableName, columnName, expectedType)
  local showColumnQuery = "SHOW COLUMNS FROM `" .. tableName .. "` LIKE '" .. columnName .. "';"

  local function handleResult(result)
    if #result > 0 then
      local currentType = result[1].Type:lower()

      if currentType ~= expectedType then
        print("Column `" ..
        columnName .. "` type `" .. currentType .. "` as it is found in, `" .. expectedType .. "` is updated as..")

        local alterQuery = "ALTER TABLE `" ..
        tableName .. "` MODIFY `" .. columnName .. "` " .. expectedType .. " DEFAULT NULL;"

        if Config.SQL == "oxmysql" then
          exports.oxmysql:execute(alterQuery, {}, function(success)
            if success then
              print("Column `" .. columnName .. "` successfully `" .. expectedType .. "` updated as.")
            else
              print("Column `" .. columnName .. "` failed to update.")
            end
          end)
        elseif Config.SQL == "ghmattimysql" then
          exports.ghmattimysql:execute(alterQuery, {}, function(success)
            if success then
              print("Column `" .. columnName .. "` successfully `" .. expectedType .. "` updated as.")
            else
              print("Column `" .. columnName .. "` failed to update.")
            end
          end)
        elseif Config.SQL == "mysql-async" then
          MySQL.Async.execute(alterQuery, {}, function(success)
            if success then
              print("Column `" .. columnName .. "` successfully `" .. expectedType .. "` updated as.")
            else
              print("Column `" .. columnName .. "` failed to update.")
            end
          end)
        end
      end
    else
      print("Colomn `" .. columnName .. "` not found.")
    end
  end

  if Config.SQL == "oxmysql" then
    exports.oxmysql:execute(showColumnQuery, {}, handleResult)
  elseif Config.SQL == "ghmattimysql" then
    exports.ghmattimysql:execute(showColumnQuery, {}, handleResult)
  elseif Config.SQL == "mysql-async" then
    MySQL.Async.fetchAll(showColumnQuery, {}, handleResult)
  end
end

-- Check and Update Column Collation
function CheckAndUpdateColumnCollation(tableName, columnName, expectedCollation)
  local showColumnsQuery = "SHOW FULL COLUMNS FROM `" .. tableName .. "` LIKE '" .. columnName .. "';"

  local function handleResult(result)
    if #result > 0 then
      local currentCollation = result[1].Collation

      if currentCollation ~= expectedCollation then
        print("Column `" ..
        columnName .. "` has collation `" .. currentCollation .. "`, updating to `" .. expectedCollation .. "`.")

        local columnType = result[1].Type
        local alterQuery = "ALTER TABLE `" ..
        tableName .. "` MODIFY `" .. columnName .. "` " .. columnType .. " COLLATE " .. expectedCollation .. ";"

        if Config.SQL == "oxmysql" then
          exports.oxmysql:execute(alterQuery, {}, function(success)
            if success then
              print("Collation of column `" .. columnName .. "` updated to `" .. expectedCollation .. "` successfully.")
            else
              print("Failed to update collation of column `" .. columnName .. "`.")
            end
          end)
        elseif Config.SQL == "ghmattimysql" then
          exports.ghmattimysql:execute(alterQuery, {}, function(success)
            if success then
              print("Collation of column `" .. columnName .. "` updated to `" .. expectedCollation .. "` successfully.")
            else
              print("Failed to update collation of column `" .. columnName .. "`.")
            end
          end)
        elseif Config.SQL == "mysql-async" then
          MySQL.Async.execute(alterQuery, {}, function(success)
            if success then
              print("Collation of column `" .. columnName .. "` updated to `" .. expectedCollation .. "` successfully.")
            else
              print("Failed to update collation of column `" .. columnName .. "`.")
            end
          end)
        end
      end
    else
      print("Column `" .. columnName .. "` not found for collation check.")
    end
  end

  if Config.SQL == "oxmysql" then
    exports.oxmysql:execute(showColumnsQuery, {}, handleResult)
  elseif Config.SQL == "ghmattimysql" then
    exports.ghmattimysql:execute(showColumnsQuery, {}, handleResult)
  elseif Config.SQL == "mysql-async" then
    MySQL.Async.fetchAll(showColumnsQuery, {}, handleResult)
  end
end

-- Check and Add Missing Column
function CheckAndAddColumn(tableName, columnDefinition, callback)
  local columnName = columnDefinition.column
  local alterQuery = columnDefinition.alterQuery
  local expectedType = columnDefinition.correctType
  local expectedCollation = "utf8mb4_unicode_ci"

  local showColumnQuery = "SHOW COLUMNS FROM `" .. tableName .. "` LIKE '" .. columnName .. "';"

  local function handleResult(result)
    if #result == 0 then
      print("Column `" .. columnName .. "` not found, adding...")

      if Config.SQL == "oxmysql" then
        exports.oxmysql:execute(alterQuery, {}, function(success)
          if success then
            callback(true)
          else
            print("Colomn `" .. columnName .. "` could not be added.")
            callback(false)
          end
        end)
      elseif Config.SQL == "ghmattimysql" then
        exports.ghmattimysql:execute(alterQuery, {}, function(success)
          if success then
            callback(true)
          else
            print("Column `" .. columnName .. "` could not be added.")
            callback(false)
          end
        end)
      elseif Config.SQL == "mysql-async" then
        MySQL.Async.execute(alterQuery, {}, function(success)
          if success then
            callback(true)
          else
            print("Column `" .. columnName .. "` could not be added.")
            callback(false)
          end
        end)
      end
    else
      -- Column exists, check type and collation
      if expectedType then
        CheckAndUpdateColumnType(tableName, columnName, expectedType)
      end
      if expectedCollation then
        CheckAndUpdateColumnCollation(tableName, columnName, expectedCollation)
      end
      callback(false)
    end
  end

  if Config.SQL == "oxmysql" then
    exports.oxmysql:execute(showColumnQuery, {}, handleResult)
  elseif Config.SQL == "ghmattimysql" then
    exports.ghmattimysql:execute(showColumnQuery, {}, handleResult)
  elseif Config.SQL == "mysql-async" then
    MySQL.Async.fetchAll(showColumnQuery, {}, handleResult)
  end
end

-- Initialize Tables on Resource Start
Citizen.CreateThread(function()
  for tableName, createQuery in pairs(tableDefinitions) do
    local function handleTableCreation(success)
      if success then
        local columnDefs = tableColumnDefinitions[tableName]

        if columnDefs then
          local changesMade = false
          local processedCount = 0

          for _, columnDef in ipairs(columnDefs) do
            CheckAndAddColumn(tableName, columnDef, function(columnAdded)
              if columnAdded then
                changesMade = true
              end

              processedCount = processedCount + 1

              if processedCount == #columnDefs then
                if changesMade then
                  print("Table `" .. tableName .. "` changes were made to it.")
                end
              end
            end)
          end
        else
          print("Table `" .. tableName .. "` için alterTableQueries bulunamadı.")
        end
      else
        print("Table `" .. tableName .. "` oluşturulamadı.")
      end
    end

    if Config.SQL == "oxmysql" then
      exports.oxmysql:execute(createQuery, {}, handleTableCreation)
    elseif Config.SQL == "ghmattimysql" then
      exports.ghmattimysql:execute(createQuery, {}, handleTableCreation)
    elseif Config.SQL == "mysql-async" then
      MySQL.Async.execute(createQuery, {}, handleTableCreation)
    else
      print("No valid SQL configuration found.")
    end
  end
end)
