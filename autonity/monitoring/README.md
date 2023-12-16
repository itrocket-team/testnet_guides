```
cd $HOME
NETWORK="$USER"
TELEGRAM_BOT_TOKEN="REDACTED"
TELEGRAM_CHAT_ID="-724741147"
RPC="https://x1-testnet-rpc.itrocket.net:443"
SLEEP="1m"
```

Create SH file
```
#!/bin/bash

# Variables
TELEGRAM_BOT_TOKEN=""
TELEGRAM_CHAT_ID=""
# Set VALIDATOR_ADDRESS to enable commit status checks for that validator
VALIDATOR_ADDRESS=""

# Missing validator alert text
MESSAGE="Alert: Autonity Validator address $VALIDATOR_ADDRESS is missing from the current Autonity committee list"
# Parrent RPC address
PARRENT_RPC="https://rpc1.piccadilly.autonity.org"
# Threshold for block height difference
BLOCK_HEIGHT_DIFF="2"

# Function for sending messages to Telegram
send_telegram() {
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" -d chat_id=$TELEGRAM_CHAT_ID -d text="$1"
}

# Main loop
while true; do
    echo "Checking blocks height..."

    # Retrieving block height from your node
    HEIGHT=$(aut block height 2>&1)
    if [[ $? -ne 0 ]]; then
        send_telegram "Autonity local node error or invalid response: $HEIGHT"
        echo "Error: Autonity local node error or invalid response: $HEIGHT"
        sleep 5
        continue # Proceeding to the next iteration of the loop
    fi
    
    # Convert hex to decimal
    echo "Current Local Block Height: $HEIGHT"

    # Retrieving block height from the parent RPC
    PARENT_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' $PARRENT_RPC)
    PARENT_HEIGHT=$(echo $PARENT_RESPONSE | jq -r '.result')
    if [[ $PARENT_RESPONSE == "" ]] || [[ $PARENT_HEIGHT == null ]]; then
        echo "Error: Autonity Parent RPC $PARRENT_RPC is down or sent an invalid response."
        PARENT_HEIGHT=0
        sleep 5
        continue
    fi
    
     # Convert hex to decimal using printf
    PARENT_HEIGHT_DEC=$(printf "%d" "$PARENT_HEIGHT")
    echo "Parent RPC Block Height: $PARENT_HEIGHT_DEC"

    # Checking the difference in block height
    if [[ $HEIGHT -ne 0 ]] && [[ $PARENT_HEIGHT -ne 0 ]]; then
        DIFF=$(($PARENT_HEIGHT - $HEIGHT))
        if [[ $DIFF -gt $BLOCK_HEIGHT_DIFF ]]; then
            send_telegram "Autonity ITRocket RPC Block height difference is more than $BLOCK_HEIGHT_DIFF. RPC: $HEIGHT, Parent RPC: $PARENT_HEIGHT."
            echo "Alert: Block height difference is more than $BLOCK_HEIGHT_DIFF. RPC: $HEIGHT, Parent RPC: $PARENT_HEIGHT."
        else
            echo "Block height within acceptable range."
        fi
    fi

    # Checking if the validator is signing blocks
    if [[ -n $VALIDATOR_ADDRESS ]]; then
        echo "Checking if the validator is committing blocks..."
        OUTPUT=$(aut protocol get-committee 2>&1)

        # Check for errors in the command execution
        if [ $? -ne 0 ]; then
            ERROR_MSG="Autonity Error executing command: $OUTPUT"
            send_telegram "$ERROR_MSG"
        else
            # Check if the validator address is in the output
            if echo $OUTPUT | grep -q $VALIDATOR_ADDRESS; then
                echo "Validator address $VALIDATOR_ADDRESS has successfully committed."
            else
                send_telegram "$MESSAGE"
            fi
        fi
    else
        echo "Validator address not set. Skipping commit check."
    fi

    # Wait for 5 minutes
    echo "--------------------------------------"
    echo "Waiting 5 minutes before next check..."
    sleep 300
done
EOF
```

Add permissions
```
cd $HOME
chmod +x ${USER}-rpc-monitoring.sh
```

Create Service file
```
sudo tee /etc/systemd/system/${USER}-rpc-monitoring.service > /dev/null <<EOF
[Unit]
Description=${USER}-rpc monitoring script
After=network.target

[Service]
User=root
ExecStart=${HOME}/${USER}-rpc-monitoring.sh
WorkingDirectory=$HOME
StandardOutput=inherit
StandardError=inherit
Restart=always

[Install]
WantedBy=multi-user.target
EOF
```

Enable and start service
```
sudo systemctl daemon-reload
sudo systemctl enable ${USER}-rpc-monitoring.service
sudo systemctl restart ${USER}-rpc-monitoring && sudo journalctl -u ${USER}-rpc-monitoring -f
```

### Delete
```
sudo systemctl stop ${SERVICE}-monitoring
sudo systemctl disable ${SERVICE}-monitoring
sudo rm -rf /etc/systemd/system/${SERVICE}-monitoring.service
```
