CreateThread(function()
    while GetResourceState('oxmysql') ~= 'started' do
        Wait(200)
    end
    Mechanic.EnsureSchema()
    Mechanic.LoadAll()
    local count = 0
    for _ in pairs(Mechanic.Shops) do count = count + 1 end
    print(('^2[%s]^0 Server ready — %d shop(s) in database'):format(Mechanic.ResourceName, count))
end)

exports('SendEngineSwapInvoice', function(customerSource, engineName, mechanicShopId, amount)
    local src = source
    if customerSource and engineName and Mechanic.CreateBill then
        Mechanic.CreateBill(src or 0, customerSource, amount or 0, ('Engine swap: %s'):format(engineName), mechanicShopId)
    end
end)
