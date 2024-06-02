# Celestia Bridge Storage node monitoring script

- **Tracks DA Node status (every 15m)**
- **Compares block height with an external server (every 15m)**
- **Checks Bridge node wallet balance (every 15m)**
- **Sends alerts and status updates via Telegram**

[ITRocket team Celestia services full list](https://itrocket.net/services/)

### Configure Telegram alerting:
Open Telegram and find `@BotFather`
- Here are the [instructions](https://sematext.com/docs/integration/alerts-telegram-integration/)
- How to get [chat id](https://stackoverflow.com/questions/32423837/telegram-bot-how-to-get-a-group-chat-id)

After creating telegram bot and group, specify the variables:
- set values for `TELEGRAM_BOT_TOKEN=` and `TELEGRAM_CHAT_ID=""`
~~~
TELEGRAM_BOT_TOKEN="<BOT_TOKEN>" # Telegram bot token
TELEGRAM_CHAT_ID="<CHAT_ID>" # Telegram chat ID for notifications
NODE_NAME="Celestia_Mainnet_bridge_Node" # Name of the node
SERVICE_FILE_NAME="celestia-bridge" # Service file name for Celestia bridge node
PARENT_RPC="https://celestia-mainnet-rpc.itrocket.net" # URL of the parent RPC node
MIN_BALANCE=1000000 # Minimum balance threshold in utia
BLOCK_DIFF=1 # Block difference threshold
SLEEP=15m # Sleep interval between checks
~~~

## Create monitoring-bridge.sh file
~~~
cat <<EOF >"$HOME/monitoring-bridge.sh"
#!/bin/bash

# Your variables
TELEGRAM_BOT_TOKEN="$TELEGRAM_BOT_TOKEN"
TELEGRAM_CHAT_ID="$TELEGRAM_CHAT_ID"
NODE_NAME="$NODE_NAME"
SERVICE="$SERVICE_FILE_NAME"
PARENT_RPC="$PARENT_RPC"
WALLETS=("") # List addresses in quotes, separated by spaces, without commas.
MIN_BALANCE="$MIN_BALANCE" # Minimal utia balance
BLOCK_DIFF="$BLOCK_DIFF"
SLEEP="$SLEEP"

# Function to send messages to Telegram
send_telegram() {
    curl -s -X POST "https://api.telegram.org/bot\$TELEGRAM_BOT_TOKEN/sendMessage" -d chat_id=\$TELEGRAM_CHAT_ID -d text="\$1"
    echo "Sent Telegram message: \$1" # Log message being sent
}

while true; do
    echo "----------------------------------------------------"
    echo "Checking service status..."
    # Check service status
    if ! systemctl is-active --quiet \$SERVICE; then
        message="The service \$SERVICE is not running, please check."
        echo \$message
        send_telegram "\$message"
    else
        echo "Service \$SERVICE is running. Checking logs..."
        # Read the last 50 lines of the log
        log_output=\$(journalctl -u \$SERVICE -n 200 -o cat)

        # Extract the number of the last finalized block
        current_block=\$(echo "\$log_output" | grep -oP 'new head.*"height": \K\d+' | sort -n | tail -n 1)

        if [ -z "\$current_block" ]; then
            message="Failed to obtain the last block number from the logs of \$SERVICE."
            echo \$message
            send_telegram "\$message"
        else
            echo "Current block from logs: \$current_block"
            # Get the current block height from PARENT_RPC
            parent_height=\$(curl -s "\$PARENT_RPC/block" | jq '.result.block.header.height' | tr -d '"')
            echo "Parrent block from RPC:  \$parent_height"

            if [ -z "\$parent_height" ]; then
                message="Failed to retrieve block height from \$PARENT_RPC."
                echo \$message
                send_telegram "\$message"
            elif [ \$((\$parent_height - \$current_block)) -gt \$BLOCK_DIFF ]; then
                message="Block height in \$SERVICE is more than \$BLOCK_DIFF blocks behind \$PARENT_RPC. 
"----------------------------------------------------"
Node height:  \$current_block 
Chain height: \$parent_height"
                echo \$message
                send_telegram "\$message"
            else
                echo "Block height difference is within acceptable range."
            fi
        fi

        # Checking wallet balances
        if [ -z "\$WALLETS" ]; then
            echo "----------------------------------------------------"
            echo "No wallets given for the balance check"
        else
            echo "----------------------------------------------------"
            echo "Checking wallet balances..."
            # Iterating over wallets
            for wallet in "\${WALLETS[@]}"; do
                echo "Checking wallet \$wallet..."
                # Getting the wallet's balance
                balance=\$(\${CELESTIA_APPD_BIN} q bank balances \$wallet --node \${PARENT_RPC}:443 | grep -oP 'amount: "\K\d+')
                if [ \$balance -lt \$MIN_BALANCE ]; then
                    message="\$NODE_NAME 
>> Balance of \$wallet is less than \$MIN_BALANCE
>> Current balance: \$(echo "scale=1; \${balance}/1000000" | bc) TIA"
                    echo \$message
                    send_telegram "\$message"
                else
                    echo "Balance of wallet is acceptable: \$(echo "scale=1; \${balance}/1000000" | bc) TIA"
                fi
            done
        fi
    fi
    
    # Delay before the next iteration
    echo "----------------------------------------------------"
    echo "Sleeping for \$SLEEP..."
    sleep \$SLEEP
done
EOF
~~~

## Create service file

~~~
sudo tee /etc/systemd/system/monitoring-bridge.service > /dev/null <<EOF
[Unit]
Description=Celestia bridge-monitoring script
After=network.target

[Service]
User=$USER
ExecStart=$HOME/monitoring-bridge.sh
WorkingDirectory=$HOME
StandardOutput=inherit
StandardError=inherit
Restart=always

[Install]
WantedBy=multi-user.target
EOF
~~~

Enable and start service
~~~
chmod +x $HOME/monitoring-bridge.sh
sudo systemctl daemon-reload
sudo systemctl enable monitoring-bridge
sudo systemctl restart monitoring-bridge && sudo journalctl -u monitoring-bridge -f
~~~

Voilà! Enjoy the script ;)

## Delete
~~~
sudo systemctl stop monitoring-bridge
sudo systemctl disable monitoring-bridge
sudo rm -rf /etc/systemd/system/monitoring-bridge.service
~~~
