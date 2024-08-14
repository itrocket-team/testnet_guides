### Guide to Fixing AppHash After Migration
Downgrade binary
~~~
cd $HOME
sudo wget -O /usr/lib/libwasmvm.x86_64.so https://github.com/CosmWasm/wasmvm/releases/download/v1.3.1/libwasmvm.x86_64.so
wget https://github.com/MANTRA-Finance/public/raw/main/mantrachain-hongbai/mantrachaind-linux-amd64.zip
unzip mantrachaind-linux-amd64.zip
rm mantrachaind-linux-amd64.zip
sudo mv mantrachaind $(which mantrachaind)
~~~

Download the pre-upgrade snapshot
~~~
sudo systemctl stop mantrachaind

cp $HOME/.mantrachain/data/priv_validator_state.json $HOME/.mantrachain/priv_validator_state.json.backup

rm -rf $HOME/.mantrachain/data $HOME/.mantrachain/wasm
curl https://server-4.itrocket.net/mantra_2024-08-14_1631626_snap.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.mantrachain

mv $HOME/.mantrachain/priv_validator_state.json.backup $HOME/.mantrachain/data/priv_validator_state.json

sudo systemctl restart mantrachaind && sudo journalctl -u mantrachaind -f
~~~

>We wait for a message in the logs indicating that an update is required, and then we update the binary
~~~
upgrade_version="2.0.0"
if [ "$(uname -m)" == "aarch64" ]; then export ARCH="arm64"; else export ARCH="amd64"; fi
wget https://github.com/MANTRA-Finance/public/releases/download/v$upgrade_version/mantrachaind-$upgrade_version-linux-$ARCH.tar.gz
# extract the binary
tar -xvf mantrachaind-$upgrade_version-linux-$ARCH.tar.gz
chmod +x mantrachaind
sudo mv $HOME/mantrachaind $(which mantrachaind)
~~~

Check binnary version and commit
~~~
mantrachaind version --long | grep -e version -e commit
#commit: c0b4618
#version: 2.0.0
~~~

Start node
~~~
sudo systemctl restart mantrachaind && sudo journalctl -u mantrachaind -f
~~~

