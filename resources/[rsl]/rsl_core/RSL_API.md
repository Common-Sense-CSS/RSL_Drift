# RSL Core — Developer API

`rsl_core` is the standalone framework powering the RSL Drift server. It owns
player identity, the economy, XP/leveling, notifications, the HUD, and the
game-state machine. `rsl_drift` and any other add-on resource talk to it only
through the exports below — never through direct database access.

```lua
-- client or server
local cash = exports['rsl_core']:GetPlayerCash(source)
```

This file covers **Phase 1-2** exports (framework skeleton, garage/dealership,
admin commands). Drift scoring/leaderboard exports land as later phases ship.

---

## Client Exports

### Game State

| Export | Params | Returns | Description |
|--------|--------|---------|-------------|
| `RegisterGameState(id, def)` | string id, `{ onEnter?, onExit?, onTick?, tickWait? }` | `boolean` | Register a state (built-ins already registered — see `GameState` table). |
| `SetGameState(id)` | string id | `boolean` | Transition to a registered state. |
| `GetGameState()` | | `string?` | Current client-side state id. |

Built-in state ids live in the global `GameState` table (`modules/core/game_state_sh.lua`):
`FREEROAM`, `GARAGE`, `DEALERSHIP`, `TUNING_SHOP`, `DRIFT_EVENT`, `DRIFT_LOBBY`, `DRIFT_BATTLE`.

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
| `HasPlayerLoaded(source)` | server id | `boolean` | Whether the player's profile finished loading. Guard other exports behind this. |
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

Vehicle rows live in `rsl_vehicles` (see `sql/schema.sql`), each owned by a player identifier. `mods`/`tuning` JSON columns exist for later phases and are currently always `{}`.

| Export | Params | Returns | Description |
|--------|--------|---------|-------------|
| `GetOwnedVehicles(source)` | server id | `table[]` | All vehicles owned by the player: `{ id, model, plate, garage_id, stored, xp, level }`. |
| `AddVehicleToGarage(identifier, model, garageId)` | license identifier, model name, garage id | `string` vehicle id | Creates a new owned vehicle (stored) with a unique plate. Used by the dealership; add-ons can also grant vehicles directly (e.g. event rewards). |

Garage locations are defined in `data/rsl_garages.lua` (`RSLGarages`, shared). Dealership locations and the vehicle catalog are in `data/rsl_dealerships.lua` (`RSLDealerships`) and `data/rsl_vehicles.lua` (`RSLVehicles`), both shared — add-ons can read them directly rather than through an export.

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
