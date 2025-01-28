Config = {}

-- Framework (can be 'ESX' or 'QB')
Config.Framework = 'ESX'

-- UI display time in milliseconds (global)
Config.DisplayTime = 20000 -- Adjust this value according to your needs

-- Job configuration, ranks, and texts for the UI
Config.Jobs = {
    ['police'] = {
        label = "Police Department",
        ranks = {1, 2, 3, 4, 5, 6, 7, 8, 9},
        openText = "There is POLICE available at the station",
        closeText = "There is NO POLICE available at the station"
    },
    ['ambulance'] = {
        label = "Los Santos Hospital",
        ranks = {1, 2, 3, 4, 5, 6, 7},
        openText = "EMS is available at the hospital",
        closeText = "No EMS is available at the hospital"
    },
    ['mechanic'] = {
        label = "Mechanic Shop",
        ranks = {4},
        openText = "The Mechanic Shop is OPEN",
        closeText = "The Mechanic Shop is CLOSED"
    },
    ['taxi'] = {
        label = "Taxi",
        ranks = {0, 1, 2, 3, 4},
        openText = "Taxis are available",
        closeText = "No taxis available"
    },
    ['realestate'] = {
        label = "Real Estate",
        ranks = {1, 2, 3, 4, 5},
        openText = "Real Estate is OPEN",
        closeText = "Real Estate is CLOSED"
    }
}

-- Configurable commands
Config.OpenCommand = 'open'
Config.CloseCommand = 'closed'

-- Cooldown time for commands (in seconds)
Config.CooldownTime = 300
