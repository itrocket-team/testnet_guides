Template, under construction...
~~~
pipx install --force git+https://github.com/autonity/aut
aut --version
#aut, version 0.4.0.dev0
~~~

~~~
sudo systemctl stop antony
~~~

~~~
cd ~/autonity-chaindata/autonity/chaindata/
rm -rf *
~~~

~~~
cd
rm -rf autonity
git clone https://github.com/autonity/autonity && cd autonity
git checkout tags/v0.13.0 -b v0.13.0
make autonity
sudo mv $HOME/autonity/build/bin/autonity /usr/local/bin/
~~~

~~~
sudo systemctl daemon-reload
sudo systemctl restart antony && journalctl -u antony -f -o cat
~~~
