<div>
<h1 align="left" style="display: flex;"> DeFund Node Setup for Testnet — orbit-alpha-1</h1>
<img src="https://avatars.githubusercontent.com/u/95717440?s=200&v=4"  style="float: right;" width="100" height="100"></img>
</div>

Official documentation:
>- [Validator setup instructions](https://github.com/defund-labs/testnet/blob/main/defund-private-4/validators.md)

Explorer:
>-  https://testnet.itrocket.net/defund/staking


## Hardware Requirements
### Recommended Hardware Requirements 
 - 16GB RAM
 - 4vCPUs
 - 200GB Disk space

## Set up your defund node
### Manual installation

Update packages and Install dependencies

~~~bash
sudo apt update && sudo apt upgrade -y
sudo apt install curl git wget htop tmux build-essential jq make lz4 gcc -y
~~~

Replace your moniker `<YOUR_MONIKER>` without `<>`, save and import variables into system

~~~bash
DEFUND_PORT=18
echo "export WALLET="wallet"" >> $HOME/.bash_profile
echo "export MONIKER="<YOUR_MONIKER>"" >> $HOME/.bash_profile
echo "export DEFUND_CHAIN_ID="orbit-alpha-1"" >> $HOME/.bash_profile
echo "export DEFUND_PORT="${DEFUND_PORT}"" >> $HOME/.bash_profile
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
rm -rf defund
git clone https://github.com/defund-labs/defund
cd defund
git checkout v0.2.6
make install
~~~
Config and init app

~~~bash
defundd config node tcp://localhost:${DEFUND_PORT}657
defundd config keyring-backend test
defundd config chain-id $DEFUND_CHAIN_ID
defundd init $MONIKER --chain-id $DEFUND_CHAIN_ID
~~~

Download genesis and addrbook

~~~bash
wget -O $HOME/.defund/config/genesis.json https://files.itrocket.net/testnet/defund/genesis.json
wget -O $HOME/.defund/config/addrbook.json https://files.itrocket.net/testnet/defund/addrbook.json
~~~

Set seeds and peers

~~~bash
SEEDS="74e6425e7ec76e6eaef92643b6181c42d5b8a3b8@defund-testnet-seed.itrocket.net:443"
PEERS="6ebe0fd3fd0990feec2dd1e09fe06b766b6b67d0@defund-testnet-peer.itrocket.net:443,d837b7f78c03899d8964351fb95c78e84128dff6@174.83.6.129:30791,f03f3a18bae28f2099648b1c8b1eadf3323cf741@162.55.211.136:26656,f8fa20444c3c56a2d3b4fdc57b3fd059f7ae3127@148.251.43.226:56656,70a1f41dea262730e7ab027bcf8bd2616160a9a9@142.132.202.86:17000"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.defund/config/config.toml
~~~

Set gustom ports in app.toml file

~~~bash
sed -i.bak -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${DEFUND_PORT}317\"%;
s%^address = \":8080\"%address = \":${DEFUND_PORT}080\"%;
s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:${DEFUND_PORT}090\"%; 
s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:${DEFUND_PORT}091\"%; 
s%^address = \"0.0.0.0:8545\"%address = \"0.0.0.0:${DEFUND_PORT}545\"%; 
s%^ws-address = \"0.0.0.0:8546\"%ws-address = \"0.0.0.0:${DEFUND_PORT}546\"%" $HOME/.defund/config/app.toml
~~~

Set gustom ports in config.toml file

~~~bash
sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${DEFUND_PORT}658\"%; 
s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://0.0.0.0:${DEFUND_PORT}657\"%; 
s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${DEFUND_PORT}060\"%;
s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${DEFUND_PORT}656\"%;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${DEFUND_PORT}656\"%;
s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${DEFUND_PORT}660\"%" $HOME/.defund/config/config.toml
~~~

Config pruning

~~~bash
sed -i -e "s/^pruning *=.*/pruning = \"nothing\"/" $HOME/.defund/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.defund/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.defund/config/app.toml
~~~

Set minimum gas price, enable prometheus and disable indexing

~~~bash
sed -i 's/minimum-gas-prices =.*/minimum-gas-prices = "0ufetf"/g' $HOME/.defund/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.defund/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.defund/config/config.toml
~~~

Reset chain data

~~~bash
defundd tendermint unsafe-reset-all --home $HOME/.defund
~~~

Create Service file

~~~bash
sudo tee /etc/systemd/system/defundd.service > /dev/null <<EOF
[Unit]
Description=defund
After=network-online.target

[Service]
User=$USER
ExecStart=$(which defundd) start --home $HOME/.defund
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
sudo systemctl enable defundd
sudo systemctl restart defundd && sudo journalctl -u defundd -f
~~~

## Snapshot, State Sync (OPTIONAL)
In order not to wait for a long synchronization, you can use our guides:

>https://itrocket.net/services/testnet/defund/#snap  
>https://itrocket.net/services/testnet/defund/#sync


## Create wallet
To create a new wallet, use the following command. don’t forget to save the mnemonic

~~~bash
defundd keys add $WALLET
~~~

(optional) To restore exexuting wallet, use the following command

~~~bash
defundd keys add $WALLET --recover
~~~

Save wallet and validator address

~~~bash
WALLET_ADDRESS=$(defundd keys show $WALLET -a)
~~~
~~~bash
VALOPER_ADDRESS=$(defundd keys show $WALLET --bech val -a)
~~~
~~~bash
echo "export WALLET_ADDRESS="${WALLET_ADDRESS} >> $HOME/.bash_profile
echo "export VALOPER_ADDRESS="${VALOPER_ADDRESS} >> $HOME/.bash_profile
source $HOME/.bash_profile
~~~

Fund your wallet 
Before creating a validator, you need to fund your wallet, go to the Defund discord server and  and navigate to `faucet` channel

~~~bash
!faucet <YOUR_WALLET_ADDRESS>
~~~


## Create validator

before creating a validator, you need to check the balance and make sure that the node is synched

Check Sync status, once your node is fully synced, the output from above will say `false`

~~~bash
defundd status 2>&1 | jq .SyncInfo
~~~

Check your balance

~~~bash
defundd query bank balances $WALLET_ADDRESS
~~~

Create validator

~~~bash
defundd tx staking create-validator \
  --amount 1000000ufetf \
  --from $WALLET \
  --commission-max-change-rate "0.01" \
  --commission-max-rate "0.2" \
  --commission-rate "0.05" \
  --min-self-delegation "1" \
  --pubkey  $(defundd tendermint show-validator) \
  --moniker $MONIKER \
  --chain-id $DEFUND_CHAIN_ID
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
sudo ufw allow ${DEFUND_PORT}656/tcp
sudo ufw enable
~~~

## Usefull commands
### Service commands
check logs

~~~bash
sudo journalctl -u defundd -f
~~~

stop service

~~~bash
sudo systemctl stop defundd
~~~

start service

~~~bash
sudo systemctl start defundd
~~~

restart service

~~~bash
sudo systemctl restart defundd
~~~

### Wallet operation

check balance

~~~bash
defundd query bank balances $WALLET_ADDRESS
~~~

transfer funds

~~~bash
defundd tx bank send $WALLET_ADDRESS <TO_WALLET_ADDRESS> 1000000ufetf --gas auto --gas-adjustment 1.3
~~~

lists of wallets

~~~bash
defundd keys list
~~~

create a new wallet

~~~bash
defundd keys add $WALLET
~~~

recover wallet

~~~bash
defundd keys add $WALLET --recover
~~~

delete wallet

~~~bash
defundd keys delete $WALLET
~~~

### Node information

synch info

~~~bash
defundd status 2>&1 | jq .SyncInfo
~~~

node status

~~~bash
curl -s localhost:${DEFUND_PORT}657/status
~~~

node info

~~~bash
defundd status 2>&1 | jq .NodeInfo
~~~

validator info

~~~bash
defundd status 2>&1 | jq .ValidatorInfo
~~~

your node peers

~~~bash
echo $(defundd tendermint show-node-id)'@'$(curl -s ifconfig.me)':'$(cat $HOME/.defund/config/config.toml | sed -n '/Address to listen for incoming connection/{n;p;}' | sed 's/.*://; s/".*//')
~~~

get currently conected peers lis

~~~bash
curl -sS http://localhost:${DEFUND_PORT}657/net_info | jq -r '.result.peers[] | "\(.node_info.id)@\(.remote_ip):\(.node_info.listen_addr)"' | awk -F ':' '{print $1":"$(NF)}'
~~~

### Voting

~~~bash
defundd tx gov vote 1 yes --from $WALLET --chain-id $DEFUND_CHAIN_ID
~~~

### Staking, Delegation and Rewards

Withdraw all rewards

~~~bash
defundd tx distribution withdraw-all-rewards --from $WALLET --chain-id $DEFUND_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

Withdraw rewards with commision

~~~bash
defundd tx distribution withdraw-rewards $VALOPER_ADDRESS --from $WALLET --commission --chain-id $DEFUND_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

Check balance 

~~~bash
defundd query bank balances $WALLET_ADDRESS
~~~

Delegate stake

~~~bash
defundd tx staking delegate $VALOPER_ADDRESS 1000000ufetf --from $WALLET --chain-id $DEFUND_CHAIN_ID --gas=auto --gas-adjustment 1.3
~~~

Redelegate stake to another validator

~~~bash
defundd tx staking redelegate <srcValidatorAddress> <destValidatorAddress> 1000000ufetf --from $WALLET --chain-id $DEFUND_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

### Validator operation

Edit validator

~~~bash
defundd tx staking edit-validator \
  --moniker=$NODENAME \
  --identity=<your_keybase_id> \
  --website="<your_website>" \
  --details="<your_validator_description>" \
  --chain-id=$DEFUND_CHAIN_ID \
  --from=$WALLET
~~~

Validator info

~~~bash
defundd status 2>&1 | jq .ValidatorInfo

~~~

Jailing info

~~~bash
defundd q slashing signing-info $(defundd tendermint show-validator)
~~~

Unjail validator

~~~bash
defundd tx slashing unjail --broadcast-mode=block --from $WALLET --chain-id $DEFUND_CHAIN_ID --gas auto --gas-adjustment 1.5
~~~

Consensus state

~~~bash
curl localhost:${DEFUND_PORT}657/consensus_state
~~~

### Delete node

~~~bash
sudo systemctl stop defundd
sudo systemctl disable defundd
sudo rm -rf /etc/systemd/system/defundd*
sudo rm $(which defundd)
sudo rm -rf $HOME/.defund
sudo rm -fr $HOME/defund
sed -i "/DEFUND_/d" $HOME/.bash_profile
~~~

