<div>
<h1 align="left" style="display: flex;"> Uptick Node Setup for Testnet — uptick_7000-2</h1>
<img src="https://user-images.githubusercontent.com/79756157/205509209-512319b4-59dc-415d-a1ce-29bdeedc20f7.jpg"  style="float: right;" width="100" height="100"></img>
</div>

Official documentation:
>- [Validator setup instructions](https://docs.uptick.network/testnet/)

Explorer:
>-  https://explorer.testnet.uptick.network/uptick-network-testnet


## Hardware Requirements
### Minimum Hardware Requirements
 - 3x CPUs
 - 4GB RAM
 - 100GB Disk

### Recommended Hardware Requirements 
 - 4x CPUs
 - 8GB RAM
 - 200GB of storage (SSD or NVME)

## Set up your uptick fullnode
### Manual installation

Update packages and Install dependencies

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install curl git wget htop tmux build-essential jq make gcc -y
```

Replace your wallet and moniker `<YOUR_WALLET_NAME>` `<YOUR_MONIKER>` without `<>`, save and import variables into system

```bash
UPTICK_PORT=10
echo "export UPTICK_WALLET="<YOUR_WALLET_NAME>"" >> $HOME/.bash_profile
echo "export UPTICK_MONIKER="<YOUR_MONIKER>"" >> $HOME/.bash_profile
echo "export UPTICK_CHAIN_ID="uptick_7000-2"" >> $HOME/.bash_profile
echo "export UPTICK_PORT="${UPTICK_PORT}"" >> $HOME/.bash_profile
source $HOME/.bash_profile
```

install go

```bash
cd $HOME
VER="1.19.3"
wget "https://golang.org/dl/go$VER.linux-amd64.tar.gz"
sudo tar -C /usr/local -xzf "go$VER.linux-amd64.tar.gz"
rm -rf  "go$VER.linux-amd64.tar.gz"
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile
source $HOME/.bash_profile
go version
```

Download and build binaries

```bash
cd $HOME
rm -rf uptick
git clone https://github.com/UptickNetwork/uptick.git
cd uptick
git checkout v0.2.5
make install
```
Config and init app

```bash
uptickd config node tcp://localhost:${UPTICK_PORT}657
uptickd config chain-id $UPTICK_CHAIN_ID
uptickd init $UPTICK_MONIKER --chain-id $UPTICK_CHAIN_ID
```

Download genesis

```bash
wget -O $HOME/.uptickd/config/genesis.json https://raw.githubusercontent.com/UptickNetwork/uptick-testnet/main/uptick_7000-2/genesis.json
```

Set seeds and peers

```bash
SEEDS=""
PEERS="eecdfb17919e59f36e5ae6cec2c98eeeac05c0f2@peer0.testnet.uptick.network:26656,178727600b61c055d9b594995e845ee9af08aa72@peer1.testnet.uptick.network:26656,f97a75fb69d3a5fe893dca7c8d238ccc0bd66a8f@uptick-seed.p2p.brocha.in:30554,94b63fddfc78230f51aeb7ac34b9fb86bd042a77@uptick-testnet-rpc.p2p.brocha.in:30556,902a93963c96589432ee3206944cdba392ae5c2d@65.108.42.105:27656"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.uptickd/config/config.toml
```

Set gustom ports in app.toml file

```bash
sed -i.bak -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${UPTICK_PORT}317\"%;
s%^address = \":8080\"%address = \":${UPTICK_PORT}080\"%;
s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:${UPTICK_PORT}090\"%; 
s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:${UPTICK_PORT}091\"%; 
s%^address = \"0.0.0.0:8545\"%address = \"0.0.0.0:${UPTICK_PORT}545\"%; 
s%^ws-address = \"0.0.0.0:8546\"%ws-address = \"0.0.0.0:${UPTICK_PORT}546\"%" $HOME/.uptickd/config/app.toml
```

Set gustom ports in config.toml file

```bash
sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${UPTICK_PORT}658\"%; 
s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://0.0.0.0:${UPTICK_PORT}657\"%; 
s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${UPTICK_PORT}060\"%;
s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${UPTICK_PORT}656\"%;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${UPTICK_PORT}656\"%;
s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${UPTICK_PORT}660\"%" $HOME/.uptickd/config/config.toml
```

Config pruning

```bash
sed -i -e "s/^pruning *=.*/pruning = \"nothing\"/" $HOME/.uptickd/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.uptickd/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.uptickd/config/app.toml
```

Set minimum gas price, enable prometheus and disable indexing

```bash
sed -i -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0auptick\"/" $HOME/.uptickd/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.uptickd/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.uptickd/config/config.toml
```

Clean old data

```bash
uptickd tendermint unsafe-reset-all --home $HOME/.uptickd --keep-addr-book
```

Create Service file

```bash
sudo tee /etc/systemd/system/uptickd.service > /dev/null <<EOF
[Unit]
Description=uptick
After=network-online.target

[Service]
User=$USER
ExecStart=$(which uptickd) start --home $HOME/.uptickd
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
```

Enable and start service

```bash
sudo systemctl daemon-reload
sudo systemctl enable uptickd
sudo systemctl restart uptickd && sudo journalctl -u uptickd -f
```

## Snapshot, State Sync (OPTIONAL)
In order not to wait for a long synchronization, you can use our guides:

>https://itrocket.net/services/testnet/uptick/#snap  
>https://itrocket.net/services/testnet/uptick/#sync

## Create wallet
To create a new wallet, use the following command. don’t forget to save the mnemonic

```bash
uptickd keys add $UPTICK_WALLET
```

(optional) To restore exexuting wallet, use the following command

```bash
uptickd keys add $UPTICK_WALLET --recover
```

Fund your wallet 
Before creating a validator, you need to fund your wallet, go to the [Sei discord server](https://discord.gg/sei) and  and navigate to faucet channel

```bash
$faucet <YOUR_WALLET_ADDRESS>
```

Save wallet and validator address

```bash
UPTICK_WALLET_ADDRESS=$(uptickd keys show $UPTICK_WALLET -a)
UPTICK_VALOPER_ADDRESS=$(uptickd keys show $UPTICK_WALLET --bech val -a)
echo "export UPTICK_WALLET_ADDRESS="${UPTICK_WALLET_ADDRESS} >> $HOME/.bash_profile
echo "export UPTICK_VALOPER_ADDRESS="${UPTICK_VALOPER_ADDRESS} >> $HOME/.bash_profile
source $HOME/.bash_profile
```

## (OPTIONAL) State Sync

In order not to wait for a long synchronization, you can use our StateSync guide

Stop the service 

```bash
sudo systemctl stop uptickd
```

Configure

```bash
cd $HOME peers="86f50af23369997882ca3988eabeba998b4f07cc@65.109.92.79:10656" 
config=$HOME/.uptickd/config/config.toml 
SNAP_RPC=65.109.92.79:10657
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" $config 
sed -i.bak -e "s/^snapshot-interval *=.*/snapshot-interval = \"2000\"/" $HOME/.uptickd/config/app.toml 
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \ 
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \ 
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash) 
```

Сheck is the state sync information available

```bash
echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH
```

Configure the state sync
```bash
sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"| ; \
s|^(seeds[[:space:]]+=[[:space:]]+).*$|\1\"\"|" $config
```

Clean old data

```bash
uptickd tendermint unsafe-reset-all --home $HOME/.uptickd --keep-addr-book
```
Restart the service and check the log

```bash
sudo systemctl restart uptickd && sudo journalctl -u uptickd -f
```

## Create validator

before creating a validator, you need to check the balance and make sure that the node is synched

Check Sync status, once your node is fully synced, the output from above will say `false`

```bash
uptickd status 2>&1 | jq .SyncInfo
```

Check your balance

```bash
uptickd query bank balances $UPTICK_WALLET_ADDRESS
```

Create validator

```bash
uptickd tx staking create-validator \
  --amount 5000000000000000000auptick \
  --from $UPTICK_WALLET \
  --commission-max-change-rate "0.01" \
  --commission-max-rate "0.2" \
  --commission-rate "0.05" \
  --min-self-delegation "1" \
  --pubkey  $(uptickd tendermint show-validator) \
  --moniker $UPTICK_MONIKER \
  --chain-id $UPTICK_CHAIN_ID \
  --gas=auto
```
  
You can add `--website` `--security-contact` `--identity` `--details` flags in it needed

```bash
--website <YOUR_SITE_URL> \
--security-contact <YOUR_CONTACT> \
--identity <KEYBASE_IDENTITY> \
--details <YOUR_VALIDATOR_DETAILS>
```

### Monitoring
If you want to have set up a monitoring and alert system use [our cosmos nodes monitoring guide with tenderduty](https://teletype.in/@itrocket/bdJAHvC_q8h)
  
### Security
To protect you keys please don`t share your privkey, mnemonic and follow a basic security rules

### Set up ssh keys for authentication
You can use this [guide](https://www.digitalocean.com/community/tutorials/how-to-set-up-ssh-keys-on-ubuntu-20-04) to configure ssh authentication and disable password authentication on your server

### Firewall security
Set the default to allow outgoing connections, deny all incoming, allow ssh and node p2p port

```bash
sudo ufw default allow outgoing 
sudo ufw default deny incoming 
sudo ufw allow ssh/tcp 
sudo ufw allow ${UPTICK_PORT}656/tcp
sudo ufw enable
```

## Usefull commands
### Service commands
check logs

```bash
sudo journalctl -u uptickd -f
```

stop service

```bash
sudo systemctl stop uptickd
```

start service

```bash
sudo systemctl start uptickd
```

restart service

```bash
sudo systemctl restart uptickd
```

### Wallet operation

check balance

```bash
uptickd query bank balances $UPTICK_WALLET_ADDRESS
```

transfer funds

```bash
uptickd tx bank send $UPTICK_WALLET_ADDRESS <TO_UPTICK_WALLET_ADDRESS> 1000000000000000000auptick --gas auto --gas-adjustment 1.3
```

lists of wallets

```bash
uptickd keys list
```

create a new wallet

```bash
uptickd keys add $UPTICK_WALLET
```

recover wallet

```bash
uptickd keys add $UPTICK_WALLET --recover
```

delete wallet

```bash
uptickd keys delete $UPTICK_WALLET
```

### Node information

synch info

```bash
uptickd status 2>&1 | jq .SyncInfo
```

node status

```bash
curl -s localhost:${UPTICK_PORT}657/status
```

node info

```bash
uptickd status 2>&1 | jq .NodeInfo
```

validator info

```bash
uptickd status 2>&1 | jq .ValidatorInfo
```

your node peers

```bash
echo $(uptickd tendermint show-node-id)'@'$(curl -s ifconfig.me)':'$(cat $HOME/.uptickd/config/config.toml | sed -n '/Address to listen for incoming connection/{n;p;}' | sed 's/.*://; s/".*//')
```

get currently conected peers lis

```bash
curl -sS http://localhost:${UPTICK_PORT}657/net_info | jq -r '.result.peers[] | "\(.node_info.id)@\(.remote_ip):\(.node_info.listen_addr)"' | awk -F ':' '{print $1":"$(NF)}'
```

### Voting

```bash
uptickd tx gov vote 1 yes --from $UPTICK_WALLET --chain-id $UPTICK_CHAIN_ID
```

### Staking, Delegation and Rewards

Withdraw all rewards

```bash
uptickd tx distribution withdraw-all-rewards --from $UPTICK_WALLET --chain-id $UPTICK_CHAIN_ID --gas auto --gas-adjustment 1.3
```

Withdraw rewards with commision

```bash
uptickd tx distribution withdraw-rewards $UPTICK_VALOPER_ADDRESS --from $UPTICK_WALLET --commission --chain-id $UPTICK_CHAIN_ID --gas auto --gas-adjustment 1.3
```

Check balance 

```bash
uptickd query bank balances $UPTICK_WALLET_ADDRESS
```

Delegate stake

```bash
uptickd tx staking delegate $UPTICK_VALOPER_ADDRESS 5000000000000000000auptick --from $UPTICK_WALLET --chain-id $UPTICK_CHAIN_ID --gas=auto --gas-adjustment 1.3
```

Redelegate stake to another validator

```bash
uptickd tx staking redelegate <srcValidatorAddress> <destValidatorAddress> 5000000000000000000auptick --from $UPTICK_WALLET --chain-id $UPTICK_CHAIN_ID --gas auto --gas-adjustment 1.3
```

### Validator operation

Edit validator

```bash
uptickd tx staking edit-validator \
  --moniker=$NODENAME \
  --identity=<your_keybase_id> \
  --website="<your_website>" \
  --details="<your_validator_description>" \
  --chain-id=$UPTICK_CHAIN_ID \
  --from=$UPTICK_WALLET
```

Validator info

```bash
uptickd status 2>&1 | jq .ValidatorInfo

```

Jailing info

```bash
uptickd q slashing signing-info $(uptickd tendermint show-validator)
```

Unjail validator

```bash
uptickd tx slashing unjail --broadcast-mode=block --from $UPTICK_WALLET --chain-id $UPTICK_CHAIN_ID --gas auto --gas-adjustment 1.5
```

Consensus state

```bash
curl localhost:${UPTICK_PORT}657/consensus_state
```

### Delete node

```bash
sudo systemctl stop uptickd
sudo systemctl disable uptickd
sudo rm -rf /etc/systemd/system/uptick*
sudo rm $(which uptickd)
sudo rm -rf $HOME/.uptickd
sudo rm -fr $HOME/uptick
sed -i "/UPTICK_/d" $HOME/.bash_profile
```

