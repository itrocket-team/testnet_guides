<div>
<h1 align="left" style="display: flex;"> Crowd Control Node Setup for Testnet — testnet3</h1>
<img src="https://avatars.githubusercontent.com/u/42208331?s=200&v=4"  style="float: right;" width="100" height="100"></img>
</div>

Official documentation:
>- [Validator setup instructions](https://github.com/DecentralCardGame/Testnet)

Explorer:
>-  https://testnet.itrocket.net/cardchain/staking


## Set up your node
### Manual installation

Update packages and Install dependencies

~~~bash
sudo apt update && sudo apt upgrade -y
sudo apt install curl git wget htop tmux build-essential jq make lz4 gcc -y
~~~

Replace your moniker `<YOUR_MONIKER>` without `<>`, save and import variables into system

~~~bash
CARDCHAIN_PORT=31
echo "export WALLET="wallet"" >> $HOME/.bash_profile
echo "export MONIKER="<YOUR_MONIKER>"" >> $HOME/.bash_profile
echo "export CARDCHAIN_CHAIN_ID="Testnet3"" >> $HOME/.bash_profile
echo "export CARDCHAIN_PORT="${CARDCHAIN_PORT}"" >> $HOME/.bash_profile
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
wget https://github.com/DecentralCardGame/Cardchain/releases/download/v0.81/CARDCHAIN_latest_linux_amd64.tar.gz
tar xzf CARDCHAIN_latest_linux_amd64.tar.gz
chmod 775 Cardchaind
sudo mv Cardchaind /usr/local/bin
sudo rm CARDCHAIN_latest_linux_amd64.tar.gz
~~~

Config and init app

~~~bash
Cardchaind config node tcp://localhost:${CARDCHAIN_PORT}657
Cardchaind config keyring-backend test
Cardchaind config chain-id $CARDCHAIN_CHAIN_ID
Cardchaind init $MONIKER --chain-id $CARDCHAIN_CHAIN_ID
~~~

Download genesis and addrbook

~~~bash
curl -s https://files.itrocket.net/testnet/cardchain/genesis.json > $HOME/.Cardchain/config/genesis.json
curl -s https://files.itrocket.net/testnet/cardchain/addrbook.json > $HOME/.Cardchain/config/addrbook.json
~~~

Set seeds and peers

~~~bash
SEEDS=""
PEERS="56d11635447fa77163f31119945e731c55e256a4@45.136.28.158:26658, 72b662370d2296a22cad1eecbe447012dd3c2a89@65.21.151.93:36656,b17b995cf2fcff579a4b4491ca8e05589c2d8627@195.54.41.130:36656,d692726a2bdeb0e371b42ef4fa6dfaa47a1c5ad4@38.242.250.15:26656,f1d8bede57e24cb6e5258da1e4f17b1c5b0a0ca3@173.249.45.161:26656,959f9a742058ff591a5359130a392bcccf5f11a5@5.189.165.127:18656,56ff9898493787bf566c68ede80febb76a45eedc@23.88.77.188:20004,96821b39e381e293a251c860c58a2d9e85435363@49.12.245.142:13656,638240b94ac3da7d8c8df8ae4da72a7d920acf2a@173.212.245.44:26656,b41f7ce40c863ee7e20801e6cd3a97237a79114a@65.21.53.39:16656,5d2bb1fed3f93aed0ba5c96bff4b0afb31d9501d@130.185.119.10:26656"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.Cardchain/config/config.toml
~~~

Set gustom ports in app.toml file

~~~bash
sed -i.bak -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${CARDCHAIN_PORT}317\"%;
s%^address = \":8080\"%address = \":${CARDCHAIN_PORT}080\"%;
s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:${CARDCHAIN_PORT}090\"%; 
s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:${CARDCHAIN_PORT}091\"%; 
s%^address = \"0.0.0.0:8545\"%address = \"0.0.0.0:${CARDCHAIN_PORT}545\"%; 
s%^ws-address = \"0.0.0.0:8546\"%ws-address = \"0.0.0.0:${CARDCHAIN_PORT}546\"%" $HOME/.Cardchain/config/app.toml
~~~

Set gustom ports in config.toml file

~~~bash
sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${CARDCHAIN_PORT}658\"%; 
s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://0.0.0.0:${CARDCHAIN_PORT}657\"%; 
s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${CARDCHAIN_PORT}060\"%;
s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${CARDCHAIN_PORT}656\"%;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${CARDCHAIN_PORT}656\"%;
s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${CARDCHAIN_PORT}660\"%" $HOME/.Cardchain/config/config.toml
~~~

Config pruning

~~~bash
sed -i -e "s/^pruning *=.*/pruning = \"nothing\"/" $HOME/.Cardchain/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.Cardchain/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.Cardchain/config/app.toml
~~~

Set minimum gas price, enable prometheus and disable indexing

~~~bash
sed -i 's/minimum-gas-prices =.*/minimum-gas-prices = "0.0ubpf"/g' $HOME/.Cardchain/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.Cardchain/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.Cardchain/config/config.toml
~~~

Reset chain data
~~~bash
Cardchaind unsafe-reset-all --home $HOME/.Cardchain
~~~

Create Service file

~~~bash
sudo tee /etc/systemd/system/Cardchaind.service > /dev/null <<EOF
[Unit]
Description=cardchain
After=network-online.target

[Service]
User=$USER
ExecStart=$(which Cardchaind) start --home $HOME/.Cardchain
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
sudo systemctl enable Cardchaind
sudo systemctl restart Cardchaind && sudo journalctl -u Cardchaind -f
~~~

Download Snapshot # Updated every 4h

~~~bash
sudo systemctl stop Cardchaind
cp $HOME/.Cardchain/data/priv_validator_state.json $HOME/.Cardchain/priv_validator_state.json.backup
rm -rf $HOME/.Cardchain/data
curl https://files.itrocket.net/testnet/cardchain/snap_cardchain.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.Cardchain
mv $HOME/.Cardchain/priv_validator_state.json.backup $HOME/.Cardchain/data/priv_validator_state.json
sudo systemctl restart Cardchaind && sudo journalctl -u Cardchaind -f
~~~

## Create wallet
To create a new wallet, use the following command. don’t forget to save the mnemonic

~~~bash
Cardchaind keys add $WALLET
~~~

(optional) To restore exexuting wallet, use the following command

~~~bash
Cardchaind keys add $WALLET --recover
~~~

Save wallet and validator address

~~~bash
WALLET_ADDRESS=$(Cardchaind keys show $WALLET -a)
VALOPER_ADDRESS=$(Cardchaind keys show $WALLET --bech val -a)
echo "export WALLET_ADDRESS="${WALLET_ADDRESS} >> $HOME/.bash_profile
echo "export VALOPER_ADDRESS="${VALOPER_ADDRESS} >> $HOME/.bash_profile
source $HOME/.bash_profile
~~~


## Create validator

before creating a validator, you need to check the balance and make sure that the node is synched

Check Sync status, once your node is fully synced, the output from above will say `false`

~~~bash
Cardchaind status 2>&1 | jq .SyncInfo
~~~

Check your balance

~~~bash
Cardchaind query bank balances $WALLET_ADDRESS
~~~

Create validator

~~~bash
Cardchaind tx staking create-validator \
  --amount 1000000ubpf \
  --from $WALLET \
  --commission-max-change-rate "0.01" \
  --commission-max-rate "0.2" \
  --commission-rate "0.05" \
  --min-self-delegation "1" \
  --pubkey  $(Cardchaind tendermint show-validator) \
  --moniker $MONIKER \
  --chain-id $CARDCHAIN_CHAIN_ID
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
sudo ufw allow ${CARDCHAIN_PORT}656/tcp
sudo ufw enable
~~~

## Usefull commands
### Service commands
check logs

~~~bash
sudo journalctl -u Cardchaind -f
~~~

stop service

~~~bash
sudo systemctl stop Cardchaind
~~~

start service

~~~bash
sudo systemctl start Cardchaind
~~~

restart service

~~~bash
sudo systemctl restart Cardchaind
~~~

### Wallet operation

check balance

~~~bash
Cardchaind query bank balances $WALLET_ADDRESS
~~~

transfer funds

~~~bash
Cardchaind tx bank send $WALLET_ADDRESS <TO_WALLET_ADDRESS> 1000000ubpf --gas auto --gas-adjustment 1.3
~~~

lists of wallets

~~~bash
Cardchaind keys list
~~~

create a new wallet

~~~bash
Cardchaind keys add $WALLET
~~~

recover wallet

~~~bash
Cardchaind keys add $WALLET --recover
~~~

delete wallet

~~~bash
Cardchaind keys delete $WALLET
~~~

### Node information

synch info

~~~bash
Cardchaind status 2>&1 | jq .SyncInfo
~~~

node status

~~~bash
curl -s localhost:${CARDCHAIN_PORT}657/status
~~~

node info

~~~bash
Cardchaind status 2>&1 | jq .NodeInfo
~~~

validator info

~~~bash
Cardchaind status 2>&1 | jq .ValidatorInfo
~~~

your node peers

~~~bash
echo $(Cardchaind tendermint show-node-id)'@'$(curl -s ifconfig.me)':'$(cat $HOME/.Cardchain/config/config.toml | sed -n '/Address to listen for incoming connection/{n;p;}' | sed 's/.*://; s/".*//')
~~~

get currently conected peers lis

~~~bash
curl -sS http://localhost:${CARDCHAIN_PORT}657/net_info | jq -r '.result.peers[] | "\(.node_info.id)@\(.remote_ip):\(.node_info.listen_addr)"' | awk -F ':' '{print $1":"$(NF)}'
~~~

### Voting

~~~bash
Cardchaind tx gov vote 1 yes --from $WALLET --chain-id $CARDCHAIN_CHAIN_ID
~~~

### Staking, Delegation and Rewards

Withdraw all rewards

~~~bash
Cardchaind tx distribution withdraw-all-rewards --from $WALLET --chain-id $CARDCHAIN_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

Withdraw rewards with commision

~~~bash
Cardchaind tx distribution withdraw-rewards $VALOPER_ADDRESS --from $WALLET --commission --chain-id $CARDCHAIN_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

Check balance 

~~~bash
Cardchaind query bank balances $WALLET_ADDRESS
~~~

Delegate stake

~~~bash
Cardchaind tx staking delegate $VALOPER_ADDRESS 1000000ubpf --from $WALLET --chain-id $CARDCHAIN_CHAIN_ID --gas=auto --gas-adjustment 1.3
~~~

Redelegate stake to another validator

~~~bash
Cardchaind tx staking redelegate <srcValidatorAddress> <destValidatorAddress> 1000000ubpf --from $WALLET --chain-id $CARDCHAIN_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

### Validator operation

Edit validator

~~~bash
Cardchaind tx staking edit-validator \
  --moniker=$NODENAME \
  --identity=<your_keybase_id> \
  --website="<your_website>" \
  --details="<your_validator_description>" \
  --chain-id=$CARDCHAIN_CHAIN_ID \
  --from=$WALLET
~~~

Validator info

~~~bash
Cardchaind status 2>&1 | jq .ValidatorInfo

~~~

Jailing info

~~~bash
Cardchaind q slashing signing-info $(Cardchaind tendermint show-validator)
~~~

Unjail validator

~~~bash
Cardchaind tx slashing unjail --broadcast-mode=block --from $WALLET --chain-id $CARDCHAIN_CHAIN_ID --gas auto --gas-adjustment 1.5
~~~

Consensus state

~~~bash
curl localhost:${CARDCHAIN_PORT}657/consensus_state
~~~

### Delete node

~~~bash
sudo systemctl stop Cardchaind
sudo systemctl disable Cardchaind
sudo rm -rf /etc/systemd/system/Cardchaind*
sudo rm $(which Cardchaind)
sudo rm -rf $HOME/.Cardchain
sudo rm -fr $HOME/cardchain-chain
sed -i "/CARDCHAIN_/d" $HOME/.bash_profile
~~~

