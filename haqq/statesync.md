## (OPTIONAL) Haqq State Sync

In order not to wait for a long synchronization, you can use our StateSync guide

Stop the service 

~~~bash
sudo systemctl stop haqqd
~~~

Configure

~~~bash
cd $HOME 
peers="b87ae2a43e27bd0360ea1b868c8cb9e98d612fce@https://haqq-testnet-peer.itrocket.net:443"  
SNAP_RPC=https://haqq-testnet-rpc.itrocket.net:443
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" $HOME/.haqqd/config/config.toml 
sed -i.bak -e "s/^snapshot-interval *=.*/snapshot-interval = \"1000\"/" $HOME/.haqqd/config/app.toml 
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \ 
BLOCK_HEIGHT=$((LATEST_HEIGHT - 1000)); \ 
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
s|^(seeds[[:space:]]+=[[:space:]]+).*$|\1\"\"|" $HOME/.haqqd/config/config.toml
~~~

Clean old data

~~~bash
haqqd tendermint unsafe-reset-all --home $HOME/.haqqd --keep-addr-book
~~~
Restart the service and check the log

~~~bash
sudo systemctl restart haqqd && sudo journalctl -u haqqd -f
~~~
