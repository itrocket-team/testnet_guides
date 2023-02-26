<div>
<h1 align="left" style="display: flex;"> Arkhadian Node Setup for mainnet — arkh</h1>
</div>

Explorer:
>-  https://mainnet.itrocket.net/arkhadian/staking


## Set up your node
### Manual installation

Update packages and Install dependencies

~~~bash
sudo apt update && sudo apt upgrade -y
sudo apt install curl git wget htop tmux build-essential jq make lz4 gcc -y
~~~

Replace your moniker `<YOUR_MONIKER>` without `<>`, save and import variables into system

~~~bash
ARKH_PORT=27
echo "export WALLET="wallet"" >> $HOME/.bash_profile
echo "export MONIKER="<YOUR_MONIKER>"" >> $HOME/.bash_profile
echo "export ARKH_CHAIN_ID="arkh"" >> $HOME/.bash_profile
echo "export ARKH_PORT="${ARKH_PORT}"" >> $HOME/.bash_profile
source $HOME/.bash_profile
~~~

install go

~~~bash
cd $HOME
if ! [ -x "$(command -v go)" ]; then
VER="1.19.3"
wget "https://golang.org/dl/go$VER.linux-amd64.tar.gz"
sudo tar -C /usr/local -xzf "go$VER.linux-amd64.tar.gz"
rm -rf  "go$VER.linux-amd64.tar.gz"
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile
source $HOME/.bash_profile
fi
~~~

Download and build binaries

~~~bash
cd $HOME
rm -rf arkh-blockchain
git clone https://github.com/vincadian/arkh-blockchain
cd arkh-blockchain
git checkout v2.0.0
go build -o arkhd ./cmd/arkhd
mv arkhd $HOME/go/bin
~~~

Config and init app

~~~bash
arkhd config node tcp://localhost:${ARKH_PORT}657
arkhd config keyring-backend test
arkhd config chain-id $ARKH_CHAIN_ID
arkhd init $MONIKER --chain-id $ARKH_CHAIN_ID
~~~

Download genesis and addrbook

~~~bash
wget -O $HOME/.arkh/config/addrbook.json https://files.itrocket.net/mainnet/arkhadian/addrbook.json
wget -O $HOME/.arkh/config/genesis.json https://files.itrocket.net/mainnet/arkhadian/genesis.json
~~~

Set seeds and peers

~~~bash
SEEDS=""
PEERS=""
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.arkh/config/config.toml
~~~

Set gustom ports in app.toml file

~~~bash
sed -i.bak -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${ARKH_PORT}317\"%;
s%^address = \":8080\"%address = \":${ARKH_PORT}080\"%;
s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:${ARKH_PORT}090\"%; 
s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:${ARKH_PORT}091\"%; 
s%^address = \"0.0.0.0:8545\"%address = \"0.0.0.0:${ARKH_PORT}545\"%; 
s%^ws-address = \"0.0.0.0:8546\"%ws-address = \"0.0.0.0:${ARKH_PORT}546\"%" $HOME/.arkh/config/app.toml
~~~

Set gustom ports in config.toml file

~~~bash
sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${ARKH_PORT}658\"%; 
s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://0.0.0.0:${ARKH_PORT}657\"%; 
s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${ARKH_PORT}060\"%;
s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${ARKH_PORT}656\"%;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${ARKH_PORT}656\"%;
s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${ARKH_PORT}660\"%" $HOME/.arkh/config/config.toml
~~~

Config pruning

~~~bash
sed -i -e "s/^pruning *=.*/pruning = \"nothing\"/" $HOME/.arkh/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.arkh/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.arkh/config/app.toml
~~~

Set minimum gas price, enable prometheus and disable indexing

~~~bash
sed -i 's/minimum-gas-prices =.*/minimum-gas-prices = "0.0arkh"/g' $HOME/.arkh/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.arkh/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.arkh/config/config.toml
~~~

Reset chain data
~~~bash
arkhd unsafe-reset-all --home $HOME/.arkh
~~~

Create Service file

~~~bash
sudo tee /etc/systemd/system/arkhd.service > /dev/null <<EOF
[Unit]
Description=arkhadian
After=network-online.target

[Service]
User=$USER
ExecStart=$(which arkhd) start --home $HOME/.arkh
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
sudo systemctl enable arkhd
sudo systemctl restart arkhd && sudo journalctl -u arkhd -f
~~~

## Snapshot, State Sync (OPTIONAL)
In order not to wait for a long synchronization, you can use our guides:

>https://itrocket.net/services/mainnet/arkhadian/#snap  
>https://itrocket.net/services/mainnet/arkhadian/#sync


## Create wallet
To create a new wallet, use the following command. don’t forget to save the mnemonic

~~~bash
arkhd keys add $WALLET
~~~

(optional) To restore exexuting wallet, use the following command

~~~bash
arkhd keys add $WALLET --recover
~~~

Save wallet and validator address

~~~bash
WALLET_ADDRESS=$(arkhd keys show $WALLET -a)
VALOPER_ADDRESS=$(arkhd keys show $WALLET --bech val -a)
echo "export WALLET_ADDRESS="${WALLET_ADDRESS} >> $HOME/.bash_profile
echo "export VALOPER_ADDRESS="${VALOPER_ADDRESS} >> $HOME/.bash_profile
source $HOME/.bash_profile
~~~

## (OPTIONAL) State Sync, Snapshot

In order not to wait for a long synchronization, you can use our StateSync or Snapshot guide:
> https://itrocket.net/services/testnet/sei/#snap
> https://itrocket.net/services/testnet/sei/#sync


## Create validator

before creating a validator, you need to check the balance and make sure that the node is synched

Check Sync status, once your node is fully synced, the output from above will say `false`

~~~bash
arkhd status 2>&1 | jq .SyncInfo
~~~

Check your balance

~~~bash
arkhd query bank balances $WALLET_ADDRESS
~~~

Create validator

~~~bash
arkhd tx staking create-validator \
  --amount 1000000arkh \
  --from $WALLET \
  --commission-max-change-rate "0.01" \
  --commission-max-rate "0.2" \
  --commission-rate "0.05" \
  --min-self-delegation "1" \
  --pubkey  $(arkhd tendermint show-validator) \
  --moniker $MONIKER \
  --chain-id $ARKH_CHAIN_ID
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
sudo ufw allow ${ARKH_PORT}656/tcp
sudo ufw enable
~~~

## Usefull commands
### Service commands
check logs

~~~bash
sudo journalctl -u arkhd -f
~~~

stop service

~~~bash
sudo systemctl stop arkhd
~~~

start service

~~~bash
sudo systemctl start arkhd
~~~

restart service

~~~bash
sudo systemctl restart arkhd
~~~

### Wallet operation

check balance

~~~bash
arkhd query bank balances $WALLET_ADDRESS
~~~

transfer funds

~~~bash
arkhd tx bank send $WALLET_ADDRESS <TO_WALLET_ADDRESS> 1000000arkh --gas auto --gas-adjustment 1.3
~~~

lists of wallets

~~~bash
arkhd keys list
~~~

create a new wallet

~~~bash
arkhd keys add $WALLET
~~~

recover wallet

~~~bash
arkhd keys add $WALLET --recover
~~~

delete wallet

~~~bash
arkhd keys delete $WALLET
~~~

### Node information

synch info

~~~bash
arkhd status 2>&1 | jq .SyncInfo
~~~

node status

~~~bash
curl -s localhost:${ARKH_PORT}657/status
~~~

node info

~~~bash
arkhd status 2>&1 | jq .NodeInfo
~~~

validator info

~~~bash
arkhd status 2>&1 | jq .ValidatorInfo
~~~

your node peers

~~~bash
echo $(arkhd tendermint show-node-id)'@'$(curl -s ifconfig.me)':'$(cat $HOME/.arkh/config/config.toml | sed -n '/Address to listen for incoming connection/{n;p;}' | sed 's/.*://; s/".*//')
~~~

get currently conected peers lis

~~~bash
curl -sS http://localhost:${ARKH_PORT}657/net_info | jq -r '.result.peers[] | "\(.node_info.id)@\(.remote_ip):\(.node_info.listen_addr)"' | awk -F ':' '{print $1":"$(NF)}'
~~~

### Voting

~~~bash
arkhd tx gov vote 1 yes --from $WALLET --chain-id $ARKH_CHAIN_ID
~~~

### Staking, Delegation and Rewards

Withdraw all rewards

~~~bash
arkhd tx distribution withdraw-all-rewards --from $WALLET --chain-id $ARKH_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

Withdraw rewards with commision

~~~bash
arkhd tx distribution withdraw-rewards $VALOPER_ADDRESS --from $WALLET --commission --chain-id $ARKH_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

Check balance 

~~~bash
arkhd query bank balances $WALLET_ADDRESS
~~~

Delegate stake

~~~bash
arkhd tx staking delegate $VALOPER_ADDRESS 1000000arkh --from $WALLET --chain-id $ARKH_CHAIN_ID --gas=auto --gas-adjustment 1.3
~~~

Redelegate stake to another validator

~~~bash
arkhd tx staking redelegate <srcValidatorAddress> <destValidatorAddress> 1000000arkh --from $WALLET --chain-id $ARKH_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

Unbond

~~~bash
arkhd tx staking unbond $VALOPER_ADDRESS 1000000arkh --from $WALLET --chain-id $ARKH_CHAIN_ID --gas=auto --gas-adjustment 1.3
~~~

### Validator operation

Edit validator

~~~bash
arkhd tx staking edit-validator \
  --moniker=$NODENAME \
  --identity=<your_keybase_id> \
  --website="<your_website>" \
  --details="<your_validator_description>" \
  --chain-id=$ARKH_CHAIN_ID \
  --from=$WALLET
~~~

Validator info

~~~bash
arkhd status 2>&1 | jq .ValidatorInfo

~~~

Jailing info

~~~bash
arkhd q slashing signing-info $(arkhd tendermint show-validator)
~~~

Unjail validator

~~~bash
arkhd tx slashing unjail --broadcast-mode=block --from $WALLET --chain-id $ARKH_CHAIN_ID --gas auto --gas-adjustment 1.5
~~~

Consensus state

~~~bash
curl localhost:${ARKH_PORT}657/consensus_state
~~~

### Delete node

~~~bash
sudo systemctl stop arkhd
sudo systemctl disable arkhd
sudo rm -rf /etc/systemd/system/arkhd*
sudo rm $(which arkhd)
sudo rm -rf $HOME/.arkh
sudo rm -fr $HOME/arkh-blockchain
sed -i "/ARKH_/d" $HOME/.bash_profile
~~~

