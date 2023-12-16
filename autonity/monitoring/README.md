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
cat <<EOF >"${USER}-rpc-monitoring.sh"
#!/bin/bash

# Configure your Telegram BOT_TOKEN and CHAT_ID here
TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN}"
TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID}"
NETWORK="${NETWORK}"
RPC="${RPC}"
TIMER="${SLEEP}"

# Function to send a message to Telegram
send_telegram_message() {
    local message=\$1
    curl -s -X POST "https://api.telegram.org/bot\$TELEGRAM_BOT_TOKEN/sendMessage" -d chat_id=\$TELEGRAM_CHAT_ID -d text="\$message"
}

# Function to get the block height
get_block_height() {
    response=\$(curl -s -H "Content-Type: application/json" -X POST --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":83}' \$RPC)
    if [ -z "\$response" ]; then
        echo "No response received"
        return
    fi
    # Check if the response is valid JSON
    if ! echo \$response | jq empty; then
        echo "Invalid JSON response"
        return
    fi
    echo \$response | jq -r '.result'
}

# Previous block height
previous_height=0

# Main loop
while true; do
    echo "Requesting the current block height..."
    current_height=\$(get_block_height)
    
    # Check if we received a valid response
    if [ -z "\$current_height" ] || [ "\$current_height" == "null" ] || [ "\$current_height" == "Invalid JSON response" ]; then
        echo "Error: Failed to retrieve block height."
        send_telegram_message "Error: \${NETWORK} Failed to retrieve block height."
        echo "Sleep \$TIMER and recheck..."
        sleep \$TIMER
        continue
    fi

    echo "Received block height: \$current_height"

    # Check if the current_height is a valid hexadecimal number
    if ! [[ \$current_height =~ ^0x[0-9a-fA-F]+$ ]]; then
        echo "Error: Invalid block height received: \$current_height"
        send_telegram_message "Error: \${NETWORK} Invalid block height received: \$current_height"
        echo "Sleep \$TIMER and recheck..."
        sleep \$TIMER
        continue
    fi

    # Remove '0x' prefix and convert the block height from hexadecimal to decimal
    current_height_decimal=\$((16#\${current_height:2}))

    # Compare with the previous block height
    if [ \$current_height_decimal -le \$previous_height ]; then
        echo "Warning: Block height is not increasing. Current height: \$current_height_decimal."
        send_telegram_message "Warning: \${NETWORK} Block height is not increasing. Current height: \$current_height_decimal."
    fi

    # Update the previous block height
    previous_height=\$current_height_decimal

    # Wait for 1 minute before the next check
    echo "Sleep \$TIMER and recheck..."
    sleep \$TIMER
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
