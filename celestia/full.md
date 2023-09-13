<div>
<h1 align="left" style="display: flex;"> Celestia Full node Setup for Testnet - mocha-4</h1>
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
 - Bandwidth: 1 Gbps for Download/1 Gbps for Upload

## Set up a Celestia Full node 
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

Save your cel-key wallet name and import variables into system

~~~bash
echo "export CEL_WALLET="wallet_1"" >> $HOME/.bash_profile
source $HOME/.bash_profile
~~~

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

Add cel_key `you can use your orchestrator address`

~~~bash
cd ~/celestia-node
./cel-key add $CEL_WALLET --keyring-backend test --node.type full
~~~

(Optional) Restore an existing cel_key

~~~bash
cd ~/celestia-node
./cel-key add $CEL_WALLET --keyring-backend test --node.type full --recover
~~~

Initialize the full node
>Please enable RPC and gRPC on your validator node, and allow these ports in firewall rules

```bash
celestia full init --core.ip <RPC_NODE_IP> --core.grpc.port <RPC_NODE_GRPC_PORT> --core.rpc.port <RPC_NODE_RPC_PORT> --keyring.accname $CEL_WALLET
```

Create Service file
Replace validator node ip address in `<PUT_VALIDATOR_NODE_IP>` without `<>`

```bash
sudo tee /etc/systemd/system/celestia-full.service > /dev/null <<EOF
[Unit]
Description=celestia full
After=network-online.target

[Service]
User=$USER
ExecStart=$(which celestia) full start
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

## Delete full node 

~~~bash
sudo systemctl stop celestia-full
sudo systemctl disable celestia-full
sudo rm /etc/systemd/system/celestia-full*
rm -rf $HOME/celestia-node $HOME/.celestia-app $HOME/.celestia-full-mocha
~~~
