#!/bin/bash


# Exit on any script failures
set -e -o pipefail

ls /dev/ppp || su-exec root mknod /dev/ppp c 108 0

# Set default values
LOCAL_PORT=${LOCAL_PORT:-"1111"}
#REMOTE_ADDR=${REMOTE_ADDR:-"127.0.0.1:80"}


# Do not run haproxy without REMOTE_ADDR
if [[ ! -n "${REMOTE_ADDR}" ]]; then
  echo "Environment variable REMOTE_ADDR is not set."
else
  # Tweak haproxy config
  sed -i /etc/haproxy/haproxy.cfg \
      -e "s|bind 0\.0\.0\.0.*|bind 0.0.0.0:${LOCAL_PORT}|g" \
      -e "s|server srv1.*|server srv1 ${REMOTE_ADDR} maxconn 2048|g"
  # Run haproxy daemon
  exec su-exec root haproxy -f /etc/haproxy/haproxy.cfg &
fi


# Force all args into openfortivpn
if [[ "$1" = 'openfortivpn' ]]; then
  shift
fi

exec openfortivpn "$@"
