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
sudo apt install curl git wget htop tmux build-essential jq make gcc -y
```

install go

```bash
cd $HOME
VER="1.18.3"
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
git checkout tags/v0.3.0-rc2
make install
make cel-key
```

Initialize the bridge node

```bash
celestia light init
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
ExecStart=$HOME/go/bin/celestia light start  --core.remote tcp://<PUT_VALIDATOR_NODE_IP>:11657 --core.grpc tcp://<PUT_VALIDATOR_NODE_IP>:11090
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
