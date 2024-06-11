# Nubit Guide: Light Node Setup & Interacting with DA 

## 1. Run a Light Node
We will run a node with a service file.

Create the service file and open it:
~~~
sudo nano /etc/systemd/system/nubitd
~~~

Insert the following into the file and save it (`Ctrl-X`, `y`, `Enter`):
~~~
[Unit]
Description=Nubit Node Service
After=network.target

[Service]
ExecStart=/bin/bash -c 'curl -sL1 https://nubit.sh | bash'
Restart=always
User=nobody
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
~~~

Reload the systemd configuration
~~~
sudo systemctl daemon-reload
~~~

Start the service
~~~
sudo systemctl start nubitd
~~~

Enable and restart the service
~~~
sudo systemctl enable nubit.service
sudo systemctl restart humansd && sudo journalctl -u humansd -f
~~~


## 2. Interact with Nubit DA

~~~

~~~
