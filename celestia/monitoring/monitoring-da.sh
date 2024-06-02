#!/bin/bash

# Your variables
TELEGRAM_BOT_TOKEN=""
TELEGRAM_CHAT_ID=""
NODE_NAME="Cel_M_bridge"
SERVICE="celestia-bridge"
CELESTIA_APP_BIN="/home/celbridge/go/bin/celestia-appd"
PARENT_RPC="https://celestia-mainnet-rpc.itrocket.net"
MIN_BALANCE=100000 #utia
BLOCK_DIFF=1
SLEEP=15m

# Function to send messages to Telegram
send_telegram() {
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" -d chat_id=$TELEGRAM_CHAT_ID -d text="$1"
    echo "Sent Telegram message: $1" # Log message being sent
}

while true; do
    echo "----------------------------------------------------"
    echo "Checking service status..."
    # Check service status
    if ! systemctl is-active --quiet $SERVICE; then
        message="The service $SERVICE is not running, please check."
        echo $message
        send_telegram "$message"
    else
        echo "Service $SERVICE is running. Checking logs..."
        # Read the last 50 lines of the log
        log_output=$(journalctl -u $SERVICE -n 200 -o cat)

        # Extract the number of the last finalized block
        current_block=$(echo "$log_output" | grep -oP 'new head.*"height": \K\d+' | sort -n | tail -n 1)

        if [ -z "$current_block" ]; then
            message="Failed to obtain the last block number from the logs of $NODE_NAME."
            echo $message
            send_telegram "$message"
        else
            echo "Current block from logs: $current_block"
            # Get the current block height from PARENT_RPC
            parent_height=$(curl -s "$PARENT_RPC/block" | jq '.result.block.header.height' | tr -d '"')
            echo "Parrent block from RPC:  $parent_height"

            if [ -z "$parent_height" ]; then
                message="Failed to retrieve block height from $PARENT_RPC."
                echo $message
                send_telegram "$message"
            elif [ $(($parent_height - $current_block)) -gt $BLOCK_DIFF ]; then
                message="Block height in $NODE_NAME is more than $BLOCK_DIFF blocks behind $PARENT_RPC. 
"----------------------------------------------------"
Node height:  $current_block 
Chain height: $parent_height"
                echo $message
                send_telegram "$message"
            else
                echo "Block height difference is within acceptable range."
            fi
        fi

        # Checking wallet balances
        if [ -z "$WALLETS" ]; then
            echo "----------------------------------------------------"
            echo "No wallets given for the balance check"
        else
            echo "----------------------------------------------------"
            echo "Checking wallet balances..."
            # Iterating over wallets
            for wallet in "${WALLETS[@]}"; do
                echo "Checking wallet $wallet..."
                # Getting the wallet's balance
                balance=$(${CELESTIA_APP_BIN} q bank balances $wallet --node ${PARENT_RPC}:443 | grep -oP 'amount: "\K\d+')
                if [ $balance -lt $MIN_BALANCE ]; then
                    message="$NODE_NAME 
>> Balance of $wallet is less than $MIN_BALANCE
>> Current balance: $(echo "scale=1; ${balance}/1000000" | bc) TIA"
                    echo $message
                    send_telegram "$message"
                else
                    echo "Balance of wallet is acceptable: $(echo "scale=1; ${balance}/1000000" | bc) TIA"
                fi
            done
        fi
    fi
    
    # Delay before the next iteration
    echo "----------------------------------------------------"
    echo "Sleeping for $SLEEP..."
    sleep $SLEEP
done
