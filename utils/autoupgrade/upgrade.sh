#!/bin/bash
# Replaces the node binary at the upgrade height and restarts the service.
#
#   -u  upgrade height                      (required)
#   -b  systemd service name                (required)
#   -n  path of the new binary              (required)
#   -o  path of the binary that is replaced (required)
#   -h  node home, upgrade.log is written there
#   -r  RPC port of the node                (required)
#   -p  proposal API URL: the upgrade is cancelled if the proposal is rejected
#   -v  expected version: "<new binary> version" has to contain it
#   -s  expected sha256 of the new binary
#   -i  chain id (not used)
#
# The script needs root only to replace the binary and to restart the service.
# Started as root (sudo), it runs the new binary as the user who called sudo
# or who owns the file, never as root if such a user exists.
#
# Telegram notifications: create /root/tg.conf (owner root, chmod 600) with
#   CHAT_ID_ALARM=""
#   BOT_TOKEN=""

set -u

GREEN="\e[1m\e[1;32m"
RED="\e[1m\e[1;31m"
BLUE='\033[0;34m'
NC="\e[0m"

printLine() {
  echo "------------------------------------------------------------------------------------"
}

printLogo() {
  echo -e "$BLUE"
  echo "     ::: ::::::::::: ::::::::::: ::::::::::: ::::::::::: :::     ::: ::::::::::: ::::::::::: "
  echo "     :+:     :+:     :+:     :+: :+:     :+: :+:         :+:   :+:   :+:             :+:     "
  echo "     +:+     +:+     +:+     +:+ +:+     +:+ +:+         +:+  +:+    +:+             +:+     "
  echo "     +++     +++     +++++++++++ +++     +++ +++         +++ +++     +++++++++++     +++     "
  echo "     +#+     +#+     +#+  +#+    +#+     +#+ +#+         +#+  +#+    +#+             +#+     "
  echo "     #+#     #+#     #+#   #+#   #+#     #+# #+#         #+#   #+#   #+#             #+#     "
  echo "     ###     ###     ###     ### ########### ########### ###     ### ###########     ###     "
  echo -e "$GREEN"
  echo "                                                                          itrocket.net"
  echo -e "$NC"
}

UPD_HEIGHT="" BINARY="" VERSION="" NEW_BIN_PATH="" OLD_BIN_PATH="" PROPOSAL_API=""
PROJECT_HOME="" CHAIN_ID="" PORT_RPC="" NEW_BIN_SHA256=""

while getopts u:b:v:n:o:p:h:i:r:s: flag; do
  case "${flag}" in
  u) UPD_HEIGHT=$OPTARG ;;
  b) BINARY=$OPTARG ;;
  v) VERSION=$OPTARG ;;
  n) NEW_BIN_PATH=$OPTARG ;;
  o) OLD_BIN_PATH=$OPTARG ;;
  p) PROPOSAL_API=$OPTARG ;;
  h) PROJECT_HOME=$OPTARG ;;
  i) CHAIN_ID=$OPTARG ;;
  r) PORT_RPC=$OPTARG ;;
  s) NEW_BIN_SHA256=$OPTARG ;;
  *) echo "WARN: unknown parameter" ;;
  esac
done

printLogo

# Leaves the message on the screen before the tmux session closes
finish() {
  local code=$1
  if [ -n "${TMUX:-}" ]; then
    echo "The session will be terminated automatically after 15 min"
    sleep 900
    tmux kill-session
  fi
  exit "$code"
}

die() {
  echo -e "${RED}ERROR: $1${NC}"
  finish 1
}

log() {
  if [ -n "$PROJECT_HOME" ] && [ -d "$PROJECT_HOME" ]; then
    echo "$(date): $1" >> "$PROJECT_HOME/upgrade.log"
  fi
}

# ---- parameters -------------------------------------------------------------

[[ $UPD_HEIGHT =~ ^[1-9][0-9]*$ ]] || die "-u: the upgrade height has to be a number, got '$UPD_HEIGHT'"
[[ $PORT_RPC =~ ^[1-9][0-9]*$ ]] || die "-r: the RPC port has to be a number, got '$PORT_RPC'"
[[ $BINARY =~ ^[A-Za-z0-9_.@-]+$ ]] || die "-b: bad service name '$BINARY'"
[[ $NEW_BIN_PATH == /* ]] || die "-n: the path of the new binary has to be absolute, got '$NEW_BIN_PATH'"
[[ $OLD_BIN_PATH == /* ]] || die "-o: the path of the current binary has to be absolute, got '$OLD_BIN_PATH'"
[[ $NEW_BIN_PATH != "$OLD_BIN_PATH" ]] || die "-n and -o are the same file"
[ -d "$(dirname -- "$OLD_BIN_PATH")" ] || die "-o: no directory $(dirname -- "$OLD_BIN_PATH")"
if [ -n "$NEW_BIN_SHA256" ]; then
  NEW_BIN_SHA256=${NEW_BIN_SHA256,,}
  [[ $NEW_BIN_SHA256 =~ ^[0-9a-f]{64}$ ]] || die "-s: not a sha256 sum"
fi
for cmd in curl jq sha256sum install; do
  command -v "$cmd" > /dev/null || die "$cmd is not installed"
done

# Root is used for two things only: the replacement of the binary and the restart
if [ "$(id -u)" -eq 0 ]; then
  SUDO=()
else
  SUDO=(sudo)
fi

# ---- Telegram ---------------------------------------------------------------

BOT_TOKEN="" CHAT_ID_ALARM=""
TG_CONF=/root/tg.conf
if [ -f "$TG_CONF" ] && [ -r "$TG_CONF" ]; then
  # The file is executed as shell code: nobody but root may be able to change it
  if [ "$(stat -c %u "$TG_CONF")" = 0 ] && [ -z "$(find "$TG_CONF" -maxdepth 0 -perm /022)" ]; then
    # shellcheck disable=SC1090
    source "$TG_CONF"
  else
    echo -e "${RED}$TG_CONF is not owned by root or is writable by others, ignored.${NC} Fix: chown root $TG_CONF && chmod 600 $TG_CONF"
  fi
else
  echo "Telegram configuration file not found. Telegram notifications will be disabled."
fi

send_telegram() {
  local message=$1
  if [ -n "${BOT_TOKEN:-}" ] && [ -n "${CHAT_ID_ALARM:-}" ]; then
    # The URL with the token goes through stdin, not through the process list
    curl -s -m 20 -o /dev/null -K - \
      --data-urlencode chat_id="$CHAT_ID_ALARM" --data-urlencode text="$message" << EOF
url = "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage"
EOF
    echo "Sent Telegram message: $message"
  else
    echo "BOT_TOKEN or CHAT_ID_ALARM not set. Telegram message not sent."
  fi
}

# ---- the new binary ---------------------------------------------------------

# The user the new binary is run as while it is only being checked
RUN_AS=""
if [ "$(id -u)" -eq 0 ]; then
  if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != root ] && id "$SUDO_USER" > /dev/null 2>&1; then
    RUN_AS=$SUDO_USER
  fi
fi

# Prints "<binary> version"; stdin is closed, the script itself may come from it
bin_version() {
  local user=$RUN_AS owner
  if [ "$(id -u)" -eq 0 ] && [ -z "$user" ]; then
    owner=$(stat -c %U -- "$NEW_BIN_PATH" 2> /dev/null)
    if [ -n "$owner" ] && [ "$owner" != root ] && [ "$owner" != UNKNOWN ]; then
      user=$owner
    fi
  fi
  if [ -n "$user" ] && command -v runuser > /dev/null; then
    local home
    home=$(getent passwd "$user" | cut -d: -f6)
    timeout 60 runuser -u "$user" -- env HOME="${home:-/}" "$NEW_BIN_PATH" version < /dev/null 2>&1
  else
    timeout 60 "$NEW_BIN_PATH" version < /dev/null 2>&1
  fi
}

bin_sha256() {
  sha256sum -- "$NEW_BIN_PATH" 2> /dev/null | cut -d' ' -f1
}

while true; do
  problem=""
  if [ ! -f "$NEW_BIN_PATH" ] || [ -L "$NEW_BIN_PATH" ]; then
    problem="The binary file $NEW_BIN_PATH is missing. Please BUILD the binary first, the script is waiting for it."
  else
    NEW_SHA=$(bin_sha256)
    if VER=$(set -o pipefail; bin_version | tr -d '\n') && [ -n "$VER" ]; then
      if [ -n "$VERSION" ] && [[ ${VER#v} != *"${VERSION#v}"* ]]; then
        problem="The new binary reports version '$VER', expected '$VERSION'."
      elif [ -n "$NEW_BIN_SHA256" ] && [ "$NEW_SHA" != "$NEW_BIN_SHA256" ]; then
        problem="sha256 of the new binary is $NEW_SHA, expected $NEW_BIN_SHA256."
      elif [ -z "$NEW_SHA" ] || [ "$NEW_SHA" != "$(bin_sha256)" ]; then
        problem="The new binary is still changing."
      fi
    else
      problem="'$NEW_BIN_PATH version' failed: ${VER:-no output}"
    fi
  fi

  if [ -z "$problem" ]; then
    echo -e "New Bin version: $GREEN $VER ${NC}"
    echo -e "New Bin sha256: $GREEN $NEW_SHA ${NC}"
    echo -e "HOME path: $GREEN $PROJECT_HOME ${NC}"
    echo -e "RPC port: $GREEN $PORT_RPC ${NC}"
    echo -e "NEW bin path: $GREEN $NEW_BIN_PATH ${NC}"
    echo -e "OLD bin path: $GREEN $OLD_BIN_PATH ${NC}"
    echo -e "Proposal API: $GREEN $PROPOSAL_API ${NC}"
    break
  fi
  echo -e "$RED $problem ${NC}"
  sleep 5
done

printLine
echo -e "YOUR NODE WILL BE UPDATED AT HEIGHT $GREEN $UPD_HEIGHT ${NC} to $GREEN ${VER} ${NC}"
printLine
echo -e "Don't kill the session with $RED CTRL+C ${NC} before update completed"
echo -e "if you want to disconnect the session use $GREEN CTRL+B D ${NC}"
printLine
sleep 2

# ---- proposal ---------------------------------------------------------------

prev_time=$(date +%s)
cur_time=0
avg_time=0
block_count=0
last_check_time=0
check_interval=3
proposal_status_checked=false
status=""

check_proposal_status() {
  local response
  response=$(curl -s -m 20 -X GET -- "$PROPOSAL_API")
  status=$(echo "$response" | jq -r '.proposal.status' 2> /dev/null)

  if [[ $status == "PROPOSAL_STATUS_REJECTED" ]]; then
    printLine
    echo "Proposal rejected"
    log "Upgrade rejected because PROPOSAL $PROPOSAL_API was REJECTED"
    finish 0
  elif [[ $status == "PROPOSAL_STATUS_PASSED" ]]; then
    echo "Proposal passed. Continuing with the script."
    proposal_status_checked=true
  fi
}

# ---- upgrade ----------------------------------------------------------------

fail_upgrade() {
  echo -e "${RED}ERROR: $1${NC}"
  log "Upgrade to ${VER} FAILED: $1"
  send_telegram "$BINARY upgrade to ${VER} FAILED at height $UPD_HEIGHT: $1"
  finish 1
}

do_upgrade() {
  # The file may not have changed since it was checked
  local sha
  sha=$(bin_sha256)
  if [ "$sha" != "$NEW_SHA" ]; then
    fail_upgrade "$NEW_BIN_PATH has changed since the script started (sha256 ${sha:-unreadable}, was $NEW_SHA), the binary was NOT replaced"
  fi

  if [ -f "$OLD_BIN_PATH" ]; then
    "${SUDO[@]}" cp -p -- "$OLD_BIN_PATH" "$OLD_BIN_PATH.bak" ||
      fail_upgrade "cannot back up $OLD_BIN_PATH, the binary was NOT replaced"
  fi

  # A copy next to the target and a rename: the target is never half written
  if ! "${SUDO[@]}" install -m 0755 -- "$NEW_BIN_PATH" "$OLD_BIN_PATH.new"; then
    fail_upgrade "cannot copy $NEW_BIN_PATH to $OLD_BIN_PATH.new, the binary was NOT replaced"
  fi
  if [ "$(sha256sum -- "$OLD_BIN_PATH.new" 2> /dev/null | cut -d' ' -f1)" != "$NEW_SHA" ]; then
    "${SUDO[@]}" rm -f -- "$OLD_BIN_PATH.new"
    fail_upgrade "the copy of the new binary differs from the checked one, the binary was NOT replaced"
  fi
  if ! "${SUDO[@]}" mv -f -- "$OLD_BIN_PATH.new" "$OLD_BIN_PATH"; then
    fail_upgrade "cannot replace $OLD_BIN_PATH, the binary was NOT replaced"
  fi
  rm -f -- "$NEW_BIN_PATH" 2> /dev/null || "${SUDO[@]}" rm -f -- "$NEW_BIN_PATH"

  if ! "${SUDO[@]}" systemctl restart "$BINARY"; then
    fail_upgrade "the binary was replaced, but 'systemctl restart $BINARY' failed (old binary: $OLD_BIN_PATH.bak)"
  fi
  sleep 5
  if ! systemctl is-active --quiet "$BINARY"; then
    fail_upgrade "the binary was replaced, but the service $BINARY is not running after the restart (old binary: $OLD_BIN_PATH.bak)"
  fi
}

for ((;;)); do
  height=$(curl -s -m 10 "localhost:$PORT_RPC/status" | jq -r .result.sync_info.latest_block_height 2> /dev/null)

  if [[ -n $PROPOSAL_API ]] && ! $proposal_status_checked && ((cur_time - last_check_time > check_interval)); then
    check_proposal_status
    last_check_time=$cur_time
  fi

  # Calculate current time
  cur_time=$(date +%s)

  # The answer of the RPC is used in arithmetic: digits only
  if ! [[ $height =~ ^[0-9]+$ ]]; then
    echo -e "${RED}No block height from localhost:$PORT_RPC, retrying${NC}"
    sleep 4
    continue
  fi
  height=$((10#$height))

  # Calculate time interval between blocks
  time_interval=$((cur_time - prev_time))
  prev_time=$cur_time

  # Calculate average time
  avg_time=$(((avg_time * block_count + time_interval) / (block_count + 1)))
  block_count=$((block_count + 1))

  # Calculate remaining blocks and remaining time
  remaining_blocks=$((UPD_HEIGHT - height))
  remaining_time=$((remaining_blocks * avg_time))

  # Generate readable time string directly
  readable_remaining_time=$(printf "%dd %dh %dm %ds" $((remaining_time / 86400)) $((remaining_time % 86400 / 3600)) $((remaining_time % 3600 / 60)) $((remaining_time % 60)))

  echo -e "Node Height: ${GREEN}$height${NC}"
  echo -e "Upgr Height: ${BLUE}$UPD_HEIGHT${NC}"
  echo -e "Estimated Time: ${BLUE}${readable_remaining_time}${NC} | Remaining Blocks: ${BLUE}${remaining_blocks}${NC} | Average Time per Block: ${BLUE}${avg_time}s${NC}"

  if ((height == UPD_HEIGHT)); then
    if $proposal_status_checked || [[ $status == "" ]]; then
      # The proposal has passed, or there is no proposal API or no answer from it
      if [[ -n $PROPOSAL_API ]] && ! $proposal_status_checked; then
        echo -e "${RED}WARN: no answer from the proposal API, upgrading without the check${NC}"
      fi
      do_upgrade
      printLine
      echo -e "$GREEN Your node has been updated and restarted${NC}"
      send_telegram "$BINARY updated to ${VER} and service restarted"
      log "Your node successfully upgraded to ${VER}"
      printLine
      break
    else
      # Anything else cancels the upgrade
      echo -e "$RED Update cancelled due to proposal status: $status${NC}"
      log "Upgrade cancelled due to proposal status: $status"
      finish 0
    fi
  fi

  sleep 4
done

finish 0
