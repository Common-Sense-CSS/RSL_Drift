-- RSL character select/creation — server net-event layer.
-- Thin wrapper around the character CRUD exports in player_data_s.lua; keeps
-- that file focused on the data layer and this one on the request/response
-- flow the character-select/creator NUI drives.

RegisterNetEvent('rsl_character:requestSlots', function()
    local src = source
    print(('^3[rsl_character]^7 requestSlots from #%d'):format(src))
    local ok, slots = pcall(function() return exports['rsl_core']:GetCharacterSlots(src) end)
    if not ok then
        print(('^1[rsl_character]^7 GetCharacterSlots errored: %s'):format(tostring(slots)))
        return
    end
    print(('^3[rsl_character]^7 sending %d slots to #%d'):format(#slots, src))
    TriggerClientEvent('rsl_character:slots', src, slots)
end)

RegisterNetEvent('rsl_character:select', function(characterId)
    local src = source
    if type(characterId) ~= 'string' then return end

    local character = exports['rsl_core']:SelectCharacter(src, characterId)
    if character then
        TriggerClientEvent('rsl_character:selected', src, character)
    else
        TriggerClientEvent('rsl_character:selectFailed', src, 'Could not load that character.')
    end
end)

RegisterNetEvent('rsl_character:create', function(slotIndex, name, model, appearance)
    local src = source
    if type(slotIndex) ~= 'number' or type(name) ~= 'string' or type(model) ~= 'string' then return end

    local character = exports['rsl_core']:CreateCharacter(src, slotIndex, name, model, appearance)
    if character then
        TriggerClientEvent('rsl_character:selected', src, character)
    else
        TriggerClientEvent('rsl_character:selectFailed', src, 'Could not create that character.')
    end
end)

RegisterNetEvent('rsl_character:delete', function(characterId)
    local src = source
    if type(characterId) ~= 'string' then return end

    exports['rsl_core']:DeleteCharacter(src, characterId)
    local slots = exports['rsl_core']:GetCharacterSlots(src)
    TriggerClientEvent('rsl_character:slots', src, slots)
end)
