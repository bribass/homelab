#!/bin/bash

# Process command line options
if ! OPTS=$(getopt -o H:P:u:h -l host,port,user,help -n "$0" -- "$@"); then
  exit 1
fi
eval set -- "$OPTS"
PVE_HOST=""
PVE_PORT=8006
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
      echo "Usage: $0 [-H|--host HOST] [-P|--port PORT] [-u|--user USER] [-h|--help]"
      echo "Log in to a Proxmox PVE server and print curl options for authenticating with that session."
      echo ""
      echo "Options:"
      echo "  -H, --host HOST  Hostname of PVE server to log in to"
      echo "  -P, --port PORT  Port of PVE server to log in to (default 8006)"
      echo "  -u, --user USER  Username and realm (name@realm) to log in as"
      echo "  -h, --help       Display this help message"
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

if [ -z "$PVE_HOST" ]; then
  echo "$0: no host specified; aborting" >&2
  exit 1
fi
if [ -z "$PVE_USER" ]; then
  echo "$0: no user specified; aborting" >&2
  exit 1
fi

# Read in password
echo -n "Enter password for $PVE_USER: " >&2
read -rs PVE_PASS
echo "" >&2

# Get login ticket and CSRF token
RESPONSE=$(mktemp -u "${TMPDIR:-/tmp}/pve-XXXXXXXXXX.json")
# shellcheck disable=SC2064
trap "rm -f $RESPONSE" EXIT
PVE_URL_BASE="https://${PVE_HOST}:${PVE_PORT}/api2/json/"
curl -sk --data "username=${PVE_USER}" --data-urlencode "password=${PVE_PASS}" "${PVE_URL_BASE}access/ticket" >"${RESPONSE}"
LOGIN_TICKET=$(jq --raw-output .data.ticket "${RESPONSE}")
CSRF_TOKEN=$(jq --raw-output .data.CSRFPreventionToken "${RESPONSE}")

# Print the curl command line options
echo "--cookie PVEAuthCookie=${LOGIN_TICKET} --header \"CSRFPreventionToken: ${CSRF_TOKEN}\""
exit 0
