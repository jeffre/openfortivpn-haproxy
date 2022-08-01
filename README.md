# openfortivpn-haproxy
This docker image proxies tcp ports across a Fortinet VPN to remote host using
[openfortivpn](https://github.com/adrienverge/openfortivpn)
and ~~[haproxy](https://www.haproxy.org/)~~ 
[socat](http://www.dest-unreach.org/socat/).


# Create docker image
1. Clone this repository

        git clone https://github.com/jeffre/openfortivpn-haproxy

2. Build the image

        docker build ./openfortivpn-haproxy \
            -t "jeffre/openfortivpn-haproxy:latest"

    Alternatively, you may specify the openfortivpn version using `--build-arg`

        docker build ./openfortivpn-haproxy \
            -t "jeffre/openfortivpn-haproxy:v1.17.1" \
            --build-arg OPENFORTIVPN_VERSION=v1.17.1


# Deploy docker container

## Configure forwarded ports
To configure forwarded ports, use environment variables with names that start
with `PORT_FORWARD` and contain a special string (outlined below). More than
one port can be forwarded by using a unique variable name (`PORT_FORWARD1`,
`PORT_FORWARD2`, etc). The variable should contain a string that is formatted
like one of the following:
 * `REMOTE_HOST`:`REMOTE_PORT`
 * `LOCAL_PORT`:`REMOTE_HOST`:`REMOTE_PORT`
 * `PROTOCOL`:`LOCAL_PORT`:`REMOTE_HOST`:`REMOTE_PORT`

`REMOTE_HOST` is a public hostname or ip address (note that a current limitations prevents the hostname from being resolved within the VPN)  
`REMOTE_PORT` an integer between 1-65535  
`LOCAL_PORT` an integer between 1-65535. If omitted, port 1111 is used.  
`PROTOCOL` either tcp or udp. If omitted, tcp is used.


## Configure openfortivpn
Openfortivpn configuration can be provided as command-line arguments to this
image, as a mounted config file, or a combination of both. For details about
openfortivpn configuration run

    docker run --rm jeffre/openfortivpn-haproxy:latest -h


# Examples

### Expose a remote RDP server
```
docker run --rm -it \
    --device=/dev/ppp \
    --cap-add=NET_ADMIN \
    -p 127.0.0.1:3389:3389 \
    -e PORT_FORWARD="3389:10.0.0.1:3389" \
    jeffre/openfortivpn-haproxy:latest \
    fortinet.example.com:8443 \
    --username=foo \
    --password=bar \
    --otp=123456
```
Once connected, rdp://127.0.0.1 will be reachable.


## Expose 2 remote services (RDP, SSH)
```
docker run --rm -it \
    --device=/dev/ppp \
    --cap-add=NET_ADMIN \
    -p 127.0.0.1:3389:1111 \
    -e PORT_FORWARD1="1111:10.0.0.1:3389" \
    -p 127.0.0.1:2222:2222 \
    -e PORT_FORWARD2="2222:10.0.0.2:22" \
    jeffre/openfortivpn-haproxy:latest \
    fortinet.example.com:8443 \
    --username=foo \
    --password=bar \
    --otp=123456
```
Once connected, rdp://localhost:1111 and ssh://localhost:2222 will be 
reachable.


## Use both a config file and command-line parameters for openfortivpn

Contents of ./config:
```
host = fortinet.example.com
port = 8443
username = foo
password = bar
```

```
docker run --rm -it \
    --device=/dev/ppp \
    --cap-add=NET_ADMIN \
    -p "1111:1111" \
    -e PORT_FORWARD="1111:10.0.0.1:3389" \
    -v "$(pwd)/config:/etc/openfortivpn/config" \
    jeffre/openfortivpn-haproxy:latest \
    --otp=123456
```


# Running on MacOS
Since /dev/ppp does not exist on MacOS, we will not attempt to bring it in with
the `--device` flag. However, in order to create a ppp device inside the 
container, we will instead need the `--privileged` flag:
```
docker run --rm -it \
    --privileged \
    -p "1111:1111" \
    -e PORT_FORWARD="3389:10.0.0.1:3389" \
    jeffre/openfortivpn-haproxy:latest \
    fortinet.example.com:8443
```
