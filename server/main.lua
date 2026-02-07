local RSGCore = exports['rsg-core']:GetCoreObject()

-- Robbery states are reset on script/server restart
-- Once robbed = stays looted until restart

-- Clear GlobalState on resource start to prevent exploits
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    GlobalState.devchacha_robbery_states = {}
    print('[devchacha-robbery] Resource started - GlobalState cleared')
end)

-- Time sync for clients (os.time doesn't work on client)
RegisterNetEvent('devchacha-robbery:server:requestTime', function()
    local src = source
    TriggerClientEvent('devchacha-robbery:client:syncTime', src, os.time())
end)

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

        local currentStates = GlobalState.devchacha_robbery_states or {}
        currentStates[key] = { state = 'unlocking', unlockTime = unlockTime }
        GlobalState.devchacha_robbery_states = currentStates

        TriggerClientEvent('devchacha-robbery:client:syncExplosion', -1, bankId, vaultId)
        Notify(src, 'Vault blown! But the heat is too high. Looting available in ' .. Config.BankRobberyDuration .. ' minutes.', 'inform')
    else
        -- Just in case we use other states
        local currentStates = GlobalState.devchacha_robbery_states or {}
        currentStates[key] = state
        GlobalState.devchacha_robbery_states = currentStates
    end
end)

RSGCore.Functions.CreateCallback('devchacha-robbery:server:checkBankState', function(source, cb, bankId, vaultId)
    local key = bankId .. '_' .. vaultId
    local currentTime = os.time()
    
    local currentStates = GlobalState.devchacha_robbery_states or {}
    local data = currentStates[key]
    
    -- Check if already looted (stays until restart)
    if data == 'looted' then
        return cb('looted')
    end
    
    -- Check if we're in 'unlocking' phase
    if data and type(data) == 'table' and data.state == 'unlocking' then
        if currentTime >= data.unlockTime then
            return cb('open')
        else
            local remaining = data.unlockTime - currentTime
            return cb('unlocking', remaining)
        end
    end
    
    -- Not robbed yet = fresh
    cb(nil)
end)

RegisterNetEvent('devchacha-robbery:server:startStoreRobbery', function(storeId, label)
    local src = source
    local key = 'store_' .. storeId
    local currentStates = GlobalState.devchacha_robbery_states or {}
    
    -- Check if already looted (stays until restart)
    if currentStates[key] == 'looted' then
        Notify(src, 'This store has already been robbed!', 'error')
        return
    end
    
    -- Check if robbery already in progress
    if currentStates[key] and type(currentStates[key]) == 'table' then
        Notify(src, 'Robbery already in progress here!', 'error')
        return
    end
    
    -- Set Unlock Timer
    local unlockTime = os.time() + (Config.RobberyDuration * 60)
    
    currentStates[key] = { state = 'unlocking', unlockTime = unlockTime }
    GlobalState.devchacha_robbery_states = currentStates
    
    Notify(src, 'Store lock mechanism disabled. Safe unlocking in ' .. Config.RobberyDuration .. ' minutes!', 'success')
    
    local coords = Config.Stores[storeId].coords
    TriggerEvent('devchacha-robbery:server:policeAlert', label or 'Store Robbery', coords)
end)

-----------------------------------------------------------------------
-- CALLBACKS
-----------------------------------------------------------------------

RSGCore.Functions.CreateCallback('devchacha-robbery:server:canRob', function(source, cb, data)
    local src = source
    local robType = data.type 
    local id = data.id 
    local subId = data.subId 

    -- Check Police
    local policeNeeded = (robType == 'bank') and Config.Police.RequiredForBank or Config.Police.RequiredForStore
    local policeCount = GetPoliceCount()

    if policeCount < policeNeeded then
        Notify(src, 'Not enough lawmen in the area!', 'error')
        return cb(false)
    end

    -- Build state key
    local stateKey = nil
    if robType == 'bank' then
        stateKey = id .. '_' .. subId
    else
        stateKey = 'store_' .. id
    end
    
    local currentStates = GlobalState.devchacha_robbery_states or {}
    local stateData = currentStates[stateKey]
    local currentTime = os.time()
    
    -- Check if already looted
    if stateData == 'looted' then
        Notify(src, 'This location has already been robbed!', 'error')
        return cb(false)
    end
    
    -- Check if vault/store is OPEN for looting (unlockTime passed)
    local isOpenForLooting = false
    if stateData and type(stateData) == 'table' and stateData.state == 'unlocking' then
        if stateData.unlockTime and currentTime >= stateData.unlockTime then
            isOpenForLooting = true
        end
    end

    -- Check Items (skip if open for looting - player already used item)
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return cb(false) end

    if not isOpenForLooting then
        local requiredItem = nil
        if robType == 'bank' then
            requiredItem = Config.Items.Dynamite
        else
            requiredItem = Config.Items.Lockpick
        end

        local hasItem = Player.Functions.GetItemByName(requiredItem)
        if not hasItem then
            Notify(src, 'You need a ' .. requiredItem .. '!', 'error')
            return cb(false)
        end

        -- Remove item (consumed on attempt - pass or fail)
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
    local currentTime = os.time()
    
    local currentStates = GlobalState.devchacha_robbery_states or {}
    local data = currentStates[key]
    
    -- Check if already looted (stays until restart)
    if data == 'looted' then
        return cb('looted')
    end
    
    -- Check if we're in 'unlocking' phase
    if data and type(data) == 'table' and data.state == 'unlocking' and data.unlockTime then
        if currentTime >= data.unlockTime then
            return cb('open')
        else
            local remaining = data.unlockTime - currentTime
            return cb('unlocking', remaining)
        end
    end
    
    -- Not robbed yet = fresh
    cb(nil)
end)

-----------------------------------------------------------------------
-- EVENTS
-----------------------------------------------------------------------

RegisterNetEvent('devchacha-robbery:server:payout', function(data)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local currentTime = os.time()
    local robType = data.type
    local id = data.id 
    local subId = data.subId
    
    -- Build state key
    local stateKey = nil
    if robType == 'bank' then
        stateKey = id .. '_' .. subId
    else
        stateKey = 'store_' .. id
    end
    
    -- ANTI-EXPLOIT: Check if vault/store is actually OPEN for looting
    local currentStates = GlobalState.devchacha_robbery_states or {}
    local stateData = currentStates[stateKey]
    
    -- Must be in 'unlocking' state with timer expired
    if stateData == 'looted' then
        Notify(src, 'Someone already collected the loot!', 'error')
        print('[devchacha-robbery] BLOCKED: Player ' .. src .. ' tried to loot already-looted ' .. stateKey)
        return
    end
    
    if not stateData or type(stateData) ~= 'table' or stateData.state ~= 'unlocking' then
        Notify(src, 'Nothing to loot here!', 'error')
        print('[devchacha-robbery] BLOCKED: Player ' .. src .. ' tried to loot ' .. stateKey .. ' with invalid state')
        return
    end
    
    -- Check if timer has actually expired
    if stateData.unlockTime and currentTime < stateData.unlockTime then
        local remaining = stateData.unlockTime - currentTime
        Notify(src, 'Wait ' .. math.ceil(remaining/60) .. ' more minutes!', 'error')
        print('[devchacha-robbery] BLOCKED: Player ' .. src .. ' tried to loot ' .. stateKey .. ' before timer expired')
        return
    end
    
    -- IMMEDIATELY mark as looted BEFORE giving rewards (prevents race condition)
    currentStates[stateKey] = 'looted'
    GlobalState.devchacha_robbery_states = currentStates
    print('[devchacha-robbery] Location ' .. stateKey .. ' marked as LOOTED')

    -- Calculate Rewards
    local rewardsCfg = nil
    if robType == 'bank' then
        rewardsCfg = Config.Rewards.BankVault
    else 
        -- Unified reward for store (combines cash and maybe items)
        rewardsCfg = Config.Rewards.Store
    end

    -- Give Cash
    local cash = math.random(rewardsCfg.minCash, rewardsCfg.maxCash)
    Player.Functions.AddMoney('cash', cash, "robbery-payout")

    -- Give Items
    local itemsGot = {}
    if rewardsCfg.items then
        for _, itemInfo in ipairs(rewardsCfg.items) do
            local roll = math.random(0, 100)
            print('[devchacha-robbery] Item Roll: ' .. itemInfo.name .. ' - Rolled: ' .. roll .. ' / Needed: ' .. itemInfo.chance)
            
            if roll <= itemInfo.chance then
                local amount = 1
                if type(itemInfo.amount) == 'table' then
                    amount = math.random(itemInfo.amount[1], itemInfo.amount[2])
                else
                    amount = itemInfo.amount
                end
                
                print('[devchacha-robbery] Trying to give: ' .. amount .. 'x ' .. itemInfo.name)
                
                local success = Player.Functions.AddItem(itemInfo.name, amount)
                if success then
                    table.insert(itemsGot, amount .. 'x ' .. itemInfo.name)
                    TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[itemInfo.name], "add")
                    print('[devchacha-robbery] SUCCESS: Gave ' .. amount .. 'x ' .. itemInfo.name)
                else
                    print('[devchacha-robbery] FAILED: Could not give ' .. itemInfo.name .. ' - Item may not exist or inventory full')
                    Notify(src, 'Could not receive ' .. itemInfo.name .. ' (inventory full?)', 'error')
                end
            end
        end
    else
        print('[devchacha-robbery] No items configured for this reward type')
    end

    -- Notify
    local itemStr = table.concat(itemsGot, ', ')
    if itemStr ~= "" then
        Notify(src, 'You got $' .. cash .. ' and ' .. itemStr, 'success')
    else
        Notify(src, 'You got $' .. cash, 'success')
    end
    
    print('[devchacha-robbery] Payout complete for ' .. stateKey)
end)

RegisterNetEvent('devchacha-robbery:server:policeAlert', function(locName, coords)
    local players = RSGCore.Functions.GetRSGPlayers()
    for _, src in pairs(players) do
        local Player = RSGCore.Functions.GetPlayer(src)
        if Player then
            local job = Player.PlayerData.job.name
            for _, pJob in ipairs(Config.Police.Jobs) do
                if job == pJob then
                    TriggerClientEvent('devchacha-robbery:client:policeAlert', src, locName, coords)
                    Notify(src, string.format(Config.Text.PoliceAlert, locName), 'error')
                end
            end
        end
    end
end)
