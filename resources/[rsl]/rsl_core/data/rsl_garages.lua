-- RSL garages — shared.
-- `garage_start` sits close to RSLConfig.DEFAULT_SPAWN and is confirmed
-- on-ground by real testing. The rest are UNVERIFIED placeholders picked
-- from general map knowledge (common Los Santos parking garages/lots) — test
-- each in-game and report back corrected coords/headings, same as
-- garage_start originally was.
-- Vehicles are still placed with PlaceObjectOnGroundProperly on spawn as a
-- safety net regardless.

RSLGarages = {
    {
        id = 'garage_start',
        name = 'RSL Garage',
        coords = vector3(-252.6908, -1008.1157, 29.0049),
        spawnCoords = vector4(-252.6908, -1008.1157, 29.0049, 244.8474),
    },
    -- UNVERIFIED placeholder, test in-game — Textile City multi-story car park
    {
        id = 'garage_textile',
        name = 'Textile City Parking',
        coords = vector3(-211.7, -814.8, 30.3),
        spawnCoords = vector4(-211.7, -814.8, 30.3, 300.0),
    },
    -- UNVERIFIED placeholder, test in-game — Rockford Hills lot
    {
        id = 'garage_rockford',
        name = 'Rockford Hills Garage',
        coords = vector3(-629.9, -853.7, 27.3),
        spawnCoords = vector4(-629.9, -853.7, 27.3, 30.0),
    },
    -- UNVERIFIED placeholder, test in-game — Vespucci Beach lot
    {
        id = 'garage_vespucci',
        name = 'Vespucci Garage',
        coords = vector3(-1197.0, -1461.0, 4.35),
        spawnCoords = vector4(-1197.0, -1461.0, 4.35, 30.0),
    },
}
