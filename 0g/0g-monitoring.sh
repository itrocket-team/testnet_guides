#!/bin/bash

# Ensure required dependencies are installed
if ! command -v jq &> /dev/null || ! command -v curl &> /dev/null; then
    echo "jq and curl are required but not installed. Please install them and try again."
    exit 1
fi

# Configuration
TELEGRAM_BOT_TOKEN=""
TELEGRAM_CHAT_ID=""
STORAGE_RPC_PORT="5678" # Leave empty if storage node monitoring is not needed
NODE_NAME="0G_NODE"
PARENT_RPC="https://og-testnet-rpc.itrocket.net"
SLEEP_TIME=15m # Interval between checks
MAX_ATTEMPTS=10 # Number of retry attempts for parent RPC

# Derived variable
STORAGE_RPC="http://localhost:$STORAGE_RPC_PORT"

# Function to send Telegram notifications
send_telegram() {
    local message="$1"
    echo "$message"
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
        -d chat_id=$TELEGRAM_CHAT_ID \
        -d text="$message" &> /dev/null
}

# Function to fetch JSON field safely
fetch_json_field() {
    local json="$1"
    local field="$2"
    echo "$json" | jq -r "$field" 2>/dev/null
}

# Function to check block height and peers
check_block_height_and_peers() {
    local rpc="$1"
    echo "$NODE_NAME: Checking RPC block height and connected peers for $rpc..."

    local response=$(curl -s -X POST "$rpc" -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","method":"zgs_getStatus","params":[],"id":1}')

    if [[ -z "$response" ]]; then
        send_telegram "$NODE_NAME: Failed to get response from $rpc"
        return 1
    fi

    local height=$(fetch_json_field "$response" '.result.logSyncHeight')
    local peers=$(fetch_json_field "$response" '.result.connectedPeers')

    if [[ -z "$height" || -z "$peers" ]]; then
        send_telegram "$NODE_NAME: Invalid response from RPC $rpc"
        return 1
    fi

    echo "$NODE_NAME: Storage node height: $height"
    echo "$NODE_NAME: Connected peers: $peers"

    if [[ $peers -eq 0 ]]; then
        send_telegram "$NODE_NAME: RPC $rpc has 0 connected peers."
    fi

    # Check parent RPC block height
    for attempt in $(seq 1 $MAX_ATTEMPTS); do
        local parent_height=$(curl -s --max-time 10 "$PARENT_RPC/block" | jq -r '.result.block.header.height' 2>/dev/null)
        if [[ $parent_height =~ ^[0-9]+$ ]]; then
            break
        fi
        echo "$NODE_NAME: Attempt $attempt/$MAX_ATTEMPTS: Parent RPC $PARENT_RPC is unavailable. Retrying in 5 seconds..."
        sleep 5
    done

    if [[ -z $parent_height || ! $parent_height =~ ^[0-9]+$ ]]; then
        send_telegram "$NODE_NAME: Parent RPC $PARENT_RPC is unavailable after $MAX_ATTEMPTS attempts."
        return 1
    fi

    echo "$NODE_NAME: Parent RPC block height: $parent_height"

    # Compare block heights
    local diff=$((parent_height - height))
    if [[ $diff -gt 25 ]]; then
        send_telegram "$NODE_NAME: Block height difference is $diff. RPC: $height, Parent RPC: $parent_height."
    else
        echo "$NODE_NAME: Block height is within acceptable range."
    fi

    return 0
}

# Main loop
while true; do
    if [[ -n "$STORAGE_RPC_PORT" ]]; then
        echo "$NODE_NAME: Storage RPC: $STORAGE_RPC"
        check_block_height_and_peers "$STORAGE_RPC"
        echo "----------------------------------------"
    fi

    echo "$NODE_NAME: Waiting $SLEEP_TIME before next check..."
    echo "----------------------------------------"
    sleep $SLEEP_TIME
done
