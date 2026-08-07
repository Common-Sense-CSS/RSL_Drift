# RSL Core — Developer API

`rsl_core` is the standalone framework powering the RSL Drift server. It owns
player identity, the economy, XP/leveling, notifications, the HUD, and the
game-state machine. `rsl_drift` and any other add-on resource talk to it only
through the exports below — never through direct database access.

```lua
-- client or server
local cash = exports['rsl_core']:GetPlayerCash(source)
```

This file covers **Phase 1-2 + the character system** (framework skeleton,
garage/dealership, admin commands, multi-character accounts). Inventory and
the status/needs HUD land next; drift scoring/leaderboard exports land as
later phases ship.

**Accounts vs. characters:** a license identifier can hold up to
`RSLConfig.CHARACTER_SLOTS` (3) characters. Nothing is "the active player"
until one is selected or created via the character-select/creator flow — all
economy/progression/data exports below operate on whichever character is
currently active for `source`, and return empty/failure values before that.

---

## Client Exports

### Game State

| Export | Params | Returns | Description |
|--------|--------|---------|-------------|
| `RegisterGameState(id, def)` | string id, `{ onEnter?, onExit?, onTick?, tickWait? }` | `boolean` | Register a state (built-ins already registered — see `GameState` table). |
| `SetGameState(id)` | string id | `boolean` | Transition to a registered state. |
| `GetGameState()` | | `string?` | Current client-side state id. |

Built-in state ids live in the global `GameState` table (`modules/core/game_state_sh.lua`):
`MAIN_MENU`, `AVATAR`, `FREEROAM`, `GARAGE`, `DEALERSHIP`, `TUNING_SHOP`, `DRIFT_EVENT`, `DRIFT_LOBBY`, `DRIFT_BATTLE`.
Every session starts in `MAIN_MENU` (character select) — `rsl_core` owns the
`MAIN_MENU`/`AVATAR` states itself (character_select_c.lua/character_creator_c.lua);
add-ons shouldn't re-register them.

```lua
exports['rsl_core']:RegisterGameState('my_addon_state', {
    onEnter = function(prevState) end,
    onExit  = function(nextState) end,
    onTick  = function() end,
    tickWait = 0,
})
exports['rsl_core']:SetGameState('my_addon_state')
```

Listen for `rsl_core:gameStateChanged` (client event, payload `newState, previousState`) instead of owning transition logic yourself.

### Notifications

| Export | Params | Description |
|--------|--------|-------------|
| `ShowNotification(options)` | `{ title, type?, duration? }` | Toast notification. `type` is `'info'` (default) \| `'success'` \| `'error'` \| `'warning'`. `duration` in ms (default 3500). |

```lua
exports['rsl_core']:ShowNotification({ title = 'Run saved!', type = 'success' })
```

### HUD

| Export | Params | Returns | Description |
|--------|--------|---------|-------------|
| `SetHudEnabled(on)` | `boolean` | `boolean` | Show/hide the built-in speedometer HUD, e.g. while a custom drift-score overlay owns the screen. |

---

## Server Exports

### Economy

| Export | Params | Returns | Description |
|--------|--------|---------|-------------|
| `HasPlayerLoaded(source)` | server id | `boolean` | Whether the player has an **active character** (selected or just created) — not just connected. Guard other exports behind this. |
| `GetPlayerCash(source)` | server id | `number` | Current cash balance (0 if not loaded). |
| `AddPlayerCash(source, amount)` | server id, amount | `boolean` | Add cash. `false` if not loaded or invalid amount. |
| `RemovePlayerCash(source, amount)` | server id, amount | `boolean` | Remove cash. `false` if not loaded, invalid amount, or insufficient funds. |
| `SetPlayerCash(source, amount)` | server id, amount | `boolean` | Set cash to an absolute value (admin/testing use). `false` if not loaded or negative amount. |

### Progression

| Export | Params | Returns | Description |
|--------|--------|---------|-------------|
| `GetPlayerLevel(source)` | server id | `integer` | Current level (1 if not loaded). |
| `SetPlayerLevel(source, level)` | server id, level | `boolean` | Set level directly, recalculating XP to match (admin/testing use). `false` if not loaded or out of range. |
| `GetPlayerXp(source)` | server id | `integer` | Current total XP. |
| `AwardPlayerXp(source, amount)` | server id, amount | `table?` | `{ xpGained, oldLevel, newLevel, levelUps }`, or `nil` if not loaded / invalid amount. |

```lua
local result = exports['rsl_core']:AwardPlayerXp(source, 150)
if result and result.levelUps > 0 then
    TriggerClientEvent('myAddon:levelUp', source, result.newLevel)
end
```

### Player Data

Arbitrary per-player JSON storage for add-ons (settings, unlocks, custom stats), addressed by dot-path.

| Export | Params | Returns | Description |
|--------|--------|---------|-------------|
| `ReadPlayerData(source, path)` | server id, dot-path string | `any` | Read a value, e.g. `'myAddon.favoriteZone'`. |
| `WritePlayerData(source, path, value)` | server id, dot-path string, value | `boolean` | Write a value. Creates intermediate tables as needed. |
| `PersistPlayer(source)` | server id | `boolean` | Force an immediate flush to the database (normally happens on an interval and on disconnect). |

```lua
exports['rsl_core']:WritePlayerData(source, 'myAddon.favoriteZone', 'docks_01')
local zone = exports['rsl_core']:ReadPlayerData(source, 'myAddon.favoriteZone')
```

### Game State (Server)

| Export | Params | Returns | Description |
|--------|--------|---------|-------------|
| `GetPlayerGameState(source)` | server id | `string?` | The player's last-reported client-side game state. |

### Garage / Vehicles

Vehicle rows live in `rsl_vehicles` (see `sql/schema.sql`), each owned by a **character id** (not an account). `mods`/`tuning` JSON columns exist for later phases and are currently always `{}`. A vehicle's `garage_id` is assigned once, at creation, and never changes — taking it out and storing it again just toggles `stored` within that same garage.

Each garage holds at most `RSLConfig.GARAGE_MAX_VEHICLES` (15) vehicles **per character** — counted across both stored and currently-out vehicles, since `garage_id` is permanent. Only one vehicle can be "out" per character at a time: requesting a different one auto-stores whichever vehicle is currently out, back at its own garage (this is what `SpawnOwnedVehicle` below handles).

Garage names are personal nicknames — each character can optionally rename any garage for themselves (stored in their own `data` JSON via `WritePlayerData`, path `garageNames.<garageId>`); other characters/players still see the default name from `RSLGarages` unless they've set their own.

| Export | Params | Returns | Description |
|--------|--------|---------|-------------|
| `GetOwnedVehicles(source)` | server id | `table[]` | All vehicles owned by the player's active character: `{ id, model, plate, garage_id, stored, xp, level }`. |
| `AddVehicleToGarage(characterId, model, garageId)` | character id, model name, garage id | `string` vehicle id | Creates a new owned vehicle (stored) with a unique plate. Used by the dealership; add-ons can also grant vehicles directly (e.g. event rewards) — get the character id via `GetActiveCharacterId(source)`. Does **not** check garage capacity itself — callers that let a player pick the garage (like the dealership) should check `GetGarageVehicleCount` first. |
| `SpawnOwnedVehicle(source, characterId, vehicleId, coordsOverride?)` | server id, character id, vehicle id, `vector4?` | | Spawns an owned vehicle for the player — at `coordsOverride` if given, else its garage's `spawnCoords`. Auto-stores any other vehicle the character currently has out first. Used by the garage take-out flow and the dealership's "drive now" purchase. |
| `GetGarageVehicleCount(characterId, garageId)` | character id, garage id | `integer` | Total vehicles (stored or out) that character has assigned to that garage — compare against `RSLConfig.GARAGE_MAX_VEHICLES` before adding another. |
| `GetGarageName(source, garageId)` | server id, garage id | `string` | The garage's effective name for that player — their personal nickname if they've set one, else the default from `RSLGarages`. |

Garage locations are defined in `data/rsl_garages.lua` (`RSLGarages`, shared) — each entry is `{ id, name, coords, spawnCoords }`. Dealership locations and the vehicle catalog are in `data/rsl_dealerships.lua` (`RSLDealerships`, each `{ id, name, coords, spawnCoords }`) and `data/rsl_vehicles.lua` (`RSLVehicles`, each entry has a `category` used for the dealership's filter tabs), both shared — add-ons can read them directly rather than through an export.

At the dealership, every purchase requires the player to pick a real garage — there's no default. Purchases carry a `mode`: `'drive'` still spawns the car immediately at the dealership's `spawnCoords`, but its `garage_id` is the chosen garage (so a later auto-swap — see `SpawnOwnedVehicle` above — has a real home to return it to instead of a fixed default); `'garage'` sends it (stored) straight to the chosen garage. Either way it's rejected before any cash is taken if that garage is already at capacity.

### Characters

| Export | Params | Returns | Description |
|--------|--------|---------|-------------|
| `GetCharacterSlots(source)` | server id | `table[]` | The account's `RSLConfig.CHARACTER_SLOTS` slots: `{ slotIndex, occupied, id?, name?, model?, level? }`. |
| `SelectCharacter(source, characterId)` | server id, character id | `table?` | Activates an owned character, returns its full row (including decoded `appearance`/`data`), or `nil` if not owned. |
| `CreateCharacter(source, slotIndex, name, model, appearance)` | server id, slot 1-N, name, `'mp_m_freemode_01'`\|`'mp_f_freemode_01'`, appearance table | `table?` | Creates + activates a character in an empty slot. `appearance` is run through `RSLCharacterOptions.SanitizeAppearance` server-side — never trust it as-is. `nil` if the slot is taken or inputs are invalid. |
| `DeleteCharacter(source, characterId)` | server id, character id | `boolean` | Deletes an owned character. Cascades to their vehicles and (later) drift scores/inventory. |
| `GetActiveCharacterId(source)` | server id | `string?` | The active character's id, for add-ons that need to key their own tables off it (as `rsl_vehicles` does). |

Shared (`data/rsl_character_options.lua`): `RSLCharacterOptions.DefaultAppearance(model)` and `RSLCharacterOptions.SanitizeAppearance(raw, model)` define and clamp the appearance table shape (head blend, 20 face features, hair, overlays, clothing) — reuse these rather than hand-rolling appearance validation.

Client-side, `RSLAppearance.Apply(ped, model, appearance)` (`modules/character/appearance_c.lua`) applies an appearance table to any ped — self, a preview, or (via `modules/character/appearance_sync_c.lua`'s `rsl:appearance` state bag handler) another player's.

---

## Events

| Event | Side | Payload | Description |
|-------|------|---------|-------------|
| `rsl_core:gameStateChanged` | client | `newState, previousState` | Fired after a successful `SetGameState`. |
| `rsl_core:cashUpdated` | client | `newCash` | Fired to a specific player after their cash changes. |
| `rsl_core:xpUpdated` | client | `newXp, newLevel, result` | Fired to a specific player after `AwardPlayerXp`/`SetPlayerLevel`. |

---

## Admin Commands

Registered restricted (require the `command.<name>` ACE permission — see the commented block near the bottom of `server.cfg` for how to grant it to your admin group):

| Command | Usage | Description |
|---------|-------|-------------|
| `/givecash` | `/givecash [id] [amount]` | Add cash to a player. |
| `/setlevel` | `/setlevel [id] [level]` | Set a player's level directly. |
| `/car` | `/car [model]` | Spawn a vehicle in front of yourself (any model, not tied to ownership). |
| `/tp` | `/tp [x] [y] [z]` | Teleport yourself to coordinates. |
| `/deletevehicle` | `/deletevehicle` | Delete the vehicle you're currently in. |
