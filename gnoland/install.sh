# install go, if needed
cd $HOME
VER="1.23.1"
wget "https://golang.org/dl/go$VER.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$VER.linux-amd64.tar.gz"
rm "go$VER.linux-amd64.tar.gz"
[ ! -f ~/.bash_profile ] && touch ~/.bash_profile
echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
source $HOME/.bash_profile
[ ! -d ~/go/bin ] && mkdir -p ~/go/bin

# set vars
echo "export WALLET="wallet"" >> $HOME/.bash_profile
echo "export MONIKER="test"" >> $HOME/.bash_profile
echo "export GNOLAND_CHAIN_ID="test7.2"" >> $HOME/.bash_profile
echo "export GNOLAND_PORT="54"" >> $HOME/.bash_profile
source $HOME/.bash_profile

cd $HOME
rm -rf gno
git clone https://github.com/gnolang/gno.git
git checkout chain/${GNOLAND_CHAIN_ID}
cd gno
make install_gnokey
make -C gno.land install.gnoland && make -C contribs/gnogenesis install

cd $HOME
gnoland secrets init
gnoland config init
gnoland config set rpc.laddr tcp://0.0.0.0:${GNOLAND_PORT}657
gnoland config set p2p.laddr tcp://0.0.0.0:${GNOLAND_PORT}656
gnoland config set proxy_app tcp://127.0.0.1:${GNOLAND_PORT}658
gnoland config set moniker $MONIKER
gnoland config set consensus.peer_gossip_sleep_duration 10ms
gnoland config set consensus.timeout_commit 3s
gnoland config set mempool.size 10000
gnoland config set p2p.flush_throttle_timeout 10ms
gnoland config set p2p.max_num_outbound_peers 40
gnoland config set p2p.persistent_peers g15y3wvtjc7tdepems32l80gf9a6tshj9nhhl388@gnolan-testnet-rpc.shazoes.xyz:42656,g137jz3hjhz6psrxxjtj5h7h4s6llfyrv2zxtfq3@gno-core-sen-01.test7.testnets.gno.land:26656,g1kpxll39mgzfhsepazzs0vne2l42mmkylxkt6un@gno-core-sen-02.test7.testnets.gno.land:26656
gnoland config set p2p.seeds g15y3wvtjc7tdepems32l80gf9a6tshj9nhhl388@gnolan-testnet-rpc.shazoes.xyz:42656,g137jz3hjhz6psrxxjtj5h7h4s6llfyrv2zxtfq3@gno-core-sen-01.test7.testnets.gno.land:26656,g1kpxll39mgzfhsepazzs0vne2l42mmkylxkt6un@gno-core-sen-02.test7.testnets.gno.land:26656
cd ~/gnoland-data/config
wget -O genesis.json https://gno-testnets-genesis.s3.eu-central-1.amazonaws.com/test7/genesis.json


sudo tee /etc/systemd/system/gnoland.service > /dev/null <<EOF
[Unit]
Description=Gnoland node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME
ExecStart=$(which gnoland) start --genesis  $HOME/gnoland-data/config/genesis.json --data-dir $HOME/gnoland-data/ --skip-genesis-sig-verification
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl restart gnoland && sudo journalctl -u gnoland -f


# get validator address and public key
VAL_ADDRESS=$(gnoland secrets get validator_key | jq -r '.address')
VAL_PUB_KEY=$(gnoland secrets get validator_key | jq -r '.pub_key')

# create wallet
gnokey add $WALLET -home /home/gnoland/gnoland-data/

# add your validator description (you can use Markdown)
DETAILS=$(cat <<'EOF'
your validator description
EOF
)

# create validator
gnokey maketx call \
-pkgpath "gno.land/r/gnoland/valopers" \
-func "Register" \
-gas-fee 1000000ugnot \
-gas-wanted 30000000 \
-broadcast \
-chainid "$GNOLAND_CHAIN_ID" \
-args "$MONIKER" \
-args "$DETAILS" \
-args "$VAL_ADDRESS" \
-args "$VAL_PUB_KEY" \
-remote "https://rpc.test7.testnets.gno.land:443" \
$WALLET -home /home/gnoland/gnoland-data/
