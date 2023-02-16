<div>
<h1 align="left" style="display: flex;"> Dymension Node Setup for Testnet — 35-C</h1>
<img src="https://avatars.githubusercontent.com/u/108229184?s=200&v=4"  style="float: right;" width="100" height="100"></img>
</div>

Official documentation:
>- [Validator setup instructions](https://docs.dymension.xyz/validate/dymension-hub/overview)

Explorer:
>-  https://testnet.itrocket.net/dymension/staking


## Hardware Requirements
### Recommended Hardware Requirements 
 - Dual Core
 - At least 500GB of SSD disk storage
 - At least 16GB of memory (RAM)
 - At least 100mbps network bandwidth

## Set up your node
### Manual installation

Update packages and Install dependencies

~~~bash
sudo apt update && sudo apt upgrade -y
sudo apt install curl git wget htop tmux build-essential jq make lz4 gcc -y
~~~

Replace your moniker `<YOUR_MONIKER>` without `<>`, save and import variables into system

~~~bash
DYMENSION_PORT=32
echo "export WALLET="wallet"" >> $HOME/.bash_profile
echo "export MONIKER="<YOUR_MONIKER>"" >> $HOME/.bash_profile
echo "export DYMENSION_CHAIN_ID="35-C"" >> $HOME/.bash_profile
echo "export DYMENSION_PORT="${DYMENSION_PORT}"" >> $HOME/.bash_profile
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
rm -rf dymension
git clone https://github.com/dymensionxyz/dymension.git --branch v0.2.0-beta
cd dymension
make install
~~~

Config and init app

~~~bash
dymd config node tcp://localhost:${DYMENSION_PORT}657
dymd config keyring-backend test
dymd config chain-id $DYMENSION_CHAIN_ID
dymd init $MONIKER --chain-id $DYMENSION_CHAIN_ID
~~~

Download genesis and addrbook

~~~bash
wget -O $HOME/.dymension/config/genesis.json https://files.itrocket.net/testnet/dymension/genesis.json
wget -O $HOME/.dymension/config/addrbook.json https://files.itrocket.net/testnet/dymension/addrbook.json
~~~

Set seeds and peers

~~~bash
SEEDS=""
PEERS="adf394846dc942b1fd03f6e310eda60b5eda7848@dymension-testnet-peer.itrocket.net:443,562f840c5f6d11ac846f77502198f7c724ef21b9@185.219.142.32:04656,e8a706e3a81a36a6dded6cc02eabaf5d355f4c1d@80.79.5.171:28656,5d689e09a129c03c003f05850262f03b2433a384@51.79.30.141:26656,af6787b3273dd60e0f809c7e5e2a2a9fd379045e@195.201.195.61:27656,7fc44e2651006fb2ddb4a56132e738da2845715f@65.108.6.45:61256,a4b27ddb9e126d1debafeef0a23ab60e4d5d8a14@95.216.2.219:26656,bb8615bb51139c05fd59020fc2aa7eac210690b4@135.181.221.186:27656,9e1ea4938f0112c1477827344e2f9d0792710575@185.252.232.189:30656,c6cdcc7f8e1a33f864956a8201c304741411f219@3.214.163.125:26656"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.dymension/config/config.toml
~~~

Set gustom ports in app.toml file

~~~bash
sed -i.bak -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${DYMENSION_PORT}317\"%;
s%^address = \":8080\"%address = \":${DYMENSION_PORT}080\"%;
s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:${DYMENSION_PORT}090\"%; 
s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:${DYMENSION_PORT}091\"%; 
s%^address = \"0.0.0.0:8545\"%address = \"0.0.0.0:${DYMENSION_PORT}545\"%; 
s%^ws-address = \"0.0.0.0:8546\"%ws-address = \"0.0.0.0:${DYMENSION_PORT}546\"%" $HOME/.dymension/config/app.toml
~~~

Set gustom ports in config.toml file

~~~bash
sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${DYMENSION_PORT}658\"%; 
s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://0.0.0.0:${DYMENSION_PORT}657\"%; 
s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${DYMENSION_PORT}060\"%;
s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${DYMENSION_PORT}656\"%;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${DYMENSION_PORT}656\"%;
s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${DYMENSION_PORT}660\"%" $HOME/.dymension/config/config.toml
~~~

Config pruning

~~~bash
sed -i -e "s/^pruning *=.*/pruning = \"nothing\"/" $HOME/.dymension/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.dymension/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.dymension/config/app.toml
~~~

Set minimum gas price, enable prometheus and disable indexing

~~~bash
sed -i 's/minimum-gas-prices =.*/minimum-gas-prices = "0.0udym"/g' $HOME/.dymension/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.dymension/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.dymension/config/config.toml
~~~

Reset chain data
~~~bash
dymd tendermint unsafe-reset-all --home $HOME/.dymension
~~~

Create Service file

~~~bash
sudo tee /etc/systemd/system/dymd.service > /dev/null <<EOF
[Unit]
Description=dymension
After=network-online.target

[Service]
User=$USER
ExecStart=$(which dymd) start --home $HOME/.dymension
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
sudo systemctl enable dymd
sudo systemctl restart dymd && sudo journalctl -u dymd -f
~~~

## Create wallet
To create a new wallet, use the following command. don’t forget to save the mnemonic

~~~bash
dymd keys add $WALLET
~~~

(optional) To restore exexuting wallet, use the following command

~~~bash
dymd keys add $WALLET --recover
~~~

Save wallet and validator address

~~~bash
WALLET_ADDRESS=$(dymd keys show $WALLET -a)
VALOPER_ADDRESS=$(dymd keys show $WALLET --bech val -a)
echo "export WALLET_ADDRESS="${WALLET_ADDRESS} >> $HOME/.bash_profile
echo "export VALOPER_ADDRESS="${VALOPER_ADDRESS} >> $HOME/.bash_profile
source $HOME/.bash_profile
~~~

## (OPTIONAL) State Sync, Snapshot

In order not to wait for a long synchronization, you can use our StateSync or Snapshot guide:
> https://itrocket.net/services/testnet/dymension/#snap
> https://itrocket.net/services/testnet/dymension/#sync


## Create validator

before creating a validator, you need to check the balance and make sure that the node is synched

Check Sync status, once your node is fully synced, the output from above will say `false`

~~~bash
dymd status 2>&1 | jq .SyncInfo
~~~

Check your balance

~~~bash
dymd query bank balances $WALLET_ADDRESS
~~~

Create validator

~~~bash
dymd tx staking create-validator \
  --amount 1000000udym \
  --from $WALLET \
  --commission-max-change-rate "0.01" \
  --commission-max-rate "0.2" \
  --commission-rate "0.05" \
  --min-self-delegation "1" \
  --pubkey  $(dymd tendermint show-validator) \
  --moniker $MONIKER \
  --chain-id $DYMENSION_CHAIN_ID
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
sudo ufw allow ${DYMENSION_PORT}656/tcp
sudo ufw enable
~~~

## Usefull commands
### Service commands
check logs

~~~bash
sudo journalctl -u dymd -f
~~~

stop service

~~~bash
sudo systemctl stop dymd
~~~

start service

~~~bash
sudo systemctl start dymd
~~~

restart service

~~~bash
sudo systemctl restart dymd
~~~

### Wallet operation

check balance

~~~bash
dymd query bank balances $WALLET_ADDRESS
~~~

transfer funds

~~~bash
dymd tx bank send $WALLET_ADDRESS <TO_WALLET_ADDRESS> 1000000udym --gas auto --gas-adjustment 1.3
~~~

lists of wallets

~~~bash
dymd keys list
~~~

create a new wallet

~~~bash
dymd keys add $WALLET
~~~

recover wallet

~~~bash
dymd keys add $WALLET --recover
~~~

delete wallet

~~~bash
dymd keys delete $WALLET
~~~

### Node information

synch info

~~~bash
dymd status 2>&1 | jq .SyncInfo
~~~

node status

~~~bash
curl -s localhost:${DYMENSION_PORT}657/status
~~~

node info

~~~bash
dymd status 2>&1 | jq .NodeInfo
~~~

validator info

~~~bash
dymd status 2>&1 | jq .ValidatorInfo
~~~

your node peers

~~~bash
echo $(dymd tendermint show-node-id)'@'$(curl -s ifconfig.me)':'$(cat $HOME/.dymension/config/config.toml | sed -n '/Address to listen for incoming connection/{n;p;}' | sed 's/.*://; s/".*//')
~~~

get currently conected peers lis

~~~bash
curl -sS http://localhost:${DYMENSION_PORT}657/net_info | jq -r '.result.peers[] | "\(.node_info.id)@\(.remote_ip):\(.node_info.listen_addr)"' | awk -F ':' '{print $1":"$(NF)}'
~~~

### Voting

~~~bash
dymd tx gov vote 1 yes --from $WALLET --chain-id $DYMENSION_CHAIN_ID
~~~

### Staking, Delegation and Rewards

Withdraw all rewards

~~~bash
dymd tx distribution withdraw-all-rewards --from $WALLET --chain-id $DYMENSION_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

Withdraw rewards with commision

~~~bash
dymd tx distribution withdraw-rewards $VALOPER_ADDRESS --from $WALLET --commission --chain-id $DYMENSION_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

Check balance 

~~~bash
dymd query bank balances $WALLET_ADDRESS
~~~

Delegate stake

~~~bash
dymd tx staking delegate $VALOPER_ADDRESS 1000000udym --from $WALLET --chain-id $DYMENSION_CHAIN_ID --gas=auto --gas-adjustment 1.3
~~~

Redelegate stake to another validator

~~~bash
dymd tx staking redelegate <srcValidatorAddress> <destValidatorAddress> 1000000udym --from $WALLET --chain-id $DYMENSION_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

### Validator operation

Edit validator

~~~bash
dymd tx staking edit-validator \
  --moniker=$NODENAME \
  --identity=<your_keybase_id> \
  --website="<your_website>" \
  --details="<your_validator_description>" \
  --chain-id=$DYMENSION_CHAIN_ID \
  --from=$WALLET
~~~

Validator info

~~~bash
dymd status 2>&1 | jq .ValidatorInfo

~~~

Jailing info

~~~bash
dymd q slashing signing-info $(dymd tendermint show-validator)
~~~

Unjail validator

~~~bash
dymd tx slashing unjail --broadcast-mode=block --from $WALLET --chain-id $DYMENSION_CHAIN_ID --gas auto --gas-adjustment 1.5
~~~

Consensus state

~~~bash
curl localhost:${DYMENSION_PORT}657/consensus_state
~~~

### Delete node

~~~bash
sudo systemctl stop dymd
sudo systemctl disable dymd
sudo rm -rf /etc/systemd/system/dymd*
sudo rm $(which dymd)
sudo rm -rf $HOME/.dymension
sudo rm -fr $HOME/dymension
sed -i "/DYMENSION_/d" $HOME/.bash_profile
~~~

