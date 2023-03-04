<div>
<h1 align="left" style="display: flex;"> Quicksilver Node Setup for Mainnet — quicksilver-2</h1>
<img src="https://github.com/marutyan/testnet_guides/blob/main/logos/quicksilver.jpg"  style="float: right;" width="100" height="100"></img>
</div>

Official documentation:
>- [Validator setup instructions](https://github.com/ingenuity-build/mainnet)

Explorer:
>-  https://quicksilver.explorers.guru/


## Hardware Requirements
### Recommended Hardware Requirements 
 - 4 cores (max. clock speed possible)
 - 16GB RAM
 - 500GB+ of NVMe or SSD disk

## Set up your Quicksilver mainet node
### Manual installation

Update packages and Install dependencies

~~~bash
sudo apt update && sudo apt upgrade -y
sudo apt install curl git wget htop tmux build-essential jq make lz4 gcc -y
~~~

Replace your wallet and moniker `<YOUR_WALLET_NAME>` `<YOUR_MONIKER>` without `<>`, save and import variables into system

~~~bash
QUICKSILVER_PORT=15
echo "export QUICKSILVER_WALLET="<YOUR_WALLET_NAME>"" >> $HOME/.bash_profile
echo "export QUICKSILVER_MONIKER="<YOUR_MONIKER>"" >> $HOME/.bash_profile
echo "export QUICKSILVER_CHAIN_ID="quicksilver-2"" >> $HOME/.bash_profile
echo "export QUICKSILVER_PORT="${QUICKSILVER_PORT}"" >> $HOME/.bash_profile
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
rm -rf ~/quicksilver
git clone https://github.com/ingenuity-build/quicksilver
cd quicksilver
git fetch
git checkout v1.2.4
make install
~~~

Verify installation
~~~bash
quicksilverd version --long
~~~

Config and init app

~~~bash
quicksilverd config node tcp://localhost:${QUICKSILVER_PORT}657
quicksilverd config chain-id $QUICKSILVER_CHAIN_ID
quicksilverd init $QUICKSILVER_MONIKER --chain-id $QUICKSILVER_CHAIN_ID
~~~

Download genesis and addrbook

~~~bash
wget https://raw.githubusercontent.com/ingenuity-build/mainnet/main/migrate-genesis.py
wget https://raw.githubusercontent.com/ingenuity-build/mainnet/main/export-quicksilver-1-115000.json
python3 migrate-genesis.py
cp genesis.json ~/.quicksilverd/config/genesis.json
~~~

Set seeds and peers

~~~bash
export SEEDS="20e1000e88125698264454a884812746c2eb4807@seeds.lavenderfive.com:11156,babc3f3f7804933265ec9c40ad94f4da8e9e0017@seed.rhinostake.com:11156,00f51227c4d5d977ad7174f1c0cea89082016ba2@seed-quick-mainnet.moonshot.army:26650"
sed -i.bak -e "s/^seeds *=.*/seeds = \"$SEEDS\"/" ~/.quicksilverd/config/config.toml
~~~

Set gustom ports in app.toml file

~~~bash
sed -i.bak -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${QUICKSILVER_PORT}317\"%;
s%^address = \":8080\"%address = \":${QUICKSILVER_PORT}080\"%;
s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:${QUICKSILVER_PORT}090\"%; 
s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:${QUICKSILVER_PORT}091\"%; 
s%^address = \"0.0.0.0:8545\"%address = \"0.0.0.0:${QUICKSILVER_PORT}545\"%; 
s%^ws-address = \"0.0.0.0:8546\"%ws-address = \"0.0.0.0:${QUICKSILVER_PORT}546\"%" $HOME/.quicksilverd/config/app.toml
~~~

Set gustom ports in config.toml file

~~~bash
sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${QUICKSILVER_PORT}658\"%; 
s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://0.0.0.0:${QUICKSILVER_PORT}657\"%; 
s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${QUICKSILVER_PORT}060\"%;
s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${QUICKSILVER_PORT}656\"%;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${QUICKSILVER_PORT}656\"%;
s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${QUICKSILVER_PORT}660\"%" $HOME/.quicksilverd/config/config.toml
~~~

Config pruning

~~~bash
sed -i -e "s/^pruning *=.*/pruning = \"nothing\"/" $HOME/.quicksilverd/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.quicksilverd/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.quicksilverd/config/app.toml
~~~

Set minimum gas price, enable prometheus and disable indexing

~~~bash
sed -i.bak -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0uqck\"/;" ~/.quicksilverd/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.quicksilverd/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.quicksilverd/config/config.toml
~~~

Create Service file

~~~bash
sudo tee /etc/systemd/system/quicksilverd.service > /dev/null <<EOF
[Unit]
Description=quicksilver
After=network-online.target

[Service]
User=$USER
ExecStart=$(which quicksilverd) start --home $HOME/.quicksilverd
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
sudo systemctl enable quicksilverd
sudo systemctl restart quicksilverd && sudo journalctl -u quicksilverd -f
~~~

## Snapshot, State Sync (OPTIONAL)
In order not to wait for a long synchronization, you can use our guides:

>https://itrocket.net/services/mainnet/quicksilver/#snap
>https://itrocket.net/services/mainnet/quicksilver/#sync

## Create wallet
To create a new wallet, use the following command. don’t forget to save the mnemonic

~~~bash
quicksilverd keys add $QUICKSILVER_WALLET
~~~

(optional) To restore exexuting wallet, use the following command

~~~bash
quicksilverd keys add $QUICKSILVER_WALLET --recover
~~~

Save wallet and validator address

~~~bash
QUICKSILVER_WALLET_ADDRESS=$(quicksilverd keys show $QUICKSILVER_WALLET -a)
~~~
~~~bash
QUICKSILVER_VALOPER_ADDRESS=$(quicksilverd keys show $QUICKSILVER_WALLET --bech val -a)
~~~
~~~bash
echo "export QUICKSILVER_WALLET_ADDRESS="${QUICKSILVER_WALLET_ADDRESS} >> $HOME/.bash_profile
echo "export QUICKSILVER_VALOPER_ADDRESS="${QUICKSILVER_VALOPER_ADDRESS} >> $HOME/.bash_profile
source $HOME/.bash_profile
~~~

## Create validator

before creating a validator, you need to check the balance and make sure that the node is synched

Check Sync status, once your node is fully synced, the output from above will say `false`

~~~bash
quicksilverd status 2>&1 | jq .SyncInfo
~~~

Check your balance

~~~bash
quicksilverd query bank balances $QUICKSILVER_WALLET_ADDRESS
~~~

Create validator

~~~bash
quicksilverd tx staking create-validator \
  --amount 50000000uqck \
  --from $QUICKSILVER_WALLET \
  --commission-max-change-rate "0.01" \
  --commission-max-rate "0.2" \
  --commission-rate "0.05" \
  --min-self-delegation "1" \
  --pubkey  $(quicksilverd tendermint show-validator) \
  --moniker $QUICKSILVER_MONIKER \
  --chain-id $QUICKSILVER_CHAIN_ID \
  --gas auto \
  --gas-adjustment 1.3
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
sudo ufw allow ${QUICKSILVER_PORT}656/tcp
sudo ufw enable
~~~

## Usefull commands
### Service commands
check logs

~~~bash
sudo journalctl -u quicksilverd -f
~~~

stop service

~~~bash
sudo systemctl stop quicksilverd
~~~

start service

~~~bash
sudo systemctl start quicksilverd
~~~

restart service

~~~bash
sudo systemctl restart quicksilverd
~~~

### Wallet operation

check balance

~~~bash
quicksilverd query bank balances $QUICKSILVER_WALLET_ADDRESS
~~~

transfer funds

~~~bash
quicksilverd tx bank send $QUICKSILVER_WALLET_ADDRESS <TO_QUICKSILVER_WALLET_ADDRESS> 1000000uqck --gas auto --gas-adjustment 1.3
~~~

lists of wallets

~~~bash
quicksilverd keys list
~~~

create a new wallet

~~~bash
quicksilverd keys add $QUICKSILVER_WALLET
~~~

recover wallet

~~~bash
quicksilverd keys add $QUICKSILVER_WALLET --recover
~~~

delete wallet

~~~bash
quicksilverd keys delete $QUICKSILVER_WALLET
~~~

### Node information

synch info

~~~bash
quicksilverd status 2>&1 | jq .SyncInfo
~~~

node status

~~~bash
curl -s localhost:${QUICKSILVER_PORT}657/status
~~~

node info

~~~bash
quicksilverd status 2>&1 | jq .NodeInfo
~~~

validator info

~~~bash
quicksilverd status 2>&1 | jq .ValidatorInfo
~~~

your node peers

~~~bash
echo $(quicksilverd tendermint show-node-id)'@'$(curl -s ifconfig.me)':'$(cat $HOME/.quicksilverd/config/config.toml | sed -n '/Address to listen for incoming connection/{n;p;}' | sed 's/.*://; s/".*//')
~~~

get currently conected peers lis

~~~bash
curl -sS http://localhost:${QUICKSILVER_PORT}657/net_info | jq -r '.result.peers[] | "\(.node_info.id)@\(.remote_ip):\(.node_info.listen_addr)"' | awk -F ':' '{print $1":"$(NF)}'
~~~

### Voting

~~~bash
quicksilverd tx gov vote 1 yes --from $QUICKSILVER_WALLET --chain-id $QUICKSILVER_CHAIN_ID
~~~

### Staking, Delegation and Rewards

Withdraw all rewards

~~~bash
quicksilverd tx distribution withdraw-all-rewards --from $QUICKSILVER_WALLET --chain-id $QUICKSILVER_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

Withdraw rewards with commision

~~~bash
quicksilverd tx distribution withdraw-rewards $QUICKSILVER_VALOPER_ADDRESS --from $QUICKSILVER_WALLET --commission --chain-id $QUICKSILVER_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

Check balance 

~~~bash
quicksilverd query bank balances $QUICKSILVER_WALLET_ADDRESS
~~~

Delegate stake

~~~bash
quicksilverd tx staking delegate $QUICKSILVER_VALOPER_ADDRESS 1000000uqck --from $QUICKSILVER_WALLET --chain-id $QUICKSILVER_CHAIN_ID --gas=auto --gas-adjustment 1.3
~~~

Redelegate stake to another validator

~~~bash
quicksilverd tx staking redelegate <srcValidatorAddress> <destValidatorAddress> 1000000uqck --from $QUICKSILVER_WALLET --chain-id $QUICKSILVER_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

### Validator operation

Edit validator

~~~bash
quicksilverd tx staking edit-validator \
  --moniker=$NODENAME \
  --identity=<your_keybase_id> \
  --website="<your_website>" \
  --details="<your_validator_description>" \
  --chain-id=$QUICKSILVER_CHAIN_ID \
  --from=$QUICKSILVER_WALLET
~~~

Validator info

~~~bash
quicksilverd status 2>&1 | jq .ValidatorInfo

~~~

Jailing info

~~~bash
quicksilverd q slashing signing-info $(quicksilverd tendermint show-validator)
~~~

Unjail validator

~~~bash
quicksilverd tx slashing unjail --broadcast-mode=block --from $QUICKSILVER_WALLET --chain-id $QUICKSILVER_CHAIN_ID --gas auto --gas-adjustment 1.5
~~~

Consensus state

~~~bash
curl localhost:${QUICKSILVER_PORT}657/consensus_state
~~~

### Delete node

~~~bash
sudo systemctl stop quicksilverd
sudo systemctl disable quicksilverd
sudo rm -rf /etc/systemd/system/quicksilverd*
sudo rm $(which quicksilverd)
sudo rm -rf $HOME/.quicksilverd
sudo rm -fr $HOME/quicksilverd
sed -i "/QUICKSILVER_/d" $HOME/.bash_profile
~~~

