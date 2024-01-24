# Simple script for monitoring Eigenlayer node
- This script is not a full-fledged monitoring tool, but it can serve as a good complement to a comprehensive monitoring tool using Prometheus and Grafana https://docs.eigenlayer.xyz/operator-guides/avs-installation-and-registration/eigenda-operator-guide/eigenda-metrics-and-monitoring
- This script monitors the state of the container and the presence of the message "StoreChunks succeeded" in the container logs every 15 minutes, reporting any issues to Telegram

## Download eigenlayer-monitoring.sh file
To begin, download the `eigenlayer-monitoring.sh` script using the following commands:
```
cd $HOME
rm -rf $HOME/monitoring
mkdir $HOME/monitoring
cd $HOME/monitoring
wget -O eigenlayer-monitoring.sh https://raw.githubusercontent.com/itrocket-team/testnet_guides/main/eigenlayer/eigenlayer-monitoring.sh
chmod +x eigenlayer-monitoring.sh
```

### Configure Telegram alerting
Open telegram and find @BotFather 
- Create telegram bot via @BotFather, customize it and get bot API token [how_to](https://www.siteguarding.com/en/how-to-get-telegram-bot-api-token)
- Create the group: alarm . Customize them, add the bot in your chat and get chats IDs [how_to](https://stackoverflow.com/questions/32423837/telegram-bot-how-to-get-a-group-chat-id)

## Specify the Your `TELEGRAM_CHAT_ID` and `TELEGRAM_BOT_TOKEN`  
>Customize `TELEGRAM_CHAT_ID` and `TELEGRAM_BOT_TOKEN`  
>Configure `SLEEP` time if needed
```
nano eigenlayer-monitoring.sh
```

## Create a new tmux session 
```
cd $HOME
tmux new -s eigenlayer-monitoring
```

## Start monitoring script
Finally, start the Eigenlayer monitoring script:
```
cd $HOME/monitoring
sudo /bin/bash eigenlayer-monitoring.sh
```

Don't stop process with `CTRL+C`, if you want to disconnect the session use `CTRL+B D`, if you want to kill session use `CTRL+B C`

>If you want to connect disconnected session use:
```
tmux attach -t monitoring
```
