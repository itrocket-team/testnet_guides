#!/bin/bash

# Configure your Telegram BOT_TOKEN, CHAT_ID, Node_name, monitoring_message
NODE_NAME="Covalent"
TELEGRAM_BOT_TOKEN=""
TELEGRAM_CHAT_ID=""
CONTAINER_NAME="light-client"
MONITORING_MESSAGE="verified=true"
SLEEP="15m"

# Function to send a message to Telegram
send_telegram_message() {
    local message=$1
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" -d chat_id="$TELEGRAM_CHAT_ID" -d text="$message" -d parse_mode="Markdown"
}

# Main loop
while true; do
    # Check if the container is running
    if ! docker ps | grep -q "${CONTAINER_NAME}"; then
        MESSAGE="${NODE_NAME} Docker container ${CONTAINER_NAME} is not running!"
        send_telegram_message "$MESSAGE"
        echo "${MESSAGE} Waiting ${SLEEP}..."
    else
        LOG_OUTPUT=$(docker logs ${CONTAINER_NAME} --since ${SLEEP} 2>&1 | tr -d '\n')
        if echo "$LOG_OUTPUT" | grep -q "${MONITORING_MESSAGE}"; then
            echo "Service ${NODE_NAME} is operating normally, waiting ${SLEEP}..."
        else
            echo "${NODE_NAME} No '${MONITORING_MESSAGE}' message found in the logs for the past ${SLEEP}. Sending tg notification"
            MESSAGE="${NODE_NAME}: has not found '${MONITORING_MESSAGE}' in '${CONTAINER_NAME}' logs in the past ${SLEEP}. Please check."
            send_telegram_message "$MESSAGE"
        fi
    fi
    echo "Waiting ${SLEEP} and checking again..."
    sleep ${SLEEP}
done
