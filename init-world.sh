#!/bin/bash
# One-time world initialization:
# - Applies gamerules
# - Sets world spawn

set -euo pipefail

LEVEL_NAME="${LEVEL_NAME:-Bedrock level}"
MARKER_FILE="/data/worlds/${LEVEL_NAME}/.world_initialized"

# ---- Natural spawn coordinates you captured ----
SPAWN_X=-69
SPAWN_Y=64
SPAWN_Z=42

# ---- Gamerules (rule:value) ----
GAMERULES=(
  "keepInventory:true"
  "locatorbar:true"
  "mobGriefing:false"
  "naturalRegeneration:true"
  "pvp:false"
)

# ---- Exit if already initialized ----
if [[ -f "$MARKER_FILE" ]]; then
  echo "World already initialized. Skipping."
  exit 0
fi

SERVER_PORT="${SERVER_PORT:-19132}"

echo "Waiting for server readiness..."
# Longer wait: 10 minutes (60 x 10s). Adjust as needed.
for attempt in {1..60}; do
  if /usr/local/bin/mc-monitor status-bedrock --host 127.0.0.1 --port "$SERVER_PORT" >/dev/null 2>&1; then
    echo "Server is ready."
    break
  fi
  echo "Not ready yet ($attempt/60)..."
  sleep 10
done

if ! /usr/local/bin/mc-monitor status-bedrock --host 127.0.0.1 --port "$SERVER_PORT" >/dev/null 2>&1; then
  echo "ERROR: Server never became ready."
  exit 1
fi

send_cmd() {
  /usr/local/bin/send-command "$@"
}

# ---- Apply gamerules ----
echo "Applying gamerules..."
for rule_pair in "${GAMERULES[@]}"; do
  IFS=':' read -r rule value <<< "$rule_pair"
  send_cmd gamerule "$rule" "$value"
  sleep 0.5
done

# ---- Set world spawn (natural coords) ----
echo "Setting world spawn..."
send_cmd setworldspawn "$SPAWN_X" "$SPAWN_Y" "$SPAWN_Z"
sleep 1

# ---- Marker ----
echo "Marking world as initialized..."
mkdir -p "$(dirname "$MARKER_FILE")"
echo "Initialized on $(date)" > "$MARKER_FILE"

echo "World initialization complete."
