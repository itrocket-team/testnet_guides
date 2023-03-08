# ETH goerly testnet full node installation guide with erigon

Official documentation:
>- [Erigon Full node](https://github.com/ledgerwatch/erigon)

Update packages and Install dependencies

~~~bash
sudo apt update && sudo apt upgrade -y
sudo apt install curl build-essential git wget jq make gcc tmux -y
~~~

Install go

~~~bash
  ver="1.19.3"
  cd $HOME
  wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
  rm "go$ver.linux-amd64.tar.gz"
  echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.bash_profile
  source ~/.bash_profile
~~~

## Install Erigon

~~~bash
cd $HOME
rm -rf erigon
git clone --branch stable --single-branch https://github.com/ledgerwatch/erigon.git
cd erigon
make erigon
sudo mv ~/erigon/build/bin/erigon ~/go/bin/erigon
mkdir $HOME/.ethereum
~~~

Create service file

~~~bash
sudo tee <<EOF >/dev/null /etc/systemd/system/erigond.service
[Unit]
Description=Erigon Node
After=network.target

[Service]
User=$USER
Type=simple
WorkingDirectory=$HOME
ExecStart=$(which erigon) --datadir $HOME/.ethereum --chain=goerli --http.vhosts '*' --http.port 8545 --http.addr 0.0.0.0 --http.corsdomain '*' --http.api 'eth,erigon,net,web3,trace,txpool' --ws --private.api.addr=localhost:9090 --metrics --metrics.port 6060 --metrics.addr 0.0.0.0
Restart=on-failure
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
~~~

Enable and start service

~~~bash
sudo systemctl daemon-reload
sudo systemctl enable erigond
sudo systemctl restart erigond && sudo journalctl -u erigond -f
~~~

To test your Ethereum RPC node, you can send an RPC request using `cURL`

~~~bash
curl -X POST -H "Content-Type: application/json" --data '{"jsonrpc": "2.0", "method": "eth_blockNumber", "params": [], "id":1}' localhost:8545
~~~

## Update node
### You can check the [list of releases](https://github.com/ledgerwatch/erigon/releases) for release notes.
For building the bleeding edge development branch:

~~~bash
git clone --recurse-submodules https://github.com/ledgerwatch/erigon.git
cd erigon
git checkout <LATEST_VERSION>
make erigon
mv ~/erigon/build/bin/erigon ~/go/bin/erigon
sudo systemctl restart erigond && sudo journalctl -u erigond -f
~~~

### Delete node 

~~~bash
sudo systemctl stop erigond
sudo systemctl disable erigond
sudo rm -rf $HOME/.ethereum
sudo rm -rf $HOME/go/bin/erigon
sudo rm -rf $HOME/erigon/
sudo rm -rf /etc/systemd/system/erigon.service
sudo systemctl daemon-reload
~~~
