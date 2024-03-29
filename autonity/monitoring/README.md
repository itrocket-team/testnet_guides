# Autoniti Validator and RPC node monitoring script

- **Tracks node status and height, and compares it with parent RPC (every 15m)**
- **Monitors validator status and commitments (every 15m)**
- **Sends Telegram notifications if any problems are found**

[Autonity Round 5: Node Setup + Useful Commands](https://github.com/itrocket-team/testnet_guides/blob/main/autonity/README.md)

## Download autonity-monitoring.sh
~~~
cd $HOME
wget -O autonity-monitoring.sh https://raw.githubusercontent.com/itrocket-team/testnet_guides/main/autonity/monitoring/autonity-monitoring.sh
chmod +x autonity-monitoring.sh
~~~

### Configure Telegram alerting:
Open Telegram and find `@BotFather`
- Here are the [instructions](https://sematext.com/docs/integration/alerts-telegram-integration/)
- How to get [chat id](https://stackoverflow.com/questions/32423837/telegram-bot-how-to-get-a-group-chat-id)

After creating telegram bot and group, specify the variables in the autonity-monitoring.sh:
- set values for `TELEGRAM_BOT_TOKEN=`, `TELEGRAM_CHAT_ID=""` and `VALIDATOR_ADDRESS=`
~~~
nano autonity-monitoring.sh
~~~

## Create service file

~~~
sudo tee /etc/systemd/system/autonity-monitoring.service > /dev/null <<EOF
[Unit]
Description=Autonity-monitoring script
After=network.target

[Service]
User=$USER
ExecStart=$HOME/autonity-monitoring.sh
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
sudo systemctl enable autonity-monitoring
sudo systemctl restart autonity-monitoring && sudo journalctl -u autonity-monitoring -f
~~~

Voilà! Enjoy the script ;)

## Delete
~~~
sudo systemctl stop autonity-monitoring
sudo systemctl disable autonity-monitoring
sudo rm -rf /etc/systemd/system/autonity-monitoring.service
~~~
