-- RSL vehicle catalog — shared.
-- Curated set of drift-viable GTA5 vehicles. `category` is used to group the
-- dealership UI. AWD entries are included because the Phase 5 tuning editor
-- lets players push drive bias toward RWD — not everything here is stock-RWD.

RSLVehicles = {
    -- starter
    futo     = { label = 'Futo',          brand = 'Karin',    price = 9000,   category = 'starter' },
    blista   = { label = 'Blista',        brand = 'Dinka',    price = 8000,   category = 'starter' },

    -- sport
    sultan   = { label = 'Sultan',        brand = 'Karin',    price = 22000,  category = 'sport' },
    buffalo  = { label = 'Buffalo',       brand = 'Bravado',  price = 18000,  category = 'sport' },
    buffalo2 = { label = 'Buffalo S',     brand = 'Bravado',  price = 27000,  category = 'sport' },
    jester3  = { label = 'Jester Classic',brand = 'Dinka',    price = 32000,  category = 'sport' },
    comet2   = { label = 'Comet',         brand = 'Pfister',  price = 35000,  category = 'sport' },
    banshee  = { label = 'Banshee',       brand = 'Bravado',  price = 38000,  category = 'sport' },
    calico   = { label = 'Calico GTF',    brand = 'Karin',    price = 30000,  category = 'sport' },

    -- muscle
    dominator  = { label = 'Dominator',            brand = 'Vapid',   price = 26000, category = 'muscle' },
    dominator2 = { label = 'Dominator Pisswasser',  brand = 'Vapid',   price = 34000, category = 'muscle' },
    gauntlet   = { label = 'Gauntlet',              brand = 'Bravado', price = 24000, category = 'muscle' },

    -- drift icons
    sultanrs = { label = 'Sultan RS',    brand = 'Karin',   price = 55000,  category = 'icon' },
    tampa3   = { label = 'Drift Tampa',  brand = 'Declasse',price = 60000,  category = 'icon' },
    remus2   = { label = 'Remus',        brand = 'Annis',   price = 65000,  category = 'icon' },
    euros    = { label = 'Euros',        brand = 'Annis',   price = 50000,  category = 'icon' },
}
