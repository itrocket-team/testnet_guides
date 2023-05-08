# Set up monitoring and alerting for Cosmos sdk based nodes

- Node Exporter is a service whose task is to export information about the server in a format understandable by Prometheus [Official docs](https://github.com/prometheus/node_exporter)
- Cosmos Exporter is a service whose task is to export information from the full node of the Cosmos-based blockchain via gRPC. [Official docs](https://github.com/solarlabsteam/cosmos-exporter)

# Node Exporter and Cosmos Exporter will be installed on the same server - for this you can use the validator server or run the node on a separate server, Prometheus and Grafana will be installed on a separate server


## Update packages and Install dependencies

~~~
sudo apt update && sudo apt upgrade -y
sudo apt-get install curl build-essential ca-certificates gnupg git wget jq make gcc tmux pkg-config libssl-dev libleveldb-dev tar -y
~~~ 

## Set validator node variables
>Default RPC port is 26657, gRPC - 9090. if you have custom ports on your validator node, check it and change ports!

| KEY |VALUE |
|---------------|-------------|
| **rpc_port** | Your validator `rpc` port that is defined in `config.toml` file. Default value is `20657` |
| **grpc_port** | Your validator `grpc` port that is defined in `app.toml` file. Default value is `9090` |
| **bond_denom** | Denominated token name, for example, `aheart` for Humans testnet. You can find it in genesis file |
| **bench_prefix** | Prefix for chain addresses, for example, `human`. You can find it in public addresses like this **human**_valoper14acd299ds9q3qf09gjqw9qvvzwmla8g7nhhg8k |

~~~
RPC_PORT=26657
GRPC_PORT=9090
DENOM=aheart
BENCH=human
~~~

## Install cosmos-exporter on validator node
>First of all, you need to download the latest release from the releases [page](https://github.com/solarlabsteam/cosmos-exporter/releases/). After that, you should unzip it and you are ready to go:

~~~
cd $HOME
wget https://github.com/solarlabsteam/cosmos-exporter/releases/download/v0.3.0/cosmos-exporter_0.3.0_Linux_x86_64.tar.gz
tar -xvf $HOME/cosmos-exporter_0.3.0_Linux_x86_64.tar.gz
sudo cp ./cosmos-exporter /usr/bin
rm -rf cosmos-exporter*
~~~

## Add user

~~~
sudo useradd -rs /bin/false cosmos_exporter
~~~

## Create service file and start cosmos-exporter

~~~
sudo tee /etc/systemd/system/cosmos-exporter.service << EOF
[Unit]
Description=Cosmos Exporter
After=network.target

[Service]
User=cosmos_exporter
TimeoutStartSec=0
CPUWeight=95
IOWeight=95
ExecStart=cosmos-exporter  --denom ${DENOM} --denom-coefficient 1000000 --bech-prefix ${BENCH} --tendermint-rpc http://localhost:${RPC_PORT} --node localhost:${GRPC_PORT}
Restart=always
RestartSec=2
LimitNOFILE=800000
KillSignal=SIGTERM

[Install]
WantedBy=multi-user.target
EOF
~~~

~~~
sudo systemctl enable cosmos-exporter
sudo systemctl start cosmos-exporter
sudo systemctl restart cosmos-exporter && sudo journalctl -u cosmos-exporter -f
~~~

## Install node-exporter

~~~
cd $HOME
wget https://github.com/prometheus/node_exporter/releases/download/v1.5.0/node_exporter-1.5.0.linux-amd64.tar.gz
tar -xvf node_exporter-1.5.0.linux-amd64.tar.gz
sudo mv $HOME/node_exporter-1.5.0.linux-amd64/node_exporter /usr/local/bin/
rm -rf node_exporter*
~~~

## Add user

~~~
sudo useradd -rs /bin/false exporter
~~~

## Create service file and start node_exporter

~~~
sudo tee <<EOF >/dev/null /etc/systemd/system/exporter.service
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=exporter
Group=exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF
~~~

~~~
sudo systemctl enable exporter
sudo systemctl start exporter
sudo systemctl status exporter && sudo journalctl -u exporter -f
~~~

## Open following ports:

- node_exporter port: 9100
- cosmos_exporter port: 9300

Check your node_exporter metrics http://<ip_address>:9100

# Install monitoring stack, Monitor stack needs to be deployed on seperate machine

### Recommended Hardware Requirements

- 1 VCPU
- 2 GB RAM
- 20 GB SSD

## Update packages and Install dependencies

~~~
sudo apt update && sudo apt upgrade -y
sudo apt-get install curl build-essential ca-certificates gnupg git wget jq make gcc tmux pkg-config libssl-dev libleveldb-dev tar -y
~~~ 

# Install dependencies

~~~
sudo apt install jq -y
sudo apt install python3-pip -y
sudo pip install yq
~~~

## Install docker and docker-compose

~~~bash
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update && sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
~~~

## install docker-compose

~~~
docker_compose_version=$(wget -qO- https://api.github.com/repos/docker/compose/releases/latest | jq -r ".tag_name")
sudo curl -L "https://github.com/docker/compose/releases/download/${docker_compose_version}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version
~~~

Install monitoring stack

~~~
cd $HOME
git clone https://github.com/kj89/cosmos_node_monitoring.git
chmod +x $HOME/cosmos_node_monitoring/add_validator.sh
~~~

## Optional: Configure Telegram alerting
Open telegram and find @BotFather 
- Create telegram bot via @BotFather, customize it and get bot API token [how_to](https://www.siteguarding.com/en/how-to-get-telegram-bot-api-token)
- Create the group: alarm . Customize them, add the bot in your chat and get chats IDs [how_to](https://stackoverflow.com/questions/32423837/telegram-bot-how-to-get-a-group-chat-id)
- Open config .env file 

~~~
cp $HOME/cosmos_node_monitoring/config/.env.example $HOME/cosmos_node_monitoring/config/.env
nano $HOME/cosmos_node_monitoring/config/.env
~~~

>change enabled: no to enabled: yes
api_key: '5555555555:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' to  api_key: '<YOUR_TELEGRAM_BOT_TOKEN>'
channel: "-666666666" to channel: "<YOUR_TELEGRAM_USER_ID>"


## Add validator into configuration file
To add validator use command with specified 'VALIDATOR_IP', 'PROM_PORT', 'VALOPER_ADDRESS', 'WALLET_ADDRESS' and 'PROJECT_NAME'
>example: $HOME/cosmos_node_monitoring/add_validator.sh 1.11.1 26660 humanvaloper14acd299ds9q3qf09gjqw9qvvzwmla8g7nhhg8k human14acd299ds9q3qf09gjqw9qvvzwmla8g7lyd8vn humans

~~~
$HOME/cosmos_node_monitoring/add_validator.sh VALIDATOR_IP PROM_PORT VALOPER_ADDRESS WALLET_ADDRESS PROJECT_NAME
~~~

## Run docker compose

~~~
cd $HOME/cosmos_node_monitoring
sudo docker compose up -d
~~~

ports used:

- 8080 (alertmanager-bot)
- 9090 (prometheus)
- 9093 (alertmanager)
- 9999 (grafana)

## Configure grafana

Open Grafana in your web browser http://<IP_ADDRESS>:9999

defaul user - admin, password -admin
