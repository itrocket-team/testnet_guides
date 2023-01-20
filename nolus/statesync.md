## (OPTIONAL) Nolus State Sync

In order not to wait for a long synchronization, you can use our StateSync guide

~~~bash
sudo systemctl stop nolusd

cp $HOME/.nolus/data/priv_validator_state.json $HOME/.nolus/priv_validator_state.json.backup
nolusd tendermint unsafe-reset-all --home $HOME/.nolus --keep-addr-book

cd $HOME 
peers="721e40c2c9abefa358f9428bc396cdbe05520312@nolus-testnet-peer.itrocket.net:443"  
SNAP_RPC="https://nolus-testnet-rpc.itrocket.net:443"
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" $HOME/.nolus/config/config.toml 
sed -i.bak -e "s/^snapshot-interval *=.*/snapshot-interval = \"2000\"/" $HOME/.nolus/config/app.toml 
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height);
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000));
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash) 

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ;
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ;
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ;
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"| ;
s|^(seeds[[:space:]]+=[[:space:]]+).*$|\1\"\"|" $HOME/.nolus/config/config.toml

mv $HOME/.nolus/priv_validator_state.json.backup $HOME/.nolus/data/priv_validator_state.json

sudo systemctl restart nolusd && sudo journalctl -u nolusd -f
~~~
