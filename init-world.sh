#!/bin/bash
# One-time world initialization:
# - Applies gamerules
# - Sets world spawn to natural coords (captured manually)
# - Builds a spawn pad
# - Builds a colorful path to a starter area
# - Builds a 3D rainbow arch (walk-through height) over the starter chest
# - Places torches around the chest
# - Populates the chest

set -euo pipefail

LEVEL_NAME="${LEVEL_NAME:-Bedrock level}"
MARKER_FILE="/data/worlds/${LEVEL_NAME}/.world_initialized"

# ---- Natural spawn coordinates you captured ----
SPAWN_X=-69
SPAWN_Y=64
SPAWN_Z=42

# ---- Move the starter area away from spawn ----
# Offset along +X (east). Increase if you want it farther away.
START_OFFSET_X=14
START_X=$((SPAWN_X + START_OFFSET_X))
START_Y=$SPAWN_Y
START_Z=$SPAWN_Z

# Chest centered under the arch
CHEST_X=$START_X
CHEST_Y=$START_Y
CHEST_Z=$START_Z

# ---- Spawn pad settings (at spawn) ----
SPAWN_PAD_HALF_SIZE=2                 # 5x5
SPAWN_PAD_BLOCK="cobblestone"

# ---- Starter area pad settings (under arch/chest/path end) ----
START_PAD_HALF_SIZE=4                 # 9x9 so it feels like a little plaza
START_PAD_BLOCK="cobblestone"

# ---- Path settings (from spawn to starter area) ----
PATH_WIDTH=3                          # 3-wide walkway
PATH_Y=$((SPAWN_Y - 1))               # place on ground level
# Repeating path colors (concrete). Edit as you like.
PATH_COLORS=(red_concrete orange_concrete yellow_concrete lime_concrete light_blue_concrete blue_concrete purple_concrete)

# ---- Rainbow arch settings ----
# The arch is a thick semicircle "shell" you can walk under.
# With OUTER_R=12, inner is 5 (7 stripes thick), opening is roomy.
OUTER_R=12
INNER_R=$((OUTER_R - 7))              # 7 stripes => inner radius 5
ARCH_THICKNESS_Z=3                    # 3 blocks thick (depth)

# Stripe colors from outer -> inner (7 stripes)
RAINBOW_COLORS=(red_concrete orange_concrete yellow_concrete lime_concrete light_blue_concrete blue_concrete purple_concrete)

# ---- Gamerules (rule:value) ----
GAMERULES=(
  "keepInventory:true"
  "locatorbar:true"
  "mobGriefing:false"
  "naturalRegeneration:true"
  "pvp:false"
)

# ---- Chest contents (slot:item:amount) ----
CHEST_ITEMS=(
  "0:stone_pickaxe:4"
  "1:stone_axe:4"
  "2:stone_shovel:4"

  "3:empty_map:4"

  "4:crafting_table:4"
  "5:furnace:4"
  "6:chest:4"
  "7:white_bed:4"

  "8:cooked_beef:16"
  "9:cooked_porkchop:16"
  "10:cooked_chicken:16"
  "11:cooked_mutton:16"

  "12:torch:64"

  "13:oak_log:32"
  "14:stick:32"
  "15:cobblestone:32"
)

# ---- Exit if already initialized ----
if [[ -f "$MARKER_FILE" ]]; then
  echo "World already initialized. Skipping."
  exit 0
fi

SERVER_PORT="${SERVER_PORT:-19132}"

echo "Waiting for server readiness..."
# Longer wait: 10 minutes (60 x 10s). Adjust if you want.
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

send_cmd() { /usr/local/bin/send-command "$@"; }

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

# ---- Build spawn pad ----
echo "Building spawn pad..."
SPAWN_PAD_Y=$((SPAWN_Y - 1))
SX1=$((SPAWN_X - SPAWN_PAD_HALF_SIZE))
SX2=$((SPAWN_X + SPAWN_PAD_HALF_SIZE))
SZ1=$((SPAWN_Z - SPAWN_PAD_HALF_SIZE))
SZ2=$((SPAWN_Z + SPAWN_PAD_HALF_SIZE))
send_cmd fill "$SX1" "$SPAWN_PAD_Y" "$SZ1" "$SX2" "$SPAWN_PAD_Y" "$SZ2" "$SPAWN_PAD_BLOCK"
sleep 1

# ---- Build starter area pad ----
echo "Building starter area pad..."
START_PAD_Y=$((START_Y - 1))
PX1=$((START_X - START_PAD_HALF_SIZE))
PX2=$((START_X + START_PAD_HALF_SIZE))
PZ1=$((START_Z - START_PAD_HALF_SIZE))
PZ2=$((START_Z + START_PAD_HALF_SIZE))
send_cmd fill "$PX1" "$START_PAD_Y" "$PZ1" "$PX2" "$START_PAD_Y" "$PZ2" "$START_PAD_BLOCK"
sleep 1

# ---- Build colorful path (3-wide) from spawn to starter area along X ----
echo "Building colorful path..."
# Path runs from the edge of spawn pad to the edge of starter pad
PATH_START_X=$((SPAWN_X + SPAWN_PAD_HALF_SIZE + 1))
PATH_END_X=$((START_X - START_PAD_HALF_SIZE - 1))
HALF_W=$((PATH_WIDTH / 2))

i=0
for x in $(seq "$PATH_START_X" "$PATH_END_X"); do
  color="${PATH_COLORS[$((i % ${#PATH_COLORS[@]}))]}"
  z1=$((SPAWN_Z - HALF_W))
  z2=$((SPAWN_Z + HALF_W))
  send_cmd fill "$x" "$PATH_Y" "$z1" "$x" "$PATH_Y" "$z2" "$color"
  i=$((i + 1))
done
sleep 1

# ---- Build 3D rainbow arch over the chest ----
# Arch is centered at (START_X, START_Y, START_Z) with thickness along Z.
echo "Building 3D rainbow arch..."
ARCH_BASE_Y=$START_Y
Z_MIN=$((START_Z - (ARCH_THICKNESS_Z / 2)))
Z_MAX=$((START_Z + (ARCH_THICKNESS_Z / 2)))

# Helper: integer sqrt floor
isqrt() {
  local n="$1"
  local x=0
  while (( (x+1)*(x+1) <= n )); do
    x=$((x+1))
  done
  echo "$x"
}

for z in $(seq "$Z_MIN" "$Z_MAX"); do
  for dx in $(seq $((-OUTER_R)) "$OUTER_R"); do
    for dy in $(seq 0 "$OUTER_R"); do
      d2=$((dx*dx + dy*dy))
      r=$(isqrt "$d2")

      # Only place within the 7-stripe shell: INNER_R < r <= OUTER_R
      if (( r > INNER_R && r <= OUTER_R )); then
        stripe=$((OUTER_R - r)) # 0..6
        if (( stripe >= 0 && stripe < ${#RAINBOW_COLORS[@]} )); then
          block="${RAINBOW_COLORS[$stripe]}"
          x=$((START_X + dx))
          y=$((ARCH_BASE_Y + dy))
          send_cmd setblock "$x" "$y" "$z" "$block"
        fi
      fi
    done
  done
done

# Clear the interior space to ensure it's walk-through (hollow)
# (In case terrain overlaps the starter area)
echo "Clearing interior under arch..."
INNER_CLEAR_R=$((INNER_R - 1))
CLEAR_X1=$((START_X - INNER_CLEAR_R))
CLEAR_X2=$((START_X + INNER_CLEAR_R))
CLEAR_Y1=$ARCH_BASE_Y
CLEAR_Y2=$((ARCH_BASE_Y + INNER_CLEAR_R))
send_cmd fill "$CLEAR_X1" "$CLEAR_Y1" "$Z_MIN" "$CLEAR_X2" "$CLEAR_Y2" "$Z_MAX" air
sleep 1

# ---- Place the chest centered under the arch ----
echo "Placing starter chest..."
send_cmd setblock "$CHEST_X" "$CHEST_Y" "$CHEST_Z" chest
sleep 1

# ---- Place torches around the chest ----
echo "Placing torches..."
send_cmd setblock "$((CHEST_X + 1))" "$CHEST_Y" "$CHEST_Z" torch
send_cmd setblock "$((CHEST_X - 1))" "$CHEST_Y" "$CHEST_Z" torch
send_cmd setblock "$CHEST_X" "$CHEST_Y" "$((CHEST_Z + 1))" torch
send_cmd setblock "$CHEST_X" "$CHEST_Y" "$((CHEST_Z - 1))" torch
sleep 1

# ---- Fill the chest ----
echo "Filling starter chest..."
for entry in "${CHEST_ITEMS[@]}"; do
  IFS=':' read -r slot item amount <<< "$entry"
  send_cmd replaceitem block "$CHEST_X" "$CHEST_Y" "$CHEST_Z" slot.container "$slot" "$item" "$amount"
  sleep 0.2
done

# ---- Marker ----
echo "Marking world as initialized..."
mkdir -p "$(dirname "$MARKER_FILE")"
echo "Initialized on $(date)" > "$MARKER_FILE"

echo "World initialization complete."
