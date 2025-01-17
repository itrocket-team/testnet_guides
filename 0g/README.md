### 0G Storage node Monitoring script

#### Step 1: Download the Monitoring Script

Navigate to your home directory and download the monitoring script:
```bash
cd $HOME
wget -O monitoring-og.sh https://raw.githubusercontent.com/itrocket-team/testnet_guides/main/0g/monitoring-og.sh
chmod +x monitoring-og.sh
```
#### Step 2: Configure Telegram Alerts
Open Telegram and find `@BotFather`
- Here are the [instructions](https://sematext.com/docs/integration/alerts-telegram-integration/)
- How to get [chat id](https://stackoverflow.com/questions/32423837/telegram-bot-how-to-get-a-group-chat-id)

#### Step 3: Edit script
```bash
nano monitoring-og.sh
```
```bash
TELEGRAM_BOT_TOKEN=""
TELEGRAM_CHAT_ID=""
STORAGE_RPC_PORT="" # Default port 5678.
```

#### Step 4: Set Up the Systemd Service

Create and edit the service file:
```bash
sudo tee /etc/systemd/system/monitoring-og.service > /dev/null <<EOF
[Unit]
Description=OG Storage Node Monitoring
After=network.target

[Service]
User=$USER
ExecStart=${HOME}/monitoring-og.sh
WorkingDirectory=$HOME
StandardOutput=inherit
StandardError=inherit
Restart=always

[Install]
WantedBy=multi-user.target
EOF
```

#### Step 5: Start the Service

Reload the systemd daemon and enable the service to start on boot:
```bash
sudo systemctl daemon-reload
sudo systemctl enable monitoring-og
sudo systemctl restart monitoring-og && sudo journalctl -u monitoring-og -fo cat
```

#### Removing the Service and Script (if needed)

If you need to remove the service and script, execute the following commands:

Stop and disable the service, then remove the service file and script:
```bash
sudo systemctl stop monitoring-og
sudo systemctl disable monitoring-og
sudo rm -rf /etc/systemd/system/monitoring-og.service
rm ~/monitoring-og.sh
sudo systemctl daemon-reload
```
