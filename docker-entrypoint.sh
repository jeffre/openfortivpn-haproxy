#!/bin/bash

# Exit on any script failures
set -e -o pipefail

# Ensure the ppp device exists
[[ -c /dev/ppp ]] || su-exec root mknod /dev/ppp c 108 0

# Flush out any previous haproxy configurations
cat <<- EOF >> /etc/haproxy/haproxy.cfg
global
    user haproxy
    group haproxy
    daemon
    maxconn 4096
defaults
    mode    tcp
    balance leastconn
    timeout client      300ms
    timeout server      30000ms
    timeout tunnel      12h
    timeout connect     30000ms
    retries 3
EOF

# Iterate over all REMOTE_ADDR.* environment variables
for address in $(env | sed -n "s/^REMOTE_ADDR.*=//gp"); do

  addr_array=(${addr//:/,})

  if [ "${#addr_array[@]}" -eq "3"]; then
    LOCAL_PORT=${addr_array[0]}
    REMOTE_HOST=${addr_array[1]}
    REMOTE_PORT=${addr_array[2]}
  elif [ "${#addr_array[@]}" -eq "2"]; then
    # For legacy compatibilty
    LOCAL_PORT=1111
    REMOTE_HOST=${addr_array[0]}
    REMOTE_PORT=${addr_array[1]}
  else
    printf 'Unrecognized REMOTE_ADDR(*) value: "%s"\n' "${address}" >&2
    exit 1
  fi

  # Tweak haproxy config
  printf "%s\n" \
      "frontend fr_server${LOCAL_PORT}" \
      "    bind 0.0.0.0:${LOCAL_PORT}" \
      "    default_backend bk_server${LOCAL_PORT}" \
      "backend bk_server${LOCAL_PORT}" \
      "    server srv1 ${REMOTE_HOST}:${REMOTE_PORT} maxconn 2048" \
      >> /etc/haproxy/haproxy.cfg
done


# Check if REMOTE_ADDR* was used. If not, print warning and skip running 
# haproxy
if ! env | grep -q "^REMOTE_ADDR.*=.\+:\d\+"; then
  printf "REMOTE_ADDR* environment variable is not set. haproxy will not be started!\n" >&2
else
  # Run haproxy daemon
  exec su-exec root haproxy -f /etc/haproxy/haproxy.cfg &
fi


# Force all args into openfortivpn
if [[ "$1" = 'openfortivpn' ]]; then
  shift
fi

exec openfortivpn "$@"
