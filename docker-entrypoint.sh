#!/bin/sh

# Exit on any script failures
set -e -o pipefail

if [ "$ENTRYDEBUG" == "TRUE" ]; then
  # Print shell input lines as they are read
  set -v
fi

SOCAT_ARGS="${SOCAT_ARGS:-"-d"}"

# Ensure the ppp device exists
[ -c /dev/ppp ] || su-exec root mknod /dev/ppp c 108 0

# Reads environment variables and prints the values that match a special regex
# string
get_port_forwards_raw() {
  # Generate regex search string
  local r="^"                              # Required start of variable name
  r="${r}(PORT_FORWARD|REMOTE_ADDR)[^=]*=" # Required variable name
  r="${r}((tcp|udp):)?"                    # Optional tcp or udp
  r="${r}(([0-9]{1,5}):)?"                 # Optional LOCAL_PORT
  r="${r}[a-zA-Z0-9.-]+"                   # Required REMOTE_HOST (ip or hostname)
  r="${r}:[0-9]{1,5}"                      # Required REMOTE_PORT
  r="${r}$"                                # Required end of variable contents

  env | awk -F= -v pattern="$r" '$0 ~ pattern { print $2 }'
}

# Outputs 4 fields related to port forwarding:
#   1. Protocol
#   2. Local port
#   3. Remote host
#   4. Remote port
get_port_forwards_sane() {
  get_port_forwards_raw | awk -F: '{
    if (NF == 4) {
      print $1" "$2" "$3" "$4
    } else if (NF == 3) {
      print "TCP "$1" "$2" "$3
    } else if (NF == 2) {
      print "TCP 1111 "$1" "$2
    }
  }'
}

# Starts a port-forwarding executable in the background
daemonize_port_forward() {
  local protocol="$1"
  local local_port="$2"
  local remote_host="$3"
  local remote_port="$4"

  socat $SOCAT_ARGS \
    "${protocol}-LISTEN:${local_port},fork,reuseaddr" \
    "${protocol}:"${remote_host}":"${remote_port} &
}

# Start all port-forwarding services
start_port_forwarding() {
  get_port_forwards_sane | while IFS= read -r line; do
    # Set IFS to default whitespace characters. Then split the 'line' variable
    # into positional parameters ($1, $2, $3, $4). Finally, restore the original
    # IFS value
    old_ifs="$IFS"
    IFS=$' \t\n'
    set -- $line
    IFS="$old_ifs"

    daemonize_port_forward "$1" "$2" "$3" "$4"
  done
}

# Remove possible stutter
if [ "$1" = "openfortivpn" ]; then
  shift
fi

start_port_forwarding

exec openfortivpn "$@"
