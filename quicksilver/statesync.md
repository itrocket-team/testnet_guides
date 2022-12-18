## (OPTIONAL) Nibiru State Sync

In order not to wait for a long synchronization, you can use our StateSync guide

Stop the service 

~~~bash
sudo systemctl stop quicksilverd
~~~

Configure

~~~bash
cd $HOME 
peers="4559f4c24037bfad4791b2a6d6d5c769a16cad53@65.109.92.79:15656"  
SNAP_RPC=65.109.92.79:15657
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" $HOME/.quicksilverd/config/config.toml 
sed -i.bak -e "s/^snapshot-interval *=.*/snapshot-interval = \"2000\"/" $HOME/.quicksilverd/config/app.toml 
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
s|^(seeds[[:space:]]+=[[:space:]]+).*$|\1\"\"|" $HOME/.quicksilverd/config/config.toml
~~~

Clean old data

~~~bash
quicksilverd tendermint unsafe-reset-all --home $HOME/.quicksilverd --keep-addr-book
~~~
Restart the service and check the log

~~~bash
sudo systemctl restart quicksilverd && sudo journalctl -u quicksilverd -f
~~~
