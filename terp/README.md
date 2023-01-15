<div>
<h1 align="left" style="display: flex;"> Terp Node Setup for Testnet — athena-2</h1>
<img src="https://avatars.githubusercontent.com/u/112838174?s=200&v=4"  style="float: right;" width="100" height="100"></img>
</div>

Official documentation:
>- [Validator setup instructions](https://github.com/terpnetwork/terp-core)

Bccnodes Explorer:
>-  https://explorer.bccnodes.com/terp


## Hardware Requirements
### Minimal Hardware Requirements
 - 4 GB RAM
 - 100 GB SSD
 - 3.2 x4 GHz CPU

### Recommended Hardware Requirements 
 - 8 GB RAM
 - 1 TB NVME SSD
 - 3.2 GHz x4 GHz CPU

## Set up your Terp node
### Manual installation

Update packages and Install dependencies

~~~bash
sudo apt update && sudo apt upgrade -y
sudo apt install curl git wget htop tmux build-essential jq make lz4 gcc -y
~~~

Replace your wallet and moniker `<YOUR_WALLET_NAME>` `<YOUR_MONIKER>` without `<>`, save and import variables into system

~~~bash
TERP_PORT=13
echo "export TERP_WALLET="<YOUR_WALLET_NAME>"" >> $HOME/.bash_profile
echo "export TERP_MONIKER="<YOUR_MONIKER>"" >> $HOME/.bash_profile
echo "export TERP_CHAIN_ID="athena-2"" >> $HOME/.bash_profile
echo "export TERP_PORT="${TERP_PORT}"" >> $HOME/.bash_profile
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
rm -rf ~/terp-core
git clone https://github.com/terpnetwork/terp-core.git
cd terp-core
git checkout v0.1.2
make install
~~~
Config and init app

~~~bash
terpd config node tcp://localhost:${TERP_PORT}657
terpd config chain-id $TERP_CHAIN_ID
terpd init $TERP_MONIKER --chain-id $TERP_CHAIN_ID
~~~

Download genesis and addrbook

~~~bash
curl https://raw.githubusercontent.com/terpnetwork/test-net/master/athena-2/genesis.json > ~/.terp/config/genesis.json
~~~

Set seeds and peers

~~~bash
SEEDS="19a2f912fd1e87bba8d5daf7578d438ce17d0f7f@195.201.197.4:33656"
PEERS=""
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.terp/config/config.toml
~~~

Set gustom ports in app.toml file

~~~bash
sed -i.bak -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${TERP_PORT}317\"%;
s%^address = \":8080\"%address = \":${TERP_PORT}080\"%;
s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:${TERP_PORT}090\"%; 
s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:${TERP_PORT}091\"%; 
s%^address = \"0.0.0.0:8545\"%address = \"0.0.0.0:${TERP_PORT}545\"%; 
s%^ws-address = \"0.0.0.0:8546\"%ws-address = \"0.0.0.0:${TERP_PORT}546\"%" $HOME/.terp/config/app.toml
~~~

Set gustom ports in config.toml file

~~~bash
sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${TERP_PORT}658\"%; 
s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://0.0.0.0:${TERP_PORT}657\"%; 
s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${TERP_PORT}060\"%;
s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${TERP_PORT}656\"%;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${TERP_PORT}656\"%;
s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${TERP_PORT}660\"%" $HOME/.terp/config/config.toml
~~~

Config pruning

~~~bash
sed -i -e "s/^pruning *=.*/pruning = \"nothing\"/" $HOME/.terp/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.terp/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.terp/config/app.toml
~~~

Set minimum gas price, enable prometheus and disable indexing

~~~bash
sed -i 's/minimum-gas-prices =.*/minimum-gas-prices = "0.0125uterpx"/g' $HOME/.terp/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.terp/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.terp/config/config.toml
~~~

Clean old data

~~~bash
terpd tendermint unsafe-reset-all --home $HOME/.terp --keep-addr-book
~~~

Create Service file

~~~bash
sudo tee /etc/systemd/system/terpd.service > /dev/null <<EOF
[Unit]
Description=terp
After=network-online.target

[Service]
User=$USER
ExecStart=$(which terpd) start --home $HOME/.terp
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
sudo systemctl enable terpd
sudo systemctl restart terpd && sudo journalctl -u terpd -f
~~~

## Create wallet
To create a new wallet, use the following command. don’t forget to save the mnemonic

~~~bash
terpd keys add $TERP_WALLET
~~~

(optional) To restore exexuting wallet, use the following command

~~~bash
terpd keys add $TERP_WALLET --recover
~~~

Save wallet and validator address

~~~bash
TERP_WALLET_ADDRESS=$(terpd keys show $TERP_WALLET -a)
~~~
~~~bash
TERP_VALOPER_ADDRESS=$(terpd keys show $TERP_WALLET --bech val -a)
~~~
~~~bash
echo "export TERP_WALLET_ADDRESS="${TERP_WALLET_ADDRESS} >> $HOME/.bash_profile
echo "export TERP_VALOPER_ADDRESS="${TERP_VALOPER_ADDRESS} >> $HOME/.bash_profile
source $HOME/.bash_profile
~~~

Fund your wallet 
Before creating a validator, you need to fund your wallet, go to the [Terp discord server]() and  and navigate to `faucet` channel

~~~bash
$request <YOUR_WALLET_ADDRESS>
~~~

## Create validator

before creating a validator, you need to check the balance and make sure that the node is synched

Check Sync status, once your node is fully synced, the output from above will say `false`

~~~bash
terpd status 2>&1 | jq .SyncInfo
~~~

Check your balance

~~~bash
terpd query bank balances $TERP_WALLET_ADDRESS
~~~

Create validator

~~~bash
terpd tx staking create-validator \
  --amount 1000000uterpx \
  --from $TERP_WALLET \
  --commission-max-change-rate "0.01" \
  --commission-max-rate "0.2" \
  --commission-rate "0.05" \
  --min-self-delegation "1" \
  --pubkey  $(terpd tendermint show-validator) \
  --moniker $TERP_MONIKER \
  --chain-id $TERP_CHAIN_ID \
  --gas=auto \
  --gas-adjustment=1.5 \
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
sudo ufw allow ${TERP_PORT}656/tcp
sudo ufw enable
~~~

## Usefull commands
### Service commands
check logs

~~~bash
sudo journalctl -u terpd -f
~~~

stop service

~~~bash
sudo systemctl stop terpd
~~~

start service

~~~bash
sudo systemctl start terpd
~~~

restart service

~~~bash
sudo systemctl restart terpd
~~~

### Wallet operation

check balance

~~~bash
terpd query bank balances $TERP_WALLET_ADDRESS
~~~

transfer funds

~~~bash
terpd tx bank send $TERP_WALLET_ADDRESS <TO_TERP_WALLET_ADDRESS> 1000000uterpx --gas auto --gas-adjustment 1.3
~~~

lists of wallets

~~~bash
terpd keys list
~~~

create a new wallet

~~~bash
terpd keys add $TERP_WALLET
~~~

recover wallet

~~~bash
terpd keys add $TERP_WALLET --recover
~~~

delete wallet

~~~bash
terpd keys delete $TERP_WALLET
~~~

### Node information

synch info

~~~bash
terpd status 2>&1 | jq .SyncInfo
~~~

node status

~~~bash
curl -s localhost:${TERP_PORT}657/status
~~~

node info

~~~bash
terpd status 2>&1 | jq .NodeInfo
~~~

validator info

~~~bash
terpd status 2>&1 | jq .ValidatorInfo
~~~

your node peers

~~~bash
echo $(terpd tendermint show-node-id)'@'$(curl -s ifconfig.me)':'$(cat $HOME/.terp/config/config.toml | sed -n '/Address to listen for incoming connection/{n;p;}' | sed 's/.*://; s/".*//')
~~~

get currently conected peers lis

~~~bash
curl -sS http://localhost:${TERP_PORT}657/net_info | jq -r '.result.peers[] | "\(.node_info.id)@\(.remote_ip):\(.node_info.listen_addr)"' | awk -F ':' '{print $1":"$(NF)}'
~~~

### Voting

~~~bash
terpd tx gov vote 1 yes --from $TERP_WALLET --chain-id $TERP_CHAIN_ID
~~~

### Staking, Delegation and Rewards

Withdraw all rewards

~~~bash
terpd tx distribution withdraw-all-rewards --from $TERP_WALLET --chain-id $TERP_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

Withdraw rewards with commision

~~~bash
terpd tx distribution withdraw-rewards $TERP_VALOPER_ADDRESS --from $TERP_WALLET --commission --chain-id $TERP_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

Check balance 

~~~bash
terpd query bank balances $TERP_WALLET_ADDRESS
~~~

Delegate stake

~~~bash
terpd tx staking delegate $TERP_VALOPER_ADDRESS 1000000uterpx --from $TERP_WALLET --chain-id $TERP_CHAIN_ID --gas=auto --gas-adjustment 1.3
~~~

Redelegate stake to another validator

~~~bash
terpd tx staking redelegate <srcValidatorAddress> <destValidatorAddress> 1000000uterpx --from $TERP_WALLET --chain-id $TERP_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

### Validator operation

Edit validator

~~~bash
terpd tx staking edit-validator \
  --moniker=$NODENAME \
  --identity=<your_keybase_id> \
  --website="<your_website>" \
  --details="<your_validator_description>" \
  --chain-id=$TERP_CHAIN_ID \
  --from=$TERP_WALLET
~~~

Validator info

~~~bash
terpd status 2>&1 | jq .ValidatorInfo

~~~

Jailing info

~~~bash
terpd q slashing signing-info $(terpd tendermint show-validator)
~~~

Unjail validator

~~~bash
terpd tx slashing unjail --broadcast-mode=block --from $TERP_WALLET --chain-id $TERP_CHAIN_ID --gas auto --gas-adjustment 1.5
~~~

Consensus state

~~~bash
curl localhost:${TERP_PORT}657/consensus_state
~~~

### Delete node

~~~bash
sudo systemctl stop terpd
sudo systemctl disable terpd
sudo rm -rf /etc/systemd/system/terpd*
sudo rm $(which terpd)
sudo rm -rf $HOME/.terp
sudo rm -fr $HOME/terp-core
sed -i "/TERP_/d" $HOME/.bash_profile
~~~

