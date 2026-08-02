-- RSL spawn — client
-- Minimal first-join spawn using the base `spawnmanager` system resource.
-- Later phases can swap this for garage-based spawn-in-owned-vehicle logic.
--
-- IMPORTANT: `basic-gamemode` (one of the base CFX system resources) also
-- registers its own spawn points with spawnmanager. If we used
-- addSpawnPoint + setAutoSpawn(true), spawnmanager would randomly pick
-- between its points and ours. Calling spawnPlayer directly bypasses that
-- pool entirely and spawns exactly where we say, every time.

CreateThread(function()
    exports.spawnmanager:setAutoSpawn(false)

    exports.spawnmanager:spawnPlayer({
        x = RSLConfig.DEFAULT_SPAWN.x,
        y = RSLConfig.DEFAULT_SPAWN.y,
        z = RSLConfig.DEFAULT_SPAWN.z,
        heading = RSLConfig.DEFAULT_SPAWN.w,
        model = 'a_m_y_business_02',
    })
end)
