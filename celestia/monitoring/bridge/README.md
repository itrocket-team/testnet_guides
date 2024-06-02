# Celestia Bridge node monitoring script

- **Tracks DA Node status (every 15m)**
- **Compares block height with an external server (every 15m)**
- **Checks Bridge node wallet balance (every 15m)**
- **Sends alerts and status updates via Telegram**

[ITRocket team Celestia services full list](https://itrocket.net/services/)

## Download monitoring-bridge.sh
~~~
cd $HOME
wget -O monitoring-bridge.sh https://raw.githubusercontent.com/itrocket-team/testnet_guides/main/celestia/monitoring/bridge/monitoring-bridge.sh
chmod +x monitoring-bridge.sh
~~~

### Configure Telegram alerting:
Open Telegram and find `@BotFather`
- Here are the [instructions](https://sematext.com/docs/integration/alerts-telegram-integration/)
- How to get [chat id](https://stackoverflow.com/questions/32423837/telegram-bot-how-to-get-a-group-chat-id)

After creating telegram bot and group, specify the variables in the autonity-monitoring.sh:
- set values for `TELEGRAM_BOT_TOKEN=`, `TELEGRAM_CHAT_ID=""` and `VALIDATOR_ADDRESS=`
~~~
nano monitoring-bridge.sh
~~~

## Create service file

~~~
sudo tee /etc/systemd/system/monitoring-bridge.service > /dev/null <<EOF
[Unit]
Description=Celestia Bridge-monitoring script
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
