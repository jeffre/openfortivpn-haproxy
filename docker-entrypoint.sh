#!/bin/sh

# Exit on any script failures
set -e -o pipefail

# Ensure the ppp device exists
[ -c /dev/ppp ] || su-exec root mknod /dev/ppp c 108 0

# Generate regex search string
r="^"                       # Required start of variable name
r="${r}\(PORT_FORWARD\|REMOTE_ADDR\)[^=]*="  # Required variable name
r="${r}\(\(tcp\|udp\):\)\?"    # Optional tcp or udp
r="${r}\(\(\d\{1,5\}\):\)\?"   # Optional LOCAL_PORT
r="${r}[a-zA-Z0-9.-]\+"        # Required REMOTE_HOST (ip or hostname)
r="${r}:\d\{1,5\}"             # Required REMOTE_PORT
r="${r}$"                      # Required end of variabzle contents

# Create a space separated list of port forwards
forwards=$(
  env \
  | grep "${r}" \
  | cut -d= -f2-
)

# Iterate over all REMOTE_ADDR.* environment variables
for forward in ${forwards}; do

  # Replace colons with spaces add them into a bash array
  colons=$(echo "${forward}" | grep -o ':' | wc -l)

  if [ "${colons}" -eq "3" ]; then
    PROTOCOL=$(echo "forward" | cut -d: -f1)
    LOCAL_PORT=$(echo "forward" | cut -d: -f2)
    REMOTE_HOST=$(echo "forward" | cut -d: -f3)
    REMOTE_PORT=$(echo "forward" | cut -d: -f4)

  elif [ "${colons}" -eq "2" ]; then
    PROTOCOL="tcp"
    LOCAL_PORT=$(echo "forward" | cut -d: -f1)
    REMOTE_HOST=$(echo "forward" | cut -d: -f2)
    REMOTE_PORT=$(echo "forward" | cut -d: -f3)

  elif [ "${colons}" -eq "1" ]; then
    PROTOCOL="tcp"
    LOCAL_PORT="1111"
    REMOTE_HOST=$(echo "forward" | cut -d: -f3)
    REMOTE_PORT=$(echo "forward" | cut -d: -f4)

  else
    printf 'Unrecognized PORT_FORWARD(*) value: "%s"\n' "${address}" >&2
    exit 1
  fi

  # Background a socat processes for each port forward
  set -x
  socat ${PROTOCOL}-l:${LOCAL_PORT},fork,reuseaddr ${PROTOCOL}:${REMOTE_HOST}:${REMOTE_PORT} &
  { set +x; } 2>/dev/null

done


# Force all args into openfortivpn
if [ "$1" = "openfortivpn" ]; then
  shift
fi

exec openfortivpn "$@"
