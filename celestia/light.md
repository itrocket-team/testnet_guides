<div>
<h1 align="left" style="display: flex;"> Celestia Light node Setup for Testnet — mamaki</h1>
<img src="https://avatars.githubusercontent.com/u/54859940?s=200&v=4"  style="float: right;" width="100" height="100"></img>
</div>

Official documentation:
>- [Validator setup instructions](https://docs.celestia.org/nodes/overview/)

Explorer:
>-  https://celestia.explorers.guru/


## Hardware Requirements
 - Memory: 2 GB RAM
 - CPU: Single Core
 - Disk: 5 GB SSD Storage
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
cd $HOME
VER="1.19.3"
wget "https://golang.org/dl/go$VER.linux-amd64.tar.gz"
sudo tar -C /usr/local -xzf "go$VER.linux-amd64.tar.gz"
rm -rf  "go$VER.linux-amd64.tar.gz"
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile
source $HOME/.bash_profile
go version
```

Save your cel-key wallet name and import variables into system

~~~bash
echo "export CEL_WALLET="wallet"" >> $HOME/.bash_profile
source $HOME/.bash_profile
~~~

Download and build binaries

```bash
cd $HOME
rm -rf celestia-node
git clone https://github.com/celestiaorg/celestia-node.git
cd celestia-node/
git checkout tags/v0.6.0
make install
make cel-key
```

Add cel_key

~~~bash
cd ~/celestia-node
./cel-key add $CEL_WALLET --keyring-backend test --node.type light
~~~

(Optional) Restore an existing cel_key

~~~bash
cd ~/celestia-node
./cel-key add $CEL_WALLET --keyring-backend test --node.type light --recover
~~~

Initialize the bridge node
>Please enable RPC and gRPC on your validator node, and allow these ports in firewall rules

```bash
celestia light init --core.ip <VALIDATOR_NODE_IP> --core.grpc.port <VALIDATOR_NODE_GRPC_PORT> --core.rpc.port <VALIDATOR_NODE_RPC_PORT> --keyring.accname $CEL_WALLET
```

Create Service file
Replace validator node ip address in `<PUT_VALIDATOR_NODE_IP>` without `<>`

```bash
sudo tee /etc/systemd/system/celestia-light.service > /dev/null <<EOF
[Unit]
Description=celestia light
After=network-online.target

[Service]
User=$USER
ExecStart=$(which celestia) light start
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

## Delete light node 

~~~bash
sudo systemctl stop celestia-light
sudo systemctl disable celestia-light
sudo rm /etc/systemd/system/celestia-light*
rm -rf $HOME/celestia-node $HOME/.celestia-app $HOME/.celestia-light-mocha
~~~
