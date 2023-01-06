<div>
<h1 align="left" style="display: flex;"> Lava Validator node setup for testnet - lava-testnet-1</h1>
<img src="https://docs.lavanet.xyz/img/lava_logo.svg"  style="float: right;" width="100" height="100"></img>
</div>

Official documentation:
>- [Validator setup instructions](https://docs.lavanet.xyz/testnet)

Explorer:
>-  https://testnet.itrocket.net/lava


## Hardware Requirements
### Recommended Hardware Requirements 
 - x64 2.0 GHz 4v CPU
 - 8GB RAM
 - 100GB SSD	

## Set up your Lava node
### Manual installation

Update packages and Install dependencies

~~~bash
sudo apt update && sudo apt upgrade -y
sudo apt install curl git wget htop tmux build-essential jq make lz4 gcc -y
~~~

Replace your moniker `<YOUR_MONIKER>` without `<>`, save and import variables into system

~~~bash
LAVA_PORT=20
echo "export WALLET="wallet"" >> $HOME/.bash_profile
echo "export MONIKER="<YOUR_MONIKER>"" >> $HOME/.bash_profile
echo "export LAVA_CHAIN_ID="lava-testnet-1"" >> $HOME/.bash_profile
echo "export LAVA_PORT="${LAVA_PORT}"" >> $HOME/.bash_profile
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
git clone https://github.com/lavanet/lava.git
cd lava
git checkout 0.4.0
make install
~~~

Check version
~~~bash
lavad version --long | grep -e version
#0.4.0-rc2-e2c69db
~~~

Config and init app

~~~bash
lavad config node tcp://localhost:${LAVA_PORT}657
lavad config keyring-backend test
lavad config chain-id $LAVA_CHAIN_ID
lavad init $MONIKER --chain-id $LAVA_CHAIN_ID
~~~


Download genesis and addrbook

~~~bash
curl https://raw.githubusercontent.com/K433QLtr6RA9ExEq/GHFkqmTzpdNLDd6T/main/testnet-1/genesis_json/genesis.json > ~/.lava/config/genesis.json
curl https://snaps.itrocket.net/testnet/lava/addrbook.json > ~/.lava/config/addrbook.json
~~~

Set seeds and peers

~~~bash
SEEDS="3a445bfdbe2d0c8ee82461633aa3af31bc2b4dc0@prod-pnet-seed-node.lavanet.xyz:26656,e593c7a9ca61f5616119d6beb5bd8ef5dd28d62d@prod-pnet-seed-node2.lavanet.xyz:26656"
PEERS=""
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.lava/config/config.toml
~~~

Set gustom ports in app.toml file

~~~bash
sed -i.bak -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${LAVA_PORT}317\"%;
s%^address = \":8080\"%address = \":${LAVA_PORT}080\"%;
s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:${LAVA_PORT}090\"%; 
s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:${LAVA_PORT}091\"%; 
s%^address = \"0.0.0.0:8545\"%address = \"0.0.0.0:${LAVA_PORT}545\"%; 
s%^ws-address = \"0.0.0.0:8546\"%ws-address = \"0.0.0.0:${LAVA_PORT}546\"%" $HOME/.lava/config/app.toml
~~~

Set gustom ports in config.toml file

~~~bash
sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${LAVA_PORT}658\"%; 
s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://0.0.0.0:${LAVA_PORT}657\"%; 
s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${LAVA_PORT}060\"%;
s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${LAVA_PORT}656\"%;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${LAVA_PORT}656\"%;
s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${LAVA_PORT}660\"%" $HOME/.lava/config/config.toml
~~~

Config pruning

~~~bash
sed -i -e "s/^pruning *=.*/pruning = \"nothing\"/" $HOME/.lava/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.lava/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.lava/config/app.toml
~~~

Set minimum gas price, enable prometheus and disable indexing

~~~bash
sed -i 's/minimum-gas-prices =.*/minimum-gas-prices = "0.0ulava"/g' $HOME/.lava/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.lava/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.lava/config/config.toml
~~~

Reset chain data
~~~bash
lavad tendermint unsafe-reset-all --home $HOME/.lava
~~~

Create Service file

~~~bash
sudo tee /etc/systemd/system/lavad.service > /dev/null <<EOF
[Unit]
Description=lava
After=network-online.target

[Service]
User=$USER
ExecStart=$(which lavad) start --home $HOME/.lava
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
sudo systemctl enable lavad
sudo systemctl restart lavad && sudo journalctl -u lavad -f
~~~

Download ITRocket-team snapshot

~~~bash
cp $HOME/.lava/data/priv_validator_state.json $HOME/.lava/priv_validator_state.json.backup
rm -rf $HOME/.lava/data
curl https://snaps.itrocket.net/testnet/lava/snap_lava.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.lava
mv $HOME/.lava/priv_validator_state.json.backup $HOME/.lava/data/priv_validator_state.json
~~~

Restart Service

~~~bash
sudo systemctl restart lavad && sudo journalctl -u lavad -f
~~~

## Create wallet
To create a new wallet, use the following command. don’t forget to save the mnemonic

~~~bash
lavad keys add $WALLET
~~~

(optional) To restore exexuting wallet, use the following command

~~~bash
lavad keys add $WALLET --recover
~~~

Save wallet and validator address

~~~bash
WALLET_ADDRESS=$(lavad keys show $WALLET -a)
~~~
~~~bash
VALOPER_ADDRESS=$(lavad keys show $WALLET --bech val -a)
~~~
~~~bash
echo "export WALLET_ADDRESS="${WALLET_ADDRESS} >> $HOME/.bash_profile
echo "export VALOPER_ADDRESS="${VALOPER_ADDRESS} >> $HOME/.bash_profile
source $HOME/.bash_profile
~~~

## Faucet
### Fund your wallet
Get your account funded through the faucet:

~~~bash
curl -X POST -d '{"address": "'$WALLET_ADDRESS'", "coins": ["60000000ulava"]}' https://faucet-api.lavanet.xyz/faucet/
~~~

You can fund your wallet on discord channel, go to the [Lava discord server](https://discord.gg/5VcqgwMmkA) and  and navigate to `faucet` channel

~~~bash
$request <YOUR_WALLET_ADDRESS>
~~~

## Create validator

before creating a validator, you need to check the balance and make sure that the node is synched

Check Sync status, once your node is fully synced, the output from above will say `false`

~~~bash
lavad status 2>&1 | jq .SyncInfo
~~~

Check your balance

~~~bash
lavad query bank balances $WALLET_ADDRESS
~~~

Create validator

~~~bash
lavad tx staking create-validator \
  --amount 1000000ulava \
  --from $WALLET \
  --commission-max-change-rate "0.01" \
  --commission-max-rate "0.2" \
  --commission-rate "0.05" \
  --min-self-delegation "1" \
  --pubkey  $(lavad tendermint show-validator) \
  --moniker $MONIKER \
  --chain-id $LAVA_CHAIN_ID
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
sudo ufw allow ${LAVA_PORT}656/tcp
sudo ufw enable
~~~

## Usefull commands
### Service commands
check logs

~~~bash
sudo journalctl -u lavad -f
~~~

stop service

~~~bash
sudo systemctl stop lavad
~~~

start service

~~~bash
sudo systemctl start lavad
~~~

restart service

~~~bash
sudo systemctl restart lavad
~~~

### Wallet operation

check balance

~~~bash
lavad query bank balances $WALLET_ADDRESS
~~~

transfer funds

~~~bash
lavad tx bank send $WALLET_ADDRESS <TO_WALLET_ADDRESS> 1000000ulava --gas auto --gas-adjustment 1.3
~~~

lists of wallets

~~~bash
lavad keys list
~~~

create a new wallet

~~~bash
lavad keys add $WALLET
~~~

recover wallet

~~~bash
lavad keys add $WALLET --recover
~~~

delete wallet

~~~bash
lavad keys delete $WALLET
~~~

### Node information

synch info

~~~bash
lavad status 2>&1 | jq .SyncInfo
~~~

node status

~~~bash
curl -s localhost:${LAVA_PORT}657/status
~~~

node info

~~~bash
lavad status 2>&1 | jq .NodeInfo
~~~

validator info

~~~bash
lavad status 2>&1 | jq .ValidatorInfo
~~~

your node peers

~~~bash
echo $(lavad tendermint show-node-id)'@'$(curl -s ifconfig.me)':'$(cat $HOME/.lava/config/config.toml | sed -n '/Address to listen for incoming connection/{n;p;}' | sed 's/.*://; s/".*//')
~~~

get currently conected peers lis

~~~bash
curl -sS http://localhost:${LAVA_PORT}657/net_info | jq -r '.result.peers[] | "\(.node_info.id)@\(.remote_ip):\(.node_info.listen_addr)"' | awk -F ':' '{print $1":"$(NF)}'
~~~

### Voting

~~~bash
lavad tx gov vote 1 yes --from $WALLET --chain-id $LAVA_CHAIN_ID
~~~

### Staking, Delegation and Rewards

Withdraw all rewards

~~~bash
lavad tx distribution withdraw-all-rewards --from $WALLET --chain-id $LAVA_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

Withdraw rewards with commision

~~~bash
lavad tx distribution withdraw-rewards $VALOPER_ADDRESS --from $WALLET --commission --chain-id $LAVA_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

Check balance 

~~~bash
lavad query bank balances $WALLET_ADDRESS
~~~

Delegate stake

~~~bash
lavad tx staking delegate $VALOPER_ADDRESS 1000000ulava --from $WALLET --chain-id $LAVA_CHAIN_ID --gas=auto --gas-adjustment 1.3
~~~

Redelegate stake to another validator

~~~bash
lavad tx staking redelegate <srcValidatorAddress> <destValidatorAddress> 1000000ulava --from $WALLET --chain-id $LAVA_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

### Validator operation

Edit validator

~~~bash
lavad tx staking edit-validator \
  --moniker=$NODENAME \
  --identity=<your_keybase_id> \
  --website="<your_website>" \
  --details="<your_validator_description>" \
  --chain-id=$LAVA_CHAIN_ID \
  --from=$WALLET
~~~

Validator info

~~~bash
lavad status 2>&1 | jq .ValidatorInfo

~~~

Jailing info

~~~bash
lavad q slashing signing-info $(lavad tendermint show-validator)
~~~

Unjail validator

~~~bash
lavad tx slashing unjail --broadcast-mode=block --from $WALLET --chain-id $LAVA_CHAIN_ID --gas auto --gas-adjustment 1.5
~~~

Consensus state

~~~bash
curl localhost:${LAVA_PORT}657/consensus_state
~~~

### Delete node

~~~bash
sudo systemctl stop lavad
sudo systemctl disable lavad
sudo rm -rf /etc/systemd/system/lavad*
sudo rm $(which lavad)
sudo rm -rf $HOME/.lava
sed -i "/LAVA_/d" $HOME/.bash_profile
~~~

