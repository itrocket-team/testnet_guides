<div>
<h1 align="left" style="display: flex;"> Sui Testnet Wave 2 Full Node Setup </h1>
</div>

Official documentation:
>- [Full node setup instructions](https://docs.sui.io/build/devnet)

Explorer:
>-  https://explorer.sui.io/

### Hardware Requirements
Recomended Hardware Requirements
- CPUs: 10 core
- RAM: 32 GB
- Storage: 1 TB

## Set up your sui node
### Manual installation

Update packages and Install dependencies

~~~bash
sudo apt update && sudo apt upgrade -y
sudo apt install make clang pkg-config libssl-dev libclang-dev build-essential git curl ntp jq llvm tmux htop screen unzip cargo cmake tzdata ca-certificates pkg-config cmake -y
~~~

Install yq

~~~bash
wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq &&\
chmod +x /usr/bin/yq
~~~

install rust and cargo

~~~bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
~~~

press 1

~~~bash
source ~/.cargo/env 
rustup update stable
~~~

install go

~~~bash
cd $HOME
VER="1.19.3"
wget "https://golang.org/dl/go$VER.linux-amd64.tar.gz"
sudo tar -C /usr/local -xzf "go$VER.linux-amd64.tar.gz"
rm -rf  "go$VER.linux-amd64.tar.gz"
mkdir -p $HOME/go/bin
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile
source $HOME/.bash_profile
go version
~~~

Download and build binaries

~~~bash
cd $HOME
mkdir $HOME/.sui
rm -rf $HOME/sui
git clone https://github.com/MystenLabs/sui.git
cd sui
git remote add upstream https://github.com/MystenLabs/sui
git fetch upstream
git checkout --track upstream/testnet
cargo build -p sui-node -p sui --release
sudo mv ~/sui/target/release/sui-node $HOME/go/bin/
~~~

Check version

~~~bash
sui-node --version
~~~

Download and update configs

~~~bash
cp crates/sui-config/data/fullnode-template.yaml fullnode.yaml
mv fullnode.yaml $HOME/.sui/fullnode.yaml
wget -qO $HOME/.sui/genesis.blob https://github.com/MystenLabs/sui-genesis/raw/main/testnet/genesis.blob
yq -i ".db-path = \"$HOME/.sui/db\"" $HOME/.sui/fullnode.yaml
yq -i ".genesis.genesis-file-location = \"$HOME/.sui/genesis.blob\"" $HOME/.sui/fullnode.yaml
~~~

Create Service file

~~~bash
sudo tee /etc/systemd/system/suid.service > /dev/null <<EOF
[Unit]
Description=sui
After=network-online.target

[Service]
User=$USER
ExecStart=$(which sui-node) --config-path $HOME/.sui/fullnode.yaml
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
~~~

Enable and start service

~~~bash
sudo systemctl daemon-reload
sudo systemctl enable suid
sudo systemctl restart suid && sudo journalctl -u suid -f
~~~
