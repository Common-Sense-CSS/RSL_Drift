-- RSL garages — shared.
-- Coordinates sit close to RSLConfig.DEFAULT_SPAWN (confirmed on-ground) to
-- minimize the odds of an unverified location dropping a vehicle underground.
-- Vehicles are still placed with PlaceObjectOnGroundProperly on spawn as a
-- safety net regardless.

RSLGarages = {
    {
        id = 'garage_start',
        name = 'RSL Garage',
        coords = vector3(-252.6908, -1008.1157, 29.0049),
        spawnCoords = vector4(-252.6908, -1008.1157, 29.0049, 244.8474),
    },
}
