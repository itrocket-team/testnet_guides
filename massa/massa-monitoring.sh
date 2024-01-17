#!/bin/bash
#start with /bin/bash massa-monitoring.sh

# Configure telegram bot and chat id token
BOT_TOKEN="<YOUR_BOT_TOKEN>"
CHAT_ID_ALARM="<YOUR_CHAT_ID>"
# You can add NODE_NAME to customize Telegram messages
NODE_NAME=""
# Change to false if you want to disable notifications
CANDIDATE_NOTIFICATIONS=true
START_NOTIFICATION=false

# Set variables
read -s -p "Enter ${NODE_NAME} massa-client password: " PASSWORD
SLEEP=15m
DIR=$HOME
HOME_DIR=${DIR}/massa/massa-client
cd $HOME_DIR

echo '================================================='
echo -e "massa-client folder path: \e[1m\e[32m${HOME_DIR}\e[0m"
echo -e "Sleep time: \e[1m\e[32m$SLEEP\e[0m"
echo '================================================='
sleep 1

        if [ "$START_NOTIFICATION" == "true" ]; then
        MESSAGE="${NODE_NAME} Massa monitoring script has been started"
        curl --header 'Content-Type: application/json' --request 'POST' --data '{"chat_id":"'"${CHAT_ID_ALARM}"'", "text":"'"$(echo -e "${MESSAGE}")"'", "parse_mode": "html"}' "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" /dev/null 2>&1
        fi

# Function to buy rolls
buy_rolls() {
    local wallet_address=$1
    local balance=$2
    local candidate=$3

    # Check if balance is sufficient to buy rolls
    if [ "$(echo "$balance > 101" | bc)" -eq 1 ]; then
        rolls_to_buy=$((balance / 100))
        echo -e "\033[0;32m"Address:${WALLET_ADDRESS} has Candidate=${CANDIDATE} Rolls, Balance=${BALANCE} MAS. Buying ${rolls_to_buy} rolls..."\033[0m"
        TXH=$(./massa-client -p "$PASSWORD" buy_rolls ${WALLET_ADDRESS} ${rolls_to_buy} 0)
        echo "We have bought ${rolls_to_buy} rolls TXH:$TXH"
        echo '--------------------------------'
    else
        echo -e "\033[0;32m${WALLET_ADDRESS}\033[0m | Balance=${BALANCE} MAS | Candidate=${CANDIDATE} Rolls | insufficient to buy additional Rolls"
        echo '--------------------------------'
    fi
}

# Main infinite loop
while true; do
    # Check node status
    echo Checking node status...
    echo '-----------------------'
    STATUS=$(./massa-client -p "$PASSWORD" get_status | grep 'Error'| awk '{print $1}')
    while [ "$STATUS" == "Error:" ]; do
        MESSAGE="${NODE_NAME} Massa node status is: Error, please check it"
        curl --header 'Content-Type: application/json' --request 'POST' --data '{"chat_id":"'"${CHAT_ID_ALARM}"'", "text":"'"$(echo -e "${MESSAGE}")"'", "parse_mode": "html"}' "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" /dev/null 2>&1
    echo -e "\033[0;31m"$MESSAGE", waiting ${SLEEP}...\033[0m"
    sleep $SLEEP
        STATUS=$(./massa-client -p "$PASSWORD" get_status | grep 'Error'| awk '{print $1}')
done


# Execute wallet_info
WALLET_INFO=$(./massa-client wallet_info -p "$PASSWORD")

# Get list of all wallet addresses
WALLET_ADDRESSES=$(echo "$WALLET_INFO" | grep 'Address' | awk '{print $2}')

# Process each address
for WALLET_ADDRESS in $WALLET_ADDRESSES; do

    # Extract balance and number of candidate rolls for this address
    BALANCE=$(echo "$WALLET_INFO" | grep -A 2 "$WALLET_ADDRESS" | grep "Balance:" | awk '{print $2}' | sed 's/=/ /' | awk '{print $2}' | awk '{print int($1)}')
    CANDIDATE=$(echo "$WALLET_INFO" | grep -A 2 "$WALLET_ADDRESS" | grep "Rolls:" | awk '{print $4}' | sed 's/=/ /' | awk '{print $2}')

    # Check number of candidate rolls
        if [ "$CANDIDATE" == "0" ] && [ "$CANDIDATE_NOTIFICATIONS" == "true" ]; then
        # Send message to Telegram
        MESSAGE="${NODE_NAME} Massa $WALLET_ADDRESS has $CANDIDATE Rolls, please check it"
        curl --header 'Content-Type: application/json' --request 'POST' --data '{"chat_id":"'"${CHAT_ID_ALARM}"'", "text":"'"$(echo -e "${MESSAGE}")"'", "parse_mode": "html"}' "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" /dev/null 2>&1
    fi

    # Call buy_rolls function if necessary
    buy_rolls "$WALLET_ADDRESS" "$BALANCE" "$CANDIDATE"
done

echo -e "\033[0;34mAll addresses processed, waiting $SLEEP before the next iteration...\033[0m"
echo '================================================='
sleep $SLEEP
done
