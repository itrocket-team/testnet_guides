# Namada node monitoring script

## Download namada.sh file
To begin, download the `namada.sh` script using the following commands:
```
cd $HOME
rm -rf $HOME/monitoring
mkdir $HOME/monitoring
cd $HOME/monitoring
wget -O namada.sh https://raw.githubusercontent.com/itrocket-team/testnet_guides/main/namada/monitoring/namada.sh
chmod +x namada.sh
```

### Configure Telegram alerting
Open telegram and find @BotFather 
- Create telegram bot via @BotFather, customize it and get bot API token [how_to](https://www.siteguarding.com/en/how-to-get-telegram-bot-api-token)
- Create the group: alarm . Customize them, add the bot in your chat and get chats IDs [how_to](https://stackoverflow.com/questions/32423837/telegram-bot-how-to-get-a-group-chat-id)
- Open namada.sh file 
>change ENABLE=false to ENABLE=true

## Specify the Your node `RPC_SERVER`, `TELEGRAM_CHAT_ID` and `TELEGRAM_BOT_TOKEN`
>Configure correct Namada node port - `RPC_SERVER`  
>Customize `TELEGRAM_CHAT_ID` and `TELEGRAM_BOT_TOKEN`  
>Configure `BLOCK_GAP_ALARM` and allow `RESTART` function if needed
```
nano namada.sh
```

## Create a new tmux session 
```
cd $HOME
tmux new -s monitoring
```

## Start monitoring script
Finally, start the Namada node monitoring script:
```
cd $HOME/monitoring/namada.sh
sudo /bin/bash namada.sh
```

Don't stop process with `CTRL+C`, if you want to disconnect the session use `CTRL+B D`, if you want to kill session use `CTRL+B C`

>If you want to connect disconnected session use:
```
tmux attach -t monitoring
```
