## (OPTIONAL) Nolus State Sync

In order not to wait for a long synchronization, you can use our StateSync guide

Stop the service 

~~~bash
sudo systemctl stop nolusd
~~~

Configure

~~~bash
cd $HOME 
peers="721e40c2c9abefa358f9428bc396cdbe05520312@65.109.92.79:16656"  
SNAP_RPC=65.109.92.79:16657
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" $HOME/.nolus/config/config.toml 
sed -i.bak -e "s/^snapshot-interval *=.*/snapshot-interval = \"2000\"/" $HOME/.nolus/config/app.toml 
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
s|^(seeds[[:space:]]+=[[:space:]]+).*$|\1\"\"|" $HOME/.nolus/config/config.toml
~~~

Clean old data

~~~bash
nolusd tendermint unsafe-reset-all --home $HOME/.nolus --keep-addr-book
~~~
Restart the service and check the log

~~~bash
sudo systemctl restart nolusd && sudo journalctl -u nolusd -f
~~~
