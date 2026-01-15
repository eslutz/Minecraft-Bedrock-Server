#!/bin/bash
# This script runs once when the world is first created to set game rules
# It creates a marker file to prevent re-running on subsequent startups

MARKER_FILE="/data/worlds/${LEVEL_NAME}/.gamerules_initialized"

# Check if game rules have already been initialized
if [[ -f "$MARKER_FILE" ]]; then
  echo "Game rules already initialized, skipping..."
  exit 0
fi

# Wait for server to be fully started (adjust time if needed)
echo "Waiting for server to start before applying game rules..."
sleep 30

# Apply game rules
echo "Applying game rules..."
/usr/local/bin/send-command gamerule keepInventory true
sleep 1
/usr/local/bin/send-command gamerule showCoordinates true
sleep 1
/usr/local/bin/send-command gamerule mobGriefing false
sleep 1

# Create marker file to prevent re-running
echo "Game rules applied. Creating marker file..."
mkdir -p "$(dirname "$MARKER_FILE")"
echo "Game rules initialized on $(date)" > "$MARKER_FILE"

echo "Game rules initialization complete!"
