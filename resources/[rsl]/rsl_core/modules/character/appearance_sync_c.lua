-- RSL character appearance — sync
-- Every client applies its own appearance locally the moment it's chosen
-- (see character_select_c.lua). This handler is what makes OTHER players'
-- peds render correctly too: each client sets an `rsl:appearance` entity
-- state bag on spawn (replicated, since sv_stateBagStrictMode only blocks
-- client writes — server/self writes still propagate normally), and every
-- client applies whatever appearance shows up on any ped's state bag.

AddStateBagChangeHandler('rsl:appearance', '', function(bagName, _key, value)
    if type(value) ~= 'table' then return end

    local entity = GetEntityFromStateBagName(bagName)
    if entity == 0 or entity == PlayerPedId() then return end

    RSLAppearance.Apply(entity, value.model, value.appearance)
end)
