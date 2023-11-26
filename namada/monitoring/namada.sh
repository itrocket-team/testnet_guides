#!/bin/bash

# Validator Node RPC server address
RPC_SERVER="http://127.0.0.1:26657"

# Telegram chat ID
TELEGRAM_CHAT_ID="<TELEGRAM_CHAT_ID>"

# Telegram bot token
TELEGRAM_BOT_TOKEN="<TELEGRAM_TOKEN>"

# Alert threshold for the block height difference between the node and network
BLOCK_GAP_ALARM=100

# Change to false if you don't want to allow the node restart function
RESTART=true

# External RPC server address to get the expected block height
EXTERNAL_RPC_SERVER="https://namada-testnet-rpc.itrocket.net:443"

# Function to send a message to Telegram
send_telegram_message() {
  message="$1"
  # Use curl to send a POST request with the message to Telegram
  curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
       -d "chat_id=$TELEGRAM_CHAT_ID" \
       -d "text=$message"
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
      if [ "$RESTART" == "true" ]; then
        sudo systemctl restart namadad
        send_telegram_message "NAMADA node not responding. But, service has been restarted."
      else
        send_telegram_message "Namada Node is not responding, please check it."
      fi
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

        echo "Block Height: $block_height"
        echo "Expected Block Height: $expected_block_height"
    else
        echo "EXTERNAL_RPC_SERVER is not available. Skipping expected block height check."
        break
    fi

  if [ $(($expected_block_height - $block_height)) -ge "$BLOCK_GAP_ALARM" ]; then
    if [ "$RESTART" == "true" ]; then
      sudo systemctl restart namadad
      send_telegram_message "NAMADA node
      >>> ${block_height}/${expected_block_height} diff $(($expected_block_height - $block_height)) 
      > but service has been restarted"
      echo "${block_height}/${expected_block_height} diff $(($expected_block_height - $block_height)), but service has been restarted, rechecking after 10 min... "
    else
      send_telegram_message "NAMADA node
      >>> ${block_height}/${expected_block_height} diff $(($expected_block_height - $block_height))
      > but restart is disabled."
      echo "${block_height}/${expected_block_height} diff $(($expected_block_height - $block_height)), but restart is disabled, rechecking after 10 min..."
    fi
    sleep 600  # 10 minutes in seconds
  else
    break  # Exit the loop if the condition is met
  fi
done

    # If the node is available, continue with information extraction
    block_height=$(echo "$response" | jq -r '.result.sync_info.latest_block_height')
    catching_up=$(echo "$response" | jq -r '.result.sync_info.catching_up')
    validator_address=$(echo "$response" | jq -r '.result.validator_info.address')

    echo "Block Height: $block_height"
    echo "Catching Up: $catching_up"
    echo "Validator Address: $validator_address"
}

# Function to get Validator info
get_validator_info() {
  # Use curl to send a JSON-RPC request to the node
  validator_info=$(curl -s ${RPC_SERVER}/status | jq -sr '.[].result.validator_info')
  echo "$validator_info"
}

# Function to check node status and validator info
check_node() {
  echo "Checking node status..."
  get_node_info
  echo "Getting Validator Info..."
  get_validator_info
  echo "Sleeping for 10 minutes..."
}

# Infinite loop to check the node every 15 minutes
while true; do
  check_node
  sleep 600
done
