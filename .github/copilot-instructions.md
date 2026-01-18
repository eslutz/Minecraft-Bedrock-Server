# Copilot Instructions: Minecraft Bedrock Server

## Project Overview

This is a **Dockerized Minecraft Bedrock Edition server** designed for family/friends gameplay. The architecture centers around a single `docker-compose.yml` file orchestrating the `itzg/minecraft-bedrock-server` image with extensive environment-based configuration.

## Architecture & Key Components

### Configuration Layers (Precedence: High → Low)

1. **Environment Variables** (`.env`) → Docker container → `server.properties` generation
2. **Docker Compose** (`docker-compose.yml`) → Defines container, volumes, ports, logging
3. **Initialization Scripts** (`init-world.sh`) → One-time world setup on creation
4. **Persistent Data** (`minecraft-data` volume) → Worlds, configs, player data

**Critical Pattern**: The `itzg` image auto-generates `/data/server.properties` from environment variables on startup. Never edit `data/server.properties` directly—changes will be overwritten. Always modify `.env` and restart the container.

### Data Flow

```
.env → docker-compose.yml → Container → /data/server.properties
                                      → /data/worlds/<LEVEL_NAME>/
                                      → /data/allowlist.json
                                      → /data/permissions.json
```

## Developer Workflows

### Configuration Changes

```bash
# 1. Edit .env (not docker-compose.yml environment section)
vim .env

# 2. Recreate to apply new env values (auto-regenerates server.properties)
docker compose up -d
```

### Game Rule Management

**Automatic** (preferred for new worlds):

- Script: `init-world.sh` runs once on world creation
- Marker: `/data/worlds/<LEVEL_NAME>/.world_initialized` prevents re-runs
- Re-apply: Delete marker + restart

**Manual** (for existing worlds):

```bash
docker exec minecraft-bedrock send-command gamerule keepInventory true
```

### Common Commands

```bash
# Server management
docker compose up -d              # Start detached
docker compose logs -f            # Tail logs
docker compose restart            # Apply config changes
docker compose pull && docker compose up -d  # Update server version

# Send in-game commands (preferred over attach)
docker exec minecraft-bedrock send-command <command>

# Console access (⚠️ Ctrl+P, Ctrl+Q to detach—NOT Ctrl+C!)
docker attach minecraft-bedrock
```

## Project-Specific Conventions

### Environment Variable Pattern

- **Never hardcode** sensitive values (XUIDs, server names) in `docker-compose.yml`
- Use `${VAR_NAME}` placeholders + `.env` file
- Reference `.env.example` for required variables and format

### Player Access Control

- **Allowlist format**: `ALLOW_LIST_USERS=gamertag:xuid,gamertag:xuid`
- **Get XUIDs**: https://mcprofile.io/ (required for Bedrock authentication)
- Operators list uses XUIDs only (no gamertags)

### World Reset Pattern

Changing `LEVEL_NAME` in `.env` + restart creates a new world automatically. Old world data persists in volume:

```
/data/worlds/OldWorld/
/data/worlds/NewWorld/  ← Active after restart
```

## Critical Files

- **[docker-compose.yml](../docker-compose.yml)**: Single source of truth for container config, ports, volumes, environment variable mappings
- **[.env](../.env)**: Actual values (gitignored); copy from `.env.example` to start
- **[init-world.sh](../init-world.sh)**: World initialization logic; mounted read-only, uses `send-command` API
- **[README.md](../README.md)**: User-facing documentation with complete environment variable reference

## Troubleshooting Patterns

### Config Not Applied

**Symptom**: Changed `.env`, restarted, but server behavior unchanged.
**Cause**: Forgot to rebuild container OR edited `data/server.properties` directly.
**Fix**: `docker compose up -d` OR revert `server.properties` changes and edit `.env` instead.

### Game Rules Reset

**Symptom**: Game rules revert to defaults.
**Cause**: Marker file exists but was created before rules applied, OR script didn't run (container startup issue).
**Fix**: Delete `/data/worlds/<LEVEL_NAME>/.world_initialized`, ensure script is mounted, restart.

### Permission Denied Errors

**Symptom**: Container can't write to `/data/` volume.
**Cause**: Volume ownership doesn't match container user.
**Fix**: Recreate the volume or `chown` it using a one-off container.

## Integration Points

- **External**: Xbox Live authentication (when `ONLINE_MODE=true`)
- **LAN Discovery**: UDP broadcast on local network (port 19132)
- **Volume**: `minecraft-data` Docker volume stores all persistent data; backup with `docker run --rm -v minecraft-data:/data -v $(pwd):/backup alpine tar czf /backup/backup.tar.gz -C /data .`
- **Logging**: JSON driver with rotation (10MB × 3 files); view with `docker compose logs`

## Making Changes

When modifying this project:

1. **Config changes**: Edit `.env` only, never `docker-compose.yml` environment values
2. **New game rules**: Add to `init-world.sh`, delete marker file for existing worlds
3. **Port changes**: Update both `ports:` in compose AND firewall/router forwarding
