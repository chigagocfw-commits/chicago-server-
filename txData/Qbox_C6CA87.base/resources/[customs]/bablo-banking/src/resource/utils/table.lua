tbl = {}

function tbl.deepEqual(left, right)
  if type(left) ~= "table" or type(right) ~= "table" then
    return false
  end

  for key, value in pairs(left) do
    if type(value) == "table" then
      if not tbl.deepEqual(value, right[key]) then
        return false
      end
    elseif value ~= right[key] then
      return false
    end
  end

  for key in pairs(right) do
    if left[key] == nil then
      return false
    end
  end

  return true
end

function tbl.getKeyByValue(list, value)
  for key, entry in pairs(list) do
    if entry:lower() == value then
      return key
    end
  end

  return nil
end

function tbl.find(list, predicate)
  for index, value in ipairs(list) do
    if predicate(value, index) then
      return value, index
    end
  end

  return nil, nil
end

function tbl.filter(list, predicate)
  local filtered = {}

  for index, value in ipairs(list) do
    if predicate(value, index) then
      table.insert(filtered, value)
    end
  end

  return filtered
end

function tbl.map(list, mapper)
  local mapped = {}

  for index, value in ipairs(list) do
    mapped[index] = mapper(value, index)
  end

  return mapped
end

function tbl.reduce(list, reducer, initialValue)
  local result = initialValue

  for index, value in ipairs(list) do
    result = reducer(result, value, index)
  end

  return result
end

function tbl.sort(list, comparator)
  table.sort(list, comparator)
  return list
end
