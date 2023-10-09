#!/bin/bash
source <(curl -s https://raw.githubusercontent.com/itrocket-team/testnet_guides/main/utils/common.sh)

while getopts u:b:v:n:o:p:h:i:r: flag; do
  case "${flag}" in
  u) UPD_HEIGHT=$OPTARG ;;
  b) BINARY=$OPTARG ;;
  v) VERSION=$OPTARG ;;
  n) NEW_BIN_PATH=$OPTARG ;;
  o) OLD_BIN_PATH=$OPTARG ;;
  p) PROJECT_NAME=$OPTARG ;;
  h) PROJECT_HOME=$OPTARG ;;
  i) CHAIN_ID=$OPTARG ;;
  r) PORT_RPC=$OPTARG ;;
  *) echo "WARN: unknown parameter: ${OPTARG}"
  esac
done

printLogo

# Initialize an empty array to store block times
block_times=()
MAX_BLOCK_COUNT=5  # Number of blocks to average over

while true; do
    VER=$($NEW_BIN_PATH version)

    if [[ -n $VER ]]; then
        echo -e "New Bin version: $GREEN $VER ${NC}"
        echo -e "HOME path: $GREEN $PROJECT_HOME ${NC}"
        echo -e "RPC port: $GREEN $PORT_RPC ${NC}"
        echo -e "NEW bin path: $GREEN $NEW_BIN_PATH ${NC}"
        echo -e "OLD bin path: $GREEN $OLD_BIN_PATH ${NC}"
        break
    else
        echo -e "$RED The binary file is missing. Please BUILD the binary first and then run this script again. ${NC}"
        sleep 5
    fi
done

printLine
echo -e "YOUR NODE WILL BE UPDATED AT HEIGHT $GREEN $UPD_HEIGHT ${NC} to $GREEN ${VER} ${NC}"
printLine
echo -e "Don't kill the session with $RED CTRL+C ${NC} before update completed"
echo -e "if you want to disconnect the session use $GREEN CTRL+B D ${NC}"
printLine
sleep 2

prev_time=$(date +%s)

for((;;)); do
  height=$(curl -s localhost:$PORT_RPC/status | jq -r .result.sync_info.latest_block_height)

  # Calculate current time
  cur_time=$(date +%s)

  # Calculate time interval between blocks
  time_interval=$((cur_time - prev_time))
  prev_time=$cur_time

  # Add the new time interval to the array and remove the oldest if the array size exceeds MAX_BLOCK_COUNT
  block_times=("${block_times[@]}" "$time_interval")
  if [ ${#block_times[@]} -gt $MAX_BLOCK_COUNT ]; then
    block_times=("${block_times[@]:1}")
  fi

  # If we have enough data, calculate and display the remaining time
  if [ ${#block_times[@]} -eq $MAX_BLOCK_COUNT ]; then
    sum_times=0
    for t in "${block_times[@]}"; do
      sum_times=$((sum_times + t))
    done
    avg_time=$((sum_times / MAX_BLOCK_COUNT))

    remaining_blocks=$((UPD_HEIGHT - height))
    remaining_time=$((remaining_blocks * avg_time))

    readable_remaining_time=$(printf "%dd %dh %dm %ds" $((remaining_time/86400)) $((remaining_time%86400/3600)) $((remaining_time%3600/60)) $((remaining_time%60)))
    time_display=${BLUE}${readable_remaining_time}${NC}
  else
    time_display="Calculating average time..."
  fi

  echo -e Node Height: ${GREEN}$height${NC}
  echo -e Upgr Height: ${BLUE}$UPD_HEIGHT${NC}
  echo -e "Estimated Time: ${time_display} | Remaining Blocks: ${BLUE}${remaining_blocks}${NC} | Average Time per Block: ${BLUE}${avg_time}s${NC}"

  if ((height==$UPD_HEIGHT)); then
    sudo mv $NEW_BIN_PATH $OLD_BIN_PATH
    sudo systemctl restart $BINARY
    printLine
    echo -e "$GREEN Your node has been updated and restarted, the session will be terminated automatically after 15 min${NC}"   
    printLine
    break
  fi

  sleep 4
done

echo "$(date): Your node successfully upgraded to v${VER}" >> $PROJECT_HOME/upgrade.log
sleep 900
tmux kill-session
