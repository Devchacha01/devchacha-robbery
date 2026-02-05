local RSGCore = exports['rsg-core']:GetCoreObject()

-- Handlers
local Cooldowns = {} -- Tracks time (os.time)
local RobberyStates = {} -- Tracks state ('blown', etc) of locations to sync users

-----------------------------------------------------------------------
-- FUNCTIONS
-----------------------------------------------------------------------

local function Notify(src, msg, type)
    TriggerClientEvent('ox_lib:notify', src, { title = 'Robbery', description = msg, type = type or 'inform' })
end

local function GetPoliceCount()
    local count = 0
    local players = RSGCore.Functions.GetRSGPlayers()
    for _, src in pairs(players) do
        local Player = RSGCore.Functions.GetPlayer(src)
        if Player then
            local job = Player.PlayerData.job.name
            for _, pJob in ipairs(Config.Police.Jobs) do
                if job == pJob then
                    count = count + 1
                    break
                end
            end
        end
    end
    return count
end

-----------------------------------------------------------------------
-- GLOBAL STATE SYNC
-----------------------------------------------------------------------

RegisterNetEvent('devchacha-robbery:server:setVaultState', function(bankId, vaultId, state)
    local src = source
    local key = bankId .. '_' .. vaultId
    
    if state == 'blown' then
        -- This means player successfully planted TNT and it exploded
        -- We now start the timer for 'unlocking'
        local unlockTime = os.time() + (Config.BankRobberyDuration * 60)
         
        RobberyStates[key] = { state = 'unlocking', unlockTime = unlockTime }

        local currentStates = GlobalState.devchacha_robbery_states or {}
        currentStates[key] = { state = 'unlocking', unlockTime = unlockTime }
        GlobalState.devchacha_robbery_states = currentStates

        -- SET 2 HOUR COOLDOWN IMMEDIATELY so no one else can rob this bank
        local cdKey = 'bank_' .. bankId .. '_' .. vaultId
        Cooldowns[cdKey] = os.time() + (Config.Cooldowns.Bank * 60)

        TriggerClientEvent('devchacha-robbery:client:syncExplosion', -1, bankId, vaultId)
        Notify(src, 'Vault blown! But the heat is too high. Looting available in ' .. Config.BankRobberyDuration .. ' minutes.', 'inform')
    else
        -- Just in case we use other states
        RobberyStates[key] = state
        local currentStates = GlobalState.devchacha_robbery_states or {}
        currentStates[key] = state
        GlobalState.devchacha_robbery_states = currentStates
    end
end)

RSGCore.Functions.CreateCallback('devchacha-robbery:server:checkBankState', function(source, cb, bankId, vaultId)
    local key = bankId .. '_' .. vaultId
    local currentStates = GlobalState.devchacha_robbery_states or {}
    local data = currentStates[key]
    
    if not data then return cb(nil) end
    
    if type(data) == 'table' and data.state == 'unlocking' then
        if os.time() >= data.unlockTime then
            cb('open') -- Time passed, now lootable
        else
            local remaining = data.unlockTime - os.time()
            cb('unlocking', remaining)
        end
    else
        cb(data) -- e.g. nil or 'done'
    end
end)

RegisterNetEvent('devchacha-robbery:server:startStoreRobbery', function(storeId, label)
    local src = source
    local key = 'store_' .. storeId
    
    -- Set Unlock Timer
    local unlockTime = os.time() + (Config.RobberyDuration * 60)
    
    local currentStates = GlobalState.devchacha_robbery_states or {}
    currentStates[key] = { state = 'unlocking', unlockTime = unlockTime }
    GlobalState.devchacha_robbery_states = currentStates
    
    Notify(src, 'Store lock mechanism disabled. Safe unlocking in ' .. Config.RobberyDuration .. ' minutes!', 'success')
    TriggerEvent('devchacha-robbery:server:policeAlert', label or 'Store Robbery')
end)

-----------------------------------------------------------------------
-- CALLBACKS
-----------------------------------------------------------------------

RSGCore.Functions.CreateCallback('devchacha-robbery:server:canRob', function(source, cb, data)
    local src = source
    local type = data.type 
    local id = data.id 
    local subId = data.subId 

    -- Check Police
    local policeNeeded = (type == 'bank') and Config.Police.RequiredForBank or Config.Police.RequiredForStore
    local policeCount = GetPoliceCount()

    if policeCount < policeNeeded then
        Notify(src, 'Not enough lawmen in the area!', 'error')
        return cb(false)
    end

    -- Check Cooldowns
    local cdKey = type .. '_' .. id .. (subId and ('_' .. subId) or '')
    
    local currentTime = os.time()
    
    if Cooldowns[cdKey] and Cooldowns[cdKey] > currentTime then
        local remaining = Cooldowns[cdKey] - currentTime
        local mins = math.ceil(remaining/60)
        Notify(src, 'This spot was recently robbed. Wait ' .. mins .. ' minutes.', 'error')
        return cb(false)
    end

    -- Check Items
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return cb(false) end

    local requiredItem = nil
    if type == 'bank' then
        requiredItem = Config.Items.Dynamite
    else
        requiredItem = Config.Items.Lockpick
    end

    local hasItem = Player.Functions.GetItemByName(requiredItem)
    if not hasItem then
        Notify(src, 'You need a ' .. requiredItem .. '!', 'error')
        return cb(false)
    end

    -- Remove item logic (if consumable)
    if type == 'bank' then
        Player.Functions.RemoveItem(requiredItem, 1)
        TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[requiredItem], "remove")
    end

    cb(true)
end)

RSGCore.Functions.CreateCallback('devchacha-robbery:server:canBreach', function(source, cb, data)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return cb(false) end

    local policeNeeded = (data.type == 'bank') and Config.Police.RequiredForBank or Config.Police.RequiredForStore
    local policeCount = GetPoliceCount()

    if policeCount < policeNeeded then
        Notify(src, 'Not enough lawmen in the area!', 'error')
        return cb(false)
    end

    local requiredItem = Config.Items.Lockpick
    local hasItem = Player.Functions.GetItemByName(requiredItem)
    
    if not hasItem then
        Notify(src, 'You need a ' .. requiredItem .. ' to breach this door!', 'error')
        return cb(false)
    end

    cb(true)
end)

RSGCore.Functions.CreateCallback('devchacha-robbery:server:checkStoreState', function(source, cb, storeId)
    local key = 'store_' .. storeId
    local currentStates = GlobalState.devchacha_robbery_states or {}
    local data = currentStates[key]
    
    if not data then return cb(nil) end
    
    -- Check time
    if os.time() >= data.unlockTime then
        cb('open')
    else
        local remaining = data.unlockTime - os.time()
        cb('unlocking', remaining)
    end
end)

-----------------------------------------------------------------------
-- EVENTS
-----------------------------------------------------------------------

RegisterNetEvent('devchacha-robbery:server:payout', function(data)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    -- Verify cooldown
    local currentTime = os.time()
    local type = data.type
    local id = data.id 
    local subId = data.subId
    local cdKey = type .. '_' .. id .. (subId and ('_' .. subId) or '')

    if Cooldowns[cdKey] and Cooldowns[cdKey] > currentTime then
        return
    end

    -- Set Cooldown
    local cdDuration = (type == 'bank') and (Config.Cooldowns.Bank * 60) or (Config.Cooldowns.Store * 60)
    -- Unified Store Robbery uses 'Store' cooldown now, not SearchRegister
    
    Cooldowns[cdKey] = currentTime + cdDuration

    -- Calculate Rewards
    local rewardsCfg = nil
    if type == 'bank' then
        rewardsCfg = Config.Rewards.BankVault
    else 
        -- Unified reward for store (combines cash and maybe items)
        rewardsCfg = Config.Rewards.StoreSafe -- Use Safe rewards as base for the "Main Loot"
    end

    -- Give Cash
    local cash = math.random(rewardsCfg.minCash, rewardsCfg.maxCash)
    Player.Functions.AddMoney('cash', cash, "robbery-payout")

    -- Give Items
    local itemsGot = {}
    if rewardsCfg.items then
        for _, itemInfo in ipairs(rewardsCfg.items) do
            if math.random(0, 100) <= itemInfo.chance then
                local amount = 1
                if type(itemInfo.amount) == 'table' then
                    amount = math.random(itemInfo.amount[1], itemInfo.amount[2])
                else
                    amount = itemInfo.amount
                end
                
                if Player.Functions.AddItem(itemInfo.name, amount) then
                    table.insert(itemsGot, amount .. 'x ' .. itemInfo.name)
                    TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[itemInfo.name], "add")
                end
            end
        end
    end

    -- Notify
    local itemStr = table.concat(itemsGot, ', ')
    if itemStr ~= "" then
        Notify(src, 'You got $' .. cash .. ' and ' .. itemStr, 'success')
    else
        Notify(src, 'You got $' .. cash, 'success')
    end
    
    -- Reset state if needed (state remains until restart or overwritten by new state in future)
end)

RegisterNetEvent('devchacha-robbery:server:policeAlert', function(locName)
    local players = RSGCore.Functions.GetRSGPlayers()
    for _, src in pairs(players) do
        local Player = RSGCore.Functions.GetPlayer(src)
        if Player then
            local job = Player.PlayerData.job.name
            for _, pJob in ipairs(Config.Police.Jobs) do
                if job == pJob then
                    TriggerClientEvent('devchacha-robbery:client:policeAlert', src, locName)
                    Notify(src, string.format(Config.Text.PoliceAlert, locName), 'inform')
                end
            end
        end
    end
end)
