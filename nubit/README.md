# Nubit Guide: Light Node Setup & Interacting with DA 

## 1. Run a Light Node
We will run a node with a service file.

Create the service file and open it:
~~~
sudo tee /etc/systemd/system/nubitd.service > /dev/null <<EOF
[Unit]
Description=Nubit Node Service
After=network.target

[Service]
ExecStart=/bin/bash -c 'curl -sL1 https://nubit.sh | bash'
WorkingDirectory=$HOME
Restart=always
User=nubit
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
~~~

Reload the systemd configuration, enable and restart the service
~~~
sudo systemctl daemon-reload
sudo systemctl enable nubitd
sudo systemctl restart nubitd && sudo journalctl -u nubitd -f
~~~


## 2. Interact with Nubit DA

## Set Environment
Go to the nubit-node directory
~~~
cd nubit-node
~~~

Set the path and environment variables
~~~
export PATH=$PATH:$(pwd)/bin
NETWORK=nubit-alphatestnet-1
NODE_TYPE=light
PEERS=/ip4/34.222.12.122/tcp/2121/p2p/12D3KooWJJWdaCB8GRMHuLiy1Y8FWTRCxDd5GVt6A2mFn8pryuf3
VALIDATOR_IP=validator.nubit-alphatestnet-1.com
GENESIS_HASH=AD1DB79213CA0EA005F82FACC395E34BE3CFCC086CD5C25A89FC64F871B3ABAE
AUTH_TYPE=admin
store=$HOME/.nubit-${NODE_TYPE}-${NETWORK}/
NUBIT_CUSTOM="${NETWORK}:${GENESIS_HASH}:${PEERS}"
~~~

## Manage Keys
List keys. If you are initializing the light node for the first time, a Nubit address named `my_nubit_key` will be automatically generated. 
**Don't forget to save your mnemonic phrase.**
~~~
nkey list --p2p.network $NETWORK --node.type $NODE_TYPE
~~~

Export the unarmored hex private key if you missed the mnemonic phrase. Replace `my_nubit_key` with your account name.
~~~
nkey export my_nubit_key --unarmored-hex --unsafe --p2p.network $NETWORK --node.type $NODE_TYPE
~~~

### Store keys in Keplr Wallet.
- Visit the Keplr Chains website at https://chains.keplr.app, search for "Nubit Alpha Testnet," and add it to your wallet.
- Open the Keplr wallet extension and click the user avatar in the top right corner. Select "Add Wallet," then choose "Import an existing wallet". Enter your mnemonic phrase or your unarmored hex private key.
- Set a custom name for your wallet, select "Nubit Alpha Testnet" Chain and confirm. Your Nubit address will now appear in the Keplr wallet extension.

### Import Keys
Another option id to create a Nubit address in the Keplr wallet and then import its mnemonic phrase into nubit-node. Replace `my_keplr_key` with desired wallet name.
~~~
nkey add my_keplr_key --recover --keyring-backend test --node.type $NODE_TYPE --p2p.network $NETWORK
~~~

Nubit-node also supports importing addresses using private key files. Refer to the following command, replacing `my_nubit_key` with the desired key name and `~/nubit-da/nubit-node/account1.private` with the actual location of your private key file.
~~~
nkey import my_nubit_key ~/nubit-da/nubit-node/account1.private --keyring-backend test --node.type $NODE_TYPE --p2p.network $NETWORK
~~~

### Delete Keys
Please note that nubit-node will only use the first key it encounters. If you wish to switch to a new key, you need to delete the previous key. This command will clear all your address data in nubit-node, so proceed with caution! It is recommended to export your keys and store them safely before deleting any addresses to ensure you can reuse them later:
~~~
rm -rf $HOME/.nubit-$NODE_TYPE*
~~~


## Explore More Node Operations
Following commands could be helpful for interaction with Nubit DA Alpha Testnet.

### Address
**Get Account Address**
Get your Account Address by entering the following command in terminal:
~~~
nubit state account-address  --node.store $store
~~~

It should return the following:
~~~
{
  "result": ""
}
~~~

**Check Address Balance**
Get the balance of your account by entering the following command in terminal.
~~~
nubit state balance --node.store $store
~~~

It should return the following:
~~~
{
  "result": {
    "denom": "unub"
    "amount": "" 
  }
}
~~~

**Use the alpha-testnet-faucet on [Discord](https://discord.gg/nubit) to get testnet tokens.**

### Transaction
**Initiate a Transaction**
Send a given amount of unub from node wallet to the account address provided.

Parameters
- `address`: Account address receiving Unub, starting in nubit.... 
- `amount` - [Integer]: Amount of Unub transfered.
- `fee` - [Integer]: Gas Price. 
- `gasLimit` - [Integer]: Gas Limit of this transaction.

Command
~~~
nubit state transfer [address] [amount] [fee] [gasLimit]  --node.store $store
~~~

Example
~~~
nubit state transfer nubit1pehkl4edqwc6kar2zmhy2gw8feek68hvpe8d49 1 1 1000 --node.store $store
~~~

It should return the following:
~~~
{
  "result": {
    "height":
    "txhash":
    "data":
    "raw_log":
    "logs":[]
    "gas_wanted":
    "gas_used":
    "events":[]
  }
}
~~~


### Submit Blob
**Initiate a Blob Transaction**
Submit the blob at the given namespace by following command below.

Parameters
- `namespace` - [hexadecimal]: Namespace chosen, starting in 0x.
- `blobData` - [string]: Data uploaded and broadcasted.

Command
~~~
nubit blob submit [namespace] [blobData] --node.store $store
~~~

Example
~~~

~~~

It should return the following:
~~~
// Some code{
  "result": {
    "height":
    "commitments": []
  }
}
~~~

**Inquire about Blob Transaction**
Get the blob for the given namespace by commitment at a particular height.

Parameters
- `height` - [Integer]: Height blobs of data was uploaded.
- `namespace` - [hexadecimal]: Namespace chosen, starting in 0x.
- `commitment`- [string]: Commitment provided as response when submitting blobs.

Command
~~~
nubit blob get [height] [namespace] [commitment] --node.store $store
~~~

Example
~~~

~~~

It should return the following:
~~~
{
  "result": {
    "namespace": 
    "data":
    "share_version":
    "commitment":
    "index":
  }
}
~~~
For more interaction with Nubit DA Alpha Testnet, please refer to Nubit DA Node APIs.

**Nubit explorer to check the transactions: https://explorer.nubit.org/.**
Official docs: https://docs.nubit.org/.

### Useful Commands

Check node status
~~~
$HOME/nubit-node/bin/nubit das sampling-stats --node.store $HOME/.nubit-light-nubit-alphatestnet-1
~~~

>You will receive a response similar to the following to verify that your node is running successfully
~~~
{
  "result": {
    "head_of_sampled_chain": 143124,
    "head_of_catchup": 143124,
    "network_head_height": 143124,
    "concurrency": 0,
    "catch_up_done": true,
    "is_running": true
  }
}
~~~
