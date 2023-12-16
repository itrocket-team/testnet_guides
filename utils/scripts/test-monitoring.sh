#!/bin/bash

# Ваши переменные
TELEGRAM_BOT_TOKEN=""
TELEGRAM_CHAT_ID=""
RPC="http://:8646"
PARRENT_RPC="https://rpc1.piccadilly.autonity.org"

# Функция для отправки сообщений в Telegram
send_telegram() {
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" -d chat_id=$TELEGRAM_CHAT_ID -d text="$1"
}

# Основной цикл
while true; do
    echo "Checking RPC block height..."

    # Получаем высоту блока с вашего RPC
    RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' $RPC)
    HEIGHT=$(echo $RESPONSE | jq -r '.result')
    if [[ $RESPONSE == "" ]] || [[ $HEIGHT == null ]]; then
        send_telegram "Autonity ITRocket RPC $RPC is down or sent an invalid response."
        echo "Error: Autonity ITRocket RPC $RPC is down or sent an invalid response."
        HEIGHT=0
    fi
    echo "Current RPC Block Height: $HEIGHT"

    # Получаем высоту блока с парент RPC
    PARENT_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' $PARRENT_RPC)
    PARENT_HEIGHT=$(echo $PARENT_RESPONSE | jq -r '.result')
    if [[ $PARENT_RESPONSE == "" ]] || [[ $PARENT_HEIGHT == null ]]; then
        echo "Error: Autonity Parent RPC $PARRENT_RPC is down or sent an invalid response."
        PARENT_HEIGHT=0
        sleep 5 # Ждем 5 секунд перед следующей попыткой
        continue # Переходим к следующей итерации цикла
    fi
    echo "Parent RPC Block Height: $PARENT_HEIGHT"

    # Проверяем разницу в высоте блоков
    if [[ $HEIGHT -ne 0 ]] && [[ $PARENT_HEIGHT -ne 0 ]]; then
        DIFF=$(($PARENT_HEIGHT - $HEIGHT))
        if [[ $DIFF -gt 2 ]]; then
            send_telegram "Autonity ITRocket RPC Block height difference is more than 2. RPC: $HEIGHT, Parent RPC: $PARENT_HEIGHT."
            echo "Alert: Block height difference is more than 2. RPC: $HEIGHT, Parent RPC: $PARENT_HEIGHT."
        else
            echo "Block height within acceptable range."
        fi
    fi

    # Ожидаем 5 минут перед следующей проверкой
    echo "Waiting 5 minutes before next check..."
    sleep 300
done

