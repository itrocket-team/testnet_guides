## RPC Scanner Information

Our RPC scanner actively scans the network and finds all public RPC addresses, checking whether each RPC is archival or not.

However, **if your RPC port is not open to the public** and you are using a DNS address with proxying, you need to manually add your RPC URL in JSON format to the following files to ensure it appears on the RPC dashboard:

- **COSMOS RPCs**: [tendermint_rpc.json](https://github.com/itrocket-team/testnet_guides/blob/main/story/tendermint_rpc.json)
- **EVM RPCs**: [evm_rpc.json](https://github.com/itrocket-team/testnet_guides/blob/main/story/evm_rpc.json)
