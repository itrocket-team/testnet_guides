<div>
<h1 align="left" style="display: flex;"> Fleek Node Setup </h1>
<img src="https://avatars.githubusercontent.com/u/116367644?s=200&v=4"  style="float: right;" width="100" height="100"></img>
</div>

Official documentation:
>- [Fleek node setup instructions](https://docs.fleek.network/guides/Network%20nodes/fleek-network-getting-started-guide)


## Hardware Requirements
### Recommended Hardware Requirements 
 - 4 Cores
 - 8GB RAM
 - 160 GB SSD

## Set up your fleek node
### Manual installation

Update packages and Install dependencies

~~~bash
sudo apt update && sudo apt upgrade -y
sudo apt install curl git wget htop tmux build-essential jq make tmux lz4 gcc protobuf-compiler -y
~~~


install Rust and Crgo `press 1`

~~~bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
~~~

~~~bash
sudo apt install cargo -y
source ~/.cargo/env 
rustup update stable
~~~

Download and build binaries

~~~bash
cd $HOME
rm -rf ursa
git clone https://github.com/fleek-network/ursa.git
cd ursa
make install
~~~

Check version

~~~bash
ursa --version
#ursa 0.1.0
~~~

Open tmux session

~~~bash
tmux new -s fleek
~~~

Start fleek node

~~~bash
cd $HOME/ursa && ursa
~~~

Waiting for the inscription to appear  `bootstrap complete` and deattach tmux session Ctrl+B D

Put Data

~~~bash
curl https://ipfs.io/ipfs/bafybeidqdywrzg7c3b4dmm332m4b7uiakgitplz2pep2zntederxpj3odi -o basic.car
~~~

Put the file on the node

~~~bash
ursa rpc put basic.car
~~~

Retrieve Data

~~~bash
ls -hl ./output
~~~

Compare

~~~bash
cmp basic.car bafybeifyjj2bjhtxmp235vlfeeiy7sz6rzyx3lervfk3ap2nyn4rggqgei.car
~~~
  
### Security
To protect you keys please don`t share your privkey, mnemonic and follow a basic security rules

### Set up ssh keys for authentication
You can use this [guide](https://www.digitalocean.com/community/tutorials/how-to-set-up-ssh-keys-on-ubuntu-20-04) to configure ssh authentication and disable password authentication on your server

### Firewall security
Set the default to allow outgoing connections, deny all incoming, allow ssh and node p2p port

~~~bash
sudo ufw default allow outgoing 
sudo ufw default deny incoming 
sudo ufw allow ssh/tcp 
sudo ufw allow 4069,6009/tcp
sudo ufw enable
~~~

### Delete node

~~~bash
tmux kill-session -t fleek
sudo rm $HOME/go/bin/ursa
sudo rm -rf $HOME/.ursa
sudo rm -rf $HOME/ursa
~~~

