Update version and build binaries

~~~bash
cd $HOME
cd nym
git fetch
git restore Cargo.lock
git checkout release/v1.1.4
cargo build
~~~

Move binaries, add permissions

~~~bash
mv $HOME/nym/target/debug/nym-mixnode $HOME/go/bin/nym-mixnode
chmod u+x $HOME/go/bin/nym-mixnode
~~~

Check version

~~~bash
nym-mixnode version
~~~

Restart service and check log

~~~bash
sudo systemctl restart nym-mixnode && sudo journalctl -u nym-mixnode -f
~~~

Open Nym wallet application, go to  Bonding -> Node Setting and update version to 1.1.4
