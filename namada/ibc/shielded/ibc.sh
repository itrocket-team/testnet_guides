#!/bin/bash

rpc_nam="https://namada-testnet-rpc.itrocket.net:443"
rpc_tia="https://celestia-testnet-rpc.itrocket.net:443"
rpc_osmo="http://65.109.62.39:15657"

nam_osmo_ch="channel-1335"
osmo_nam_ch="channel-7760"
nam_tia_ch="channel-1324"
tia_nam_ch="channel-83"


######################################### Design functions ##############################################

GREEN="\e[1m\e[1;92m"
RED="\e[1m\e[1;35m" 
BLUE="\e[1m\e[1;34m"
CYAN="\e[1m\e[1;36m" 
YELLOW="\e[1m\e[1;93m"
NC="\e[0m" 
NAMADA_VER="v0.32.1"
CELESTIA_VER="1.7.0"
OSMOSIS_VER="24.0.0-rc0"

function printLine {
  echo "------------------------------------------------------------------------------------"
}

function printGreen {
  echo -e "${GREEN}${1}${NC}"
}

function printRed {
  echo -e "${RED}${1}${NC}"
}

function printCyan {
  echo -e "${CYAN}${1}${NC}"
}

function printYellow {
  echo -e "${YELLOW}${1}${NC}"
}

function addToPath {
  source $HOME/.bash_profile
  PATH_EXIST=$(grep "${1}" $HOME/.bash_profile)
  if [ -z "$PATH_EXIST" ]; then
    echo "export PATH=\$PATH:${1}" >> $HOME/.bash_profile
  fi
}


########################################### Installation functions ###########################################

function installNamada {
  echo "Starting Namada installation..."
  cd $HOME
  rm -rf $HOME/namada
  git clone https://github.com/anoma/namada
  cd namada
  wget "https://github.com/anoma/namada/releases/download/${NAMADA_VER}/namada-${NAMADA_VER}-Linux-x86_64.tar.gz"
  tar -xvf "namada-${NAMADA_VER}-Linux-x86_64.tar.gz"
  rm "namada-${NAMADA_VER}-Linux-x86_64.tar.gz"
  cd "namada-${NAMADA_VER}-Linux-x86_64"
  sudo mv namad* /usr/local/bin/
  if [ ! -d "$HOME/.local/share/namada" ]; then
    mkdir -p "$HOME/.local/share/namada"
  fi
  echo "Namada installation completed."
}

function installOsmosis {
  echo "Starting Osmosis installation..."
  cd $HOME
  rm -rf $HOME/osmosis
  git clone https://github.com/osmosis-labs/osmosis osmosis
  cd osmosis
  git checkout v${OSMOSIS_VER}
  make install
  echo "Osmosis installation completed."
}

function installCelestia {
  echo "Starting Celestia installation..."
  cd $HOME
  rm -rf $HOME/celestia-app
  git clone https://github.com/celestiaorg/celestia-app.git
  cd celestia-app/
  git checkout tags/v${CELESTIA_VER} -b v${CELESTIA_VER}
  make install
  echo "Celestia installation completed."
}

function checkNamada {
  needInstall=false
  
  printLine
  printCyan "Checking Namada testnet binary..."
  if command -v namada >/dev/null; then
    INSTALLED_VER=$(namada --version | awk '{print $NF}')
    echo "Detected Namada version: $INSTALLED_VER, Required version: $NAMADA_VER"
    sleep 1
    if [ "$INSTALLED_VER" != "$NAMADA_VER" ]; then
      echo "A different version of Namada found. Installing version $NAMADA_VER."
      needInstall=true
    else
      echo "Namada version $NAMADA_VER is already installed. No action needed."
    fi
  else
    echo "Namada not found. Installing version $NAMADA_VER..."
    sleep 1
    needInstall=true
  fi
  
  if [ "$needInstall" = true ]; then
    echo "Namada not found. updating to a new version $NAMADA_VER..."
    installNamada
  fi
  printGreen "done"
}

function checkCelestia {
  printLine
  printCyan "Checking Celestia binary..."
  if command -v celestia-appd >/dev/null; then
    INSTALLED_VER=$(celestia-appd version 2>&1 | tr -d '\n')
    echo "Detected Celestia version: $INSTALLED_VER, Required version: $CELESTIA_VER"
    if [ "$INSTALLED_VER" != "$CELESTIA_VER" ]; then
      echo "A different version of Celestia found. Installing version $CELESTIA_VER."
      installCelestia
    else
      echo "Celestia version $CELESTIA_VER is already installed. No action needed."
    fi
  else
    echo "Celestia is not found. Installing version $CELESTIA_VER."
    installCelestia
  fi
  
  if command -v celestia-appd >/dev/null; then
    echo "Current Celestia version:"
    echo $(celestia-appd version)
  else
    echo "Celestia installation failed."
  fi
}

function checkOsmosis {
  printLine
  printCyan "Checking Osmosis binary..."
  if command -v osmosisd >/dev/null; then
    INSTALLED_VER=$(osmosisd version 2>&1 | tr -d '\n')
    echo "Detected Osmosis version: $INSTALLED_VER, Required version: $OSMOSIS_VER"
    if [ "$INSTALLED_VER" != "$OSMOSIS_VER" ]; then
      echo "A different version of Osmosis found. Installing version $OSMOSIS_VER."
      installOsmosis
    else
      echo "Osmosis version $OSMOSIS_VER is already installed. No action needed."
    fi
  else
    echo "Osmosis is not found. Installing version $OSMOSIS_VER."
    installOsmosis
  fi
  
  if command -v osmosisd >/dev/null; then
    echo "Current osmosisd version:"
    echo $(osmosisd version)
  else
    echo "Osmosis installation failed."
  fi
}


##################################### Wallet check functions #####################################

function check_nam_wallet {
  if [[ -z $nam_wallet ]]; then
    read -rp "$(printCyan "Enter your namada transparent wallet alias:") " nam_wallet
    if echo $(namadaw list) | grep -q "Alias \"$nam_wallet\""; then
      printGreen "Wallet found."
    else
      printRed "Wallet not found. Choose an action"
      echo ""
      read -p "1. Enter another wallet name
2. Recover existing wallet
3. Create new wallet
4. Exit

Your answer: " action
echo ""
      if [[ action -eq 1 ]]; then
        nam_wallet=""
        check_nam_wallet
      elif [[ action -eq 2 ]]; then
        tmpfile=$(mktemp /tmp/derive_output.XXXXXX)
        expect -c "
         set timeout -1
         log_user 1;
         spawn namadaw derive --alias $nam_wallet
         expect \"Enter your encryption password:\"
         interact
         expect \"Enter same passphrase again:\"
         interact
         expect \"Input mnemonic code:\"
         interact
         expect eof
         " | tee $tmpfile
         echo ""
         if grep -q "Failed to derive a keypair." $tmpfile || grep -q "Passphrases did not match" $tmpfile; then
           printRed "Failed to derive the wallet. Please try again."
           nam_wallet=""
           check_nam_wallet
         else
           printGreen "Wallet successfully derived."
         fi
         rm -f $tmpfile
      elif [[ action -eq 3 ]]; then
        expect -c "
        set timeout -1
        log_user 1;
        spawn namadaw gen --alias $nam_wallet
        expect \"Enter your encryption password:\"
        interact
        expect \"Enter same passphrase again:\"
        interact
        expect eof
        "
      elif [[ action -eq 4 ]]; then
        echo "Exiting script."
        exit 0
      fi
    fi
  echo ""
  else
    return 0
  fi
}

function check_nam_shwallet {
    if [[ -z $shielded_sk ]]; then
    read -p "Your namada shielded spending key alias: " shielded_sk
    if echo $(namadaw list) | grep -q "Alias \"$shielded_sk\""; then
      printGreen "Wallet found."
    else
      printRed "Wallet not found. Choose an action:"
      echo ""
      read -p "1. Enter another wallet name
2. Recover existing wallet
3. Create new wallet
4. Exit

Your answer: " action
echo ""
      if [[ action -eq 1 ]]; then
        shielded_sk=""
        check_nam_shwallet
      elif [[ action -eq 2 ]]; then
        tmpfile=$(mktemp /tmp/derive_output.XXXXXX)
        expect -c "
         set timeout -1
         log_user 1;
         spawn namadaw derive --alias $shielded_sk
         expect \"Enter your encryption password:\"
         interact
         expect \"Enter same passphrase again:\"
         interact
         expect \"Input mnemonic code:\"
         interact
         expect eof
         " | tee $tmpfile
         echo ""
         if grep -q "Failed to derive a keypair." $tmpfile || grep -q "Passphrases did not match" $tmpfile; then
           printRed "Failed to derive the wallet. Please try again."
           shielded_sk=""
           check_nam_shwallet
         else
           printGreen "Wallet successfully derived."
         fi
         rm -f $tmpfile
         
      elif [[ action -eq 3 ]]; then
        expect -c "
        set timeout -1
        log_user 1;
        spawn namadaw gen --shielded --alias $shielded_sk
        expect \"Enter your encryption password:\"
        interact
        expect \"Enter same passphrase again:\"
        interact
        expect eof
        "
      elif [[ action -eq 4 ]]; then
        echo "Exiting script."
        exit 0
      fi
    fi
  echo ""
  else
    return 0
  fi
}

function check_nam_shaddr {
    if [[ -z $shielded_addr ]]; then
    read -rp "$(printCyan "Enter your namada shielded ADDRESS alias:") " shielded_addr
    if echo $(namadaw list) | grep -q "\"$shielded_addr\": znam1"; then
      printGreen "Shielded address with alias $shielded_addr found."
    else
      printRed "Shielded address with alias $shielded_addr not found. Choose an action:"
      echo ""
      read -p "1. Enter another shielded address alias
2. Generate a shielded address based on existing or new shielded wallet
3. Exit

Your answer: " action
echo ""
      if [[ action -eq 1 ]]; then
        shielded_addr=""
        check_nam_shaddr
      elif [[ action -eq 2 ]]; then
        check_nam_shwallet
        tmpfile=$(mktemp /tmp/derive_output.XXXXXX)
        expect -c "
        set timeout -1
        log_user 1;
        spawn namadaw gen-payment-addr --key $shielded_sk --alias $shielded_addr
        expect eof
        "
        echo ""
        if grep -q "Unknown" $tmpfile; then
          printRed "Failed to generate the address. Please try again."
          shielded_addr=""
          check_nam_shaddr
        else
          printGreen "Address successfully generated."
        fi
        rm -f $tmpfile
      elif [[ action -eq 3 ]]; then
        echo "Exiting script."
        exit 0
      fi
    fi
  echo ""
  else
    return 0
  fi
}

function getCelestiaWallet {
    if [[ -z "$tia_wallet" ]]; then
    read -rp "$(printCyan "Enter Celestia WALLET alias:") " tia_wallet
    printLine
    fi

    CELESTIA_WALLET_ADDRESS=$(celestia-appd keys show "$tia_wallet" -a)

    if [[ -z "$CELESTIA_WALLET_ADDRESS" ]]; then
        echo "Wallet named '$tia_wallet' not found."
        printLine
        return 1
    fi

    printGreen "Wallet named '$tia_wallet' found with address: $CELESTIA_WALLET_ADDRESS"
}

function createCelestiaWallet {
    if [[ -z "$CELESTIA_WALLET_ADDRESS" ]]; then
        printRed "Celestia wallet named '$tia_wallet' not found. Choose an action:"
        printLine
        echo "1. Enter another wallet name"
        echo "2. Create a new wallet"
        echo "3. Recover a wallet"
        echo "4. Exit"
        printLine
        read -p "Enter your choice (1-4): " CHOICE

        case $CHOICE in
            1)
                read -p $'\033[1;34mEnter Celestia WALLET name:\033[0m ' tia_wallet
                getCelestiaWallet
                if [[ -z "$CELESTIA_WALLET_ADDRESS" ]]; then
                createCelestiaWallet
                fi
                ;;
            2)
                printLine
                celestia-appd keys add "$tia_wallet"
                printGreen "**Important** write this mnemonic phrase in a safe place. It is the only way to recover your account if you ever forget your password."
                echo "Press Enter to continue..."
                printLine
                read -p ""
                getCelestiaWallet
                ;;
            3)
                celestia-appd keys add "$tia_wallet" --recover
                getCelestiaWallet
                ;;
            4)
                echo "Exiting application."
                exit 0
                ;;
            *)
                printRed "Invalid choice. Please enter a number between 1 and 4."
                ;;
        esac
    else
        printLine
    fi
}

function check_tia_wallet {  
  getCelestiaWallet
  createCelestiaWallet
}

function getOsmosisWallet {
    if [[ -z "$osmo_wallet" ]]; then
    read -rp "$(printCyan "Enter Osmosis WALLET alias:") " osmo_wallet
    printLine
    fi

    OSMOSIS_WALLET_ADDRESS=$(osmosisd keys show "$osmo_wallet" -a)

    if [[ -z "$OSMOSIS_WALLET_ADDRESS" ]]; then
        echo "Wallet named '$osmo_wallet' not found."
        printLine
        return 1
    fi

    printGreen "Wallet named '$osmo_wallet' found with address: $OSMOSIS_WALLET_ADDRESS"
}

function createOsmosisWallet {
    if [[ -z "$OSMOSIS_WALLET_ADDRESS" ]]; then
        printRed "Osmosis wallet named '$osmo_wallet' not found. Choose an action:"
        printLine
        echo "1. Enter another wallet name"
        echo "2. Create a new wallet"
        echo "3. Recover a wallet"
        echo "4. Exit"
        printLine
        read -p "Enter your choice (1-4): " CHOICE

        case $CHOICE in
            1)
                read -p $'\033[1;34mEnter Osmosis WALLET name:\033[0m ' osmo_wallet
                getOsmosisWallet
                if [[ -z "$OSMOSIS_WALLET_ADDRESS" ]]; then
                createOsmosisWallet
                fi
                ;;
            2)
                printLine
                osmosisd keys add "$osmo_wallet"
                printGreen "**Important** write this mnemonic phrase in a safe place. It is the only way to recover your account if you ever forget your password."
                echo "Press Enter to continue..."
                printLine
                read -p ""
                getOsmosisWallet
                ;;
            3)
                osmosisd keys add "$osmo_wallet" --recover
                getOsmosisWallet
                ;;
            4)
                echo "Exiting script."
                exit 0
                ;;
            *)
                echo "Invalid choice. Please enter a number between 1 and 4."
                ;;
        esac
    else
        printLine
    fi
}

function check_osmo_wallet {
  getOsmosisWallet
  createOsmosisWallet
}


######################################### Token and amount functions #########################################

function choose_token_and_amount {
  local wallet_type="$1"
  local sender="$2"
  declare -A token_balances

  printCyan "Parcing the balance of $sender... "
          i=1
          declare -a token_names
          if [ "$wallet_type" == "namadac" ]; then
            while IFS= read -r line; do
              if [[ "$line" == *"Last committed epoch:"* ]] || [[ "$line" == *"converting current asset type to latest asset type"* ]]; then
                  continue
              elif [[ "$line" == *"The application panicked"* ]]; then
                  printRed "A problem occured. Please try another wallet"
                  check_nam_wallet
                  continue
              fi
              clean_line=$(echo "$line" | sed -e 's/ *: */:/g')

              tokens=$(echo "$clean_line" | awk -F ':' '{print $1}')
              amount=$(echo "$clean_line" | awk -F ':' '{print $NF}')

              token_balances["$tokens"]="$amount"
            done < <(namadac balance --owner "$sender" --node $rpc_nam)
              for tokens in "${!token_balances[@]}"; do
                echo "$i. $tokens: ${token_balances[$tokens]}"
                token_names[i]="$tokens"
                ((i++))
              done
              echo ""
              read -p "$(printYellow "Choose the token you would like to transfer by printing the corresponding number:") " token_num
              token="${token_names[$token_num]}"
          elif [ "$wallet_type" == "osmosisd" ]; then
            echo "uosmo: "
            echo "$(osmosisd q bank balances $OSMOSIS_WALLET_ADDRESS --node $rpc_osmo)" | awk -F': "' '/amount/ {amount=$2} /uosmo/ {print amount}' | tr -d '"'
          elif [ "$wallet_type" == "celestia-appd" ]; then
            echo "utia: "
            echo "$(celestia-appd q bank balances $CELESTIA_WALLET_ADDRESS --node $rpc_tia)" | awk -F': "' '/amount/ {amount=$2} /utia/ {print amount}' | tr -d '"'
          fi
  read -p "$(printYellow "Print the amount you would like to transfer:") " amount
}

function offer_another_action {
    printLine
    printLine
    read -rp "$(printCyan "Do you want to perform another action? (yes/no):") " another
    if [[ $another == "yes" ]]; then
        return 0 
    else
        return 1 
    fi
}

function confirm_transaction {
    printLine
    echo ""
    printCyan "You are about to make the following transaction:"
    echo "$(printCyan "Sender:") $1"
    echo "$(printCyan "Receiver:") $2"
    echo "$(printCyan "Amount & token:") $3 $4"
    echo ""
    read -rp "$(printYellow "Do you want to proceed? (yes/no):") " confirmation
    if [[ $confirmation != "yes" ]]; then
        printRed "Transaction cancelled."
        return 1
    fi
    return 0
}


######################################### Common Installation ###############################################

printLine
printCyan "Checking Go version and Installing if needed..." && sleep 1
# Install go if needed
cd $HOME
goInstallationNeeded=true

# Check if Go is installed and verify its version
if command -v go >/dev/null; then
    CURRENT_VER=$(go version | grep -oP '\d+\.\d+\.\d+')
    DESIRED_VER="1.20"
    # Determine if the current version is less than the desired version
    if [[ $(printf '%s\n' "$DESIRED_VER" "$CURRENT_VER" | sort -V | head -n1) = "$DESIRED_VER" ]]; then
        echo "Go version $CURRENT_VER is already installed and meets the desired version requirement."
        goInstallationNeeded=false
    fi
fi

if [ "$goInstallationNeeded" = true ] ; then
    # Install Go if not installed or version is less than desired
    VER="1.20.3"
    wget "https://golang.org/dl/go$VER.linux-amd64.tar.gz"
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "go$VER.linux-amd64.tar.gz"
    rm "go$VER.linux-amd64.tar.gz"

    # Ensure .bash_profile exists
    [ ! -f ~/.bash_profile ] && touch ~/.bash_profile
    # Append Go paths to .bash_profile only if not already present to avoid duplicates
    if ! grep -q 'export PATH=$PATH:/usr/local/go/bin:~/go/bin' ~/.bash_profile; then
        echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
    fi

    # Source the .bash_profile to update the current session
    source $HOME/.bash_profile
fi

# Ensure the ~/go/bin directory exists regardless of Go installation status
[ ! -d ~/go/bin ] && mkdir -p ~/go/bin


echo $(go version) && sleep 1

sudo apt-get install -y git-core libssl-dev pkg-config libclang-12-dev protobuf-compiler expect

printLine
printCyan "Checking for Rust & Cargo installation..." && sleep 1
# Check if Rust and Cargo are installed by checking for the cargo command
if command -v cargo > /dev/null; then
    echo "Rust and Cargo are already installed."
    printGreen "done"
else
    printCyan "Installing Rust & Cargo..." && sleep 1
    # Install Rust and Cargo
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
    printGreen "done"
fi

printLine
printCyan "Checking Protocol Buffers..." && sleep 1
# Check if protoc is installed
if command -v protoc >/dev/null; then
    echo "Protocol Buffers are already installed."
    sleep 1
    printGreen "done"
else
    cd $HOME
    curl -L -o protobuf.zip https://github.com/protocolbuffers/protobuf/releases/download/v24.4/protoc-24.4-linux-x86_64.zip
    mkdir protobuf_temp && unzip protobuf.zip -d protobuf_temp/
    sudo cp protobuf_temp/bin/protoc /usr/local/bin/
    sudo cp -r protobuf_temp/include/* /usr/local/include/
    rm -rf protobuf_temp protobuf.zip
    sleep 1
    printGreen "done"
fi

printLine
printCyan "Checking CometBFT..." && sleep 1
# Check if CometBFT is installed
if [ -x "/usr/local/bin/cometbft" ]; then
    echo "CometBFT is already installed."
    # Check and print the installed version
    cometbft version
    sleep 1
    printGreen "done"
else
    # Install CometBFT
    cd $HOME
    rm -rf $HOME/cometbft
    git clone https://github.com/cometbft/cometbft.git
    cd cometbft
    git checkout v0.37.2
    make build
    sudo cp build/cometbft /usr/local/bin/
    # Check and print the installed version
    cometbft version
    sleep 1
    printGreen "done"
fi

checkNamada
printLine

################################################## Transactions & Faucet ###############################################



while true; do
echo ""
printLine

printYellow "Which action would you like to perform?"
options=(
  "Use shielded faucet"
  "Make a shielded transfer"
)
for i in "${!options[@]}"; do
  printf "%s. %s\n" "$((i + 1))" "${options[$i]}"
done
read -rp "$(printCyan "Your answer:") " action
echo ""
printLine

if [[ action -eq 1 ]]; then
  read -rp "$(printYellow "Insert the shielded address (znam..) you would like to refill:") " address
echo ""
  # Node.js API
  url="http://65.109.92.79:3006/transfer"

  response=$(curl -X POST $url \
    -H "Content-Type: application/json" \
    -d "{\"address\":\"$address\"}")

  # Output the response from the server
  if echo $response | grep -q "Transaction was successfully applied" ; then
    printGreen "Tokens sent to "$address" successfully."
  else
    printRed "Transaction failed."
  fi
  echo "$response"
  echo ""

elif [[ action -eq 2 ]]; then
    printYellow "Choose the shielded transfer direction by printing the corresponding number:"
    options=(
      "Namada    -->   Osmosis"
      "Osmosis   -->   Namada"
      "Namada    -->   Celestia"
      "Celestia  -->   Namada"
      "Namada internal transfer"
    )
    for i in "${!options[@]}"; do
      printf "%s. %s\n" "$((i + 1))" "${options[$i]}"
    done
    read -rp "$(printCyan "Your answer:") " tx_type
    echo ""
    
    if [[ tx_type -eq 1 ]]; then
        checkOsmosis
        
        check_nam_shwallet
        check_osmo_wallet
        choose_token_and_amount namadac $shielded_sk
    
        if confirm_transaction $shielded_sk $osmo_wallet $amount $token; then
          memo_path=$(echo $(namadac ibc-gen-shielded --target $OSMOSIS_WALLET_ADDRESS --token $token --amount $amount --channel-id $nam_osmo_ch --node $rpc_nam) | awk '{print $NF}')
        
          expect -c "
          set timeout -1
          spawn namadac ibc-transfer --source $shielded_sk --receiver $OSMOSIS_WALLET_ADDRESS --token $token --amount $amount --channel-id $nam_osmo_ch --memo-path "$memo_path" --node $rpc_nam
          expect \"Enter your decryption password: \"
          interact
          expect eof
          "
        fi
        shielded_sk=""
        osmo_wallet=""
    elif [[ tx_type -eq 2 ]]; then
        checkOsmosis
    
        check_nam_shaddr
        check_osmo_wallet
        choose_token_and_amount osmosisd $osmo_wallet
        
        if confirm_transaction $osmo_wallet $shielded_addr $amount uosmo; then
          memo=$(cat $(echo $(namadac ibc-gen-shielded --target $shielded_addr --token uosmo --amount $amount --channel-id $nam_osmo_ch --node $rpc_nam) | awk '{print $NF}'))
          shielded_znam=$(echo $(namadaw list | grep -oP "\"$shielded_addr\": \K[^ ]+"))
          
          expect -c "
          set timeout -1
          log_user 0;
          spawn osmosisd tx ibc-transfer transfer transfer $osmo_nam_ch $shielded_znam ${amount}uosmo --from $osmo_wallet --chain-id="osmo-test-5" --gas-prices 0.1uosmo --gas auto --gas-adjustment 1.6 -y --memo $memo --node $rpc_osmo
          log_user 1;
          expect \"Enter keyring passphrase (attempt *\"
          interact
          "
        fi
        osmo_wallet=""
        shielded_addr=""
        shielded_znam=""
    elif [[ tx_type -eq 3 ]]; then
        checkCelestia
        
        check_nam_shwallet
        check_tia_wallet
        choose_token_and_amount namadac $shielded_sk
    
        if confirm_transaction $shielded_sk $tia_wallet $amount $token; then
          memo_path=$(echo $(namadac ibc-gen-shielded --target $CELESTIA_WALLET_ADDRESS --token $token --amount $amount --channel-id $nam_tia_ch --node $rpc_nam) | awk '{print $NF}')
        
          expect -c "
          set timeout -1
          spawn namadac ibc-transfer --source $shielded_sk --receiver $CELESTIA_WALLET_ADDRESS --token $token --amount $amount --channel-id $nam_tia_ch --memo-path "$memo_path" --node $rpc_nam
          expect \"Enter your decryption password: \"
          interact
          expect eof
          "
        fi
        shielded_sk=""
        tia_wallet=""
    elif [[ tx_type -eq 4 ]]; then
        checkCelestia
    
        check_nam_shaddr
        check_tia_wallet
        choose_token_and_amount celestia-appd $tia_wallet
    
        if confirm_transaction $tia_wallet $shielded_addr $amount utia; then
          memo=$(cat $(echo $(namadac ibc-gen-shielded --target $shielded_addr --token utia --amount $amount --channel-id $nam_tia_ch --node $rpc_nam) | awk '{print $NF}'))
          shielded_znam=$(echo $(namadaw list | grep -oP "\"$shielded_addr\": \K[^ ]+"))
          
          expect -c "
          set timeout -1
          log_user 0;
          spawn celestia-appd tx ibc-transfer transfer transfer $tia_nam_ch $shielded_znam ${amount}utia --from $tia_wallet --chain-id=“mocha-4” --gas-prices 0.1utia --gas auto --gas-adjustment 1.6 -y --memo $memo --node $rpc_tia
          log_user 1;
          expect \"Enter keyring passphrase (attempt *\"
          interact
          expect eof
          "
        fi
        tia_wallet=""
        shielded_addr=""
        shielded_znam=""
    elif [[ tx_type -eq 5 ]]; then
        printLine
        printYellow "Choose the Namada transfer type by printing the corresponding number:"
        namada_options=(
        "Shielding: transparent --> shielded"
        "Shielded: shielded --> shielded"
        "Unshielding: shielded --> transparent"
        )
        for i in "${!namada_options[@]}"; do
          printf "%s. %s\n" "$((i + 1))" "${namada_options[$i]}"
        done
        read -rp "$(printCyan "Your answer:") " nam_tx_type
        echo ""
        
        case $nam_tx_type in
        1)
            printLine
            printYellow "Choose the target of your transfer:"
            options=("Your shielded address" "Another shielded address (znam..)")
            for i in "${!options[@]}"; do
                printf "%s. %s\n" "$((i + 1))" "${options[$i]}"
            done
            read -rp "$(printCyan "Your answer:") " shielding_target
            echo ""
            if [[ $shielding_target -eq 1 ]]; then
                check_nam_shaddr $shielded_addr
                shielding_target=$shielded_addr
            else
                read -rp "$(printYellow "Insert the receiver shielded address (znam...):") " shielding_target
            fi
            
            check_nam_wallet
            choose_token_and_amount namadac $nam_wallet
    
            if confirm_transaction $nam_wallet $shielding_target $amount $token; then
              expect -c "
              log_user 0;
              spawn namadac transfer --source $nam_wallet --target $shielding_target --amount $amount --token $token --node $rpc_nam
              log_user 1;
              expect \"Enter your decryption password: \"
              interact
              "
            fi
            nam_wallet=""
            shielding_target=""
            shielded_addr=""
            ;;
        2)
            read -rp "$(printYellow "Insert the receiver shielded address (znam...):") " shielded_target
    
            check_nam_shwallet
            choose_token_and_amount namadac $shielded_sk
    
            if confirm_transaction $shielded_sk $shielded_target $amount $token; then
              expect -c "
              log_user 0;
              spawn namadac transfer --source $shielded_sk --target $shielded_target --amount $amount --token $token --signing-keys $nam_wallet --node $rpc_nam
              log_user 1;
              expect \"Enter your decryption password: \"
              interact
              "
            fi
            shielded_sk=""
            shielded_target=""
            ;;
        3)
            printLine
            printYellow "Choose the target of your transfer:"
            options=("Your Namada wallet" "Another transparent address (tnam..)")
            for i in "${!options[@]}"; do
                printf "%s. %s\n" "$((i + 1))" "${options[$i]}"
            done
            read -rp "$(printCyan "Your answer:") " unshielding_target
            echo ""
            if [[ $unshielding_target -eq 1 ]]; then
                check_nam_wallet
                unshielding_target=$nam_wallet
            else
                read -rp "$(printYellow "Insert the receiver transparent address (tnam..):") " unshielding_target
            fi
    
            check_nam_shwallet
            choose_token_and_amount namadac $shielded_sk
            
            if confirm_transaction $shielded_sk $unshielding_target $amount $token; then
              expect -c "
              log_user 0;
              spawn namadac transfer --source $shielded_sk --target $unshielding_target --amount $amount --token $token --signing-keys $nam_wallet --node $rpc_nam
              log_user 1;
              expect \"Enter your decryption password: \"
              interact
              "
            fi
            shielded_sk=""
            nam_wallet=""
            ;;
    esac
    fi
fi
    if ! offer_another_action; then
      break        
    fi
done
