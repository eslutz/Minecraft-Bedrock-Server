#!/bin/bash
# This script runs once when the world is first created to set game rules
# It creates a marker file to prevent re-running on subsequent startups

MARKER_FILE="/data/worlds/${LEVEL_NAME}/.gamerules_initialized"

# Game rules to apply (rule:value)
GAMERULES=(
  "keepInventory:true"
  "locatorbar:true"
  "mobGriefing:false"
  "naturalRegeneration:true"
  "pvp:false"
)

# Check if game rules have already been initialized
if [[ -f "$MARKER_FILE" ]]; then
  echo "Game rules already initialized, skipping..."
  exit 0
fi

# Wait for server to be fully started
SERVER_PORT="${SERVER_PORT:-19132}"
echo "Waiting for server to start before applying game rules..."
for attempt in {1..12}; do
  if /usr/local/bin/mc-monitor status-bedrock --host 127.0.0.1 --port "$SERVER_PORT" >/dev/null 2>&1; then
    echo "Server is ready."
    break
  fi

  echo "Server not ready yet (attempt $attempt/12). Waiting 10s..."
  sleep 10
done

if ! /usr/local/bin/mc-monitor status-bedrock --host 127.0.0.1 --port "$SERVER_PORT" >/dev/null 2>&1; then
  echo "⚠ WARNING: Server did not become ready in time. Exiting without applying game rules."
  exit 1
fi

# Helper function to set game rules
set_gamerule() {
  local rule=$1
  local value=$2

  echo "Setting $rule to $value..."
  /usr/local/bin/send-command gamerule "$rule" "$value"
  sleep 1
}

# Apply game rules with validation
echo "Applying game rules..."

# Apply game rules from the list above
for rule_pair in "${GAMERULES[@]}"; do
  IFS=':' read -r rule value <<< "$rule_pair"
  set_gamerule "$rule" "$value"
done

# Create marker file to prevent re-running
echo "Game rules applied. Creating marker file..."
mkdir -p "$(dirname "$MARKER_FILE")"
echo "Game rules initialized on $(date)" > "$MARKER_FILE"

echo "Game rules initialization complete!"
