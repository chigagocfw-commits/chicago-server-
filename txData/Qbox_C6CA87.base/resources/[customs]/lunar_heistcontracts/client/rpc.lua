Utils.entityStateHandler("contracts:heading", function(entity, heading)
    if GetEntityHeading(entity) ~= heading then
        SetEntityHeading(entity, heading + 0.0)
        FreezeEntityPosition(entity, true)
    end
end)