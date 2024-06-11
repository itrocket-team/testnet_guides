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

### Set Environment

### Manage Keys

### Explore More Node Operations

**Nubit explorer to check the transactions: https://explorer.nubit.org/.**
