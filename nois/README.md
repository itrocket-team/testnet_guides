<div>
<h1 align="left" style="display: flex;"> Nois Node Validator Setup for Testnet — nois-testnet-003</h1>
<img src="https://raw.githubusercontent.com/itrocket-team/testnet_guides/main/logos/nois.png"  style="float: right;" width="100" height="100"></img>
</div>

Official documentation:
>- [Validator setup instructions](https://docs.nois.network/use-cases/for-validators)

Explorer:
>-  https://testnet.itrocket.net/nois


## Hardware Requirements
### Recommended Hardware Requirements 
 - 4x CPUs
 - 8GB RAM
 - 100GB of storage (SSD or NVME)
 - Permanent Internet connection (traffic will be minimal during testnet; 10Mbps will be plenty - for production at least 100Mbps is expected)

## Set up your nois node
### Manual installation

Update packages and Install dependencies

~~~bash
sudo apt update && sudo apt upgrade -y
sudo apt install curl git wget htop tmux build-essential jq make lz4 gcc -y
~~~

Replace your moniker `<YOUR_MONIKER>` without `<>`, save and import variables into system

~~~bash
NOIS_PORT=21
echo "export WALLET="wallet"" >> $HOME/.bash_profile
echo "export MONIKER="<YOUR_MONIKER>"" >> $HOME/.bash_profile
echo "export NOIS_CHAIN_ID="nois-testnet-003"" >> $HOME/.bash_profile
echo "export NOIS_PORT="${NOIS_PORT}"" >> $HOME/.bash_profile
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
mkdir $HOME/go/bin
source $HOME/.bash_profile
go version
~~~

Download and build binaries

~~~bash
cd $HOME
rm -rf $HOME/full-node
git clone https://github.com/noislabs/full-node.git 
cd full-node/full-node/
git checkout nois-testnet-003
./build.sh
mv $HOME/full-node/full-node/out/noisd $HOME/go/bin/
~~~

Config and init app

~~~bash
cd $HOME
noisd config node tcp://localhost:${NOIS_PORT}657
noisd config keyring-backend test
noisd config chain-id $NOIS_CHAIN_ID
noisd init $MONIKER --chain-id $NOIS_CHAIN_ID
~~~

Download genesis and addrbook

~~~bash
wget -O "$HOME/.noisd/config/genesis.json" https://raw.githubusercontent.com/noislabs/testnets/main/nois-testnet-003/genesis.json
~~~

Set seeds and peers

~~~bash
SEEDS="da81dd66bca4bba509163dbd06b4a6b2e05c2e12@nois-testnet-seed.itrocket.net:443"
PEERS="5ecd40831e453845587cbd03534e68a7b9fc3576@nois-testnet-peer.itrocket.net:443,bf5bbdf9ac1ccd72d7b29c3fbcc7e99ff89fd053@node-0.noislabs.com:26656"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.noisd/config/config.toml
~~~

Set gustom ports in app.toml file

~~~bash
sed -i.bak -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${NOIS_PORT}317\"%;
s%^address = \":8080\"%address = \":${NOIS_PORT}080\"%;
s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:${NOIS_PORT}090\"%; 
s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:${NOIS_PORT}091\"%; 
s%^address = \"0.0.0.0:8545\"%address = \"0.0.0.0:${NOIS_PORT}545\"%; 
s%^ws-address = \"0.0.0.0:8546\"%ws-address = \"0.0.0.0:${NOIS_PORT}546\"%" $HOME/.noisd/config/app.toml
~~~

Set gustom ports in config.toml file

~~~bash
sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${NOIS_PORT}658\"%; 
s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://0.0.0.0:${NOIS_PORT}657\"%; 
s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${NOIS_PORT}060\"%;
s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${NOIS_PORT}656\"%;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${NOIS_PORT}656\"%;
s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${NOIS_PORT}660\"%" $HOME/.noisd/config/config.toml
~~~

Update config.toml

~~~bash
CONFIG_DIR="$HOME/.noisd/config"
sed -i 's/^timeout_propose =.*$/timeout_propose = "2000ms"/' $CONFIG_DIR/config.toml \
  && sed -i 's/^timeout_propose_delta =.*$/timeout_propose_delta = "500ms"/' $CONFIG_DIR/config.toml \
  && sed -i 's/^timeout_prevote =.*$/timeout_prevote = "1s"/' $CONFIG_DIR/config.toml \
  && sed -i 's/^timeout_prevote_delta =.*$/timeout_prevote_delta = "500ms"/' $CONFIG_DIR/config.toml \
  && sed -i 's/^timeout_precommit =.*$/timeout_precommit = "1s"/' $CONFIG_DIR/config.toml \
  && sed -i 's/^timeout_precommit_delta =.*$/timeout_precommit_delta = "500ms"/' $CONFIG_DIR/config.toml \
  && sed -i 's/^timeout_commit =.*$/timeout_commit = "1800ms"/' $CONFIG_DIR/config.toml
~~~

Config pruning

~~~bash
sed -i -e "s/^pruning *=.*/pruning = \"nothing\"/" $HOME/.noisd/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.noisd/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.noisd/config/app.toml
~~~

Set minimum gas price, enable prometheus and disable indexing

~~~bash
sed -i 's/minimum-gas-prices =.*/minimum-gas-prices = "0.0unois"/g' $HOME/.noisd/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.noisd/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.noisd/config/config.toml
~~~

Reset chain data
~~~bash
noisd tendermint unsafe-reset-all --home $HOME/.noisd
~~~

Create Service file

~~~bash
sudo tee /etc/systemd/system/noisd.service > /dev/null <<EOF
[Unit]
Description=nois
After=network-online.target

[Service]
User=$USER
ExecStart=$(which noisd) start --home $HOME/.noisd
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
sudo systemctl enable noisd
sudo systemctl restart noisd && sudo journalctl -u noisd -f
~~~

## Create wallet
To create a new wallet, use the following command. don’t forget to save the mnemonic

~~~bash
noisd keys add $WALLET
~~~

(optional) To restore exexuting wallet, use the following command

~~~bash
noisd keys add $WALLET --recover
~~~

Save wallet and validator address

~~~bash
WALLET_ADDRESS=$(noisd keys show $WALLET -a)
VALOPER_ADDRESS=$(noisd keys show $WALLET --bech val -a)
echo "export WALLET_ADDRESS="${WALLET_ADDRESS} >> $HOME/.bash_profile
echo "export VALOPER_ADDRESS="${VALOPER_ADDRESS} >> $HOME/.bash_profile
source $HOME/.bash_profile
~~~

Fund your wallet 
Before creating a validator, you need to fund your wallet, go to the [discord server](https://chat.nois.network/) and  and navigate to `faucet` channel

~~~bash
!faucet <YOUR_WALLET_ADDRESS>
~~~

## (OPTIONAL) State Sync

In order not to wait for a long synchronization, you can use our StateSync guide:
> https://github.com/marutyan/testnet_guides/blob/main/nois/statesync.md


## Create validator

before creating a validator, you need to check the balance and make sure that the node is synched

Check Sync status, once your node is fully synced, the output from above will say `false`

~~~bash
noisd status 2>&1 | jq .SyncInfo
~~~

Check your balance

~~~bash
noisd query bank balances $WALLET_ADDRESS
~~~

Create validator

~~~bash
noisd tx staking create-validator \
  --amount 1000000unois \
  --from $WALLET \
  --commission-max-change-rate "0.01" \
  --commission-max-rate "0.2" \
  --commission-rate "0.05" \
  --min-self-delegation "1" \
  --pubkey  $(noisd tendermint show-validator) \
  --moniker $MONIKER \
  --chain-id $NOIS_CHAIN_ID
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
sudo ufw allow ${NOIS_PORT}656/tcp
sudo ufw enable
~~~

## Usefull commands
### Service commands
check logs

~~~bash
sudo journalctl -u noisd -f
~~~

stop service

~~~bash
sudo systemctl stop noisd
~~~

start service

~~~bash
sudo systemctl start noisd
~~~

restart service

~~~bash
sudo systemctl restart noisd
~~~

### Wallet operation

check balance

~~~bash
noisd query bank balances $WALLET_ADDRESS
~~~

transfer funds

~~~bash
noisd tx bank send $WALLET_ADDRESS <TO_WALLET_ADDRESS> 1000000unois --gas auto --gas-adjustment 1.3
~~~

lists of wallets

~~~bash
noisd keys list
~~~

create a new wallet

~~~bash
noisd keys add $WALLET
~~~

recover wallet

~~~bash
noisd keys add $WALLET --recover
~~~

delete wallet

~~~bash
noisd keys delete $WALLET
~~~

### Node information

synch info

~~~bash
noisd status 2>&1 | jq .SyncInfo
~~~

node status

~~~bash
curl -s localhost:${NOIS_PORT}657/status
~~~

node info

~~~bash
noisd status 2>&1 | jq .NodeInfo
~~~

validator info

~~~bash
noisd status 2>&1 | jq .ValidatorInfo
~~~

your node peers

~~~bash
echo $(noisd tendermint show-node-id)'@'$(curl -s ifconfig.me)':'$(cat $HOME/.noisd/config/config.toml | sed -n '/Address to listen for incoming connection/{n;p;}' | sed 's/.*://; s/".*//')
~~~

get currently conected peers lis

~~~bash
curl -sS http://localhost:${NOIS_PORT}657/net_info | jq -r '.result.peers[] | "\(.node_info.id)@\(.remote_ip):\(.node_info.listen_addr)"' | awk -F ':' '{print $1":"$(NF)}'
~~~

### Voting

~~~bash
noisd tx gov vote 1 yes --from $WALLET --chain-id $NOIS_CHAIN_ID
~~~

### Staking, Delegation and Rewards

Withdraw all rewards

~~~bash
noisd tx distribution withdraw-all-rewards --from $WALLET --chain-id $NOIS_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

Withdraw rewards with commision

~~~bash
noisd tx distribution withdraw-rewards $VALOPER_ADDRESS --from $WALLET --commission --chain-id $NOIS_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

Check balance 

~~~bash
noisd query bank balances $WALLET_ADDRESS
~~~

Delegate stake

~~~bash
noisd tx staking delegate $VALOPER_ADDRESS 1000000unois --from $WALLET --chain-id $NOIS_CHAIN_ID --gas=auto --gas-adjustment 1.3
~~~

Redelegate stake to another validator

~~~bash
noisd tx staking redelegate <srcValidatorAddress> <destValidatorAddress> 1000000unois --from $WALLET --chain-id $NOIS_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

### Validator operation

Edit validator

~~~bash
noisd tx staking edit-validator \
  --moniker=$NODENAME \
  --identity=<your_keybase_id> \
  --website="<your_website>" \
  --details="<your_validator_description>" \
  --chain-id=$NOIS_CHAIN_ID \
  --from=$WALLET
~~~

Validator info

~~~bash
noisd status 2>&1 | jq .ValidatorInfo

~~~

Jailing info

~~~bash
noisd q slashing signing-info $(noisd tendermint show-validator)
~~~

Unjail validator

~~~bash
noisd tx slashing unjail --broadcast-mode=block --from $WALLET --chain-id $NOIS_CHAIN_ID --gas auto --gas-adjustment 1.5
~~~

Consensus state

~~~bash
curl localhost:${NOIS_PORT}657/consensus_state
~~~

### Delete node

~~~bash
sudo systemctl stop noisd
sudo systemctl disable noisd
sudo rm -rf /etc/systemd/system/noisd*
sudo rm $(which noisd)
sudo rm -rf $HOME/.noisd
sudo rm -fr $HOME/full-node
sed -i "/NOIS_/d" $HOME/.bash_profile
~~~

