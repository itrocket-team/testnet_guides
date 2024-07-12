#!/bin/bash

# Replace with your bot token and chat ID
TOKEN="your_bot_token"
CHAT_ID="your_chat_id"
compose_directory="/home/$USER/nwaku-compose/"
URL="https://api.telegram.org/bot$TOKEN/sendMessage"
# Messages for various node states
message1="WAKU_NODE(health): Node stopped or turned off"
message2="WAKU_NODE(health): An error occurred with the node"
message3="WAKU_NODE(health): Unknown node status: ${response}"
message_normal="WAKU_NODE(health): Node is back to normal"

# IP address and output setting
ip_address="localhost:8645"
plain_text_out=false
POSITIONAL_ARGS=()
ALARM=0

while [[ $# -gt 0 ]]; do
  cd "$compose_directory" || { echo "Failed to change directory to $compose_directory"; exit 1; }
  case $1 in
    -p|--plain)
      plain_text_out=true
      shift
      ;;
    -*|--*)
      echo "Unknown parameter $1"
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1")
      shift
      ;;
  esac
done

set -- "${POSITIONAL_ARGS[@]}"

if [[ -n "$1" ]]; then
  ip_address="$1"
fi
if ! command -v curl &> /dev/null; then
    echo "Curl utility not found"
    exit 1
fi

while true; do
  cd "$compose_directory" || { echo "Failed to change directory to $compose_directory"; exit 1; }
  response=$(curl --connect-timeout 6 -s GET "http://${ip_address}/health")

  if [[ $? -ne 0 ]]; then
    echo -e "$(date +'%H:%M:%S') - Node may be turned off or inaccessible at http://${ip_address}\n"
    exit 1
  fi

  if [[ -z "${response}" ]]; then
    echo -e "$(date +'%H:%M:%S') - Node status: unknown\n"
    exit 1
  fi

  if ! command -v jq &> /dev/null || [[ "$plain_text_out" = true ]]; then
    echo -e "$(date +'%H:%M:%S') - Node status: ${response}\n"
  else
    echo -e "$(date +'%H:%M:%S') - Node status:\n"
    echo "${response}" | jq . 2>/dev/null
    if [[ $? -ne 0 ]]; then
      echo -e "${response}"
    fi
  fi
  node_health=$(echo "${response}" | jq -r '.nodeHealth')
  if [[ "${node_health}" == "Ready" ]]; then
    echo "Node is ready and working normally."
    if [[ "$ALARM" -eq 1 ]]; then
      curl -s -X POST "$URL" -d chat_id="$CHAT_ID" -d text="$message_normal" -d parse_mode="HTML"
      ALARM=0
    fi
  elif [[ "${node_health}" == "initializing" ]]; then
    echo "Node is initializing or loading."
  elif [[ "${node_health}" == "stopped" ]]; then
    echo "Node stopped or turned off."
    if [[ "$ALARM" -eq 0 ]]; then
      curl -s -X POST "$URL" -d chat_id="$CHAT_ID" -d text="$message1" -d parse_mode="HTML"
      ALARM=1
    fi
  elif [[ "${node_health}" == *"error"* ]]; then
    echo "An error occurred with the node."
    if [[ "$ALARM" -eq 0 ]]; then
      curl -s -X POST "$URL" -d chat_id="$CHAT_ID" -d text="$message2" -d parse_mode="HTML"
      ALARM=1
    fi
  else
    echo "Unknown node status: ${response}"
    if [[ "$ALARM" -eq 0 ]]; then
      curl -s -X POST "$URL" -d chat_id="$CHAT_ID" -d text="$message3" -d parse_mode="HTML"
      ALARM=1
    fi
  fi
  sleep 300
  echo "----------------------------------------"
done
