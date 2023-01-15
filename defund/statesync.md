## (OPTIONAL) Defundd State Sync

In order not to wait for a long synchronization, you can use our StateSync guide

~~~bash
sudo systemctl stop defundd
cd $HOME 
peers="6ebe0fd3fd0990feec2dd1e09fe06b766b6b67d0@defund-testnet-peer.itrocket.net:443"  
SNAP_RPC="https://defund-testnet-rpc.itrocket.net:443"
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" $HOME/.defund/config/config.toml 
sed -i.bak -e "s/^snapshot-interval *=.*/snapshot-interval = \"1000\"/" $HOME/.defund/config/app.toml 
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height);
BLOCK_HEIGHT=$((LATEST_HEIGHT - 1000));
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash) 
sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ;
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ;
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ;
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"| ;
s|^(seeds[[:space:]]+=[[:space:]]+).*$|\1\"\"|" $HOME/.defund/config/config.toml
defundd tendermint unsafe-reset-all --home $HOME/.defund --keep-addr-book
sudo systemctl restart defundd && sudo journalctl -u defundd -f
~~~
