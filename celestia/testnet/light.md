<div>
<h1 align="left" style="display: flex;"> Celestia Light node Setup for Testnet — mocha-4</h1>
<img src="https://avatars.githubusercontent.com/u/54859940?s=200&v=4"  style="float: right;" width="100" height="100"></img>
</div>

Official documentation:
>- [Validator setup instructions](https://docs.celestia.org/nodes/light-node)

Explorer:
>-  https://testnet.itrocket.net/celestia/staking

- [Set up Validator node](https://github.com/itrocket-team/testnet_guides/blob/main/celestia/testnet/README.md)
- [Set up Consensus node](https://github.com/itrocket-team/testnet_guides/blob/main/celestia/testnet/consensus.md)
- [Set up Full Storage node](https://github.com/itrocket-team/testnet_guides/blob/main/celestia/testnet/full_storage.md) 
- [Set up Bridge node](https://github.com/itrocket-team/testnet_guides/blob/main/celestia/testnet/bridge.md)   

## Hardware Requirements
 - Memory: 500 MB RAM (minimum)
 - CPU: Single Core
 - Disk: 50 GB SSD Storage
 - Bandwidth: 56 Kbps for Download/56 Kbps for Upload

## Set up a Celestia light node 
### Manual installation

Update packages and Install dependencies

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install curl git wget htop tmux build-essential jq make gcc tar clang pkg-config libssl-dev ncdu -y
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

Download and build binaries

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

Config and init app

```bash
celestia light init --p2p.network mocha
```

Create wallet
>You will need to fund that address with Testnet tokens to pay for PayForBlob transactions.

~~~
KEY_NAME="my_celes_key"
cd ~/celestia-node
./cel-key add $KEY_NAME --keyring-backend test --node.type light --p2p.network mocha
~~~

(Optional) Restore an existing cel_key

~~~bash
KEY_NAME="my_celes_key"
cd ~/celestia-node
./cel-key add $KEY_NAME --keyring-backend test --node.type light  --p2p.network mocha --recover
~~~

You can find the address by running the following command in the celestia-node directory
~~~
cd $HOME/celestia-node
./cel-key list --node.type light --keyring-backend test --p2p.network mocha
~~~

Create Service file
Replace FULL node ip, RPC and gRPC ports
~~~
CORE_IP="<PUT_FULL_NODE_RPC_IP>"
CORE_RPC_PORT="<PUT_FULL_NODE_RPC_PORT>"
CORE_GRPC_PORT="<PUT_FULL_NODE_GRPC_PORT>"
KEY_NAME="my_celes_key"
~~~
```bash
sudo tee /etc/systemd/system/celestia-light.service > /dev/null <<EOF
[Unit]
Description=celestia light
After=network-online.target

[Service]
User=$USER
ExecStart=$(which celestia) light start \
--core.ip $CORE_IP \
--core.rpc.port $CORE_RPC_PORT \
--core.grpc.port $CORE_GRPC_PORT \
--keyring.accname $KEY_NAME \
--gateway --gateway.addr 0.0.0.0 \
--gateway.port 26659 \
--rpc.addr 0.0.0.0 \
--rpc.port 26658 \
--p2p.network mocha \
--metrics.tls=true \
--metrics --metrics.endpoint otel.celestia-mocha.com
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
sudo systemctl enable celestia-light
sudo systemctl restart celestia-light && sudo journalctl -u celestia-light -f
```

## Usefull commands
Check Light Node wallet balance

~~~bash
celestia state balance --node.store ~/.celestia-light-mocha-4/
~~~

Check Light node status
~~~
celestia header sync-state --node.store ~/.celestia-light-mocha-4/
~~~

Submit a blob to Celestia
~~~
AUTH_TOKEN=$(celestia light auth admin --p2p.network mocha)
celestia blob submit 0x42690c204d39600fddd3 'gm' --token $AUTH_TOKEN
~~~

(Optional) If you want transferring keys to another server, you will need to add permissions

~~~
chmod -R 700 .celestia-light-mocha-4
~~~

## Delete light node 

~~~bash
sudo systemctl stop celestia-light
sudo systemctl disable celestia-light
sudo rm /etc/systemd/system/celestia-light*
rm -rf $HOME/celestia-node $HOME/.celestia-app $HOME/.celestia-light-mocha
~~~
