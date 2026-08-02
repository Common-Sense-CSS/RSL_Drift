# RSL Drift Server

A FiveM drift server running on **RSL**, a custom-built framework (not
ESX/QBCore). See `resources/[rsl]/rsl_core/RSL_API.md` for the framework's
export API.

## Status

Phase 1 (framework skeleton) and Phase 2 (vehicles & progression) are complete:

- `rsl_core` — player identity/economy/XP, game-state machine, notifications,
  HUD, garage, dealership, and admin commands (see `RSL_API.md`).
- `rsl_drift` — scaffolded, depends on `rsl_core`, no drift gameplay yet.

Drift scoring & zones, tandem detection, leaderboards/ghosts, tuning, and the
tablet/drift-battle UI land in later phases.

## Setup

1. **FXServer artifacts** — download the latest FiveM server artifact for
   your platform from https://runtime.fivem.net/artifacts/fivem/build_server_windows/master/
   and place it in this folder (or point your run script at this folder as
   the server root — `+set citizen_dir "..."`, `+exec server.cfg`).

2. **Base CFX system resources** — `mapmanager`, `chat`, `spawnmanager`,
   `sessionmanager`, `basic-gamemode`, `hardcap`, `rconlog`. These are **not**
   bundled in the FXServer artifact. Download
   [`citizenfx/cfx-server-data`](https://github.com/citizenfx/cfx-server-data)
   and copy its `resources/` folder into `resources/[cfx]/` here. Without
   these, clients hang indefinitely on "awaiting scripts".

3. **Third-party dependencies** — this project intentionally depends on two
   community utility libraries (not frameworks): download the latest releases
   and drop them into `resources/`:
   - [`ox_lib`](https://github.com/overextended/ox_lib)
   - [`oxmysql`](https://github.com/overextended/oxmysql)

4. **Database** — create a MySQL/MariaDB database (e.g. `rsl_drift`). Tables
   are created automatically on first start by `rsl_core`
   (`resources/[rsl]/rsl_core/sql/schema.sql`), so you don't need to import
   anything manually — just make sure the database itself exists.

5. **Configure `server.cfg`**:
   - Set `sv_licenseKey` (get one at https://keymaster.fivem.net/).
   - Set the `mysql_connection_string` convar to your database credentials.
   - Uncomment and fill in the `add_principal`/`add_ace` lines at the bottom
     to grant yourself admin commands (see `RSL_API.md`).

6. **Start the server** (e.g. `FXServer.exe +exec server.cfg` on Windows).

## Deploying via txAdmin recipe

This repo doubles as a **txAdmin recipe** (`recipe.yaml`) — the same mechanism
QBCore/ox_core use — so a fresh server can be stood up from txAdmin's
Deployer instead of doing the manual setup above.

1. Push this entire `RSL Drift server/` folder to the repo root of
   **https://github.com/Common-Sense-CSS/RSL_Drift** on the `main` branch
   (`server.cfg`, `recipe.yaml`, `resources/[rsl]/...` all need to be at the
   repo root — this repo folder *is* the repo).
2. In txAdmin, start the **Setup / Deployer**, choose "custom recipe", and
   paste the raw recipe URL:
   `https://raw.githubusercontent.com/Common-Sense-CSS/RSL_Drift/main/recipe.yaml`
3. Follow the deployer prompts (server name, license key, database
   credentials, slot count) — it downloads `ox_lib`/`oxmysql`, pulls
   `rsl_core`/`rsl_drift` from this repo, generates `server.cfg`, and creates
   the database schema automatically.

The recipe always fetches `rsl_core`/`rsl_drift` fresh from GitHub, so keep
`main` pushed to whatever you want newly-deployed servers to run — it does
**not** read from your local disk.

## Project layout

```
RSL Drift server/          -- also the root of the Common-Sense-CSS/RSL_Drift repo
  server.cfg
  recipe.yaml               -- txAdmin recipe
  .gitignore
  resources/
    [rsl]/
      rsl_core/    -- the framework
      rsl_drift/   -- drift gameplay, built on rsl_core's exports
```

## Configuration

- `resources/[rsl]/rsl_core/data/rsl_config.lua` — starting cash, save
  interval, speed unit (mph/kmh), default spawn point, XP curve.
