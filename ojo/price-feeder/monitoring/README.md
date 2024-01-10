# Price-feeder monitoring script
### Manual installation

Configure params:  
1. Create telegram bot via @BotFather, customize it and get bot API token [how_to](https://www.siteguarding.com/en/how-to-get-telegram-bot-api-token).
2. Create the group: alarm . Customize them, add the bot in your chat and get chats IDs [how_to](https://stackoverflow.com/questions/32423837/telegram-bot-how-to-get-a-group-chat-id). 
```
SERVICE="ojo-price-feeder"
MESSAGE="successfully broadcasted tx"
TELEGRAM_BOT_TOKEN=""
TELEGRAM_CHAT_ID=""
SLEEP="15m"
```

Create SH file
```
cat <<EOF >"${HOME}/${SERVICE}-monitoring.sh"
#!/bin/bash

# Function to send a message to Telegram
send_telegram_message() {
    local message=$1
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" -d chat_id="$TELEGRAM_CHAT_ID" -d text="$message" -d parse_mode="Markdown"
}

# Main loop of the script
while true; do
    # Check if the service is active before checking the logs
    if systemctl is-active --quiet ${SERVICE}; then
        # Service is active, now check for the log message
        if ! sudo journalctl -u ${SERVICE} --since "${SLEEP} ago" --no-pager --output cat | grep -i "${MESSAGE}"; then
            # Message not found, stopping and restarting the service
            echo "No '${MESSAGE}' message found in the logs for the past ${SLEEP} minutes. Restarting service."
            sudo systemctl stop ${SERVICE}
            sleep 30
            sudo systemctl restart ${SERVICE}
            # Sending a message to Telegram
            send_telegram_message "Service ${SERVICE} has been restarted after not finding a success message in the past ${SLEEP} minutes."
        else
            # Message found, continuing normal operation
            echo "Service ${SERVICE} is operating normally, waiting ${SLEEP} min..."
        fi
    else
        # Service is not active, trying to start it
        echo "Service ${SERVICE} is not active. Trying to start..."
        sudo systemctl restart ${SERVICE}
        send_telegram_message "Service ${SERVICE} was not active and has been started."
    fi

    # Pause before the next iteration of the loop
    sleep $SLEEP
done
EOF
```

Add permissions
```
cd $HOME
chmod +x ${HOME}/${SERVICE}-monitoring.sh
```

Create Service file
```
sudo tee /etc/systemd/system/${SERVICE}-monitoring.service > /dev/null <<EOF
[Unit]
Description=$USER ${SERVICE}-monitoring script
After=network.target

[Service]
User=root
ExecStart=${HOME}/${SERVICE}-monitoring.sh
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
sudo systemctl enable ${SERVICE}-monitoring.service
sudo systemctl restart ${SERVICE}-monitoring && sudo journalctl -u ${SERVICE}-monitoring -f
```

### Delete 
```
sudo systemctl stop ${SERVICE}-monitoring
sudo systemctl disable ${SERVICE}-monitoring
sudo rm -rf /etc/systemd/system/${SERVICE}-monitoring.service
```
