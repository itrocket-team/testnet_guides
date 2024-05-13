<div>
<h1 align="left" style="display: flex;"> Celestia Bridge node Setup Setup for Celestia Mainnet - celestia</h1>
<img src="https://avatars.githubusercontent.com/u/54859940?s=200&v=4"  style="float: right;" width="100" height="100"></img>
</div>

Official documentation:
>- [Validator setup instructions](https://docs.celestia.org/nodes/bridge-node/)

Explorer:
>-  https://mainnet.itrocket.net/celestia/staking

- [Set up Validator node](https://github.com/itrocket-team/testnet_guides/blob/main/celestia/README.md)
- [Set up Consensus node](https://github.com/itrocket-team/testnet_guides/blob/main/celestia/consensus.md) 
- [Set up Full Storage node](https://github.com/itrocket-team/testnet_guides/blob/main/celestia/full_storage.md)
- [Set up Light node](https://github.com/itrocket-team/testnet_guides/blob/main/celestia/light.md)  

## Hardware Requirements
 - Memory: 16 GB RAM
 - CPU: 6 cores
 - Disk: 10 TB SSD Storage
 - Bandwidth: 1 Gbps

## Set up a Celestia bridge node 
### Manual installation
>In this case Full node and bridge node located on the same server, if you want to install on different servers, change the value `localhost` to your full node IP address

Update packages and Install dependencies

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install curl git wget htop tmux build-essential jq make gcc tar clang pkg-config libssl-dev ncdu -y 
```

install go

```bash
cd ~
! [ -x "$(command -v go)" ] && {
VER="1.21.1"
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

Install Celestia-node

```bash
cd $HOME
rm -rf celestia-node
git clone https://github.com/celestiaorg/celestia-node.git
cd celestia-node/
git checkout tags/v0.13.4
make build 
sudo make install 
make cel-key 
```

Install Celestia-app

```bash
cd $HOME 
rm -rf celestia-app 
git clone https://github.com/celestiaorg/celestia-app.git 
cd celestia-app/ 
APP_VERSION=v1.9.0
git checkout tags/$APP_VERSION -b $APP_VERSION 
make install
```

Config and init app

```bash
celestia bridge init --core.ip <RPC_NODE_IP>
```

Once you start the Bridge Node, a wallet key will be generated for you. You will need to fund that address with Mainnet tokens to pay for PayForBlob transactions. You can find the address by running the following command:

~~~bash
cd $HOME/celestia-node
./cel-key list --node.type bridge --keyring-backend test
~~~

Reset node
~~~bash
celestia bridge unsafe-reset-store
~~~

Add your Full node RPC and gRPC ports

~~~bash
RPC_IP="<PUT_FULL_NODE_RPC_IP>"
RPC_PORT="<PUT_FULL_NODE_RPC_PORT>"
GRPC_PORT="<PUT_FULL_NODE_GRPC_PORT>"
~~~

Create Service file

```bash
sudo tee /etc/systemd/system/celestia-bridge.service > /dev/null <<EOF
[Unit]
Description=celestia bridge
After=network-online.target

[Service]
User=$USER
ExecStart=$(which celestia) bridge start  --core.ip $RPC_IP --core.grpc.port $GRPC_PORT --core.rpc.port $RPC_PORT --metrics.tls=true --metrics --metrics.endpoint otel.celestia.observer --keyring.accname my_celes_key --gateway --gateway.addr 0.0.0.0 --gateway.port 26659 --rpc.addr 0.0.0.0 --rpc.port 26658
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
```

Enable and start service

```bash
sudo systemctl daemon-reload
sudo systemctl enable celestia-bridge
sudo systemctl restart celestia-bridge && sudo journalctl -u celestia-bridge -f
```

This is an RPC call in order to get your node's peerId information. NOTE: You can only generate an auth token after initializing and starting your celestia-node.

~~~bash
NODE_TYPE=bridge
AUTH_TOKEN=$(celestia $NODE_TYPE auth admin)
~~~

Then you can get the peerId of your node with the following curl command:

~~~bash
curl -X POST \
     -H "Authorization: Bearer $AUTH_TOKEN" \
     -H 'Content-Type: application/json' \
     -d '{"jsonrpc":"2.0","id":0,"method":"p2p.Info","params":[]}' \
     http://localhost:26658
~~~

## Usefull commands
Check bridge wallet balance

~~~bash
celestia state balance --node.store ~/.celestia-bridge/
~~~

Check bridge node status
~~~
celestia header sync-state --node.store "/home/celbridge/.celestia-bridge/"
~~~

Get Node ID
~~~
celestia p2p info --node.store ~/.celestia-bridge/
~~~

(Optional) If you want transferring keys to another server, you will need to add permissions

~~~
chmod -R 700 .celestia-bridge
~~~

## Upgrade

Stop bridge node
~~~
sudo systemctl stop celestia-bridge
~~~

Download binary
~~~
cd $HOME
rm -rf celestia-node
git clone https://github.com/celestiaorg/celestia-node.git
cd celestia-node/
git checkout tags/v0.13.4 
make build 
sudo make install 
make cel-key 
~~~

Update
~~~
celestia bridge config-update
~~~

Start bridge node
~~~
sudo systemctl restart celestia-bridge && sudo journalctl -u celestia-bridge -f
~~~


## Delete bridge node

~~~bash
sudo systemctl stop celestia-bridge
sudo systemctl disable celestia-bridge
sudo rm /etc/systemd/system/celestia-bridge*
rm -rf $HOME/celestia-node $HOME/.celestia-app $HOME/.celestia-bridge
~~~
