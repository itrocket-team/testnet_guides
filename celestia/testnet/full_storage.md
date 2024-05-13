<div>
<h1 align="left" style="display: flex;"> Celestia Full Storage node Setup Setup for Mocha Race Testnet — mocha-4</h1>
<img src="https://avatars.githubusercontent.com/u/54859940?s=200&v=4"  style="float: right;" width="100" height="100"></img>
</div>

Official documentation:
>- [Full Storage node setup instructions](https://docs.celestia.org/nodes/full-storage-node)

Explorer:
>-  https://testnet.itrocket.net/celestia/staking

- [Set up Validator node](https://github.com/itrocket-team/testnet_guides/blob/main/celestia/testnet/README.md)
- [Set up Consensus node](https://github.com/itrocket-team/testnet_guides/blob/main/celestia/testnet/consensus.md) 
- [Set up Bridge node](https://github.com/itrocket-team/testnet_guides/blob/main/celestia/testnet/bridge.md) 
- [Set up Light node](https://github.com/itrocket-team/testnet_guides/blob/main/celestia/testnet/light.md)    

## Hardware Requirements
 - Memory: 4 GB RAM (minimum)
 - CPU: 6 cores
 - Disk: 10 TB SSD Storage
 - Bandwidth: 1 Gbps for Download/1 Gbps for Upload

## Set up a Celestia bridge node 
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
git checkout tags/v0.13.5 
make build 
sudo make install 
make cel-key 
```

Create wallet
>You will need to fund that address with Testnet tokens to pay for PayForBlob transactions.

~~~
./cel-key add my_celes_key --keyring-backend test --node.type full --p2p.network mocha
~~~

(Optional) Restore an existing cel_key

~~~bash
cd ~/celestia-node
./cel-key add my_celes_key --keyring-backend test --node.type full --recover
~~~

You can find the address by running the following command in the celestia-node directory
~~~
cd $HOME/celestia-node
./cel-key list --node.type full --keyring-backend test --p2p.network mocha
~~~

Config and init app
~~~
celestia full init --keyring.accname my_celes_key --p2p.network mocha-4
~~~

If keys have not been created previously, Once you start the Bridge Node, a wallet key will be generated for you. You will need to fund that address with Testnet tokens to pay for PayForBlob transactions. You can find the address by running the following command:

~~~bash
cd $HOME/celestia-node
./cel-key list --node.type bridge --keyring-backend test --p2p.network mocha
~~~

Replace Consensus node ip, RPC and gRPC ports
~~~
CORE_IP="<PUT_RPC_IP>"
CORE_RPC_PORT="<PUT_RPC_PORT>"
CORE_GRPC_PORT="<PUT_GRPC_PORT>"
KEY_NAME="my_celes_key"
~~~

Create Service file
```bash
sudo tee /etc/systemd/system/celestia-full.service > /dev/null <<EOF
[Unit]
Description=celestia bridge
After=network-online.target

[Service]
User=$USER
ExecStart=$(which celestia) full start \
--core.ip $CORE_IP \
--core.rpc.port $CORE_RPC_PORT \
--core.grpc.port $CORE_GRPC_PORT \
--gateway \
--gateway.addr "0.0.0.0" \
--gateway.port "26659" \
--rpc.addr "0.0.0.0" \
--rpc.port "26658" \
--p2p.network mocha \
--keyring.accname $KEY_NAME \
--metrics.tls=true --metrics --metrics.endpoint otel.celestia-mocha.com
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
sudo systemctl enable celestia-full
sudo systemctl restart celestia-full && sudo journalctl -u celestia-full -f
```

This is an RPC call in order to get your node's peerId information. NOTE: You can only generate an auth token after initializing and starting your celestia-node.

~~~bash
NODE_TYPE=full
AUTH_TOKEN=$(celestia $NODE_TYPE auth admin --p2p.network mocha)
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

Check balance
~~~
celestia state balance --node.store ~/.celestia-full-mocha-4/
~~~

Reset node
~~~bash
celestia full unsafe-reset-store --p2p.network mocha
~~~

(Optional) If you want transferring keys to another server, you will need to add permissions

~~~
chmod -R 700 .celestia-full-mocha-4
~~~

## Submitting a blob using curl

~~~
export CELESTIA_NODE_AUTH_TOKEN=$(celestia full auth admin --p2p.network mocha)
~~~

Post your blob with:
~~~
curl -H "Content-Type: application/json" -H "Authorization: Bearer $CELESTIA_NODE_AUTH_TOKEN" -X POST --data '{"id": 1,
  "jsonrpc": "2.0",
  "method": "blob.Submit",
  "params": [
    [
      {
        "namespace": "AAAAAAAAAAAAAAAAAAAAAAAAAAECAwQFBgcICRA=",
        "data": "VGhpcyBpcyBhbiBleGFtcGxlIG9mIHNvbWUgYmxvYiBkYXRh",
        "share_version": 0,
        "commitment": "AD5EzbG0/EMvpw0p8NIjMVnoCP4Bv6K+V6gjmwdXUKU="
      }
    ],
    0.002
  ]
}' 127.0.0.1:26658
~~~

## Upgrade

Stop Full Storage node
~~~
sudo systemctl stop celestia-full
~~~

Download binary
~~~
cd $HOME
rm -rf celestia-node
git clone https://github.com/celestiaorg/celestia-node.git
cd celestia-node/
git checkout tags/v0.13.5 
make build 
sudo make install 
make cel-key 
~~~

Update
~~~
celestia full config-update --p2p.network mocha
~~~

Start full storage node
~~~
sudo systemctl restart celestia-full && sudo journalctl -u celestia-full -f
~~~


## Delete Full Storage node

~~~bash
sudo systemctl stop celestia-full
sudo systemctl disable celestia-full
sudo rm /etc/systemd/system/celestia-full*
rm -rf $HOME/celestia-node $HOME/.celestia-app $HOME/.celestia-full-blockspacerace-0
~~~
