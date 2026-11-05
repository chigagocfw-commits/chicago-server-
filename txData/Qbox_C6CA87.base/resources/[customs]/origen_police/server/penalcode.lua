-- Penal Code System
local PenalCode = {}

-- Load penal code from database on startup
Citizen.CreateThread(function()
  -- Load chapters (cap = 0 means it's a chapter/category)
  local chapters = MySQL.awaitQuery("SELECT id, title, job FROM origen_police_penalc WHERE cap = 0")
  
  for i = 1, #chapters do
    local chapter = chapters[i]
    PenalCode[chapter.id] = {
      arts = {},
      title = chapter.title,
      id = chapter.id,
      job = chapter.job or "police"
    }
  end
  
  -- Load articles (cap != 0 means it's an article under a chapter)
  local articles = MySQL.awaitQuery("SELECT * FROM origen_police_penalc WHERE NOT cap = 0")
  
  for i = 1, #articles do
    local article = articles[i]
    
    if PenalCode[article.cap] then
      table.insert(PenalCode[article.cap].arts, {
        title = article.title,
        description = article.description,
        price = article.price,
        month = article.month,
        id = article.id,
        job = article.job or "police"
      })
    end
  end
end)

-- Get Penal Code Callback
FW_CreateCallback("origen_police:callback:GetPenalCode", function(source, cb)
  local player = FW_GetPlayer(source)
  
  if not player then
    return
  end
  
  -- Get player's job penal code
  local jobPenalCode = exports.origen_police:CanOpenTablet(player.PlayerData.job.name)[3]
  local filteredCode = {}
  
  -- Filter penal code by job
  for chapterId, chapterData in pairs(PenalCode) do
    if chapterData.job == jobPenalCode then
      filteredCode[chapterId] = chapterData
    end
  end
  
  cb(filteredCode)
end)

-- Update Penal Code Callback
FW_CreateCallback("origen_police:callback:UpdatePenalCode", function(source, cb, data)
  local player = FW_GetPlayer(source)
  
  if not player then
    return
  end
  
  local jobPenalCode = exports.origen_police:CanOpenTablet(player.PlayerData.job.name)[3]
  
  -- Allow all officers to manage criminal code
  -- Change to "if player.PlayerData.job.isboss then" to restrict to boss only
  if true then
    if data.type == "edit-art" then
      -- Edit an article
      local affectedRows = MySQL.awaitUpdate(
        "UPDATE origen_police_penalc SET title = ?, description = ?, price = ?, month = ? WHERE id = ?",
        {data.title, data.description, data.price, data.month, data.id}
      )
      
      -- Update in-memory cache
      for i = 1, #PenalCode[data.cap].arts do
        if PenalCode[data.cap].arts[i].id == data.id then
          PenalCode[data.cap].arts[i] = {
            title = data.title,
            description = data.description,
            price = data.price,
            month = data.month,
            id = data.id
          }
          break
        end
      end
      
      return cb(affectedRows > 0)
      
    elseif data.type == "new-art" then
      -- Create new article
      local insertId = MySQL.awaitInsert(
        "INSERT INTO origen_police_penalc (cap, title, description, price, month, job) VALUES (?, ?, ?, ?, ?, ?)",
        {data.cap, data.title, data.description, data.price, data.month, jobPenalCode}
      )
      
      -- Add to in-memory cache
      table.insert(PenalCode[data.cap].arts, {
        title = data.title,
        description = data.description,
        price = data.price,
        month = data.month,
        id = insertId,
        job = jobPenalCode
      })
      
      return cb(insertId)
      
    elseif data.type == "delete-art" then
      -- Delete an article
      local result = MySQL.awaitQuery(
        "DELETE FROM origen_police_penalc WHERE id = ?",
        {data.id}
      )
      
      -- Remove from in-memory cache
      for i = 1, #PenalCode[data.cap].arts do
        if PenalCode[data.cap].arts[i].id == data.id then
          table.remove(PenalCode[data.cap].arts, i)
          break
        end
      end
      
      return cb(result.affectedRows > 0)
      
    elseif data.type == "new-cap" then
      -- Create new chapter
      local insertId = MySQL.awaitInsert(
        "INSERT INTO origen_police_penalc (title, description, job) VALUES (?, ?, ?)",
        {data.title, "", jobPenalCode}
      )
      
      -- Add to in-memory cache
      PenalCode[insertId] = {
        arts = {},
        title = data.title,
        id = insertId,
        job = jobPenalCode
      }
      
      return cb(insertId)
      
    elseif data.type == "edit-cap" then
      -- Edit a chapter
      local affectedRows = MySQL.awaitUpdate(
        "UPDATE origen_police_penalc SET title = ? WHERE id = ?",
        {data.title, data.id}
      )
      
      -- Update in-memory cache
      PenalCode[data.id].title = data.title
      
      return cb(affectedRows > 0)
      
    elseif data.type == "delete-cap" then
      -- Delete chapter and all its articles
      MySQL.awaitQuery(
        "DELETE FROM origen_police_penalc WHERE id = ? or cap = ?",
        {data.id, data.id}
      )
      
      -- Remove from in-memory cache
      for chapterId, chapterData in pairs(PenalCode) do
        if chapterData.id == data.id then
          PenalCode[chapterId] = nil
        end
      end
      
      return cb(true)
    end
  end
  
  cb(false)
end)