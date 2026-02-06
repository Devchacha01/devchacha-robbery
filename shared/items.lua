--[[
    ╔══════════════════════════════════════════════════════════════════╗
    ║           DEVCHACHA ROBBERY - REQUIRED ITEMS                     ║
    ║                                                                  ║
    ║   Copy these items to: rsg-core/shared/items.lua                 ║
    ║   Add them inside the RSGShared.Items = { } table                ║
    ║                                                                  ║
    ║   NOTE: Check if items already exist before adding!              ║
    ╚══════════════════════════════════════════════════════════════════╝
]]

-- =====================================================================
-- REQUIRED ITEMS FOR ROBBERY SCRIPT
-- Copy and paste these into rsg-core/shared/items.lua
-- =====================================================================

--[[
    ROBBERY TOOLS - Required for robberies
    ─────────────────────────────────────────────────────────────────────
]]

-- Lockpick - Used for Store Robberies (CONSUMED on use - pass or fail)
lockpick = { name = 'lockpick', label = 'Lockpick', weight = 100, type = 'item', image = 'lockpick.png', unique = false, useable = true, shouldClose = true, description = 'A tool for picking locks' },

-- Dynamite (TNT) - Used for Bank Vault Robberies (CONSUMED on use)
tnt = { name = 'tnt', label = 'Dynamite Stick', weight = 500, type = 'item', image = 'tnt.png', unique = false, useable = true, shouldClose = true, description = 'Explosive for blowing open bank vaults' },


--[[
    REWARD ITEMS - Given as loot from robberies
    ─────────────────────────────────────────────────────────────────────
    Add these if you don't already have them in your items file
]]

-- Store Robbery Rewards
gold_ring = { name = 'gold_ring', label = 'Gold Ring', weight = 50, type = 'item', image = 'gold_ring.png', unique = false, useable = false, shouldClose = false, description = 'A shiny gold ring, valuable to the right buyer' },
rolex = { name = 'rolex', label = 'Pocket Watch', weight = 100, type = 'item', image = 'rolex.png', unique = false, useable = false, shouldClose = false, description = 'An expensive pocket watch' },

-- Bank Vault Rewards
gold_bar = { name = 'gold_bar', label = 'Gold Bar', weight = 1000, type = 'item', image = 'gold_bar.png', unique = false, useable = false, shouldClose = false, description = 'A solid gold bar worth a fortune' },
diamond = { name = 'diamond', label = 'Diamond', weight = 50, type = 'item', image = 'diamond.png', unique = false, useable = false, shouldClose = false, description = 'A sparkling diamond of exceptional quality' },


-- =====================================================================
-- HOW TO ADD THESE ITEMS:
-- =====================================================================
--[[
    1. Open: rsg-core/shared/items.lua
    
    2. Find the RSGShared.Items = { section (usually at the top)
    
    3. Copy the items you need from above (check if they already exist!)
    
    4. Paste them inside the table, under "-- YOUR CUSTOM ITEMS"
       Example:
       
       RSGShared.Items = {
           
           -- YOUR CUSTOM ITEMS
           lockpick = { name = 'lockpick', label = 'Lockpick', weight = 100, type = 'item', image = 'lockpick.png', unique = false, useable = true, shouldClose = true, description = 'A tool for picking locks' },
           tnt = { name = 'tnt', label = 'Dynamite Stick', weight = 500, type = 'item', image = 'tnt.png', unique = false, useable = true, shouldClose = true, description = 'Explosive for blowing open bank vaults' },
           
           -- ... rest of items ...
       }
    
    5. Save the file and restart rsg-core
    
    6. Add the images to: rsg-inventory/html/images/
       - lockpick.png
       - tnt.png
       - (and any reward item images you added)
]]
