-- RSL notifications — client
-- exports['rsl_core']:ShowNotification({ title = '...', type = 'info'|'success'|'error'|'warning', duration = 3500 })

---@param options { title: string, type: string?, duration: integer? }
local function showNotification(options)
    if type(options) ~= 'table' or type(options.title) ~= 'string' then return end
    SendNUIMessage({
        action = 'notify:show',
        title = options.title,
        type = options.type or 'info',
        duration = options.duration or 3500,
    })
end

exports('ShowNotification', showNotification)
