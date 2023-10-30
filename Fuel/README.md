<h1 align="left"> 
<img src="https://avatars.githubusercontent.com/u/55993183?s=48&v=4" alt="Fuel Beta-4" width="30" height="30">
 Fuel Beta-4 Setup // Testnet — Beta-4   
</h1>
### Install rust
~~~
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
~~~
~~~
sudo apt install cargo -y
source ~/.cargo/env 
rustup update stable
~~~

### Run fuelup-init
~~~
curl --proto '=https' --tlsv1.2 -sSf https://install.fuel.network/fuelup-init.sh | sh
~~~

Add path
~~~
echo 'export PATH=$PATH:/home/fuel/.fuelup/bin' >> ~/.bashrc
source ~/.bashrc
~~~

### Install beta-4
~~~
fuelup toolchain install beta-4
~~~

Set beta-4 as your default toolchain
~~~
fuelup default beta-4
~~~

### Genereate P2P key
~~~
fuel-core-keygen new --key-type peering
~~~

### Download chain config
~~~
wget -O chainConfig.json https://raw.githubusercontent.com/FuelLabs/fuel-core/v0.20.4/deployment/scripts/chainspec/beta_chainspec.json
~~~


### Create service file
>Add your Sepolia endpoint, like Infura, Alchemy...  
ENDPOINT=<Your_Ethereum_Sepolia_Endpoint>  
KEYPAR=<Your_P2P_Key_Secret>

~~~
sudo tee /etc/systemd/system/fueld.service > /dev/null <<EOF
[Unit]
Description=Fuel node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME
ExecStart=$(which fuel-core) run \
--keypair $KEYPAR \
--relayer $ENDPOINT \
--ip 127.0.0.1 --port 4000 --peering_port 30339 \
--db-path  $HOME/.fuel_beta4 \
--chain $HOME/chainConfig.json \
--utxo-validation --poa-instant false --network beta-4 --enable-p2p \
--min-gas-price 1 --max_block_size 18874368  --max_transmit_size 18874368 \
--bootstrap_nodes /dns4/p2p-beta-4.fuel.network/tcp/30333/p2p/16Uiu2HAm3xjsqASZ68KpaJPkPCMUiMgquhjyDHtxcVxVdFkMgRFf,/dns4/p2p-beta-4.fuel.network/tcp/30334/p2p/16Uiu2HAmJyoJ2HrtPRdBALMT8fs5Q25xVj57gZj5s6G6dzbHypoS \
--sync_max_get_header 100 --sync_max_get_txns 100 \
--relayer-v2-listening-contracts 0x03f2901Db5723639978deBed3aBA66d4EA03aF73 \
--relayer-da-finalization 4 \
--relayer-da-deploy-height 4111672 \
--relayer-log-page-size 10000
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF
~~~

Enable and start service

~~~
sudo systemctl daemon-reload
sudo systemctl enable fueld
sudo systemctl restart fueld && sudo journalctl -u fueld -f
~~~

### Security
Set the default to allow outgoing connections, deny all incoming, allow ssh and node p2p port
~~~
sudo ufw default allow outgoing 
sudo ufw default deny incoming 
sudo ufw allow ssh/tcp 
sudo ufw allow 30339/tcp
sudo ufw enable
~~~
