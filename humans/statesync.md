## (OPTIONAL) Humans State Sync

In order not to wait for a long synchronization, you can use our StateSync guide

Stop the service 

~~~bash
sudo systemctl stop humansd
~~~

Configure

~~~bash
cd $HOME 
peers="6ef7d7d851917ed86dece6f81c8c2c315a93ca9c@65.109.92.79:17656"  
SNAP_RPC=65.109.92.79:17657
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" $HOME/.humans/config/config.toml 
sed -i.bak -e "s/^snapshot-interval *=.*/snapshot-interval = \"2000\"/" $HOME/.humans/config/app.toml 
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
s|^(seeds[[:space:]]+=[[:space:]]+).*$|\1\"\"|" $HOME/.humans/config/config.toml
~~~

Clean old data

~~~bash
humansd tendermint unsafe-reset-all --home $HOME/.humans --keep-addr-book
~~~
Restart the service and check the log

~~~bash
sudo systemctl restart humansd && sudo journalctl -u humansd -f
~~~
