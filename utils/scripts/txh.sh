#!/bin/bash

# Replace the following variables with your actual values
RECIPIENT_ADDRESS="zeta1p3emgemv8q0fmtw70kfzwecmcvyd9ztqmzy3r9"
TRANSFER_AMOUNT="10azeta"
CHAIN_ID="athens_7001-1"
BIN="zetacored"
GAS_PRICES="0.1azeta"
PASSWORD="<SUPER_SECURITY_PASSWORD>"

# Function to get the current sequence number of your account
get_sequence_number() {
  $BIN query account $WALLET_ADDRESS --chain-id $CHAIN_ID --output json | jq -r '.base_account.sequence'
}

# Initial sequence number
SEQUENCE=$(get_sequence_number)

for ((i = 1; i <= 1001; i++)); do
  echo "Sending TX $i..."
  echo $PASSWORD | $BIN tx bank send $WALLET_ADDRESS $RECIPIENT_ADDRESS $TRANSFER_AMOUNT --chain-id $CHAIN_ID --gas auto --gas-adjustment 1.5 --gas-prices="$GAS_PRICES" --sequence $SEQUENCE -y
  ((SEQUENCE++)) # Increment the sequence number for the next transaction
done
