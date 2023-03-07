<div>
<h1 align="left" style="display: flex;"> Ojo Node Setup for Testnet — ojo-devnet</h1>
<img src="https://avatars.githubusercontent.com/u/110753560?s=200&v=4"  style="float: right;" width="100" height="100"></img>
</div>

Official documentation:
>- [Validator setup instructions](https://docs.ojo.network/sauron-testnet/joining-as-a-validator)

Explorer:
>-  https://testnet.itrocket.net/ojo/staking


## Hardware Requirements
### Recommended Hardware Requirements 
 - 4 vCPU
 - 8GB RAM
 - 200GB of storage

## Set up your node
### Manual installation

Update packages and Install dependencies

~~~bash
sudo apt update && sudo apt upgrade -y
sudo apt install curl git wget htop tmux build-essential jq make lz4 gcc -y
~~~

Replace your moniker `<YOUR_MONIKER>` without `<>`, save and import variables into system

~~~bash
OJO_PORT=12
echo "export WALLET="wallet"" >> $HOME/.bash_profile
echo "export MONIKER="<YOUR_MONIKER>"" >> $HOME/.bash_profile
echo "export OJO_CHAIN_ID="ojo-devnet"" >> $HOME/.bash_profile
echo "export OJO_PORT="${OJO_PORT}"" >> $HOME/.bash_profile
source $HOME/.bash_profile
~~~

install go

~~~bash
cd $HOME
if ! [ -x "$(command -v go)" ]; then
VER="1.20"
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
rm -rf ojo
git clone https://github.com/ojo-network/ojo.git
cd ojo
git checkout v0.1.2
make install
~~~

Config and init app

~~~bash
ojod config node tcp://localhost:${OJO_PORT}657
ojod config keyring-backend test
ojod config chain-id $OJO_CHAIN_ID
ojod init $MONIKER --chain-id $OJO_CHAIN_ID
~~~

Download genesis and addrbook

~~~bash
wget -O $HOME/.ojo/config/genesis.json https://files.itrocket.net/testnet/ojo/genesis.json
wget -O $HOME/.ojo/config/addrbook.json https://files.itrocket.net/testnet/ojo/addrbook.json
~~~

Set seeds and peers

~~~bash
SEEDS="7186f24ace7f4f2606f56f750c2684d387dc39ac@ojo-testnet-seed.itrocket.net:12656"
PEERS=""
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.ojo/config/config.toml
~~~

Set gustom ports in app.toml file

~~~bash
sed -i.bak -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${OJO_PORT}317\"%;
s%^address = \":8080\"%address = \":${OJO_PORT}080\"%;
s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:${OJO_PORT}090\"%; 
s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:${OJO_PORT}091\"%; 
s%^address = \"0.0.0.0:8545\"%address = \"0.0.0.0:${OJO_PORT}545\"%; 
s%^ws-address = \"0.0.0.0:8546\"%ws-address = \"0.0.0.0:${OJO_PORT}546\"%" $HOME/.ojo/config/app.toml
~~~

Set gustom ports in config.toml file

~~~bash
sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${OJO_PORT}658\"%; 
s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://0.0.0.0:${OJO_PORT}657\"%; 
s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${OJO_PORT}060\"%;
s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${OJO_PORT}656\"%;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${OJO_PORT}656\"%;
s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${OJO_PORT}660\"%" $HOME/.ojo/config/config.toml
~~~

Config pruning

~~~bash
sed -i -e "s/^pruning *=.*/pruning = \"nothing\"/" $HOME/.ojo/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.ojo/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.ojo/config/app.toml
~~~

Set minimum gas price, enable prometheus and disable indexing

~~~bash
sed -i 's/minimum-gas-prices =.*/minimum-gas-prices = "0.0uojo"/g' $HOME/.ojo/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.ojo/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.ojo/config/config.toml
~~~

Reset chain data
~~~bash
ojod tendermint unsafe-reset-all --home $HOME/.ojo
~~~

Create Service file

~~~bash
sudo tee /etc/systemd/system/ojod.service > /dev/null <<EOF
[Unit]
Description=ojo
After=network-online.target

[Service]
User=$USER
ExecStart=$(which ojod) start --home $HOME/.ojo
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
sudo systemctl enable ojod
sudo systemctl restart ojod && sudo journalctl -u ojod -f
~~~

## Snapshot, State Sync (OPTIONAL)
In order not to wait for a long synchronization, you can use our guides:

>https://itrocket.net/services/testnet/ojo/#snap  
>https://itrocket.net/services/testnet/ojo/#sync


## Create wallet
To create a new wallet, use the following command. don’t forget to save the mnemonic

~~~bash
ojod keys add $WALLET
~~~

(optional) To restore exexuting wallet, use the following command

~~~bash
ojod keys add $WALLET --recover
~~~

Save wallet and validator address

~~~bash
WALLET_ADDRESS=$(ojod keys show $WALLET -a)
VALOPER_ADDRESS=$(ojod keys show $WALLET --bech val -a)
echo "export WALLET_ADDRESS="${WALLET_ADDRESS} >> $HOME/.bash_profile
echo "export VALOPER_ADDRESS="${VALOPER_ADDRESS} >> $HOME/.bash_profile
source $HOME/.bash_profile
~~~

## Create validator

before creating a validator, you need to check the balance and make sure that the node is synched

Check Sync status, once your node is fully synced, the output from above will say `false`

~~~bash
ojod status 2>&1 | jq .SyncInfo
~~~

Check your balance

~~~bash
ojod query bank balances $WALLET_ADDRESS
~~~

Create validator

~~~bash
ojod tx staking create-validator \
  --amount 1000000uojo \
  --from $WALLET \
  --commission-max-change-rate "0.01" \
  --commission-max-rate "0.2" \
  --commission-rate "0.05" \
  --min-self-delegation "1" \
  --pubkey  $(ojod tendermint show-validator) \
  --moniker $MONIKER \
  --chain-id $OJO_CHAIN_ID
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
sudo ufw allow ${OJO_PORT}656/tcp
sudo ufw enable
~~~

## Usefull commands
### Service commands
check logs

~~~bash
sudo journalctl -u ojod -f
~~~

stop service

~~~bash
sudo systemctl stop ojod
~~~

start service

~~~bash
sudo systemctl start ojod
~~~

restart service

~~~bash
sudo systemctl restart ojod
~~~

### Wallet operation

check balance

~~~bash
ojod query bank balances $WALLET_ADDRESS
~~~

transfer funds

~~~bash
ojod tx bank send $WALLET_ADDRESS <TO_WALLET_ADDRESS> 1000000uojo --gas auto --gas-adjustment 1.3
~~~

lists of wallets

~~~bash
ojod keys list
~~~

create a new wallet

~~~bash
ojod keys add $WALLET
~~~

recover wallet

~~~bash
ojod keys add $WALLET --recover
~~~

delete wallet

~~~bash
ojod keys delete $WALLET
~~~

### Node information

synch info

~~~bash
ojod status 2>&1 | jq .SyncInfo
~~~

node status

~~~bash
curl -s localhost:${OJO_PORT}657/status
~~~

node info

~~~bash
ojod status 2>&1 | jq .NodeInfo
~~~

validator info

~~~bash
ojod status 2>&1 | jq .ValidatorInfo
~~~

your node peers

~~~bash
echo $(ojod tendermint show-node-id)'@'$(curl -s ifconfig.me)':'$(cat $HOME/.ojo/config/config.toml | sed -n '/Address to listen for incoming connection/{n;p;}' | sed 's/.*://; s/".*//')
~~~

get currently conected peers lis

~~~bash
curl -sS http://localhost:${OJO_PORT}657/net_info | jq -r '.result.peers[] | "\(.node_info.id)@\(.remote_ip):\(.node_info.listen_addr)"' | awk -F ':' '{print $1":"$(NF)}'
~~~

### Voting

~~~bash
ojod tx gov vote 1 yes --from $WALLET --chain-id $OJO_CHAIN_ID
~~~

### Staking, Delegation and Rewards

Withdraw all rewards

~~~bash
ojod tx distribution withdraw-all-rewards --from $WALLET --chain-id $OJO_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

Withdraw rewards with commision

~~~bash
ojod tx distribution withdraw-rewards $VALOPER_ADDRESS --from $WALLET --commission --chain-id $OJO_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

Check balance 

~~~bash
ojod query bank balances $WALLET_ADDRESS
~~~

Delegate stake

~~~bash
ojod tx staking delegate $VALOPER_ADDRESS 1000000uojo --from $WALLET --chain-id $OJO_CHAIN_ID --gas=auto --gas-adjustment 1.3
~~~

Redelegate stake to another validator

~~~bash
ojod tx staking redelegate <srcValidatorAddress> <destValidatorAddress> 1000000uojo --from $WALLET --chain-id $OJO_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

Unbond

~~~bash
ojod tx staking unbond $VALOPER_ADDRESS 1000000uojo --from $WALLET --chain-id $OJO_CHAIN_ID --gas=auto --gas-adjustment 1.3
~~~

### Validator operation

Edit validator

~~~bash
ojod tx staking edit-validator \
  --moniker=$NODENAME \
  --identity=<your_keybase_id> \
  --website="<your_website>" \
  --details="<your_validator_description>" \
  --chain-id=$OJO_CHAIN_ID \
  --from=$WALLET
~~~

Validator info

~~~bash
ojod status 2>&1 | jq .ValidatorInfo

~~~

Jailing info

~~~bash
ojod q slashing signing-info $(ojod tendermint show-validator)
~~~

Unjail validator

~~~bash
ojod tx slashing unjail --broadcast-mode=block --from $WALLET --chain-id $OJO_CHAIN_ID --gas auto --gas-adjustment 1.5
~~~

Consensus state

~~~bash
curl localhost:${OJO_PORT}657/consensus_state
~~~

### Delete node

~~~bash
sudo systemctl stop ojod
sudo systemctl disable ojod
sudo rm -rf /etc/systemd/system/ojod*
sudo rm $(which ojod)
sudo rm -rf $HOME/.ojo
sudo rm -fr $HOME/ojo
sed -i "/OJO_/d" $HOME/.bash_profile
~~~

