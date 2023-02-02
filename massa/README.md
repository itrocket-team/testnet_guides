<div>
<h1 align="left" style="display: flex;"> Massa Node Setup </h1>
<img src="https://avatars.githubusercontent.com/u/92152619?s=200&v=4"  style="float: right;" width="100" height="100"></img>
</div>

Official documentation:
>- [Installing a node](https://docs.massa.net/en/latest/testnet/install.html)


## Hardware Requirements
### Recommended Hardware Requirements 
Right now 4 cores and 8 GB of RAM should be enough to run a node, but it might increase in the future.

## Set up your massa node
### Manual installation

Update packages and Install dependencies

~~~bash
sudo apt update && sudo apt upgrade -y
sudo apt install curl git wget htop tmux build-essential jq make lz4 gcc -y
~~~

Download and unzip software

~~~bash
cd $HOME
wget https://github.com/massalabs/massa/releases/download/TEST.19.1/massa_TEST.19.1_release_linux.tar.gz
tar zxvf massa_TEST.19.1_release_linux.tar.gz
~~~

Config  app

~~~bash
sudo tee <<EOF >/dev/null $HOME/massa/massa-node/config/config.toml
[network]
routable_ip = "`wget -qO- eth0.me`"
EOF
~~~

Start Node and create password

~~~bash
cd $HOME/massa/massa-node/
./massa-node
~~~


Close session `Ctrl+С`  
Replace your Password `<YOUR_PASSWORD>` without `<>`

~~~bash
PASSWORD=<YOUR_PASSWORD>
~~~

Create Service file

~~~bash
sudo tee /etc/systemd/system/massad.service > /dev/null <<EOF
[Unit]
Description=Massa
After=network-online.target

[Service]
User=$USER
WorkingDirectory=$HOME/massa/massa-node
ExecStart=$HOME/massa/massa-node/massa-node -p $PASSWORD
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
~~~


Enable and start service

~~~bash
sudo systemctl daemon-reload
sudo systemctl enable massad
sudo systemctl restart massad && sudo journalctl -u massad -f
~~~

## Run client
Run Massa client

~~~bash
cd $HOME/massa/massa-client/
./massa-client
~~~

## Create or restore wallet
To create a new wallet, use the following command, don’t forget to save `$HOME/massa/massa-client/wallet.dat` and `$HOME/massa/massa-node/config/node_privkey.key` 

~~~bash
wallet_generate_secret_key
~~~

>(optional) To restore exexuting wallet, put you backup files `wallet.dat` to `$HOME/massa/massa-client/wallet.dat` and `node_privkey.key` to `$HOME/massa/massa-node/config/node_privkey.key`

To view the wallet address use this command:

~~~bash
wallet_info
~~~

Enable staking for your address, replace your Wallet address `<YOUR_PASSWORD>` without `<>` 
>You need to see `Keys successfully added!`

~~~bash
node_start_staking <YOUR_WALLET_ADDRESS>
~~~

>- Fund your wallet, go to the Massa discord server and  and navigate to `testnet-faucet` channel and put your wallet address

After a while, the balance will be displayed in the client interface, usually 1-10 minutes

~~~bash
wallet_info
~~~

## Buy rolls
Open client interface if you closed

~~~bash
cd $HOME/massa/massa-client/
./massa-client
~~~

Buy rolls, replace your Wallet address `<YOUR_WALLET_ADDRESS>` without `<>`

~~~bash 
buy_rolls <YOUR_WALLET_ADDRESS> 1 0
~~~
>We are waiting for 2 hours until the roll becomes active, you need to see `Rolls: active=1` in `wallet_info` command

## Register your node on discord server
Go to Massa discord server `testnet-rewwards-registration` channel and write `hi`, you will receive a message from masa-bot, opent this chat and send a message with your ip address

~~~bash
wget -qO- eth0.me
~~~

Now you need to regitrer your node, replace your Wallet address `<YOUR_WALLET_ADDRESS>` and <DISCORD_ID> without `<>`.  You will find Discord ID in the message from massa-bot
>Example: node_testnet_rewards_program_ownership_proof your_staking_address `69703435236262333`

~~~bash
node_testnet_rewards_program_ownership_proof <YOUR_WALLET_ADDRESS> <DISCORD_ID>
~~~
>- In response, you will receive a long key that you need to copy and paste into the Mess-bout chat

### Security
To protect you keys please save and don`t share your keys, and follow a basic security rules

### Set up ssh keys for authentication
You can use this [guide](https://www.digitalocean.com/community/tutorials/how-to-set-up-ssh-keys-on-ubuntu-20-04) to configure ssh authentication and disable password authentication on your server

### Firewall security
Set the default to allow outgoing connections, deny all incoming, allow ssh and node p2p port

~~~bash
sudo ufw default allow outgoing 
sudo ufw default deny incoming 
sudo ufw allow ssh/tcp 
sudo ufw allow 31244 && sudo ufw allow 31245
sudo ufw enable
~~~
