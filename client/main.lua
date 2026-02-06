local RSGCore = exports['rsg-core']:GetCoreObject()

-----------------------------------------------------------------------
-- UTILITIES & ANIMATIONS
-----------------------------------------------------------------------

local function loadAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        RequestAnimDict(dict)
        Wait(10)
    end
end

local function PlayAnimation(ped, dict, name, duration, flag)
    loadAnimDict(dict)
    TaskPlayAnim(ped, dict, name, 2.0, 2.0, duration or -1, flag or 1, 0, false, false, false)
end

local function FormatTime(seconds)
    local mins = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d", mins, secs)
end

-----------------------------------------------------------------------
-- GLOBAL TIMER DISPLAY (OPTIMIZED - ox_lib TextUI, no frame loop)
-----------------------------------------------------------------------

-- We get server time via event since os.time() doesn't work on client
local ServerTimeOffset = 0

RegisterNetEvent('devchacha-robbery:client:syncTime', function(serverTime)
    ServerTimeOffset = serverTime - (GetGameTimer() / 1000)
end)

local function GetServerTime()
    return math.floor((GetGameTimer() / 1000) + ServerTimeOffset)
end

-- Request server time on start
CreateThread(function()
    TriggerServerEvent('devchacha-robbery:server:requestTime')
end)

-- OPTIMIZED: Single thread checking every 1 second, uses ox_lib textUI (no frame loop needed)
local CurrentDisplayState = nil -- Track what we're currently showing

CreateThread(function()
    while true do
        Wait(1000) -- Check every 1 second (NOT every frame!)
        
        local playerCoords = GetEntityCoords(PlayerPedId())
        local states = GlobalState.devchacha_robbery_states or {}
        local serverTime = GetServerTime()
        local newDisplayState = nil
        
        -- Check Banks
        for bankId, bankData in pairs(Config.Banks or {}) do
            if bankData.vaults and not newDisplayState then
                for vaultId, vault in ipairs(bankData.vaults) do
                    local key = bankId .. '_' .. vaultId
                    local data = states[key]
                    
                    if data and type(data) == 'table' and data.state == 'unlocking' and data.unlockTime then
                        local dist = #(playerCoords - vault.coords)
                        if dist < 5.0 then
                            local remaining = data.unlockTime - serverTime
                            if remaining > 0 then
                                newDisplayState = { type = 'bank_countdown', time = FormatTime(remaining) }
                            else
                                newDisplayState = { type = 'bank_ready' }
                            end
                            break
                        end
                    end
                end
            end
        end
        
        -- Check Stores (only if no bank found)
        if not newDisplayState then
            for storeId, storeData in pairs(Config.Stores or {}) do
                local key = 'store_' .. storeId
                local data = states[key]
                
                if data and type(data) == 'table' and data.state == 'unlocking' and data.unlockTime then
                    local displayCoords = storeData.coords or (storeData.registers and storeData.registers[1] and storeData.registers[1].coords)
                    if displayCoords then
                        local dist = #(playerCoords - displayCoords)
                        if dist < 5.0 then
                            local remaining = data.unlockTime - serverTime
                            if remaining > 0 then
                                newDisplayState = { type = 'store_countdown', time = FormatTime(remaining) }
                            else
                                newDisplayState = { type = 'store_ready' }
                            end
                            break
                        end
                    end
                end
            end
        end
        
        -- Only update UI if state changed (prevents flickering and unnecessary calls)
        local stateChanged = false
        if newDisplayState == nil and CurrentDisplayState ~= nil then
            stateChanged = true
        elseif newDisplayState ~= nil and CurrentDisplayState == nil then
            stateChanged = true
        elseif newDisplayState and CurrentDisplayState then
            if newDisplayState.type ~= CurrentDisplayState.type or newDisplayState.time ~= CurrentDisplayState.time then
                stateChanged = true
            end
        end
        
        if stateChanged then
            if newDisplayState == nil then
                lib.hideTextUI()
            else
                local text, bgColor
                if newDisplayState.type == 'bank_countdown' then
                    text = '🔴 VAULT COOLING: ' .. newDisplayState.time
                    bgColor = '#8B0000'
                elseif newDisplayState.type == 'bank_ready' then
                    text = '🟢 VAULT OPEN - COLLECT LOOT!'
                    bgColor = '#006400'
                elseif newDisplayState.type == 'store_countdown' then
                    text = '🟠 SAFE UNLOCKING: ' .. newDisplayState.time
                    bgColor = '#CC5500'
                elseif newDisplayState.type == 'store_ready' then
                    text = '🟢 SAFE OPEN - COLLECT LOOT!'
                    bgColor = '#006400'
                end
                
                lib.showTextUI(text, {
                    position = 'top-center',
                    style = {
                        backgroundColor = bgColor,
                        color = 'white',
                        padding = '10px 20px',
                        borderRadius = '8px',
                        fontSize = '18px',
                        fontWeight = 'bold'
                    }
                })
            end
            CurrentDisplayState = newDisplayState
        end
    end
end)

-----------------------------------------------------------------------
-- ROBBERY LOGIC
-----------------------------------------------------------------------

local function RobStore(storeId, regId, data)
    local ped = PlayerPedId()
    
    -- Check Current State via Callback
    RSGCore.Functions.TriggerCallback('devchacha-robbery:server:checkStoreState', function(state, remaining)
        if state == 'looted' then
            -- ALREADY ROBBED (resets on server/script restart)
            lib.notify({ title = 'Robbery', description = 'This store has already been robbed!', type = 'error' })
        
        elseif state == 'open' then
             -- LOOT PHASE - Check canRob first to validate
            RSGCore.Functions.TriggerCallback('devchacha-robbery:server:canRob', function(canRob)
                if not canRob then return end
                
                PlayAnimation(ped, "script_common@jail_cell@unlock@key", "action", -1, 1)
                if lib.progressBar({
                    duration = 5000,
                    label = 'Grabbing Loot...',
                    useWhileDead = false,
                    canCancel = true,
                    disable = { move = true, car = true, combat = true },
                }) then
                    ClearPedTasks(ped)
                    TriggerServerEvent('devchacha-robbery:server:payout', {
                        type = 'store',
                        id = storeId,
                        subId = regId,
                        label = data.label,
                        register = false
                    })
                else
                    ClearPedTasks(ped)
                    lib.notify({ title = 'Robbery', description = 'Cancelled', type = 'error' })
                end
            end, { type = 'store', id = storeId, subId = regId })

        elseif state == 'unlocking' then
             -- WAITING PHASE
             local mins = math.ceil((remaining or 0) / 60)
             lib.notify({ title = 'Robbery', description = 'Mechanism active. Wait ' .. mins .. ' minutes.', type = 'error' })
        
        else
            -- START PHASE (state == nil)
            RSGCore.Functions.TriggerCallback('devchacha-robbery:server:canRob', function(canRob)
                if not canRob then return end
        
                -- Minigame (Lockpick) - lockpick is already consumed on server
                local success = lib.skillCheck(Config.Difficulty.StoreRegister, {'e'})
                if not success then
                    lib.notify({ title = 'Robbery', description = 'Lockpick broke! You need another one.', type = 'error' })
                    return 
                end
        
                -- 3. Progress / Animation
                PlayAnimation(ped, "script_common@jail_cell@unlock@key", "action", -1, 1)
                if lib.progressBar({
                    duration = 5000,
                    label = 'Disabling Security...',
                    useWhileDead = false,
                    canCancel = true,
                    disable = { move = true, car = true, combat = true },
                }) then
                    ClearPedTasks(ped)
                    TriggerServerEvent('devchacha-robbery:server:startStoreRobbery', storeId, data.label)
                else
                    ClearPedTasks(ped)
                    lib.notify({ title = 'Robbery', description = 'Cancelled', type = 'error' })
                end
            end, { type = 'store', id = storeId, subId = regId })
        end
    end, storeId)
end

local function RobBankVault(bankId, vaultId, data)
    local ped = PlayerPedId()
    
    RSGCore.Functions.TriggerCallback('devchacha-robbery:server:checkBankState', function(state, remaining)
        if state == 'looted' then
            -- ALREADY ROBBED (resets on server/script restart)
            lib.notify({ title = 'Robbery', description = 'This vault has already been robbed!', type = 'error' })
        
        elseif state == 'open' then
             -- LOOT PHASE
            RSGCore.Functions.TriggerCallback('devchacha-robbery:server:canRob', function(canRob)
                if not canRob then return end
    
                -- Animation (Looting)
                TaskStartScenarioInPlace(ped, `WORLD_HUMAN_CROUCH_INSPECT`, 0, true)
    
                if lib.progressBar({
                    duration = 7000,
                    label = 'Looting Vault...',
                    useWhileDead = false,
                    canCancel = true,
                    disable = { move = true, car = true, combat = true }
                }) then
                    ClearPedTasks(ped)
                    TriggerServerEvent('devchacha-robbery:server:payout', {
                        type = 'bank',
                        id = bankId,
                        subId = vaultId,
                        label = data.label,
                        vault = true
                    })
                else
                    ClearPedTasks(ped)
                    lib.notify({ title = 'Robbery', description = 'Cancelled', type = 'error' })
                end
            end, { type = 'bank', id = bankId, subId = vaultId })
            
        elseif state == 'unlocking' then
             -- WAITING PHASE
             local mins = math.ceil((remaining or 0) / 60)
             lib.notify({ title = 'Robbery', description = 'Heat is too high! Wait ' .. mins .. ' minutes for smoke to clear.', type = 'error' })
        
        else
            -- BLOWING PHASE
            RSGCore.Functions.TriggerCallback('devchacha-robbery:server:canRob', function(canRob)
                if not canRob then return end
    
                -- Animation (Planting TNT)
                TaskStartScenarioInPlace(ped, `WORLD_HUMAN_CROUCH_INSPECT`, 0, true)
                
                if lib.progressBar({
                    duration = 4000,
                    label = 'Planting Dynamite...',
                    useWhileDead = false,
                    canCancel = true,
                    disable = { move = true, car = true, combat = true }
                }) then
                    ClearPedTasks(ped)
                    
                    -- Notify Player to Run
                    lib.notify({ 
                        title = 'DANGER', 
                        description = 'Dynamite Active! MOVE! It\'s gonna BLAST in 15 seconds!', 
                        type = 'error',
                        duration = 15000 
                    })
    
                    -- Trigger Police Alert immediately upon planting
                    TriggerServerEvent('devchacha-robbery:server:policeAlert', data.label or 'Bank Vault')
    
                    Wait(15000) -- Wait 15 Seconds before blast
                    
                    -- Tell server we blew it up -> Server triggers explosion for everyone
                    TriggerServerEvent('devchacha-robbery:server:setVaultState', bankId, vaultId, 'blown')
                    
                else
                    ClearPedTasks(ped)
                    lib.notify({ title = 'Robbery', description = 'Cancelled', type = 'error' })
                end
            end, { type = 'bank', id = bankId, subId = vaultId })
        end
    end, bankId, vaultId)
end

local function BreachDoor(type, id, doorId, doorData)
    local ped = PlayerPedId()

    RSGCore.Functions.TriggerCallback('devchacha-robbery:server:canBreach', function(canBreach)
        if not canBreach then return end

        local diff = (type == 'bank') and Config.Difficulty.BankDoor or Config.Difficulty.DoorBreach
        local success = lib.skillCheck(diff, {'e'}) 
        if not success then
             lib.notify({ title = 'Robbery', description = 'Failed to breach door!', type = 'error' })
             return
        end

        PlayAnimation(ped, "script_common@jail_cell@unlock@key", "action", -1, 1)
        if lib.progressBar({
            duration = (type == 'bank') and 10000 or 5000, -- Longer for banks
            label = 'Breaching Door...',
            useWhileDead = false,
            canCancel = true,
            disable = { move = true, car = true, combat = true },
        }) then
            ClearPedTasks(ped)
            lib.notify({ title = 'Robbery', description = 'Door breached!', type = 'success' })
        else
            ClearPedTasks(ped)
            lib.notify({ title = 'Robbery', description = 'Cancelled', type = 'error' })
        end
    end, { type = type, id = id, doorId = doorId })
end

-----------------------------------------------------------------------
-- INITIALIZATION
-----------------------------------------------------------------------

CreateThread(function()
    print('[devchacha-robbery] Initializing Targets (Third Eye)...')
    
    -- Init Store Targets
    for storeId, storeData in pairs(Config.Stores) do
        -- Main Robbery Interaction (At Registers)
        if storeData.registers then
            for i, reg in ipairs(storeData.registers) do
                exports.ox_target:addSphereZone({
                    coords = reg.coords,
                    radius = reg.radius,
                    debug = Config.Debug,
                    options = {
                        {
                            name = 'rob_store_' .. storeId .. '_' .. i,
                            icon = 'fa-solid fa-sack-dollar', -- New Icon for Main Robbery
                            label = 'Rob Store', -- Generic label, logic handles state
                            onSelect = function()
                                RobStore(storeId, i, storeData)
                            end
                        }
                    }
                })
            end
        end

        -- Note: Safes and Doors for stores enabled in Config will NOT be initialized individually
        -- as requested ("Remove breach door crack safe and rob register make it one")
    end

    -- Init Bank Targets
    for bankId, bankData in pairs(Config.Banks) do
        -- Vaults
        if bankData.vaults then
            for i, vault in ipairs(bankData.vaults) do
                 exports.ox_target:addSphereZone({
                    coords = vault.coords,
                    radius = vault.radius,
                    debug = Config.Debug,
                    options = {
                        {
                            name = 'rob_vault_' .. bankId .. '_' .. i,
                            icon = 'fa-solid fa-vault',
                            label = Config.Text.BlowVault, -- Initial label
                            onSelect = function()
                                RobBankVault(bankId, i, bankData)
                            end
                        }
                    }
                })
            end
        end

        -- Bank Doors (optional)
        if bankData.doors then
            for i, door in ipairs(bankData.doors) do
                exports.ox_target:addSphereZone({
                    coords = door.coords,
                    radius = door.radius or 1.0,
                    debug = Config.Debug,
                    options = {
                        {
                            name = 'breach_bank_door_' .. bankId .. '_' .. i,
                            icon = 'fa-solid fa-door-open',
                            label = 'Breach Bank Door',
                            onSelect = function()
                                BreachDoor('bank', bankId, i, door)
                            end
                        }
                    }
                })
            end
        end
    end
end)

-----------------------------------------------------------------------
-- EVENTS
-----------------------------------------------------------------------

RegisterNetEvent('devchacha-robbery:client:policeAlert', function(locName)
    local alertMsg = string.format(Config.Text.PoliceAlert, locName)
    lib.notify({ title = 'Police Alert', description = alertMsg, type = 'error', duration = 300000 })
    PlaySoundFrontend("Core_Fill_Up", "Consumption_Sounds", true, 0)
end)

RegisterNetEvent('devchacha-robbery:client:syncExplosion', function(bankId, vaultId)
    -- Find the location from Config
    local bankData = Config.Banks[bankId]
    if bankData and bankData.vaults and bankData.vaults[vaultId] then
        local pos = bankData.vaults[vaultId].coords
        
        -- Create Explosion Effect
        AddExplosion(pos.x, pos.y, pos.z, Config.Explosion.type, Config.Explosion.radius, true, false, 1.0)
        ShakeGameplayCam(Config.Explosion.cameraShake, Config.Explosion.shake)
        
        -- Notify (Timer is handled by global thread that reads GlobalState)
        lib.notify({ title = 'BOOM!', description = 'Vault has been blown open! Cooling down...', type = 'success' })
    end
end)
