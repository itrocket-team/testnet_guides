### 0G Storage node Monitoring script

#### Step 1: Download the Monitoring Script

Navigate to your home directory and download the monitoring script:
```bash
cd $HOME
wget -O monitoring-ogstorage.sh https://raw.githubusercontent.com/itrocket-team/testnet_guides/main/0g/monitoring-ogstorage.sh
chmod +x monitoring-ogstorage.sh
```
#### Step 2: Configure Telegram Alerts
Open Telegram and find `@BotFather`
- Here are the [instructions](https://sematext.com/docs/integration/alerts-telegram-integration/)
- How to get [chat id](https://stackoverflow.com/questions/32423837/telegram-bot-how-to-get-a-group-chat-id)

#### Step 3: Edit script
```bash
nano monitoring-ogstorage.sh
```
```bash
TELEGRAM_BOT_TOKEN=""
TELEGRAM_CHAT_ID=""
STORAGE_RPC_PORT="" # Default port 5678.
```

#### Step 4: Set Up the Systemd Service

Create and edit the service file:
```bash
sudo tee /etc/systemd/system/monitoring-ogstorage.service > /dev/null <<EOF
[Unit]
Description=0G Storage Node Health Service
After=network-online.target

[Service]
User=$USER
ExecStart=$HOME/monitoring-ogstorage.sh
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
sudo systemctl enable monitoring-ogstorage
sudo systemctl restart monitoring-ogstorage && sudo journalctl -u monitoring-ogstorage -o cat
```

#### Removing the Service and Script (if needed)

If you need to remove the service and script, execute the following commands:

Stop and disable the service, then remove the service file and script:
```bash
sudo systemctl stop monitoring-ogstorage
sudo systemctl disable monitoring-ogstorage
sudo rm -rf /etc/systemd/system/monitoring-ogstorage.service
rm ~/monitoring-ogstorage.sh
sudo systemctl daemon-reload
```
