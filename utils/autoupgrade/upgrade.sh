#!/bin/bash
source <(curl -s https://raw.githubusercontent.com/itrocket-team/testnet_guides/main/utils/common.sh)

while getopts u:b:v:n:o:p:h:i:r: flag; do
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
  *) echo "WARN: unknown parameter: ${OPTARG}"
  esac
done

printLogo

# Function to send messages to Telegram
source ./tg.conf
send_telegram() {
    local message=$1
    if [ -n "$BOT_TOKEN" ] && [ -n "$CHAT_ID_ALARM" ]; then
        local response=$(curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
            -d chat_id="$CHAT_ID_ALARM" -d text="$message" > /dev/null 2>&1)
        echo "Sent Telegram message: $message"
    else
        echo "BOT_TOKEN or CHAT_ID_ALARM not set. Telegram message not sent."
    fi
}

# Initialize variables for time calculations
prev_time=$(date +%s)
cur_time=0
avg_time=0
block_count=0
last_check_time=0
check_interval=3
proposal_status_checked=false

# Function check_proposal_status
check_proposal_status() {
  response=$(curl -s -X 'GET' $PROPOSAL_API)
  status=$(echo "$response" | jq -r '.proposal.status')

  if [[ $status == "PROPOSAL_STATUS_REJECTED" ]]; then
    printLine
    echo "Proposal rejected, the session will be terminated automatically after 15 min"
    echo "$(date): Upgrade rejected because PROPOSAL $PROPOSAL_API was REJECTED" >> $PROJECT_HOME/upgrade.log
    sleep 900
    tmux kill-session
    exit 0
  elif [[ $status == "PROPOSAL_STATUS_PASSED" ]]; then
    echo "Proposal passed. Continuing with the script."
    proposal_status_checked=true
  fi
}

while true; do
    VER=$($NEW_BIN_PATH version 2>&1 | tr -d '\n')

    if [[ -n $VER ]]; then
        echo -e "New Bin version: $GREEN $VER ${NC}"
        echo -e "HOME path: $GREEN $PROJECT_HOME ${NC}"
        echo -e "RPC port: $GREEN $PORT_RPC ${NC}"
        echo -e "NEW bin path: $GREEN $NEW_BIN_PATH ${NC}"
        echo -e "OLD bin path: $GREEN $OLD_BIN_PATH ${NC}"
        echo -e "Proposal API: $GREEN $PROPOSAL_API ${NC}"
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

for((;;)); do
  height=$(curl -s localhost:$PORT_RPC/status | jq -r .result.sync_info.latest_block_height)
  
  if ! $proposal_status_checked && (( cur_time - last_check_time > check_interval )); then
    check_proposal_status
    last_check_time=$cur_time
  fi

  # Calculate current time
  cur_time=$(date +%s)

  # Calculate time interval between blocks
  time_interval=$((cur_time - prev_time))
  prev_time=$cur_time
  
  # Calculate average time
  avg_time=$(( (avg_time * block_count + time_interval) / (block_count + 1) ))
  block_count=$((block_count + 1))

  # Calculate remaining blocks and remaining time
  remaining_blocks=$((UPD_HEIGHT - height))
  remaining_time=$((remaining_blocks * avg_time))

  # Generate readable time string directly
  readable_remaining_time=$(printf "%dd %dh %dm %ds" $((remaining_time/86400)) $((remaining_time%86400/3600)) $((remaining_time%3600/60)) $((remaining_time%60)))

  echo -e Node Height: ${GREEN}$height${NC}
  echo -e Upgr Height: ${BLUE}$UPD_HEIGHT${NC}
  echo -e "Estimated Time: ${BLUE}${readable_remaining_time}${NC} | Remaining Blocks: ${BLUE}${remaining_blocks}${NC} | Average Time per Block: ${BLUE}${avg_time}s${NC}"

  if ((height==$UPD_HEIGHT)); then
    if $proposal_status_checked || [[ $status == "" ]]; then
      # Если статус предложения "Passed" или нет ответа от API, выполняем обновление
    sudo mv $NEW_BIN_PATH $OLD_BIN_PATH
    sudo systemctl restart $BINARY
    printLine
    echo -e "$GREEN Your node has been updated and restarted, the session will be terminated automatically after 15 min${NC}"
    MESSAGE="$BINARY updated to ${VER} and service restarted"
    send_telegram "$MESSAGE"
    echo "$(date): Your node successfully upgraded to ${VER}" >> $PROJECT_HOME/upgrade.log
    printLine
    break
  else
    # Во всех остальных случаях отменяем обновление и выходим из скрипта
    echo -e "$RED Update cancelled due to proposal status: $status, the session will be terminated automatically after 15 min${NC}"
    sleep 900
    tmux kill-session
    exit 0
    fi
  fi

  sleep 4
done

sleep 900
tmux kill-session
