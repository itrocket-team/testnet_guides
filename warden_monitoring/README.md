## Warden Node and Slinky Monitoring Script

This script monitors the status of a Warden node & Slynki oracle, sends Telegram notifications in case of errors or node shutdown. Developed by ITRocket for the community, it enhances the functionality of the existing warden node script.

### Description

The script periodically checks the Warden node's health via /health and the Oracle's status, notifying via console and Telegram if there's no response, incorrect data, or missing price information.

### Key Features

- **Regular Status Checks**: Monitors the node's status at 15-minute intervals.
- **Telegram Notifications**: Alerts users via Telegram on node shutdowns, errors, or unknown statuses.

### Installation and Usage

**Step 1: Preparation**

1. **Download the Script**:
   ```bash
   cd $HOME
   wget -O monitoring-warden.sh https://raw.githubusercontent.com/itrocket-team/testnet_guides/main/warden_monitoring/monitoring-warden.sh
   ```

2. **Configure Telegram Alerts**:
   - Open Telegram and find `@BotFather` to create a new bot.
   - Obtain your `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` as instructed by @BotFather.
   - Specify these variables in `monitoring-warden.sh`.
   - Replace without `<>`
     ```bash
     nano ~/monitoring-warden.sh
     TELEGRAM_BOT_TOKEN="<your_bot_token>"
     TELEGRAM_CHAT_ID="<your_chat_id>"
     ```

4. **Make the Script Executable**:
   ```bash
   chmod +x ~/monitoring-warden.sh
   ```

**Step 2: Create Service File**

Create a systemd service file to ensure the script runs continuously:

```bash
sudo tee /etc/systemd/system/monitoring-warden.service > /dev/null <<EOF
[Unit]
Description=warden Node Health Service
After=network-online.target

[Service]
User=$USER
WorkingDirectory=$HOME
ExecStart=/bin/bash $HOME/monitoring-warden.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

**Step 3: Enable and Start the Service**

Enable and start the service to run automatically:

```bash
sudo systemctl daemon-reload
sudo systemctl enable monitoring-warden
sudo systemctl restart monitoring-warden && sudo journalctl -u monitoring-warden -f
```

**Voilà!** You're all set to enjoy the script. If needed, you can delete the service and script using the following commands:

```bash
sudo systemctl stop monitoring-warden
sudo systemctl disable monitoring-warden
sudo rm -rf /etc/systemd/system/monitoring-warden.service
rm ~/monitoring-warden.sh
sudo systemctl daemon-reload
```
