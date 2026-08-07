-- RSL item registry — shared.
-- Definitions live here, not in the DB — inventory rows only store an
-- `item_key` + quantity + metadata, everything else is looked up from this
-- table. Add tuning parts, event rewards, etc. here later; no schema change
-- needed. `consumeEffects` isn't wired to anything yet — the needs system
-- (hunger/thirst) doesn't exist yet, that phase will read it from here once
-- it does.

RSLItems = {
    water_bottle = {
        label = 'Water Bottle',
        description = 'Refreshing. Quenches thirst.',
        weight = 0.5,
        maxStack = 10,
        usable = true,
        category = 'food',
        consumeEffects = { thirst = 40 },
    },
    energy_drink = {
        label = 'Energy Drink',
        description = 'Sugar rush. Mostly thirst, a little hunger.',
        weight = 0.5,
        maxStack = 10,
        usable = true,
        category = 'food',
        consumeEffects = { thirst = 25, hunger = 5 },
    },
    burger = {
        label = 'Burger',
        description = 'Fast food. Filling.',
        weight = 0.6,
        maxStack = 10,
        usable = true,
        category = 'food',
        consumeEffects = { hunger = 45 },
    },
    sandwich = {
        label = 'Sandwich',
        description = 'Quick bite.',
        weight = 0.4,
        maxStack = 10,
        usable = true,
        category = 'food',
        consumeEffects = { hunger = 30 },
    },
    chips = {
        label = 'Chips',
        description = 'Salty snack.',
        weight = 0.2,
        maxStack = 15,
        usable = true,
        category = 'food',
        consumeEffects = { hunger = 15 },
    },
}
