<div>
<h1 align="left" style="display: flex;"> Anoma Namada Setup for Testnet — public-testnet-14.5d79b6958580</h1>
<img src="https://avatars.githubusercontent.com/u/87261362?s=200&v=4"  style="float: right;" width="100" height="100"></img>
</div>

Official documentation:
>- [Validator setup instructions](https://docs.namada.net/testnets/environment-setup.html)

Explorer
>- https://namadaexplorer.com/

## Hardware Requirements
### Recommended Hardware Requirements 
 - CPU: x86_64 or arm64 processor with at least 4 physical cores (must support AVX/SSE instruction set)
 - RAM: 8GB DDR4
 - Storage: at least 500GB SSD (NVMe SSD is recommended. HDD will also work.)

## Set up your node
### Manual installation

Update packages and Install dependencies `select 1`

~~~bash
sudo apt update && sudo apt upgrade -y
sudo apt-get install -y make git-core libssl-dev pkg-config libclang-12-dev build-essential protobuf-compiler
~~~
~~~bash
wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.0g-2ubuntu4_amd64.deb
sudo dpkg -i libssl1.1_1.1.0g-2ubuntu4_amd64.deb
~~~

Install Rust
~~~
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
~~~
~~~
source "$HOME/.cargo/env"
~~~

Replace your Validator and Wallet name, save and import variables into system

~~~bash
echo "export ALIAS="CHOOSE_A_NAME_FOR_YOUR_VALIDATOR"" >> $HOME/.bash_profile
echo "export WALLET="CHOOSE_A_WALLET_NAME"" >> $HOME/.bash_profile
echo "export PUBLIC_IP=$(wget -qO- eth0.me)" >> $HOME/.bash_profile
echo "export TM_HASH="v0.1.4-abciplus"" >> $HOME/.bash_profile
echo "export CHAIN_ID="public-testnet-14.5d79b6958580"" >> $HOME/.bash_profile
echo "export BASE_DIR="$HOME/.local/share/namada"" >> $HOME/.bash_profile
source $HOME/.bash_profile
~~~

install go

~~~bash
cd $HOME
if ! [ -x "$(command -v go)" ]; then
wget -O go1.19.4.linux-amd64.tar.gz https://golang.org/dl/go1.19.4.linux-amd64.tar.gz
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.19.4.linux-amd64.tar.gz && sudo rm go1.19.4.linux-amd64.tar.gz
echo 'export GOROOT=/usr/local/go' >> $HOME/.bash_profile
echo 'export GOPATH=$HOME/go' >> $HOME/.bash_profile
echo 'export GO111MODULE=on' >> $HOME/.bash_profile
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile && . $HOME/.bash_profile
go version
fi
~~~

Install CometBFT

~~~
cd $HOME
git clone https://github.com/cometbft/cometbft.git
cd cometbft
git checkout v0.37.2
make build
sudo cp $HOME/cometbft/build/cometbft /usr/local/bin/
cometbft version
~~~

Download and build namada binaries

~~~bash
cd $HOME
rm -rf $HOME/.masp-params
rm -rf namada
wget https://github.com/anoma/namada/releases/download/v0.24.0/namada-v0.24.0-Linux-x86_64.tar.gz
tar -xvf namada-v0.24.0-Linux-x86_64.tar.gz
mv ~/namada-v0.24.0-Linux-x86_64 ~/namada
mv ~/namada/namada* ~/go/bin
rm namada-v0.24.0-Linux-x86_64.tar.gz
mkdir -p $HOME/.local/share/namada
cp -r ~/.namada/pre-genesis $BASE_DIR/
~~~

Check namada version

~~~bash
namada --version
~~~

Run node

~~~bash
cd $HOME
namada client utils join-network --chain-id $CHAIN_ID --genesis-validator $ALIAS
~~~

Create Service file

~~~bash
sudo tee /etc/systemd/system/namadad.service > /dev/null <<EOF
[Unit]
Description=namada
After=network-online.target

[Service]
User=$USER
Environment=NAMADA_CMT_STDOUT=true
Environment=TM_LOG_LEVEL=p2p:none,pex:error
ExecStart=$(which namada) ledger run
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
sudo systemctl enable namadad
sudo systemctl restart namadad && sudo journalctl -u namadad -f
~~~

Set the default to allow outgoing connections, deny all incoming, allow ssh and node p2p port

~~~bash
sudo ufw default allow outgoing 
sudo ufw default deny incoming 
sudo ufw allow ssh/tcp 
sudo ufw allow 26656,26657/tcp
sudo ufw enable
~~~

Create wallet

~~~bash
namada wallet address gen --alias $WALLET
~~~


Fund your wallet 

~~~bash
namadac transfer \
    --token NAM \
    --amount 1000 \
    --source faucet \
    --target $ALIAS \
    --signer $ALIAS
~~~

Check bonds 

~~~bash
namada client bonds --owner $ALIAS
~~~

## Create validator

before creating a validator, you need to check the balance and make sure that the node is synched

Check Sync status, once your node is fully synced, the output from above will say `false`

~~~bash
curl http://127.0.0.1:26657/status | jq .result.sync_info.catching_up
~~~

Check your balance

~~~bash
namada client balance --owner $ALIAS --token NAM
~~~

Init validator

~~~bash
namada client init-validator \
  --alias $ALIAS \
  --source $WALLET \
  --commission-rate 0.1 \
  --max-commission-rate-change 0.01
~~~
  
Stake your funds

~~~bash
namada client bond \
  --validator $ALIAS \
  --amount 1500 \
  --gas-limit 10000000
  ~~~
  
Waiting more than 2 epoch and check your status

~~~bash
namada client bonded-stake
~~~
  
### Security
To protect you keys please don`t share your privkey, mnemonic and follow a basic security rules

### Set up ssh keys for authentication
You can use this [guide](https://www.digitalocean.com/community/tutorials/how-to-set-up-ssh-keys-on-ubuntu-20-04) to configure ssh authentication and disable password authentication on your server
