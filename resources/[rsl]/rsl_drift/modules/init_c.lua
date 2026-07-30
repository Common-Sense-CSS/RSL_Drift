-- rsl_drift — client bootstrap
-- Placeholder for phase 1: confirms rsl_core exports are reachable.
-- Drift zones, scoring, tandem detection, ghosts, and tuning land in later phases.

CreateThread(function()
    Wait(1000)
    exports['rsl_core']:ShowNotification({
        title = 'RSL Drift loaded — drift systems coming in a later phase.',
        type = 'info',
    })
end)
