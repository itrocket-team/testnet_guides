#!/bin/bash
VAL_CREATION_CONTRACT="0xea224dBB52F57752044c0C86aD50930091F561B9"
RPC_URL="https://evmrpc-testnet.0g.ai"
VAL_COMMISSION=50000
VAL_WITHDRAW_FEE=1
VALUE="32.1ether"

source <(curl -s https://raw.githubusercontent.com/itrocket-team/testnet_guides/main/utils/common.sh)

run_cmd() {
    local desc=$1; shift

    local out
    if ! out=$("$@" 2>&1); then
        echo ""
        printRed "❌ Process failed ($desc):" >&2
        echo "$out" >&2
        return 1
    fi

    echo "$out"
}

get_validator_info() {
    local file="$HOME/validator_info.json"
    echo "Getting validator info..."
    _json_val() {
        local key=$1
        if command -v jq &>/dev/null; then
            jq -r ".$key // empty" "$file" 2>/dev/null
        else
            grep -oE "\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$file" \
              | cut -d'"' -f4
        fi
    }

    if [[ -f $file ]]; then
        MONIKER=$(_json_val moniker)
        WEBSITE=$(_json_val website)
        IDENTITY=$(_json_val identity)
        CONTACT=$(_json_val contact)
        DETAILS=$(_json_val details)
        echo "✅ Loaded validator info from $file"
    else
        printBlue "Please enter your validator info:"
        read -rp " • Moniker  : " MONIKER
        read -rp " • Website  : " WEBSITE
        read -rp " • Identity : " IDENTITY
        read -rp " • Contact  : " CONTACT
        read -rp " • Details  : " DETAILS

        cat > "$file" <<EOF
{
  "moniker": "$(echo "$MONIKER"  | sed 's/"/\\"/g')",
  "website": "$(echo "$WEBSITE"  | sed 's/"/\\"/g')",
  "identity": "$(echo "$IDENTITY"  | sed 's/"/\\"/g')",
  "contact": "$(echo "$CONTACT"  | sed 's/"/\\"/g')",
  "details": "$(echo "$DETAILS"  | sed 's/"/\\"/g')"
}
EOF
        echo "✅ Validator info saved to $file for further use"
    fi

    export MONIKER WEBSITE CONTACT DETAILS
}

extract_pubkey() {
    local raw pubkey
    echo "" >&2
    echo "Extracting ETH pubkey..." >&2 && sleep 1
    raw=$(run_cmd "ETH pubkey extraction with validator-keys" \
          0gchaind deposit validator-keys \
          --chaincfg.chain-spec=devnet \
          --home "$HOME/.0gchaind/0g-home/0gchaind-home/") || return 1

    pubkey=$(echo "$raw" | awk -F':' '/Eth\/Beacon Pubkey/ {getline; print $1}' | tr -d '[:space:]')

    if [[ -n $pubkey ]]; then
        echo "✅ ETH pubkey extracted: $pubkey" >&2
        echo "$pubkey"
    else
        echo "Error: Eth pubkey not found in command output." >&2
        return 1
    fi
}

compute_val_addr() {
    local pubkey=$1
    echo "" >&2
    echo "Computing validator address from ETH pubkey..." >&2 && sleep 1

    [[ -z $pubkey ]] && { echo "Pubkey missing." >&2; return 1; }

    local raw address
    raw=$(run_cmd "computeValidatorAddress" \
          cast call "$VAL_CREATION_CONTRACT" \
          "computeValidatorAddress(bytes)(address)" \
          "$pubkey" \
          --rpc-url "$RPC_URL") || return 1

    address=$(echo "$raw" | grep -Eo '0x[0-9a-fA-F]{40}' | head -n1)

if [[ -n $address ]]; then
    echo "✅ Validator address found: $address" >&2
    echo "$address"
else
    printRed "❌ Error: validator address not found in cast output." >&2
    return 1
fi
}

gen_signature() {
    local val_addr=$1
    echo "" >&2
    echo "Generating signature for validator creation..." >&2 && sleep 1

    [[ -z $val_addr ]] && {
        printRed "❌ Validator address required." >&2
        return 1
    }

    local raw sig
    raw=$(run_cmd "signature generation via create-validator" \
          0gchaind deposit create-validator \
          "$val_addr" 32000000000 \
          ~/.0gchaind/0g-home/0gchaind-home/config/genesis.json \
          --home ~/.0gchaind/0g-home/0gchaind-home/ \
          --chaincfg.chain-spec=devnet) || return 1

    sig=$(echo "$raw" | awk -F': ' '/^signature/ {print $2}' | tr -d '[:space:]')

    if [[ -n $sig ]]; then
        echo "✅ Signature generated: $sig" >&2
        echo "$sig"
    else
        printRed "❌ Error: signature not found in command output." >&2
        return 1
    fi
}

create_validator() {
    echo "" >&2
    echo "Sending validator-creation transaction…" >&2 && sleep 1

    validator_meta=()
    validator_types=()

    for field in "$MONIKER" "$IDENTITY" "$WEBSITE" "$CONTACT" "$DETAILS"; do
        [[ -n $field ]] && {
            validator_meta+=("$field")
            validator_types+=("string")
        }
    done

    if [[ ${#validator_meta[@]} -eq 0 ]]; then
        printRed "❌ No validator metadata (moniker / website / …) provided. Please run the script again and insert data." >&2
        return 1
    fi

    meta_type=$(IFS=,; echo "${validator_types[*]}")
    meta_tuple=$(printf '"%s",' "${validator_meta[@]}")
    meta_tuple="(${meta_tuple%,})"
    fn_sig="createAndInitializeValidatorIfNecessary(($meta_type),uint32,uint96,bytes,bytes)(address)"

    while true; do
        [[ -n ${PRIVATE_KEY:-} ]] || read -srp "Enter your private key (0x…64-hex): " PRIVATE_KEY
        echo >&2
        if [[ $PRIVATE_KEY =~ ^0x[0-9a-fA-F]{64}$ ]]; then
            break
        fi
        printRed "❌ Invalid private-key format; must be 0x + 64 hex symbols." >&2
        echo ""
        unset PRIVATE_KEY
    done

    local raw tx_hash
    raw=$(run_cmd "validator creation via createAndInitializeValidatorIfNecessary" \
          cast send "$VAL_CREATION_CONTRACT" \
          "$fn_sig" \
          "$meta_tuple" \
          "$VAL_COMMISSION" \
          "$VAL_WITHDRAW_FEE" \
          "$ETH_PUBKEY" \
          "$SIGNATURE" \
          --value "$VALUE" \
          --rpc-url "$RPC_URL" \
          --private-key "$PRIVATE_KEY") || return 1

    tx_hash=$(echo "$raw" | grep -Eo '0x[0-9a-fA-F]{64}' | head -n1)

    if [[ -n $tx_hash ]]; then
        printGreen "✅ Validator created. TX: $tx_hash" >&2
        echo "$tx_hash"
    else
        printRed "❌ Failed to create validator." >&2
        return 1
    fi
}

delegate() {
    printBlue "Starting delegation…" >&2 && sleep 1

    while :; do
        [[ -n ${PRIVATE_KEY:-} ]] || read -srp "Enter your private key (0x…64-hex): " PRIVATE_KEY
        echo >&2
        [[ $PRIVATE_KEY =~ ^0x[0-9a-fA-F]{64}$ ]] && break
        printRed "❌ Invalid private-key format; must be 0x + 64 hex symbols." >&2
        echo ""
        unset PRIVATE_KEY
    done
    DELEGATOR_ADDR=$(cast wallet address "$PRIVATE_KEY")

    while :; do
        read -rp "Enter amount to delegate in ETH (e.g. 0.1): " AMT_ETH
        [[ $AMT_ETH =~ ^([0-9]+([.][0-9]+)?)$ ]] && break
        printRed "❌ Invalid amount. Use integer or decimal with dot." >&2
        echo ""
    done
    DELEGATE_VALUE="${AMT_ETH}ether"

    ETH_PUBKEY=$(extract_pubkey) || exit 1

    VALIDATOR_ADDR=$(run_cmd "getValidator" \
        cast call "$VAL_CREATION_CONTRACT" \
        "getValidator(bytes)(address)" \
        "$ETH_PUBKEY" \
        --rpc-url "$RPC_URL") || return 1

    if [[ $VALIDATOR_ADDR == 0x0000000000000000000000000000000000000000 ]]; then
        printRed "❌ Validator not found / not initialized." >&2
        return 1
    fi

    local raw tx_hash
    raw=$(run_cmd "delegate()" \
          cast send "$VALIDATOR_ADDR" \
          "delegate(address)" "$DELEGATOR_ADDR" \
          --value  "$DELEGATE_VALUE" \
          --rpc-url "$RPC_URL" \
          --private-key "$PRIVATE_KEY") || return 1

    tx_hash=$(echo "$raw" | awk '/transactionHash/ {print $2}')

    if [[ -n $tx_hash ]]; then
        printGreen "✅ Delegation TX sent: $tx_hash" >&2
    else
        printRed "❌ Process failed: tx hash not found." >&2
        return 1
    fi
}

get_delegation_info() {
    echo "" >&2
    printBlue "Fetching delegation info…" >&2 && sleep 1

    while :; do
        read -rp "Enter delegator address (0x…40-hex) or press Enter to derive from private key: " DELEGATOR_ADDR
        if [[ -z $DELEGATOR_ADDR ]]; then
            while :; do
                read -srp "Enter your private key (0x…64-hex): " PRIVATE_KEY
                echo >&2
                [[ $PRIVATE_KEY =~ ^0x[0-9a-fA-F]{64}$ ]] && break
                printRed "❌ Invalid private-key format. Try again." >&2
                echo ""
            done
            DELEGATOR_ADDR=$(cast wallet address "$PRIVATE_KEY")
            printGreen "Delegator address derived: $DELEGATOR_ADDR" >&2
        fi
        [[ $DELEGATOR_ADDR =~ ^0x[0-9a-fA-F]{40}$ ]] && break
        printRed "❌ Invalid Ethereum address format. Try again." >&2
        echo ""
    done

    ETH_PUBKEY=$(extract_pubkey) || exit 1

    VALIDATOR_ADDR=$(run_cmd "getValidator" \
        cast call "$VAL_CREATION_CONTRACT" \
        "getValidator(bytes)(address)" \
        "$ETH_PUBKEY" \
        --rpc-url "$RPC_URL") || return 1

    if [[ $VALIDATOR_ADDR == 0x0000000000000000000000000000000000000000 ]]; then
        printRed "❌ Validator not found / not initialized." >&2
        return 1
    fi

    local raw shares
    raw=$(run_cmd "getDelegation" \
          cast call "$VALIDATOR_ADDR" \
          "getDelegation(address)(address,uint256)" \
          "$DELEGATOR_ADDR" \
          --rpc-url "$RPC_URL") || return 1

    if [[ $raw =~ ^\([^,]+,([0-9]+)\)$ ]]; then
        shares=${BASH_REMATCH[1]}
    else
        printRed "❌ Could not parse shares." >&2
        return 1
    fi

    total_tokens=$(run_cmd "tokens()"           \
        cast call "$VALIDATOR_ADDR" "tokens()(uint256)" --rpc-url "$RPC_URL") || return 1
    total_shares=$(run_cmd "delegatorShares()"  \
        cast call "$VALIDATOR_ADDR" "delegatorShares()(uint256)" --rpc-url "$RPC_URL") || return 1

    est_tokens=0
    if [[ $total_shares -gt 0 ]]; then
        est_tokens=$(( shares * total_tokens / total_shares ))
    fi

    printGreen "✅ Delegation info:" >&2
    echo " • Shares          : $shares"
    echo " • Estimated tokens: $est_tokens"
}

undelegate() {
    printBlue "Starting undelegation…" >&2 && sleep 1

    while :; do
        [[ -n ${PRIVATE_KEY:-} ]] || read -srp "Enter your private key (0x…64-hex): " PRIVATE_KEY
        echo >&2
        [[ $PRIVATE_KEY =~ ^0x[0-9a-fA-F]{64}$ ]] && break
        printRed "❌ Invalid private-key format; must be 0x + 64 hex symbols." >&2
        echo ""
        unset PRIVATE_KEY
    done
    DELEGATOR_ADDR=$(cast wallet address "$PRIVATE_KEY")

    while :; do
        read -rp "Enter the number of shares to undelegate (e.g. 1): " NUM_SHARES
        [[ $NUM_SHARES =~ ^([0-9]+([.][0-9]+)?)$ ]] && break
        printRed "❌ Invalid number of shares. Use integer or decimal with dot." >&2
        echo ""
    done

    ETH_PUBKEY=$(extract_pubkey) || exit 1

    VALIDATOR_ADDR=$(run_cmd "getValidator" \
        cast call "$VAL_CREATION_CONTRACT" \
        "getValidator(bytes)(address)" \
        "$ETH_PUBKEY" \
        --rpc-url "$RPC_URL") || return 1

    if [[ $VALIDATOR_ADDR == 0x0000000000000000000000000000000000000000 ]]; then
        printRed "❌ Validator not found / not initialized." >&2
        return 1
    fi

    FEE_GWEI=$(cast call $VALIDATOR_ADDR "withdrawalFeeInGwei()(uint96)" --rpc-url $RPC_URL)
    FEE=$(cast to-wei $FEE_GWEI gwei)

    local raw tx_hash
    raw=$(run_cmd "undelegate()" \
          cast send "$VALIDATOR_ADDR" \
          "undelegate(address,uint256)" "$DELEGATOR_ADDR" \
          --value  "$NUM_SHARES" \
          --value $FEE \
          --rpc-url "$RPC_URL" \
          --private-key "$PRIVATE_KEY") || return 1

    tx_hash=$(echo "$raw" | awk '/transactionHash/ {print $2}')

    if [[ -n $tx_hash ]]; then
        printGreen "✅ Delegation TX sent: $tx_hash" >&2
    else
        printRed "❌ Process failed: tx hash not found." >&2
        return 1
    fi
}


printLogo
echo "0G Validator Creation & Delegation Tool"

printLine
printBlue "Checking if Foundry is installed..." && sleep 1
if ! command -v foundryup &>/dev/null; then
    printRed "❌ Foundry not found. Please install it and try again." && sleep 1
    exit 1
fi

echo "✅ Foundry is installed: $(command -v foundryup)" && sleep 1
cast --version

action=0
while [[ $action -ne 5 ]]; do
echo ""
printLine
printLine
printBlue "Which action would you like to perform?"
echo "1. Create a validator
2. Delegate to a validator
3. Check delegation
4. Undelegate
5. Exit"

read -rp "Your answer: " action
echo ""
printLine

if [[ $action -eq 1 ]]; then
    printLine
    get_validator_info
    ETH_PUBKEY=$(extract_pubkey) || exit 1
    ADDRESS=$(compute_val_addr "$ETH_PUBKEY") || exit 1
    SIGNATURE=$(gen_signature "$ADDRESS") || exit 1
    create_validator

elif [[ $action -eq 2 ]]; then
    printLine
    delegate

elif [[ $action -eq 3 ]]; then
    printLine
    get_delegation_info

elif [[ $action -eq 4 ]]; then
    printLine
    undelegate

elif [[ $action -eq 5 ]]; then
    printRed "Exiting the script..." && sleep 1

elif [[ $action -ne 5 ]]; then
    printRed "Invalid choice. Try again." && sleep 1

fi
done
