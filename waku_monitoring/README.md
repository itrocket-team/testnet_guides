## Waku Node Monitoring Script

This script monitors the status of a Waku node and sends Telegram notifications in case of errors or node shutdown. Developed by ITRocket for the community, it enhances the functionality of the existing Waku node script.You can find the code that was used as the source script at ~/nwaku-compose/chkhealth.sh.

### Description

The script periodically checks the health of the Waku node using HTTP requests to the `/health` endpoint. Depending on the node's status, it provides relevant console output and sends notifications to Telegram.

### Key Features

- **Regular Status Checks**: Monitors the node's status at 5-minute intervals.
- **Telegram Notifications**: Alerts users via Telegram on node shutdowns, errors, or unknown statuses.

### Installation and Usage

**Step 1: Preparation**

1. **Download the Script**:
   ```bash
   cd $HOME
   wget -O monitoring-waku.sh https://raw.githubusercontent.com/mART321/waku_monitor/main/monitoring-waku.sh
   ```

2. **Configure Telegram Alerts**:
   - Open Telegram and find `@BotFather` to create a new bot.
   - Obtain your `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` as instructed by @BotFather.
   - Specify these variables in `monitoring-waku.sh`.
   - Replace your nwake-compose directory path, example `/root/nwaku-compose` without `<>`
     ```bash
     nano ~/monitoring-waku.sh
     TELEGRAM_BOT_TOKEN="<your_bot_token>"
     TELEGRAM_CHAT_ID="<your_chat_id>"
     compose_directory="<nwake-compose_directory>"
     ```

4. **Make the Script Executable**:
   ```bash
   chmod +x ~/monitoring-waku.sh
   ```

**Step 2: Create Service File**

Create a systemd service file to ensure the script runs continuously:

```bash
sudo tee /etc/systemd/system/monitoring-waku.service > /dev/null <<EOF
[Unit]
Description=Waku Node Health Service
After=network-online.target

[Service]
User=$USER
WorkingDirectory=$HOME
ExecStart=/bin/bash $HOME/monitoring-waku.sh
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
sudo systemctl enable monitoring-waku
sudo systemctl restart monitoring-waku && sudo journalctl -u monitoring-waku -f
```

**Voilà!** You're all set to enjoy the script. If needed, you can delete the service and script using the following commands:

```bash
sudo systemctl stop monitoring-waku
sudo systemctl disable monitoring-waku
sudo rm -rf /etc/systemd/system/monitoring-waku.service
rm ~/monitoring-waku.sh
sudo systemctl daemon-reload
```
