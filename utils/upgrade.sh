#!/bin/bash
sudo -v
source <(curl -s https://raw.githubusercontent.com/itrocket-team/testnet_guides/main/utils/common.sh)

while getopts u:b:v:n:p:h:i:r: flag; do
  case "${flag}" in
  u) UPD_HEIGHT=$OPTARG ;;
  b) BINARY=$OPTARG ;;
  v) VERSION=$OPTARG ;;
  n) NEW_BIN_PATH=$OPTARG ;;
  p) PROJECT_NAME=$OPTARG ;;
  h) PROJECT_HOME=$OPTARG ;;
  i) CHAIN_ID=$OPTARG ;;
  r) PORT_RPC=$OPTARG ;;
  *) echo "WARN: unknown parameter: ${OPTARG}"
  esac
done

printLogo
echo -e "$PROJECT_NAME YOUR NODE WILL BE UPDATED AT BLOCK $GREEN $UPD_HEIGHT ${NC}"
echo -e "Don't kill the session with $RED CTRL+C ${NC} before update completed"
echo -e "if you want to disconnect the session use $GREEN CTRL+B D ${NC}"
sleep 2
for((;;)); do
  height=$(${BINARY} status |& jq -r .SyncInfo.latest_block_height)
    if ((height==$UPD_HEIGHT)); then
      sudo mv $NEW_BIN_PATH $(which $BINARY)
      sudo systemctl restart $BINARY
      echo -e "$GREEN restarting...${NC}"
      
    break
  else
      echo $height
  fi
  sleep 4
done
sleep 6000
tmux kill-session
