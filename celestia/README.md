<div>
<h1 align="left" style="display: flex;"> Celestia Node Setup for Testnet — mocha-4</h1>
<img src="https://avatars.githubusercontent.com/u/54859940?s=200&v=4"  style="float: right;" width="100" height="100"></img>
</div>

Official documentation:
>- [Validator setup instructions](https://docs.celestia.org/nodes/overview/)

Explorer:
>-  https://celestia.explorers.guru/

- [Set up Validator node](https://github.com/marutyan/testnet_guides/tree/main/celestia)  
- [Set up Bridge node](https://github.com/marutyan/testnet_guides/blob/main/celestia/bridge.md)  
- [Set up Light node](https://github.com/marutyan/testnet_guides/blob/main/celestia/light.md)  
- [Set up Full node](https://github.com/marutyan/testnet_guides/blob/main/celestia/full.md) 

 You can run Validator and Bridge Node on the same machine
>1. [Set up Validator node](https://github.com/marutyan/testnet_guides/tree/main/celestia)
>2. [Set up Bridge node on the same machine](https://github.com/marutyan/testnet_guides/blob/main/celestia/bridge.md) 

## Set up a Celestia Validator node
### Hardware Requirements
 - Memory: 8 GB RAM
 - CPU: Quad-Core
 - Disk: 250 GB SSD Storage
 - Bandwidth: 1 Gbps for Download/100 Mbps for Upload
  
### Manual installation

Update packages and Install dependencies

~~~bash
sudo apt update && sudo apt upgrade -y
sudo apt install curl git wget htop tmux build-essential jq make gcc -y
~~~

Replace your wallet and moniker `<YOUR_WALLET_NAME>` `<YOUR_MONIKER>` without `<>`, save and import variables into system
>

```bash
CELESTIA_PORT=11
echo "export CELESTIA_WALLET="<YOUR_WALLET_NAME>"" >> $HOME/.bash_profile
echo "export CELESTIA_MONIKER="<YOUR_MONIKER>"" >> $HOME/.bash_profile
echo "export CELESTIA_CHAIN_ID="mocha-4"" >> $HOME/.bash_profile
echo "export CELESTIA_PORT="${CELESTIA_PORT}"" >> $HOME/.bash_profile
source $HOME/.bash_profile
```

install go

```bash
cd $HOME
VER="1.21.1"
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
rm -rf celestia-app
rm $HOME/.celestia-app/config/genesis.json
git clone https://github.com/celestiaorg/celestia-app.git
cd celestia-app/
APP_VERSION=v1.0.0-rc14
git checkout tags/$APP_VERSION -b $APP_VERSION
make install
```
Setup the P2P networks

```bash
cd $HOME
rm -rf networks
git clone https://github.com/celestiaorg/networks.git
```

Config and init app

```bash
celestia-appd config node tcp://localhost:${CELESTIA_PORT}657
celestia-appd config chain-id $CELESTIA_CHAIN_ID
celestia-appd init $CELESTIA_MONIKER --chain-id $CELESTIA_CHAIN_ID
```

Download genesis

```bash
cp $HOME/networks/mocha-4/genesis.json $HOME/.celestia-app/config
```

Set seeds and peers

```bash
SEEDS="5d0bf034d6e6a8b5ee31a2f42f753f1107b3a00e@celestia-testnet-seed.itrocket.net:11656"
PEERS="daf2cecee2bd7f1b3bf94839f993f807c6b15fbf@celestia-testnet-peer.itrocket.net:11656"
sed -i -e 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.celestia-app/config/config.toml
```

Set gustom ports in app.toml file

```bash
sed -i.bak -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${CELESTIA_PORT}317\"%;
s%^address = \":8080\"%address = \":${CELESTIA_PORT}080\"%;
s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:${CELESTIA_PORT}090\"%; 
s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:${CELESTIA_PORT}091\"%; 
s%^address = \"0.0.0.0:8545\"%address = \"0.0.0.0:${CELESTIA_PORT}545\"%; 
s%^ws-address = \"0.0.0.0:8546\"%ws-address = \"0.0.0.0:${CELESTIA_PORT}546\"%" $HOME/.celestia-app/config/app.toml
```

Set gustom ports in config.toml file

```bash
sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${CELESTIA_PORT}658\"%; 
s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://0.0.0.0:${CELESTIA_PORT}657\"%; 
s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${CELESTIA_PORT}060\"%;
s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${CELESTIA_PORT}656\"%;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${CELESTIA_PORT}656\"%;
s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${CELESTIA_PORT}660\"%" $HOME/.celestia-app/config/config.toml
```

Configure validator mode
```bash
sed -i.bak -e "s/^mode *=.*/mode = \"validator\"/" $HOME/.celestia-app/config/config.toml
sed -i -e "s|^target_height_duration *=.*|timeout_commit = \"11s\"|" $HOME/.celestia-app/config/config.toml
```

Config pruning

```bash
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.celestia-app/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.celestia-app/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"10\"/" $HOME/.celestia-app/config/app.toml
```

Set minimum gas price, enable prometheus and disable indexing

```bash
sed -i -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0utia\"/" $HOME/.celestia-app/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.celestia-app/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.celestia-app/config/config.toml
```

Clean old data

```bash
celestia-appd tendermint unsafe-reset-all --home $HOME/.celestia-app --keep-addr-book
```

Create Service file

```bash
sudo tee /etc/systemd/system/celestia-appd.service > /dev/null <<EOF
[Unit]
Description=celestia
After=network-online.target

[Service]
User=$USER
ExecStart=$(which celestia-appd) start --home $HOME/.celestia-app/
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
sudo systemctl enable celestia-appd
sudo systemctl restart celestia-appd && sudo journalctl -u celestia-appd -f
```

## Create wallet
### 2 new flags should be added in the new Mocha testnet 
>`--evm-address` This flag should contain a 0x EVM address.  
>`--orchestrator-address` This flag should contain a newly-generated celestia1 Celestia address  
 
To create a new Ethereum  wallet, use the following guide
>Visit https://metamask.io/ and locate the extension that is compatible with your browser. 
Click and install the appropriate extension.
Once downloaded and installed, click on the extension icon and follow the prompts to create and confirm your password.  
Next, accept the term of use and give the extension the go-ahead to reveal your seed phrase. It is advisable to store multiple copies of these secret words in secure locations. Once you have backed up your seed phrase, the account registration process is complete.  
To view your ETH or ERC-20 address, navigate and select the Deposit Ether Directly tab. Then click on View Account to see and copy your ERC-20 address.

To create a new Celestia wallets, use the following command. don’t forget to save the mnemonic. 
### You need 2 Celestia addresses 

1 - `$CELESTIA_WALLET` - Validator wallet addresss 

```bash
celestia-appd keys add $CELESTIA_WALLET
``` 

2 -  `CELESTIA_WALLET_1` - Orchestrator-address

~~~bash
celestia-appd keys add ${CELESTIA_WALLET}_1
~~~

(optional) Recover wallet from mamaki, use the following command

```bash
celestia-appd keys add $CELESTIA_WALLET --recover
```

Fund your wallet 
Before creating a validator, you need to fund your wallet, go to the [Celestia discord server](https://discord.gg/celestiacommunity) and  and navigate to mocha-faucet channel. `please fund your orchestrator address too, if you want to run Celestia bridge, Full or Light node`
 
```bash
$request <YOUR_WALLET_ADDRESS>
```

Save wallets and validator addresses
>Replace your ERC-20 address `PUT_YOUR_ERC20_ADDRESS>` without `<>`

```bash
ERC20_ADDRESS="<PUT_YOUR_ERC20_ADDRESS>"
CELESTIA_WALLET_ADDRESS=$(celestia-appd keys show $CELESTIA_WALLET -a)
CELESTIA_VALOPER_ADDRESS=$(celestia-appd keys show $CELESTIA_WALLET --bech val -a)
ORCHESTRATOR_ADDRESS=$(celestia-appd keys show ${CELESTIA_WALLET}_1 -a)
echo "export CELESTIA_WALLET_ADDRESS="${CELESTIA_WALLET_ADDRESS} >> $HOME/.bash_profile
echo "export CELESTIA_ORCHESTRATOR_ADDRESS="${ORCHESTRATOR_ADDRESS} >> $HOME/.bash_profile
echo "export CELESTIA_VALOPER_ADDRESS="${CELESTIA_VALOPER_ADDRESS} >> $HOME/.bash_profile
echo "export EVM_ADDRESS=""$ERC20_ADDRESS" >> $HOME/.bash_profile
source $HOME/.bash_profile
```

## Create validator

before creating a validator, you need to check the balance and make sure that the node is synched

Check Sync status, once your node is fully synced, the output from above will say `false`

```bash
celestia-appd status 2>&1 | jq .SyncInfo
```

Check your balance

```bash
celestia-appd query bank balances $CELESTIA_WALLET_ADDRESS
```

Create validator

```bash
celestia-appd tx staking create-validator \
  --amount 1000000utia \
  --from $CELESTIA_WALLET \
  --commission-max-change-rate "0.01" \
  --commission-max-rate "0.2" \
  --commission-rate "0.05" \
  --min-self-delegation "1" \
  --pubkey  $(celestia-appd tendermint show-validator) \
  --moniker $CELESTIA_MONIKER \
  --chain-id $CELESTIA_CHAIN_ID \
  --evm-address $EVM_ADDRESS \
  --orchestrator-address $CELESTIA_ORCHESTRATOR_ADDRESS \
  --gas=auto \
  --gas-adjustment=1.5 \
  --fees=1000utia \
  -y
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
sudo ufw allow ${CELESTIA_PORT}656/tcp
sudo ufw enable
```

## Usefull commands
### Service commands
check logs

```bash
sudo journalctl -u celestia-appd -f
```

stop service

```bash
sudo systemctl stop celestia-appd
```

start service

```bash
sudo systemctl start celestia-appd
```

restart service

```bash
sudo systemctl restart celestia-appd
```

### Wallet operation

check balance

```bash
celestia-appd query bank balances $CELESTIA_WALLET_ADDRESS
```

transfer funds

```bash
celestia-appd tx bank send $CELESTIA_WALLET_ADDRESS <TO_CELESTIA_WALLET_ADDRESS> 1000000000000000000utia --gas auto --gas-adjustment 1.3
```

lists of wallets

```bash
celestia-appd keys list
```

create a new wallet

```bash
celestia-appd keys add $CELESTIA_WALLET
```

recover wallet

```bash
celestia-appd keys add $CELESTIA_WALLET --recover
```

delete wallet

```bash
celestia-appd keys delete $CELESTIA_WALLET
```

### Node information

synch info

```bash
celestia-appd status 2>&1 | jq .SyncInfo
```

node status

```bash
curl -s localhost:${CELESTIA_PORT}657/status
```

node info

```bash
celestia-appd status 2>&1 | jq .NodeInfo
```

validator info

```bash
celestia-appd status 2>&1 | jq .ValidatorInfo
```

your node peers

```bash
echo $(celestia-appd tendermint show-node-id)'@'$(curl -s ifconfig.me)':'$(cat $HOME/.celestia-app/config/config.toml | sed -n '/Address to listen for incoming connection/{n;p;}' | sed 's/.*://; s/".*//')
```

get currently conected peers lis

```bash
curl -sS http://localhost:${CELESTIA_PORT}657/net_info | jq -r '.result.peers[] | "\(.node_info.id)@\(.remote_ip):\(.node_info.listen_addr)"' | awk -F ':' '{print $1":"$(NF)}'
```

### Voting

```bash
celestia-appd tx gov vote 1 yes --from $CELESTIA_WALLET --chain-id $CELESTIA_CHAIN_ID
```

### Staking, Delegation and Rewards

Withdraw all rewards

```bash
celestia-appd tx distribution withdraw-all-rewards --from $CELESTIA_WALLET --chain-id $CELESTIA_CHAIN_ID --gas auto --gas-adjustment 1.3
```

Withdraw rewards with commision

```bash
celestia-appd tx distribution withdraw-rewards $CELESTIA_VALOPER_ADDRESS --from $CELESTIA_WALLET --commission --chain-id $CELESTIA_CHAIN_ID --gas auto --gas-adjustment 1.3
```

Check balance 

```bash
celestia-appd query bank balances $CELESTIA_WALLET_ADDRESS
```

Delegate stake

```bash
celestia-appd tx staking delegate $CELESTIA_VALOPER_ADDRESS 10000000utia --from $CELESTIA_WALLET --chain-id $CELESTIA_CHAIN_ID --gas=auto --gas-adjustment 1.3
```

Redelegate stake to another validator

```bash
celestia-appd tx staking redelegate <srcValidatorAddress> <destValidatorAddress> 1000000utia --from $CELESTIA_WALLET --chain-id $CELESTIA_CHAIN_ID --gas auto --gas-adjustment 1.3
```

### Validator operation

Edit validator

```bash
celestia-appd tx staking edit-validator \
  --moniker=$NODENAME \
  --identity=<your_keybase_id> \
  --website="<your_website>" \
  --details="<your_validator_description>" \
  --chain-id=$CELESTIA_CHAIN_ID \
  --from=$CELESTIA_WALLET
```

Validator info

```bash
celestia-appd status 2>&1 | jq .ValidatorInfo

```

Jailing info

```bash
celestia-appd q slashing signing-info $(celestia-appd tendermint show-validator)
```

Unjail validator

```bash
celestia-appd tx slashing unjail --broadcast-mode=block --from $CELESTIA_WALLET --chain-id $CELESTIA_CHAIN_ID --gas auto --gas-adjustment 1.5
```

Consensus state

```bash
curl localhost:${CELESTIA_PORT}657/consensus_state
```

### Delete node

```bash
sudo systemctl stop celestia-appd
sudo systemctl disable celestia-appd
sudo rm -rf /etc/systemd/system/celestia-appd*
sudo systemctl daemon-reload
sudo rm $(which celestia-appd)
sudo rm -rf $HOME/.celestia-app
sudo rm -fr $HOME/celestia-app
sed -i "/CELESTIA_/d" $HOME/.bash_profile
```

