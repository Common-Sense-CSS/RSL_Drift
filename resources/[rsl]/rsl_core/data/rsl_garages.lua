-- RSL garages — shared.
-- Coordinates supplied directly by the user (adapted from an existing,
-- tested config) — treated as ground truth, not placeholders. Each entry's
-- `coords` is the single interaction point (take out AND store happen from
-- here); `spawnCoords` is where a taken-out vehicle appears.
-- Vehicles are still placed with PlaceObjectOnGroundProperly on spawn as a
-- safety net regardless.

RSLGarages = {
    { id = 'motelgarage',      name = 'Motel Parking',            coords = vector3(273.43, -343.99, 44.91),      spawnCoords = vector4(270.94, -342.96, 43.97, 161.5) },
    { id = 'sapcounsel',       name = 'San Andreas Parking',       coords = vector3(-330.01, -780.33, 33.96),     spawnCoords = vector4(-334.44, -780.75, 33.96, 137.5) },
    { id = 'spanishave',       name = 'Spanish Ave Parking',       coords = vector3(-1160.86, -741.41, 19.63),    spawnCoords = vector4(-1163.88, -749.32, 18.42, 35.5) },
    { id = 'caears24',         name = 'Caears 24 Parking',         coords = vector3(69.84, 12.6, 68.96),          spawnCoords = vector4(73.21, 10.72, 68.83, 163.5) },
    { id = 'caears242',        name = 'Caears 24 Parking (2)',     coords = vector3(-475.31, -818.73, 30.46),     spawnCoords = vector4(-472.03, -815.47, 30.5, 177.5) },
    { id = 'lagunapi',         name = 'Laguna Parking',            coords = vector3(364.37, 297.83, 103.49),      spawnCoords = vector4(367.49, 297.71, 103.43, 340.5) },
    { id = 'airportp',         name = 'Airport Parking',           coords = vector3(-796.86, -2024.85, 8.88),     spawnCoords = vector4(-800.41, -2016.53, 9.32, 48.5) },
    { id = 'beachp',           name = 'Beach Parking',             coords = vector3(-1183.1, -1511.11, 4.36),     spawnCoords = vector4(-1181.0, -1505.98, 4.37, 214.5) },
    { id = 'themotorhotel',    name = 'The Motor Hotel Parking',   coords = vector3(1137.77, 2663.54, 37.9),      spawnCoords = vector4(1137.69, 2673.61, 37.9, 359.5) },
    { id = 'liqourparking',    name = 'Liqour Parking',            coords = vector3(934.95, 3606.59, 32.81),      spawnCoords = vector4(941.57, 3619.99, 32.5, 141.5) },
    { id = 'shoreparking',     name = 'Shore Parking',             coords = vector3(1726.21, 3707.16, 34.17),     spawnCoords = vector4(1730.31, 3711.07, 34.2, 20.5) },
    { id = 'haanparking',      name = 'Bell Farms Parking',        coords = vector3(78.34, 6418.74, 31.28),       spawnCoords = vector4(70.71, 6425.16, 30.92, 68.5) },
    { id = 'dumbogarage',      name = 'Dumbo Private Parking',     coords = vector3(157.26, -3240.00, 7.00),      spawnCoords = vector4(165.32, -3236.10, 5.93, 268.5) },
    { id = 'pillboxgarage',    name = 'Pillbox Garage Parking',    coords = vector3(215.9499, -809.698, 30.731),  spawnCoords = vector4(234.1942, -787.066, 30.193, 159.6) },

    -- Originally job-restricted (gang garages); used as normal open garages here — RSL has no gang/job system.
    { id = 'ballasgarage',     name = 'Ballas',                    coords = vector3(98.50, -1954.49, 20.84),      spawnCoords = vector4(98.50, -1954.49, 20.75, 335.73) },
    { id = 'la_familiagarage', name = 'La Familia',                coords = vector3(-811.65, 187.49, 72.48),      spawnCoords = vector4(-818.43, 184.97, 72.28, 107.85) },
    { id = 'the_lostgarage',   name = 'Lost MC',                   coords = vector3(957.25, -129.63, 74.39),      spawnCoords = vector4(957.25, -129.63, 74.39, 199.21) },
    { id = 'cartelgarage',     name = 'Cartel',                    coords = vector3(1407.18, 1118.04, 114.84),    spawnCoords = vector4(1407.18, 1118.04, 114.84, 88.34) },

    -- Originally a depot (fixed loaner spawn, no storage concept); used as a normal garage here.
    { id = 'hayesdepot',       name = 'Hayes Depot',               coords = vector3(491.0, -1314.69, 29.25),      spawnCoords = vector4(491.0, -1314.69, 29.25, 304.5) },
}
