#!/bin/bash

# Configure your Telegram BOT_TOKEN, CHAT_ID, Node_name, monitoring_message
NODE_NAME="Chainbase"
TELEGRAM_BOT_TOKEN=""  # Add your bot token here
TELEGRAM_CHAT_ID=""    # Add your chat ID here
CHAINBASE_PATH="/root/chainbase-avs-setup/holesky/"  # Ensure the correct path
SLEEP="15m"

# Function to send a message to Telegram
send_telegram_message() {
    local message=$1
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" -d chat_id="$TELEGRAM_CHAT_ID" -d text="$message" -d parse_mode="Markdown"
}

# Function to check Chainbase node
check_chainbase() {
    cd $CHAINBASE_PATH || exit  # Ensure the directory exists
    CHAINBASE_OUTPUT=$(./chainbase-avs.sh test 2>&1)
    echo "Chainbase output: $CHAINBASE_OUTPUT"
    sleep 2
    if echo "$CHAINBASE_OUTPUT" | grep -q "All systems are working for your manuscript node"; then
        echo "Chainbase node is operating normally, waiting ${SLEEP}..."
    else
        echo "Chainbase node check failed. Sending tg notification"
        MESSAGE="Chainbase node: issue detected. '${CHAINBASE_OUTPUT}'. Please check."
        send_telegram_message "$MESSAGE"
    fi
}

# Main loop
while true; do
    # Call Chainbase check function
    echo "Checking Chainbase node..."
    check_chainbase

    echo "Waiting ${SLEEP} and checking again..."
    sleep ${SLEEP}
done
