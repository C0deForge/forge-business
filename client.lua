-- Event to open the UI with business data
RegisterNetEvent('forge-business:openUI')
AddEventHandler('forge-business:openUI', function(businessLabel, businessText, status)
    SendNUIMessage({
        display = true,
        businessLabel = businessLabel,
        businessText = businessText,
        status = status,
        displayTime = Config.DisplayTime or 5000 -- Use the config value or 5000ms by default
    })
end)

-- Close the UI from the NUI (optional)
RegisterNUICallback('closeUI', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)