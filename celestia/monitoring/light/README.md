# Celestia Light node monitoring script

- **Tracks DA Node status (every 15m)**
- **Compares block height with an external server (every 15m)**
- **Checks Light node wallet balance (every 15m)**
- **Sends alerts and status updates via Telegram**

[ITRocket team Celestia services full list](https://itrocket.net/services/)

## Download monitoring-light.sh
~~~
cd $HOME
wget -O monitoring-light.sh https://raw.githubusercontent.com/itrocket-team/testnet_guides/main/celestia/monitoring/light/monitoring-light.sh
chmod +x monitoring-light.sh
~~~

### Configure Telegram alerting:
Open Telegram and find `@BotFather`
- Here are the [instructions](https://sematext.com/docs/integration/alerts-telegram-integration/)
- How to get [chat id](https://stackoverflow.com/questions/32423837/telegram-bot-how-to-get-a-group-chat-id)

After creating telegram bot and group, specify the variables in the autonity-monitoring.sh:
- set values for `TELEGRAM_BOT_TOKEN=`, `TELEGRAM_CHAT_ID=""` and `VALIDATOR_ADDRESS=`
~~~
nano monitoring-light.sh
~~~

## Create service file

~~~
sudo tee /etc/systemd/system/monitoring-light.service > /dev/null <<EOF
[Unit]
Description=Celestia light-monitoring script
After=network.target

[Service]
User=$USER
ExecStart=$HOME/monitoring-light.sh
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
sudo systemctl enable monitoring-light
sudo systemctl restart monitoring-light && sudo journalctl -u monitoring-light -f
~~~

Voilà! Enjoy the script ;)

## Delete
~~~
sudo systemctl stop monitoring-light
sudo systemctl disable monitoring-light
sudo rm -rf /etc/systemd/system/monitoring-light.service
~~~
