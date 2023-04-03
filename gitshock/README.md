<div>
<h1 align="left" style="display: flex;"> Gitshock Finance Node Setup for Testnet </h1>
<img src="https://avatars.githubusercontent.com/u/96646938?s=200&v=4"  style="float: right;" width="100" height="100"></img>
</div>

Official documentation:
>- [Validator setup instructions](https://docs.gitshock.com/gitshock-testnet-overview/gitshock-chain-evm-testnet)

## Hardware Requirements
### Recommended Hardware Requirements 
 - CPU 4 Core (2.1 Ghz or Above)
 - 4GB of RAM (Recomended 8-16GB)
 - 250GB - 500GB of disk space

## Set up your node
### Manual installation

Update packages and Install dependencies

~~~bash
sudo apt update && sudo apt upgrade -y
sudo apt install curl git wget htop tmux build-essential jq make lz4 gcc micro gcc g++ pkg-config llvm-dev libclang-dev clang cmake -y
~~~

Install Go-Ethereum

~~~bash
sudo add-apt-repository -y ppa:ethereum/ethereum
sudo apt update -y
sudo apt install ethereum -y
sudo apt update -y
~~~

Make sure to replace `<YOUR_MONIKER>` and `<YOUR_FEE_ADDRESS>` address with your own Ethereum address where you want to receive the transaction tips

~~~bash
echo "export MONIKER="<YOUR_MONIKER>"" >> $HOME/.bash_profile
echo "export FEE_ADDRESS="<YOUR_FEE_ADDRESS>"" >> $HOME/.bash_profile
source $HOME/.bash_profile
~~~

install go

~~~bash
cd $HOME
if ! [ -x "$(command -v go)" ]; then
VER="1.19.3"
wget "https://golang.org/dl/go$VER.linux-amd64.tar.gz"
sudo tar -C /usr/local -xzf "go$VER.linux-amd64.tar.gz"
rm -rf  "go$VER.linux-amd64.tar.gz"
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile
source $HOME/.bash_profile
fi
~~~

Clone Repository and create a JWT Secret to create a new secret key

~~~bash
cd $HOME
rm -rf testnet-list
git clone https://github.com/gitshock-labs/testnet-list
mkdir $HOME/geth-data
~~~

Create a JWT Secret to create a new secret key by running this command 

~~~bash
cd $HOME/geth-data
openssl rand -hex 32 | tr -d "\n" > "jwt.hex"
~~~

Create a new execution layer account 
>Your new account is locked with a password. Please give a password. Do not forget this password. A public address of the key will be generated (public address of the key will look like 0x.. something). Then a path of the secret key file will also be generated, save it .You’ll need to save them in a safe place directly and you can share the PUBLIC KEY, and don’t EVEN Share your path to the secret key

~~~bash
geth account new --datadir $HOME/geth-data
~~~

Run this command to write custom genesis block 

~~~bash
geth --datadir $HOME/geth-data init $HOME/testnet-list/execution/genesis.json 
~~~

Create service file

~~~bash
sudo tee <<EOF >/dev/null /etc/systemd/system/gethd.service
[Unit]
Description=Geth Execution Layer
After=network.target

[Service]
User=$USER
Type=simple
ExecStart=$(which geth) --datadir $HOME/geth-data \
--http --http.api="engine,eth,web3,net,admin" \
--ws --ws.api="engine,eth,web3,net,debug" \
--http.port 8545 \
--authrpc.port 8551 \
--discovery.port 30303 \
--port 30303 \
--http.addr 0.0.0.0 \
--authrpc.addr 0.0.0.0 \
--authrpc.jwtsecret="$HOME/geth-data/jwt.hex" \
--http.corsdomain="*" \
--http.vhosts=* \
--bloomfilter.size 2048 \
--gcmode="archive" \
--networkid=1881 \
--syncmode=full \
--identity $MONIKER \
--cache 2048 \
--bootnodes="enode://e3b6cbacb5b918ea46104ca295101a53f159d06769e4d5730b4edd95e0880b4ca84bccb5d0c7ca70cf95dfeccef92bb6caa0533be667e4bb0114fc12051989cb@212.47.241.173:30303,enode://45b4fff6ab970e1e490deea8a5f960d806522fafdb33c8eaa38bc0ae970efc2256fc5746f0ecfec770af24c44864a3e6772a64f2e9f031f96fd4af7fd0483110@147.75.71.217:30304,enode://0e2b41699b95e8c915f4f5d18962c0d2db35dc22d3abbebbd25fc48221d1039943240ad37a6e9d853c0b4ea45da7b6b5203a7127b5858c946fc040cace8d2d63@147.75.71.217:30303,enode://787282effee17f9a9da49b3376f475b1521846ee924c962595e672ee9b90290e39b9f2fb67a5f34fb1f4964353cd6ef2a989c110d53b8fd169d8481c44f93119@44.202.92.152:30303" 
Restart=on-failure
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
~~~

Enable and start Execution client

~~~bash
sudo systemctl daemon-reload
sudo systemctl enable gethd
sudo systemctl restart gethd && sudo journalctl -u gethd -f
~~~

Open geth console

~~~bash
geth attach http://localhost:8545
~~~

Check peers

~~~bash
admin.peers
~~~

Check nodeinfo

~~~bash
admin.nodeInfo.enode
~~~

Exit )

~~~bash
exit
~~~

Install Rust

~~~bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
~~~

`Press 1`
Install Cargo 

~~~bash
sudo apt install cargo -y
source ~/.cargo/env 
rustup update stable
~~~

Install Ligthouse

~~~
cd $HOME
rm -rf lighthouse
git clone https://github.com/sigp/lighthouse.git
cd lighthouse
git checkout stable
make
~~~

Run Consensus Layer

~~~
nohup lighthouse beacon \
--testnet-dir $HOME/testnet-list/consensus \
--datadir $HOME/beacon-1 \
--eth1 \
--http \
--gui \
--http-address 127.0.0.1 \
--http-allow-origin="*" \
--http-allow-sync-stalled \
--execution-endpoints http://127.0.0.1:8551 \
--http-port=5052 \
--enr-udp-port=9000 \
--enr-tcp-port=9000 \
--discovery-port=9000 \
--graffiti $MONIKER \
--jwt-secrets $HOME/geth-data/jwt.hex \
--suggested-fee-recipient="$FEE_ADDRESS" \
> $HOME/beacon_1.log &
~~~

Check logs

~~~bash
tail -f $HOME/beacon_1.log
~~~

Gett ENR Key and save result

~~~bash
curl http://localhost:5052/eth/v1/node/identity | jq 
~~~

Save ENR key to variable

~~~bash
ENR=$(curl http://localhost:5052/eth/v1/node/identity | jq .data.enr)
~~~

Run Other Consensus Layer

~~~bash
nohup lighthouse \
--testnet-dir $HOME/testnet-list/consensus \
bn \
--datadir $HOME/beacon-2 \
--eth1 \
--http \
--http-allow-sync-stalled \
--execution-endpoints "http://127.0.0.1:8551" \
--eth1-endpoints "http://127.0.0.1:8545" \
--http-address 0.0.0.0 \
--http-port 5053 \
--http-allow-origin="*" \
--listen-address 0.0.0.0 \
--enr-udp-port 9001 \
--enr-tcp-port 9001 \
--port 9001 \
--enr-address 65.108.72.253 \
--execution-jwt $HOME/geth-data/jwt.hex \
--suggested-fee-recipient="$FEE_ADDRESS" \
--boot-nodes=${ENR} \
> $HOME/beacon_2.log &
~~~

Check logs

~~~bash
tail -f $HOME/beacon_2.log
~~~

### Security
To protect you keys please don`t share your privkey, mnemonic and follow a basic security rules

### Set up ssh keys for authentication
You can use this [guide](https://www.digitalocean.com/community/tutorials/how-to-set-up-ssh-keys-on-ubuntu-20-04) to configure ssh authentication and disable password authentication on your server

### Firewall security
Set the default to allow outgoing connections, deny all incoming, allow ssh and node p2p ports

~~~bash
sudo ufw default allow outgoing 
sudo ufw default deny incoming 
sudo ufw allow ssh/tcp 
sudo ufw allow 5052,5053,3000,9000,30303/tcp
sudo ufw allow 30303/udp
sudo ufw enable
~~~

Synchronize system time

~~~bash
sudo systemctl enable systemd-timesyncd
sudo systemctl start systemd-timesyncd
timedatectl status 
~~~

