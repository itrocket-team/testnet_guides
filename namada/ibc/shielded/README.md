# Shielded IBC Application
Our Bash script streamlines the process of performing shielded transactions within the Namada network and executing Shielded IBC transactions with various networks from any Linux server. The script is fully automated, including the creation of proof, puting the content of the memo, as well as installing the necessary binaries, among other features.

**Shielded transactions:**  
1. Namada    -->   Osmosis
2. Osmosis   -->   Namada
3. Namada    -->   Celestia
4. Celestia  -->   Namada
5. Namada internal transfer (shielding, shielded, unshielding)

### Key Functions of the Script:

- **Dependency Management:** Checks for and installs any necessary dependencies, ensuring the environment is properly set up for transactions.

- **Binary Management:** Checks for, installs, or updates the binary files for required networks (i.e., Namada, Osmosis, Celestia), based on the specific transaction direction and type chosen by the user.

- **Wallet Verification and Management:** It verifies the existence of wallets necessary for the transaction. If a wallet does not exist, the script offers options to either create a new wallet or recover an existing one.

- **Balance Display and Token Selection:** Users can view their wallet balance, displaying all tokens contained within. The script also facilitates the selection of the specific token and the amount to be sent in the shielded transaction.

- **Transaction Execution:** It conducts the shielded IBC transaction and provides the transaction hash upon completion. This includes automatic generation of proofs if necessary and their insertion in the memo field.

- **User-Centric Design:** Designed for straightforward use without the need for pre-installed nodes or complex configurations. Transactions are executed via RPC, simplifying the process for users.
Interactive Guidance: Offers interactive prompts for various actions like wallet creation, recovery, and transaction execution, guiding users through each step.

In essence, this script is a powerful tool for anyone looking to engage with shielded transactions and cross-network operations without delving into the complexities of performing these actions in basic CLI context.

_The functionality is planned to be recharged with new chains and other transaction types. Also, since shielded transactions from Namada are not available, there might be issues which couldn't have been tested. They will be managed as soon as shielded actions are back._
