<div>
<h1 align="left" style="display: flex;"> Quasar Node Setup for Testnet — qsr-questnet-04</h1>
<img src="https://avatars.githubusercontent.com/u/102316182?s=200&v=4"  style="float: right;" width="100" height="100"></img>
</div>

Official documentation:
>- [Validator setup instructions](https://github.com/quasar-finance/questnet/blob/main/docs/Get_quasar.md)

Explorer:
>-  https://testnet.itrocket.net/quasar/staking


## Hardware Requirements
### Recommended Hardware Requirements 
 - 4 or more physical CPU cores
 - At least 500GB of SSD disk storage
 - At least 16GB of memory
 - At least 100mbps network bandwidth

## Set up your quasar node
### Manual installation

Update packages and Install dependencies

~~~bash
sudo apt update && sudo apt upgrade -y
sudo apt install curl git wget htop tmux build-essential jq make lz4 gcc -y
~~~

Replace your moniker `<YOUR_MONIKER>` without `<>`, save and import variables into system

~~~bash
QUASAR_PORT=29
echo "export WALLET="wallet"" >> $HOME/.bash_profile
echo "export MONIKER="<YOUR_MONIKER>"" >> $HOME/.bash_profile
echo "export QUASAR_CHAIN_ID="qsr-questnet-04"" >> $HOME/.bash_profile
echo "export QUASAR_PORT="${QUASAR_PORT}"" >> $HOME/.bash_profile
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
wget https://github.com/quasar-finance/binary-release/raw/main/v0.0.2-alpha-11/quasarnoded-linux-amd64
chmod +x quasarnoded-linux-amd64
if [ ! -d "$HOME/go/bin" ]; then
mkdir $HOME/go/bin
fi
sudo mv quasarnoded-linux-amd64 $HOME/go/bin/quasarnoded
quasarnoded version
~~~

Config and init app

~~~bash
quasarnoded config node tcp://localhost:${QUASAR_PORT}657
quasarnoded config keyring-backend test
quasarnoded config chain-id $QUASAR_CHAIN_ID
quasarnoded init $MONIKER --chain-id $QUASAR_CHAIN_ID
~~~

Download genesis and addrbook

~~~bash
wget -O $HOME/.quasarnode/config/genesis.json https://files.itrocket.net/testnet/quasar/genesis.json
~~~

Set seeds and peers

~~~bash
SEEDS=""
PEERS="19afe579cc0a2b38ca87143f779f45e9a7f18a2f@18.134.191.148:26656,a23f002bda10cb90fa441a9f2435802b35164441@38.146.3.203:18256,bffb10a5619be7bfa98919e08f4a6bef4f8f6bf0@135.181.210.186:26656,8937bdacf1f0c8b2d1ffb4606554eaf08bd55df4@5.75.255.107:26656,1112acc7479a8a1afb0777b0b9a39fb1f7e77abd@34.175.69.87:26656,bcb8d2b5d5464cddbab9ce2705aae3ad3e38aeac@144.76.67.53:2490,41ee7632f310c035235828ce03c208dbe1e24d7d@38.146.3.204:18256,bba6e85e3d1f1d9c127324e71a982ddd86af9a99@88.99.3.158:18256,966acc999443bae0857604a9fce426b5e09a7409@65.108.105.48:18256,1c1043ae487c91209fce8c589a5772a7f3846e7c@136.243.88.91:8080,20b4f9207cdc9d0310399f848f057621f7251846@222.106.187.13:40606,177144bed1e280a6f2435d253441e3e4f1699c6d@65.109.85.226:8090"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.quasarnode/config/config.toml
~~~

Set gustom ports in app.toml file

~~~bash
sed -i.bak -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${QUASAR_PORT}317\"%;
s%^address = \":8080\"%address = \":${QUASAR_PORT}080\"%;
s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:${QUASAR_PORT}090\"%; 
s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:${QUASAR_PORT}091\"%; 
s%^address = \"0.0.0.0:8545\"%address = \"0.0.0.0:${QUASAR_PORT}545\"%; 
s%^ws-address = \"0.0.0.0:8546\"%ws-address = \"0.0.0.0:${QUASAR_PORT}546\"%" $HOME/.quasarnode/config/app.toml
~~~

Set gustom ports in config.toml file

~~~bash
sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${QUASAR_PORT}658\"%; 
s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://0.0.0.0:${QUASAR_PORT}657\"%; 
s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${QUASAR_PORT}060\"%;
s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${QUASAR_PORT}656\"%;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${QUASAR_PORT}656\"%;
s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${QUASAR_PORT}660\"%" $HOME/.quasarnode/config/config.toml
~~~

Config pruning

~~~bash
sed -i -e "s/^pruning *=.*/pruning = \"nothing\"/" $HOME/.quasarnode/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.quasarnode/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.quasarnode/config/app.toml
~~~

Set minimum gas price, enable prometheus and disable indexing

~~~bash
sed -i 's/minimum-gas-prices =.*/minimum-gas-prices = "0.0uqsr"/g' $HOME/.quasarnode/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.quasarnode/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.quasarnode/config/config.toml
~~~

Reset chain data
~~~bash
quasarnoded tendermint unsafe-reset-all --home $HOME/.quasarnode
~~~

Create Service file

~~~bash
sudo tee /etc/systemd/system/quasarnoded.service > /dev/null <<EOF
[Unit]
Description=quasar
After=network-online.target

[Service]
User=$USER
ExecStart=$(which quasarnoded) start --home $HOME/.quasarnode
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
sudo systemctl enable quasarnoded
sudo systemctl restart quasarnoded && sudo journalctl -u quasarnoded -f
~~~

## Create wallet
To create a new wallet, use the following command. don’t forget to save the mnemonic

~~~bash
quasarnoded keys add $WALLET
~~~

(optional) To restore exexuting wallet, use the following command

~~~bash
quasarnoded keys add $WALLET --recover
~~~

Save wallet and validator address

~~~bash
WALLET_ADDRESS=$(quasarnoded keys show $WALLET -a)
VALOPER_ADDRESS=$(quasarnoded keys show $WALLET --bech val -a)
echo "export WALLET_ADDRESS="${WALLET_ADDRESS} >> $HOME/.bash_profile
echo "export VALOPER_ADDRESS="${VALOPER_ADDRESS} >> $HOME/.bash_profile
source $HOME/.bash_profile
~~~

## Create validator

before creating a validator, you need to check the balance and make sure that the node is synched

Check Sync status, once your node is fully synced, the output from above will say `false`

~~~bash
quasarnoded status 2>&1 | jq .SyncInfo
~~~

Check your balance

~~~bash
quasarnoded query bank balances $WALLET_ADDRESS
~~~

Create validator

~~~bash
quasarnoded tx staking create-validator \
  --amount 1000000uqsr \
  --from $WALLET \
  --commission-max-change-rate "0.01" \
  --commission-max-rate "0.2" \
  --commission-rate "0.05" \
  --min-self-delegation "1" \
  --pubkey  $(quasarnoded tendermint show-validator) \
  --moniker $MONIKER \
  --chain-id $QUASAR_CHAIN_ID
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
sudo ufw allow ${QUASAR_PORT}656/tcp
sudo ufw enable
~~~

## Usefull commands
### Service commands
check logs

~~~bash
sudo journalctl -u quasarnoded -f
~~~

stop service

~~~bash
sudo systemctl stop quasarnoded
~~~

start service

~~~bash
sudo systemctl start quasarnoded
~~~

restart service

~~~bash
sudo systemctl restart quasarnoded
~~~

### Wallet operation

check balance

~~~bash
quasarnoded query bank balances $WALLET_ADDRESS
~~~

transfer funds

~~~bash
quasarnoded tx bank send $WALLET_ADDRESS <TO_WALLET_ADDRESS> 1000000uqsr --gas auto --gas-adjustment 1.3
~~~

lists of wallets

~~~bash
quasarnoded keys list
~~~

create a new wallet

~~~bash
quasarnoded keys add $WALLET
~~~

recover wallet

~~~bash
quasarnoded keys add $WALLET --recover
~~~

delete wallet

~~~bash
quasarnoded keys delete $WALLET
~~~

### Node information

synch info

~~~bash
quasarnoded status 2>&1 | jq .SyncInfo
~~~

node status

~~~bash
curl -s localhost:${QUASAR_PORT}657/status
~~~

node info

~~~bash
quasarnoded status 2>&1 | jq .NodeInfo
~~~

validator info

~~~bash
quasarnoded status 2>&1 | jq .ValidatorInfo
~~~

your node peers

~~~bash
echo $(quasarnoded tendermint show-node-id)'@'$(curl -s ifconfig.me)':'$(cat $HOME/.quasarnode/config/config.toml | sed -n '/Address to listen for incoming connection/{n;p;}' | sed 's/.*://; s/".*//')
~~~

get currently conected peers lis

~~~bash
curl -sS http://localhost:${QUASAR_PORT}657/net_info | jq -r '.result.peers[] | "\(.node_info.id)@\(.remote_ip):\(.node_info.listen_addr)"' | awk -F ':' '{print $1":"$(NF)}'
~~~

### Voting

~~~bash
quasarnoded tx gov vote 1 yes --from $WALLET --chain-id $QUASAR_CHAIN_ID
~~~

### Staking, Delegation and Rewards

Withdraw all rewards

~~~bash
quasarnoded tx distribution withdraw-all-rewards --from $WALLET --chain-id $QUASAR_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

Withdraw rewards with commision

~~~bash
quasarnoded tx distribution withdraw-rewards $VALOPER_ADDRESS --from $WALLET --commission --chain-id $QUASAR_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

Check balance 

~~~bash
quasarnoded query bank balances $WALLET_ADDRESS
~~~

Delegate stake

~~~bash
quasarnoded tx staking delegate $VALOPER_ADDRESS 1000000uqsr --from $WALLET --chain-id $QUASAR_CHAIN_ID --gas=auto --gas-adjustment 1.3
~~~

Redelegate stake to another validator

~~~bash
quasarnoded tx staking redelegate <srcValidatorAddress> <destValidatorAddress> 1000000uqsr --from $WALLET --chain-id $QUASAR_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

### Validator operation

Edit validator

~~~bash
quasarnoded tx staking edit-validator \
  --moniker=$NODENAME \
  --identity=<your_keybase_id> \
  --website="<your_website>" \
  --details="<your_validator_description>" \
  --chain-id=$QUASAR_CHAIN_ID \
  --from=$WALLET
~~~

Validator info

~~~bash
quasarnoded status 2>&1 | jq .ValidatorInfo

~~~

Jailing info

~~~bash
quasarnoded q slashing signing-info $(quasarnoded tendermint show-validator)
~~~

Unjail validator

~~~bash
quasarnoded tx slashing unjail --broadcast-mode=block --from $WALLET --chain-id $QUASAR_CHAIN_ID --gas auto --gas-adjustment 1.5
~~~

Consensus state

~~~bash
curl localhost:${QUASAR_PORT}657/consensus_state
~~~

### Delete node

~~~bash
sudo systemctl stop quasarnoded
sudo systemctl disable quasarnoded
sudo rm -rf /etc/systemd/system/quasarnoded*
sudo rm $(which quasarnoded)
sudo rm -rf $HOME/.quasarnode
sed -i "/QUASAR_/d" $HOME/.bash_profile
~~~

