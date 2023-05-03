<div>
<h1 align="left" style="display: flex;"> Humans Node Setup for Testnet — humans_3000-1</h1>
<img src="https://github.com/itrocket-team/testnet_guides/blob/main/logos/humans.jpg"  style="float: right;" width="100" height="100"></img>
</div>

Official documentation:
>- [Validator setup instructions](https://github.com/humansdotai/testnets/blob/master/Install.md)

Explorer:
>-  https://explorer.humans.zone/humans-testnet


## Hardware Requirements
### Minimal Hardware Requirements 
 - 6 or more physical CPU cores
 - At least 500GB of SSD disk storage
 - At least 32GB of memory (RAM)
 - Bandwidth: At least 1000mbps network bandwidth

## Set up your Humans node
### Manual installation

Update packages and Install dependencies

~~~bash
sudo apt update && sudo apt upgrade -y
sudo apt install curl git wget htop tmux build-essential jq make lz4 gcc -y
~~~

Replace your moniker `<YOUR_MONIKER>` without `<>`, save and import variables into system

~~~bash
HUMANS_PORT=17
echo "export WALLET="wallet"" >> $HOME/.bash_profile
echo "export MONIKER="<YOUR_MONIKER>"" >> $HOME/.bash_profile
echo "export HUMANS_CHAIN_ID="humans_3000-1"" >> $HOME/.bash_profile
echo "export HUMANS_PORT="${HUMANS_PORT}"" >> $HOME/.bash_profile
source $HOME/.bash_profile
~~~

install go

~~~bash
cd $HOME
VER="1.19.3"
wget "https://golang.org/dl/go$VER.linux-amd64.tar.gz"
sudo tar -C /usr/local -xzf "go$VER.linux-amd64.tar.gz"
rm -rf  "go$VER.linux-amd64.tar.gz"
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile
source $HOME/.bash_profile
go version
~~~

Download and build binaries

~~~bash
cd $HOME
rm -rf ~/humans
git clone https://github.com/humansdotai/humans
cd humans
git checkout tags/v0.1.0
make install
~~~
Config and init app

~~~bash
humansd config node tcp://localhost:${HUMANS_PORT}657
humansd config chain-id humans_3000-1
humansd init "$MONIKER" --chain-id humans_3000-1
~~~

Download genesis and addrbook

~~~bash
wget -O $HOME/.humansd/config/genesis.json "https://raw.githubusercontent.com/humansdotai/testnets/master/friction/genesis-M1-P3.json"
~~~

Set seeds and peers

~~~bash
SEEDS="6ce9a9acc23594ec75516617647286fe546f83ca@humans-testnet-seed.itrocket.net:17656"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.humansd/config/config.toml
~~~

Set gustom ports in app.toml file

~~~bash
sed -i.bak -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${HUMANS_PORT}317\"%;
s%^address = \":8080\"%address = \":${HUMANS_PORT}080\"%;
s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:${HUMANS_PORT}090\"%; 
s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:${HUMANS_PORT}091\"%; 
s%^address = \"0.0.0.0:8545\"%address = \"0.0.0.0:${HUMANS_PORT}545\"%; 
s%^ws-address = \"0.0.0.0:8546\"%ws-address = \"0.0.0.0:${HUMANS_PORT}546\"%" $HOME/.humansd/config/app.toml
~~~

Set gustom ports in config.toml file

~~~bash
sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${HUMANS_PORT}658\"%; 
s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://0.0.0.0:${HUMANS_PORT}657\"%; 
s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${HUMANS_PORT}060\"%;
s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${HUMANS_PORT}656\"%;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${HUMANS_PORT}656\"%;
s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${HUMANS_PORT}660\"%" $HOME/.humansd/config/config.toml
~~~

Config pruning

~~~bash
sed -i -e "s/^pruning *=.*/pruning = \"nothing\"/" $HOME/.humansd/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.humansd/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.humansd/config/app.toml
~~~

Set minimum gas price and disable indexing

~~~bash
sed -i 's/minimum-gas-prices =.*/minimum-gas-prices = "1800000000aheart"/g' $HOME/.humansd/config/app.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.humansd/config/config.toml
~~~

Update parameters

~~~bash
sed -i 's/create_empty_blocks =.*/create_empty_blocks = false/g' $HOME/.humansd/config/config.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.humansd/config/config.toml
sed -i 's/create_empty_blocks_interval =.*/create_empty_blocks_interval = "30s"/g' $HOME/.humansd/config/config.toml
sed -i 's/timeout_propose =.*/timeout_propose = "30s"/g' $HOME/.humansd/config/config.toml
sed -i 's/timeout_propose_delta =.*/timeout_propose_delta = "5s"/g' $HOME/.humansd/config/config.toml
sed -i 's/timeout_prevote =.*/timeout_prevote = "10s"/g' $HOME/.humansd/config/config.toml
sed -i 's/timeout_prevote_delta =.*/timeout_prevote_delta = "5s"/g' $HOME/.humansd/config/config.toml
sed -i 's/cors_allowed_origins =.*/cors_allowed_origins = ["*"]/g' $HOME/.humansd/config/config.toml
~~~

Clean old data

```bash
humansd tendermint unsafe-reset-all --home $HOME/.humans --keep-addr-book
```

Create Service file

~~~bash
sudo tee /etc/systemd/system/humansd.service > /dev/null <<EOF
[Unit]
Description=humans
After=network-online.target

[Service]
User=$USER
ExecStart=$(which humansd) start --home $HOME/.humans
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
~~~

Enable and start service

~~~bash
sudo systemctl daemon-reload
sudo systemctl enable humansd
sudo systemctl restart humansd && sudo journalctl -u humansd -f
~~~

## Snapshot, State Sync (OPTIONAL)
In order not to wait for a long synchronization, you can use our guides:

>https://itrocket.net/services/testnet/humans/#snap  
>https://itrocket.net/services/testnet/humans/#sync

## Create wallet
To create a new wallet, use the following command. don’t forget to save the mnemonic

~~~bash
humansd keys add $WALLET
~~~

(optional) To restore exexuting wallet, use the following command

~~~bash
humansd keys add $WALLET --recover
~~~

Save wallet and validator address

~~~bash
WALLET_ADDRESS=$(humansd keys show $WALLET -a)
HUMANS_VALOPER_ADDRESS=$(humansd keys show $WALLET --bech val -a)
echo "export WALLET_ADDRESS="${WALLET_ADDRESS} >> $HOME/.bash_profile
echo "export HUMANS_VALOPER_ADDRESS="${HUMANS_VALOPER_ADDRESS} >> $HOME/.bash_profile
source $HOME/.bash_profile
~~~

## Create validator

before creating a validator, you need to check the balance and make sure that the node is synched

Check Sync status, once your node is fully synced, the output from above will say `false`

~~~bash
humansd status 2>&1 | jq .SyncInfo
~~~

Check your balance

~~~bash
humansd query bank balances $WALLET_ADDRESS
~~~

Create validator

~~~bash
humansd tx staking create-validator \
  --amount 1000000uheart \
  --from $WALLET \
  --commission-max-change-rate "0.01" \
  --commission-max-rate "0.2" \
  --commission-rate "0.05" \
  --min-self-delegation "1" \
  --pubkey  $(humansd tendermint show-validator) \
  --moniker $MONIKER \
  --chain-id $HUMANS_CHAIN_ID \
  --gas auto --gas-adjustment 1.5 \
  -y
~~~
  
You can add `--website` `--security-contact` `--identity` `--details` flags in it needed

~~~bash
--website <YOUR_SITE_URL> \
--security-contact <YOUR_CONTACT> \
--identity <KEYBASE_IDENTITY> \
--details <YOUR_VALIDATOR_DETAILS>
~~~

### Monitoring
If you want to have set up a monitoring and alert system use [our cosmos nodes monitoring guide with tenderduty](https://teletype.in/@itrocket/bdJAHvC_q8h)

>Team plan to monitoring the system resources, please enable metrics, open RPC, API, EVM RPC, EVM WebSocket, EVM Metrics, proxy_app, P2P port. If in some of these points in the settings it is specified 127.0.0.1 change to 0.0.0.0

~~~
sudo ufw allow from 45.136.40.0/22 to any port ${HUMANS_PORT}545 proto tcp
sudo ufw allow from 45.136.40.0/22 to any port ${HUMANS_PORT}546 proto tcp
sudo ufw allow from 45.136.40.0/22 to any port ${HUMANS_PORT}317 proto tcp
sudo ufw allow from 45.136.40.0/22 to any port ${HUMANS_PORT}657 proto tcp
sudo ufw allow from 45.136.40.0/22 to any port ${HUMANS_PORT}660 proto tcp
sudo ufw allow from 45.136.40.0/22 to any port ${HUMANS_PORT}658 proto tcp
sudo ufw allow from 45.136.40.0/22 to any port ${HUMANS_PORT}065 proto tcp
~~~
  
### Security
To protect you keys please don`t share your privkey, mnemonic and follow a basic security rules

### Set up ssh keys for authentication
You can use this [guide](https://www.digitalocean.com/community/tutorials/how-to-set-up-ssh-keys-on-ubuntu-20-04) to configure ssh authentication and disable password authentication on your server

### Firewall security
Set the default to allow outgoing connections, deny all incoming, allow ssh and node p2p port

~~~bash
sudo ufw default allow outgoing 
sudo ufw default deny incoming 
sudo ufw allow ssh/tcp 
sudo ufw allow ${HUMANS_PORT}656/tcp
sudo ufw enable
~~~

## Usefull commands
### Service commands
check logs

~~~bash
sudo journalctl -u humansd -f
~~~

restart service

~~~bash
sudo systemctl restart humansd
~~~

### Wallet operation

check balance

~~~bash
humansd query bank balances $WALLET_ADDRESS
~~~

transfer funds

~~~bash
humansd tx bank send $WALLET_ADDRESS <TO_WALLET_ADDRESS> 1000000uheart --gas auto --gas-adjustment 1.3
~~~

lists of wallets

~~~bash
humansd keys list
~~~

delete wallet

~~~bash
humansd keys delete $WALLET
~~~

### Node information

synch info

~~~bash
humansd status 2>&1 | jq .SyncInfo
~~~

node status && node info && validator info

~~~bash
curl -s localhost:${HUMANS_PORT}657/status && humansd status 2>&1 | jq .NodeInfo && humansd status 2>&1 | jq .ValidatorInfo
~~~

your node peers

~~~bash
echo $(humansd tendermint show-node-id)'@'$(curl -s ifconfig.me)':'$(cat $HOME/.humans/config/config.toml | sed -n '/Address to listen for incoming connection/{n;p;}' | sed 's/.*://; s/".*//')
~~~

get currently conected peers lis

~~~bash
curl -sS http://localhost:${HUMANS_PORT}657/net_info | jq -r '.result.peers[] | "\(.node_info.id)@\(.remote_ip):\(.node_info.listen_addr)"' | awk -F ':' '{print $1":"$(NF)}'
~~~

### Voting

~~~bash
humansd tx gov vote 1 yes --from $WALLET --chain-id $HUMANS_CHAIN_ID
~~~

### Staking, Delegation and Rewards

Withdraw all rewards

~~~bash
humansd tx distribution withdraw-all-rewards --from $WALLET --chain-id $HUMANS_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

Withdraw rewards with commision

~~~bash
humansd tx distribution withdraw-rewards $HUMANS_VALOPER_ADDRESS --from $WALLET --commission --chain-id $HUMANS_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

Check balance 

~~~bash
humansd query bank balances $WALLET_ADDRESS
~~~

Delegate stake

~~~bash
humansd tx staking delegate $HUMANS_VALOPER_ADDRESS 1000000uheart --from $WALLET --chain-id $HUMANS_CHAIN_ID --gas=auto --gas-adjustment 1.3
~~~

Redelegate stake to another validator

~~~bash
humansd tx staking redelegate <srcValidatorAddress> <destValidatorAddress> 1000000uheart --from $WALLET --chain-id $HUMANS_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

### Validator operation

Edit validator

~~~bash
humansd tx staking edit-validator \
  --moniker=$NODENAME \
  --identity=<your_keybase_id> \
  --website="<your_website>" \
  --details="<your_validator_description>" \
  --chain-id=$HUMANS_CHAIN_ID \
  --from=$WALLET
~~~

Jailing info

~~~bash
humansd q slashing signing-info $(humansd tendermint show-validator)
~~~

Unjail validator

~~~bash
humansd tx slashing unjail --broadcast-mode=block --from $WALLET --chain-id $HUMANS_CHAIN_ID --gas auto --gas-adjustment 1.5
~~~

Consensus state

~~~bash
curl localhost:${HUMANS_PORT}657/consensus_state
~~~

### Delete node

~~~bash
sudo systemctl stop humansd
sudo systemctl disable humansd
sudo rm -rf /etc/systemd/system/humansd*
sudo rm $(which humansd)
sudo rm -rf $HOME/.humans
sudo rm -fr $HOME/humans
sed -i "/HUMANS_/d" $HOME/.bash_profile
~~~

