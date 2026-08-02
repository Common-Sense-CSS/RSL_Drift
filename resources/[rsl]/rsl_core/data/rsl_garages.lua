-- RSL garages — shared.
-- Coordinates sit close to RSLConfig.DEFAULT_SPAWN (confirmed on-ground) to
-- minimize the odds of an unverified location dropping a vehicle underground.
-- Vehicles are still placed with PlaceObjectOnGroundProperly on spawn as a
-- safety net regardless.

RSLGarages = {
    {
        id = 'garage_start',
        name = 'RSL Garage',
        coords = vector3(-206.0, -1010.0, 24.35),
        spawnCoords = vector4(-200.0, -1005.0, 24.35, 40.0),
    },
}
