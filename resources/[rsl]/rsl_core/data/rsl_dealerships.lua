-- RSL dealerships — shared.
-- `dealership_start` is confirmed on-ground by real testing. The rest are
-- UNVERIFIED placeholders picked from general map knowledge (real/likely
-- dealer-style spots) — test each in-game and report back corrected
-- coords/headings, same as dealership_start originally was.
-- `coords` is the interaction marker/blip; `spawnCoords` is where a
-- "drive now" purchase spawns (in front of the doors).

RSLDealerships = {
    {
        id = 'dealership_start',
        name = 'RSL Dealership',
        coords = vector3(-297.2243, -980.2850, 31.0806),
        spawnCoords = vector4(-297.2243, -980.2850, 31.0806, 160.0),
        defaultGarageId = 'sapcounsel',
    },
    -- UNVERIFIED placeholder, test in-game — Premium Deluxe Motorsport showroom
    {
        id = 'dealership_pdm',
        name = 'Premium Deluxe Motorsport',
        coords = vector3(-56.9, -1096.4, 26.4),
        spawnCoords = vector4(-46.0, -1096.4, 26.4, 210.0),
        defaultGarageId = 'pillboxgarage',
    },
    -- UNVERIFIED placeholder, test in-game — open lot near the docks
    {
        id = 'dealership_docks',
        name = 'Dockside Motors',
        coords = vector3(1000.0, -1090.0, 30.0),
        spawnCoords = vector4(1010.0, -1090.0, 30.0, 90.0),
        defaultGarageId = 'motelgarage',
    },
}
