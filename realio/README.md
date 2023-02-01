<div>
<h1 align="left" style="display: flex;"> Realio Node Setup for Testnet — realionetwork_1110-2</h1>
<img src="https://avatars.githubusercontent.com/u/73153279?s=200&v=4"  style="float: right;" width="100" height="100"></img>
</div>

Official documentation:
>- [Validator setup instructions](https://docs.realio.network/fullnode/setup)

Explorer:
>-  https://testnet.itrocket.net/realio/staking


## Hardware Requirements
### Recommended Hardware Requirements 
 - 4 Cores
 - 8GB RAM
 - 240GB of storage (NVME)

## Set up your sei node
### Manual installation

Update packages and Install dependencies

~~~bash
sudo apt update && sudo apt upgrade -y
sudo apt install curl git wget htop tmux build-essential jq make lz4 gcc -y
~~~

Replace your moniker `<YOUR_MONIKER>` without `<>`, save and import variables into system

~~~bash
REALIO_PORT=23
echo "export WALLET="wallet"" >> $HOME/.bash_profile
echo "export MONIKER="<YOUR_MONIKER>"" >> $HOME/.bash_profile
echo "export REALIO_CHAIN_ID="realionetwork_1110-2"" >> $HOME/.bash_profile
echo "export REALIO_PORT="${REALIO_PORT}"" >> $HOME/.bash_profile
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
rm -rf realio-networ
git clone https://github.com/realiotech/realio-network.git
cd realio-network
git checkout v0.7.2
make install
~~~
Config and init app

~~~bash
realio-networkd config node tcp://localhost:${REALIO_PORT}657
realio-networkd config keyring-backend test
realio-networkd config chain-id $REALIO_CHAIN_ID
realio-networkd init $MONIKER --chain-id $REALIO_CHAIN_ID
~~~

Download genesis and addrbook

~~~bash
curl https://raw.githubusercontent.com/realiotech/testnets/master/realionetwork_1110-2/genesis.json > $HOME/.realio-network/config/genesis.json
~~~

Set seeds and peers

~~~bash
SEEDS="aa194e9f9add331ee8ba15d2c3d8860c5a50713f@143.110.230.177:26656"
PEERS=""
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.realio-network/config/config.toml
~~~

Set gustom ports in app.toml file

~~~bash
sed -i.bak -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${REALIO_PORT}317\"%;
s%^address = \":8080\"%address = \":${REALIO_PORT}080\"%;
s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:${REALIO_PORT}090\"%; 
s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:${REALIO_PORT}091\"%; 
s%^address = \"0.0.0.0:8545\"%address = \"0.0.0.0:${REALIO_PORT}545\"%; 
s%^ws-address = \"0.0.0.0:8546\"%ws-address = \"0.0.0.0:${REALIO_PORT}546\"%" $HOME/.realio-network/config/app.toml
~~~

Set gustom ports in config.toml file

~~~bash
sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${REALIO_PORT}658\"%; 
s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://0.0.0.0:${REALIO_PORT}657\"%; 
s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${REALIO_PORT}060\"%;
s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${REALIO_PORT}656\"%;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${REALIO_PORT}656\"%;
s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${REALIO_PORT}660\"%" $HOME/.realio-network/config/config.toml
~~~

Config pruning

~~~bash
sed -i -e "s/^pruning *=.*/pruning = \"nothing\"/" $HOME/.realio-network/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.realio-network/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"10\"/" $HOME/.realio-network/config/app.toml
~~~

Set minimum gas price, enable prometheus and disable indexing

~~~bash
sed -i 's/minimum-gas-prices =.*/minimum-gas-prices = "0.0ario"/g' $HOME/.realio-network/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.realio-network/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.realio-network/config/config.toml
~~~

Reset chain data
~~~bash
realio-networkd tendermint unsafe-reset-all --home $HOME/.realio-network
~~~

Create Service file

~~~bash
sudo tee /etc/systemd/system/realio-networkd.service > /dev/null <<EOF
[Unit]
Description=realio
After=network-online.target

[Service]
User=$USER
ExecStart=$(which realio-networkd) start --home $HOME/.realio-network
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
sudo systemctl enable realio-networkd
sudo systemctl restart realio-networkd && sudo journalctl -u realio-networkd -f
~~~

## Create wallet
To create a new wallet, use the following command. don’t forget to save the mnemonic

~~~bash
realio-networkd keys add $WALLET
~~~

(optional) To restore exexuting wallet, use the following command

~~~bash
realio-networkd keys add $WALLET --recover
~~~

Save wallet and validator address

~~~bash
WALLET_ADDRESS=$(realio-networkd keys show $WALLET -a)
VALOPER_ADDRESS=$(realio-networkd keys show $WALLET --bech val -a)
echo "export WALLET_ADDRESS="${WALLET_ADDRESS} >> $HOME/.bash_profile
echo "export VALOPER_ADDRESS="${VALOPER_ADDRESS} >> $HOME/.bash_profile
source $HOME/.bash_profile
~~~

Fund your wallet 
Before creating a validator, you need to fund your wallet, go to the [Realio discord server](https://discord.gg/WhRgHEfDF4) and  and navigate to `faucet` channel

~~~bash
!faucet <YOUR_WALLET_ADDRESS>
~~~

## (OPTIONAL) State Sync, Snapshot

In order not to wait for a long synchronization, you can use our StateSync or Snapshot guide:
> https://itrocket.net/services/testnet/realio


## Create validator

before creating a validator, you need to check the balance and make sure that the node is synched

Check Sync status, once your node is fully synced, the output from above will say `false`

~~~bash
realio-networkd status 2>&1 | jq .SyncInfo
~~~

Check your balance

~~~bash
realio-networkd query bank balances $WALLET_ADDRESS
~~~

Create validator

~~~bash
realio-networkd tx staking create-validator \
  --amount 1000000ario \
  --from $WALLET \
  --commission-max-change-rate "0.01" \
  --commission-max-rate "0.2" \
  --commission-rate "0.05" \
  --min-self-delegation "1" \
  --pubkey  $(realio-networkd tendermint show-validator) \
  --moniker $MONIKER \
  --chain-id $REALIO_CHAIN_ID \
  --fees 5000000000000000ario \
  --gas 800000
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
sudo ufw allow ${REALIO_PORT}656/tcp
sudo ufw enable
~~~

## Usefull commands
### Service commands
check logs

~~~bash
sudo journalctl -u realio-networkd -f
~~~

stop service

~~~bash
sudo systemctl stop realio-networkd
~~~

start service

~~~bash
sudo systemctl start realio-networkd
~~~

restart service

~~~bash
sudo systemctl restart realio-networkd
~~~

### Wallet operation

check balance

~~~bash
realio-networkd query bank balances $WALLET_ADDRESS
~~~

transfer funds

~~~bash
realio-networkd tx bank send $WALLET_ADDRESS <TO_WALLET_ADDRESS> 1000000ario --gas auto --gas-adjustment 1.3
~~~

lists of wallets

~~~bash
realio-networkd keys list
~~~

create a new wallet

~~~bash
realio-networkd keys add $WALLET
~~~

recover wallet

~~~bash
realio-networkd keys add $WALLET --recover
~~~

delete wallet

~~~bash
realio-networkd keys delete $WALLET
~~~

### Node information

synch info

~~~bash
realio-networkd status 2>&1 | jq .SyncInfo
~~~

node status

~~~bash
curl -s localhost:${REALIO_PORT}657/status
~~~

node info

~~~bash
realio-networkd status 2>&1 | jq .NodeInfo
~~~

validator info

~~~bash
realio-networkd status 2>&1 | jq .ValidatorInfo
~~~

your node peers

~~~bash
echo $(realio-networkd tendermint show-node-id)'@'$(curl -s ifconfig.me)':'$(cat $HOME/.realio-network/config/config.toml | sed -n '/Address to listen for incoming connection/{n;p;}' | sed 's/.*://; s/".*//')
~~~

get currently conected peers lis

~~~bash
curl -sS http://localhost:${REALIO_PORT}657/net_info | jq -r '.result.peers[] | "\(.node_info.id)@\(.remote_ip):\(.node_info.listen_addr)"' | awk -F ':' '{print $1":"$(NF)}'
~~~

### Voting

~~~bash
realio-networkd tx gov vote 1 yes --from $WALLET --chain-id $REALIO_CHAIN_ID
~~~

### Staking, Delegation and Rewards

Withdraw all rewards

~~~bash
realio-networkd tx distribution withdraw-all-rewards --from $WALLET --chain-id $REALIO_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

Withdraw rewards with commision

~~~bash
realio-networkd tx distribution withdraw-rewards $VALOPER_ADDRESS --from $WALLET --commission --chain-id $REALIO_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

Check balance 

~~~bash
realio-networkd query bank balances $WALLET_ADDRESS
~~~

Delegate stake

~~~bash
realio-networkd tx staking delegate $VALOPER_ADDRESS 1000000ario --from $WALLET --chain-id $REALIO_CHAIN_ID --gas=auto --gas-adjustment 1.3
~~~

Redelegate stake to another validator

~~~bash
realio-networkd tx staking redelegate <srcValidatorAddress> <destValidatorAddress> 1000000ario --from $WALLET --chain-id $REALIO_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

### Validator operation

Edit validator

~~~bash
realio-networkd tx staking edit-validator \
  --moniker=$NODENAME \
  --identity=<your_keybase_id> \
  --website="<your_website>" \
  --details="<your_validator_description>" \
  --chain-id=$REALIO_CHAIN_ID \
  --from=$WALLET \
  --fees 5000000000000000ario \
  --gas 800000
~~~

Validator info

~~~bash
realio-networkd status 2>&1 | jq .ValidatorInfo

~~~

Jailing info

~~~bash
realio-networkd q slashing signing-info $(realio-networkd tendermint show-validator)
~~~

Unjail validator

~~~bash
realio-networkd tx slashing unjail --broadcast-mode=block --from $WALLET --chain-id $REALIO_CHAIN_ID --gas auto --gas-adjustment 1.5
~~~

Consensus state

~~~bash
curl localhost:${REALIO_PORT}657/consensus_state
~~~

### Delete node

~~~bash
sudo systemctl stop realio-networkd
sudo systemctl disable realio-networkd
sudo rm -rf /etc/systemd/system/realio-networkd*
sudo rm $(which realio-networkd)
sudo rm -rf $HOME/.realio-network
sudo rm -fr $HOME/realio-network
sed -i "/REALIO_/d" $HOME/.bash_profile
~~~

