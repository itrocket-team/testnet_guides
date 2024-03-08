Template, under construction...

Update aut
~~~
pipx install --force git+https://github.com/autonity/aut
aut --version
#aut, version 0.4.0.dev0
~~~

Stop node
~~~
sudo systemctl stop antony
~~~

Delete old data
~~~
cd ~/autonity-chaindata/autonity/chaindata/
rm -rf *
~~~

Update autonity
~~~
cd
rm -rf autonity
git clone https://github.com/autonity/autonity && cd autonity
git checkout tags/v0.13.0 -b v0.13.0
make autonity
sudo mv $HOME/autonity/build/bin/autonity /usr/local/bin/
~~~

Restart node
~~~
sudo systemctl restart antony && journalctl -u antony -f -o cat
~~~

Update Oracle
~~~
sudo systemctl stop antoracle.service
cd
rm -rf autonity-oracle
git clone https://github.com/autonity/autonity-oracle && cd autonity-oracle
git fetch --all 
git checkout v0.1.6 
make autoracle
sudo mv build/bin/autoracle /usr/local/bin
autoracle version
#v0.1.6
~~~
