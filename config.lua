Config = {}

-- General Settings
Config.Debug = true -- Enable debug mode for zones and prints
Config.Framework = 'rsg' -- rsg or vorp (currently optimized for RSG)

-- Items Required
Config.Items = {
    Lockpick = 'lockpick',
    AdvancedLockpick = 'advancedlockpick',
    Dynamite = 'tnt', -- used for banks/safes
}

-- Police Settings
Config.Police = {
    RequiredForStore = 0,
    RequiredForBank = 0, -- Set to 0 for testing, increase for production
    Jobs = { 'sheriff', 'leo', 'police', 'marshal' }
}

-- Cooldowns (in minutes)
Config.Cooldowns = {
    Store = 120, -- 2 hours (120 mins)
    Bank = 120, -- 2 hours
    SearchRegister = 5 -- Cooldown for milking the same register
}

Config.RobberyDuration = 5 -- Minutes to wait before looting store
Config.BankRobberyDuration = 10 -- Minutes to wait before looting bank

-- Minigame Difficulty (ox_lib skill check)
Config.Difficulty = {
    StoreRegister = {'easy', 'easy', 'medium'}, -- 3 checks
    SafeCrack = {'medium', 'medium', 'hard'},
    DoorBreach = {'easy', 'medium'}, -- For store back doors
    BankDoor = {'medium', 'hard', 'hard'}, -- Harder for banks
    BankDrill = {'hard', 'hard', 'hard', 'hard'} -- Not used for dynamite, but for future expansion
}

-- Rewards
Config.Rewards = {
    StoreRegister = {
        minCash = 10, maxCash = 40,
        items = { -- chance is 0-100
            { name = 'candy', amount = 1, chance = 50 },
            { name = 'bread', amount = 1, chance = 30 }
        }
    },
    StoreSafe = {
        minCash = 100, maxCash = 300,
        items = {
            { name = 'gold_ring', amount = 1, chance = 80 },
            { name = 'rolex', amount = 1, chance = 40 }
        }
    },
    BankVault = {
        minCash = 500, maxCash = 2000,
        items = {
            { name = 'gold_bar', amount = {1, 3}, chance = 100 },
            { name = 'diamond', amount = {1, 2}, chance = 30 }
        }
    }
}

-- Target/Text Settings
Config.Text = {
    RobRegister = 'Rob Register',
    RobSafe = 'Crack Safe',
    BlowVault = 'Blow Open Vault',
    LootVault = 'Loot Vault',
    PoliceAlert = 'Robbery in progress at %s!'
}

-- Store Locations
Config.Stores = {
    ['ValentineGeneral'] = {
        label = "Valentine General Store",
        coords = vector3(-324.26, 804.1, 117.93),
        registers = {
            { coords = vector3(-324.24, 804.08, 117.98), radius = 1.5 }
        },
        safes = {
             -- Example Safe Coords (Fill in with actual coords)
             { coords = vector3(-325.0, 805.0, 117.93), radius = 1.5 } 
        },
        doors = {
            -- Example Door to breach (Fill in with actual Back Door coords)
            { coords = vector3(-326.0, 806.0, 118.0), radius = 2.0 } 
        },
        type = 'general'
    },
    ['RhodesGeneral'] = {
        label = "Rhodes General Store",
        coords = vector3(1328.03, -1293.70, 77.07),
        registers = {
            { coords = vector3(1330.34, -1293.58, 77.02), radius = 1.5 }
        },
        safes = {
             -- Add safe coords
        },
        doors = {
            -- Add door coords
        },
        type = 'general'
    },
    ['SaintDenisGeneral'] = {
        label = "Saint Denis General Store",
        coords = vector3(2828.26, -1320.1, 46.8),
        registers = {
            { coords = vector3(2828.26, -1320.1, 46.8), radius = 1.5 }
        },
        safes = {},
        doors = {},
        type = 'general'
    },
    ['StrawberryGeneral'] = {
        label = "Strawberry General Store",
        coords = vector3(-1789.34, -387.5, 160.37),
        registers = {
            { coords = vector3(-1789.33, -387.55, 160.33), radius = 1.5 }
        },
        safes = {},
        doors = {},
        type = 'general'
    },
    ['BlackwaterGeneral'] = {
        label = "Blackwater General Store",
        coords = vector3(-785.47, -1323.85, 43.9),
        registers = {
             { coords = vector3(-785.49, -1322.16, 43.88), radius = 1.5 }
        },
        safes = {},
        doors = {},
        type = 'general'
    },
    ['ArmadilloGeneral'] = {
        label = "Armadillo General Store",
        coords = vector3(-3687.2, -2622.31, -13.3),
        registers = {
             { coords = vector3(-3687.3, -2622.49, -13.43), radius = 1.5 }
        },
        safes = {},
        doors = {},
        type = 'general'
    },
    ['TumbleweedGeneral'] = {
        label = "Tumbleweed General Store",
        coords = vector3(-5486.33, -2937.6, -0.35),
        registers = {
            { coords = vector3(-5486.36, -2937.69, -0.4), radius = 1.5 }
        },
        safes = {},
        doors = {},
        type = 'general'
    }
}

-- Bank Locations
Config.Banks = {
    ['ValentineBank'] = {
        label = "Valentine Bank",
        coords = vector3(-309.00, 763.63, 118.70),
        vaults = {
            { coords = vector3(-309.00, 763.63, 118.70), radius = 1.5 }
        }
    },
    ['RhodesBank'] = {
        label = "Rhodes Bank",
        coords = vector3(1287.42, -1314.50, 77.04),
        vaults = {
            { coords = vector3(1287.42, -1314.50, 77.04), radius = 1.5 }
        }
    },
    ['BlackwaterBank'] = {
        label = "Blackwater Bank",
        coords = vector3(-820.08, -1273.85, 43.65),
        vaults = {
            { coords = vector3(-820.08, -1273.85, 43.65), radius = 1.5 }
        }
    },
    ['SaintDenisBank'] = {
        label = "Saint Denis Bank",
        coords = vector3(2644.49, -1306.44, 52.25),
        vaults = {
            { coords = vector3(2644.49, -1306.44, 52.25), radius = 1.5 }
        }
    },
    ['ArmadilloBank'] = {
        label = "Armadillo Bank",
        coords = vector3(-3665.95, -2632.33, -13.59),
        vaults = {
            { coords = vector3(-3665.95, -2632.33, -13.59), radius = 1.5 }
        }
    }
}

-- FX / Audio
Config.Explosion = {
    type = 29, -- Dynamite
    radius = 10.0,
    shake = 1.0, 
    audible = true,
    cameraShake = 'LARGE_EXPLOSION_SHAKE'
}
