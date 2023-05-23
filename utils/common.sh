GREEN="\e[1m\e[1;32m" # green color
RED="\e[1m\e[1;31m" # red color
NC="\e[0m"           # no color

function printLogo {
  bash <(curl -s https://raw.githubusercontent.com/itrocket-team/testnet_guides/main/utils/logo.sh)
}

function printLine {
  echo "------------------------------------------------------------------------------------"
}

function printGreen {
  echo -e "${GREEN}${1}${NC}"
}

function printRed {
  echo -e "${RED}${1}${NC}"
}
