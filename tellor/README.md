### Guide to Fixing AppHash After Upgrade to v0.4.2
Upgrade binary
~~~
cd $HOME
rm -rf layer
git clone https://github.com/tellor-io/layer
cd layer
git checkout v0.4.2
go build ./cmd/layerd
sudo mv layerd $(which layerd)
~~~

Download the pre-upgrade snapshot
~~~
sudo systemctl stop layerd

cp $HOME/.layer/data/priv_validator_state.json $HOME/.layer/priv_validator_state.json.backup

rm -rf $HOME/.layer/data $HOME/.layer/wasm
curl https://server-5.itrocket.net/testnet/tellor/backup/tellor_2024-08-28_874300_snap.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.layer

mv $HOME/.layer/priv_validator_state.json.backup $HOME/.layer/data/priv_validator_state.json

sudo systemctl start layerd && sudo journalctl -u layerd -f
~~~

> ### *You can restore your node using our guide, but after any reboot, the node will go into AppHash error... https://github.com/cosmos/cosmos-sdk/issues/20489*
