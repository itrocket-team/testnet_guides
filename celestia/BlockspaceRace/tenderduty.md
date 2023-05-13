# Celestia Validator protecting and monitoring guide with tenderduty

## Update packages and Install dependencies

~~~
sudo apt update && sudo apt upgrade -y
sudo apt install curl build-essential git wget jq make gcc tmux pkg-config libssl-dev libleveldb-dev tar -y
~~~

## Install go

~~~
ver="1.18.2"
cd $HOME
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
rm "go$ver.linux-amd64.tar.gz"
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.bash_profile
source ~/.bash_profile
go version
~~~

## Add user and install tenderduty

~~~
sudo useradd -rs /bin/false tenderduty
cd $HOME
git clone https://github.com/blockpane/tenderduty
cd tenderduty
go install
cp example-config.yml config.yml
~~~

## Open config.yml file 

~~~
nano $HOME/tenderduty/config.yml
~~~

For simple monitoring without notifications, just change these in the config:
- `celestia to` <PROJECT_NAME>
- chain_id: `blockspacerace-0` to chain_id: <YOUR_CHAIN_ID> 
- valoper_address: celestiavaloper1xxxxxxx... to valoper_address: <YOUR_VALOPER_ADDRESS>
- `url: tcp://localhost:<VALIDATOR_NODE_RPC_PORT>` TO url: tcp://localhost:<YOUR_NODE_RPC_PORT>

<img src="https://github.com/itrocket-team/patterns/blob/main/utils/celestia_1.jpg" alt="image" style="max-width: 100%;">
<img src="https://github.com/itrocket-team/patterns/blob/main/utils/Celestia_2.jpg" alt="image" style="max-width: 100%;">

## Optional 
If you want to add another node monitoring, you can dublicate this section on conf.yml file

~~~chains:

  # The user-friendly name that will be used for labels. Highly suggest wrapping in quotes.
  "Celestia":
    # chain_id is validated for a match when connecting to an RPC endpoint, also used as a label in several places.
    chain_id: blockspacerace-0
    # Hooray, in v2 we derive the valcons from abci queries so you don't have to jump through hoops to figure out how
    # to convert ed25519 keys to the appropriate bech32 address
    valoper_address: celestiavaloper1xxxxxxx...
    # Should the monitor revert to using public API endpoints if all supplied RCP nodes fail?
    # This isn't always reliable, not all public nodes have websocket proxying setup correctly.
    public_fallback: no

    # Controls various alert settings for each chain.
    alerts:
      # If the chain stops seeing new blocks, should an alert be sent?
      stalled_enabled: yes
      # How long a halted chain takes in minutes to generate an alarm
      stalled_minutes: 10

      # Most basic alarm, you just missed x blocks ... would you like to know?
      consecutive_enabled: yes
      # How many missed blocks should trigger a notification?
      consecutive_missed: 5
      # NOT USED: future hint for pagerduty's routing
      consecutive_priority: critical

      # For each chain there is a specific window of blocks and a percentage of missed blocks that will result in
      # a downtime jail infraction. Should an alert be sent if a certain percentage of this window is exceeded?
      percentage_enabled: no
      # What percentage should trigger the alert
      percentage_missed: 10
      # Not used yet, pagerduty routing hint
      percentage_priority: warning

      # Should an alert be sent if the validator is not in the active set ie, jailed,
      # tombstoned, unbonding?
      alert_if_inactive: yes
      # Should an alert be sent if no RPC servers are responding? (Note this alarm is instantaneous with no delay)
      alert_if_no_servers: yes

      # for this *specific* chain it's possible to override alert settings. If the api_key or webhook addresses are empty,
      # the global settings will be used. Note, enabled must be set both globally and for each chain.

      # Chain specific setting for pagerduty
      pagerduty:
        enabled: yes
        api_key: "" # uses default if blank

      # Discord settings
      discord:
        enabled: yes
        webhook: "" # uses default if blank

      # Telegram settings
      telegram:
        enabled: yes
        api_key: "" # uses default if blank
        channel: "" # uses default if blank

    # This section covers our RPC providers. No LCD (aka REST) endpoints are used, only TM's RPC endpoints
    # Multiple hosts are encouraged, and will be tried sequentially until a working endpoint is discovered.
    nodes:
      # URL for the endpoint. Must include protocol://hostname:port
      - url: tcp://localhost:26657
        # Should we send an alert if this host isn't responding?
        alert_if_down: yes
      # repeat hosts for monitoring redundancy
      - url: https://some-other-node:443
        alert_if_down: no
~~~

## Create service file and start tenderduty

~~~
sudo tee /etc/systemd/system/tenderdutyd.service << EOF
[Unit]
Description=Tenderduty
After=network.target

[Service]
Type=simple
Restart=always
RestartSec=5
TimeoutSec=180

User=tenderduty
WorkingDirectory=$HOME/tenderduty
ExecStart=$(which tenderduty)

# there may be a large number of network connections if a lot of chains
LimitNOFILE=infinity

# extra process isolation
NoNewPrivileges=true
ProtectSystem=strict
RestrictSUIDSGID=true
LockPersonality=true
PrivateUsers=true
PrivateDevices=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
~~~

~~~
sudo systemctl daemon-reload
sudo systemctl enable tenderdutyd
sudo systemctl start tenderdutyd && sudo journalctl -fu tenderdutyd
~~~

> You can open dashboard on web browser by using tenderduty port and your server IP http://<YOUR_SERVER_IP>:<PORT>
Default port on tenderduty is 8888

## Turn on firewall to protect your server and open the required port
>Default P2P port is 26656, prometheus - 26660 and tenderduty - 8888. if you have custom ports on your node or have another nodes in this server, check it and open custom ports!

~~~
sudo apt install ufw 
sudo ufw default allow outgoing 
sudo ufw default deny incoming 
sudo ufw allow ssh/tcp 
sudo ufw limit ssh/tcp 
sudo ufw allow 26656,26660,8888/tcp
sudo ufw enable
~~~

Configure Telegram alerting
Open telegram and find @BotFather 
- Create telegram bot via @BotFather, customize it and get bot API token [how_to](https://www.siteguarding.com/en/how-to-get-telegram-bot-api-token)
- Create the group: alarm . Customize them, add the bot in your chat and get chats IDs [how_to](https://stackoverflow.com/questions/32423837/telegram-bot-how-to-get-a-group-chat-id)
- Open config.yml file 
>change enabled: no to enabled: yes
api_key: '5555555555:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' to  api_key: '<YOUR_BOT_API_KEY>'
channel: "-666666666" to channel: "<YOUR_GROUP_CHAT_ID>"

~~~
nano $HOME/tenderduty/config.yml
~~~

## Restart tenderduty

~~~
sudo systemctl restart tenderdutyd && sudo journalctl -fu tenderdutyd
~~~

Congratulations! You have set up a monitoring and alert system
