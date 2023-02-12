<div>
<h1 align="left" style="display: flex;"> KYVE Node Setup for Testnet — kaon-1</h1>
<img src="https://avatars.githubusercontent.com/u/78351592?s=200&v=4"  style="float: right;" width="100" height="100"></img>
</div>

Official documentation:
>- [Validator setup instructions](https://github.com/KYVENetwork/networks/tree/main/kaon-1)

Explorer:
>-  https://testnet.itrocket.net/kyve/staking


## Hardware Requirements
### Recommended Hardware Requirements 
 - 4 vCPU
 - 8GB RAM
 - 200 GB of storage

## Set up your KYVE kaon node
### Manual installation

Update packages and Install dependencies

~~~bash
sudo apt update && sudo apt upgrade -y
sudo apt install curl git wget htop tmux build-essential jq make lz4 gcc -y
~~~

Replace your moniker `<YOUR_MONIKER>` without `<>`, save and import variables into system

~~~bash
KAON_PORT=28
echo "export WALLET="wallet"" >> $HOME/.bash_profile
echo "export MONIKER="<YOUR_MONIKER>"" >> $HOME/.bash_profile
echo "export KAON_CHAIN_ID="kaon-1"" >> $HOME/.bash_profile
echo "export KAON_PORT="${KAON_PORT}"" >> $HOME/.bash_profile
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
wget https://files.kyve.network/chain/v1.0.0-rc0/kyved_linux_amd64.tar.gz
tar -xvzf kyved_linux_amd64.tar.gz
mv kyved $HOME/go/bin/
rm kyved_linux_amd64.tar.gz
~~~

Config and init app

~~~bash
kyved config node tcp://localhost:${KAON_PORT}657
kyved config keyring-backend test
kyved config chain-id $KAON_CHAIN_ID
kyved init $MONIKER --chain-id $KAON_CHAIN_ID
~~~

Download genesis and addrbook

~~~bash
curl https://raw.githubusercontent.com/KYVENetwork/networks/main/kaon-1/genesis.json > ~/.kyve/config/genesis.json
~~~

Set seeds and peers

~~~bash
SEEDS="de7865a2a4936fd4bb00861ed887f219d8dd73d7@kyve-testnet-seed.itrocket.net:443"
PEERS="664e06d2d6110c5ba93f8ecfee66f150bad981bf@kyve-testnet-peer.itrocket.net:443"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.kyve/config/config.toml
~~~

Set gustom ports in app.toml file

~~~bash
sed -i.bak -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${KAON_PORT}317\"%;
s%^address = \":8080\"%address = \":${KAON_PORT}080\"%;
s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:${KAON_PORT}090\"%; 
s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:${KAON_PORT}091\"%; 
s%^address = \"0.0.0.0:8545\"%address = \"0.0.0.0:${KAON_PORT}545\"%; 
s%^ws-address = \"0.0.0.0:8546\"%ws-address = \"0.0.0.0:${KAON_PORT}546\"%" $HOME/.kyve/config/app.toml
~~~

Set gustom ports in config.toml file

~~~bash
sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${KAON_PORT}658\"%; 
s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://0.0.0.0:${KAON_PORT}657\"%; 
s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${KAON_PORT}060\"%;
s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${KAON_PORT}656\"%;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${KAON_PORT}656\"%;
s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${KAON_PORT}660\"%" $HOME/.kyve/config/config.toml
~~~

Config pruning

~~~bash
sed -i -e "s/^pruning *=.*/pruning = \"nothing\"/" $HOME/.kyve/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.kyve/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.kyve/config/app.toml
~~~

Set minimum gas price, enable prometheus and disable indexing

~~~bash
sed -i 's/minimum-gas-prices =.*/minimum-gas-prices = "0.0tkyve"/g' $HOME/.kyve/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.kyve/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.kyve/config/config.toml
~~~

Reset chain data
~~~bash
kyved tendermint unsafe-reset-all --home $HOME/.kyve
~~~

Create Service file

~~~bash
sudo tee /etc/systemd/system/kyved.service > /dev/null <<EOF
[Unit]
Description=kyve
After=network-online.target

[Service]
User=$USER
ExecStart=$(which kyved) start --home $HOME/.kyve
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
sudo systemctl enable kyved
sudo systemctl restart kyved && sudo journalctl -u kyved -f
~~~

## Create wallet
To create a new wallet, use the following command. don’t forget to save the mnemonic

~~~bash
kyved keys add $WALLET
~~~

(optional) To restore exexuting wallet, use the following command

~~~bash
kyved keys add $WALLET --recover
~~~

Save wallet and validator address

~~~bash
WALLET_ADDRESS=$(kyved keys show $WALLET -a)
VALOPER_ADDRESS=$(kyved keys show $WALLET --bech val -a)
echo "export WALLET_ADDRESS="${WALLET_ADDRESS} >> $HOME/.bash_profile
echo "export VALOPER_ADDRESS="${VALOPER_ADDRESS} >> $HOME/.bash_profile
source $HOME/.bash_profile
~~~

## (OPTIONAL) State Sync, Snapshot

In order not to wait for a long synchronization, you can use our StateSync or Snapshot guide:
> https://itrocket.net/services/testnet/kyve

## Create validator

before creating a validator, you need to check the balance and make sure that the node is synched

Check Sync status, once your node is fully synced, the output from above will say `false`

~~~bash
kyved status 2>&1 | jq .SyncInfo
~~~

Check your balance

~~~bash
kyved query bank balances $WALLET_ADDRESS
~~~

Create validator

~~~bash
kyved tx staking create-validator \
  --amount 1000000tkyve \
  --from $WALLET \
  --commission-max-change-rate "0.01" \
  --commission-max-rate "0.2" \
  --commission-rate "0.05" \
  --min-self-delegation "1" \
  --pubkey  $(kyved tendermint show-validator) \
  --moniker $MONIKER \
  --chain-id $KAON_CHAIN_ID
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
sudo ufw allow ${KAON_PORT}656/tcp
sudo ufw enable
~~~

## Usefull commands
### Service commands
check logs

~~~bash
sudo journalctl -u kyved -f
~~~

stop service

~~~bash
sudo systemctl stop kyved
~~~

start service

~~~bash
sudo systemctl start kyved
~~~

restart service

~~~bash
sudo systemctl restart kyved
~~~

### Wallet operation

check balance

~~~bash
kyved query bank balances $WALLET_ADDRESS
~~~

transfer funds

~~~bash
kyved tx bank send $WALLET_ADDRESS <TO_WALLET_ADDRESS> 1000000tkyve --gas auto --gas-adjustment 1.3
~~~

lists of wallets

~~~bash
kyved keys list
~~~

create a new wallet

~~~bash
kyved keys add $WALLET
~~~

recover wallet

~~~bash
kyved keys add $WALLET --recover
~~~

delete wallet

~~~bash
kyved keys delete $WALLET
~~~

### Node information

synch info

~~~bash
kyved status 2>&1 | jq .SyncInfo
~~~

node status

~~~bash
curl -s localhost:${KAON_PORT}657/status
~~~

node info

~~~bash
kyved status 2>&1 | jq .NodeInfo
~~~

validator info

~~~bash
kyved status 2>&1 | jq .ValidatorInfo
~~~

your node peers

~~~bash
echo $(kyved tendermint show-node-id)'@'$(curl -s ifconfig.me)':'$(cat $HOME/.kyve/config/config.toml | sed -n '/Address to listen for incoming connection/{n;p;}' | sed 's/.*://; s/".*//')
~~~

get currently conected peers lis

~~~bash
curl -sS http://localhost:${KAON_PORT}657/net_info | jq -r '.result.peers[] | "\(.node_info.id)@\(.remote_ip):\(.node_info.listen_addr)"' | awk -F ':' '{print $1":"$(NF)}'
~~~

### Voting

~~~bash
kyved tx gov vote 1 yes --from $WALLET --chain-id $KAON_CHAIN_ID
~~~

### Staking, Delegation and Rewards

Withdraw all rewards

~~~bash
kyved tx distribution withdraw-all-rewards --from $WALLET --chain-id $KAON_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

Withdraw rewards with commision

~~~bash
kyved tx distribution withdraw-rewards $VALOPER_ADDRESS --from $WALLET --commission --chain-id $KAON_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

Check balance 

~~~bash
kyved query bank balances $WALLET_ADDRESS
~~~

Delegate stake

~~~bash
kyved tx staking delegate $VALOPER_ADDRESS 1000000tkyve --from $WALLET --chain-id $KAON_CHAIN_ID --gas=auto --gas-adjustment 1.3
~~~

Redelegate stake to another validator

~~~bash
kyved tx staking redelegate <srcValidatorAddress> <destValidatorAddress> 1000000tkyve --from $WALLET --chain-id $KAON_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

### Validator operation

Edit validator

~~~bash
kyved tx staking edit-validator \
  --moniker=$NODENAME \
  --identity=<your_keybase_id> \
  --website="<your_website>" \
  --details="<your_validator_description>" \
  --chain-id=$KAON_CHAIN_ID \
  --from=$WALLET
~~~

Validator info

~~~bash
kyved status 2>&1 | jq .ValidatorInfo

~~~

Jailing info

~~~bash
kyved q slashing signing-info $(kyved tendermint show-validator)
~~~

Unjail validator

~~~bash
kyved tx slashing unjail --broadcast-mode=block --from $WALLET --chain-id $KAON_CHAIN_ID --gas auto --gas-adjustment 1.5
~~~

Consensus state

~~~bash
curl localhost:${KAON_PORT}657/consensus_state
~~~

### Delete node

~~~bash
sudo systemctl stop kyved
sudo systemctl disable kyved
sudo rm -rf /etc/systemd/system/kyved*
sudo rm $(which kyved)
sudo rm -rf $HOME/.kyve
sed -i "/KAON_/d" $HOME/.bash_profile
~~~

