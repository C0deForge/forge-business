local ESX = nil
local QBCore = nil

-- Detect the framework
if GetResourceState('es_extended') == 'started' then
    ESX = exports['es_extended']:getSharedObject()
elseif GetResourceState('qb-core') == 'started' then
    QBCore = exports['qb-core']:GetCoreObject()
end

-- Table to store the last command usage for each player
local lastCommandUsage = {}

-- Helper function to check if a value exists in a table
local function contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

-- Command to open the business
RegisterCommand(Config.OpenCommand, function(source)
    if not ESX and not QBCore then
        print("Error: No framework is initialized")
        return
    end

    local xPlayer = nil
    if ESX then
        xPlayer = ESX.GetPlayerFromId(source)
    elseif QBCore then
        xPlayer = QBCore.Functions.GetPlayer(source)
    end

    if xPlayer then
        local job = nil
        local grade = nil
        
        if ESX then
            job = xPlayer.getJob().name
            grade = xPlayer.getJob().grade
        elseif QBCore then
            job = xPlayer.PlayerData.job.name
            grade = xPlayer.PlayerData.job.grade.level
        end

        -- Check cooldown
        local currentTime = os.time()
        local lastUsage = lastCommandUsage[source] or 0
        local cooldownTime = Config.CooldownTime

        if currentTime - lastUsage < cooldownTime then
            local timeLeft = cooldownTime - (currentTime - lastUsage)
            if ESX then
                xPlayer.showNotification("You must wait " .. timeLeft .. " seconds before using this command again.")
            elseif QBCore then
                TriggerClientEvent('QBCore:Notify', source, "You must wait " .. timeLeft .. " seconds before using this command again.", 'error')
            end
            return
        end

        -- Check if the job and grade are in the config
        if Config.Jobs[job] and contains(Config.Jobs[job].ranks, grade) then
            local businessLabel = Config.Jobs[job].label
            local openText = Config.Jobs[job].openText

            -- Update last usage time
            lastCommandUsage[source] = currentTime

            -- Send the event to all clients to show the UI with the "open" status
            TriggerClientEvent('forge-business:openUI', -1, businessLabel, openText, 'open')
            
            if ESX then
                xPlayer.showNotification("Business status set to OPEN")
            elseif QBCore then
                TriggerClientEvent('QBCore:Notify', source, "Business status set to OPEN", 'success')
            end
        else
            if ESX then
                xPlayer.showNotification("You don't have permission to use this command")
            elseif QBCore then
                TriggerClientEvent('QBCore:Notify', source, "You don't have permission to use this command", 'error')
            end
        end
    end
end)

-- Command to close the business
RegisterCommand(Config.CloseCommand, function(source)
    if not ESX and not QBCore then
        print("Error: No framework is initialized")
        return
    end

    local xPlayer = nil
    if ESX then
        xPlayer = ESX.GetPlayerFromId(source)
    elseif QBCore then
        xPlayer = QBCore.Functions.GetPlayer(source)
    end

    if xPlayer then
        local job = nil
        local grade = nil
        
        if ESX then
            job = xPlayer.getJob().name
            grade = xPlayer.getJob().grade
        elseif QBCore then
            job = xPlayer.PlayerData.job.name
            grade = xPlayer.PlayerData.job.grade.level
        end

        -- Check cooldown
        local currentTime = os.time()
        local lastUsage = lastCommandUsage[source] or 0
        local cooldownTime = Config.CooldownTime

        if currentTime - lastUsage < cooldownTime then
            local timeLeft = cooldownTime - (currentTime - lastUsage)
            if ESX then
                xPlayer.showNotification("You must wait " .. timeLeft .. " seconds before using this command again.")
            elseif QBCore then
                TriggerClientEvent('QBCore:Notify', source, "You must wait " .. timeLeft .. " seconds before using this command again.", 'error')
            end
            return
        end

        -- Check if the job and grade are in the config
        if Config.Jobs[job] and contains(Config.Jobs[job].ranks, grade) then
            local businessLabel = Config.Jobs[job].label
            local closeText = Config.Jobs[job].closeText

            -- Update last usage time
            lastCommandUsage[source] = currentTime

            -- Send the event to all clients to show the UI with the "close" status
            TriggerClientEvent('forge-business:openUI', -1, businessLabel, closeText, 'close')
            
            if ESX then
                xPlayer.showNotification("Business status set to CLOSED")
            elseif QBCore then
                TriggerClientEvent('QBCore:Notify', source, "Business status set to CLOSED", 'success')
            end
        else
            if ESX then
                xPlayer.showNotification("You don't have permission to use this command")
            elseif QBCore then
                TriggerClientEvent('QBCore:Notify', source, "You don't have permission to use this command", 'error')
            end
        end
    end
end)