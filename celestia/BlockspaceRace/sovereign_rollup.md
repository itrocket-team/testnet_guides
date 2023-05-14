# <img src="https://avatars.githubusercontent.com/u/54859940?s=200&v=4" style="border-radius: 50%; vertical-align: middle;" width="35" height="35" /> Deploy your own Celestia sovereign rollup
> For Celestia Testnet — blockspacerace-0

In this tutorial, you will learn how to set up a simple Movie Rating App. The app will be connected to Celestia's data availability (DA) layer using Rollkit, optimized for the blockspacerace network. We will create a blockchain with a module that allows us to write and read data from the blockchain. This module will allow the end user to submit new ratings (Create), view a list of existing ratings on the blockchain (Read), update existing ratings (Update) and remove them (Delete). By following this tutorial you'll learn how to build a simple CRUD applications and build your own one in the future!


<details><summary> <h2>📋 Requirements </h2></summary>
<p>  Before we get started make sure that your server (computer) meets the minimum requirements:</p>
<ul>
<li><b>Memory</b>: 1 GB RAM</li>
<li><b>CPU</b>: Single Core AMD</li>
<li><b>Disk</b>: 25 GB SSD Storage</li>
<li><b>Ubuntu</b>: Ubuntu 22.10 x64</details></li>
</ul>

## 🔧 Setup 
1. **Prerequisites.** You must have a fully configured [Bridge](https://github.com/itrocket-team/testnet_guides/blob/main/celestia/BlockspaceRace/bridge.md) or [Light](https://github.com/itrocket-team/testnet_guides/blob/main/celestia/BlockspaceRace/light.md) node  
>Please ensure that you check the balance on your account, which will be utilized for posting blocks to the local network. This verification will guarantee your ability to post roll up blocks to the Celestia for data availability (DA) and consensus purposes.
You can find the address by running the following command:
```
NODE_TYPE=bridge
cd $HOME/celestia-node
./cel-key list --node.type $NODE_TYPE --keyring-backend test --p2p.network blockspacerace
```
>Check balance:
```bash
curl -s http://localhost:26659/balance | jq
```
2. **Prerequisites.** Ensure system packages are up-to-date and install dependencies:
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install curl git wget htop tmux build-essential jq make gcc -y
  ```
3. **Install go**
```bash
cd ~
! [ -x "$(command -v go)" ] && {
VER="1.19.3"
wget "https://golang.org/dl/go$VER.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$VER.linux-amd64.tar.gz"
rm "go$VER.linux-amd64.tar.gz"
[ ! -f ~/.bash_profile ] && touch ~/.bash_profile
echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
source ~/.bash_profile
}
[ ! -d ~/go/bin ] && mkdir -p ~/go/bin
go version
```
4. **install Ignite CLI**
```bash
cd $HOME 
curl https://get.ignite.com/cli! | bash
```
>Check version: `ignite version`
5. **Set Environment Variables.** 
> Type new `blockchain name`, `validator name`, `chain_id` `key_name` example `PROJECT_NAME test` `VALIDATOR_NAME test` `CHAIN_ID test-1` `KEY_NAME test-key` `WALLET_RPEFIX xtoken` without `<>`, save and import variables into system
```bash
echo "export PROJECT_NAME="<YOUR_PROJECT_NAME>"" >> $HOME/.bash_profile
echo "export VALIDATOR_NAME="<VALIDATOR_NAME>"" >> $HOME/.bash_profile
echo "export CHAIN_ID="<CHAIN_ID>"" >> $HOME/.bash_profile
echo "export KEY_NAME="<KEY_NAME>"" >> $HOME/.bash_profile
echo "export KEY_2_NAME="<KEY_2_NAME>"" >> $HOME/.bash_profile
echo "export PREFIX="<WALLET_RPEFIX>"" >> $HOME/.bash_profile
source $HOME/.bash_profile
```

6. **Create a Cosmos SDK blockchain**
> This command has created a Cosmos SDK blockchain in the $PROJECT_NAME directoryi 
```
ignite scaffold chain $PROJECT_NAME --address-prefix $PREFIX
```
>
7. **Install Rollkit**
>Run the following command to swap out Tendermint for Rollkit
```bash
cd $PROJECT_NAME
go mod edit -replace github.com/cosmos/cosmos-sdk=github.com/rollkit/cosmos-sdk@v0.46.7-rollkit-v0.7.3-no-fraud-proofs
go mod edit -replace github.com/tendermint/tendermint=github.com/celestiaorg/tendermint@v0.34.22-0.20221202214355-3605c597500d
go mod tidy
go mod download
```
8. **Generate `NAMESPACE_ID` and get Celestia `DA_BLOCK_HEIGHT`**
```
NAMESPACE_ID=$(openssl rand -hex 8)
DA_BLOCK_HEIGHT=$(curl https://rpc-blockspacerace.pops.one/block | jq -r '.result.block.header.height')
```
>check
```
echo $NAMESPACE_ID
echo $DA_BLOCK_HEIGHT
```
9. **Generate code**
>The Ignite CLI will use this information to generate the necessary code for creating/reading/updating/deleting data. `ignite scaffold list` is a command, `post` is a type and `name` and `rating` are fields
```bash
ignite scaffold list post name rating
```
10. **Build binaries**
```bash
ignite chain build
```
11. **Config and init app**
```bash
${PROJECT_NAME}d tendermint unsafe-reset-all
${PROJECT_NAME}d init $VALIDATOR_NAME --chain-id $CHAIN_ID
```
12. **Configure genesys (set custom parameters)**
> Set custom `DENOM`. The default  value is `stake`. We changed it to `utest`, `timeout_commit`, `inflation`, `unbonding_time`
```
sed -i 's/"stake"/"utest"/g' $HOME/.${PROJECT_NAME}/config/genesis.json
sed -i "s/timeout_commit = \".*\"/timeout_commit = \"5s\"/" $HOME/.${PROJECT_NAME}/config/config.toml
sed -i 's%"threshold": "0.500000000000000000",%"threshold": "0.300000000000000001",%g' $HOME/.${PROJECT_NAME}/config/genesis.json
sed -i 's%"inflation": "0.130000000000000000",%"inflation": "0.100000000000000000",%g' $HOME/.${PROJECT_NAME}/config/genesis.json
sed -i 's%"unbonding_time": "1814400s",%"unbonding_time": "6000s",%g' $HOME/.${PROJECT_NAME}/config/genesis.json
```
Total `TOKEN_AMOUNT` `STAKING_AMOUNT` `NODEIP` `DENOM`:
```
TOKEN_AMOUNT="10000000000000000000000000utest"
STAKING_AMOUNT="1152921504606846975utest"
# NODEIP="--node http://127.0.0.1:26657"
```
13. **Create keys**
```
${PROJECT_NAME}d keys add $KEY_NAME --keyring-backend test
${PROJECT_NAME}d keys add $KEY_2_NAME --keyring-backend test
```
14. **Add genesys accounts**
~~~
${PROJECT_NAME}d add-genesis-account $KEY_NAME $TOKEN_AMOUNT --keyring-backend test
${PROJECT_NAME}d add-genesis-account $KEY_2_NAME $TOKEN_AMOUNT --keyring-backend test
~~~
15. **Set the staking amount in the genesys**
```bash
${PROJECT_NAME}d gentx $KEY_NAME $STAKING_AMOUNT --chain-id $CHAIN_ID --keyring-backend test
```
16. **Collect genesis**
~~~bash 
${PROJECT_NAME}d collect-gentxs 
~~~
17. **Check genesis**
~~~bash 
${PROJECT_NAME}d validate-genesis
~~~
18. **Config app**
```
${PROJECT_NAME}d config keyring-backend test
${PROJECT_NAME}d config chain-id $CHAIN_ID
```
19. **Create Service file**
```bash
sudo tee /etc/systemd/system/${PROJECT_NAME}d.service > /dev/null <<EOF
[Unit]
Description=celestia
After=network-online.target

[Service]
User=$USER
ExecStart=$(which ${PROJECT_NAME}d) start --rollkit.aggregator true --rollkit.da_layer celestia --rollkit.da_config='{"base_url":"http://localhost:26659","timeout":60000000000,"fee":6000,"gas_limit":6000000}' --rollkit.namespace_id $NAMESPACE_ID --rollkit.da_start_height $DA_BLOCK_HEIGHT
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
```
20. **Enable and start service**
```bash
sudo systemctl daemon-reload
sudo systemctl enable ${PROJECT_NAME}d
sudo systemctl restart ${PROJECT_NAME}d && sudo journalctl -u ${PROJECT_NAME}d -f
```
21. **Create a your first movie rating post**
>Create a movie rating post with name `avengers` and the rating of `5`. When using the `--from` flag to specify the account that will sign a transaction, it's important to ensure that the specified account is available for use. 
```
${PROJECT_NAME}d tx ${PROJECT_NAME} create-post avengers 5 --from $KEY_NAME --keyring-backend test
```
22. **Read the movies posts**
>We query the blockchain to see the changes. 
```
${PROJECT_NAME}d q ${PROJECT_NAME} list-post
```
> Then we see our first rating ⭐⭐⭐⭐⭐
```
Post:
- creator: itrocket1hmvkgupdxayp7mays3y5ecjsh3hf6znpdnjc7g
  id: "0"
  name: avengers
  rating: "5"
pagination:
  next_key: null
  total: "0"
```
23. **Update the movies list**

Let's update the post and change it to the old soviet film `Mimino`. Let's give it a solid `9` 🤔
```
${PROJECT_NAME}d tx ${PROJECT_NAME} update-post 0 mimino 9 --from $KEY_NAME --keyring-backend test
```
> Check the changes using `movied q movie list-post` 
```
auth_info:
  fee:
    amount: []
    gas_limit: "200000"
    granter: ""
    payer: ""
  signer_infos: []
  tip: null
body:
  extension_options: []
  memo: ""
  messages:
  - '@type': /itrocket.itrocket.MsgUpdatePost
    creator: itrocket1hmvkgupdxayp7mays3y5ecjsh3hf6znpdnjc7g
    id: "0"
    name: mimino
    rating: "9"
  non_critical_extension_options: []
  timeout_height: "0"
signatures: []
code: 0
codespace: ""
data: ""
events: []
gas_used: "0"
gas_wanted: "0"
height: "0"
info: ""
logs: []
raw_log: '[]'
timestamp: ""
tx: null
txhash: 7EE50514698003609109D041DBA69718325D18F0213ED7E69202DCEEA84C6936
```
24. **Delete the post**
> We use `delete-post` and value `0` as our post id is `0`
```
${PROJECT_NAME}d tx ${PROJECT_NAME} delete-post 0 --from $KEY_NAME --keyring-backend test
```

## Congratulations 🎉
You have successfully built a sovereign rollup! 

<img src="https://itrocket.net/logo.svg" style="width: 100%; fill: white" />
