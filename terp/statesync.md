## (OPTIONAL) Terp State Sync

In order not to wait for a long synchronization, you can use our StateSync guide

Stop the service 

~~~bash
sudo systemctl stop terpd
~~~

Configure

~~~bash
cd $HOME 
peers="51d48be3809bb8907c1ef5f747e53cdd0c9ded1b@65.109.92.79:13656"  
SNAP_RPC=65.109.92.79:13657
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" $HOME/.terp/config/config.toml 
sed -i.bak -e "s/^snapshot-interval *=.*/snapshot-interval = \"2000\"/" $HOME/.terp/config/app.toml 
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \ 
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \ 
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash) 
~~~

Check is the state sync information available

~~~bash
echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH
~~~

Configure the state sync
~~~bash
sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"| ; \
s|^(seeds[[:space:]]+=[[:space:]]+).*$|\1\"\"|" $HOME/.terp/config/config.toml
~~~

Clean old data

~~~bash
terpd tendermint unsafe-reset-all --home $HOME/.terp --keep-addr-book
~~~
Restart the service and check the log

~~~bash
sudo systemctl restart terpd && sudo journalctl -u terpd -f
~~~
