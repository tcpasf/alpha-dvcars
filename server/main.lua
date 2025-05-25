local QBCore = exports['qb-core']:GetCoreObject()

local isSystemActive = Config.AutoStart
local currentInterval = Config.AutoDeleteInterval

CreateThread(function()
    if Config.AutoStart then
        Wait(5000)
        TriggerClientEvent('alpha-dvcars:client:systemStarted', -1, currentInterval)
    end
end)
