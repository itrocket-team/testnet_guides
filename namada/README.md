<h1 align="left"> 
<img src="https://raw.githubusercontent.com/itrocket-team/testnet_guides/main/utils/basket/namada.jpg" alt="Namada" width="30" height="30">
 Anoma Namada Setup // Testnet — public-testnet-14.5d79b6958580   
</h1>

Official documentation: [validator setup instructions](https://docs.namada.net/testnets/environment-setup.html)

Explorer: https://namadaexplorer.com/

## ⚙️ Hardware Requirements
### Minimum Hardware Requirements 
 - CPU: x86_64 or arm64 processor with at least 4 physical cores
 - RAM: 8GB DDR4
 - Storage: 1TB

## 🔧 Set up your node
### Manual installation

Update packages and Install dependencies `select 1`

~~~bash
sudo apt update && sudo apt upgrade -y
sudo apt-get install -y make git-core libssl-dev pkg-config libclang-12-dev build-essential protobuf-compiler
~~~

Install Go, if needed
~~~
cd $HOME
! [ -x "$(command -v go)" ] && {
VER="1.20.3"
wget "https://golang.org/dl/go$VER.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$VER.linux-amd64.tar.gz"
rm "go$VER.linux-amd64.tar.gz"
[ ! -f ~/.bash_profile ] && touch ~/.bash_profile
echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
source $HOME/.bash_profile
}
[ ! -d ~/go/bin ] && mkdir -p ~/go/bin
~~~

Install Rust
~~~
sudo apt install curl -y
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

Download and build Namada binaries

~~~bash
rm -rf namada
git clone https://github.com/anoma/namada
cd namada
wget https://github.com/anoma/namada/releases/download/v0.23.2/namada-v0.23.2-Linux-x86_64.tar.gz
tar -xvf namada-v0.23.2-Linux-x86_64.tar.gz
mv ~/namada-v0.23.2-Linux-x86_64 ~/namada
mv ~/namada/namada* /usr/local/bin/
rm namada-v0.23.2-Linux-x86_64.tar.gz
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

</details>

<details>
  <summary><strong>🔗 Create Post-Genesis Validator (skip this point if you are a pre-genesis validator) </strong></summary>

Create wallet

~~~bash
namada wallet address gen --alias $WALLET
~~~

>Fund your wallet from [faucet](https://faucet.heliax.click/)

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
namada client bonds --owner $ALIAS
~~~

</details>

## 🔒 Security

❗To protect you keys please don`t share your privkey, mnemonic and follow a basic security rules


### Set up ssh keys for authentication
You can use this [guide](https://www.digitalocean.com/community/tutorials/how-to-set-up-ssh-keys-on-ubuntu-20-04) to configure ssh authentication and disable password authentication on your server

Set the default to allow outgoing connections, deny all incoming, allow ssh and node p2p port

~~~bash
sudo ufw default allow outgoing 
sudo ufw default deny incoming 
sudo ufw allow ssh/tcp 
sudo ufw allow 26656,26657/tcp
sudo ufw enable
~~~

## 📝 Useful commands

Check logs

~~~bash
sudo journalctl -u namadad -f
~~~

Check your validator bond status
~~~bash
namada client bonds --owner $ALIAS
~~~

Check all bonded nodes
~~~bash
namada client bonded-stake
~~~

Check balance

~~~bash
namada client balance --owner $ALIAS --token NAM
~~~

Stake funds

~~~bash
namada client bond \
  --validator $ALIAS \
  --amount 1500 \
  --gas-limit 10000000
~~~

Check Sync status and node info

~~~bash
curl http://127.0.0.1:26657/status | jq
~~~

Check consensus state

~~~bash
curl -s localhost:26657/consensus_state | jq .result.round_state.height_vote_set[0].prevotes_bit_array
~~~

Full consensus state

~~~bash
curl -s localhost:12657/dump_consensus_state
~~~

Your validator votes (prevote)

~~~bash
curl -s http://localhost:26657/dump_consensus_state | jq '.result.round_state.votes[0].prevotes' | grep $(curl -s http://localhost:26657/status | jq -r '.result.validator_info.address[:12]')
~~~

## 🔄 Upgrade

Upgrade to v0.23.2
```
cd $HOME
rm -rf namada
git clone https://github.com/anoma/namada
cd namada
git checkout v0.23.2
make build-release
sudo mv $HOME/namada/target/release/namada* /usr/local/bin/
sudo systemctl restart namadad && sudo journalctl -u namadad -f
```

## If your node  halt, try the following steps, if not, ignore it

Stop node and delete `tx_wasm_cache` `vp_wasm_cache`
~~~bash
sudo systemctl stop namadad
cd ${BASE_DIR}/public-testnet-14.5d79b6958580
rm -rf tx_wasm_cache vp_wasm_cache
~~~

Update service file

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

Enable and restart service

~~~bash
sudo systemctl daemon-reload
sudo systemctl enable namadad
sudo systemctl restart namadad && sudo journalctl -u namadad -f
~~~


