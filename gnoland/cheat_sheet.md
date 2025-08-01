### Service Operations
Reload service
```
sudo systemctl daemon-reload
```

Enable service
```
sudo systemctl enable gnoland
```

Disable service
```
sudo systemctl disable gnoland
```

Start service
```
sudo systemctl start gnoland
```

Stop service
```
sudo systemctl stop gnoland
```

Restart service
```
sudo systemctl restart gnoland
```

View service status
```
sudo systemctl status gnoland
```

View service logs
```
sudo journalctl -u gnoland -f --no-hostname -o cat
```

Delete node
```
sudo systemctl stop gnoland && sudo systemctl disable gnoland && sudo rm /etc/systemd/system/gnoland.service && sudo systemctl daemon-reload && sudo rm -rf $(which gnoland) && sudo rm -rf $(which gnogenesis) && sudo rm -rf $(which gnokey) && rm -rf $HOME/gnoland-data && rm -rf $HOME/gno
```

### Key Management
Add new wallet
```
gnokey add wallet
```

Restore executing wallet
```
gnokey add wallet --recover
```

List all wallets
```
gnokey list -home /home/gnoland/gnoland-data/
```

Delete wallet
```
gnokey delete wallet
```

Check wallet balance
```
gnokey query -remote "https://rpc.test7.testnets.gno.land:443" auth/accounts/$ADDRESS - ????
```

### Node and Validator info
View validator key
```
gnoland secrets get validator_key
```

View node info
```
curl -s localhost:54657/status | jq
```
