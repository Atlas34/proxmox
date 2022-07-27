#!/usr/bin/env bash
echo -e "Loading..."
NEXTID=$(pvesh get /cluster/nextid)
INTEGER='^[0-9]+$'
YELLOW=`echo "\033[33m"`
BLUE=`echo "\033[36m"`
RED=`echo "\033[01;31m"`
BGN=`echo "\033[4;92m"`
GREEN=`echo "\033[1;92m"`
DGN=`echo "\033[32m"`
NORMAL=`echo "\033[m"`
BFR="\\r\\033[K"
HOLD="-"
CM="${GREEN}✓${NORMAL}"
APP="Home Assistant"
NSAPP=$(echo ${APP,,} | tr -d ' ')
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

while true; do
    clear
    read -p "This will create a New ${APP} in a DOCKER LXC. Proceed(y/n)?" yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done
clear
function header_info {
echo -e "${BLUE}
  _                                        _     _              _   
 | |   ${YELLOW}  ${NORMAL}${BLUE}                                 (_)   | |            | |  
 | |__   ___  _ __ ___   ___  __ _ ___ ___ _ ___| |_ __ _ _ __ | |_ 
 |  _ \ / _ \|  _   _ \ / _ \/ _  / __/ __| / __| __/ _  |  _ \| __|
 | | | | (_) | | | | | |  __/ (_| \__ \__ \ \__ \ || (_| | | | | |_ 
 |_| |_|\___/|_| |_| |_|\___|\__,_|___/___/_|___/\__\__,_|_| |_|\__|
${NORMAL}"
}

header_info

function msg_info() {
    local msg="$1"
    echo -ne " ${HOLD} ${YELLOW}${msg}..."
}

function msg_ok() {
    local msg="$1"
    echo -e "${BFR} ${CM} ${GREEN}${msg}${NORMAL}"
}

function PVE_CHECK() {
    PVE=$(pveversion | grep "pve-manager/7" | wc -l)

    if [[ $PVE != 1 ]]; then
        echo -e "${RED}This script requires Proxmox Virtual Environment 7.0 or greater${NORMAL}"
        echo -e "Exiting..."
        sleep 2
        exit
    fi
}

function select_container() {
    clear
    header_info
    echo -e "${YELLOW}Enter the CT ID, or Press [ENTER] to automatically generate (${NEXTID}) "
    read CT_ID
    if [ -z $CT_ID ]; then CT_ID=$NEXTID; fi;
    echo -en "${DGN}Set CT ID To ${BLUE}$CT_ID${NORMAL}"
    echo -e " ${CM}${NORMAL} \r"

    read -p "Are these settings correct(y/n)? " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
      select_container
    fi
}

function start_script() {
  select_container 
}

PVE_CHECK
start_script

export CTID=$CT_ID

LXC_CONFIG=/etc/pve/lxc/${CTID}.conf
cat <<EOF >> $LXC_CONFIG
lxc.cgroup2.devices.allow: a
lxc.cap.drop:
EOF

msg_info "Starting LXC Container"
pct start $CTID
msg_ok "Started LXC Container"

lxc-attach -n $CTID -- bash -c "$(wget -qLO - https://raw.githubusercontent.com/atlas34/proxmox/proxmox-homeassistant-install.sh)" || exit

IP=$(pct exec $CTID ip a s dev eth0 | sed -n '/inet / s/\// /p' | awk '{print $2}')

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BLUE}http://${IP}:8123${NORMAL}

