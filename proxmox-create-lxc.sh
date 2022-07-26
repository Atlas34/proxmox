#!/usr/bin/env bash
YELLOW=`echo "\033[33m"`
BLUE=`echo "\033[36m"`
RED=`echo "\033[01;31m"`
GREEN=`echo "\033[1;92m"`
NORMAL=`echo "\033[m"`
CHECKMARK="${GREEN}✓${NORMAL}"
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
   echo -e "${BFR} ${CHECKMARK} ${GREEN}${msg}${NORMAL}"
}

function select_storage() {
  local CLASS=$1
  local CONTENT
  local CONTENT_LABEL
  case $CLASS in
    container) CONTENT='rootdir'; CONTENT_LABEL='Container';;
    template) CONTENT='vztmpl'; CONTENT_LABEL='Container template';;
    *) false || die "Invalid storage class.";;
  esac

  local -a MENU
  while read -r line; do
    local TAG=$(echo $line | awk '{print $1}')
    local TYPE=$(echo $line | awk '{printf "%-10s", $2}')
    local FREE=$(echo $line | numfmt --field 4-6 --from-unit=K --to=iec --format %.2f | awk '{printf( "%9sB", $6)}')
    local ITEM="  Type: $TYPE Free: $FREE "
    local OFFSET=2
    if [[ $((${#ITEM} + $OFFSET)) -gt ${MSG_MAX_LENGTH:-} ]]; then
      local MSG_MAX_LENGTH=$((${#ITEM} + $OFFSET))
    fi
    MENU+=( "$TAG" "$ITEM" "OFF" )
  done < <(pvesm status -content $CONTENT | awk 'NR>1')

  if [ $((${#MENU[@]}/3)) -eq 0 ]; then            
    echo -e "'$CONTENT_LABEL' needs to be selected for at least one storage location."
    die "Unable to detect valid storage location."
  elif [ $((${#MENU[@]}/3)) -eq 1 ]; then          
    printf ${MENU[0]}
  else                                             
    local STORAGE
    while [ -z "${STORAGE:+x}" ]; do              
      STORAGE=$(whiptail --title "Storage Pools" --radiolist \
      "Which storage pool you would like to use for the ${CONTENT_LABEL,,}?\n\n" \
      16 $(($MSG_MAX_LENGTH + 23)) 6 \
      "${MENU[@]}" 3>&1 1>&2 2>&3) || die "Menu aborted."
    done
    printf $STORAGE
  fi
}

[[ "${CTID:-}" ]] || die "You need to set 'CTID' variable."
[[ "${PCT_OSTYPE:-}" ]] || die "You need to set 'PCT_OSTYPE' variable."

[ "$CTID" -ge "100" ] || die "ID cannot be less than 100."

if pct status $CTID &>/dev/null; then
  echo -e "ID '$CTID' is already in use."
  unset CTID
  die "Cannot use ID that is already in use."
fi

TEMPLATE_STORAGE=$(select_storage template) || exit
msg_ok "Using ${BLUE}$TEMPLATE_STORAGE${NORMAL} ${GREEN}for Template Storage."

CONTAINER_STORAGE=$(select_storage container) || exit
msg_ok "Using ${BLUE}$CONTAINER_STORAGE${NORMAL} ${GREEN}for Container Storage."

msg_info "Updating LXC Template List"
pveam update >/dev/null
msg_ok "Updated LXC Template List"

TEMPLATE_SEARCH=${PCT_OSTYPE}-${PCT_OSVERSION:-}

if [ -z ${PCT_SECTION} ]
then
  PCT_SECTION=system
fi

mapfile -t TEMPLATES < <(pveam available -section ${PCT_SECTION} | sed -n "s/.*\($TEMPLATE_SEARCH.*\)/\1/p" | sort -t - -k 2 -V)
[ ${#TEMPLATES[@]} -gt 0 ] || die "Unable to find a template when searching for '$TEMPLATE_SEARCH'."
TEMPLATE="${TEMPLATES[-1]}"

if ! pveam list $TEMPLATE_STORAGE | grep -q $TEMPLATE; then
  msg_info "Downloading LXC Template"
  pveam download $TEMPLATE_STORAGE $TEMPLATE >/dev/null ||
    die "A problem occured while downloading the LXC template."
  msg_ok "Downloaded LXC Template"
fi

DEFAULT_PCT_OPTIONS=(
  -arch $(dpkg --print-architecture))
  
PCT_OPTIONS=( ${PCT_OPTIONS[@]:-${DEFAULT_PCT_OPTIONS[@]}} )
[[ " ${PCT_OPTIONS[@]} " =~ " -rootfs " ]] || PCT_OPTIONS+=( -rootfs $CONTAINER_STORAGE:${PCT_DISK_SIZE:-8} )

msg_info "Creating LXC Container"
pct create $CTID ${TEMPLATE_STORAGE}:vztmpl/${TEMPLATE} ${PCT_OPTIONS[@]} >/dev/null ||
  die "A problem occured while trying to create container."
msg_ok "LXC Container ${BLUE}$CTID${NORMAL} ${GREEN}was successfully created."


