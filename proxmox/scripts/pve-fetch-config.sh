#!/bin/bash

BASE_DIR=$(dirname "$0")
# shellcheck disable=SC1091
source "${BASE_DIR}/pve-functions.sh"

if ! OPTS=$(getopt -o H:P:u:h -l host:,port:,user:,help -n "$0" -- "$@"); then
  exit 1
fi
eval set -- "$OPTS"
PVE_HOST=""
PVE_PORT="8006"
PVE_USER=""
while true; do
  case "$1" in
    -H | --host)
      PVE_HOST="$2"
      shift 2
      ;;
    -P | --port)
      PVE_PORT="$2"
      shift 2
      ;;
    -u | --user)
      PVE_USER="$2"
      shift 2
      ;;
    -h | --help)
      echo "Usage: $0 [-H|--host HOST] [-P|--port PORT] [-u|--user USER] [-h|--help] readme-directory"
      echo "Fetch the configuration of a VM or LXC container."
      echo ""
      echo "Required arguments:"
      echo "  readme-directory  directory containing README.md documentation file"
      echo "Options:"
      echo "  -H, --host HOST   Hostname of PVE server to log in to"
      echo "  -P, --port PORT   Port of PVE server to log in to (default 8006)"
      echo "  -u, --user USER   Username and realm (name@realm) to log in as"
      echo "  -h, --help        Display this help message"
      exit 0
      ;;
    --)
      shift
      break
      ;;
    *)
      echo "$0: internal error while processing command line" >&2
      exit 1
      ;;
  esac
done
README_DIR=$1

if [ -z "$PVE_HOST" ]; then
  echo "$0: no host specified; aborting" >&2
  exit 1
fi
if [ -z "$PVE_USER" ]; then
  echo "$0: no user specified; aborting" >&2
  exit 1
fi
if [ -z "$README_DIR" ]; then
  echo "$0: no README directory specified; aborting" >&2
  exit 1
fi

# Check to make sure the README exists in the readme directory
README_FILE="$README_DIR/README.md"
if [ ! -f "$README_FILE" ]; then
  echo "$0: $README_FILE does not exist; aborting" >&2
  exit 1
fi

# Determine the VM/CT status and ID
if ID_LINE=$(grep "Proxmox ID" "$README_FILE"); then
  echo "$0: $README_FILE did not contain 'Proxmox ID' line; aborting" >&2
  exit 1
fi
ID_NUMBER="${ID_LINE//[^0-9]/}"
case "$ID_LINE" in
  *CT*)
    ID_CATEGORY=lxc
    ID_FILENAME=proxmox-pct.cfg
    ;;
  *VM*)
    ID_CATEGORY=qemu
    ID_FILENAME=proxmox-qm.cfg
    ;;
  *)
    echo "$0: $README_FILE did not declare Proxmox ID as either 'CT' or 'VM'; aborting" >&2
    exit 1
    ;;
esac

# PVE API URL
PVE_URL_BASE="https://${PVE_HOST}:${PVE_PORT}/api2/json/"

# Log in to PVE
pve_login "$PVE_HOST" "$PVE_PORT" "$PVE_USER" AUTH_OPTIONS

# Determine the node we have contacted
pve_this_node "$PVE_HOST" "$PVE_PORT" AUTH_OPTIONS PVE_NODE

# Pull the config from the server
RESPONSE=$(mktemp -u "${TMPDIR:-/tmp}/pve-XXXXXXXXXX.json")
# shellcheck disable=SC2064
trap "rm -f $RESPONSE" EXIT
curl -ks  "${AUTH_OPTIONS[@]}" "${PVE_URL_BASE}nodes/${PVE_NODE}/${ID_CATEGORY}/${ID_NUMBER}/config" >"$RESPONSE"
PVE_CFG_FILE="${README_DIR}/${ID_FILENAME}"
jq --raw-output '.data | del(.digest, .lxc) | to_entries | sort_by(.key)[] | "\(.key): \(.value)"' "$RESPONSE" >"$PVE_CFG_FILE"
jq --raw-output '.data.lxc | .[]? | "\(.[0]): \(.[1])"' "$RESPONSE" >>"$PVE_CFG_FILE"
