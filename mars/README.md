<div>
<h1 align="left" style="display: flex;"> Mars Validator Node Setup for Testnet — ares-1</h1>
<img src="https://avatars.githubusercontent.com/u/82292512?s=200&v=4"  style="float: right;" width="100" height="100"></img>
</div>

Official documentation:
>- [Validator setup instructions](https://validatordocs.marsprotocol.io/TfYZfjcaUzFmiAkWDf7P/infrastructure/validators)

Explorer:
>-  https://mars.explorers.guru/validators


## Hardware Requirements
### Recommended Hardware Requirements 
 - 8-core x86 CPU
 - 32GB RAM
 - 2TB of storage (NVME)

## Set up your mars node
### Manual installation

Update packages and Install dependencies

~~~bash
sudo apt update && sudo apt upgrade -y
sudo apt install curl git wget htop tmux build-essential jq make lz4 gcc -y
~~~

Replace your moniker `<YOUR_MONIKER>` without `<>`, save and import variables into system

~~~bash
MARS_PORT=22
echo "export WALLET="wallet"" >> $HOME/.bash_profile
echo "export MONIKER="<YOUR_MONIKER>"" >> $HOME/.bash_profile
echo "export MARS_CHAIN_ID="ares-1"" >> $HOME/.bash_profile
echo "export MARS_PORT="${MARS_PORT}"" >> $HOME/.bash_profile
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
rm -rf hub
git clone https://github.com/mars-protocol/hub.git
cd hub
git checkout v1.0.0-rc7
make install
~~~
Config and init app

~~~bash
marsd config node tcp://localhost:${MARS_PORT}657
marsd config keyring-backend test
marsd config chain-id $MARS_CHAIN_ID
marsd init $MONIKER --chain-id $MARS_CHAIN_ID
~~~

Download genesis and addrbook

~~~bash
wget -O $HOME/.mars/config/addrbook.json "https://raw.githubusercontent.com/elangrr/testnet_guide/main/mars/addrbook.json"
wget -O $HOME/.mars/config/genesis.json "https://raw.githubusercontent.com/elangrr/testnet_guide/main/mars/genesis.json"
~~~

Set seeds and peers

~~~bash
SEEDS="a841d3e526089172867a73b709fd14e1d9fb87bd@mars-testnet-seed.itrocket.net:443"
PEERS="56ff8e129a481f186e4ac066f3a38bac179bd8e2@mars-testnet-peer.itrocket.net:443,14ba3b19424301a6bb58c27663a0323a81866d5d@134.122.82.186:26656,6c855909a8bf1c12ef34baca059f5c0cdf82bc36@65.108.255.124:36656,9847d03c789d9c87e84611ebc3d6df0e6123c0cc@91.194.30.203:10656,cec7501f438e2700573cdd9d45e7fb5116ba74b9@176.9.51.55:10256,e12bc490096d1b5f4026980f05a118c82e81df2a@85.17.6.142:26656,7342199e80976b052d8506cc5a56d1f9a1cbb486@65.21.89.54:26653,7226c00dd90cf182ca9ec9aa513f518965e7e1a4@167.235.7.34:43656,846ee4df536ddba9739d3f5eebd0139b0a9e5169@159.148.146.132:27225,719cf7e8f7640a48c782599475d4866b401f2d34@51.254.197.170:26656,fe8d614aa5899a97c11d0601ef50c3e7ce17d57b@65.108.233.109:18556"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.mars/config/config.toml
~~~

Set gustom ports in app.toml file

~~~bash
sed -i.bak -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${MARS_PORT}317\"%;
s%^address = \":8080\"%address = \":${MARS_PORT}080\"%;
s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:${MARS_PORT}090\"%; 
s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:${MARS_PORT}091\"%; 
s%^address = \"0.0.0.0:8545\"%address = \"0.0.0.0:${MARS_PORT}545\"%; 
s%^ws-address = \"0.0.0.0:8546\"%ws-address = \"0.0.0.0:${MARS_PORT}546\"%" $HOME/.mars/config/app.toml
~~~

Set gustom ports in config.toml file

~~~bash
sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${MARS_PORT}658\"%; 
s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://0.0.0.0:${MARS_PORT}657\"%; 
s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${MARS_PORT}060\"%;
s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${MARS_PORT}656\"%;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${MARS_PORT}656\"%;
s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${MARS_PORT}660\"%" $HOME/.mars/config/config.toml
~~~

Config pruning

~~~bash
sed -i -e "s/^pruning *=.*/pruning = \"nothing\"/" $HOME/.mars/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.mars/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.mars/config/app.toml
~~~

Set minimum gas price, enable prometheus and disable indexing

~~~bash
sed -i 's/minimum-gas-prices =.*/minimum-gas-prices = "0.0umars"/g' $HOME/.mars/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.mars/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.mars/config/config.toml
~~~

Reset chain data
~~~bash
marsd tendermint unsafe-reset-all --home $HOME/.mars
~~~

Create Service file

~~~bash
sudo tee /etc/systemd/system/marsd.service > /dev/null <<EOF
[Unit]
Description=mars
After=network-online.target

[Service]
User=$USER
ExecStart=$(which marsd) start --home $HOME/.mars
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
sudo systemctl enable marsd
sudo systemctl restart marsd && sudo journalctl -u marsd -f
~~~

## Create wallet
To create a new wallet, use the following command. don’t forget to save the mnemonic

~~~bash
marsd keys add $WALLET
~~~

(optional) To restore exexuting wallet, use the following command

~~~bash
marsd keys add $WALLET --recover
~~~

Save wallet and validator address

~~~bash
WALLET_ADDRESS=$(marsd keys show $WALLET -a)
VALOPER_ADDRESS=$(marsd keys show $WALLET --bech val -a)
echo "export WALLET_ADDRESS="${WALLET_ADDRESS} >> $HOME/.bash_profile
echo "export VALOPER_ADDRESS="${VALOPER_ADDRESS} >> $HOME/.bash_profile
source $HOME/.bash_profile
~~~

Fund your wallet 
Before creating a validator, you need to fund your wallet, https://faucet.marsprotocol.io/

## (OPTIONAL) State Sync

In order not to wait for a long synchronization, you can use our StateSync guide:
> https://github.com/marutyan/testnet_guides/blob/main/mars/statesync.md


## Create validator

before creating a validator, you need to check the balance and make sure that the node is synched

Check Sync status, once your node is fully synced, the output from above will say `false`

~~~bash
marsd status 2>&1 | jq .SyncInfo
~~~

Check your balance

~~~bash
marsd query bank balances $WALLET_ADDRESS
~~~

Create validator

~~~bash
marsd tx staking create-validator \
  --amount 1000000umars \
  --from $WALLET \
  --commission-max-change-rate "0.01" \
  --commission-max-rate "0.2" \
  --commission-rate "0.05" \
  --min-self-delegation "1" \
  --pubkey  $(marsd tendermint show-validator) \
  --moniker $MONIKER \
  --chain-id $MARS_CHAIN_ID
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
sudo ufw allow ${MARS_PORT}656/tcp
sudo ufw enable
~~~

## Usefull commands
### Service commands
check logs

~~~bash
sudo journalctl -u marsd -f
~~~

stop service

~~~bash
sudo systemctl stop marsd
~~~

start service

~~~bash
sudo systemctl start marsd
~~~

restart service

~~~bash
sudo systemctl restart marsd
~~~

### Wallet operation

check balance

~~~bash
marsd query bank balances $WALLET_ADDRESS
~~~

transfer funds

~~~bash
marsd tx bank send $WALLET_ADDRESS <TO_WALLET_ADDRESS> 1000000umars --gas auto --gas-adjustment 1.3
~~~

lists of wallets

~~~bash
marsd keys list
~~~

create a new wallet

~~~bash
marsd keys add $WALLET
~~~

recover wallet

~~~bash
marsd keys add $WALLET --recover
~~~

delete wallet

~~~bash
marsd keys delete $WALLET
~~~

### Node information

synch info

~~~bash
marsd status 2>&1 | jq .SyncInfo
~~~

node status

~~~bash
curl -s localhost:${MARS_PORT}657/status
~~~

node info

~~~bash
marsd status 2>&1 | jq .NodeInfo
~~~

validator info

~~~bash
marsd status 2>&1 | jq .ValidatorInfo
~~~

your node peers

~~~bash
echo $(marsd tendermint show-node-id)'@'$(curl -s ifconfig.me)':'$(cat $HOME/.mars/config/config.toml | sed -n '/Address to listen for incoming connection/{n;p;}' | sed 's/.*://; s/".*//')
~~~

get currently conected peers lis

~~~bash
curl -sS http://localhost:${MARS_PORT}657/net_info | jq -r '.result.peers[] | "\(.node_info.id)@\(.remote_ip):\(.node_info.listen_addr)"' | awk -F ':' '{print $1":"$(NF)}'
~~~

### Voting

~~~bash
marsd tx gov vote 1 yes --from $WALLET --chain-id $MARS_CHAIN_ID
~~~

### Staking, Delegation and Rewards

Withdraw all rewards

~~~bash
marsd tx distribution withdraw-all-rewards --from $WALLET --chain-id $MARS_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

Withdraw rewards with commision

~~~bash
marsd tx distribution withdraw-rewards $VALOPER_ADDRESS --from $WALLET --commission --chain-id $MARS_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

Check balance 

~~~bash
marsd query bank balances $WALLET_ADDRESS
~~~

Delegate stake

~~~bash
marsd tx staking delegate $VALOPER_ADDRESS 1000000umars --from $WALLET --chain-id $MARS_CHAIN_ID --gas=auto --gas-adjustment 1.3
~~~

Redelegate stake to another validator

~~~bash
marsd tx staking redelegate <srcValidatorAddress> <destValidatorAddress> 1000000umars --from $WALLET --chain-id $MARS_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

### Validator operation

Edit validator

~~~bash
marsd tx staking edit-validator \
  --moniker=$NODENAME \
  --identity=<your_keybase_id> \
  --website="<your_website>" \
  --details="<your_validator_description>" \
  --chain-id=$MARS_CHAIN_ID \
  --from=$WALLET
~~~

Validator info

~~~bash
marsd status 2>&1 | jq .ValidatorInfo

~~~

Jailing info

~~~bash
marsd q slashing signing-info $(marsd tendermint show-validator)
~~~

Unjail validator

~~~bash
marsd tx slashing unjail --broadcast-mode=block --from $WALLET --chain-id $MARS_CHAIN_ID --gas auto --gas-adjustment 1.5
~~~

Consensus state

~~~bash
curl localhost:${MARS_PORT}657/consensus_state
~~~

### Delete node

~~~bash
sudo systemctl stop marsd
sudo systemctl disable marsd
sudo rm -rf /etc/systemd/system/marsd*
sudo rm $(which marsd)
sudo rm -rf $HOME/.mars
sudo rm -fr $HOME/hub
sed -i "/MARS_/d" $HOME/.bash_profile
~~~

