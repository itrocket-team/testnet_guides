<div>
<h1 align="left" style="display: flex;"> Humans Node Setup for Testnet — testnet-1</h1>
<img src="https://www.itrocket.net/_next/image?url=%2F_next%2Fstatic%2Fmedia%2Fhumans.c7e242ae.jpg&w=1920&q=75"  style="float: right;" width="100" height="100"></img>
</div>

Official documentation:
>- [Validator setup instructions](https://github.com/humansdotai/docs-humans/blob/master/run-nodes/testnet/joining-testnet.md)

Explorer:
>-  https://explorer.humans.zone/humans-testnet


## Hardware Requirements
### Minimal Hardware Requirements 
 - Memory: 8 GB RAM
 - CPU: Quad-Core
 - Disk: 250 GB SSD Storage
 - Bandwidth: 1 Gbps for Download / 100 Mbps for Upload

## Set up your Humans node
### Manual installation

Update packages and Install dependencies

~~~bash
sudo apt update && sudo apt upgrade -y
sudo apt install curl git wget htop tmux build-essential jq make lz4 gcc -y
~~~

Replace your moniker `<YOUR_MONIKER>` without `<>`, save and import variables into system

~~~bash
HUMANS_PORT=17
echo "export HUMANS_WALLET="wallet"" >> $HOME/.bash_profile
echo "export HUMANS_MONIKER="<YOUR_MONIKER>"" >> $HOME/.bash_profile
echo "export HUMANS_CHAIN_ID="testnet-1"" >> $HOME/.bash_profile
echo "export HUMANS_PORT="${HUMANS_PORT}"" >> $HOME/.bash_profile
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
rm -rf ~/humans
git clone https://github.com/humansdotai/humans
cd humans
git checkout v1.0.0
go build -o humansd cmd/humansd/main.go
mv humansd ~/go/bin/humansd
~~~
Config and init app

~~~bash
humansd config node tcp://localhost:${HUMANS_PORT}657
humansd config chain-id $HUMANS_CHAIN_ID
humansd config keyring-backend test
humansd init $HUMANS_MONIKER --chain-id $HUMANS_CHAIN_ID
~~~

Download genesis and addrbook

~~~bash
curl -s https://rpc-testnet.humans.zone/genesis | jq -r .result.genesis > $HOME/.humans/config/genesis.json
~~~

Set seeds and peers

~~~bash
SEEDS=""
PEERS="1df6735ac39c8f07ae5db31923a0d38ec6d1372b@45.136.40.6:26656,9726b7ba17ee87006055a9b7a45293bfd7b7f0fc@45.136.40.16:26656,6e84cde074d4af8a9df59d125db3bf8d6722a787@45.136.40.18:26656,eda3e2255f3c88f97673d61d6f37b243de34e9d9@45.136.40.13:26656,4de8c8acccecc8e0bed4a218c2ef235ab68b5cf2@45.136.40.12:26656"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.humans/config/config.toml
~~~

Set gustom ports in app.toml file

~~~bash
sed -i.bak -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${HUMANS_PORT}317\"%;
s%^address = \":8080\"%address = \":${HUMANS_PORT}080\"%;
s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:${HUMANS_PORT}090\"%; 
s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:${HUMANS_PORT}091\"%; 
s%^address = \"0.0.0.0:8545\"%address = \"0.0.0.0:${HUMANS_PORT}545\"%; 
s%^ws-address = \"0.0.0.0:8546\"%ws-address = \"0.0.0.0:${HUMANS_PORT}546\"%" $HOME/.humans/config/app.toml
~~~

Set gustom ports in config.toml file

~~~bash
sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${HUMANS_PORT}658\"%; 
s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://0.0.0.0:${HUMANS_PORT}657\"%; 
s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${HUMANS_PORT}060\"%;
s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${HUMANS_PORT}656\"%;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${HUMANS_PORT}656\"%;
s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${HUMANS_PORT}660\"%" $HOME/.humans/config/config.toml
~~~

Config pruning

~~~bash
sed -i -e "s/^pruning *=.*/pruning = \"nothing\"/" $HOME/.humans/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.humans/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.humans/config/app.toml
~~~

Set minimum gas price, enable prometheus and disable indexing

~~~bash
sed -i 's/minimum-gas-prices =.*/minimum-gas-prices = "0.025uheart"/g' $HOME/.humans/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.humans/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.humans/config/config.toml
~~~

Update block time parameters

~~~bash
CONFIG_TOML="$HOME/.humans/config/config.toml"
 sed -i 's/timeout_propose =.*/timeout_propose = "100ms"/g' $CONFIG_TOML
 sed -i 's/timeout_propose_delta =.*/timeout_propose_delta = "500ms"/g' $CONFIG_TOML
 sed -i 's/timeout_prevote =.*/timeout_prevote = "100ms"/g' $CONFIG_TOML
 sed -i 's/timeout_prevote_delta =.*/timeout_prevote_delta = "500ms"/g' $CONFIG_TOML
 sed -i 's/timeout_precommit =.*/timeout_precommit = "100ms"/g' $CONFIG_TOML
 sed -i 's/timeout_precommit_delta =.*/timeout_precommit_delta = "500ms"/g' $CONFIG_TOML
 sed -i 's/timeout_commit =.*/timeout_commit = "1s"/g' $CONFIG_TOML
 sed -i 's/skip_timeout_commit =.*/skip_timeout_commit = false/g' $CONFIG_TOML
~~~

Clean old data

```bash
humansd tendermint unsafe-reset-all --home $HOME/.humans --keep-addr-book
```

Create Service file

~~~bash
sudo tee /etc/systemd/system/humansd.service > /dev/null <<EOF
[Unit]
Description=humans
After=network-online.target

[Service]
User=$USER
ExecStart=$(which humansd) start --home $HOME/.humans
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
sudo systemctl enable humansd
sudo systemctl restart humansd && sudo journalctl -u humansd -f
~~~

## (OPTIONAL) State Sync

In order not to wait for a long synchronization, you can use our StateSync guide:
> https://github.com/marutyan/testnet_guides/blob/main/sei/statesync.md

## Create wallet
To create a new wallet, use the following command. don’t forget to save the mnemonic

~~~bash
humansd keys add $HUMANS_WALLET
~~~

(optional) To restore exexuting wallet, use the following command

~~~bash
humansd keys add $HUMANS_WALLET --recover
~~~

Save wallet and validator address

~~~bash
HUMANS_WALLET_ADDRESS=$(humansd keys show $HUMANS_WALLET -a)
HUMANS_VALOPER_ADDRESS=$(humansd keys show $HUMANS_WALLET --bech val -a)
echo "export HUMANS_WALLET_ADDRESS="${HUMANS_WALLET_ADDRESS} >> $HOME/.bash_profile
echo "export HUMANS_VALOPER_ADDRESS="${HUMANS_VALOPER_ADDRESS} >> $HOME/.bash_profile
source $HOME/.bash_profile
~~~

Fund your wallet 
Before creating a validator, you need to fund your wallet, go to the [Humans discord server](https://discord.gg/humansdotai) and  and navigate to `testnet-faucet` channel

~~~bash
$request <YOUR_WALLET_ADDRESS>
~~~


## Create validator

before creating a validator, you need to check the balance and make sure that the node is synched

Check Sync status, once your node is fully synced, the output from above will say `false`

~~~bash
humansd status 2>&1 | jq .SyncInfo
~~~

Check your balance

~~~bash
humansd query bank balances $HUMANS_WALLET_ADDRESS
~~~

Create validator

~~~bash
humansd tx staking create-validator \
  --amount 9000000uheart \
  --from $HUMANS_WALLET \
  --commission-max-change-rate "0.01" \
  --commission-max-rate "0.2" \
  --commission-rate "0.05" \
  --min-self-delegation "1" \
  --pubkey  $(humansd tendermint show-validator) \
  --moniker $HUMANS_MONIKER \
  --chain-id $HUMANS_CHAIN_ID \
  --fees 5000uheart \
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
sudo ufw allow ${HUMANS_PORT}656/tcp
sudo ufw enable
~~~

## Usefull commands
### Service commands
check logs

~~~bash
sudo journalctl -u humansd -f
~~~

restart service

~~~bash
sudo systemctl restart humansd
~~~

### Wallet operation

check balance

~~~bash
humansd query bank balances $HUMANS_WALLET_ADDRESS
~~~

transfer funds

~~~bash
humansd tx bank send $HUMANS_WALLET_ADDRESS <TO_HUMANS_WALLET_ADDRESS> 1000000uheart --gas auto --gas-adjustment 1.3
~~~

lists of wallets

~~~bash
humansd keys list
~~~

delete wallet

~~~bash
humansd keys delete $HUMANS_WALLET
~~~

### Node information

synch info

~~~bash
humansd status 2>&1 | jq .SyncInfo
~~~

node status && node info && validator info

~~~bash
curl -s localhost:${HUMANS_PORT}657/status && humansd status 2>&1 | jq .NodeInfo && humansd status 2>&1 | jq .ValidatorInfo
~~~

your node peers

~~~bash
echo $(humansd tendermint show-node-id)'@'$(curl -s ifconfig.me)':'$(cat $HOME/.humans/config/config.toml | sed -n '/Address to listen for incoming connection/{n;p;}' | sed 's/.*://; s/".*//')
~~~

get currently conected peers lis

~~~bash
curl -sS http://localhost:${HUMANS_PORT}657/net_info | jq -r '.result.peers[] | "\(.node_info.id)@\(.remote_ip):\(.node_info.listen_addr)"' | awk -F ':' '{print $1":"$(NF)}'
~~~

### Voting

~~~bash
humansd tx gov vote 1 yes --from $HUMANS_WALLET --chain-id $HUMANS_CHAIN_ID
~~~

### Staking, Delegation and Rewards

Withdraw all rewards

~~~bash
humansd tx distribution withdraw-all-rewards --from $HUMANS_WALLET --chain-id $HUMANS_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

Withdraw rewards with commision

~~~bash
humansd tx distribution withdraw-rewards $HUMANS_VALOPER_ADDRESS --from $HUMANS_WALLET --commission --chain-id $HUMANS_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

Check balance 

~~~bash
humansd query bank balances $HUMANS_WALLET_ADDRESS
~~~

Delegate stake

~~~bash
humansd tx staking delegate $HUMANS_VALOPER_ADDRESS 1000000uheart --from $HUMANS_WALLET --chain-id $HUMANS_CHAIN_ID --gas=auto --gas-adjustment 1.3
~~~

Redelegate stake to another validator

~~~bash
humansd tx staking redelegate <srcValidatorAddress> <destValidatorAddress> 1000000uheart --from $HUMANS_WALLET --chain-id $HUMANS_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

### Validator operation

Edit validator

~~~bash
humansd tx staking edit-validator \
  --moniker=$NODENAME \
  --identity=<your_keybase_id> \
  --website="<your_website>" \
  --details="<your_validator_description>" \
  --chain-id=$HUMANS_CHAIN_ID \
  --from=$HUMANS_WALLET
~~~

Jailing info

~~~bash
humansd q slashing signing-info $(humansd tendermint show-validator)
~~~

Unjail validator

~~~bash
humansd tx slashing unjail --broadcast-mode=block --from $HUMANS_WALLET --chain-id $HUMANS_CHAIN_ID --gas auto --gas-adjustment 1.5
~~~

Consensus state

~~~bash
curl localhost:${HUMANS_PORT}657/consensus_state
~~~

### Delete node

~~~bash
sudo systemctl stop humansd
sudo systemctl disable humansd
sudo rm -rf /etc/systemd/system/humansd*
sudo rm $(which humansd)
sudo rm -rf $HOME/.humans
sudo rm -fr $HOME/humans
sed -i "/HUMANS_/d" $HOME/.bash_profile
~~~

