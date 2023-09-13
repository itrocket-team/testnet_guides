<div>
<h1 align="left" style="display: flex;"> Celestia Bridge node Setup for Testnet</h1>
<img src="https://avatars.githubusercontent.com/u/54859940?s=200&v=4"  style="float: right;" width="100" height="100"></img>
</div>

Official documentation:
>- [Validator setup instructions](https://docs.celestia.org/nodes/overview/)

Explorer:
>-  https://celestia.explorers.guru/


## Hardware Requirements
 - Memory: 8 GB RAM
 - CPU: Quad-Core
 - Disk: 250 GB SSD Storage
 - Bandwidth: 1 Gbps for Download/100 Mbps for Upload

## Set up a Celestia bridge node 
### Manual installation

Update packages and Install dependencies

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install curl git wget htop tmux build-essential jq make gcc -y
```

install go

```bash
cd $HOME
VER="1.21.1"
wget "https://golang.org/dl/go$VER.linux-amd64.tar.gz"
sudo tar -C /usr/local -xzf "go$VER.linux-amd64.tar.gz"
rm -rf  "go$VER.linux-amd64.tar.gz"
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile
source $HOME/.bash_profile
go version
```

Download and build binaries

```bash
cd $HOME
rm -rf celestia-node
git clone https://github.com/celestiaorg/celestia-node.git
cd celestia-node/
git checkout tags/v0.11.0-rc12
make build
sudo make install
make cel-key
```

>NOTE: If you are running a bridge node for your validator it is highly recommended to request Mocha testnet tokens as this is the testnet used to test out validator operations.  

### Optional: run the bridge node with a custom key

You can create your key for your node by following the cel-key instructions `you can use your orchestrator address`

~~~bash
cd $HOME/celestia-node
./cel-key add bridge_wallet --keyring-backend test --node.type bridge
~~~

(Optional) Restore an existing cel_key

~~~bash
cd $HOME/celestia-node
./cel-key add bridge_wallet --keyring-backend test --node.type bridge --recover
~~~

Once you start the Bridge Node, a wallet key will be generated for you. You will need to fund that address with Testnet tokens to pay for PayForData transactions. You can find the address by running the following command:

~~~bash
./cel-key list --node.type bridge --keyring-backend test
~~~

Initialize the bridge node

Please enable RPC and gRPC on your validator node, and allow these ports in firewall rules
```bash
celestia bridge init --core.ip http://localhost --core.grpc.port <VALIDATOR_NODE_GRPX_PORT> --core.rpc.port <VALIDATOR_NODE_RPC_PORT> --keyring.accname bridge_wallet
```

Create Service file

```bash
sudo tee /etc/systemd/system/celestia-bridge.service > /dev/null <<EOF
[Unit]
Description=celestia bridge
After=network-online.target

[Service]
User=$USER
ExecStart=$(which celestia) bridge start \
--rpc.port 11058 \
--gateway.port 11059 \
--metrics.tls=false
Restart=on-failure
RestartSec=10
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

Delete bridge node

~~~bash
sudo systemctl stop celestia-bridge
sudo systemctl disable celestia-bridge
sudo rm /etc/systemd/system/celestia-bridge*
rm -rf $HOME/celestia-node $HOME/.celestia-app $HOME/.celestia-bridge-mocha
~~~
