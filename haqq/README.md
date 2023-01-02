<div>
<h1 align="left" style="display: flex;"> Haqq Node Setup for Testnet — haqq_54211-3</h1>
<img src="https://islamiccoin.net/logo.svg"  style="float: right;" width="100" height="100"></img>
</div>

Official documentation:
>- [Validator setup instructions](https://github.com/haqq-network/validators-contest)

Explorer:
>-  https://haqq.explorers.guru/validators


## Set up your Haqq node
### Manual installation

Update packages and Install dependencies

~~~bash
sudo apt update && sudo apt upgrade -y
sudo apt install curl git wget htop tmux build-essential jq make lz4 gcc -y
~~~

Replace your moniker `<YOUR_MONIKER>` without `<>`, save and import variables into system

~~~bash
HAQQ_PORT=19
echo "export WALLET="wallet"" >> $HOME/.bash_profile
echo "export MONIKER="<YOUR_MONIKER>"" >> $HOME/.bash_profile
echo "export HAQQ_CHAIN_ID="haqq_54211-3"" >> $HOME/.bash_profile
echo "export HAQQ_PORT="${HAQQ_PORT}"" >> $HOME/.bash_profile
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
rm -rf haqq
git clone https://github.com/haqq-network/haqq.git
cd haqq
git checkout v1.3.0
make install
~~~
Config and init app

~~~bash
haqqd config node tcp://localhost:${HAQQ_PORT}657
haqqd config keyring-backend test
haqqd config chain-id $HAQQ_CHAIN_ID
haqqd init $MONIKER --chain-id $HAQQ_CHAIN_ID
~~~

Download genesis and addrbook

~~~bash
cd $HOME/.haqqd/config && rm -rf genesis.json && wget https://github.com/haqq-network/validators-contest/raw/master/genesis.json
~~~

Set seeds and peers

~~~bash
seeds="62bf004201a90ce00df6f69390378c3d90f6dd7e@seed2.testedge2.haqq.network:26656,23a1176c9911eac442d6d1bf15f92eeabb3981d5@seed1.testedge2.haqq.network:26656"
peers="b3ce1618585a9012c42e9a78bf4a5c1b4bad1123@65.21.170.3:33656,952b9d918037bc8f6d52756c111d0a30a456b3fe@213.239.217.52:29656,85301989752fe0ca934854aecc6379c1ccddf937@65.109.49.111:26556,d648d598c34e0e58ec759aa399fe4534021e8401@109.205.180.81:29956,f2c77f2169b753f93078de2b6b86bfa1ec4a6282@141.95.124.150:20116,eaa6d38517bbc32bdc487e894b6be9477fb9298f@78.107.234.44:45656,37513faac5f48bd043a1be122096c1ea1c973854@65.108.52.192:36656,d2764c55607aa9e8d4cee6e763d3d14e73b83168@66.94.119.47:26656,fc4311f0109d5aed5fcb8656fb6eab29c15d1cf6@65.109.53.53:26656,297bf784ea674e05d36af48e3a951de966f9aa40@65.109.34.133:36656,bc8c24e9d231faf55d4c6c8992a8b187cdd5c214@65.109.17.86:32656"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.haqqd/config/config.toml
~~~

Set gustom ports in app.toml file

~~~bash
sed -i.bak -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${HAQQ_PORT}317\"%;
s%^address = \":8080\"%address = \":${HAQQ_PORT}080\"%;
s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:${HAQQ_PORT}090\"%; 
s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:${HAQQ_PORT}091\"%; 
s%^address = \"0.0.0.0:8545\"%address = \"0.0.0.0:${HAQQ_PORT}545\"%; 
s%^ws-address = \"0.0.0.0:8546\"%ws-address = \"0.0.0.0:${HAQQ_PORT}546\"%" $HOME/.haqqd/config/app.toml
~~~

Set gustom ports in config.toml file

~~~bash
sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${HAQQ_PORT}658\"%; 
s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://0.0.0.0:${HAQQ_PORT}657\"%; 
s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${HAQQ_PORT}060\"%;
s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${HAQQ_PORT}656\"%;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${HAQQ_PORT}656\"%;
s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${HAQQ_PORT}660\"%" $HOME/.haqqd/config/config.toml
~~~

Config pruning

~~~bash
sed -i -e "s/^pruning *=.*/pruning = \"nothing\"/" $HOME/.haqqd/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.haqqd/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.haqqd/config/app.toml
~~~

Set minimum gas price, enable prometheus and disable indexing

~~~bash
sed -i 's/minimum-gas-prices =.*/minimum-gas-prices = "0.0aISLM"/g' $HOME/.haqqd/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.haqqd/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.haqqd/config/config.toml
~~~

Reset chain data
~~~bash
haqqd tendermint unsafe-reset-all --home $HOME/.haqqd
~~~

Create Service file

~~~bash
sudo tee /etc/systemd/system/haqqd.service > /dev/null <<EOF
[Unit]
Description=haqq
After=network-online.target

[Service]
User=$USER
ExecStart=$(which haqqd) start --home $HOME/.haqqd
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
~~~

(OPTIONAL) State Sync

In order not to wait for a long synchronization, you can use our StateSync guide:
> https://github.com/marutyan/testnet_guides/blob/main/haqq/statesync.md


Enable and start service

~~~bash
sudo systemctl daemon-reload
sudo systemctl enable haqqd
sudo systemctl restart haqqd && sudo journalctl -u haqqd -f
~~~

## Create wallet
To create a new wallet, use the following command. don’t forget to save the mnemonic

~~~bash
haqqd keys add $WALLET
~~~

(optional) To restore exexuting wallet, use the following command

~~~bash
haqqd keys add $WALLET --recover
~~~

Save wallet and validator address

~~~bash
WALLET_ADDRESS=$(haqqd keys show $WALLET -a)
~~~
~~~bash
VALOPER_ADDRESS=$(haqqd keys show $WALLET --bech val -a)
~~~
~~~bash
echo "export WALLET_ADDRESS="${WALLET_ADDRESS} >> $HOME/.bash_profile
echo "export VALOPER_ADDRESS="${VALOPER_ADDRESS} >> $HOME/.bash_profile
source $HOME/.bash_profile
~~~

Fund your wallet 
Before creating a validator, you need to fund your wallet, go to the [Haqq faucet page](https://testedge2.haqq.network/) and  and claim test tockens


## Create validator

before creating a validator, you need to check the balance and make sure that the node is synched

Check Sync status, once your node is fully synced, the output from above will say `false`

~~~bash
haqqd status 2>&1 | jq .SyncInfo
~~~

Check your balance

~~~bash
haqqd query bank balances $WALLET_ADDRESS
~~~

Create validator

~~~bash
haqqd tx staking create-validator \
  --amount 999000000aISLM \
  --from $WALLET \
  --commission-max-change-rate "0.01" \
  --commission-max-rate "0.2" \
  --commission-rate "0.05" \
  --min-self-delegation "1" \
  --pubkey  $(haqqd tendermint show-validator) \
  --moniker $MONIKER \
  --chain-id $HAQQ_CHAIN_ID
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
sudo ufw allow ${HAQQ_PORT}656/tcp
sudo ufw enable
~~~

## Usefull commands
### Service commands
check logs

~~~bash
sudo journalctl -u haqqd -f
~~~

stop service

~~~bash
sudo systemctl stop haqqd
~~~

start service

~~~bash
sudo systemctl start haqqd
~~~

restart service

~~~bash
sudo systemctl restart haqqd
~~~

### Wallet operation

check balance

~~~bash
haqqd query bank balances $WALLET_ADDRESS
~~~

transfer funds

~~~bash
haqqd tx bank send $WALLET_ADDRESS <TO_WALLET_ADDRESS> 1000000000aISLM --gas auto --gas-adjustment 1.3
~~~

lists of wallets

~~~bash
haqqd keys list
~~~

create a new wallet

~~~bash
haqqd keys add $WALLET
~~~

recover wallet

~~~bash
haqqd keys add $WALLET --recover
~~~

delete wallet

~~~bash
haqqd keys delete $WALLET
~~~

### Node information

synch info

~~~bash
haqqd status 2>&1 | jq .SyncInfo
~~~

node status

~~~bash
curl -s localhost:${HAQQ_PORT}657/status
~~~

node info

~~~bash
haqqd status 2>&1 | jq .NodeInfo
~~~

validator info

~~~bash
haqqd status 2>&1 | jq .ValidatorInfo
~~~

your node peers

~~~bash
echo $(haqqd tendermint show-node-id)'@'$(curl -s ifconfig.me)':'$(cat $HOME/.haqqd/config/config.toml | sed -n '/Address to listen for incoming connection/{n;p;}' | sed 's/.*://; s/".*//')
~~~

get currently conected peers lis

~~~bash
curl -sS http://localhost:${HAQQ_PORT}657/net_info | jq -r '.result.peers[] | "\(.node_info.id)@\(.remote_ip):\(.node_info.listen_addr)"' | awk -F ':' '{print $1":"$(NF)}'
~~~

### Voting

~~~bash
haqqd tx gov vote 1 yes --from $WALLET --chain-id $HAQQ_CHAIN_ID
~~~

### Staking, Delegation and Rewards

Withdraw all rewards

~~~bash
haqqd tx distribution withdraw-all-rewards --from $WALLET --chain-id $HAQQ_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

Withdraw rewards with commision

~~~bash
haqqd tx distribution withdraw-rewards $VALOPER_ADDRESS --from $WALLET --commission --chain-id $HAQQ_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

Check balance 

~~~bash
haqqd query bank balances $WALLET_ADDRESS
~~~

Delegate stake

~~~bash
haqqd tx staking delegate $VALOPER_ADDRESS 1000000000aISLM --from $WALLET --chain-id $HAQQ_CHAIN_ID --gas=auto --gas-adjustment 1.3
~~~

Redelegate stake to another validator

~~~bash
haqqd tx staking redelegate <srcValidatorAddress> <destValidatorAddress> 1000000000aISLM --from $WALLET --chain-id $HAQQ_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

### Validator operation

Edit validator

~~~bash
haqqd tx staking edit-validator \
  --moniker=$NODENAME \
  --identity=<your_keybase_id> \
  --website="<your_website>" \
  --details="<your_validator_description>" \
  --chain-id=$HAQQ_CHAIN_ID \
  --from=$WALLET
~~~

Validator info

~~~bash
haqqd status 2>&1 | jq .ValidatorInfo

~~~

Jailing info

~~~bash
haqqd q slashing signing-info $(haqqd tendermint show-validator)
~~~

Unjail validator

~~~bash
haqqd tx slashing unjail --broadcast-mode=block --from $WALLET --chain-id $HAQQ_CHAIN_ID --gas auto --gas-adjustment 1.5
~~~

Consensus state

~~~bash
curl localhost:${HAQQ_PORT}657/consensus_state
~~~

### Delete node

~~~bash
sudo systemctl stop haqqd
sudo systemctl disable haqqd
sudo rm -rf /etc/systemd/system/haqqd*
sudo rm $(which haqqd)
sudo rm -rf $HOME/.haqqd
sudo rm -fr $HOME/haqq
sed -i "/HAQQ_/d" $HOME/.bash_profile
~~~

