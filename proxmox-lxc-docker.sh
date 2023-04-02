#!/usr/bin/env bas h
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
APP="Docker"
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
    read -p "This will create a New ${APP} LXC. Proceed(y/n)?" yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done
clear
function header_info {
echo -e "${BLUE}
  _____             _             
 |  __ \           | |            
 | |  | | ___   ___| | _____ _ __ 
 | |  | |/ _ \ / __| |/ / _ \  __|
 | |__| | (_) | (__|   <  __/ |   
 |_____/ \___/ \___|_|\_\___|_|   
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

function default_settings() {
        clear
        header_info
        echo -e "${BLUE}Using Default Settings${NORMAL}"
        echo -e "${DGN}Using CT Type ${BGN}Unprivileged${NORMAL} ${RED}NO DEVICE PASSTHROUGH${NORMAL}"
        CT_TYPE="1"
        echo -e "${DGN}Using CT Password ${BGN}Automatic Login${NORMAL}"
        PW=" "
        echo -e "${DGN}Using CT ID ${BGN}$NEXTID${NORMAL}"
        CT_ID=$NEXTID
        echo -e "${DGN}Using CT Name ${BGN}$NSAPP${NORMAL}"
        HN=$NSAPP
        echo -e "${DGN}Using Disk Size ${BGN}8${NORMAL}${DGN} GB${NORMAL}"
        DISK_SIZE="8"
        echo -e "${DGN}Using ${BGN}2${NORMAL}${DGN} vCPU${NORMAL}"
        CORE_COUNT="2"
        echo -e "${DGN}Using ${BGN}2048${NORMAL}${DGN} MiB RAM${NORMAL}"
        RAM_SIZE="2048"
        echo -e "${DGN}Using Bridge ${BGN}vmbr0${NORMAL}"
        BRG="vmbr0"
        echo -e "${DGN}Using Static IP Address ${BGN}DHCP${NORMAL}"
        NET=dhcp
        echo -e "${DGN}Using Gateway Address ${BGN}NONE${NORMAL}"
        GATE=""
        echo -e "${DGN}Using VLAN Tag ${BGN}NONE${NORMAL}"
        VLAN=""
}

function advanced_settings() {
        clear
        header_info
        echo -e "${RED}Using Advanced Settings${NORMAL}"
        echo -e "${YELLOW}Type Privileged, or Press [ENTER] for Default: Unprivileged (${RED}NO DEVICE PASSTHROUGH${NORMAL}${YELLOW})"
        read CT_TYPE1
        if [ -z $CT_TYPE1 ]; then CT_TYPE1="Unprivileged" CT_TYPE="1"; 
        echo -en "${DGN}Set CT Type ${BLUE}$CT_TYPE1${NORMAL}"
        else
        CT_TYPE1="Privileged"
        CT_TYPE="0"
        echo -en "${DGN}Set CT Type ${BLUE}Privileged${NORMAL}"  
        fi;
        echo -e " ${CM}${NORMAL} \r"
        sleep 1
        clear
        header_info
        echo -e "${RED}Using Advanced Settings${NORMAL}"
        echo -e "${DGN}Using CT Type ${BGN}$CT_TYPE1${NORMAL}"
        echo -e "${YELLOW}Set Password, or Press [ENTER] for Default: Automatic Login "
        read PW1
        if [ -z $PW1 ]; then PW1="Automatic Login" PW=" "; 
        echo -en "${DGN}Set CT ${BLUE}$PW1${NORMAL}"
        else
          PW="-password $PW1"
        echo -en "${DGN}Set CT Password ${BLUE}$PW1${NORMAL}"
        fi;
        echo -e " ${CM}${NORMAL} \r"
        sleep 1
        clear
        header_info
        echo -e "${RED}Using Advanced Settings${NORMAL}"
        echo -e "${DGN}Using CT Type ${BGN}$CT_TYPE1${NORMAL}"
        echo -e "${DGN}Using CT Password ${BGN}$PW1${NORMAL}"
        echo -e "${YELLOW}Enter the CT ID, or Press [ENTER] to automatically generate (${NEXTID}) "
        read CT_ID
        if [ -z $CT_ID ]; then CT_ID=$NEXTID; fi;
        echo -en "${DGN}Set CT ID To ${BLUE}$CT_ID${NORMAL}"
        echo -e " ${CM}${NORMAL} \r"
        sleep 1
        clear
        header_info
        echo -e "${RED}Using Advanced Settings${NORMAL}"
        echo -e "${DGN}Using CT Type ${BGN}$CT_TYPE1${NORMAL}"
        echo -e "${DGN}Using CT Password ${BGN}$PW1${NORMAL}"
        echo -e "${DGN}Using CT ID ${BGN}$CT_ID${NORMAL}"
        echo -e "${YELLOW}Enter CT Name (no-spaces), or Press [ENTER] for Default: $NSAPP "
        read CT_NAME
        if [ -z $CT_NAME ]; then
           HN=$NSAPP
        else
           HN=$(echo ${CT_NAME,,} | tr -d ' ')
        fi
        echo -en "${DGN}Set CT Name To ${BLUE}$HN${NORMAL}"
        echo -e " ${CM}${NORMAL} \r"
        sleep 1
        clear
        header_info
        echo -e "${RED}Using Advanced Settings${NORMAL}"
        echo -e "${DGN}Using CT Type ${BGN}$CT_TYPE1${NORMAL}"
        echo -e "${DGN}Using CT Password ${BGN}$PW1${NORMAL}"
        echo -e "${DGN}Using CT ID ${BGN}$CT_ID${NORMAL}"
        echo -e "${DGN}Using CT Name ${BGN}$HN${NORMAL}"
        echo -e "${YELLOW}Enter a Disk Size, or Press [ENTER] for Default: 8 "
        read DISK_SIZE
        if [ -z $DISK_SIZE ]; then DISK_SIZE="8"; fi;
        if ! [[ $DISK_SIZE =~ $INTEGER ]] ; then echo "ERROR! DISK SIZE MUST HAVE INTEGER NUMBER!"; exit; fi;
        echo -en "${DGN}Set Disk Size To ${BLUE}$DISK_SIZE${NORMAL} ${DGN}GB${NORMAL}"
        echo -e " ${CM}${NORMAL} \r"
        sleep 1
        clear
        header_info
        echo -e "${RED}Using Advanced Settings${NORMAL}"
        echo -e "${DGN}Using CT Type ${BGN}$CT_TYPE1${NORMAL}"
        echo -e "${DGN}Using CT Password ${BGN}$PW1${NORMAL}"
        echo -e "${DGN}Using CT ID ${BGN}$CT_ID${NORMAL}"
        echo -e "${DGN}Using CT Name ${BGN}$HN${NORMAL}"
        echo -e "${DGN}Using Disk Size ${BGN}$DISK_SIZE${NORMAL} ${DGN}GB${NORMAL}"
        echo -e "${YELLOW}Allocate CPU cores, or Press [ENTER] for Default: 2 "
        read CORE_COUNT
        if [ -z $CORE_COUNT ]; then CORE_COUNT="2"; fi;
        echo -en "${DGN}Set Cores To ${BLUE}$CORE_COUNT${NORMAL} ${DGN}vCPU${NORMAL}"
        echo -e " ${CM}${NORMAL} \r"
        sleep 1
        clear
        header_info
        echo -e "${RED}Using Advanced Settings${NORMAL}"
        echo -e "${DGN}Using CT Type ${BGN}$CT_TYPE1${NORMAL}"
        echo -e "${DGN}Using CT Password ${BGN}$PW1${NORMAL}"
        echo -e "${DGN}Using CT ID ${BGN}$CT_ID${NORMAL}"
        echo -e "${DGN}Using CT Name ${BGN}$HN${NORMAL}"
        echo -e "${DGN}Using Disk Size ${BGN}$DISK_SIZE${NORMAL} ${DGN}GB${NORMAL}"
        echo -e "${DGN}Using ${BGN}${CORE_COUNT}${NORMAL} ${DGN}vCPU${NORMAL}"
        echo -e "${YELLOW}Allocate RAM in MiB, or Press [ENTER] for Default: 2048 "
        read RAM_SIZE
        if [ -z $RAM_SIZE ]; then RAM_SIZE="2048"; fi;
        echo -en "${DGN}Set RAM To ${BLUE}$RAM_SIZE${NORMAL} ${DGN}MiB RAM${NORMAL}"
        echo -e " ${CM}${NORMAL} \n"
        sleep 1
        clear
        header_info
        echo -e "${RED}Using Advanced Settings${NORMAL}"
        echo -e "${DGN}Using CT Type ${BGN}$CT_TYPE1${NORMAL}"
        echo -e "${DGN}Using CT Password ${BGN}$PW1${NORMAL}"
        echo -e "${DGN}Using CT ID ${BGN}$CT_ID${NORMAL}"
        echo -e "${DGN}Using CT Name ${BGN}$HN${NORMAL}"
        echo -e "${DGN}Using Disk Size ${BGN}$DISK_SIZE${NORMAL} ${DGN}GB${NORMAL}"
        echo -e "${DGN}Using ${BGN}${CORE_COUNT}${NORMAL} ${DGN}vCPU${NORMAL}"
        echo -e "${DGN}Using ${BGN}${RAM_SIZE}${NORMAL} ${DGN}MiB RAM${NORMAL}"
        echo -e "${YELLOW}Enter a Bridge, or Press [ENTER] for Default: vmbr0 "
        read BRG
        if [ -z $BRG ]; then BRG="vmbr0"; fi;
        echo -en "${DGN}Set Bridge To ${BLUE}$BRG${NORMAL}"
        echo -e " ${CM}${NORMAL} \n"
        sleep 1
        clear
        header_info
        echo -e "${RED}Using Advanced Settings${NORMAL}"
        echo -e "${DGN}Using CT Type ${BGN}$CT_TYPE1${NORMAL}"
        echo -e "${DGN}Using CT Password ${BGN}$PW1${NORMAL}"
        echo -e "${DGN}Using CT ID ${BGN}$CT_ID${NORMAL}"
        echo -e "${DGN}Using CT Name ${BGN}$HN${NORMAL}"
        echo -e "${DGN}Using Disk Size ${BGN}$DISK_SIZE${NORMAL} ${DGN}GB${NORMAL}"
        echo -e "${DGN}Using ${BGN}${CORE_COUNT}${NORMAL} ${DGN}vCPU${NORMAL}"
        echo -e "${DGN}Using ${BGN}${RAM_SIZE}${NORMAL} ${DGN}MiB RAM${NORMAL}"
        echo -e "${DGN}Using Bridge ${BGN}${BRG}${NORMAL}"
        echo -e "${YELLOW}Enter a Static IPv4 CIDR Address, or Press [ENTER] for Default: DHCP "
        read NET
        if [ -z $NET ]; then NET="dhcp"; fi;
        echo -en "${DGN}Set Static IP Address To ${BLUE}$NET${NORMAL}"
        echo -e " ${CM}${NORMAL} \n"
        sleep 1
        clear
        header_info
        echo -e "${RED}Using Advanced Settings${NORMAL}"
        echo -e "${DGN}Using CT Type ${BGN}$CT_TYPE1${NORMAL}"
        echo -e "${DGN}Using CT Password ${BGN}$PW1${NORMAL}"
        echo -e "${DGN}Using CT ID ${BGN}$CT_ID${NORMAL}"
        echo -e "${DGN}Using CT Name ${BGN}$HN${NORMAL}"
        echo -e "${DGN}Using Disk Size ${BGN}$DISK_SIZE${NORMAL} ${DGN}GB${NORMAL}"
        echo -e "${DGN}Using ${BGN}${CORE_COUNT}${NORMAL} ${DGN}vCPU${NORMAL}"
        echo -e "${DGN}Using ${BGN}${RAM_SIZE}${NORMAL} ${DGN}MiB RAM${NORMAL}"
        echo -e "${DGN}Using Bridge ${BGN}${BRG}${NORMAL}"
        echo -e "${DGN}Using Static IP Address ${BGN}$NET${NORMAL}"
        echo -e "${YELLOW}Enter a Gateway IP (mandatory if static IP is used), or Press [ENTER] for Default: NONE "
        read GATE1
        if [ -z $GATE1 ]; then GATE1="NONE" GATE=""; 
        echo -en "${DGN}Set Gateway IP To ${BLUE}$GATE1${NORMAL}"
        else
          GATE=",gw=$GATE1"
        echo -en "${DGN}Set Gateway IP To ${BLUE}$GATE1${NORMAL}"
        fi;
        echo -e " ${CM}${NORMAL} \n"
        sleep 1
        clear
        header_info

        echo -e "${RED}Using Advanced Settings${NORMAL}"
        echo -e "${DGN}Using CT Type ${BGN}$CT_TYPE1${NORMAL}"
        echo -e "${DGN}Using CT Password ${BGN}$PW1${NORMAL}"
        echo -e "${DGN}Using CT ID ${BGN}$CT_ID${NORMAL}"
        echo -e "${DGN}Using CT Name ${BGN}$HN${NORMAL}"
        echo -e "${DGN}Using Disk Size ${BGN}$DISK_SIZE${NORMAL} ${DGN}GB${NORMAL}"
        echo -e "${DGN}Using ${BGN}${CORE_COUNT}${NORMAL} ${DGN}vCPU${NORMAL}"
        echo -e "${DGN}Using ${BGN}${RAM_SIZE}${NORMAL} ${DGN}MiB RAM${NORMAL}"
        echo -e "${DGN}Using Bridge ${BGN}${BRG}${NORMAL}"
        echo -e "${DGN}Using Static IP Address ${BGN}$NET${NORMAL}"
        echo -e "${DGN}Using Gateway IP Address ${BGN}$GATE1${NORMAL}"
        echo -e "${YELLOW}Enter a VLAN Tag, or Press [ENTER] for Default: NONE "
        read VLAN1
        if [ -z $VLAN1 ]; then VLAN1="NONE" VLAN=""; 
        echo -en "${DGN}Set VLAN Tag To ${BLUE}$VLAN1${NORMAL}"
        else
          VLAN=",tag=$VLAN1"
        echo -en "${DGN}Set VLAN Tag To ${BLUE}$VLAN1${NORMAL}"
        fi;
        echo -e " ${CM}${NORMAL} \n"
        sleep 1
        clear
        header_info
        echo -e "${RED}Using Advanced Settings${NORMAL}"
        echo -e "${DGN}Using CT Type ${BGN}$CT_TYPE1${NORMAL}"
        echo -e "${DGN}Using CT Password ${BGN}$PW1${NORMAL}"
        echo -e "${DGN}Using CT ID ${BGN}$CT_ID${NORMAL}"
        echo -e "${DGN}Using CT Name ${BGN}$HN${NORMAL}"
        echo -e "${DGN}Using Disk Size ${BGN}$DISK_SIZE${NORMAL} ${DGN}GB${NORMAL}"
        echo -e "${DGN}Using ${BGN}${CORE_COUNT}${NORMAL} ${DGN}vCPU${NORMAL}"
        echo -e "${DGN}Using ${BGN}${RAM_SIZE}${NORMAL} ${DGN}MiB RAM${NORMAL}"
        echo -e "${DGN}Using Bridge ${BGN}${BRG}${NORMAL}"
        echo -e "${DGN}Using Static IP Address ${BGN}$NET${NORMAL}"
        echo -e "${DGN}Using Gateway IP Address ${BGN}$GATE1${NORMAL}"
        echo -e "${DGN}Using VLAN Tag ${BGN}$VLAN1${NORMAL}"

        read -p "Are these settings correct(y/n)? " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]
        then
          advanced_settings
        fi
}

function start_script() {
		echo -e "${YELLOW}Type Advanced, or Press [ENTER] for Default Settings "
		read SETTINGS
		if [ -z $SETTINGS ]; then default_settings; 
		else
		advanced_settings 
		fi;
}

PVE_CHECK
start_script

if [ "$CT_TYPE" == "1" ]; then 
 FEATURES="nesting=1,keyctl=1"
 else
 FEATURES="nesting=1"
 fi

TEMP_DIR=$(mktemp -d)
pushd $TEMP_DIR >/dev/null

export CTID=$CT_ID
export PCT_SECTION=turnkeylinux
export PCT_OSTYPE=debian-11-turnkey
export PCT_OSVERSION=core_17.1
export PCT_DISK_SIZE=$DISK_SIZE
export PCT_OPTIONS="
  -features $FEATURES
  -hostname $HN
  -net0 name=eth0,bridge=$BRG,ip=$NET$GATE$VLAN
  -onboot 1
  -cores $CORE_COUNT
  -memory $RAM_SIZE
  -unprivileged $CT_TYPE
  $PW
"
bash -c "$(wget -qLO - https://github.com/atlas34/proxmox/raw/main/proxmox-create-lxc.sh)" || exit

LXC_CONFIG=/etc/pve/lxc/${CTID}.conf
cat <<EOF >> $LXC_CONFIG
lxc.cgroup2.devices.allow: a
lxc.cap.drop:
EOF

msg_info "Starting LXC Container"
pct start $CTID
msg_ok "Started LXC Container"

lxc-attach -n $CTID -- bash -c "$(wget -qLO - https://github.com/atlas34/proxmox/raw/main/proxmox-docker-install.sh)" || exit

IP=$(pct exec $CTID ip a s dev eth0 | sed -n '/inet / s/\// /p' | awk '{print $2}')

pct set $CTID -description "# ${APP} LXC
### https://github.com/atlas34/proxmox"

msg_ok "Completed Successfully!\n"
echo -e "Portainer should be reachable by going to the following URL.
             ${BLUE}http://${IP}:9000${NORMAL}\n"


