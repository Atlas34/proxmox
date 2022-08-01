#!/usr/bin/env bash
YELLOW=`echo "\033[33m"`
RED=`echo "\033[01;31m"`
BLUE=`echo "\033[36m"`
GREEN=`echo "\033[1;92m"`
NORMAL=`echo "\033[m"`
RETRY_NUM=10
RETRY_EVERY=3
NUM=$RETRY_NUM
CM="${GREEN}✓${NORMAL}"
CROSS="${RED}✗${NORMAL}"
BFR="\\r\\033[K"
HOLD="-"
set -o errexit
set -o errtrace
set -o nounset
set -o pipefail
shopt -s expand_aliases
alias die='EXIT=$? LINE=$LINENO error_exit'
trap die ERR

function error_exit() {
  trap - ERR
  local reason="Unknown failure occurred."
  local msg="${1:-$reason}"
  local flag="${RED}‼ ERROR ${NORMAL}$EXIT@$LINE"
  echo -e "$flag $msg" 1>&2
  exit $EXIT
}

function msg_info() {
    local msg="$1"
    echo -ne " ${HOLD} ${YELLOW}${msg}..."
}

function msg_ok() {
    local msg="$1"
    echo -e "${BFR} ${CM} ${GREEN}${msg}${NORMAL}"
}

get_latest_release() {
   curl -sL https://api.github.com/repos/$1/releases/latest | grep '"tag_name":' | cut -d'"' -f4
}

msg_info "Updating Container OS"
apt update &>/dev/null
apt-get -qqy upgrade &>/dev/null
msg_ok "Updated Container OS"

CORE_LATEST_VERSION=$(get_latest_release "home-assistant/core")

msg_info "Pulling Home Assistant $CORE_LATEST_VERSION Image"
docker pull homeassistant/home-assistant:stable &>/dev/null
msg_ok "Pulled Home Assistant $CORE_LATEST_VERSION Image"

msg_info "Installing Home Assistant $CORE_LATEST_VERSION"
docker volume create HomeAssistant_config >/dev/null
docker run -d \
  --name home_assistant \
  --privileged \
  --restart unless-stopped \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /dev:/dev \
  -v HomeAssistant_config:/config \
  -v /etc/localtime:/etc/localtime:ro \
  --net=host \
  homeassistant/home-assistant:stable &>/dev/null
msg_ok "Installed Home Assistant $CORE_LATEST_VERSION"

mkdir /root/HomeAssistant_config

read -r -p "Would you like to add HACS (Home Assistant Community Store) ? <Y/n> " prompt
if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" || $prompt == "" ]]
then
HACS="Y"
else
HACS="N"
fi

if [[ $HACS == "Y" ]]
then
  msg_info "Installing HACS latest version"
  apt install unzip &>/dev/null
  wget -O - https://get.hacs.xyz | bash -
  msg_ok "Installed HACS completed"
fi

msg_info "Cleaning up"
apt-get autoremove >/dev/null
apt-get autoclean >/dev/null
rm -rf /var/{cache,log}/* /var/lib/apt/lists/*
msg_ok "Cleaned"

