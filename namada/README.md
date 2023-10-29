<div>
<h1 align="left" style="display: flex;"> Anoma Namada Setup for Testnet — public-testnet-14.5d79b6958580</h1>
<img src="https://avatars.githubusercontent.com/u/87261362?s=200&v=4"  style="float: right;" width="100" height="100"></img>
</div>

Official documentation:
>- [Validator setup instructions](https://docs.namada.net/testnets/environment-setup.html)

Explorer
>- https://namadaexplorer.com/

## Hardware Requirements
### Minimum Hardware Requirements 
 - CPU: x86_64 or arm64 processor with at least 4 physical cores
 - RAM: 8GB DDR4
 - Storage: 1TB

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
wget https://github.com/anoma/namada/releases/download/v0.23.1/namada-v0.23.1-Linux-x86_64.tar.gz
tar -xvf namada-v0.23.1-Linux-x86_64.tar.gz
mv ~/namada-v0.23.1-Linux-x86_64 ~/namada
mv ~/namada/namada* /usr/local/bin/
rm namada-v0.23.1-Linux-x86_64.tar.gz
mkdir -p $HOME/.local/share/namada
~~~

Check namada version

~~~bash
namada --version
~~~


<details>
  <summary><strong>🔗 Join-network as Pre-Genesis Validator</strong></summary>
  <br>
  
  📁 *Move your pre-genesis folder to `$BASE_DIR` and join the network:*

  ~~~bash
cd $HOME
cp -r ~/.namada/pre-genesis $BASE_DIR/
namada client utils join-network --chain-id $CHAIN_ID --genesis-validator $ALIAS
~~~

</details>

<details>
  <summary><strong>🔗 Join-network as Full Nodes or Post-Genesis Validator</strong></summary>

~~~bash
namada client utils join-network --chain-id $CHAIN_ID
~~~

</details>

Create Service file

~~~bash
sudo tee /etc/systemd/system/namadad.service > /dev/null <<EOF
[Unit]
Description=namada
After=network-online.target

[Service]
User=$USER
WorkingDirectory=$BASE_DIR
Environment=CMT_LOG_LEVEL=p2p:none,pex:error
Environment=NAMADA_CMT_STDOUT=true
Environment=NAMADA_LOG=info
ExecStart=$(which namada) node ledger run
StandardOutput=syslog
StandardError=syslog
Restart=always
RestartSec=10
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

### Security

Set the default to allow outgoing connections, deny all incoming, allow ssh and node p2p port

~~~bash
sudo ufw default allow outgoing 
sudo ufw default deny incoming 
sudo ufw allow ssh/tcp 
sudo ufw allow 26656,26657/tcp
sudo ufw enable
~~~

### Create and fund wallet for Post-Genesis Validator

Create wallet

~~~bash
namada wallet address gen --alias $WALLET
~~~

>Fund your wallet from [faucet](https://faucet.heliax.click/)

Check balance

~~~bash
namada client bonds --owner $ALIAS
~~~

Create validator

>before creating a validator, you need to check the balance and make sure that the node is synched

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
