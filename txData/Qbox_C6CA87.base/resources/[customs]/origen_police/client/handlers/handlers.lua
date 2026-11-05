-- Vehicle Sit Handler
VehicleSitHandler = {
    name = "vehicle_sit",
    lastVehicle = nil,
    
    check = function(self)
        local playerPed = PlayerPedId()
        local currentVehicle = GetVehiclePedIsIn(playerPed, false)
        local vehicle = nil
        
        if currentVehicle ~= 0 then
            vehicle = currentVehicle
        end
        
        local previousVehicle = self.lastVehicle
        self.lastVehicle = vehicle
        
        return vehicle, previousVehicle
    end
}