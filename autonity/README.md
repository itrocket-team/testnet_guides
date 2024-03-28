# <img width="35" alt="Screenshot 2024-03-25 at 22 01 42" src="https://github.com/itrocket-team/testnet_guides/assets/153367374/d409ddcd-293b-46cf-9c68-baccbc2f0388"> Autonity Guide: Node Setup + Useful Commands
> Autonity Piccadilly Testnet R5

- [Autonity Utility Tool installation](#-aut-installation)
- [Autonity node installation](#-node-installation)
- [Oracle installation](#-oracle-installation)
- [Validator registration](#-validator-registration)
- [Using CAX](#-using-cax)
- [Useful commands](#-useful-commands)
- [Security](#security)
- [Monitoring script](https://github.com/itrocket-team/testnet_guides/tree/main/autonity/monitoring)

_Official docs: https://docs.autonity.org/_

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
pipx install --force git+https://github.com/autonity/aut
sudo mv ~/.local/bin/aut /usr/local/bin/aut
~~~

The aut version should be 0.4.0
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
git clone https://github.com/autonity/autonity && cd autonity 
git checkout tags/v0.13.0 -b v0.13.0 
make autonity 
sudo mv $HOME/autonity/build/bin/autonity /usr/local/bin/
~~~

Autonity version should be 0.13.0
~~~
autonity version
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
ExecStart=$(which autonity) --datadir $HOME/autonity-chaindata --syncmode full --piccadilly --http --http.addr 0.0.0.0 --http.api aut,eth,net,txpool,web3,admin --http.vhosts \* --ws --ws.addr 127.0.0.1 --ws.api aut,eth,net,txpool,web3,admin --autonitykeys $HOME/autonity-chaindata/autonity/autonitykeys --nat extip:$(curl 2ip.ru) --bootnodes "enode://f7a632ab392e93112cbeb7f08a4b71a4dd7a99e3b09906e56a378c1b888de23d215bc8918c2c543c8fd875135cceb9a0b19e1b6fa970095aba2bb02fcdd881a5@65.108.72.253:30303,enode://343972169784dc5400d36bd1e4abbcc54dfba7fa243db1be52aef761598909c0c1a5e5384f6c19c27b57a74d3470034b3f470eacc20e3f1493b08cf7021ee8bf@195.201.197.4:30353"
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
git checkout v0.1.6 
make autoracle 
sudo mv build/bin/autoracle /usr/local/bin
~~~

Autoracle version should be v0.1.6
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
sudo tee <<EOF >/dev/null /etc/systemd/system/antoracle.service
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
sudo systemctl enable antoracle
sudo systemctl restart antoracle && sudo journalctl -u antoracle -f
~~~

## 👨‍💻 Validator Registration
If you haven’t partiicipated in R4, register here: https://game.autonity.org/getting-started/register.html
* Autonity address is the treasure address
* Signature is the hash you should get by running the command:
~~~
aut account sign-message "I have read and agree to comply with the Piccadilly Circus Games Competition Terms and Conditions published on IPFS with CID QmVghJVoWkFPtMBUcCiqs7Utydgkfe19wkLunhS5t57yEu"
~~~

**After tokens appear on your balance, you can continue.**

Download ethkey
~~~
cd $HOME
rm -rf autonity1
git clone https://github.com/autonity/autonity.git autonity1
cd autonity1
make all
sudo mv build/bin/ethkey /usr/local/bin
~~~

The ethkey version should be 0.13.0-4073f247-20240226
~~~
ethkey --version
~~~

Get the oracle private key
~~~
ethkey inspect --private $HOME/.autonity/keystore/oracle.key
~~~

Generate the proof which we'll need later - save it
~~~
autonity genOwnershipProof --autonitykeys $HOME/autonity-chaindata/autonity/autonitykeys --oraclekeyhex <ORACLE_PRIVKEY> <TREASURE_ADDRESS>
~~~

Find ```enode```
~~~
aut node info
~~~

Find validator address
~~~
aut validator compute-address <enode>
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

**Register your validator here**: https://game.autonity.org/awards/register-validator.html

To sign the "validator onboarded" message, do the following:
* Prepare the node private key to sign the transaction
~~~
# extract the private node key and write it into ```autonitykeys.priv```
head -c 64 $HOME/autonity-chaindata/autonity/autonitykeys > $HOME/nodekey.priv
# import the private key
aut account import-private-key $HOME/nodekey.priv
# rename the generated key file
mv $HOME/.autonity/keystore/UTC* $HOME/.autonity/keystore/nodekey.key
~~~
* Sign the transaction
~~~
aut account sign-message "validator onboarded" -k $HOME/.autonity/keystore/nodekey.key
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
aut account sign-message $MESSAGE message.sig -k ~/.autonity/keystore/treasure.key > message.sig
echo -n $MESSAGE | https https://cax.piccadilly.autonity.org/api/apikeys api-sig:@/home/autonity/message.sig
~~~

Save the key as a variable
~~~
KEY=<API_KEY>
~~~

### CAX Commands

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

Get the current price (NTN-USD)
~~~
https GET https://cax.piccadilly.autonity.org/api/orderbooks/NTN-USD/quote API-Key:$KEY
~~~

Get the current price (ATN-USD)
~~~
https GET https://cax.piccadilly.autonity.org/api/orderbooks/ATN-USD/quote API-Key:$KEY
~~~

Trade NTN (limit order)
* pair: ```NTN-USD``` or ```ATN-USD```
* side: ```bid``` or ```ask```
~~~
https POST https://cax.piccadilly.autonity.org/api/orders/ API-Key:$KEY pair=NTN-USD side=bid price=<price> amount=<amount>
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

Check validator info
~~~
aut validator info --validator <validator_address>
~~~

Check if the validator is in committee
~~~
aut protocol get-committee | grep <validator_address>
~~~

Check if the validator is in committee by enode
~~~
aut protocol get-committee-enodes | grep <enode>
~~~

Bond NTN (the bond will appear in next epoch)
~~~
aut validator bond --validator <validator_address> <amount> | aut tx sign - | aut tx send -
~~~

Unjail
~~~
aut validator activate --validator <validator_address> | aut tx sign - | aut tx send -
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
