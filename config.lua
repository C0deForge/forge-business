Config = {}

-- Job configuration, ranks, and texts for the UI
Config.Jobs = {
    ['police'] = {
        label = "Police Department",
        ranks = {1, 2, 3, 4, 5, 6, 7, 8, 9},
        openText = "There is POLICE available at the Station",
        closeText = "There is NO POLICE available at the Station"
    },
    ['mechanic'] = {
        label = "Mechanic Workshop",
        ranks = {4},
        openText = "The Mechanic Workshop is OPEN",
        closeText = "The Mechanic Workshop is CLOSED"
    },
    ['ambulance'] = {
        label = "Los Santos Hospital",
        ranks = {1, 2, 3, 4, 5, 6, 7},
        openText = "There is EMS available at the Hospital",
        closeText = "There is NO EMS available at the Hospital"
    },  
    ['bahamas'] = {
        label = "Bahama Mamas",
        ranks = {0, 1, 2, 3, 4, 5, 6},
        openText = "The Bahama Mamas is OPEN",
        closeText = "The Bahama Mamas is CLOSED"
    },
-- Add more jobs here
}

-- Configurable commands
Config.OpenCommand = 'open'
Config.CloseCommand = 'close'

-- Cooldown time for commands (in seconds)
Config.CooldownTime = 300