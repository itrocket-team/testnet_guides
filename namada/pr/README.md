<h1 align="left"> 
<img src="https://raw.githubusercontent.com/itrocket-team/testnet_guides/main/utils/basket/namada.jpg" alt="Namada" width="30" height="30">
 How to create a pull request to Namada testnet 15
</h1>

## Download binaries
```
cd $HOME
rm -rf $HOME/namada
git clone https://github.com/anoma/namada
cd $HOME/namada
wget https://github.com/anoma/namada/releases/download/v0.28.0/namada-v0.28.0-Linux-x86_64.tar.gz
tar -xvf namada-v0.28.0-Linux-x86_64.tar.gz
rm namada-v0.28.0-Linux-x86_64.tar.gz
cd namada-v0.28.0-Linux-x86_64
sudo mv namada namadan namadac namadaw /usr/local/bin/
```
## Create a new address
```
namadaw --pre-genesis key gen --alias $ALIAS
```
## Save base directory path if needed
```
echo "export BASE_DIR="$HOME/.local/share/namada"" >> $HOME/.bash_profile
source $HOME/.bash_profile
```
## Init genesis established account
```
TX_FILE_PATH="$BASE_DIR/pre-genesis/transactions.toml"
namadac utils init-genesis-established-account --path $TX_FILE_PATH --aliases $ALIAS
```
## Put the established account address, email, validator address
```
ESTABLISHED_ACCOUNT_ADDRESS=<Derived_established_account_address>
EMAIL="<your-email>"
SELF_BOND_AMOUNT=1000000
VALIDATOR_ALIAS="<your-validator-alias>"
namadac utils init-genesis-validator \
  --address $ESTABLISHED_ACCOUNT_ADDRESS \
  --alias $VALIDATOR_ALIAS \
  --net-address "<IP>:<PORT>" \
  --commission-rate 0.05 \
  --max-commission-rate-change 0.01 \
  --self-bond-amount $SELF_BOND_AMOUNT \
  --email $EMAIL \
  --path $TX_FILE_PATH
```
## Sign genesis
```
namadac utils sign-genesis-txs \
    --path $TX_FILE_PATH \
    --output $BASE_DIR/pre-genesis/signed-transactions.toml \
    --alias $VALIDATOR_ALIAS
```
## A few steps left:
Fork this repository: https://github.com/anoma/namada-testnets/tree/main/namada-public-testnet-15   

Create a new file in repository and name it <your_alias_name>.toml   

Create a pull request. Name the request <create_alias.toml> if it is your first pull request, or <update_alias.toml> if you had a pull request earlier.
