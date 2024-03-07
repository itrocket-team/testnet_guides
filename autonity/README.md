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
--bootnodes enode://772248dfe1af5f77e0efc0510e83364bfad55cbd6d3e276f3bd0b4ddec6472aa98645655fd80bbf049ba3da18d219ab30a68fcb98da8e06dd42863dd0356cc95@35.242.168.170:30303,enode://24b2655b0434d1af4e2329cababf38963cab8a154e0b8c9748e75c85d10d7dab5032af7a41f3ec06dd1a7d3d306f1edee5dc46dad7a2858b80ebb56e5fa24925@34.233.111.193:30303,enode://a20e27effd92dc11e7340e96a6f2908124ea363e6b68af34cad2a46a9ffdc6f5d4f516acec7f98949cc25955269f7842dc513444902c21239155de7e70b86a87@65.109.160.27:30303,enode://a2ea938a325381c7b163e7a3ca1a63fcfd927a81cadcf86551ad29f2f3ed05ef06f0b3a5d10ca932d0b85b3cf9a7c7956bf5398a2c9322f941817c92f9f62105@37.252.184.235:30303,enode://46f4abe3aeca863ce3a1b4a2b2fce3112476ca75a20039ef4bad78e1a2171ae36404d74b08a0c5a8720e2548d296d37e0b92062c096801b3f6d2d86e4e9da2f2@46.4.32.57:30303,enode://84c9a23b75bcd0252e0b361f6962a9f360d38f4fe5206cfb2d907074de877edbb1b810fd9cecf2fa64aa6ec4f7816a7f238650d489eaa82d68e8660769c6763d@51.91.220.174:30303,enode://11dd1e9d4a68fb07e4cbd60d225c6ffea45852ac3d4e17df3a086a7d27ee05698922e7474db4dbcef14a11e3dd44bf66a52160610bd43a890fdc1bc8a2f51393@65.109.69.239:30303,enode://700ae526623b87a748acf278cee299d970ccde4e4d6e7aa7685f4a550500b6e53b84892e37c2c10516673f45253fcb824d8e1836ee91a92a16b66b85b8000642@93.115.25.90:30303
~~~

~~~
sudo systemctl daemon-reload
sudo systemctl restart antony && journalctl -u antony -f -o cat
~~~

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
