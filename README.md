# Minecraft Bedrock Server

A containerized Minecraft Bedrock Dedicated Server using Docker Compose, configured for family and friends gameplay with customized settings and world generation.

## Overview

This project runs a Minecraft Bedrock Edition server using the [itzg/minecraft-bedrock-server](https://github.com/itzg/docker-minecraft-bedrock-server) Docker image. The server is configured for:

- **Survival gameplay** on easy difficulty
- **Family-friendly environment** with PVP disabled
- **Allowlist-based access control** for approved players
- **Custom world generation** with a specific seed
- **Automatic updates** to the latest Bedrock server version

## Getting Started

*Prerequisites: Docker Engine, Docker Compose V2*

Quickly start and manage the server locally using Docker Compose.


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

## Connect to the Server

**LAN:** Server appears in **Play** → **Friends** → **LAN Games**

**Internet:** Forward UDP port `19132` to server's local IP, share your public IP, and add players to `ALLOW_LIST_USERS` in `.env`

> [!WARNING]
> This is the minimal way to get online access working, not the safest. Consider a VPN or other network security options to reduce exposure.

## Running Server Commands

```bash
# Send commands from host terminal (recommended)
docker exec minecraft-bedrock send-command <command>

# Or attach to console (Ctrl+P, Ctrl+Q to detach)
docker attach minecraft-bedrock
```

> [!WARNING]
> Do not use Ctrl+C when attached - this will stop the server!

## Environment Variables

All configuration is managed through environment variables. Sensitive values are stored in `.env` (not committed to source control). Copy [.env.example](.env.example) to `.env` and configure allowlist users with XUIDs ([Xbox XUID Finder](https://cxkes.me/xbox/xuid)), operators, and server/world settings.

### Container & Server Configuration

| Variable | Value | Description |
| --- | --- | --- |
| `EULA` **(required)** | `TRUE` | Accepts the [Minecraft EULA](https://minecraft.net/terms) |
| `TZ` | `America/New_York` | Server timezone for logs and timestamps |
| `VERSION` | `LATEST` | Auto-upgrades to the latest stable Bedrock server version |
| `PACKAGE_BACKUP_KEEP` | `2` | Number of previous server version backups to retain |
| `STOP_SERVER_BEFORE_UPGRADE` | `true` | Gracefully stops the server before upgrading |
| `ALLOW_LIST` | `true` | Only players on the allowlist can join |
| `ALLOW_LIST_USERS` **(required)** | `.env` | Comma-separated list of `gamertag:xuid` pairs |
| `OPS` **(required)** | `.env` | Comma-separated XUIDs of server operators |
| `ONLINE_MODE` | `true` | Requires Xbox Live authentication (recommended for security) |
| `ENABLE_LAN_VISIBILITY` | `true` | Server appears in LAN game discovery |
| `VIEW_DISTANCE` | `6` | Maximum view distance in chunks (client render distance) |
| `TICK_DISTANCE` | `4` | Simulation distance in chunks (affects mob AI, redstone, etc.) |
| `MAX_PLAYERS` | `6` | Maximum concurrent players allowed |
| `MAX_THREADS` | `4` | Caps server threads (match number of Pi 5 cores) |
| `CONTENT_LOG_FILE_ENABLED` | `false` | Disables content log file to reduce write load |
| `CONTENT_LOG_LEVEL` | `warning` | Log verbosity level |
| `CONTENT_LOG_CONSOLE_OUTPUT_ENABLED` | `true` | Outputs content logs to console |
| `EMIT_SERVER_TELEMETRY` | `false` | Disables telemetry data collection |
| `ITEM_TRANSACTION_LOGGING_ENABLED` | `false` | Logs item movements and transactions |

### Game Configuration

| Variable | Value | Description |
| --- | --- | --- |
| `SERVER_NAME` **(required)** | `.env` | Server name shown in-game and LAN discovery |
| `LEVEL_NAME` **(required)** | `.env` | World name |
| `LEVEL_TYPE` | `DEFAULT` | World generation type (normal terrain) |
| `LEVEL_SEED` **(required)** | `.env` | World seed for terrain generation |
| `GAMEMODE` | `survival` | Default game mode for new players |
| `FORCE_GAMEMODE` | `true` | Enforces gamemode setting on existing players |
| `DIFFICULTY` | `easy` | World difficulty level |
| `ALLOW_CHEATS` | `false` | Cheats disabled; admin commands available via `send-command` |
| `ALLOW_NETHER` | `true` | Enables access to the Nether dimension |
| `SPAWN_PROTECTION` | `16` | Radius of spawn area protected from non-ops |
| `PLAYER_IDLE_TIMEOUT` | `30` | Minutes before idle players are kicked (0 = disabled) |
| `DEFAULT_PLAYER_PERMISSION_LEVEL` | `member` | Default permission level for new players |

## Game Rules

Game rules are configured in [init-world.sh](init-world.sh) and applied automatically on first start. The init script also establishes the initial start point and more.

| Rule | Value | Description |
| --- | --- | --- |
| `keepInventory` | `true` | Players keep items on death |
| `locatorbar` | `true` | Shows locator bar with coordinates and direction |
| `mobGriefing` | `false` | Prevents mobs from destroying blocks (creeper explosions, endermen, etc.) |
| `naturalRegeneration` | `true` | Health regenerates when hunger is full |
| `pvp` | `false` | Disables player vs player combat |

### Automatic Initialization

Game rules are automatically applied when a new world is created using [scripts/init-gamerules.sh](scripts/init-gamerules.sh). For new worlds, simply change `LEVEL_NAME` in [.env](.env.example) and restart. To re-apply rules to an existing world delete the marker file and restart:

```bash
docker exec minecraft-bedrock rm /data/worlds/<LEVEL_NAME>/.gamerules_initialized
docker compose restart
```

### Manual Configuration

Set game rules manually at any time using the server console:

```bash
docker exec minecraft-bedrock send-command gamerule <rule> <value>
```

## Backup & Data

Server data persists in Docker volume `minecraft-data`. To backup:

```bash
docker run --rm -v minecraft-data:/data -v $(pwd):/backup alpine \
  tar czf /backup/minecraft-backup-$(date +%Y%m%d-%H%M%S).tar.gz -C /data .
```

## Additional Resources

- [itzg/minecraft-bedrock-server Documentation](https://github.com/itzg/docker-minecraft-bedrock-server)
- [Minecraft Bedrock Server Documentation](https://learn.microsoft.com/en-us/minecraft/creator/documents/bedrockserver/getting-started?view=minecraft-bedrock-stable)
- [Bedrock Dedicated Server Properties](https://learn.microsoft.com/en-us/minecraft/creator/documents/bedrockserver/server-properties?view=minecraft-bedrock-stable)
- [Introduction to Game Rules](https://learn.microsoft.com/en-us/minecraft/creator/documents/introductiontogamerules?view=minecraft-bedrock-stable)
- [Game Rule Reference](https://learn.microsoft.com/en-us/minecraft/creator/scriptapi/minecraft/server/gamerule?view=minecraft-bedrock-stable)
