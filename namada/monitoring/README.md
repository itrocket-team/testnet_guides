# Namada node monitoring script

## Download namada.sh File
To begin, download the `namada.sh` script using the following commands:
```
cd $HOME
rm -rf $HOME/monitoring
mkdir $HOME/monitoring
cd $HOME/monitoring
wget -O rpc.sh https://raw.githubusercontent.com/itrocket-team/testnet_guides/main/namada/monitoring/namada.sh
chmod +x namada.sh
```

## Specify the Your node `RPC port`, telegram `TELEGRAM_CHAT_ID` and `TELEGRAM_BOT_TOKEN`
Next, specify the parent RPC from which the scanner will retrieve network data:
```
nano namada.sh
```

## Create a new tmux session 
```
cd $HOME
tmux new -s monitoring
```

## Start RPC Scanner
Finally, start the Namada node monitoring script:
```
cd $HOME/monitoring/namada.sh
sudo /bin/bash namada.sh
```
