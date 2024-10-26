# Simple script for monitoring Chainbase node
- This script is not a full-fledged monitoring tool, but it can serve as a good complement to a comprehensive monitoring tool using Prometheus and Grafana
- This script monitors the result of the `./chainbase-avs.sh test` command, checking for the message "All systems are working for your manuscript node" every 15 minutes, and reports any issues to Telegram.

## Download eigenlayer-monitoring.sh file
To begin, download the `monitoring-chainbase.sh` script using the following commands:
```
cd $HOME
wget -O monitoring-chainbase.sh https://raw.githubusercontent.com/itrocket-team/testnet_guides/main/chainbase/monitoring-chainbase.sh
chmod +x $HOME/monitoring-chainbase.sh
```

### Configure Telegram alerting
Open telegram and find @BotFather 
- Create telegram bot via @BotFather, customize it and get bot API token [how_to](https://www.siteguarding.com/en/how-to-get-telegram-bot-api-token)
- Create the group: alarm . Customize them, add the bot in your chat and get chats IDs [how_to](https://stackoverflow.com/questions/32423837/telegram-bot-how-to-get-a-group-chat-id)

## Specify the Your `TELEGRAM_CHAT_ID` and `TELEGRAM_BOT_TOKEN`  
>Customize `TELEGRAM_CHAT_ID` and `TELEGRAM_BOT_TOKEN`  
>Configure `SLEEP` time if needed
>Configure HOME_PATH
```
nano $HOME/monitoring-chainbase.sh
```

## Test
```
/bin/bash $HOME/monitoring-chainbase.sh
```

## Configure monitoring every 15 min
Open crontab `crontab -e` add these lines, and save
```
# Chainbase node monitoring
1,11,21,31,41,51 * * * * bash $HOME/monitoring-chainbase.sh >> $HOME/monitoring-chainbase.log 2>&1
```

