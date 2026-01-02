#!/bin/bash

BASE_DIR=$(dirname "$0")
source "${BASE_DIR}/pve-functions.sh"

# Process command line options
if ! OPTS=$(getopt -o H:P:u:s:f:h -l host:,port:,user:,storage:,filename:,help -n "$0" -- "$@"); then
  exit 1
fi
eval set -- "$OPTS"
PVE_HOST=""
PVE_PORT="8006"
PVE_USER=""
PVE_STORAGE=""
PVE_FILENAME=""
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
    -s | --storage)
      PVE_STORAGE="$2"
      shift 2
      ;;
    -f | --filename)
      PVE_FILENAME="$2"
      shift 2
      ;;
    -h | --help)
      echo "Usage: $0 [-H|--host HOST] [-P|--port PORT] [-u|--user USER] [-s|--storage POOL] [-f|--filename NAME] [-h|--help] oci-image-ref"
      echo "Download an OCI image from a registry to a PVE storage pool."
      echo ""
      echo "Options:"
      echo "  -H, --host HOST      Hostname of PVE server to log in to"
      echo "  -P, --port PORT      Port of PVE server to log in to (default 8006)"
      echo "  -u, --user USER      Username and realm (name@realm) to log in as"
      echo "  -s, --storage POOL   PVE storage pool name to download image to"
      echo "  -f, --filename NAME  Set the filename (sans extension) of the template file on the PVE server"
      echo "  -h, --help           Display this help message"
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
OCI_IMAGE=$1

if [ -z "$PVE_HOST" ]; then
  echo "$0: no host specified; aborting" >&2
  exit 1
fi
if [ -z "$PVE_USER" ]; then
  echo "$0: no user specified; aborting" >&2
  exit 1
fi
if [ -z "$PVE_STORAGE" ]; then
  echo "$0: no storage pool specified; aborting" >&2
  exit 1
fi
if [ -z "$OCI_IMAGE" ]; then
  echo "$0: no OCI image reference specified; aborting" >&2
  exit 1
fi

# Log in to PVE
pve_login "$PVE_HOST" "$PVE_PORT" "$PVE_USER" AUTH_OPTIONS

# Determine the node we have contacted
PVE_URL_BASE="https://${PVE_HOST}:${PVE_PORT}/api2/json/"
PVE_NODE=$(curl -sk "${AUTH_OPTIONS[@]}" "${PVE_URL_BASE}cluster/status" | jq --raw-output '.data[] | select(.local==1) | .name')
if [ -z "$PVE_NODE" ]; then
  echo "$0: could not determine node name; aborting" >&2
  exit 1
fi

# Download the OCI image to the node
ADDITIONAL_OPTIONS=()
if [ -n "$PVE_FILENAME" ]; then
  ADDITIONAL_OPTIONS+=("--data-urlencode" "filename=${PVE_FILENAME}")
fi
UPID_PULL=$(curl -sk "${AUTH_OPTIONS[@]}" -X POST \
  --data-urlencode "reference=${OCI_IMAGE}" \
  "${ADDITIONAL_OPTIONS[@]}" \
  "${PVE_URL_BASE}nodes/${PVE_NODE}/storage/${PVE_STORAGE}/oci-registry-pull" | jq --raw-output .data)

# Display the log
pve_upid_logs "$PVE_HOST" "$PVE_PORT" AUTH_OPTIONS "$PVE_NODE" "$UPID_PULL" 1
