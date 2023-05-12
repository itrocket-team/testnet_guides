#!/bin/bash
source <(curl -s https://raw.githubusercontent.com/itrocket-team/testnet_guides/main/utils/common.sh)

while getopts u:v:n:i:b:h:p: flag; do
  case "${flag}" in
  u) UPD_HEIGHT=$OPTARG ;;
  v) VERSION=$OPTARG ;;
  n) CHAIN_NAME=$OPTARG ;;
  i) CHAIN_ID=$OPTARG ;;
  b) BINARY=$OPTARG ;;
  h) PROJECT_HOME=$OPTARG ;;
  p) PORT_RPC=$OPTARG ;;
  *) echo "WARN: unknown parameter: ${OPTARG}"
  esac
done

printLogo
sleep 3

echo -e "$GREEN NODE WILL BE UPDATED AT BLOCK: $HEIGHT TO $VERSION{NC}"
for((;;)); do
  elysd status
  height=$(${BINARY} status |& jq -r .SyncInfo.latest_block_height)
    if ((height==$UPD_HEIGHT)); then
      mv /home/elys/elys/build/elysd /home/elys/go/bin/elysd
    systemctl restart $BINARY
      echo restart
    break
  else
      echo $height
  fi
  sleep 5
done
sleep 600
#tmux kill-session
