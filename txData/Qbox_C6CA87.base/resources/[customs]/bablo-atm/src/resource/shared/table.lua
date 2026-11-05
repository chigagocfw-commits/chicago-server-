function table.merge(target, source)
    if type(target) ~= "table" or type(source) ~= "table" then
        return target
    end

    for key, value in pairs(source) do
        if type(value) == "table" and type(target[key]) == "table" then
            table.merge(target[key], value)
        else
            target[key] = value
        end
    end

    return target
end
