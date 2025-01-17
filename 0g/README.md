### 0G Storage node Monitoring script

#### Step 1: Download the Monitoring Script

Navigate to your home directory and download the monitoring script:
```bash
cd $HOME
wget -O 0g-monitoring.sh https://raw.githubusercontent.com/itrocket-team/testnet_guides/main/0g/0g-monitoring.sh
chmod +x 0g-monitoring.sh
```
#### Step 2: Configure Telegram Alerts
Open Telegram and find `@BotFather`
- Here are the [instructions](https://sematext.com/docs/integration/alerts-telegram-integration/)
- How to get [chat id](https://stackoverflow.com/questions/32423837/telegram-bot-how-to-get-a-group-chat-id)

#### Step 3: Edit script
```bash
nano 0g-monitoring.sh
```
```bash
TELEGRAM_BOT_TOKEN=""
TELEGRAM_CHAT_ID=""
STORAGE_RPC_PORT="" # If you don`t want to monitor storage node, leave the field empty. Default port 5678.
VALIDATOR_RPC_PORT="" # If you don`t want to monitor validator node, leave the field empty. Default port 26657
```

#### Step 4: Set Up the Systemd Service

Create and edit the service file:
```bash
sudo tee /etc/systemd/system/monitoring-0g.service > /dev/null <<EOF
[Unit]
Description=0G Node Health Service
After=network-online.target

[Service]
User=$USER
WorkingDirectory=$HOME
ExecStart=/bin/bash $HOME/0g-monitoring.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

#### Step 5: Start the Service

Reload the systemd daemon and enable the service to start on boot:
```bash
sudo systemctl daemon-reload
sudo systemctl enable monitoring-0g
sudo systemctl restart monitoring-0g && sudo journalctl -u monitoring-0g -f
```

#### Removing the Service and Script (if needed)

If you need to remove the service and script, execute the following commands:

Stop and disable the service, then remove the service file and script:
```bash
sudo systemctl stop monitoring-0g
sudo systemctl disable monitoring-0g
sudo rm -rf /etc/systemd/system/monitoring-0g.service
rm ~/0g-monitoring.sh
sudo systemctl daemon-reload
```
