<div>
<h1 align="left" style="display: flex;"> Ojo Price-feeder Setup for Testnet — ojo-devnet</h1>
<img src="https://avatars.githubusercontent.com/u/110753560?s=200&v=4"  style="float: right;" width="100" height="100"></img>
</div>

Official documentation:
>- [Validator setup instructions](https://docs.ojo.network/sauron-testnet/joining-as-a-validator)

Explorer:
>-  https://testnet.itrocket.net/ojo/staking


## Hardware Requirements
### Recommended Hardware Requirements 
 - 4 vCPU
 - 8GB RAM
 - 200GB of storage

## Set up ojo price-feeder
### Manual installation

Update packages and Install dependencies

~~~bash
sudo apt update && sudo apt upgrade -y
sudo apt install curl git wget htop tmux build-essential jq make lz4 gcc -y
~~~

install go

~~~bash
cd $HOME
if ! [ -x "$(command -v go)" ]; then
VER="1.20"
wget "https://golang.org/dl/go$VER.linux-amd64.tar.gz"
sudo tar -C /usr/local -xzf "go$VER.linux-amd64.tar.gz"
rm -rf  "go$VER.linux-amd64.tar.gz"
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile
source $HOME/.bash_profile
fi
~~~

Download and build binaries

~~~bash
cd $HOME
git clone https://github.com/ojo-network/price-feeder
cd price-feeder
git checkout v0.1.1
make install
~~~

Create folder and mv config

~~~bash
mkdir $HOME/.price-feeder
mv price-feeder.example.toml $HOME/.price-feeder/config.toml
~~~

Create new wallet for pricefeeder

~~~bash
ojod keys add pricefeeder --keyring-backend os
~~~

Export keyring password and set up variables

~~~bash
export PASSWORD="<PUT_HERE_FEEDER_KEY_PASSWORD>"
export RPC_PORT=${OJO_PORT}657
export GRPC_PORT=${OJO_PORT}090
PRICEFEEDER_ADDRESS=$(echo -e $PASSWORD | ojod keys show pricefeeder --keyring-backend os -a)
echo "export PRICEFEEDER_ADDRESS="$PRICEFEEDER_ADDRESS"" >> $HOME/.bash_profile
source $HOME/.bash_profile
~~~

Fund the pricefeeder-wallet, it needs to pay for transaction fees

~~~bash
ojod tx bank send $WALLET_ADDRESS $PRICEFEEDER_ADDRESS 1000000uojo --gas auto --gas-adjustment 1.3
~~~

Check the balance

~~~bash
ojod q bank balances $PRICEFEEDER_ADDRESS
~~~

Delegate pricefeeder responsibility to PRICEFEEDER_ADDRESS

~~~bash
ojod tx oracle delegate-feed-consent $WALLET_ADDRESS $PRICEFEEDER_ADDRESS --from $WALLET  --gas auto --gas-adjustment 1.3
~~~

Check linked PRICEFEEDER_ADDRESS

~~~bash
ojod q oracle feeder-delegation $VALOPER_ADDRESS
~~~

Set gustom ports in config.toml file

~~~bash
sed -i '
  s|^address *=.*|'"address = \"$PRICEFEEDER_ADDRESS\""'|;
  s|^chain_id *=.*|'"chain_id = \"ojo-devnet\""'|;
  s|^validator *=.*|'"validator = \"$VALOPER_ADDRESS\""'|;
  s|^backend *=.*|'"backend = \"os\""'|;
  s|^dir *=.*|'"dir = \"$HOME/.ojo\""'|;
  s|^grpc_endpoint *=.*|'"grpc_endpoint = \"localhost:${GRPC_PORT}\""'|;
  s|^tmrpc_endpoint *=.*|'"tmrpc_endpoint = \"http://localhost:${RPC_PORT}\""'|;
  s|^global-labels *=.*|'"global-labels = [[\"chain_id\", \"ojo-devnet\"]]"'|;
  s|^service-name *=.*|'"service-name = \"price-feeder\""'|;
' "$HOME/.price-feeder/config.toml"
~~~

Create Service file

~~~bash
sudo tee /etc/systemd/system/price-feeder.service > /dev/null <<EOF
[Unit]
Description=ojo-price-feeder
After=network-online.target

[Service]
User=$USER
ExecStart=$(which price-feeder) $HOME/.price-feeder/config.toml
Restart=on-failure
RestartSec=3
LimitNOFILE=65535
Environment="PRICE_FEEDER_PASS=$PASSWORD"

[Install]
WantedBy=multi-user.target
EOF
~~~

Enable and start service

~~~bash
sudo systemctl daemon-reload
sudo systemctl enable price-feeder
sudo systemctl restart price-feeder && sudo journalctl -u price-feeder -f
~~~

