#!/bin/bash

## START OPTIONS
# Process command line options
if ! OPTS=$(getopt -o n:p:h -l name:,port:,help -n "$0" -- "$@"); then
  exit 1
fi
eval set -- "$OPTS"
OCI_CONTAINER_NAME="test"
EXPOSE_PORTS=()
while true; do
  case "$1" in
    -n | --name)
      OCI_CONTAINER_NAME="$2"
      shift 2
      ;;
    -p | --port)
      EXPOSE_PORTS+=("$2")
      shift 2
      ;;
    -h | --help)
      echo "Usage: $0 [-n|--name NAME] [-p|--port PORT] [-h|--help] oci-image-ref"
      echo "Start an OCI image as an Ansible testing container."
      echo ""
      echo "Required arguments:"
      echo "  oci-image-ref    OCI image reference to start"
      echo "Options:"
      echo "  -n, --name NAME  name of the container to create (default test)"
      echo "  -p, --port PORT  port to expose"
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
OCI_IMAGE=$1

if [ -z "$OCI_IMAGE" ]; then
  echo "$0: no OCI image reference specified; aborting" >&2
  exit 1
fi
## END OPTIONS

# Start the container image
ADDITIONAL_OPTIONS=()
for port in "${EXPOSE_PORTS[@]}"; do
  ADDITIONAL_OPTIONS+=("--publish" "$port:$port")
done
CONTAINER=$(podman run --detach --rm --name "${OCI_CONTAINER_NAME}" --volume "${PWD}:/homelab" --cap-add=CAP_SYS_ADMIN "${ADDITIONAL_OPTIONS[@]}" "${OCI_IMAGE}")
if [ -z "$CONTAINER" ]; then
  echo "$0: container did not start; aborting" >&2
  exit 1
fi

# Output attach command
echo "Test container started as ${CONTAINER:0:12}.  To connect to the container, run:"
echo ""
echo "  podman exec -it ${CONTAINER:0:12} bash"
echo ""
echo "To stop the container, run:"
echo ""
echo "  podman stop ${CONTAINER:0:12}"
echo ""
