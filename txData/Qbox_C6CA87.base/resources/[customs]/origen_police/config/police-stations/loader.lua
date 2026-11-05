-- Parse a table into a vector4
function ParseVector4(coords)
  return vector4(coords[1], coords[2], coords[3], coords[4])
end

-- Check if a vector is at zero coordinates
function IsVecZero(vec)
  return vec.x == 0
end

-- Parse coordinates from configuration data
function ParseCoords(data)
  local result = {}
  
  for key, value in pairs(data) do
    if key ~= "Options" then
      for markerKey, markerData in pairs(value) do
        -- Parse marker coordinates
        if markerData.coords then
          markerData.coords = ParseVector4(markerData.coords)
          
          -- Warn if marker is at world origin (0,0,0)
          if IsVecZero(markerData.coords) then
            print("^3WARNING: YOU HAVE A MARKER WITH COORDS IN THE WORLD COORDS; YOU SHOULD REMOVE IT TO AVOID ISSUES WITH HELP NOTIFICATIONS^0")
          end
        end
        
        -- Parse spawn coordinates
        if markerData.spawn then
          markerData.spawn = ParseVector4(markerData.spawn)
        end
      end
    end
    result[key] = value
  end
  
  return result
end

-- Load markers data from a JSON file
function LoadMarkersData(mapName)
  local filePath = "config/police-stations/" .. mapName .. ".json"
  local fileContent = LoadResourceFile(GetCurrentResourceName(), filePath)
  
  if not fileContent then
    Debuger("The map " .. mapName .. " does not exist, loading default gta map.^0")
    return
  end
  
  return ParseCoords(json.decode(fileContent))
end

-- Export the LoadMarkers function
exports("LoadMarkers", LoadMarkersData)