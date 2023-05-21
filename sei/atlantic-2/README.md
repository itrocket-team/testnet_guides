<div>
<h1 align="left" style="display: flex;"> Sei Node Setup for Testnet — atlantic-2</h1>
<img src="https://github.com/sei-protocol/sei-chain/raw/master/assets/SeiLogo.png"  style="float: right;" width="100" height="100"></img>
</div>

Official documentation:
>- [Validator setup instructions](https://docs.seinetwork.io/nodes-and-validators/seinami-incentivized-testnet/joining-incentivized-testnet)

Explorer:
>-  https://sei.explorers.guru/


## Hardware Requirements
### Recommended Hardware Requirements 
 - 8 Cores (modern CPU's)
 - 32GB RAM
 - 1TB of storage (SSD or NVME)

## Set up your sei node
### Manual installation

Update packages and Install dependencies

~~~bash
sudo apt update && sudo apt upgrade -y
sudo apt install curl git wget htop tmux build-essential jq make lz4 gcc -y
~~~

Replace your wallet and moniker `<YOUR_WALLET_NAME>` `<YOUR_MONIKER>` without `<>`, save and import variables into system

~~~bash
SEI_PORT=14
echo "export WALLET="<YOUR_WALLET_NAME>"" >> $HOME/.bash_profile
echo "export MONIKER="<YOUR_MONIKER>"" >> $HOME/.bash_profile
echo "export SEI_CHAIN_ID="atlantic-2"" >> $HOME/.bash_profile
echo "export SEI_PORT="${SEI_PORT}"" >> $HOME/.bash_profile
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
rm -rf sei-chain
git clone https://github.com/sei-protocol/sei-chain.git
cd sei-chain
git checkout  2.0.47beta
make install
~~~
Config and init app

~~~bash
seid config node tcp://localhost:${SEI_PORT}657
seid config chain-id $SEI_CHAIN_ID
seid init $MONIKER --chain-id $SEI_CHAIN_ID
~~~

Download genesis and addrbook

~~~bash
wget -O $HOME/.sei/config/genesis.json https://raw.githubusercontent.com/sei-protocol/testnet/main/atlantic-2/genesis.json
~~~

Set seeds and peers

~~~bash
SEEDS="f97a75fb69d3a5fe893dca7c8d238ccc0bd66a8f@sei-seed.p2p.brocha.in:30514"
PEERS="59f519729903be6d82fe0286890077b1ce6a8622@rpc.sei.ppnv.space:06656"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.sei/config/config.toml
~~~

Set gustom ports in app.toml file

~~~bash
sed -i.bak -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${SEI_PORT}317\"%;
s%^address = \":8080\"%address = \":${SEI_PORT}080\"%;
s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:${SEI_PORT}090\"%; 
s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:${SEI_PORT}091\"%; 
s%^address = \"0.0.0.0:8545\"%address = \"0.0.0.0:${SEI_PORT}545\"%; 
s%^ws-address = \"0.0.0.0:8546\"%ws-address = \"0.0.0.0:${SEI_PORT}546\"%" $HOME/.sei/config/app.toml
~~~

Set gustom ports in config.toml file

~~~bash
sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${SEI_PORT}658\"%; 
s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://0.0.0.0:${SEI_PORT}657\"%; 
s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${SEI_PORT}060\"%;
s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${SEI_PORT}656\"%;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${SEI_PORT}656\"%;
s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${SEI_PORT}660\"%" $HOME/.sei/config/config.toml
~~~

Config pruning

~~~bash
sed -i -e "s/^pruning *=.*/pruning = \"nothing\"/" $HOME/.sei/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.sei/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.sei/config/app.toml
~~~

Set minimum gas price, enable prometheus and disable indexing

~~~bash
sed -i 's/minimum-gas-prices =.*/minimum-gas-prices = "0.0usei,0.001ibc/6D45A5CD1AADE4B527E459025AC1A5AEF41AE99091EF3069F3FEAACAFCECCD21"/g' $HOME/.sei/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.sei/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.sei/config/config.toml
~~~

Create Service file

~~~bash
sudo tee /etc/systemd/system/seid.service > /dev/null <<EOF
[Unit]
Description=sei
After=network-online.target

[Service]
User=$USER
ExecStart=$(which seid) start --home $HOME/.sei
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
sudo systemctl enable seid
sudo systemctl restart seid && sudo journalctl -u seid -f
~~~

## (Optional) quick-sync with snapshot

Syncing from Genesis can take a long time, depending on your hardware. Using this method you can synchronize your Sei node very quickly by downloading a recent snapshot of the blockchain from our website:
- https://itrocket.net/services/testnet/sei/#snap

## Create wallet
To create a new wallet, use the following command. don’t forget to save the mnemonic

~~~bash
seid keys add $WALLET
~~~

(optional) To restore exexuting wallet, use the following command

~~~bash
seid keys add $WALLET --recover
~~~

Save wallet and validator address

~~~bash
WALLET_ADDRESS=$(seid keys show $WALLET -a)
~~~
~~~bash
SEI_VALOPER_ADDRESS=$(seid keys show $WALLET --bech val -a)
~~~
~~~bash
echo "export WALLET_ADDRESS="${WALLET_ADDRESS} >> $HOME/.bash_profile
echo "export SEI_VALOPER_ADDRESS="${SEI_VALOPER_ADDRESS} >> $HOME/.bash_profile
source $HOME/.bash_profile
~~~

Fund your wallet 
Before creating a validator, you need to fund your wallet, go to the [Sei discord server](https://discord.gg/sei) and  and navigate to `atlantic-1-faucet` channel

~~~bash
!faucet <YOUR_WALLET_ADDRESS>
~~~

## Create validator

before creating a validator, you need to check the balance and make sure that the node is synched

Check Sync status, once your node is fully synced, the output from above will say `false`

~~~bash
seid status 2>&1 | jq .SyncInfo
~~~

Check your balance

~~~bash
seid query bank balances $WALLET_ADDRESS
~~~

Create validator

~~~bash
seid tx staking create-validator \
  --amount 1000000usei \
  --from $WALLET \
  --commission-max-change-rate "0.01" \
  --commission-max-rate "0.2" \
  --commission-rate "0.05" \
  --min-self-delegation "1" \
  --pubkey  $(seid tendermint show-validator) \
  --moniker $MONIKER \
  --chain-id $SEI_CHAIN_ID
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
sudo ufw allow ${SEI_PORT}656/tcp
sudo ufw enable
~~~

## Usefull commands
### Service commands
check logs

~~~bash
sudo journalctl -u seid -f
~~~

stop service

~~~bash
sudo systemctl stop seid
~~~

start service

~~~bash
sudo systemctl start seid
~~~

restart service

~~~bash
sudo systemctl restart seid
~~~

### Wallet operation

check balance

~~~bash
seid query bank balances $WALLET_ADDRESS
~~~

transfer funds

~~~bash
seid tx bank send $WALLET_ADDRESS <TO_WALLET_ADDRESS> 1000000usei --gas auto --gas-adjustment 1.3
~~~

lists of wallets

~~~bash
seid keys list
~~~

create a new wallet

~~~bash
seid keys add $WALLET
~~~

recover wallet

~~~bash
seid keys add $WALLET --recover
~~~

delete wallet

~~~bash
seid keys delete $WALLET
~~~

### Node information

synch info

~~~bash
seid status 2>&1 | jq .SyncInfo
~~~

node status

~~~bash
curl -s localhost:${SEI_PORT}657/status
~~~

node info

~~~bash
seid status 2>&1 | jq .NodeInfo
~~~

validator info

~~~bash
seid status 2>&1 | jq .ValidatorInfo
~~~

your node peers

~~~bash
echo $(seid tendermint show-node-id)'@'$(curl -s ifconfig.me)':'$(cat $HOME/.sei/config/config.toml | sed -n '/Address to listen for incoming connection/{n;p;}' | sed 's/.*://; s/".*//')
~~~

get currently conected peers lis

~~~bash
curl -sS http://localhost:${SEI_PORT}657/net_info | jq -r '.result.peers[] | "\(.node_info.id)@\(.remote_ip):\(.node_info.listen_addr)"' | awk -F ':' '{print $1":"$(NF)}'
~~~

### Voting

~~~bash
seid tx gov vote 1 yes --from $WALLET --chain-id $SEI_CHAIN_ID
~~~

### Staking, Delegation and Rewards

Withdraw all rewards

~~~bash
seid tx distribution withdraw-all-rewards --from $WALLET --chain-id $SEI_CHAIN_ID
~~~

Withdraw rewards with commision

~~~bash
seid tx distribution withdraw-rewards $SEI_VALOPER_ADDRESS --from $WALLET --commission --chain-id $SEI_CHAIN_ID
~~~

Check balance 

~~~bash
seid query bank balances $WALLET_ADDRESS
~~~

Delegate stake

~~~bash
seid tx staking delegate $SEI_VALOPER_ADDRESS 1000000usei --from $WALLET --chain-id $SEI_CHAIN_ID --gas=auto --gas-adjustment 1.3
~~~

Redelegate stake to another validator

~~~bash
seid tx staking redelegate <srcValidatorAddress> <destValidatorAddress> 1000000usei --from $WALLET --chain-id $SEI_CHAIN_ID --gas auto --gas-adjustment 1.3
~~~

### Validator operation

Edit validator

~~~bash
seid tx staking edit-validator \
  --moniker=$NODENAME \
  --identity=<your_keybase_id> \
  --website="<your_website>" \
  --details="<your_validator_description>" \
  --chain-id=$SEI_CHAIN_ID \
  --from=$WALLET
~~~

Validator info

~~~bash
seid status 2>&1 | jq .ValidatorInfo

~~~

Jailing info

~~~bash
seid q slashing signing-info $(seid tendermint show-validator)
~~~

Unjail validator

~~~bash
seid tx slashing unjail --broadcast-mode=block --from $WALLET --chain-id $SEI_CHAIN_ID --gas auto --gas-adjustment 1.5
~~~

Consensus state

~~~bash
curl localhost:${SEI_PORT}657/consensus_state
~~~

### Delete node

~~~bash
sudo systemctl stop seid
sudo systemctl disable seid
sudo rm -rf /etc/systemd/system/seid*
sudo rm $(which seid)
sudo rm -rf $HOME/.sei
sudo rm -fr $HOME/sei-chain
sed -i "/SEI_/d" $HOME/.bash_profile
~~~

