########################## Step 1 ##################################

# install dependencies, if needed
```
sudo apt install aria2 jq lz4 unzip -y
```

# Dowgrade the binaries to v0.45.1
```
cd $HOME
sudo systemctl stop namadad
rm -rf namada
git clone https://github.com/anoma/namada
cd namada
wget https://github.com/anoma/namada/releases/download/v0.45.1/namada-v0.45.1-Linux-x86_64.tar.gz
tar -xvf namada-v0.45.1-Linux-x86_64.tar.gz
cd namada-v0.45.1-Linux-x86_64
sudo mv namad* /usr/local/bin/
```

# Download v0.46.0 and the state migration json file
```rm -rf $HOME/namada-v0.46.0-Linux-x86_64
wget https://github.com/anoma/namada/releases/download/v0.46.0/namada-v0.46.0-Linux-x86_64.tar.gz
tar -xvf namada-v0.46.0-Linux-x86_64.tar.gz
rm namada-v0.46.0-Linux-x86_64.tar.gz
wget https://raw.githubusercontent.com/anoma/namada-governance-upgrades/6f488c6f45a8d5e8ad9cc803b3c17d8708378746/state_migration/dryrun_migration46.json
sha256sum dryrun_migration46.json
# acadd7d124804448b3c7f7b3dc0c3bc536fe6dbd1594757d5a992d47ecacc5c6
```

# Update service file 
```
export BLOCK_HEIGHT=182000
export MIGRATION_JSON=$HOME/dryrun_migration46.json
sudo tee /etc/systemd/system/namadad.service > /dev/null <<EOF
[Unit]
Description=namada
After=network-online.target

[Service]
User=$USER
WorkingDirectory=$BASE_DIR
Environment=CMT_LOG_LEVEL=p2p:none,pex:error
Environment=NAMADA_CMT_STDOUT=true
ExecStart=$(which namada) node ledger run-until --block-height $BLOCK_HEIGHT --halt
StandardOutput=syslog
StandardError=syslog
Restart=failure
RestartSec=10
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
```

# Download pre upgrade snapshot and restart namada with v0.45.1
```
cd $HOME
aria2c -x 16 -s 16 -o namada-snap.tar.lz4 https://server-n.itrocket.net/mainnet/namada/namada-snap.tar.lz4
```

########################## step 2 ##################################
# backup priv_validator_state.json
```
cp $HOME/.local/share/namada/namada-dryrun.abaaeaf7b78cb3ac/cometbft/data/priv_validator_state.json $HOME/.local/share/namada/namada-dryrun.abaaeaf7b78cb3ac/cometbft/priv_validator_state.json.backup
```
# delete data and unpack snapshot
```
rm -rf $HOME/.local/share/namada/namada-dryrun.abaaeaf7b78cb3ac/cometbft/data $HOME/.local/share/namada/namada-dryrun.abaaeaf7b78cb3ac/{db,wasm}
tar -I lz4 -xvf ~/namada-snap.tar.lz4 -C $HOME/.local/share/namada/namada-dryrun.abaaeaf7b78cb3ac
mv $HOME/.local/share/namada/namada-dryrun.abaaeaf7b78cb3ac/cometbft/priv_validator_state.json.backup $HOME/.local/share/namada/namada-dryrun.abaaeaf7b78cb3ac/cometbft/data/priv_validator_state.json
```
# restart node and check logs
```
sudo systemctl restart namadad && sudo journalctl -u namadad -f
```
##########################################################################################
# Step 3, Run this step only after your node has reached block 182000
##########################################################################################
# After block 182000 update binaries
```
cd $HOME
sudo systemctl stop namadad
rm -rf $HOME/namada-v0.46.0-Linux-x86_64
wget https://github.com/anoma/namada/releases/download/v0.46.0/namada-v0.46.0-Linux-x86_64.tar.gz
tar -xvf namada-v0.46.0-Linux-x86_64.tar.gz
sudo mv $HOME/namada-v0.46.0-Linux-x86_64/namad* /usr/local/bin/
```

# Update service file 
```
export BLOCK_HEIGHT=182000
export MIGRATION_JSON=$HOME/dryrun_migration46.json
sudo tee /etc/systemd/system/namadad.service > /dev/null <<EOF
[Unit]
Description=namada
After=network-online.target

[Service]
User=$USER
WorkingDirectory=$BASE_DIR
Environment=CMT_LOG_LEVEL=p2p:none,pex:error
Environment=NAMADA_CMT_STDOUT=true
ExecStart=$(which namada) node ledger run --height 182000 --path $MIGRATION_JSON --hash acadd7d124804448b3c7f7b3dc0c3bc536fe6dbd1594757d5a992d47ecacc5c6
StandardOutput=syslog
StandardError=syslog
Restart=always
RestartSec=10
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
```

# restart namada with v0.46.0
```
sudo systemctl daemon-reload
sudo systemctl enable namadad
sudo systemctl restart namadad && sudo journalctl -u namadad -f
```

####################################################################
Do not restart at height 182001, as it will cause a Merkle tree error.
####################################################################
