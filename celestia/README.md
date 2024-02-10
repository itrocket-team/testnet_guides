# <img src="https://avatars.githubusercontent.com/u/54859940?s=200&v=4" style="border-radius: 50%; vertical-align: middle;" width="35" height="35" /> Celestia Node Setup Guide
> For Celestia Testnet — mocha-4

Celestia is a new modular blockchain technology that powers, scales and secures Web3 applications. In this guide we will share our installation commands of a Celestia Validator node with the help of <img src="https://itrocket.net//whiteLogoCrop.ico" style="border-radius: 50%; vertical-align: middle;" width="15" height="15" /> ITRocket Team  services. 

Guides for bridge, full or light node can be found here:
| Setup Full node           | [Link](https://github.com/itrocket-team/testnet_guides/blob/main/celestia/full.md) |
|---------------------------|-------------------------------------|
| Setup Bridge node         | [Link](https://github.com/itrocket-team/testnet_guides/blob/main/celestia/bridge.md) |
| Setup Light node          | [Link](https://github.com/itrocket-team/testnet_guides/blob/main/celestia/light.md) |  
| Setup Monitoring          | [Link](https://github.com/itrocket-team/testnet_guides/blob/main/celestia/tenderduty.md) |  

<details><summary> <h2>📋 Requirements </h2></summary>
<p>  Before we get started make sure that your server (computer) meets the minimum requirements:</p>
<ul>
<li><b>Memory</b>: 8 GB RAM</li>
<li><b>CPU</b>: 6 cores</li>
<li><b>Disk</b>: 500 GB SSD Storage</li>
<li><b>Bandwidth</b>: 1 Gbps for Download/1 Gbps for Upload</details></li>
</ul>



  
## 🔧 Setup Validator node (Manual installation) 
1. **Prerequisites.** Ensure system packages are up-to-date and install dependencies:
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install curl git wget htop tmux build-essential jq make gcc -y
  ```
2. **Set Environment Variables.** Type your wallet and moniker `<YOUR_WALLET_NAME>` `<YOUR_MONIKER>` without `<>`, save and import variables into system
>
```bash
CELESTIA_PORT=11
echo "export WALLET="<YOUR_WALLET_NAME>"" >> $HOME/.bash_profile
echo "export MONIKER="<YOUR_MONIKER>"" >> $HOME/.bash_profile
echo "export CHAIN_ID="mocha-4"" >> $HOME/.bash_profile
echo "export CELESTIA_PORT="${CELESTIA_PORT}"" >> $HOME/.bash_profile
source $HOME/.bash_profile
```
3. **Install go**
```bash
cd ~
! [ -x "$(command -v go)" ] && {
VER="1.21.3"
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
4. **Download and build binaries**
```bash
cd $HOME 
rm -rf celestia-app 
git clone https://github.com/celestiaorg/celestia-app.git 
cd celestia-app/ 
APP_VERSION=v1.6.0 
git checkout tags/$APP_VERSION -b $APP_VERSION 
make install
```
5. **Setup the P2P networks**
```bash
cd $HOME
rm -rf networks
git clone https://github.com/celestiaorg/networks.git
```
6. **Config and init app**
```bash
celestia-appd config node tcp://localhost:${CELESTIA_PORT}657
celestia-appd config keyring-backend os
celestia-appd config chain-id $CHAIN_ID
celestia-appd init $MONIKER --chain-id $CHAIN_ID
```
7. **Download genesis**
```bash
wget -O $HOME/.celestia-app/config/genesis.json https://testnet-files.itrocket.net/celestia/genesis.json
wget -O $HOME/.celestia-app/config/addrbook.json https://testnet-files.itrocket.net/celestia/addrbook.json
```
8. **Set seeds and peers**
>You can find more peers here: https://itrocket.net/services/testnet/celestia/#peer
```bash
SEEDS="5d0bf034d6e6a8b5ee31a2f42f753f1107b3a00e@celestia-testnet-seed.itrocket.net:11656"
PEERS="daf2cecee2bd7f1b3bf94839f993f807c6b15fbf@celestia-testnet-peer.itrocket.net:11656"
sed -i -e 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.celestia-app/config/config.toml
```
9. **Set custom ports in app.toml file**
```bash
sed -i.bak -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${CELESTIA_PORT}317\"%;
s%^address = \":8080\"%address = \":${CELESTIA_PORT}080\"%;
s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:${CELESTIA_PORT}090\"%; 
s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:${CELESTIA_PORT}091\"%; 
s%^address = \"0.0.0.0:8545\"%address = \"0.0.0.0:${CELESTIA_PORT}545\"%; 
s%^ws-address = \"0.0.0.0:8546\"%ws-address = \"0.0.0.0:${CELESTIA_PORT}546\"%" $HOME/.celestia-app/config/app.toml
```
10. **Set custom ports in config.toml file**
```bash
sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${CELESTIA_PORT}658\"%; 
s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://0.0.0.0:${CELESTIA_PORT}657\"%; 
s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${CELESTIA_PORT}060\"%;
s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${CELESTIA_PORT}656\"%;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${CELESTIA_PORT}656\"%;
s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${CELESTIA_PORT}660\"%" $HOME/.celestia-app/config/config.toml
```
11. **Config pruning**
```bash
sed -i -e "s/^pruning *=.*/pruning = \"nothing\"/" $HOME/.celestia-app/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.celestia-app/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.celestia-app/config/app.toml
```
12. **Configure EXTERNAL_ADDRESS**
~~~bash
EXTERNAL_ADDRESS=$(wget -qO- eth0.me)
sed -i.bak -e "s/^external-address = \"\"/external-address = \"$EXTERNAL_ADDRESS:26656\"/" $HOME/.celestia-app/config/config.toml
~~~
13. **Set minimum gas price, enable prometheus and disable indexing**
```bash
sed -i -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0.002utia\"/" $HOME/.celestia-app/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.celestia-app/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.celestia-app/config/config.toml
```
14. **Reset network**
~~~bash 
celestia-appd tendermint unsafe-reset-all --home $HOME/.celestia-app 
~~~
15. **Create Service file**
```bash
sudo tee /etc/systemd/system/celestia-appd.service > /dev/null <<EOF
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
16. **Download snapshot**
>You can find more services on our website: https://itrocket.net/services/testnet/celestia/
~~~bash
curl https://testnet-files.itrocket.net/celestia/snap_celestia.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.celestia-app
~~~
17. **Enable and start service**
```bash
sudo systemctl daemon-reload
sudo systemctl enable celestia-appd
sudo systemctl restart celestia-appd && sudo journalctl -u celestia-appd -f
```

## 💰 Create wallet

### new flags should be added in the new mocha-4 testnet 
>`--evm-address` This flag should contain a 0x EVM address.  
 
<details>
  <summary>How do I create a new Ethereum wallet?</summary>
<blockquote> Visit https://metamask.io/ and locate the extension that is compatible with your browser. 
Click and install the appropriate extension.
Once downloaded and installed, click on the extension icon and follow the prompts to create and confirm your password.  
Next, accept the term of use and give the extension the go-ahead to reveal your seed phrase. It is advisable to store multiple copies of these secret words in secure locations. Once you have backed up your seed phrase, the account registration process is complete.  
To view your ETH or ERC-20 address, navigate and select the Deposit Ether Directly tab. Then click on View Account to see and copy your ERC-20 address.
</details>

1. **Create a new Celestia wallet.** Don’t forget to save the mnemonic. 
```bash
celestia-appd keys add $WALLET
``` 

(optional) Recover wallet, use the following command
```bash
celestia-appd keys add $WALLET --recover
```

2. **Fund your wallet** 
Before creating a validator, you need to fund your wallet, go to the [Celestia discord server](https://discord.gg/celestiacommunity) and  and navigate to faucet channel. `please fund your orchestrator address too, if you want to run Celestia bridge, Full or Light node` 
```bash
$request <YOUR_WALLET_ADDRESS>
```

3. **Save wallets and validator addresses**
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

## Create validator 👨‍💻
  
> **Note**
> Before creating a validator, you need to check the balance and make sure that the node is synched

0.1 **Check Sync status**
 Once your node is fully synced, the output will be `false`
```bash
celestia-appd status 2>&1 | jq .SyncInfo
```
0.2 **Check your balance**
```bash
celestia-appd query bank balances $WALLET_ADDRESS
```
1. **Create validator** 
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
  
2. (optional) You can add `--website` `--security-contact` `--identity` `--details` flags if needed**
```bash
--website <YOUR_SITE_URL> \
--security-contact <YOUR_CONTACT> \
--identity <KEYBASE_IDENTITY> \
--details <YOUR_VALIDATOR_DETAILS>
```

### Monitoring 🔍
We'll also provide information on how to set up node monitoring, which is an important aspect of ensuring its smooth operation.  
If you want to have set up a monitoring and alert system use [our Celestia nodes monitoring guide with tenderduty](https://github.com/itrocket-team/testnet_guides/blob/main/celestia/tenderduty.md)  
Stay tuned!
  
### Security 🔒
To protect you keys please don't share your privkey, mnemonic and follow a basic security rules

### Set up ssh keys for authentication 🔑
You can use this [guide](https://www.digitalocean.com/community/tutorials/how-to-set-up-ssh-keys-on-ubuntu-20-04) to configure ssh authentication and disable password authentication on your server

### Firewall security 🛡️
Set the default to allow outgoing connections, deny all incoming, allow ssh and node p2p port
```bash
sudo ufw default allow outgoing 
sudo ufw default deny incoming 
sudo ufw allow ssh/tcp 
sudo ufw allow ${CELESTIA_PORT}656,2121/tcp
sudo ufw allow 2121/udp
sudo ufw enable
```

If you want to open access to RPC and gRPC ports, please add these rulles
~~~bash
IP_ADDRESS="<PUT_IP_ADDRESS>"
sudo ufw allow from $IP_ADDRESS to any port ${CELESTIA_PORT}090
sudo ufw allow from $IP_ADDRESS to any port ${CELESTIA_PORT}657
~~~

## Congratulations 🎉
You have successfully installed and set up a Celestia validator node! Join the Celestia community and start contributing to the network. You can also check out useful commands below. 

<details>
  <summary> <h2>Useful commands ⭐ </h2> </summary>
  <h3>Service commands </h3>
  
check logs
```bash
sudo journalctl -u celestia-appd -f
```
  
stop service
```bash
sudo systemctl stop celestia-appd
```
start service
```bash
sudo systemctl start celestia-appd
```

restart service
```bash
sudo systemctl restart celestia-appd
```

<h3> Wallet operation </h3>

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

<h3>Node information </h3>

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
sudo systemctl stop celestia-appd
sudo systemctl disable celestia-appd
sudo rm -rf /etc/systemd/system/celestia-appd*
sudo systemctl daemon-reload
sudo rm $(which celestia-appd)
sudo rm -rf $HOME/.celestia-app
sudo rm -fr $HOME/celestia-app
sed -i "/CELESTIA_/d" $HOME/.bash_profile
```
</details>

<img src="https://itrocket.net/logo.svg" style="width: 100%; fill: white" />


