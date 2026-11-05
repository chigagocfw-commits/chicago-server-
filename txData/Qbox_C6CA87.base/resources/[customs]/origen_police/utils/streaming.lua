function LoadModel(modelHash, timeout)
    RequestModel(modelHash)
    
    local startTime = GetGameTimer()
    
    while not HasModelLoaded(modelHash) do
        local currentTime = GetGameTimer()
        
        -- Check if timeout exceeded
        if (currentTime - startTime) > timeout then
            return false
        end
        
        Wait(0)
    end
    
    return true
end