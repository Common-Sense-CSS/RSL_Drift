-- RSL inventory — server
-- General-purpose inventory. Rows live in `rsl_inventory_items`, one row per
-- occupied slot (slot numbers are 1..RSLConfig.INVENTORY_SLOTS); item
-- definitions (label, weight, stacking, etc.) come from the shared
-- `RSLItems` registry, not the DB. Direct DB queries per action — no
-- in-memory cache, same style as garage_s.lua.
--
-- `metadata` distinguishes non-stackable variants of the same item (future
-- phases — tuning parts, unique drops, etc.). Only items with empty
-- metadata (`'{}'`) auto-stack; anything else always takes its own slot.

---@param row table
---@return table
local function normalizeRow(row)
    row.quantity = tonumber(row.quantity)
    row.slot = tonumber(row.slot)
    return row
end

---@param characterId string
---@return table[] rows
---@return number totalWeight
local function fetchInventory(characterId)
    local rows = MySQL.query.await(
        'SELECT id, slot, item_key, quantity, metadata FROM rsl_inventory_items WHERE owner_character_id = ? ORDER BY slot ASC',
        { characterId }
    )
    local totalWeight = 0.0
    for _, row in ipairs(rows) do
        normalizeRow(row)
        local def = RSLItems[row.item_key]
        totalWeight = totalWeight + (def and def.weight or 0) * row.quantity
    end
    return rows, totalWeight
end

---@param source integer
---@return table[] rows
---@return number totalWeight
local function getInventory(source)
    local characterId = exports['rsl_core']:GetActiveCharacterId(source)
    if not characterId then return {}, 0 end
    return fetchInventory(characterId)
end

-- Adds `qty` of `itemKey` to `characterId`'s inventory. Computes the full
-- plan (which existing stacks get topped up, which new slots are needed)
-- before writing anything, so a run that doesn't fit (weight or slots)
-- fails cleanly with nothing partially applied.
---@param characterId string
---@param itemKey string
---@param qty integer
---@param metadata table?
---@return boolean
local function addItem(characterId, itemKey, qty, metadata)
    local def = RSLItems[itemKey]
    if not def or type(qty) ~= 'number' or qty <= 0 then return false end
    qty = math.floor(qty)
    metadata = metadata or {}
    local hasMetadata = next(metadata) ~= nil

    local existingRows, currentWeight = fetchInventory(characterId)
    if currentWeight + def.weight * qty > RSLConfig.INVENTORY_MAX_WEIGHT then return false end

    local remaining = qty
    local topUps = {} ---@type { id: string, add: integer }[]

    if not hasMetadata then
        for _, row in ipairs(existingRows) do
            if remaining <= 0 then break end
            if row.item_key == itemKey and row.metadata == '{}' then
                local space = def.maxStack - row.quantity
                if space > 0 then
                    local add = math.min(space, remaining)
                    topUps[#topUps + 1] = { id = row.id, add = add }
                    remaining = remaining - add
                end
            end
        end
    end

    local usedSlots = {}
    for _, row in ipairs(existingRows) do usedSlots[row.slot] = true end
    local newStacks = {} ---@type { slot: integer, qty: integer }[]
    local slot = 1
    while remaining > 0 do
        while usedSlots[slot] do slot = slot + 1 end
        if slot > RSLConfig.INVENTORY_SLOTS then return false end
        usedSlots[slot] = true
        local add = math.min(def.maxStack, remaining)
        newStacks[#newStacks + 1] = { slot = slot, qty = add }
        remaining = remaining - add
    end

    for _, plan in ipairs(topUps) do
        MySQL.update.await('UPDATE rsl_inventory_items SET quantity = quantity + ? WHERE id = ?', { plan.add, plan.id })
    end
    for _, plan in ipairs(newStacks) do
        MySQL.insert.await(
            'INSERT INTO rsl_inventory_items (owner_character_id, slot, item_key, quantity, metadata) VALUES (?, ?, ?, ?, ?)',
            { characterId, plan.slot, itemKey, plan.qty, json.encode(metadata) }
        )
    end

    return true
end

-- Removes `qty` of `itemKey`, decrementing across stacks oldest-slot-first.
-- All-or-nothing: fails without changing anything if the character doesn't
-- own enough total.
---@param characterId string
---@param itemKey string
---@param qty integer
---@return boolean
local function removeItem(characterId, itemKey, qty)
    if type(qty) ~= 'number' or qty <= 0 then return false end
    qty = math.floor(qty)

    local rows = MySQL.query.await(
        'SELECT id, quantity FROM rsl_inventory_items WHERE owner_character_id = ? AND item_key = ? ORDER BY slot ASC',
        { characterId, itemKey }
    )
    local total = 0
    for _, row in ipairs(rows) do
        row.quantity = tonumber(row.quantity)
        total = total + row.quantity
    end
    if total < qty then return false end

    local remaining = qty
    for _, row in ipairs(rows) do
        if remaining <= 0 then break end
        local take = math.min(row.quantity, remaining)
        if take >= row.quantity then
            MySQL.query.await('DELETE FROM rsl_inventory_items WHERE id = ?', { row.id })
        else
            MySQL.update.await('UPDATE rsl_inventory_items SET quantity = quantity - ? WHERE id = ?', { take, row.id })
        end
        remaining = remaining - take
    end
    return true
end

---@param characterId string
---@param itemKey string
---@param qty integer?
---@return boolean
local function hasItem(characterId, itemKey, qty)
    qty = qty or 1
    local total = MySQL.scalar.await(
        'SELECT COALESCE(SUM(quantity), 0) FROM rsl_inventory_items WHERE owner_character_id = ? AND item_key = ?',
        { characterId, itemKey }
    ) or 0
    return total >= qty
end

-- Consumes one unit of whatever is in `slot`. `consumeEffects` on the item
-- definition isn't applied to anything yet — the needs system (hunger/
-- thirst) doesn't exist as of this phase; it'll read RSLItems[...].
-- consumeEffects from here once it does.
---@param source integer
---@param slot integer
---@return boolean
local function useItemBySlot(source, slot)
    local characterId = exports['rsl_core']:GetActiveCharacterId(source)
    if not characterId then return false end
    slot = tonumber(slot)
    if not slot then return false end

    local row = MySQL.single.await(
        'SELECT id, item_key, quantity FROM rsl_inventory_items WHERE owner_character_id = ? AND slot = ?',
        { characterId, slot }
    )
    if not row then return false end
    local def = RSLItems[row.item_key]
    if not def or not def.usable then return false end

    if tonumber(row.quantity) <= 1 then
        MySQL.query.await('DELETE FROM rsl_inventory_items WHERE id = ?', { row.id })
    else
        MySQL.update.await('UPDATE rsl_inventory_items SET quantity = quantity - 1 WHERE id = ?', { row.id })
    end

    TriggerClientEvent('rsl_inventory:used', source, def.label)
    return true
end

RegisterNetEvent('rsl_inventory:requestInventory', function()
    local src = source
    local rows, weight = getInventory(src)
    TriggerClientEvent('rsl_inventory:list', src, rows, weight)
end)

RegisterNetEvent('rsl_inventory:moveItem', function(fromSlot, toSlot)
    local src = source
    local characterId = exports['rsl_core']:GetActiveCharacterId(src)
    if not characterId then return end
    fromSlot, toSlot = tonumber(fromSlot), tonumber(toSlot)
    if not fromSlot or not toSlot or fromSlot == toSlot then return end
    if fromSlot < 1 or fromSlot > RSLConfig.INVENTORY_SLOTS or toSlot < 1 or toSlot > RSLConfig.INVENTORY_SLOTS then return end

    local fromRow = MySQL.single.await(
        'SELECT id, item_key, quantity, metadata FROM rsl_inventory_items WHERE owner_character_id = ? AND slot = ?',
        { characterId, fromSlot }
    )
    if not fromRow then return end

    local toRow = MySQL.single.await(
        'SELECT id, item_key, quantity, metadata FROM rsl_inventory_items WHERE owner_character_id = ? AND slot = ?',
        { characterId, toSlot }
    )

    local merged = false
    if toRow and toRow.item_key == fromRow.item_key and toRow.metadata == '{}' and fromRow.metadata == '{}' then
        local def = RSLItems[fromRow.item_key]
        local combined = tonumber(fromRow.quantity) + tonumber(toRow.quantity)
        if def and combined <= def.maxStack then
            MySQL.update.await('UPDATE rsl_inventory_items SET quantity = ? WHERE id = ?', { combined, toRow.id })
            MySQL.query.await('DELETE FROM rsl_inventory_items WHERE id = ?', { fromRow.id })
            merged = true
        end
    end

    if not merged then
        if not toRow then
            MySQL.update.await('UPDATE rsl_inventory_items SET slot = ? WHERE id = ?', { toSlot, fromRow.id })
        else
            -- Swap. `slot` is UNIQUE(owner_character_id, slot) — stage
            -- through slot 0 (never a real slot, they're 1-indexed) so the
            -- two updates don't collide with each other mid-swap.
            MySQL.update.await('UPDATE rsl_inventory_items SET slot = 0 WHERE id = ?', { fromRow.id })
            MySQL.update.await('UPDATE rsl_inventory_items SET slot = ? WHERE id = ?', { fromSlot, toRow.id })
            MySQL.update.await('UPDATE rsl_inventory_items SET slot = ? WHERE id = ?', { toSlot, fromRow.id })
        end
    end

    local rows, weight = getInventory(src)
    TriggerClientEvent('rsl_inventory:list', src, rows, weight)
end)

RegisterNetEvent('rsl_inventory:useItem', function(slot)
    local src = source
    useItemBySlot(src, slot)
    local rows, weight = getInventory(src)
    TriggerClientEvent('rsl_inventory:list', src, rows, weight)
end)

-- No world pickup prop in this v1 — dropping just destroys the item. A
-- bigger feature than "general-purpose inventory" asked for; can extend
-- later if wanted.
RegisterNetEvent('rsl_inventory:dropItem', function(slot)
    local src = source
    local characterId = exports['rsl_core']:GetActiveCharacterId(src)
    if not characterId then return end
    slot = tonumber(slot)
    if not slot then return end

    MySQL.query.await('DELETE FROM rsl_inventory_items WHERE owner_character_id = ? AND slot = ?', { characterId, slot })

    local rows, weight = getInventory(src)
    TriggerClientEvent('rsl_inventory:list', src, rows, weight)
end)

---@param source integer
---@param itemKey string
---@param qty integer
---@param metadata table?
---@return boolean
local function addItemForPlayer(source, itemKey, qty, metadata)
    local characterId = exports['rsl_core']:GetActiveCharacterId(source)
    if not characterId then return false end
    return addItem(characterId, itemKey, qty, metadata)
end

---@param source integer
---@param itemKey string
---@param qty integer
---@return boolean
local function removeItemForPlayer(source, itemKey, qty)
    local characterId = exports['rsl_core']:GetActiveCharacterId(source)
    if not characterId then return false end
    return removeItem(characterId, itemKey, qty)
end

---@param source integer
---@param itemKey string
---@param qty integer?
---@return boolean
local function hasItemForPlayer(source, itemKey, qty)
    local characterId = exports['rsl_core']:GetActiveCharacterId(source)
    if not characterId then return false end
    return hasItem(characterId, itemKey, qty)
end

exports('GetInventory', getInventory)
exports('AddItem', addItemForPlayer)
exports('RemoveItem', removeItemForPlayer)
exports('HasItem', hasItemForPlayer)
exports('UseItem', useItemBySlot)
