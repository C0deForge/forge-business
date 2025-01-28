--------------------------------------------------------------------------------
-- 1) FRAMEWORK INIT
--------------------------------------------------------------------------------
local Framework = nil

if Config.Framework == 'ESX' then
    ESX = exports['es_extended']:getSharedObject()
    Framework = ESX
elseif Config.Framework == 'QB' then
    QBCore = exports['qb-core']:GetCoreObject()
    Framework = QBCore
end

--------------------------------------------------------------------------------
-- 2) DUTY DETECTION & JOB UPDATE FOR QB ONLY
--------------------------------------------------------------------------------
if Config.Framework == 'QB' then
    local previousJob = nil
    
    -- Inicializar previousJob al cargar
    Citizen.CreateThread(function()
        while not Framework.PlayerData.job do
            Citizen.Wait(100)
        end
        previousJob = Framework.PlayerData.job
    end)

    -- Detección de cambios de servicio
    AddEventHandler('QBCore:Player:SetPlayerData', function(newData)
        local wasOnDuty = (Framework.PlayerData.job and Framework.PlayerData.job.onduty) or false
        local isOnDuty = (newData.job and newData.job.onduty) or false
        
        if isOnDuty ~= wasOnDuty then
            TriggerServerEvent('forge-business:onDutyChange', isOnDuty)
        end
    end)

    -- Manejo de cambios de trabajo
    RegisterNetEvent('QBCore:Client:OnJobUpdate')
    AddEventHandler('QBCore:Client:OnJobUpdate', function(newJob)
        local oldJob = previousJob
        previousJob = newJob  -- Actualizar para próxima vez
        TriggerServerEvent('forge-business:jobUpdate', oldJob, newJob)
    end)
end

--------------------------------------------------------------------------------
-- 3) NUI DISPLAY OF BUSINESS STATUS (OPEN/CLOSED)
--------------------------------------------------------------------------------
RegisterNetEvent('forge-business:openUI')
AddEventHandler('forge-business:openUI', function(businessLabel, businessText, status)
    Citizen.CreateThread(function()
        if not businessLabel or not businessText then return end
        
        SendNUIMessage({
            display = true,
            businessLabel = businessLabel,
            businessText = businessText,
            status = status,
            displayTime = Config.DisplayTime or 5000
        })

        print(string.format("^3[DEBUG]^7 UI Trigger - Label: %s, Status: %s", businessLabel, status))
    end)
end)

RegisterNUICallback('closeUI', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

--------------------------------------------------------------------------------
-- 4) UTILITY FUNCTION FOR NOTIFICATIONS
--------------------------------------------------------------------------------
local function ShowNotification(msg)
    if Config.Framework == 'ESX' then
        Framework.ShowNotification(msg)
    elseif Config.Framework == 'QB' then
        Framework.Functions.Notify(msg)
    end
end

--------------------------------------------------------------------------------
-- 5) STATISTICS MENU (ESX / QB)
--------------------------------------------------------------------------------
RegisterNetEvent('forge-business:openStatsMenu')
AddEventHandler('forge-business:openStatsMenu', function(elements)
    print("^3[DEBUG]^7 Elements received on client: " .. tostring(#elements))
    
    if Config.Framework == 'ESX' then
        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'business_stats', {
            title = '📊 Business Statistics',
            align = 'center',
            elements = elements
        }, function(data, menu)
            if data.current.value then
                ShowNotification('Selected: ' .. data.current.label)
            end
        end, function(data, menu)
            menu.close()
        end)

    elseif Config.Framework == 'QB' then
        local menuItems = {}
        for _, v in pairs(elements) do
            menuItems[#menuItems + 1] = {
                header = v.label,
                params = {
                    event = "forge-business:selectBusiness",
                    args = {business = v.value, label = v.label}
                }
            }
        end
        exports['qb-menu']:openMenu(menuItems)
    end
end)

RegisterNetEvent('forge-business:selectBusiness')
AddEventHandler('forge-business:selectBusiness', function(data)
    if data.business then
        ShowNotification('Selected: ' .. data.label)
    end
end)
