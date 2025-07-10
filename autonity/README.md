# <img width="35" alt="Screenshot 2024-03-25 at 22 01 42" src="https://github.com/itrocket-team/testnet_guides/assets/153367374/d409ddcd-293b-46cf-9c68-baccbc2f0388"> Autonity Guide: Node Setup + Useful Commands
> Autonity Piccadilly Testnet R6

- [Autonity Utility Tool installation](#-aut-installation)
- [Autonity node installation](#-node-installation)
- [Oracle installation](#-oracle-installation)
- [Validator creation and registration](#-validator-creation-and-registration)
- [Using CAX](#-using-cax)
- [Useful commands](#-useful-commands)
- [Security](#security)
- [Monitoring script](https://github.com/itrocket-team/testnet_guides/tree/main/autonity/monitoring)

_Official docs: https://docs.autonity.org/_

_If you haven’t partiicipated in previous rounds, register here: https://game.autonity.org/getting-started/register.html_

## 🔧 Aut Installation

Prerequisites 
* Git - Follow the official GitHub documentation to install git. (Check if installed: ```git --version```)
* Golang (version 1.21 or later) - https://golang.org/dl (Check if installed: ```go --version``` or ```go version```)
* C compiler (GCC or another) (Check if GCC is installed: ```gcc --version```)
* GNU Make (Check if installed: ```make --version```)

Install go if needed
~~~
cd $HOME
VER="1.21.3"
wget "https://golang.org/dl/go$VER.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$VER.linux-amd64.tar.gz"
rm "go$VER.linux-amd64.tar.gz"
[ ! -f ~/.bash_profile ] && touch ~/.bash_profile
echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
source $HOME/.bash_profile
[ ! -d ~/go/bin ] && mkdir -p ~/go/bin
~~~

Install pipx
~~~
sudo apt install pipx
~~~

Download Autonity Utility Tool (aut)
~~~
pipx install autonity-cli
sudo mv ~/.local/bin/aut /usr/local/bin/aut
~~~

The aut version should be 1.0.0
~~~
aut --version
~~~

Create a configuration file ```.autrc```
~~~
tee <<EOF >/dev/null $HOME/.autrc
[aut]
rpc_endpoint= ws://127.0.0.1:8546
EOF
~~~

## 🔧 Node Installation

### 📋 Hardware Requirements and Ports needed

Requirements:
* OS - Ubuntu 20.04 LTS
* CPU - at least 3.10 GHz with 8 CPU’s, recommended - 3.10 GHz with 16 CPU’s
* RAM - at least 8GB, recommended - 16GB
* Storage - 1024 GB free storage for full nodes and Validators
* Network interface - 200 Mbit/s

Incoming traffic must be allowed on the following:
* ```TCP, UDP 30303``` for node p2p (DEVp2p) communication for transaction gossiping.

You may also choose to allow traffic on the following ports:
* ```TCP 8545``` to make http RPC connections to the node.
* ```TCP 8546``` to make WebSocket RPC connections to the node (for example, if you are operating a validator node and your oracle server is hosted on a separate dedicated machine).
* ```TCP 20203``` for node p2p (DEVp2p) communication for consensus gossiping (required if you are operating a validator node).
* ```TCP 6060``` to export Autonity metrics (recommended but not required)

Download binary
~~~
cd $HOME
rm -rf autonity
git clone https://github.com/autonity/autonity.git && cd autonity 
git checkout tags/v1.0.2-alpha -b v1.0.2-alpha 
make all
sudo mv $HOME/autonity/build/bin/autonity /usr/local/bin/
sudo mv $HOME/autonity/build/bin/ethkey /usr/local/bin/
~~~

Autonity version should be 1.0.2-alpha
~~~
autonity version
~~~

ethkey version should be `1.0.2-alpha-8be1825c-20241209`
~~~
ethkey --version
~~~

Create a directory for autonity working data
~~~
cd $HOME
mkdir autonity-chaindata && mkdir autonity-chaindata/autonity
~~~

Generate autonitykeys
~~~
autonity genAutonityKeys $HOME/autonity-chaindata/autonity/autonitykeys --writeaddress
~~~

Create a directory for treasure.key and oracle.key
~~~
mkdir -p $HOME/.autonity/keystore
~~~

Create oracle and treasure wallets
~~~
aut account new -k $HOME/.autonity/keystore/oracle.key
aut account new -k $HOME/.autonity/keystore/treasure.key
~~~

Add the treasure.key path to the .autrc file
~~~
echo keyfile=$HOME/.autonity/keystore/treasure.key >> $HOME/.autrc
~~~

Create a service file
~~~
sudo tee <<EOF >/dev/null /etc/systemd/system/autonity.service 
[Unit] 
Description=autonity node 
After=network.target 

[Service] 
User=$USER 
Type=simple 
ExecStart=$(which autonity) --datadir $HOME/autonity-chaindata --syncmode full --piccadilly --http --http.addr 0.0.0.0 --http.api aut,eth,net,txpool,web3,admin --http.vhosts \* --ws --ws.addr 127.0.0.1 --ws.api aut,eth,net,txpool,web3,admin --autonitykeys $HOME/autonity-chaindata/autonity/autonitykeys --nat extip:$(curl 2ip.ru) --port 30303 --metrics.port 6060
Restart=on-failure 
LimitNOFILE=65535 

[Install] 
WantedBy=multi-user.target 
EOF
~~~

Enable and start service
~~~
sudo systemctl daemon-reload 
sudo systemctl enable autonity 
sudo systemctl restart autonity && sudo journalctl -u autonity -f
~~~

## 🔧 Oracle Installation

### 📋 Hardware requirements and ports needed
Requirements:
* OS - Ubuntu 20.04 LTS
* CPU - 1.9GHz with 4CPU’s
* RAM - at least 2GB, recommended - 4GB
* Storage - at least 32GB, recommended - 64GB
* Network interface - at least 64Mbit/s, recommended - 128Mbit/s

Incoming traffic must be allowed on the following:
* ```TCP 8546``` to make WebSocket RPC connections to the node.

Download binary
~~~
git clone https://github.com/autonity/autonity-oracle && cd autonity-oracle 
git fetch --all 
git checkout v0.2.3 
make autoracle 
sudo mv build/bin/autoracle /usr/local/bin
~~~

Autoracle version should be v0.2.3
~~~
autoracle version
~~~

Un-comment lines at the end of the ```plugins-conf.yml``` file and add the keys. To get them, follow all of the links and register:
* https://currencyfreaks.com
* https://openexchangerates.org
* https://currencylayer.com
* https://www.exchangerate-api.com

~~~
nano $HOME/autonity-oracle/build/bin/plugins-conf.yml
~~~
Here's an example of how it should look like:

<img width="800" alt="Screenshot 2024-03-22 at 15 55 03" src="https://github.com/itrocket-team/testnet_guides/assets/153367374/ec27ac22-01f4-42a3-b1a8-4fdb46398179">

Create the service file. Insert the key password instead of ```your_password```
~~~
sudo tee <<EOF >/dev/null /etc/systemd/system/autonity_oracle.service
[Unit]  
Description=Autonity Oracle Server  
After=syslog.target network.target  
[Service]  
Type=simple  
ExecStart=$(which autoracle) -key.file="$HOME/.autonity/keystore/oracle.key" -plugin.dir="$HOME/autonity-oracle/build/bin/plugins/" -plugin.conf="$HOME/autonity-oracle/build/bin/plugins-conf.yml" -key.password="your_password" -ws="ws://127.0.0.1:8546"
Restart=on-failure  
RestartSec=5  
[Install]  
WantedBy=multi-user.target
EOF
~~~

Enable and start autoracle
~~~
sudo systemctl daemon-reload
sudo systemctl enable autonity_oracle
sudo systemctl restart autonity_oracle && sudo journalctl -u autonity_oracle -f
~~~

## 👨‍💻 Validator Creation and Registration

Generate the proof and `save` it - you will need it later
~~~
autonity genOwnershipProof --autonitykeys $HOME/autonity-chaindata/autonity/autonitykeys --oraclekeyhex <privatekey_oracle> <tresure_account_address>
~~~

Find ```admin_enode```
~~~
aut node info
~~~

Compute validator address
~~~
aut validator compute-address <admin_enode>
~~~

Insert the address instead of ```validator_address``` to add a variable
~~~
echo "export VALIDATOR_ADDRESS="validator_address"" >> $HOME/.bash_profile
source $HOME/.bash_profile
~~~

Find ```consensus public key```
~~~
ethkey autinspect $HOME/autonity-chaindata/autonity/autonitykeys
~~~

Find ```oracle address```
~~~
aut account info -k $HOME/.autonity/keystore/oracle.key
~~~

Send the transaction to register your validator and save the ```transaction hash```
~~~
aut validator register <enode> <oracle_address> <consensus_pubkey> <proof> | aut tx sign - | aut tx send -
~~~

Check if your validator is in the list 
~~~
aut validator list | grep $VALIDATOR_ADDRESS
~~~

Check validator info
~~~
aut validator info --validator $VALIDATOR_ADDRESS
~~~

Bond NTN to your validator (it will appear in next epoch)
~~~
aut validator bond --validator $VALIDATOR_ADDRESS 1 | aut tx sign - | aut tx send -
~~~

## 💰 Using CAX
### Preparation
Install httpie. ```httpie --version``` should be >= v3.0.0
~~~
sudo apt install httpie
pip install --upgrade httpie
~~~

Get the API key
~~~
MESSAGE=$(jq -nc --arg nonce "$(date +%s%N)" '$ARGS.named')
aut account sign-message $MESSAGE message.sig -k ~/.autonity/keystore/tresure.key > message.sig
echo -n $MESSAGE | https https://cax.piccadilly.autonity.org/api/apikeys api-sig:@/home/autonity/message.sig
~~~

Save the key as a variable
~~~
KEY=<API_KEY>
~~~

### CAX Commands
Deposit USDC to CAX
~~~
aut token transfer --token 0x3a60C03a86eEAe30501ce1af04a6C04Cf0188700 0x11F62c273dD23dbe4D1713C5629fc35713Aa5a94 <USDC_AMOUNT> | aut tx sign - | aut tx send -
~~~

Check the off-chain balance
~~~
https GET https://cax.piccadilly.autonity.org/api/balances/ API-Key:$KEY
~~~
The otput should be as on the screenshot:

<img width="398" alt="Screenshot 2024-03-25 at 20 03 33" src="https://github.com/itrocket-team/testnet_guides/assets/153367374/67124e5a-4783-4842-8efc-04caa7c9ce19">

Get the orderbooks
~~~
https GET https://cax.piccadilly.autonity.org/api/orderbooks/ API-Key:$KEY
~~~

Get the current price (NTN-USDC)
~~~
https GET https://cax.piccadilly.autonity.org/api/orderbooks/NTN-USDC/quote API-Key:$KEY
~~~

Get the current price (ATN-USDC)
~~~
https GET https://cax.piccadilly.autonity.org/api/orderbooks/ATN-USDC/quote API-Key:$KEY
~~~

Trade NTN (limit order)
* pair: ```NTN-USDC``` or ```ATN-USDC```
* side: ```bid``` or ```ask```
~~~
https POST https://cax.piccadilly.autonity.org/api/orders/ API-Key:$KEY pair=NTN-USDC side=bid price=<price> amount=<amount>
~~~

Check the order status (use ```order_id``` from the trade command output)
~~~
https GET https://cax.piccadilly.autonity.org/api/orders/<order_id> API-Key:$KEY
~~~

Check open orders
~~~
https GET https://cax.piccadilly.autonity.org/api/orders/ API-Key:$KEY|jq 'map(select(.status=="open"))'
~~~

Cancel an open order
~~~
curl -X DELETE "https://cax.piccadilly.autonity.org/api/orders/<order_id>" -H "API-Key: $KEY"
~~~

Withdraw from off-chain
~~~
https POST https://cax.piccadilly.autonity.org/api/withdraws/ API-Key:$KEY symbol=NTN  amount=1
~~~

Deposit to off-chain
~~~
aut tx make --to <recipient_address> --value <amount> --ntn | aut tx sign - | aut tx send -
~~~

Query balance of the treasure wallet
~~~
aut account info -k $HOME/.autonity/keystore/treasure.key
~~~

## ⭐ Useful Commands 
Export prived key
~~~
ethkey inspect --private "/home/autonity/.autonity/keystore/tresure.key"
~~~

~~~
ethkey inspect --private "/home/autonity/.autonity/keystore/oracle.key"
~~~

Check node info
~~~
aut node info
~~~

Check balance
~~~
aut account info
# or
aut account info <account_address>
~~~

Query validator list
~~~
aut validator list
~~~

Add a variable with your validator address
~~~
echo "export VALIDATOR_ADDRESS="your_validator_address"" >> $HOME/.bash_profile
source $HOME/.bash_profile
~~~

Check validator info
~~~
aut validator info --validator $VALIDATOR_ADDRESS
~~~

Check if the validator is in committee
~~~
aut protocol get-committee | grep $VALIDATOR_ADDRESS
~~~

Check if the validator is in committee by enode
~~~
aut protocol get-committee-enodes | grep <enode>
~~~

Pause as a validator
~~~
aut validator pause --validator $VALIDATOR_ADDRESS | aut tx sign - | aut tx send -
~~~
>This will return a Validator object. The state property will be 1 (paused). `aut validator info --validator $VALIDATOR_ADDRESS`

Re-activate a validator
~~~
aut validator activate --validator $VALIDATOR_ADDRESS | aut tx sign - | aut tx send -
~~~

Check epoch
~~~
aut protocol epoch-id --rpc-endpoint https://rpc1.piccadilly.autonity.org
~~~

Bond NTN (the bond will appear in next epoch)
~~~
aut validator bond --validator $VALIDATOR_ADDRESS <amount> | aut tx sign - | aut tx send -
~~~

Unjail
~~~
aut validator activate --validator $VALIDATOR_ADDRESS | aut tx sign - | aut tx send -
~~~

## Security

To protect you keys please don`t share your privkeys, mnemonics and follow a basic security rules

>Set up ssh keys for authentication  
>You can use this [guide](https://www.digitalocean.com/community/tutorials/how-to-set-up-ssh-keys-on-ubuntu-20-04) to configure ssh authentication and disable password authentication on your server

Firewall security
Set the default to allow outgoing connections, deny all incoming, allow ssh and node p2p port
~~~
sudo ufw default allow outgoing 
sudo ufw default deny incoming 
sudo ufw allow ssh/tcp 
sudo ufw allow 30303,20203/tcp
sudo ufw enable
~~~


_During the creation of the guide, Autonity official documentation and the guide by lesnik13utsa were used._
