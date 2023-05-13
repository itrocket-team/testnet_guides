<div>
<h1 align="left" style="display: flex;"> Humans testnet humans_3000-23</h1>
<img src="https://github.com/itrocket-team/testnet_guides/blob/main/logos/humans.jpg"  style="float: right;" width="100" height="100"></img>
</div>

# Restart your validator three times during Mission 2

### Restart 1 - 2023-05-13 11:13:29 CEST

~~~bash
humans@Ubuntu-2004-focal-64-minimal:~$ sudo systemctl restart humansd && sudo journalctl -u humansd -f
-- Logs begin at Sat 2023-05-13 11:13:29 CEST. --
May 13 12:31:07 Ubuntu-2004-focal-64-minimal humansd[1566582]: 12:31PM INF received complete proposal block hash=2ED42FED4AA58ED57F8372E18F15CD846D89184720B8E0AF13C0747009A962E3 height=29147 module=consensus server=node
May 13 12:31:08 Ubuntu-2004-focal-64-minimal humansd[1566582]: 12:31PM INF finalizing commit of block hash={} height=29147 module=consensus num_txs=0 root=4B7EC954F0CA896C6174923BAB993630DFD7EA3FC11EE28E42D1A109344BE1E5 server=node
May 13 12:31:08 Ubuntu-2004-focal-64-minimal humansd[1566582]: 12:31PM INF executed block height=29147 module=state num_invalid_txs=0 num_valid_txs=0 server=node
May 13 12:31:08 Ubuntu-2004-focal-64-minimal humansd[1566582]: 12:31PM INF commit synced commit=436F6D6D697449447B5B313831203431203131312031303420323232203531203231372033322032333120383320333920313937203235322032333920313932203233312030203232203420313135203930203830203335203537203232382030203134332032313820353520313933203139382032345D3A373144427D
May 13 12:31:08 Ubuntu-2004-focal-64-minimal humansd[1566582]: 12:31PM INF committed state app_hash=B5296F68DE33D920E75327C5FCEFC0E7001604735A502339E4008FDA37C1C618 height=29147 module=state num_txs=0 server=node
May 13 12:31:08 Ubuntu-2004-focal-64-minimal humansd[1566582]: 12:31PM INF indexed block exents height=29147 module=txindex server=node
May 13 12:31:08 Ubuntu-2004-focal-64-minimal systemd[1]: Stopping Humans node...
May 13 12:31:08 Ubuntu-2004-focal-64-minimal systemd[1]: humansd.service: Succeeded.
May 13 12:31:08 Ubuntu-2004-focal-64-minimal systemd[1]: Stopped Humans node.
May 13 12:31:08 Ubuntu-2004-focal-64-minimal systemd[1]: Started Humans node.
May 13 12:31:10 Ubuntu-2004-focal-64-minimal humansd[1583718]: 12:31PM INF Replay: New Step height=29148 module=consensus round=0 server=node step=RoundStepNewHeight
May 13 12:31:10 Ubuntu-2004-focal-64-minimal humansd[1583718]: 12:31PM INF Replay: Vote blockID={"hash":"2ED42FED4AA58ED57F8372E18F15CD846D89184720B8E0AF13C0747009A962E3","parts":{"hash":"52817D67B9A05C3D9A4271BAC67912749662A24C8F843078A3B4296E5C5E3228","total":1}} height=29147 module=consensus peer=dd531a4634ba06ceea5ac37f883cbc3bf1dd4556 round=0 server=node type=2
May 13 12:31:14 Ubuntu-2004-focal-64-minimal humansd[1583718]: 12:31PM INF commit synced commit=436F6D6D697449447B5B323235203137332031363920313930203135382031383520323533203631203136312032313120313339203230352031383520333420313233203137392038382031393120353620323420313034203733203337203938203134322031373720313639203231342031322038203233362034395D3A373144437D
May 13 12:31:14 Ubuntu-2004-focal-64-minimal humansd[1583718]: 12:31PM INF committed state app_hash=E1ADA9BE9EB9FD3DA1D38BCDB9227BB358BF3818684925628EB1A9D60C08EC31 height=29148 module=state num_txs=0 server=node
May 13 12:31:14 Ubuntu-2004-focal-64-minimal humansd[1583718]: 12:31PM INF indexed block exents height=29148 module=txindex server=node
~~~

### Restart 2 - 2023-05-13 11:26:58 CEST

~~~bash
humans@Ubuntu-2004-focal-64-minimal:~$ sudo systemctl restart humansd && sudo journalctl -u humansd -f
-- Logs begin at Sat 2023-05-13 11:26:58 CEST. --
May 13 12:41:37 Ubuntu-2004-focal-64-minimal systemd[1]: Stopped Humans node.
May 13 12:41:37 Ubuntu-2004-focal-64-minimal systemd[1]: Started Humans node.
May 13 12:41:37 Ubuntu-2004-focal-64-minimal systemd[1]: humansd.service: Succeeded.
May 13 12:41:37 Ubuntu-2004-focal-64-minimal humansd[2328436]: 12:41PM INF This node is a validator addr=FAD460A6E19AB1DBE52A56D55923FECE48BA0F04 module=consensus pubKey=PV86mETuowx7jyW4a1nOjKn6RXuREnXXcInh9o4/Fgs= server=node
May 13 12:41:38 Ubuntu-2004-focal-64-minimal humansd[2328436]: 12:41PM INF Searching for height height=29251 max=2219 min=2121 module=consensus server=node wal=/home/humans/.humansd/data/cs.wal/wal
May 13 12:41:38 Ubuntu-2004-focal-64-minimal humansd[2328436]: 12:41PM INF Searching for height height=29250 max=2219 min=2121 module=consensus server=node wal=/home/humans/.humansd/data/cs.wal/wal
May 13 12:41:39 Ubuntu-2004-focal-64-minimal humansd[2328436]: 12:41PM INF Found height=29250 index=2219 module=consensus server=node wal=/home/humans/.humansd/data/cs.wal/wal
May 13 12:41:39 Ubuntu-2004-focal-64-minimal humansd[2328436]: 12:41PM INF Catchup by replaying consensus messages height=29251 module=consensus server=node
May 13 12:41:39 Ubuntu-2004-focal-64-minimal humansd[2328436]: 12:41PM INF Replay: New Step height=29251 module=consensus round=0 server=node step=RoundStepNewHeight
May 13 12:41:39 Ubuntu-2004-focal-64-minimal humansd[2328436]: 12:41PM INF Replay: Vote blockID={"hash":"A1611534A8D056C92CD03324C4843EC674138DBB1CD45835A5C03E1D6A24530B","parts":{"hash":"2B99230A9EF59246C6DCBF632F2A5C97F72DDCBF57ACAFEBB8ADEFC66397CD00","total":1}} height=29250 module=consensus peer=6ce9a9acc23594ec75516617647286fe546f83ca round=0 server=node type=2
May 13 12:41:39 Ubuntu-2004-focal-64-minimal humansd[2328436]: 12:41PM INF received proposal module=consensus proposal={"Type":32,"block_id":{"hash":"D64B17EB9013DA5EC9E4DF3ED078FD45E43CE75E002DEF27BD42D2F8B020377B","parts":{"hash":"0DA2DC4C8AA0DE2AB3B889C94979691354AB55984D02B6BC182FA3B295EEA087","total":1}},"height":29251,"pol_round":-1,"round":0,"signature":"r0BaB5LMs/P4oFAr2t8AVZsry/MRb+lGbm/TsiP42vs0U4wb9S8Ajb/qkYlNmOm+IWgy3QUcZ4og3z5TQPR5BA==","timestamp":"2023-05-13T10:41:38.54943347Z"} server=node
May 13 12:41:39 Ubuntu-2004-focal-64-minimal humansd[2328436]: 12:41PM INF received complete proposal block hash=D64B17EB9013DA5EC9E4DF3ED078FD45E43CE75E002DEF27BD42D2F8B020377B height=29251 module=consensus server=node
May 13 12:41:39 Ubuntu-2004-focal-64-minimal humansd[2328436]: 12:41PM INF finalizing commit of block hash={} height=29251 module=consensus num_txs=0 root=2D3492C3FC8ECFADF7D3DF2153861F75EB33B1F25D06C807F4CC262196ACABCB server=node
May 13 12:41:39 Ubuntu-2004-focal-64-minimal humansd[2328436]: 12:41PM INF executed block height=29251 module=state num_invalid_txs=0 num_valid_txs=0 server=node
May 13 12:41:39 Ubuntu-2004-focal-64-minimal humansd[2328436]: 12:41PM INF commit synced commit=436F6D6D697449447B5B323139203230322031373320333420323435203231352031343320383920313533203133362031323720323135203134302032333320393520363520313234203438203234392033362032343220323920313332203231203737203533203238203132372032323920333520313935203134345D3A373234337D
May 13 12:41:39 Ubuntu-2004-focal-64-minimal humansd[2328436]: 12:41PM INF committed state app_hash=DBCAAD22F5D78F5999887FD78CE95F417C30F924F21D84154D351C7FE523C390 height=29251 module=state num_txs=0 server=node
May 13 12:41:39 Ubuntu-2004-focal-64-minimal humansd[2328436]: 12:41PM INF indexed block exents height=29251 module=txindex server=node
~~~

### Restart 3 - 2023-05-13 11:40:28 CEST

~~~
sudo systemctl restart humansd && sudo journalctl -u humansd -f
-- Logs begin at Sat 2023-05-13 11:40:28 CEST. --
May 13 12:49:26 Ubuntu-2004-focal-64-minimal humansd[2328436]: 12:49PM ERR Stopped accept routine, as transport is closed module=p2p numPeers=0 server=node
May 13 12:49:26 Ubuntu-2004-focal-64-minimal humansd[2328436]: 12:49PM INF Closing rpc listener listener={"Listener":{}} server=node
May 13 12:49:26 Ubuntu-2004-focal-64-minimal humansd[2328436]: 12:49PM INF RPC HTTP server stopped err="accept tcp [::]:26657: use of closed network connection" module=rpc-server server=node
May 13 12:49:26 Ubuntu-2004-focal-64-minimal systemd[1]: humansd.service: Succeeded.
May 13 12:49:26 Ubuntu-2004-focal-64-minimal systemd[1]: Stopped Humans node.
May 13 12:49:26 Ubuntu-2004-focal-64-minimal systemd[1]: Started Humans node.
May 13 12:49:26 Ubuntu-2004-focal-64-minimal humansd[2883157]: 12:49PM INF Unlocking keyring
May 13 12:49:26 Ubuntu-2004-focal-64-minimal humansd[2883157]: 12:49PM INF starting ABCI with Tendermint
May 13 12:49:28 Ubuntu-2004-focal-64-minimal humansd[2883157]: 12:49PM INF service start impl=TimeoutTicker module=consensus msg={} server=node
May 13 12:49:28 Ubuntu-2004-focal-64-minimal humansd[2883157]: 12:49PM INF Searching for height height=29327 max=2222 min=2124 module=consensus server=node wal=/home/humans/.humansd/data/cs.wal/wal
May 13 12:49:28 Ubuntu-2004-focal-64-minimal humansd[2883157]: 12:49PM INF Searching for height height=29326 max=2222 min=2124 module=consensus server=node wal=/home/humans/.humansd/data/cs.wal/wal
May 13 12:49:28 Ubuntu-2004-focal-64-minimal humansd[2883157]: 12:49PM INF Found height=29326 index=2222 module=consensus server=node wal=/home/humans/.humansd/data/cs.wal/wal
May 13 12:49:28 Ubuntu-2004-focal-64-minimal humansd[2883157]: 12:49PM INF Catchup by replaying consensus messages height=29327 module=consensus server=node
May 13 12:49:28 Ubuntu-2004-focal-64-minimal humansd[2883157]: 12:49PM INF Replay: New Step height=29327 module=consensus round=0 server=node step=RoundStepNewHeight
May 13 12:49:28 Ubuntu-2004-focal-64-minimal humansd[2883157]: 12:49PM INF Replay: Vote blockID={"hash":"52FCD4D9B201FFF752D906BE13D907A7291D08344FB26B375891CFB17186DB6B","parts":{"hash":"E5EF91FCBCB13D9E483819DAA649E8C1532A4EF557A5F5C78181F854ED354EC3","total":1}} height=29326 module=consensus peer=b99df5397a6104fac055f21195f1fb25b77f5704 round=0 server=node type=2
May 13 12:49:30 Ubuntu-2004-focal-64-minimal humansd[2883157]: 12:49PM INF finalizing commit of block hash={} height=29327 module=consensus num_txs=0 root=2BDC69BBE157020723FB48062C88BD33C34459A29904A20EEA869673D7FAE20E server=node
May 13 12:49:30 Ubuntu-2004-focal-64-minimal humansd[2883157]: 12:49PM INF executed block height=29327 module=state num_invalid_txs=0 num_valid_txs=0 server=node
May 13 12:49:31 Ubuntu-2004-focal-64-minimal humansd[2883157]: 12:49PM INF commit synced commit=436F6D6D697449447B5B3235342032343820363520313938203132372031323420313339203231203136203133362031383820323232203439203137342038332032323920313138203338203536203133342032332031343020313636203520343720333120323037203639203135392034392030203130335D3A373238467D
May 13 12:49:31 Ubuntu-2004-focal-64-minimal humansd[2883157]: 12:49PM INF committed state app_hash=FEF841C67F7C8B151088BCDE31AE53E576263886178CA6052F1FCF459F310067 height=29327 module=state num_txs=0 server=node
May 13 12:49:31 Ubuntu-2004-focal-64-minimal humansd[2883157]: 12:49PM INF indexed block exents height=29327 module=txindex server=node
~~~

