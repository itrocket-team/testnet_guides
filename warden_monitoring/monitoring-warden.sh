#!/bin/bash

# Variables
NODE_NAME="Warden_Oracle"
TELEGRAM_BOT_TOKEN="your_bot_token"
TELEGRAM_CHAT_ID="your_chat_id"
RPC="http://localhost:20657" # warden node rpc
ORACLE_URL="http://localhost:8080/slinky/oracle/v1/prices"
PARENT_RPC="https://warden-testnet-rpc.itrocket.net"
SLEEP_INTERVAL=15 # Interval in minutes (can be changed to 10, 15, etc.)
MAX_ATTEMPTS=10   # Maximum number of connection attempts

# Function to send messages to Telegram
send_telegram() {
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" -d chat_id=$TELEGRAM_CHAT_ID -d text="$1"
}

# Function to calculate the time until the next interval
time_to_next_interval() {
    local current_minute=$(date +%M)
    local next_interval=$(( (current_minute / SLEEP_INTERVAL + 1) * SLEEP_INTERVAL ))
    local sleep_time=$(( next_interval * 60 - $(date +%s) % 3600 ))
    echo $sleep_time
}

# Function to check block heights
check_block_height() {
    echo "Checking RPC block height..."

    # Get block height from your RPC
    ATTEMPTS=0
    while [[ $ATTEMPTS -lt $MAX_ATTEMPTS ]]; do
        RESPONSE=$(curl -s --max-time 3 "$RPC/block")
        HEIGHT=$(echo $RESPONSE | jq -r '.result.block.header.height' 2>/dev/null)
        if [[ $HEIGHT =~ ^[0-9]+$ ]]; then
            break
        fi
        ATTEMPTS=$((ATTEMPTS + 1))
        echo "Attempt $ATTEMPTS/$MAX_ATTEMPTS: RPC $RPC is down or sent an invalid response. Retrying in 5 seconds..."
        sleep 5
    done

    if [[ $ATTEMPTS -eq $MAX_ATTEMPTS ]]; then
        send_telegram "$NODE_NAME RPC $RPC is down or sent an invalid response after $MAX_ATTEMPTS attempts."
        echo "Error: $NODE_NAME RPC $RPC is down or sent an invalid response after $MAX_ATTEMPTS attempts."
        return
    fi
    echo "Current RPC Block Height: $HEIGHT"

    # Get block height from parent RPC
    ATTEMPTS=0
    while [[ $ATTEMPTS -lt $MAX_ATTEMPTS ]]; do
        PARENT_RESPONSE=$(curl -s --max-time 3 "$PARENT_RPC/block")
        PARENT_HEIGHT=$(echo $PARENT_RESPONSE | jq -r '.result.block.header.height' 2>/dev/null)
        if [[ $PARENT_HEIGHT =~ ^[0-9]+$ ]]; then
            break
        fi
        ATTEMPTS=$((ATTEMPTS + 1))
        echo "Attempt $ATTEMPTS/$MAX_ATTEMPTS: Parent RPC $PARENT_RPC is down or sent an invalid response. Retrying in 5 seconds..."
        sleep 5
    done

    if [[ $ATTEMPTS -eq $MAX_ATTEMPTS ]]; then
        send_telegram "$NODE_NAME Parent RPC $PARENT_RPC is down or sent an invalid response after $MAX_ATTEMPTS attempts."
        echo "Error: $NODE_NAME Parent RPC $PARENT_RPC is down or sent an invalid response after $MAX_ATTEMPTS attempts."
        return
    fi

    echo "Parent RPC Block Height: $PARENT_HEIGHT"

    # Check block height difference
    if [[ $HEIGHT -ne 0 ]] && [[ $PARENT_HEIGHT -ne 0 ]]; then
        DIFF=$((PARENT_HEIGHT - HEIGHT))
        if [[ $DIFF -gt 2 ]]; then
            send_telegram "$NODE_NAME RPC Block height difference $DIFF. 
>>>>>>>RPC: $HEIGHT 
>Parent RPC: $PARENT_HEIGHT"
            echo "Alert: Block height difference is $DIFF. RPC: $HEIGHT, Parent RPC: $PARENT_HEIGHT."
        else
            echo "Block height within acceptable range."
        fi
    fi
}

# Function to check Oracle prices
check_oracle_prices() {
    echo "Checking Oracle prices..."

    RESPONSE=$(curl -s --max-time 10 "$ORACLE_URL")

    if [ $? -ne 0 ]; then
        send_telegram "$NODE_NAME: No response from Oracle at $ORACLE_URL. Please check the Oracle service."
        echo "Error: No response from Oracle at $ORACLE_URL."
        return
    fi

    PRICES_EXIST=$(echo "$RESPONSE" | jq -e '.prices' > /dev/null 2>&1; echo $?)
    
    # Check if prices are present and not empty
    if [ $PRICES_EXIST -ne 0 ] || [ "$(echo $RESPONSE | jq -r '.prices | length')" -eq 0 ]; then
        send_telegram "$NODE_NAME: No price data found or price data is empty in response from Oracle at $ORACLE_URL."
        echo "Error: No price data found or price data is empty in response from Oracle at $ORACLE_URL."
    else
        echo "Oracle price data is present and correct."
    fi
}

# Main loop
while true; do
    check_block_height
    check_oracle_prices

    # Calculate time until the next check
    SLEEP_TIME=$(time_to_next_interval)
    echo "Waiting $SLEEP_TIME seconds before next check..."
    sleep $SLEEP_TIME
done
