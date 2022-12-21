## (OPTIONAL) Nibiru State Sync

In order not to wait for a long synchronization, you can use our StateSync guide

Stop the service 

~~~bash
sudo systemctl stop nibid
~~~

Configure

~~~bash
cd $HOME 
peers="a08e5b25443d038b08230177456ee23196509dd5@65.109.92.79:12656" 
config=$HOME/.nibid/config/config.toml 
SNAP_RPC=65.109.92.79:12657
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" $config 
sed -i.bak -e "s/^snapshot-interval *=.*/snapshot-interval = \"2000\"/" $HOME/.nibid/config/app.toml 
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \ 
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \ 
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash) 
sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ;
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ;
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ;
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"| ;
s|^(seeds[[:space:]]+=[[:space:]]+).*$|\1\"\"|" $config
nibid tendermint unsafe-reset-all --home $HOME/.nibid --keep-addr-book
~~~
Restart the service and check the log

~~~bash
sudo systemctl restart nibid && sudo journalctl -u nibid -f
~~~
