Busy = false
local occupiedSpot = nil

function IsSpotOccupied(spotId)
    local occupied = lib.callback.await("lunar_contracts:isSpotOccupied", false, spotId)
    
    if not occupied then
        occupiedSpot = spotId
        Busy = true
        Editable.setInventoryBusy(true)
    else
        LR.notify(locale("spot_occupied"), "error")
    end
    
    return occupied
end

function FreeOccupiedSpot()
    if not occupiedSpot then return end
    
    TriggerServerEvent("lunar_contracts:freeOccupiedSpot", occupiedSpot)
    Editable.setInventoryBusy(false)
    Busy = false
    occupiedSpot = nil
end