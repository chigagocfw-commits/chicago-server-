ATM = ATM or {}

ATM.State = ATM.State or {
    isUsingATM = false,
    currentATM = nil,
    currentATMVariant = nil,
    currentATMDUI = nil,
    currentCardObject = nil,
    currentCardData = nil,
    currentStage = nil,
}

ATM.Controls = {
    DISABLED_WHEN_USING = {
        24, 257, 263, 264, 69, 92, 114, 331, 21, 22,
        36, 23, 75, 47, 157, 158, 160, 164, 165,
    }
}

function ATM:setUsageState(isUsing)
    self.State.isUsingATM = isUsing
end

function ATM:isUsing()
    return self.State.isUsingATM
end

function ATM:setCurrentATM(entity)
    self.State.currentATM = entity
end

function ATM:getCurrentATM()
    return self.State.currentATM
end

function ATM:setCurrentCardData(cardData)
    self.State.currentCardData = cardData
end

function ATM:getCurrentCardData()
    return self.State.currentCardData
end

function ATM:setCurrentCardObject(entity)
    self.State.currentCardObject = entity
end

function ATM:getCurrentCardObject()
    return self.State.currentCardObject
end

function ATM:clearCardObject()
    local cardObject = self.State.currentCardObject

    if cardObject and DoesEntityExist(cardObject) then
        DeleteEntity(cardObject)
    end

    self.State.currentCardObject = nil
end

function ATM:setCurrentDUI(dui)
    self.State.currentATMDUI = dui
end

function ATM:getCurrentDUI()
    return self.State.currentATMDUI
end

function ATM:setCurrentVariant(variant)
    self.State.currentATMVariant = variant
end

function ATM:getCurrentVariant()
    return self.State.currentATMVariant
end

function ATM:setCurrentStage(stage)
    self.State.currentStage = stage
end

function ATM:getCurrentStage()
    return self.State.currentStage
end

function ATM:reset()
    self.State.isUsingATM = false
    self.State.currentATM = nil
    self.State.currentATMVariant = nil
    self.State.currentATMDUI = nil
    self.State.currentCardData = nil
    self.State.currentStage = nil
    self:clearCardObject()
end
