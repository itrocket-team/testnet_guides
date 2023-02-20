## Upgrade to v0.6.0-RC3
height: 82570

~~~bash
sudo systemctl stop lavad

cd $HOME
rm -rf $HOME/lava
git clone https://github.com/lavanet/lava.git
cd lava
git checkout v0.6.0-RC3
make install

sudo systemctl start lavad
sudo journalctl -u lavad -f --no-hostname -o cat
~~~
