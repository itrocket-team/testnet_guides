#!/bin/bash

if ! command -v jq &> /dev/null || ! command -v curl &> /dev/null; then
    echo "jq and curl are required but not installed. Please install them and try again."
    exit 1
fi

# Configuration
TELEGRAM_BOT_TOKEN=""
TELEGRAM_CHAT_ID=""
STORAGE_RPC_PORT="5678" # Default port 5678. If you don`t want to monitor storage node, leave the field empty
VALIDATOR_RPC_PORT="" # Default port 26657. If you don`t want to monitor validator node, leave the field empty
NODE_NAME="0G_NODE"
PARENT_RPC="https://og-testnet-rpc.itrocket.net"
SLEEP_INTERVAL=15 # Script check interval
MAX_ATTEMPTS=10   # Number of checks

#Do not modify 
STORAGE_RPC="http://localhost:$STORAGE_RPC_PORT"
VALIDATOR_RPC="http://localhost:$VALIDATOR_RPC_PORT"

send_telegram() {
    local message="$1"
    echo "$message"
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" -d chat_id=$TELEGRAM_CHAT_ID -d text="$message"
}

time_to_next_interval() {
    local current_minute=$(date +%M)
    local next_interval=$(( (current_minute / SLEEP_INTERVAL + 1) * SLEEP_INTERVAL ))
    local sleep_time=$(( next_interval * 60 - $(date +%s) % 3600 ))
    echo $sleep_time
}

check_block_height_and_peers() {
    local RPC=$1
    echo "0G_STORAGE_NODE: Checking RPC block height and connected peers for $RPC..."

    RESPONSE=$(curl -s -X POST $RPC -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"zgs_getStatus","params":[],"id":1}')
    if [[ $? -ne 0 ]]; then
        echo "0G_STORAGE_NODE: Error: Failed to get response from $RPC"
        send_telegram "0G_STORAGE_NODE: Failed to get response from $RPC"
        return 1
    fi

    HEIGHT=$(echo $RESPONSE | jq -r '.result.logSyncHeight' 2>/dev/null)
    PEERS=$(echo $RESPONSE | jq -r '.result.connectedPeers' 2>/dev/null)

    echo "0G_STORAGE_NODE: Srorage Node height: $HEIGHT"
    echo "0G_STORAGE_NODE: Connected peers: $PEERS"

    if [[ -z $HEIGHT || -z $PEERS ]]; then
        echo "0G_STORAGE_NODE: Error: Invalid response from RPC $RPC"
        send_telegram "0G_STORAGE_NODE: Invalid response from RPC $RPC"
        return 1
    fi

    if [[ $PEERS -eq 0 ]]; then
        send_telegram "0G_STORAGE_NODE: RPC $RPC has 0 connected peers."
        echo "0G_STORAGE_NODE: Alert: RPC $RPC has 0 connected peers."
    fi

    ATTEMPTS=0
    while [[ $ATTEMPTS -lt $MAX_ATTEMPTS ]]; do
        PARENT_HEIGHT=$(curl -s --max-time 10 "$PARENT_RPC/block" | jq -r '.result.block.header.height' 2>/dev/null)
        if [[ $PARENT_HEIGHT =~ ^[0-9]+$ ]]; then
            break
        fi
        ATTEMPTS=$((ATTEMPTS + 1))
        echo "0G_STORAGE_NODE: Attempt $ATTEMPTS/$MAX_ATTEMPTS: Parent RPC $PARENT_RPC is down or sent an invalid response. Retrying in 5 seconds..."
        sleep 5
    done

    if [[ $ATTEMPTS -eq $MAX_ATTEMPTS ]]; then
        send_telegram "0G_STORAGE_NODE: Parent RPC $PARENT_RPC is down or sent an invalid response after $MAX_ATTEMPTS attempts."
        echo "0G_STORAGE_NODE: Error: Parent RPC $PARENT_RPC is down or sent an invalid response after $MAX_ATTEMPTS attempts."
        return 1
    fi

    echo "0G_STORAGE_NODE: Parent RPC block height: $PARENT_HEIGHT"

    if [[ $HEIGHT -ne 0 ]] && [[ $PARENT_HEIGHT -ne 0 ]]; then
        DIFF=$((PARENT_HEIGHT - HEIGHT))
        if [[ $DIFF -gt 25 ]]; then
            send_telegram "0G_STORAGE_NODE: RPC block height difference $DIFF. RPC: $HEIGHT, Parent RPC: $PARENT_HEIGHT."
            echo "0G_STORAGE_NODE: Block height difference is $DIFF. RPC: $HEIGHT, Parent RPC: $PARENT_HEIGHT."
        else
            echo "0G_STORAGE_NODE: Block height within acceptable range."
        fi
    fi

    return 0
}

check_block_height() {
    local RPC=$1
    echo "0G_VALIDATOR_NODE: Checking RPC block height for $RPC..."

    RESPONSE=$(curl -s --max-time 3 "$RPC/block")
    if [[ $? -ne 0 ]]; then
        echo "0G_VALIDATOR_NODE: Error: Failed to get response from $RPC"
        send_telegram "0G_VALIDATOR_NODE: Failed to get response from $RPC"
        return 1
    fi

    HEIGHT=$(echo $RESPONSE | jq -r '.result.block.header.height' 2>/dev/null)

    echo "0G_VALIDATOR_NODE: Current RPC block height: $HEIGHT"

    if [[ -z $HEIGHT ]]; then
        echo "0G_VALIDATOR_NODE: Error: Invalid response from RPC $RPC"
        send_telegram "0G_VALIDATOR_NODE: Invalid response from RPC $RPC"
        return 1
    fi

    ATTEMPTS=0
    while [[ $ATTEMPTS -lt $MAX_ATTEMPTS ]]; do
        PARENT_HEIGHT=$(curl -s --max-time 10 "$PARENT_RPC/block" | jq -r '.result.block.header.height' 2>/dev/null)
        if [[ $PARENT_HEIGHT =~ ^[0-9]+$ ]]; then
            break
        fi
        ATTEMPTS=$((ATTEMPTS + 1))
        echo "0G_VALIDATOR_NODE: Attempt $ATTEMPTS/$MAX_ATTEMPTS: Parent RPC $PARENT_RPC is down or sent an invalid response. Retrying in 5 seconds..."
        sleep 5
    done

    if [[ $ATTEMPTS -eq $MAX_ATTEMPTS ]]; then
        send_telegram "0G_VALIDATOR_NODE: Parent RPC $PARENT_RPC is down or sent an invalid response after $MAX_ATTEMPTS attempts."
        echo "0G_VALIDATOR_NODE: Error: Parent RPC $PARENT_RPC is down or sent an invalid response after $MAX_ATTEMPTS attempts."
        return 1
    fi

    echo "0G_VALIDATOR_NODE: Parent RPC block height: $PARENT_HEIGHT"

    if [[ $HEIGHT -ne 0 ]] && [[ $PARENT_HEIGHT -ne 0 ]]; then
        DIFF=$((PARENT_HEIGHT - HEIGHT))
        if [[ $DIFF -gt 25 ]]; then
            send_telegram "0G_VALIDATOR_NODE: RPC block height difference $DIFF. RPC: $HEIGHT, Parent RPC: $PARENT_HEIGHT."
            echo "0G_VALIDATOR_NODE: Alert: Block height difference is $DIFF. RPC: $HEIGHT, Parent RPC: $PARENT_HEIGHT."
        else
            echo "0G_VALIDATOR_NODE: Block height within acceptable range."
        fi
    fi

    return 0
}

while true; do
    if [[ -n "$STORAGE_RPC_PORT" ]]; then
        echo "0G_STORAGE_NODE: Storage RPC: $STORAGE_RPC"
        check_block_height_and_peers "$STORAGE_RPC"
        echo "----------------------------------------"
    fi

    if [[ -n "$VALIDATOR_RPC_PORT" ]]; then
        echo "0G_VALIDATOR_NODE: Validator RPC: $VALIDATOR_RPC"
        check_block_height "$VALIDATOR_RPC"
        echo "----------------------------------------"
    fi

    SLEEP_TIME=$(time_to_next_interval)
    echo "0G_NODE: Waiting $SLEEP_TIME seconds before next check..."
    sleep $SLEEP_TIME
done
