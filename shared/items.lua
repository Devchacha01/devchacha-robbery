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

-- New Unique Bank Loot
bearer_bond = { name = 'bearer_bond', label = 'Bearer Bond', weight = 10, type = 'item', image = 'bearer_bond.png', unique = false, useable = false, shouldClose = false, description = 'A valuable government bond' },
gold_certificate = { name = 'gold_certificate', label = 'Gold Certificate', weight = 10, type = 'item', image = 'gold_certificate.png', unique = false, useable = false, shouldClose = false, description = 'Certificate redeemable for gold coin' },
confidential_ledger = { name = 'confidential_ledger', label = 'Confidential Ledger', weight = 500, type = 'item', image = 'confidential_ledger.png', unique = false, useable = false, shouldClose = false, description = 'A heavy book containing secret financial records' },
bank_draft = { name = 'bank_draft', label = 'Bank Draft', weight = 10, type = 'item', image = 'bank_draft.png', unique = false, useable = false, shouldClose = false, description = 'A draft for a large sum of money' },
trust_deed = { name = 'trust_deed', label = 'Trust Deed', weight = 10, type = 'item', image = 'trust_deed.png', unique = false, useable = false, shouldClose = false, description = 'Deed to a valuable property' },
railroad_bond = { name = 'railroad_bond', label = 'Railroad Bond', weight = 10, type = 'item', image = 'railroad_bond.png', unique = false, useable = false, shouldClose = false, description = 'Shares in the Cornwall Railroad' },
shipping_manifest = { name = 'shipping_manifest', label = 'Shipping Manifest', weight = 10, type = 'item', image = 'shipping_manifest.png', unique = false, useable = false, shouldClose = false, description = 'Details of valuable cargo shipments' },
antique_jewelry_box = { name = 'antique_jewelry_box', label = 'Antique Jewelry Box', weight = 200, type = 'item', image = 'antique_jewelry_box.png', unique = false, useable = false, shouldClose = false, description = 'A velvet lined box filled with jewels' },
diamond_ring = { name = 'diamond_ring', label = 'Diamond Ring', weight = 50, type = 'item', image = 'diamond_ring.png', unique = false, useable = false, shouldClose = false, description = 'A ring with a large diamond' },


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
