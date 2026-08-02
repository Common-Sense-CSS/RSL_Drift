-- RSL spawn — client
-- Minimal first-join spawn using the base `spawnmanager` system resource.
-- Later phases can swap this for garage-based spawn-in-owned-vehicle logic.

CreateThread(function()
    exports.spawnmanager:addSpawnPoint({
        x = RSLConfig.DEFAULT_SPAWN.x,
        y = RSLConfig.DEFAULT_SPAWN.y,
        z = RSLConfig.DEFAULT_SPAWN.z,
        heading = RSLConfig.DEFAULT_SPAWN.w,
        model = 'a_m_y_business_02',
    })
    exports.spawnmanager:setAutoSpawn(true)
    exports.spawnmanager:forceRespawn()
end)
