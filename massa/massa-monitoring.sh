#!/bin/bash
#start with /bin/bash buyrolls.sh

# Configure telegram bot and chat id token
BOT_TOKEN="<YOUR_BOT_TOKEN>"
CHAT_ID_ALARM="<YOUR_CHAT_ID>"

# set vars
read -s -p "Enter massa-client password: " PASSWORD
PASSWORD=$PASSWORD
SLEEP=900
DIR=$(pwd)
HOME_DIR=${DIR}/massa/massa-client
cd $HOME_DIR
WALLET_ADDRESS=$(./massa-client wallet_info -p "$PASSWORD" | grep 'Address' | awk '{print $2}')

echo '================================================='
echo -e "massa-client folder path: \e[1m\e[32m${HOME_DIR}\e[0m"
echo -e "Massa wallet address: \e[1m\e[32m$WALLET_ADDRESS\e[0m"
echo -e "Sleep time: \e[1m\e[32m$SLEEP sec\e[0m"
echo '================================================='
sleep 1

for (( ;; )); do
cd $HOME_DIR
# checking node status...
echo Checking node status...
echo '----------------------'
STATUS=$(./massa-client -p "$PASSWORD" get_status | grep 'Error'| awk '{print $1}')
while [ "$STATUS" == "Error:" ]
do
   MESSAGE="Massa node status is: Error, please check it"
   curl --header 'Content-Type: application/json' --request 'POST' --data '{"chat_id":"'"${CHAT_ID_ALARM}"'", "text":"'"$(echo -e "${MESSAGE}")"'", "parse_mode": "html"}' "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" /dev/null 2>&1
  echo -e "\033[0;31m"$MESSAGE", waiting 60 min...\033[0m"
 sleep 3600
STATUS=$(./massa-client -p "$PASSWORD" get_status | grep 'Error'| awk '{print $1}')
WALLET_ADDRESS=$(./massa-client wallet_info -p "$PASSWORD" | grep 'Address' | awk '{print $2}')
done
 
# Checking candidate rolls
CANDIDATE=$(./massa-client wallet_info -p "$PASSWORD" | grep Rolls | awk '{print $4}' | sed 's/=/ /'|awk '{print $2}')
echo There is a $CANDIDATE candidate rolls

if [ "$CANDIDATE" != "0" ]; then
 echo -e "\033[0;32m"Candidate = $CANDIDATE rolls, waiting $SLEEP sec..."\033[0m"
 echo '-------------------------------------------------'
sleep $SLEEP
else
echo -e "\033[0;32m"Checking ballance..."\033[0m"
BALANCE=$(./massa-client wallet_info -p "$PASSWORD" | grep "Balance:" |  awk '{print $2}' | sed 's/=/ /' |  awk '{print $2}' | awk '{print int($1)}')
echo -e "\033[0;32m"Ballance: $BALANCE rolls"\033[0m"
    MESSAGE="Massa node have $CANDIDATE rolls, please check it"
   curl --header 'Content-Type: application/json' --request 'POST' --data '{"chat_id":"'"${CHAT_ID_ALARM}"'", "text":"'"$(echo -e "${MESSAGE}")"'", "parse_mode": "html"}' "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" /dev/null 2>&1
if [ "$BALANCE" -gt "99" ]
then
echo -e "\033[0;32m"Buing rolls to $WALLET_ADDRESS, function disabled..."\033[0m"
#TXH=$(./massa-client -p "$PASSWORD" buy_rolls ${WALLET_ADDRESS} 1 0)
#echo We have buy 1 rools TXH:$TXH
fi
echo waiting $SLEEP sec
sleep $SLEEP
fi
done
