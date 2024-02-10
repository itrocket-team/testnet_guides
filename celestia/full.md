<div>
<h1 align="left" style="display: flex;"> Celestia Consensus Full node Setup for Mocha-4 Testnet — mocha-4</h1>
<img src="https://avatars.githubusercontent.com/u/54859940?s=200&v=4"  style="float: right;" width="100" height="100"></img>
</div>

Official documentation:
>- [Validator setup instructions](https://docs.celestia.org/nodes/consensus-node)

Explorer:
>-  https://testnet.itrocket.net/celestia/staking

- [Set up Bridge node](https://github.com/itrocket-team/testnet_guides/blob/main/celestia/bridge.md) 
- [Set up Validator node](https://github.com/itrocket-team/testnet_guides/blob/main/celestia/README.md)
- [Set up Light node](https://github.com/itrocket-team/testnet_guides/blob/main/celestia/light.md)  

## Set up Full node 
### Hardware Requirements
- Memory: 8 GB RAM
- CPU: Quad-Core
- Disk: 250 GB SSD Storage
- Bandwidth: 1 Gbps for Download/1 Gbps for Upload

### Manual installation

Update packages and Install dependencies

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install curl git wget htop tmux build-essential jq make gcc tar clang pkg-config libssl-dev ncdu aria2 -y 
```

install go

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

Replace your `<YOUR_NODE_NAME>` without `<>`, save and import variables into system
>

```bash
CELESTIA_PORT=11
echo "export NODENAME="<YOUR_NODE_NAME>"" >> $HOME/.bash_profile
echo "export CHAIN_ID="mocha-4"" >> $HOME/.bash_profile
echo "export CELESTIA_PORT="${CELESTIA_PORT}"" >> $HOME/.bash_profile
source $HOME/.bash_profile
```

Install celestia-app

~~~bash
cd $HOME 
rm -rf celestia-app 
git clone https://github.com/celestiaorg/celestia-app.git 
cd celestia-app/ 
APP_VERSION=v1.6.0 
git checkout tags/$APP_VERSION -b $APP_VERSION 
make install 
~~~

Setup the P2P networks

~~~bash
cd $HOME
rm -rf networks
git clone https://github.com/celestiaorg/networks.git
~~~

Config and init app

~~~bash
celestia-appd config node tcp://localhost:${CELESTIA_PORT}657
celestia-appd config chain-id $CHAIN_ID
celestia-appd init $NODENAME --chain-id $CHAIN_ID
~~~

Copy the genesis.json file

~~~bash
cp $HOME/networks/mocha-4/genesis.json $HOME/.celestia-app/config 
~~~

Set seeds and peers:
>You can find more peers here: https://itrocket.net/services/testnet/celestia/#peer
~~~bash
SEEDS=$(curl -sL https://raw.githubusercontent.com/celestiaorg/networks/master/mocha-4/seeds.txt | head -c -1 | tr '\n' ',')
echo $SEEDS
sed -i.bak -e "s/^seeds *=.*/seeds = \"$SEEDS\"/" $HOME/.celestia-app/config/config.toml
~~~
~~~bash
PERSISTENT_PEERS=$(curl -sL https://raw.githubusercontent.com/celestiaorg/networks/master/mocha-4/peers.txt | head -c -1 | tr '\n' ',')
echo $PERSISTENT_PEERS
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$PERSISTENT_PEERS\"/" $HOME/.celestia-app/config/config.toml
~~~

Set gustom ports in app.toml file

```bash
sed -i.bak -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${CELESTIA_PORT}317\"%;
s%^address = \":8080\"%address = \":${CELESTIA_PORT}080\"%;
s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:${CELESTIA_PORT}090\"%; 
s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:${CELESTIA_PORT}091\"%; 
s%^address = \"0.0.0.0:8545\"%address = \"0.0.0.0:${CELESTIA_PORT}545\"%; 
s%^ws-address = \"0.0.0.0:8546\"%ws-address = \"0.0.0.0:${CELESTIA_PORT}546\"%" $HOME/.celestia-app/config/app.toml
```

Set gustom ports in config.toml file

```bash
sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${CELESTIA_PORT}658\"%; 
s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://0.0.0.0:${CELESTIA_PORT}657\"%; 
s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${CELESTIA_PORT}060\"%;
s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${CELESTIA_PORT}656\"%;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${CELESTIA_PORT}656\"%;
s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${CELESTIA_PORT}660\"%" $HOME/.celestia-app/config/config.toml
```

Config pruning, enable indexer

```bash
sed -i -e "s/^pruning *=.*/pruning = \"nothing\"/" $HOME/.celestia-app/config/app.toml
sed -i -e "s/^indexer *=.*/indexer = \"kv\"/" $HOME/.celestia-app/config/config.toml
```

Configure EXTERNAL_ADDRESS

~~~bash
EXTERNAL_ADDRESS=$(wget -qO- eth0.me)
sed -i.bak -e "s/^external-address = \"\"/external-address = \"$EXTERNAL_ADDRESS:${CELESTIA_PORT}656\"/" $HOME/.celestia-app/config/config.toml
~~~

Set minimum gas price, enable prometheus

```bash
sed -i -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0.002utia\"/" $HOME/.celestia-app/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.celestia-app/config/config.toml
```

reset network

~~~bash 
celestia-appd tendermint unsafe-reset-all --home $HOME/.celestia-app 
~~~
    
Create Service file

```bash
sudo tee /etc/systemd/system/celestia-appd.service > /dev/null <<EOF
[Unit]
Description=celestia-full
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

Download snapshot

~~~bash
cd $HOME
rm -rf ~/.celestia-app/data
mkdir -p ~/.celestia-app/data
SNAP_NAME=$(curl -s https://snaps.qubelabs.io/celestia/ | \
    egrep -o ">mocha-4.*tar" | tr -d ">")
aria2c -x 16 -s 16 -o celestia-snap.tar "https://snaps.qubelabs.io/celestia/${SNAP_NAME}"
tar xf celestia-snap.tar -C ~/.celestia-app/data/
~~~


Enable and start service

```bash
sudo systemctl daemon-reload
sudo systemctl enable celestia-appd
sudo systemctl restart celestia-appd && sudo journalctl -u celestia-appd -f
```

Check Sync status, once your node is fully synced, the output from above will say `false`

~~~bash
celestia-appd status 2>&1 | jq .SyncInfo
~~~

### Firewall security
Set the default to allow outgoing connections, deny all incoming, allow ssh and node p2p port

~~~bash
sudo ufw default allow outgoing 
sudo ufw default deny incoming 
sudo ufw allow ssh/tcp 
sudo ufw allow ${CELESTIA_PORT}656/tcp
sudo ufw enable
~~~

Please open access to RPC and gRPC ports for your Full node

~~~bash
LIGHT_NODE_IP_ADDRESS=<IP_ADDRESS>
BRIDGE_NODE_IP_ADDRESS=<IP_ADDRESS>
sudo ufw allow from $LIGHT_NODE_IP_ADDRESS to any port ${CELESTIA_PORT}090
sudo ufw allow from $LIGHT_NODE_IP_ADDRESS to any port ${CELESTIA_PORT}657
sudo ufw allow from $BRIDGE_NODE_IP_ADDRESS to any port ${CELESTIA_PORT}090
sudo ufw allow from $BRIDGE_NODE_IP_ADDRESS to any port ${CELESTIA_PORT}657
~~~

## Delete full node 

~~~bash
sudo systemctl stop celestia-appd
sudo systemctl disable celestia-appd
sudo rm /etc/systemd/system/celestia-appd*
rm -rf $HOME/networks $HOME/celestia-app
~~~
