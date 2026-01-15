# Minecraft Bedrock Server

A containerized Minecraft Bedrock Dedicated Server using Docker Compose, configured for family and friends gameplay with customized settings and world generation.

## Overview

This project runs a Minecraft Bedrock Edition server using the [itzg/minecraft-bedrock-server](https://github.com/itzg/docker-minecraft-bedrock-server) Docker image. The server is configured for:

- **Survival gameplay** on easy difficulty
- **Family-friendly environment** with PVP disabled
- **Allowlist-based access control** for approved players
- **Custom world generation** with a specific seed
- **Automatic updates** to the latest Bedrock server version

## Environment Variables

All configuration is managed through environment variables. Sensitive values are stored in `.env` (not committed to source control). Copy [.env.example](.env.example) to `.env` and configure your UID/GID (run `id`), allowlist users with XUIDs ([MCProfile](https://mcprofile.io/)), operators, and server/world settings.

### Container & Server Configuration

| Variable | Value | Description |
| --- | --- | --- |
| `EULA` | `TRUE` | Accepts the [Minecraft EULA](https://minecraft.net/terms) (required) |
| `TZ` | `America/New_York` | Server timezone for logs and timestamps |
| `VERSION` | `LATEST` | Auto-upgrades to the latest stable Bedrock server version |
| `UID` | `.env` | User ID to run the server process (matches host user) |
| `GID` | `.env` | Group ID to run the server process (matches host group) |
| `PACKAGE_BACKUP_KEEP` | `2` | Number of previous server version backups to retain |
| `ALLOW_LIST` | `true` | Only players on the allowlist can join |
| `ALLOW_LIST_USERS` | `.env` | Comma-separated list of `gamertag:xuid` pairs |
| `OPS` | `.env` | Comma-separated XUIDs of server operators |
| `ONLINE_MODE` | `true` | Requires Xbox Live authentication (recommended for security) |
| `ENABLE_LAN_VISIBILITY` | `true` | Server appears in LAN game discovery |
| `VIEW_DISTANCE` | `10` | Maximum view distance in chunks (client render distance) |
| `TICK_DISTANCE` | `4` | Simulation distance in chunks (affects mob AI, redstone, etc.) |
| `MAX_PLAYERS` | `6` | Maximum concurrent players allowed |
| `CONTENT_LOG_FILE_ENABLED` | `true` | Enables logging content errors to file |
| `CONTENT_LOG_LEVEL` | `info` | Log verbosity level |
| `CONTENT_LOG_CONSOLE_OUTPUT_ENABLED` | `true` | Outputs content logs to console |
| `EMIT_SERVER_TELEMETRY` | `false` | Disables telemetry data collection |
| `ITEM_TRANSACTION_LOGGING_ENABLED` | `true` | Logs item movements and transactions |

### Game Configuration

| Variable | Value | Description |
| --- | --- | --- |
| `SERVER_NAME` | `.env` | Server name shown in-game and LAN discovery |
| `LEVEL_NAME` | `.env` | World/save file name |
| `LEVEL_TYPE` | `DEFAULT` | World generation type (normal terrain) |
| `LEVEL_SEED` | `.env` | World seed for terrain generation |
| `GAMEMODE` | `survival` | Default game mode for new players |
| `FORCE_GAMEMODE` | `true` | Enforces gamemode setting on existing players |
| `DIFFICULTY` | `easy` | World difficulty level |
| `ALLOW_CHEATS` | `true` | Enables command usage (required for game rules) |
| `PVP` | `false` | Disables player vs player combat |
| `ALLOW_NETHER` | `true` | Enables access to the Nether dimension |
| `SPAWN_PROTECTION` | `16` | Radius of spawn area protected from non-ops |
| `PLAYER_IDLE_TIMEOUT` | `30` | Minutes before idle players are kicked (0 = disabled) |
| `DEFAULT_PLAYER_PERMISSION_LEVEL` | `member` | Default permission level for new players |

## Game Rules

The following game rules are configured via `/gamerule` commands:

| Rule | Value | Description |
| --- | --- | --- |
| `keepInventory` | `true` | Players keep items on death |
| `showCoordinates` | `true` | Shows player coordinates in-game |
| `mobGriefing` | `false` | Prevents mobs from destroying blocks (creeper explosions, endermen, etc.) |

### Automatic Initialization

Game rules are **automatically applied** when a new world is created using the [init-gamerules.sh](init-gamerules.sh) initialization script. This script:

- Runs once when the server first starts with a new world
- Applies the game rules listed above
- Creates a marker file to prevent re-running on subsequent restarts
- Is mounted read-only into the container via `docker-compose.yml`

**For a new world**: Change `LEVEL_NAME` in `.env` and restart — the script runs automatically.

**To re-apply rules to an existing world**, delete the marker file:

```bash
docker exec minecraft-bedrock rm /data/worlds/<LEVEL_NAME>/.gamerules_initialized
docker compose restart
```

### Manual Configuration

You can also set game rules manually at any time. Connect to the server as an operator and run:

```bash
/gamerule keepInventory true
/gamerule showCoordinates true
/gamerule mobGriefing false
```

Or use the server console from the host:

```bash
docker exec minecraft-bedrock send-command gamerule keepInventory true
docker exec minecraft-bedrock send-command gamerule showCoordinates true
docker exec minecraft-bedrock send-command gamerule mobGriefing false
```

> [!NOTE]
> `ALLOW_CHEATS` is enabled to support game rule commands.

## Getting Started

**Prerequisites:** Docker Engine, Docker Compose V2

```bash
# Start server
docker compose up -d

# View logs
docker compose logs -f

# Stop server
docker compose down

# Restart server
docker compose restart

# Update to latest version
docker compose pull && docker compose up -d
```

## Running Server Commands

```bash
# Send commands from host terminal (recommended)
docker exec minecraft-bedrock send-command gamerule keepInventory true
docker exec minecraft-bedrock send-command give <playername> diamond 64

# Or attach to console (Ctrl+P, Ctrl+Q to detach)
docker attach minecraft-bedrock
```

> [!WARNING]
> Do not use Ctrl+C when attached - this will stop the server!

## Connecting

**LAN:** Server appears in **Play** → **Friends** → **LAN Games**

**Internet:** Forward UDP port `19132` to server's local IP, share your public IP, and add players to `ALLOW_LIST_USERS` in `.env`

## Backup & Data

Server data persists in Docker volume `minecraft-data`. To backup:

```bash
docker run --rm -v minecraft-data:/data -v $(pwd):/backup alpine \
  tar czf /backup/minecraft-backup-$(date +%Y%m%d-%H%M%S).tar.gz -C /data .
```

## Additional Resources

- [Minecraft Bedrock Server Documentation](https://learn.microsoft.com/en-us/minecraft/creator/documents/bedrockserver/getting-started?view=minecraft-bedrock-stable)
- [Minecraft Wiki - Server Properties](https://minecraft.wiki/w/Server.properties#Option_keys)
