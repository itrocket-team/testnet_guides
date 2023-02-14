<div>
<h1 align="left" style="display: flex;"> Andromeda Node Setup for Testnet — galileo-3</h1>
<img src="https://avatars.githubusercontent.com/u/86694044?s=200&v=4"  style="float: right;" width="100" height="100"></img>
</div>


Explorer:
>-  https://testnet.itrocket.net/sei/staking


## Hardware Requirements
### Recommended Hardware Requirements 
 - MEMORY - 32GB
 - CPUs - 16
 - DISK - 500GB
## Set up your node
### Manual installation

Update packages and Install dependencies

~~~bash
sudo apt update && sudo apt upgrade -y
sudo apt install curl git wget htop tmux build-essential jq make lz4 gcc -y
~~~

Replace your moniker `<YOUR_MONIKER>` without `<>`, save and import variables into system

~~~bash
ANDROMEDA_PORT=30
echo "export WALLET="wallet"" >> $HOME/.bash_profile
echo "export MONIKER="<YOUR_MONIKER>"" >> $HOME/.bash_profile
echo "export ANDROMEDA_CHAIN_ID="galileo-3"" >> $HOME/.bash_profile
echo "export ANDROMEDA_PORT="${ANDROMEDA_PORT}"" >> $HOME/.bash_profile
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
rm -rf andromedad
git clone https://github.com/andromedaprotocol/andromedad.git
cd andromedad
git checkout galileo-3-v1.1.0-beta1
make install
~~~

Config and init app

~~~bash
andromedad config node tcp://localhost:${ANDROMEDA_PORT}657
andromedad config keyring-backend test
andromedad config chain-id $ANDROMEDA_CHAIN_ID
andromedad init $MONIKER --chain-id $ANDROMEDA_CHAIN_ID
~~~

Download genesis and addrbook

~~~bash
wget -O $HOME/.andromedad/config/genesis.json https://files.itrocket.net/testnet/andromeda/genesis.json
wget -O $HOME/.andromedad/config/addrbook.json https://files.itrocket.net/testnet/andromeda/addrbook.json
~~~

Set seeds and peers

~~~bash
SEEDS=""
PEERS="239eeebb9c4c32f5ca91b22322fed2486aee01b5@andromeda-testnet-peer.itrocket.net:443,69e89a5169fef99ed1b72dadd4f5c7b801616c88@142.132.209.236:21256,2475bcd6fc1950d8ddecfccd2c3161ce99130741@194.126.172.250:36656,117bf8ca700de022d9c87cd7cc7155958dc0ba23@185.188.249.18:02656,9d058b4c4eb63122dfab2278d8be1bf6bf07f9ef@65.109.86.236:26656,f1d30c5f2d5882823317718eb4455f87ae846d0a@85.239.235.235:30656,8a551bc0cc7ba190db9126c8fc95c8b643ae511c@195.201.174.109:56656,18dcd9769f1b9b16730c432cdc1155c7fe90e834@136.243.56.252:56656,00cedd85b1f6a2c859a8c6116b9578e1cc2623c6@51.222.44.116:30656,139e89b8868aed5c5922a563ecd5002959af04ff@65.108.111.236:55716"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.andromedad/config/config.toml
~~~

Set gustom ports in app.toml file

~~~bash
sed -i.bak -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${ANDROMEDA_PORT}317\"%;
s%^address = \":8080\"%address = \":${ANDROMEDA_PORT}080\"%;
s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:${ANDROMEDA_PORT}090\"%; 
s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:${ANDROMEDA_PORT}091\"%; 
s%^address = \"0.0.0.0:8545\"%address = \"0.0.0.0:${ANDROMEDA_PORT}545\"%; 
s%^ws-address = \"0.0.0.0:8546\"%ws-address = \"0.0.0.0:${ANDROMEDA_PORT}546\"%" $HOME/.andromedad/config/app.toml
~~~

Set gustom ports in config.toml file

~~~bash
sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${ANDROMEDA_PORT}658\"%; 
s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://0.0.0.0:${ANDROMEDA_PORT}657\"%; 
s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${ANDROMEDA_PORT}060\"%;
s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${ANDROMEDA_PORT}656\"%;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${ANDROMEDA_PORT}656\"%;
s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${ANDROMEDA_PORT}660\"%" $HOME/.andromedad/config/config.toml
~~~

Config pruning

~~~bash
sed -i -e "s/^pruning *=.*/pruning = \"nothing\"/" $HOME/.andromedad/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.andromedad/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.andromedad/config/app.toml
~~~

Set minimum gas price, enable prometheus and disable indexing

~~~bash
sed -i 's/minimum-gas-prices =.*/minimum-gas-prices = "0.0uandr"/g' $HOME/.andromedad/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.andromedad/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.andromedad/config/config.toml
~~~

Reset chain data
~~~bash
andromedad tendermint unsafe-reset-all --home $HOME/.andromedad
~~~

Create Service file

~~~bash
sudo tee /etc/systemd/system/andromedad.service > /dev/null <<EOF
[Unit]
Description=andromeda
After=network-online.target

[Service]
User=$USER
ExecStart=$(which andromedad) start --home $HOME/.andromedad
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
sudo systemctl enable andromedad
sudo systemctl restart andromedad && sudo journalctl -u andromedad -f
~~~

Download Snapshot

~~~bash
sudo systemctl stop andromedad
cp $HOME/.andromedad/data/priv_validator_state.json $HOME/.andromedad/priv_validator_state.json.backup
rm -rf $HOME/.andromedad/data $HOME/.andromedad/wasm
curl https://files.itrocket.net/testnet/andromeda/snap_andromeda.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.andromedad
mv $HOME/.andromedad/priv_validator_state.json.backup $HOME/.andromedad/data/priv_validator_state.json
sudo systemctl restart andromedad && sudo journalctl -u andromedad -f
~~~

## Create wallet
To create a new wallet, use the following command. don’t forget to save the mnemonic

~~~bash
andromedad keys add $WALLET
~~~

(optional) To restore exexuting wallet, use the following command

~~~bash
andromedad keys add $WALLET --recover
~~~

Save wallet and validator address

~~~bash
WALLET_ADDRESS=$(andromedad keys show $WALLET -a)
VALOPER_ADDRESS=$(andromedad keys show $WALLET --bech val -a)
echo "export WALLET_ADDRESS="${WALLET_ADDRESS} >> $HOME/.bash_profile
echo "export VALOPER_ADDRESS="${VALOPER_ADDRESS} >> $HOME/.bash_profile
source $HOME/.bash_profile
~~~


## Create validator

before creating a validator, you need to check the balance and make sure that the node is synched

Check Sync status, once your node is fully synced, the output from above will say `false`

~~~bash
andromedad status 2>&1 | jq .SyncInfo
~~~

Check your balance

~~~bash
andromedad query bank balances $WALLET_ADDRESS
~~~

Create validator

~~~bash
andromedad tx staking create-validator \
  --amount 1000000uandr \
  --from $WALLET \
  --commission-max-change-rate "0.01" \
  --commission-max-rate "0.2" \
  --commission-rate "0.05" \
  --min-self-delegation "1" \
  --pubkey  $(andromedad tendermint show-validator) \
  --moniker $MONIKER \
  --chain-id $ANDROMEDA_CHAIN_ID
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
sudo ufw allow ${ANDROMEDA_PORT}656/tcp
sudo ufw enable
~~~

## Usefull commands
### Service commands
check logs

~~~bash
sudo journalctl -u andromedad -f
~~~

stop service

~~~bash
sudo systemctl stop andromedad
~~~

start service

~~~bash
sudo systemctl start andromedad
~~~

restart service

~~~bash
sudo systemctl restart andromedad
~~~

### Wallet operation

check balance

~~~bash
andromedad query bank balances $WALLET_ADDRESS
~~~

transfer funds

~~~bash
andromedad tx bank send $WALLET_ADDRESS <TO_WALLET_ADDRESS> 1000000uandr --gas auto --gas-adjustment 1.3
~~~

lists of wallets

~~~bash
andromedad keys list
~~~

create a new wallet

~~~bash
andromedad keys add $WALLET
~~~

recover wallet

~~~bash
andromedad keys add $WALLET --recover
~~~

delete wallet

~~~bash
andromedad keys delete $WALLET
~~~

### Node information

synch info

~~~bash
andromedad status 2>&1 | jq .SyncInfo
~~~

node status

~~~bash
curl -s localhost:${ANDROMEDA_PORT}657/status
~~~

node info

~~~bash
andromedad status 2>&1 | jq .NodeInfo
~~~

validator info

~~~bash
andromedad status 2>&1 | jq .ValidatorInfo
~~~

your node peers

~~~bash
echo $(andromedad tendermint show-node-id)'@'$(curl -s ifconfig.me)':'$(cat $HOME/.andromedad/config/config.toml | sed -n '/Address to listen for incoming connection/{n;p;}' | sed 's/.*://; s/".*//')
~~~

get currently conected peers lis

~~~bash
curl -sS http://localhost:${ANDROMEDA_PORT}657/net_info | jq -r '.result.peers[] | "\(.node_info.id)@\(.remote_ip):\(.node_info.listen_addr)"' | awk -F ':' '{print $1":"$(NF)}'
~~~

### Voting

~~~bash
andromedad tx gov vote 1 yes --from $WALLET --chain-id $ANDROMEDA_CHAIN_ID
~~~

### Staking, Delegation and Rewards

Withdraw all rewards

~~~bash
andromedad tx distribution withdraw-all-rewards --from $WALLET --chain-id $ANDROMEDA_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

Withdraw rewards with commision

~~~bash
andromedad tx distribution withdraw-rewards $VALOPER_ADDRESS --from $WALLET --commission --chain-id $ANDROMEDA_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

Check balance 

~~~bash
andromedad query bank balances $WALLET_ADDRESS
~~~

Delegate stake

~~~bash
andromedad tx staking delegate $VALOPER_ADDRESS 1000000uandr --from $WALLET --chain-id $ANDROMEDA_CHAIN_ID --gas=auto --gas-adjustment 1.3
~~~

Redelegate stake to another validator

~~~bash
andromedad tx staking redelegate <srcValidatorAddress> <destValidatorAddress> 1000000uandr --from $WALLET --chain-id $ANDROMEDA_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

### Validator operation

Edit validator

~~~bash
andromedad tx staking edit-validator \
  --moniker=$NODENAME \
  --identity=<your_keybase_id> \
  --website="<your_website>" \
  --details="<your_validator_description>" \
  --chain-id=$ANDROMEDA_CHAIN_ID \
  --from=$WALLET
~~~

Validator info

~~~bash
andromedad status 2>&1 | jq .ValidatorInfo

~~~

Jailing info

~~~bash
andromedad q slashing signing-info $(andromedad tendermint show-validator)
~~~

Unjail validator

~~~bash
andromedad tx slashing unjail --broadcast-mode=block --from $WALLET --chain-id $ANDROMEDA_CHAIN_ID --gas auto --gas-adjustment 1.5
~~~

Consensus state

~~~bash
curl localhost:${ANDROMEDA_PORT}657/consensus_state
~~~

### Delete node

~~~bash
sudo systemctl stop andromedad
sudo systemctl disable andromedad
sudo rm -rf /etc/systemd/system/andromedad*
sudo rm $(which andromedad)
sudo rm -rf $HOME/.andromedad
sudo rm -fr $HOME/andromedad
sed -i "/ANDROMEDA_/d" $HOME/.bash_profile
~~~

