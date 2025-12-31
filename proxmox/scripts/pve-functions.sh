# shellcheck shell=bash

# Log in to PVE and set an array with the curl options for authenticating with that session
# Arguments:
# - hostname of the PVE server
# - port of the PVE server
# - username and realm of the user to log in as
# - name of the array variable to assign the curl options to
function pve_login {
  local PVE_HOST="$1"
  local PVE_PORT="$2"
  local PVE_USER="$3"

  # Read in password
  echo -n "Enter password for $PVE_USER: " >&2
  read -rs PVE_PASS
  echo "" >&2

  # Get login ticket and CSRF token
  local RESPONSE
  RESPONSE=$(mktemp -u "${TMPDIR:-/tmp}/pve-XXXXXXXXXX.json")
  # shellcheck disable=SC2064
  trap "rm -f $RESPONSE" EXIT
  local PVE_URL_BASE="https://${PVE_HOST}:${PVE_PORT}/api2/json/"
  curl -sk --data "username=${PVE_USER}" --data-urlencode "password=${PVE_PASS}" "${PVE_URL_BASE}access/ticket" >"${RESPONSE}"
  local LOGIN_TICKET CSRF_TOKEN
  LOGIN_TICKET=$(jq --raw-output .data.ticket "${RESPONSE}")
  CSRF_TOKEN=$(jq --raw-output .data.CSRFPreventionToken "${RESPONSE}")

  # Set an array (from a nameref) containing the required curl options
  local -n PVE_AUTH=$4
  # shellcheck disable=SC2034
  PVE_AUTH=( "--cookie" "PVEAuthCookie=${LOGIN_TICKET}" "--header" "CSRFPreventionToken: ${CSRF_TOKEN}" )
}


# Show the task logs for a given PVE UPID identifier
# Arguments:
# - hostname of the PVE server
# - port of the PVE server
# - name of the array variable containing the authentication information
# - the node name on which the task was run
# - the UPID of the task to show
# - seconds to sleep between polls when determining completion status
function pve_upid_logs {
  local PVE_HOST="$1"
  local PVE_PORT="$2"
  # shellcheck disable=SC2178
  local -n PVE_AUTH=$3
  local PVE_NODE="$4"
  local PVE_UPID="$5"
  local PVE_POLL_SEC="$6"

  local PVE_URL_BASE="https://${PVE_HOST}:${PVE_PORT}/api2/json/"
  local STATUS

  # Poll to see when the task is complete
  while true; do
    sleep "${PVE_POLL_SEC}"
    STATUS=$(curl -sk "${PVE_AUTH[@]}" "${PVE_URL_BASE}nodes/${PVE_NODE}/tasks/${PVE_UPID}/status" | jq --raw-output .data.status)
    if [ "$STATUS" = "stopped" ]; then
      break
    fi
  done

  # Now retrieve the logs from the task
  curl -sk "${PVE_AUTH[@]}" "${PVE_URL_BASE}nodes/${PVE_NODE}/tasks/${PVE_UPID}/log" | jq --raw-output '.data[] | .t'
}
