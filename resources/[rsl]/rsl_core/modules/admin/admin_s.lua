-- RSL admin commands — server
-- All commands are registered "restricted" (the trailing `true`), which
-- requires the `command.<name>` ACE permission — see server.cfg for how to
-- grant that to your admin group.

local function reply(source, ok, message)
    TriggerClientEvent('chat:addMessage', source, { args = { ok and '^2RSL' or '^1RSL', message } })
end

RegisterCommand('givecash', function(source, args)
    local targetId, amount = tonumber(args[1]), tonumber(args[2])
    if not targetId or not amount then
        reply(source, false, 'Usage: /givecash [id] [amount]')
        return
    end
    local ok = exports['rsl_core']:AddPlayerCash(targetId, amount)
    reply(source, ok, ok and ('Gave $%d to #%d'):format(amount, targetId) or 'Invalid target or amount')
end, true)

RegisterCommand('setlevel', function(source, args)
    local targetId, level = tonumber(args[1]), tonumber(args[2])
    if not targetId or not level then
        reply(source, false, 'Usage: /setlevel [id] [level]')
        return
    end
    local ok = exports['rsl_core']:SetPlayerLevel(targetId, level)
    reply(source, ok, ok and ('Set #%d to level %d'):format(targetId, level) or 'Invalid target or level')
end, true)

RegisterCommand('car', function(source, args)
    local model = args[1]
    if not model then
        reply(source, false, 'Usage: /car [model]')
        return
    end
    TriggerClientEvent('rsl_admin:spawnCar', source, model)
end, true)

RegisterCommand('tp', function(source, args)
    local x, y, z = tonumber(args[1]), tonumber(args[2]), tonumber(args[3])
    if not (x and y and z) then
        reply(source, false, 'Usage: /tp [x] [y] [z]')
        return
    end
    TriggerClientEvent('rsl_admin:teleport', source, x, y, z)
end, true)

RegisterCommand('deletevehicle', function(source)
    TriggerClientEvent('rsl_admin:deleteVehicle', source)
end, true)
