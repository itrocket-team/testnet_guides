<div>
<h1 align="left" style="display: flex;"> Celestia Full node Setup for Testnet — mamaki</h1>
<img src="https://github.com/marutyan/patterns/blob/main/logos/celestia.png"  style="float: right;" width="100" height="100"></img>
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
celestia full init
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
ExecStart=$HOME/go/bin/celestia full start  --core.remote tcp://<PUT_VALIDATOR_NODE_IP>:11657 --core.grpc tcp://<PUT_VALIDATOR_NODE_IP>:11090
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

(Optional) Once you start the Full Node, a wallet key will be generated for you. You will need to fund that address with testnet tokens to pay for PayForData transactions. You can find the address by running the following command:

```bash
./cel-key list --node.type full --keyring-backend test
```
(Optional) run the full storage node with a custom key

```bash
sudo tee /etc/systemd/system/celestia-full.service > /dev/null <<EOF
[Unit]
Description=celestia full
After=network-online.target

[Service]
User=$USER
ExecStart=$HOME/go/bin/celestia full start  --core.remote tcp://<PUT_VALIDATOR_NODE_IP>:11657 -->  --keyring.accname <PUT_NAME_OF_GUSTOM_KEY>
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
```
Retart service

```bash
sudo systemctl daemon-reload
sudo systemctl restart celestia-full && sudo journalctl -u celestia-full -f
```
