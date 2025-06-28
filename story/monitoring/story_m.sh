#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/itrocket-team/testnet_guides/main/utils/common.sh)
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Validator Node RPC server address
rpc_port=$(grep -m 1 -oP '^laddr = "\K[^"]+' "$HOME/.story/story/config/config.toml" | cut -d ':' -f 3)
RPC_SERVER="http://127.0.0.1:$rpc_port"

# Change to true if you want to allow telegram notifications
ENABLE=false

# Change to false if you don't want to get telegram notifications about changes in your validator's voting power
TELEGRAM_VP=true

# Telegram chat ID
TELEGRAM_CHAT_ID="<TELEGRAM_CHAT_ID>"

# Telegram bot token
TELEGRAM_BOT_TOKEN="<TELEGRAM_TOKEN>"

# Node name
NODE_NAME="Validator"

# Alert threshold for the block height difference between the node and network
BLOCK_GAP_ALARM=100

# External RPC server address to get the expected block height
EXTERNAL_RPC_SERVER="https://story-mainnet-rpc.itrocket.net"

# Maximum number of missed blocks that triggers a notification
MISSED_BLOCKS_ALARM=50

# Validator settings, don`t change
PREVIOUS_BLOCK_HEIGHT=100

# Function to send a message to Telegram
send_telegram_message() {
  if [ "$ENABLE" == "false" ]; then
    return  # Exit the function if notifications are disabled
  fi

  message="$1"
  # Use curl to send a POST request with the message to Telegram
  curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
       -d "chat_id=$TELEGRAM_CHAT_ID" \
       -d "text=$message" > /dev/null 2>&1
}

# Function to check if the external RPC server is available
is_server_available() {
    if curl --output /dev/null --silent --head --fail "$EXTERNAL_RPC_SERVER/status"; then
        return 0  # Server is available
    else
        return 1  # Server is not available
    fi
}

# Function to get information about the node
get_node_info() {
  while true; do
    response=$(curl -s ${RPC_SERVER}/status)

    if [ -z "$response" ]; then
      send_telegram_message "STORY $NODE_NAME Node is not responding, please check it."
      echo "Waiting for 5 minutes before rechecking..."
      sleep 300
    else
      break  # Exit the loop if the node is available
    fi
  done
  
while true; do
    if is_server_available; then
        block_height=$(echo "$response" | jq -r '.result.sync_info.latest_block_height')
        expected_block_height=$(curl -s "$EXTERNAL_RPC_SERVER/status" | jq -r '.result.sync_info.latest_block_height')

        echo -e "Block Height: ${BLUE}${block_height}${NC}"
        echo -e "Expected Block Height: ${BLUE}${expected_block_height}${NC}"
    else
        printRed "EXTERNAL_RPC_SERVER is not available. Skipping expected block height check."
        break
    fi

  if [ $(($expected_block_height - $block_height)) -ge "$BLOCK_GAP_ALARM" ]; then
    diff=$(($expected_block_height - $block_height))
    send_telegram_message "STORY node \"$NODE_NAME\"
>>> Block height: ${block_height} (current) / ${expected_block_height} (expected)
>>> Difference: $diff blocks
>>> Please check your node."
    
    echo -e "Current block height: ${RED}${block_height}${NC} / Expected block height: ${RED}${expected_block_height}${NC}"
    echo -e "Difference: ${RED}${diff} blocks${NC}. Please check your node. Rechecking height difference after 10 minutes..."
    sleep 600
    response=$(curl -s ${RPC_SERVER}/status)
    block_height=$(echo "$response" | jq -r '.result.sync_info.latest_block_height')
    expected_block_height=$(curl -s "$EXTERNAL_RPC_SERVER/status" | jq -r '.result.sync_info.latest_block_height')
  else
    break  # Exit the loop if the condition is met
  fi
done

    # If the node is available, continue with information extraction
    block_height=$(echo "$response" | jq -r '.result.sync_info.latest_block_height')
    catching_up=$(echo "$response" | jq -r '.result.sync_info.catching_up')
    validator_address=$(echo "$response" | jq -r '.result.validator_info.address')

    echo -e "Catching Up: ${BLUE}${catching_up}${NC}"
}

# Function to get Validator info
get_validator_info() {
  # Use curl to send a JSON-RPC request to the node
  validator_info=$(curl -s ${RPC_SERVER}/status | jq -sr '.[].result.validator_info')
  printBlue "$validator_info"
  voting_power=$(echo "$response" | jq -r '.result.validator_info.voting_power')
  
# Checking for changes in voting_power
  check_voting_power_change
}

# Function to get signatures for a block
get_signatures() {
  local block_height=$1

  if is_server_available; then
    # Use EXTERNAL_RPC_SERVER if it's available
    curl -s "${EXTERNAL_RPC_SERVER}/block?height=${block_height}" | jq -r '.result.block.last_commit.signatures[].validator_address'
  else
    # Use RPC_SERVER if EXTERNAL_RPC_SERVER is not available
    curl -s "${RPC_SERVER}/block?height=${block_height}" | jq -r '.result.block.last_commit.signatures[].validator_address'
  fi
}

# Function to check validator activity
check_validator_activity() {
  local current_block_height=$1
  local missed_blocks=0
  local max_consecutive_missed=0
  local current_consecutive_missed=0

  echo "Checking validator activity starting from block $current_block_height... "

  if [ "$current_block_height" -le "$PREVIOUS_BLOCK_HEIGHT" ]; then
    echo "Current block height is not higher than the previously checked height. Exiting the function."
    return
  fi

  for (( i=current_block_height-1; i>current_block_height-300 && i>PREVIOUS_BLOCK_HEIGHT; i-- )); do
#    echo "Checking block $i..."
    signatures=$(get_signatures $i)

    if ! echo "$signatures" | grep -q "$validator_address"; then
      missed_blocks=$((missed_blocks+1))
      current_consecutive_missed=$((current_consecutive_missed+1))
      max_consecutive_missed=$((max_consecutive_missed < current_consecutive_missed ? current_consecutive_missed : max_consecutive_missed))
      printBlue "Block $i: Missed. Current number of missed blocks: $missed_blocks."
    else
      current_consecutive_missed=0
      echo "Block $i: Voted."
    fi
  done

  PREVIOUS_BLOCK_HEIGHT=$current_block_height

  if [ $missed_blocks -gt $MISSED_BLOCKS_ALARM ]; then
    echo "--------------------------------------------------------------------"
    printRed "Validator $validator_address missed $missed_blocks out of the last 300 blocks, with $max_consecutive_missed missed in a row. Sending message to Telegram."
    send_telegram_message "$NODE_NAME Validator $validator_address missed $missed_blocks out of the last 300 blocks, with $max_consecutive_missed missed in a row."
  else
    echo "--------------------------------------------------------------------"
    printGreen "Validator $validator_address missed $missed_blocks blocks out of the last 300."
  fi
}

# Function to check for changes in voting_power
check_voting_power_change() {
  current_voting_power=$(echo "$validator_info" | jq -r '.voting_power')

  # Only perform the check if PREVIOUS_VOTING_POWER has been set
  if [ -n "$PREVIOUS_VOTING_POWER" ]; then
    # Send a message to Telegram if there is a change in the voting_power
    if [ "$current_voting_power" -lt "$PREVIOUS_VOTING_POWER" ]; then
      if [ "$TELEGRAM_VP" == "true" ]; then
        send_telegram_message "$NODE_NAME Voting Power decreased. Previous: $PREVIOUS_VOTING_POWER, Current: $current_voting_power"
      fi
      printRed "Voting Power decreased. Previous: $PREVIOUS_VOTING_POWER, Current: $current_voting_power"
    elif [ "$current_voting_power" -gt "$PREVIOUS_VOTING_POWER" ]; then
      if [ "$TELEGRAM_VP" == "true" ]; then
        send_telegram_message "$NODE_NAME Voting Power increased. Previous: $PREVIOUS_VOTING_POWER, Current: $current_voting_power"
      fi
      printGreen "Voting Power increased. Previous: $PREVIOUS_VOTING_POWER, Current: $current_voting_power"
    fi
  fi

  # Update the variable for the next check
  PREVIOUS_VOTING_POWER=$current_voting_power
}

# Function to check node status and validator info
check_node() {
  echo "Checking node status..."
  get_node_info
  echo "Getting Validator Info..."
  get_validator_info
  
# Calling the Validator activity check function
  if [ -n "$block_height" ] && [ "$voting_power" -gt 0 ]; then
    check_validator_activity "$block_height"
  fi
  
  echo "Checking node status..."
  get_node_info
  echo "Getting Validator Info..."
  get_validator_info
  
  echo "Sleeping for 15 minutes..."
    echo "--------------------------------------------------------------------"
}

# Infinite loop to check the node every 15 minutes
while true; do
  check_node
  sleep 900
done
