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
-- 2) LOCAL / GLOBAL VARIABLES
--------------------------------------------------------------------------------
local activeBusinesses = {}
local businessStats = {}
local lastCommandUsage = {}
local discord_webhook = 'YOUR_WEBHOOK_HERE'

-- Business states (if you need them in the future)
local BUSINESS_STATES = {
    CLOSED   = 0,
    OPEN     = 1,
    REOPENED = 2
}

--------------------------------------------------------------------------------
-- 3) HELPER FUNCTIONS
--------------------------------------------------------------------------------

-- Format a given number of seconds into d/h/m
local function FormatTime(seconds)
    local days    = math.floor(seconds / 86400)
    local hours   = math.floor((seconds % 86400) / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    
    if days > 0 then
        return string.format("%dd %dh %dm", days, hours, minutes)
    elseif hours > 0 then
        return string.format("%dh %dm", hours, minutes)
    else
        return string.format("%dm", minutes)
    end
end

-- Send an embed to your Discord webhook
local function SendBusinessLog(title, description, color, extraData)
    if not discord_webhook or discord_webhook == '' then return end

    local embed = {
        {
            ["title"]       = title,
            ["description"] = description,
            ["color"]       = color,
            ["fields"]      = extraData or {},
            ["footer"]      = {["text"] = "Forge Business Logs"},
            ["timestamp"]   = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }
    }
    
    PerformHttpRequest(discord_webhook, function(err, text, headers) end,
        'POST', json.encode({embeds = embed}), { ['Content-Type'] = 'application/json' }
    )
end

-- Fetch player from source (ESX or QBCore)
local function GetPlayer(source)
    if Config.Framework == 'ESX' then
        return ESX.GetPlayerFromId(source)
    elseif Config.Framework == 'QB' then
        return QBCore.Functions.GetPlayer(source)
    end
end

-- Return the player's job data
local function GetPlayerJob(player)
    if Config.Framework == 'ESX' then
        -- For ESX, job is typically { name="police", grade=2, label="Police" }
        return player.getJob()
    elseif Config.Framework == 'QB' then
        -- For QBCore, job might be { name="police", label="Police", onduty=true, grade={ name="officer", level=2 } }
        return player.PlayerData.job
    end
end

-- Count how many players have a specific job name
local function getActiveEmployeesCount(jobName)
    local count = 0

    if Config.Framework == 'ESX' then
        local players = ESX.GetPlayers()
        for _, playerId in ipairs(players) do
            local xPlayer = ESX.GetPlayerFromId(playerId)
            if xPlayer and xPlayer.getJob().name == jobName then
                count = count + 1
            end
        end

    elseif Config.Framework == 'QB' then
        local players = QBCore.Functions.GetQBPlayers()
        for _, player in pairs(players) do
            local job = player.PlayerData.job
            if job and job.name == jobName and job.onduty then
                count = count + 1
            end
        end
    end

    return count
end

-- Send a notification to the player (ESX or QBCore)
local function ShowNotification(source, msg)
    if Config.Framework == 'ESX' then
        TriggerClientEvent('esx:showNotification', source, msg)
    elseif Config.Framework == 'QB' then
        TriggerClientEvent('QBCore:Notify', source, msg)
    end
end

-- Check if a table contains a certain value
local function contains(tbl, val)
    for i = 1, #tbl do
        if tbl[i] == val then
            return true
        end
    end
    return false
end

--------------------------------------------------------------------------------
-- 4) CORE BUSINESS LOGIC
--------------------------------------------------------------------------------

-- Close a business if conditions are met
local function CloseBusiness(job, source, reason)
    if not activeBusinesses[job] then return end

    -- If closure isn't manual, verify if other employees remain
    if reason ~= "manual" then
        local activeEmployees = getActiveEmployeesCount(job)
        if activeEmployees > 1 then
            -- Another employee is still on the same job, so do not close
            SendBusinessLog("ℹ️ Automatic Closure Attempt Canceled",
                string.format([[
**Business:** %s
**Employee:** %s
**Active employees:** %d
**Reason canceled:** %s]],
                    activeBusinesses[job].label,
                    GetPlayerName(source),
                    activeEmployees,
                    reason
                ),
                16776960
            )
            return false
        end
    end

    -- Proceed with closure
    local timeOpen = os.time() - activeBusinesses[job].openTime
    if not businessStats[job] then
        businessStats[job] = { totalTime = 0, openCount = 0 }
    end
    businessStats[job].totalTime = businessStats[job].totalTime + timeOpen

    local title, color
    if reason == "disconnect" then
        title = "⚠️ Closure due to Disconnection"
        color = 16776960
    elseif reason == "jobchange" then
        title = "⚠️ Closure due to Job Change"
        color = 16776960
    elseif reason == "dutychange" then
        title = "⚠️ Closure due to Duty Change"
        color = 16776960
    else
        title = "🔴 Business Closure"
        color = 15158332
    end

    -- Log to Discord
    SendBusinessLog(
        title,
        string.format([[
**Business:** %s
**Closed by:** %s
**Time open:** %s
**Reason:** %s]],
            activeBusinesses[job].label,
            GetPlayerName(source),
            FormatTime(timeOpen),
            reason
        ),
        color
    )

    -- Notify all players with the "closed" UI
    if Config.Jobs[job] then
        Citizen.Wait(100) -- small sync delay
        TriggerClientEvent('forge-business:openUI', -1, Config.Jobs[job].label, Config.Jobs[job].closeText, 'closed')
    end

    -- Cleanup
    activeBusinesses[job] = nil
    SaveResourceFile(GetCurrentResourceName(), 'business_stats.json', json.encode(businessStats), -1)
    
    return true
end

--------------------------------------------------------------------------------
-- 5) LOAD SAVED BUSINESS STATISTICS
--------------------------------------------------------------------------------
local statsFile = LoadResourceFile(GetCurrentResourceName(), 'business_stats.json')
if statsFile then
    businessStats = json.decode(statsFile) or {}
end

--------------------------------------------------------------------------------
-- 6) HANDLE JOB CHANGES
--------------------------------------------------------------------------------
local function HandleJobChange(source, newJob, oldJob)
    if oldJob and activeBusinesses[oldJob.name] then
        Citizen.Wait(1000)
        local activeEmployees = getActiveEmployeesCount(oldJob.name)
        if activeEmployees <= 0 then
            CloseBusiness(oldJob.name, source, "jobchange")
        end
    end
end

-- ESX job change event
if Config.Framework == 'ESX' then
    RegisterServerEvent('esx:setJob')
    AddEventHandler('esx:setJob', function(playerSource, newJob, oldJob)
        local source = source
        HandleJobChange(playerSource, newJob, oldJob)
    end)

-- QBCore job change event
elseif Config.Framework == 'QB' then

    --------------------------------------------------------------------------------
    -- IMPORTANT: QBCore usually triggers "QBCore:Client:OnJobUpdate" on the client.
    --            We forward that to the server with "forge-business:jobUpdate" so
    --            we can call HandleJobChange() here. 
    --------------------------------------------------------------------------------
    RegisterNetEvent('forge-business:jobUpdate')
    AddEventHandler('forge-business:jobUpdate', function(oldJob, newJob)
        local src = source
        HandleJobChange(src, newJob, oldJob)
    end)
end

--------------------------------------------------------------------------------
-- 7) /open and /close COMMANDS
--------------------------------------------------------------------------------

RegisterCommand(Config.OpenCommand, function(source)
    local xPlayer = GetPlayer(source)
    if not xPlayer then return end

    local jobInfo = GetPlayerJob(xPlayer)
    if not jobInfo then return end

    local job = jobInfo.name
    local grade = jobInfo.grade

    -- For QBCore, if grade is a table, we read grade.level
    if Config.Framework == 'QB' and type(grade) == 'table' then
        grade = grade.level or 0
    end

    -- For QBCore, check if the player is on duty
    if Config.Framework == 'QB' and not jobInfo.onduty then
        ShowNotification(source, "You must be on duty to open this business.")
        return
    end

    -- Check if this job is configured, and if the player's grade is allowed
    if not Config.Jobs[job] or not contains(Config.Jobs[job].ranks, grade) then
        ShowNotification(source, "You don't have permissions for this business.")
        return
    end

    -- Command cooldown
    local currentTime = os.time()
    local lastUsed = lastCommandUsage[source] or 0
    if currentTime - lastUsed < Config.CooldownTime then
        local timeLeft = Config.CooldownTime - (currentTime - lastUsed)
        ShowNotification(source, "Please wait " .. timeLeft .. " seconds.")
        return
    end

    local businessLabel = Config.Jobs[job].label
    local openText = Config.Jobs[job].openText

    -- If already open, just log a reminder
    if activeBusinesses[job] then
        SendBusinessLog("🔄 Already Open Business Reminder",
            string.format([[**Business:** %s
**Employee:** %s
**Current time open:** %s
**Opened by:** %s]],
                businessLabel,
                GetPlayerName(source),
                FormatTime(os.time() - activeBusinesses[job].openTime),
                activeBusinesses[job].ownerName
            ),
            16776960
        )
    else
        -- Mark the business as open
        activeBusinesses[job] = {
            label = businessLabel,
            openTime = currentTime,
            owner = source,
            ownerName = GetPlayerName(source)
        }

        if not businessStats[job] then
            businessStats[job] = { totalTime = 0, openCount = 0 }
        end
        businessStats[job].openCount = (businessStats[job].openCount or 0) + 1

        SendBusinessLog("🟢 New Opening Process",
            string.format([[**Business:** %s
**Employee:** %s
**Active employees:** %d]],
                businessLabel,
                GetPlayerName(source),
                getActiveEmployeesCount(job)
            ),
            3066993
        )
    end

    -- Show the "open" UI to everyone
    TriggerClientEvent('forge-business:openUI', -1, businessLabel, openText, 'open')

    -- Update command usage time
    lastCommandUsage[source] = currentTime
end)

-- Force close the business ignoring active employees
RegisterCommand(Config.CloseCommand, function(source)
    local xPlayer = GetPlayer(source)
    if not xPlayer then return end

    local jobInfo = GetPlayerJob(xPlayer)
    local job = jobInfo and jobInfo.name or nil

    if not job or not activeBusinesses[job] then
        ShowNotification(source, "The business is not open.")
        return
    end

    CloseBusiness(job, source, "manual")
end)

--------------------------------------------------------------------------------
-- 8) HANDLE PLAYER DISCONNECT
--------------------------------------------------------------------------------
AddEventHandler('playerDropped', function()
    local droppedSource = source
    local xPlayer = GetPlayer(droppedSource)
    local job = xPlayer and GetPlayerJob(xPlayer).name or nil
    
    Citizen.Wait(1000) -- let the framework remove the player
    if job and activeBusinesses[job] then
        local activeEmployees = getActiveEmployeesCount(job)
        if activeEmployees <= 0 then
            CloseBusiness(job, droppedSource, "disconnect")
        end
    end
end)

--------------------------------------------------------------------------------
-- 9) ADMIN COMMAND: /businesses
--------------------------------------------------------------------------------
RegisterCommand('businesses', function(source)
    local xPlayer = GetPlayer(source)
    if not xPlayer then return end

    local isAdmin = false

    if Config.Framework == 'ESX' then
        -- ESX admin check
        if xPlayer.getGroup and xPlayer.getGroup() == 'admin' then
            isAdmin = true
        end
    elseif Config.Framework == 'QB' then
        -- QBCore admin check (edit if you have a custom permission system)
        if QBCore.Functions.HasPermission(xPlayer.PlayerData.source, "admin") then
            isAdmin = true
        end
    end

    if isAdmin then
        local elements = {}
        
        for job, stats in pairs(businessStats) do
            if Config.Jobs[job] then
                table.insert(elements, {
                    label = string.format("%s - Openings: %d | Time: %s",
                        Config.Jobs[job].label,
                        stats.openCount or 0,
                        FormatTime(stats.totalTime or 0)
                    ),
                    value = job
                })
            end
        end

        if #elements == 0 then
            table.insert(elements, {
                label = "No statistics available",
                value = nil
            })
        end

        -- Unify the logic for both frameworks: your client handles it
        TriggerClientEvent('forge-business:openStatsMenu', source, elements)
    else
        ShowNotification(source, "You don't have permission to use this command.")
    end
end)

--------------------------------------------------------------------------------
-- 10) CLOSE BUSINESS WHEN OFF-DUTY (QB ONLY)
--------------------------------------------------------------------------------
-- This event is triggered if your client script detects a duty change
-- and calls "forge-business:onDutyChange". It has no effect on ESX.
if Config.Framework == 'QB' then
    RegisterNetEvent('forge-business:onDutyChange')
    AddEventHandler('forge-business:onDutyChange', function(isOnDuty)
        local src = source
        local player = QBCore.Functions.GetPlayer(src)
        if not player or isOnDuty then return end  -- Solo actuar al salir de servicio

        local jobName = player.PlayerData.job.name
        if activeBusinesses[jobName] then
            local activeEmployees = getActiveEmployeesCount(jobName)
            if activeEmployees <= 1 then  -- Incluyendo al propio jugador
                CloseBusiness(jobName, src, "dutychange")
            end
        end
    end)
end
