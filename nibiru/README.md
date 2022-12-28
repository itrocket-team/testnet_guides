<div>
<h1 align="left" style="display: flex;"> Nibiru Node Setup for Testnet — nibiru-testnet-2</h1>
<img src="https://avatars.githubusercontent.com/u/95279816?s=200&v=4"  style="float: right;" width="100" height="100"></img>
</div>

Official documentation:
>- [Validator setup instructions](https://docs.nibiru.fi/run-nodes/testnet/)

Explorer:
>-  https://testnet-2.nibiru.fi/validators


## Hardware Requirements
### Minimum Hardware Requirements 
 - 4x CPUs
 - 16GB RAM
 - 500GB of disk space (SSD)

## Set up your nibiru node
### Manual installation

Update packages and Install dependencies

~~~bash
sudo apt update && sudo apt upgrade -y
sudo apt install curl git wget htop tmux build-essential jq make gcc -y
~~~

Replace your moniker `<YOUR_MONIKER>` without `<>`, save and import variables into system

~~~bash
NIBIRU_PORT=12
echo "export NIBIRU_WALLET="wallet"" >> $HOME/.bash_profile
echo "export NIBIRU_MONIKER="<YOUR_MONIKER>"" >> $HOME/.bash_profile
echo "export NIBIRU_CHAIN_ID="nibiru-testnet-2"" >> $HOME/.bash_profile
echo "export NIBIRU_PORT="${NIBIRU_PORT}"" >> $HOME/.bash_profile
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
git clone https://github.com/NibiruChain/nibiru
cd nibiru
git checkout v0.16.3
make install 
~~~
Config and init app

~~~bash
nibid config node tcp://localhost:${NIBIRU_PORT}657
nibid config chain-id $NIBIRU_CHAIN_ID
nibid config keyring-backend test
nibid init $NIBIRU_MONIKER --chain-id $NIBIRU_CHAIN_ID
~~~

Download genesis

~~~bash
NETWORK=nibiru-testnet-2
curl -s https://networks.testnet.nibiru.fi/$NETWORK/genesis > $HOME/.nibid/config/genesis.json
~~~

Set seeds and peers

~~~bash
NETWORK=nibiru-testnet-2
sed -i 's|seeds =.*|seeds = "'$(curl -s https://networks.testnet.nibiru.fi/$NETWORK/seeds)'"|g' $HOME/.nibid/config/config.toml
~~~

Set gustom ports in app.toml file

~~~bash
sed -i.bak -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${NIBIRU_PORT}317\"%;
s%^address = \":8080\"%address = \":${NIBIRU_PORT}080\"%;
s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:${NIBIRU_PORT}090\"%; 
s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:${NIBIRU_PORT}091\"%; 
s%^address = \"0.0.0.0:8545\"%address = \"0.0.0.0:${NIBIRU_PORT}545\"%; 
s%^ws-address = \"0.0.0.0:8546\"%ws-address = \"0.0.0.0:${NIBIRU_PORT}546\"%" $HOME/.nibid/config/app.toml
~~~

Set gustom ports in config.toml file

~~~bash
sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${NIBIRU_PORT}658\"%; 
s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://0.0.0.0:${NIBIRU_PORT}657\"%; 
s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${NIBIRU_PORT}060\"%;
s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${NIBIRU_PORT}656\"%;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${NIBIRU_PORT}656\"%;
s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${NIBIRU_PORT}660\"%" $HOME/.nibid/config/config.toml
~~~

Config pruning

~~~bash
sed -i -e "s/^pruning *=.*/pruning = \"nothing\"/" $HOME/.nibid/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.nibid/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.nibid/config/app.toml
~~~

Set minimum gas price, enable prometheus and disable indexing

~~~bash
sed -i 's/minimum-gas-prices =.*/minimum-gas-prices = "0.025unibi"/g' $HOME/.nibid/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.nibid/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.nibid/config/config.toml
~~~

Clean old data

~~~bash
nibid tendermint unsafe-reset-all --home $HOME/.nibid --keep-addr-book
~~~

Create Service file

~~~bash
sudo tee /etc/systemd/system/nibid.service > /dev/null <<EOF
[Unit]
Description=nibiru
After=network-online.target

[Service]
User=$USER
ExecStart=$(which nibid) start --home $HOME/.nibid
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
sudo systemctl enable nibid
sudo systemctl restart nibid && sudo journalctl -u nibid -f
~~~

## Create wallet
To create a new wallet, use the following command. don’t forget to save the mnemonic

~~~bash
nibid keys add $NIBIRU_WALLET
~~~

(optional) To restore exexuting wallet, use the following command

~~~bash
nibid keys add $NIBIRU_WALLET --recover
~~~

Save wallet and validator address

~~~bash
NIBIRU_WALLET_ADDRESS=$(nibid keys show $NIBIRU_WALLET -a)
NIBIRU_VALOPER_ADDRESS=$(nibid keys show $NIBIRU_WALLET --bech val -a)
echo "export NIBIRU_WALLET_ADDRESS="${NIBIRU_WALLET_ADDRESS} >> $HOME/.bash_profile
echo "export NIBIRU_VALOPER_ADDRESS="${NIBIRU_VALOPER_ADDRESS} >> $HOME/.bash_profile
source $HOME/.bash_profile
~~~

Fund your wallet 
Before creating a validator, you need to fund your wallet, go to the [Nibiru discord server](https://discord.gg/nibiru) and  and navigate to faucet channel

~~~bash
$request <YOUR_WALLET_ADDRESS>
~~~

> or request tokens from the cli
>Please note, that current daily limit for the Web Faucet is 10NIBI (10000000unibi) and 100,000 NUSD (100000000000unusd).

~~~bash
FAUCET_URL="https://faucet.testnet-2.nibiru.fi/" 
curl -X POST -d '{"address": "'"$NIBIRU_WALLET_ADDRESS"'", "coins": ["10000000unibi","100000000000unusd"]}' $FAUCET_URL
~~~

## (OPTIONAL) State Sync

In order not to wait for a long synchronization, you can use our StateSync guide:
> https://github.com/marutyan/testnet_guides/blob/main/nibiru/statesync.md


## Create validator

before creating a validator, you need to check the balance and make sure that the node is synched

Check Sync status, once your node is fully synced, the output from above will say `false`

~~~bash
nibid status 2>&1 | jq .SyncInfo
~~~

Check your balance

~~~bash
nibid query bank balances $NIBIRU_WALLET_ADDRESS
~~~

Create validator

~~~bash
nibid tx staking create-validator \
  --amount 1000000unibi \
  --from $NIBIRU_WALLET \
  --commission-max-change-rate "0.01" \
  --commission-max-rate "0.2" \
  --commission-rate "0.05" \
  --min-self-delegation "1" \
  --pubkey  $(nibid tendermint show-validator) \
  --moniker $NIBIRU_MONIKER \
  --chain-id $NIBIRU_CHAIN_ID \
  --fees 10000unibi
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
sudo ufw allow ${NIBIRU_PORT}656/tcp
sudo ufw enable
~~~

## Usefull commands
### Service commands
check logs

~~~bash
sudo journalctl -u nibid -f
~~~

stop service

~~~bash
sudo systemctl stop nibid
~~~

start service

~~~bash
sudo systemctl start nibid
~~~

restart service

~~~bash
sudo systemctl restart nibid
~~~

### Wallet operation

check balance

~~~bash
nibid query bank balances $NIBIRU_WALLET_ADDRESS
~~~

transfer funds

~~~bash
nibid tx bank send $NIBIRU_WALLET_ADDRESS <TO_NIBIRU_WALLET_ADDRESS> 1000000000000000000unibi --gas auto --gas-adjustment 1.3
~~~

lists of wallets

~~~bash
nibid keys list
~~~

create a new wallet

~~~bash
nibid keys add $NIBIRU_WALLET
~~~

recover wallet

~~~bash
nibid keys add $NIBIRU_WALLET --recover
~~~

delete wallet

~~~bash
nibid keys delete $NIBIRU_WALLET
~~~

### Node information

synch info

~~~bash
nibid status 2>&1 | jq .SyncInfo
~~~

node status

~~~bash
curl -s localhost:${NIBIRU_PORT}657/status
~~~

node info

~~~bash
nibid status 2>&1 | jq .NodeInfo
~~~

validator info

~~~bash
nibid status 2>&1 | jq .ValidatorInfo
~~~

your node peers

~~~bash
echo $(nibid tendermint show-node-id)'@'$(curl -s ifconfig.me)':'$(cat $HOME/.nibid/config/config.toml | sed -n '/Address to listen for incoming connection/{n;p;}' | sed 's/.*://; s/".*//')
~~~

get currently conected peers lis

~~~bash
curl -sS http://localhost:${NIBIRU_PORT}657/net_info | jq -r '.result.peers[] | "\(.node_info.id)@\(.remote_ip):\(.node_info.listen_addr)"' | awk -F ':' '{print $1":"$(NF)}'
~~~

### Voting

~~~bash
nibid tx gov vote 1 yes --from $NIBIRU_WALLET --chain-id $NIBIRU_CHAIN_ID
~~~

### Staking, Delegation and Rewards

Withdraw all rewards

~~~bash
nibid tx distribution withdraw-all-rewards --from $NIBIRU_WALLET --chain-id $NIBIRU_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

Withdraw rewards with commision

~~~bash
nibid tx distribution withdraw-rewards $NIBIRU_VALOPER_ADDRESS --from $NIBIRU_WALLET --commission --chain-id $NIBIRU_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

Check balance 

~~~bash
nibid query bank balances $NIBIRU_WALLET_ADDRESS
~~~

Delegate stake

~~~bash
nibid tx staking delegate $NIBIRU_VALOPER_ADDRESS 2000000unibi --from $NIBIRU_WALLET --chain-id $NIBIRU_CHAIN_ID --gas=auto --gas-adjustment 1.3
~~~

Redelegate stake to another validator

~~~bash
nibid tx staking redelegate <srcValidatorAddress> <destValidatorAddress> 2000000unibi --from $NIBIRU_WALLET --chain-id $NIBIRU_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

### Validator operation

Edit validator

~~~bash
nibid tx staking edit-validator \
  --moniker=$NODENAME \
  --identity=<your_keybase_id> \
  --website="<your_website>" \
  --details="<your_validator_description>" \
  --chain-id=$NIBIRU_CHAIN_ID \
  --from=$NIBIRU_WALLET
~~~

Validator info

~~~bash
nibid status 2>&1 | jq .ValidatorInfo

~~~

Jailing info

~~~bash
nibid q slashing signing-info $(nibid tendermint show-validator)
~~~

Unjail validator

~~~bash
nibid tx slashing unjail --broadcast-mode=block --from $NIBIRU_WALLET --chain-id $NIBIRU_CHAIN_ID --gas auto --gas-adjustment 1.5
~~~

Consensus state

~~~bash
curl localhost:${NIBIRU_PORT}657/consensus_state
~~~

### Delete node

~~~bash
sudo systemctl stop nibid
sudo systemctl disable nibid
sudo rm -rf /etc/systemd/system/nibid*
sudo rm $(which nibid)
sudo rm -rf $HOME/.nibid
sudo rm -fr $HOME/nibiru
sed -i "/NIBIRU_/d" $HOME/.bash_profile
~~~

