## Upgrade to v0.8.1
height: 133100 

~~~bash
sudo systemctl stop lavad

cd $HOME
rm -rf $HOME/lava
git clone https://github.com/lavanet/lava.git
cd lava
git checkout v0.8.1
make install

sudo systemctl start lavad
sudo journalctl -u lavad -f --no-hostname -o cat
~~~
