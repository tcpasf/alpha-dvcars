local QBCore = exports['qb-core']:GetCoreObject()

local isUIVisible = false -- Changed from Config.ShowUI to false by default
local isSystemActive = Config.AutoStart
local currentInterval = Config.AutoDeleteInterval
local timeRemaining = 0
local countdownTimer = nil

local function IsVehicleOccupied(vehicle)
    -- Check all possible seats in the vehicle
    for i = -1, GetVehicleMaxNumberOfPassengers(vehicle) - 1 do
        if GetPedInVehicleSeat(vehicle, i) ~= 0 then
            return true
        end
    end
    
    -- Check if any player is on the vehicle (like motorcycles, bicycles, etc.)
    local players = GetActivePlayers()
    for _, player in ipairs(players) do
        local ped = GetPlayerPed(player)
        if DoesEntityExist(ped) then
            -- Check if the ped is in this vehicle
            local pedVehicle = GetVehiclePedIsIn(ped, false)
            if pedVehicle == vehicle then
                return true
            end
            
            -- Check if the ped is on top of this vehicle
            if IsPedOnVehicle(ped) then
                local pedCoords = GetEntityCoords(ped)
                local vehCoords = GetEntityCoords(vehicle)
                local distance = #(pedCoords - vehCoords)
                
                -- If player is very close to this vehicle and is on something, assume it's this vehicle
                if distance < 2.5 then
                    return true
                end
            end
        end
    end
    
    return false
end

local function ShouldExcludeVehicle(vehicle)
    -- Check if any player is in or on this vehicle
    if IsVehicleOccupied(vehicle) then
        return true
    end
    
    -- Additional check for motorcycles and other vehicles where players might be on
    local players = GetActivePlayers()
    for _, player in ipairs(players) do
        local ped = GetPlayerPed(player)
        if DoesEntityExist(ped) then
            -- Check if the player is on this vehicle
            if IsPedOnVehicle(ped) then
                local entityAttachedTo = GetEntityAttachedTo(ped)
                if entityAttachedTo == vehicle then
                    return true
                end
            end
        end
    end
    
    -- Check if this is the player's current vehicle (even if temporarily exited)
    if Config.ProtectPlayerCurrentVehicle then
        local playerPed = PlayerPedId()
        local playerVeh = GetVehiclePedIsIn(playerPed, false) -- false = current vehicle
        local lastVeh = GetVehiclePedIsIn(playerPed, true) -- true = last vehicle
        
        if vehicle == playerVeh or vehicle == lastVeh then
            return true
        end
        
        -- Check if player is on top of this vehicle
        if IsPedOnVehicle(playerPed) then
            local pedCoords = GetEntityCoords(playerPed)
            local vehCoords = GetEntityCoords(vehicle)
            local distance = #(pedCoords - vehCoords)
            
            -- If player is very close to this vehicle and is on something, assume it's this vehicle
            if distance < 2.5 then
                return true
            end
        end
    end
    
    -- Check for emergency vehicles
    if Config.ExcludeEmergencyVehicles then
        local vehicleClass = GetVehicleClass(vehicle)
        if Config.EmergencyClasses[vehicleClass] then
            return true
        end
    end

    -- Check for player-owned vehicles by plate
    if Config.ExcludePlayerVehicles then
        local plate = GetVehicleNumberPlateText(vehicle)
        if plate and string.len(string.gsub(plate, "%s+", "")) > 0 then
            return true
        end
    end

    return false
end

local function DeleteUnoccupiedVehicles()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local deletedCount = 0
    local totalVehicles = 0
    local excludedVehicles = {}
    
    -- Mark player vehicles to exclude if configured
    if Config.ProtectPlayerCurrentVehicle then
        local playerVehicle = GetVehiclePedIsIn(playerPed, false)
        local lastVehicle = GetVehiclePedIsIn(playerPed, true)
        
        if playerVehicle and DoesEntityExist(playerVehicle) then
            excludedVehicles[playerVehicle] = true
        end
        
        if lastVehicle and DoesEntityExist(lastVehicle) and lastVehicle ~= playerVehicle then
            excludedVehicles[lastVehicle] = true
        end
    end
    
    -- Check for all players' vehicles
    local players = GetActivePlayers()
    for _, player in ipairs(players) do
        local ped = GetPlayerPed(player)
        if DoesEntityExist(ped) then
            -- Check vehicles player is in
            local playerVeh = GetVehiclePedIsIn(ped, false)
            if playerVeh and DoesEntityExist(playerVeh) then
                excludedVehicles[playerVeh] = true
            end
            
            -- Check if player is standing on a vehicle
            if IsPedOnVehicle(ped) then
                -- Get all vehicles in the area to check which one the player might be on
                local vehicles = GetGamePool('CVehicle')
                for _, veh in pairs(vehicles) do
                    if DoesEntityExist(veh) then
                        local pedCoords = GetEntityCoords(ped)
                        local vehCoords = GetEntityCoords(veh)
                        local distance = #(pedCoords - vehCoords)
                        
                        -- If player is very close to a vehicle and is on something, assume it's this vehicle
                        if distance < 2.5 and IsPedOnVehicle(ped) then
                            excludedVehicles[veh] = true
                        end
                    end
                end
            end
        end
    end

    local vehicles = GetGamePool('CVehicle')

    for _, vehicle in pairs(vehicles) do
        if DoesEntityExist(vehicle) then
            totalVehicles = totalVehicles + 1
            
            -- Skip explicitly excluded vehicles
            if not excludedVehicles[vehicle] then
                local vehicleCoords = GetEntityCoords(vehicle)
                local distance = #(playerCoords - vehicleCoords)

                if distance <= Config.DeleteRadius then
                    -- Final safety check - make sure no player is in or on this vehicle
                    local canDelete = true
                    
                    -- Check if any player is in or on this vehicle one last time
                    if IsVehicleOccupied(vehicle) then
                        canDelete = false
                    end
                    
                    -- Check all players to see if they're on this vehicle
                    if canDelete then
                        for _, player in ipairs(players) do
                            local ped = GetPlayerPed(player)
                            if DoesEntityExist(ped) then
                                local pedVeh = GetVehiclePedIsIn(ped, false)
                                
                                -- Check if player is in this vehicle
                                if pedVeh == vehicle then
                                    canDelete = false
                                    break
                                end
                                
                                -- Check if player is on top of this vehicle using distance
                                if IsPedOnVehicle(ped) then
                                    local pedCoords = GetEntityCoords(ped)
                                    local vehCoords = GetEntityCoords(vehicle)
                                    local distance = #(pedCoords - vehCoords)
                                    
                                    -- If player is very close to this vehicle and is on something, assume it's this vehicle
                                    if distance < 2.5 then
                                        canDelete = false
                                        break
                                    end
                                end
                            end
                        end
                    end
                    
                    -- Final check with ShouldExcludeVehicle
                    if canDelete and not ShouldExcludeVehicle(vehicle) then
                        SetEntityAsMissionEntity(vehicle, true, true)
                        DeleteVehicle(vehicle)
                        deletedCount = deletedCount + 1
                    end
                end
            end
        end
    end

    -- Show UI temporarily when vehicles are deleted
    SendNUIMessage({
        type = 'temporaryShow',
        active = isSystemActive,
        interval = currentInterval,
        timeRemaining = timeRemaining,
        duration = 10000 -- Show for 10 seconds
    })

    -- Single Arabic notification
    if deletedCount > 0 then
        QBCore.Functions.Notify('تم حذف ' .. deletedCount .. ' مركبة غير مستخدمة', 'success')
    else
        QBCore.Functions.Notify('لا توجد مركبات للحذف', 'primary')
    end

    print('[Alpha-DVCars] Cleanup completed: ' .. deletedCount .. '/' .. totalVehicles .. ' vehicles deleted')
end

local function StartCountdown(initialTime)
    if countdownTimer then
        countdownTimer = false
        Wait(100)
    end

    timeRemaining = initialTime or (currentInterval * 60)
    countdownTimer = true

    CreateThread(function()
        while countdownTimer do
            -- Always send countdown updates regardless of UI visibility
            -- The UI will decide when to show itself based on the time
            SendNUIMessage({
                type = 'updateCountdown',
                time = timeRemaining
            })

            Wait(1000)

            if timeRemaining > 0 then
                timeRemaining = timeRemaining - 1
                
                -- Hide UI when time is not in the last 30 seconds and not 0
                if timeRemaining > 30 and timeRemaining < (currentInterval * 60 - 5) then
                    SendNUIMessage({
                        type = 'hideUI'
                    })
                end
            else
                if isSystemActive then
                    -- Show UI when cleanup is happening
                    SendNUIMessage({
                        type = 'temporaryShow',
                        active = isSystemActive,
                        interval = currentInterval,
                        timeRemaining = 0,
                        duration = 10000 -- Show for 10 seconds during cleanup
                    })
                    
                    if Config.UseDvallCommand then
                        print('[Alpha-DVCars] Timer ended - Executing /dvall command')
                        ExecuteCommand('dvall')
                        QBCore.Functions.Notify('جاري تنظيف المركبات...', 'primary') -- Arabic notification

                        if Config.FallbackToBuiltIn then
                            CreateThread(function()
                                Wait(3000)
                                local vehicleCount = #GetGamePool('CVehicle')
                                if vehicleCount > 50 then
                                    print('[Alpha-DVCars] /dvall may not have worked, using fallback deletion')
                                    DeleteUnoccupiedVehicles()
                                end
                            end)
                        end
                    else
                        print('[Alpha-DVCars] Timer ended - Using built-in vehicle deletion')
                        DeleteUnoccupiedVehicles()
                    end

                    Wait(2000)
                end
                timeRemaining = currentInterval * 60
            end
        end
    end)
end

local function InitializeUI()
    -- Initialize UI data but don't show it by default
    SendNUIMessage({
        type = 'showUI',
        active = isSystemActive,
        interval = currentInterval,
        timeRemaining = timeRemaining
    })
end

RegisterNetEvent('alpha-dvcars:client:systemStarted', function(interval)
    currentInterval = interval
    isSystemActive = true
    StartCountdown()
    InitializeUI()
end)

RegisterNetEvent('alpha-dvcars:client:performDeletion', function()
    DeleteUnoccupiedVehicles()
end)

RegisterNetEvent('alpha-dvcars:client:updateCountdown', function(time)
    StartCountdown(time)
end)

CreateThread(function()
    Wait(2000)
    -- Initialize UI data but don't show it
    InitializeUI()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if countdownTimer then
            countdownTimer = false
        end
    end
end)
