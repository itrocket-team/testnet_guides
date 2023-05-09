<div>
<h1 align="left" style="display: flex;"> Celestia Node Setup for Testnet — blockspacerace-0</h1>
<img src="https://avatars.githubusercontent.com/u/54859940?s=200&v=4"  style="float: right;" width="100" height="100"></img>
</div>

Official documentation: [Validator setup instructions](https://docs.celestia.org/nodes/blockspace-race/)

Explorer:
>-  https://testnet.itrocket.net/celestia/staking

- [Set up Validator node](https://github.com/itrocket-team/testnet_guides/blob/main/celestia/BlockspaceRace/README.md)
- [Set up Bridge node](https://github.com/itrocket-team/testnet_guides/blob/main/celestia/BlockspaceRace/bridge.md)  
- [Set up Light node](https://github.com/itrocket-team/testnet_guides/blob/main/celestia/BlockspaceRace/light.md)  
- [Set up Full node](https://github.com/itrocket-team/testnet_guides/blob/main/celestia/BlockspaceRace/full.md)
  
### Validator node Manual installation

Update packages and Install dependencies

~~~bash
sudo apt update && sudo apt upgrade -y
sudo apt install curl git wget htop tmux build-essential jq make gcc -y
~~~

Replace your wallet and moniker `<YOUR_WALLET_NAME>` `<YOUR_MONIKER>` without `<>`, save and import variables into system
>

```bash
CELESTIA_PORT=11
echo "export WALLET="<YOUR_WALLET_NAME>"" >> $HOME/.bash_profile
echo "export MONIKER="<YOUR_MONIKER>"" >> $HOME/.bash_profile
echo "export CHAIN_ID="blockspacerace-0"" >> $HOME/.bash_profile
echo "export CELESTIA_PORT="${CELESTIA_PORT}"" >> $HOME/.bash_profile
source $HOME/.bash_profile
```

install go

```bash
cd ~
! [ -x "$(command -v go)" ] && {
VER="1.19.3"
wget "https://golang.org/dl/go$VER.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$VER.linux-amd64.tar.gz"
rm "go$VER.linux-amd64.tar.gz"
[ ! -f ~/.bash_profile ] && touch ~/.bash_profile
echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
source ~/.bash_profile
}
[ ! -d ~/go/bin ] && mkdir -p ~/go/bin
go version
```

Download and build binaries

```bash
cd $HOME 
rm -rf celestia-app 
git clone https://github.com/celestiaorg/celestia-app.git 
cd celestia-app/ 
APP_VERSION=v0.13.2 
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
celestia-appd config keyring-backend os
celestia-appd config chain-id $CHAIN_ID
celestia-appd init $MONIKER --chain-id $CHAIN_ID
```

Download genesis

```bash
wget -O $HOME/.celestia-app/config/genesis.json https://testnet-files.itrocket.net/celestia/genesis.json
wget -O $HOME/.celestia-app/config/addrbook.json https://testnet-files.itrocket.net/celestia/addrbook.json
```

Set seeds and peers

```bash
SEEDS="fedea9723696360d429a23792225594779cc7cd7@celestia-testnet-seed.itrocket.net:11656"
PEERS="193acd7bf7049b425d7b95c24e02250fce8ad45c@celestia-testnet-peer.itrocket.net:11656"
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

Config pruning

```bash
sed -i -e "s/^pruning *=.*/pruning = \"nothing\"/" $HOME/.celestia-app/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.celestia-app/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"10\"/" $HOME/.celestia-app/config/app.toml
```

Configure EXTERNAL_ADDRESS

~~~bash
EXTERNAL_ADDRESS=$(wget -qO- eth0.me)
sed -i.bak -e "s/^external-address = \"\"/external-address = \"$EXTERNAL_ADDRESS:26656\"/" $HOME/.celestia-app/config/config.toml
~~~

Set minimum gas price, enable prometheus and disable indexing

```bash
sed -i -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0.01utia\"/" $HOME/.celestia-app/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.celestia-app/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.celestia-app/config/config.toml
```

reset network

~~~bash 
celestia-appd tendermint unsafe-reset-all --home $HOME/.celestia-app 
~~~

Create Service file

```bash
sudo tee /etc/systemd/system/celestia-validatord.service > /dev/null <<EOF
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

Download snapshot

~~~bash
curl https://testnet-files.itrocket.net/celestia/snap_celestia.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.celestia-app
~~~

Enable and start service

```bash
sudo systemctl daemon-reload
sudo systemctl enable celestia-validatord
sudo systemctl restart celestia-validatord && sudo journalctl -u celestia-validatord -f
```

## Create wallet
### new flags should be added in the new blockspacerace-0 testnet 
>`--evm-address` This flag should contain a 0x EVM address.  
 
To create a new Ethereum  wallet, use the following guide
>Visit https://metamask.io/ and locate the extension that is compatible with your browser. 
Click and install the appropriate extension.
Once downloaded and installed, click on the extension icon and follow the prompts to create and confirm your password.  
Next, accept the term of use and give the extension the go-ahead to reveal your seed phrase. It is advisable to store multiple copies of these secret words in secure locations. Once you have backed up your seed phrase, the account registration process is complete.  
To view your ETH or ERC-20 address, navigate and select the Deposit Ether Directly tab. Then click on View Account to see and copy your ERC-20 address.

To create a new Celestia wallets, use the following command. don’t forget to save the mnemonic. 

```bash
celestia-appd keys add $WALLET
``` 

(optional) Recover wallet, use the following command

```bash
celestia-appd keys add $WALLET --recover
```

Fund your wallet 
Before creating a validator, you need to fund your wallet, go to the [Celestia discord server](https://discord.gg/celestiacommunity) and  and navigate to faucet channel. `please fund your orchestrator address too, if you want to run Celestia bridge, Full or Light node`
 
```bash
$request <YOUR_WALLET_ADDRESS>
```

Save wallets and validator addresses
>Replace your ERC-20 address `PUT_YOUR_ERC20_ADDRESS>` without `<>`

```bash
ERC20_ADDRESS="<PUT_YOUR_ERC20_ADDRESS>"
WALLET_ADDRESS=$(celestia-appd keys show $WALLET -a)
VALOPER_ADDRESS=$(celestia-appd keys show $WALLET --bech val -a)
echo "export WALLET_ADDRESS="${WALLET_ADDRESS} >> $HOME/.bash_profile
echo "export VALOPER_ADDRESS="${VALOPER_ADDRESS} >> $HOME/.bash_profile
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
celestia-appd query bank balances $WALLET_ADDRESS
```

Create validator

```bash
celestia-appd tx staking create-validator \
  --amount 1000000utia \
  --from $WALLET \
  --commission-max-change-rate "0.01" \
  --commission-max-rate "0.2" \
  --commission-rate "0.05" \
  --min-self-delegation "1" \
  --pubkey  $(celestia-appd tendermint show-validator) \
  --moniker $MONIKER \
  --chain-id $CHAIN_ID \
  --evm-address $EVM_ADDRESS \
  --gas=auto \
  --gas-adjustment=1.5 \
  --fees 5000utia
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

If you want to open access to RPC and gRPC ports, please add these rulls

~~~bash
IP_ADDRESS="<PUT_IP_ADDRESS>"
sudo ufw allow from $IP_ADDRESS to any port ${CELESTIA_PORT}090
sudo ufw allow from $IP_ADDRESS to any port ${CELESTIA_PORT}657
~~~

## Usefull commands
### Service commands
check logs

```bash
sudo journalctl -u celestia-validatord -f
```

stop service

```bash
sudo systemctl stop celestia-validatord
```

start service

```bash
sudo systemctl start celestia-validatord
```

restart service

```bash
sudo systemctl restart celestia-validatord
```

### Wallet operation

check balance

```bash
celestia-appd query bank balances $WALLET_ADDRESS
```

transfer funds

```bash
celestia-appd tx bank send $WALLET_ADDRESS <TO_WALLET_ADDRESS> 1000000utia --gas auto --gas-adjustment 1.3 --fees 5000utia
```

lists of wallets

```bash
celestia-appd keys list
```

create a new wallet

```bash
celestia-appd keys add $WALLET
```

recover wallet

```bash
celestia-appd keys add $WALLET --recover
```

delete wallet

```bash
celestia-appd keys delete $WALLET
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
celestia-appd tx gov vote 1 yes --from $WALLET --chain-id $CHAIN_ID --fees 5000utia
```

### Staking, Delegation and Rewards

Withdraw all rewards

```bash
celestia-appd tx distribution withdraw-all-rewards --from $WALLET --chain-id $CHAIN_ID --gas auto --gas-adjustment 1.3 --fees 5000utia
```

Withdraw rewards with commision

```bash
celestia-appd tx distribution withdraw-rewards $VALOPER_ADDRESS --from $WALLET --commission --chain-id $CHAIN_ID --gas auto --gas-adjustment 1.3 --fees 5000utia
```

Check balance 

```bash
celestia-appd query bank balances $WALLET_ADDRESS
```

Delegate stake

```bash
celestia-appd tx staking delegate $VALOPER_ADDRESS 10000000utia --from $WALLET --chain-id $CHAIN_ID --gas=auto --gas-adjustment 1.3 --fees 5000utia
```

Redelegate stake to another validator

```bash
celestia-appd tx staking redelegate <srcValidatorAddress> <destValidatorAddress> 1000000utia --from $WALLET --chain-id $CHAIN_ID --gas auto --gas-adjustment 1.3 --fees 5000utia
```

### Validator operation

Edit validator

```bash
celestia-appd tx staking edit-validator \
  --moniker=$NODENAME \
  --identity=<your_keybase_id> \
  --website="<your_website>" \
  --details="<your_validator_description>" \
  --chain-id=$CHAIN_ID \
  --from=$WALLET \
  --fees 5000utia
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
celestia-appd tx slashing unjail --broadcast-mode=block --from $WALLET --chain-id $CHAIN_ID --gas auto --gas-adjustment 1.5 --fees 5000utia
```

Consensus state

```bash
curl localhost:${CELESTIA_PORT}657/consensus_state
```

### Delete node

```bash
sudo systemctl stop celestia-validatord
sudo systemctl disable celestia-validatord
sudo rm -rf /etc/systemd/system/celestia-validatord*
sudo systemctl daemon-reload
sudo rm $(which celestia-appd)
sudo rm -rf $HOME/.celestia-app
sudo rm -fr $HOME/celestia-app
sed -i "/CELESTIA_/d" $HOME/.bash_profile
```

