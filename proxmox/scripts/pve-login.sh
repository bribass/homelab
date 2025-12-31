#!/bin/bash

# Process command line options
if ! OPTS=$(getopt -o H:P:u:lh -l host:,port:,user:,line,help -n "$0" -- "$@"); then
  exit 1
fi
eval set -- "$OPTS"
PVE_HOST=""
PVE_PORT=8006
PVE_USER=""
LINE_ORIENTED="no"
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
    -l | --line)
      LINE_ORIENTED="yes"
      shift
      ;;
    -h | --help)
      echo "Usage: $0 [-H|--host HOST] [-P|--port PORT] [-u|--user USER] [-l|--line] [-h|--help]"
      echo "Log in to a Proxmox PVE server and print curl options for authenticating with that session."
      echo ""
      echo "Options:"
      echo "  -H, --host HOST  Hostname of PVE server to log in to"
      echo "  -P, --port PORT  Port of PVE server to log in to (default 8006)"
      echo "  -u, --user USER  Username and realm (name@realm) to log in as"
      echo "  -l, --line       Output curl options in a line-oriented way"
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

# Do the login
pve_login "$PVE_HOST" "$PVE_PORT" "$PVE_USER" AUTH_OPTIONS

# Print the curl command line options
if [ "$LINE_ORIENTED" = "yes" ]; then
  for i in "${AUTH_OPTIONS[@]}"; do
    echo "$i"
  done
else
  for i in "${AUTH_OPTIONS[@]}"; do
    if [[ "$i" =~ " " ]]; then
      echo -n "\"$i\" "
    else
      echo -n "$i "
    fi
  done
  echo ""
fi
exit 0
