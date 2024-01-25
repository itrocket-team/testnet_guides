<h1 align="left"> 
<img src="https://raw.githubusercontent.com/itrocket-team/testnet_guides/main/utils/basket/namada.jpg" alt="Namada" width="30" height="30">
 Anoma Namada Setup // Testnet — housefire.50d5126dba66f595d2cc   
</h1>

Official documentation: [validator setup instructions](https://knowabl.notion.site/Housefire-burner-net-0a0d670d5dad412ea5715fcc97b9433d)

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

Install Rust & Cargo
~~~
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env
~~~

Replace your Validator and Wallet name, save and import variables into system

~~~bash
echo "export ALIAS="CHOOSE_A_NAME_FOR_YOUR_VALIDATOR"" >> $HOME/.bash_profile
echo "export WALLET="CHOOSE_A_WALLET_NAME"" >> $HOME/.bash_profile
echo "export PUBLIC_IP=$(wget -qO- eth0.me)" >> $HOME/.bash_profile
echo "export TM_HASH="v0.1.4-abciplus"" >> $HOME/.bash_profile
echo "export CHAIN_ID="housefire.50d5126dba66f595d2cc"" >> $HOME/.bash_profile
echo "export BASE_DIR="$HOME/.local/share/namada"" >> $HOME/.bash_profile
echo "export NAMADA_NETWORK_CONFIGS_SERVER="https://housefire.luminara.icu/configs"" >> $HOME/.bash_profile
source $HOME/.bash_profile
~~~

Install CometBFT

~~~
cd $HOME
rm -rf cometbft
git clone https://github.com/cometbft/cometbft.git
cd cometbft
git checkout v0.37.2
make build
sudo cp $HOME/cometbft/build/cometbft /usr/local/bin/
cometbft version
~~~

Download and build Namada binaries

~~~bash
cd $HOME
rm -rf namada
git clone https://github.com/anoma/namada
cd namada
wget https://github.com/anoma/namada/releases/download/v0.30.1/namada-v0.30.1-Linux-x86_64.tar.gz
tar -xvf namada-v0.30.1-Linux-x86_64.tar.gz
rm namada-v0.30.1-Linux-x86_64.tar.gz
cd namada-v0.30.1-Linux-x86_64
sudo mv namad* /usr/local/bin/
if [ ! -d "$BASE_DIR" ]; then
    mkdir -p "$BASE_DIR"
fi
~~~

Check Namada version

~~~bash
namada --version
~~~


<details>
  <summary><strong>🔗 Join-network as Full node or Validator</strong></summary>
  <br>

  ~~~bash
cd $HOME
namada client utils join-network --chain-id $CHAIN_ID --dont-prefetch-wasm
wget https://housefire.luminara.icu/wasm.tar.gz
tar -xf wasm.tar.gz
cp wasm/* ${BASE_DIR}/${CHAIN_ID}/wasm/
rm -rf wasm.tar.gz wasm
~~~

</details>

<details>
  <summary><strong>🔗 Join-network via RPC Node</strong></summary>

~~~bash
cd $HOME
namada client utils join-network --chain-id $CHAIN_ID --dont-prefetch-wasm
wget https://housefire.luminara.icu/wasm.tar.gz
tar -xf wasm.tar.gz
cp wasm/* ${BASE_DIR}/${CHAIN_ID}/wasm/
rm -rf wasm.tar.gz wasm
~~~

>You can now execute commands on the chain without syncing a full node, by using the public RPC http://rpc.housefire.luminara.icu. To do so, input the command as normal but include the
--nodeflag to specify that you wish to use an external RPC. For example: `namadac epoch --node tcp://rpc.housefire.luminara.icu:80`

</details>

Configure peers
~~~bash
PEERS="tcp://b2cb012cbece6a378ccb96091af4f386cb45abbb@namada-testnet-peer.itrocket.net:33656,tcp://a3e17c8968bf3dff073d8156187045532a7e144c@142.93.149.122:26656"
sed -i 's|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' ${BASE_DIR}/${CHAIN_ID}/config.toml
~~~

Create Service file

~~~bash
sudo tee /etc/systemd/system/namadad.service > /dev/null <<EOF
[Unit]
Description=namada
After=network-online.target

[Service]
User=$USER
WorkingDirectory=$BASE_DIR
Environment="NAMADA_LOG=info"
Environment="CMT_LOG_LEVEL=p2p:none,pex:error"
Environment="NAMADA_CMT_STDOUT=true"
ExecStart=$(which namada) node ledger run
StandardOutput=syslog
StandardError=syslog
Restart=always
RestartSec=5
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

## 🔎 Create and fund wallet 
Create wallet

~~~bash
namadaw gen --alias $WALLET
~~~

Restore executing wallet 
~~~bash
namadaw derive --alias $WALLET
~~~

Find your wallet address

~~~bash
namadaw find --alias $WALLET
~~~
>Copy the implicit address (starts with tnam...) for the next step


- Fund your wallet from [faucet](https://faucet.housefire.luminara.icu/)

After a couple of minutes, the check the balance

~~~bash
namadac balance --owner $WALLET
~~~

List known keys and addresses in the wallet

~~~bash
namadaw list
~~~

Delete wallet

~~~bash
namadaw remove --alias $WALLET --do-it
~~~

Check Sync status, once your node is fully synced, the output from above will say `false`

~~~bash
curl http://127.0.0.1:26657/status | jq .result.sync_info.catching_up
~~~

## 🧑‍🎓 Turn your full node into a validator

Initiate a validator 

~~~bash
namadac init-validator --commission-rate 0.07 --max-commission-rate-change 1 --signing-keys $WALLET --alias $ALIAS --email <EMAIL_ADDRESS> --account-keys $WALLET
~~~

Find your `established` validator address
~~~bash
namadaw list | grep -A 1 "$ALIAS" | grep "Established"
~~~

Replace your Validator address, save and import variables into system
~~~bash
VALIDATOR_ADDRESS=$(namadaw list | grep -A 1 "$ALIAS" | grep "Established" | awk '{print $3}')
echo "export VALIDATOR_ADDRESS="$VALIDATOR_ADDRESS"" >> $HOME/.bash_profile
source $HOME/.bash_profile
~~~

Restart the node and wait for 2 epochs
~~~bash
sudo systemctl restart namadad && sudo journalctl -u namadad -f
~~~

Check epoch
~~~bash
namada client epoch
~~~

Delegate tokens
~~~bash
namadac bond --validator $ALIAS --source $WALLET --amount 1000
~~~

Wait for 3 epochs and check validator is in the consensus set 
~~~bash
namadac validator-state --validator $ALIAS
~~~

Check your validator bond status
~~~bash
namada client bonds --owner $ALIAS
~~~

Query the set of validators 
~~~bash
namadac bonded-stake
~~~

## 🔒 Security

❗To protect you keys please don`t share your privkey, mnemonic and follow a basic security rules


### Set up ssh keys for authentication
You can use this [guide](https://www.digitalocean.com/community/tutorials/how-to-set-up-ssh-keys-on-ubuntu-20-04) to configure ssh authentication and disable password authentication on your server

Set the default to allow outgoing connections, deny all incoming, allow ssh and node p2p port

~~~bash
sudo ufw default allow outgoing 
sudo ufw default deny incoming 
sudo ufw allow ssh/tcp 
sudo ufw allow 26656/tcp
sudo ufw enable
~~~

## 📝 Useful commands

Check logs

~~~bash
sudo journalctl -u namadad -f
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


