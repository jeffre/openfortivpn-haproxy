# openfortivpn-haproxy
This docker image proxies tcp ports across a Fortinet VPN to remote 
host using 
[openfortivpn](https://github.com/adrienverge/openfortivpn)
and 
[haproxy](https://www.haproxy.org/).


## Create docker image
1. Clone this repository

        git clone https://github.com/jeffre/openfortivpn-haproxy

2. Build the image

        docker build ./openfortivpn-haproxy \
            -t "jeffre/openfortivpn-haproxy:latest"

    Alternatively, you may specify the openfortivpn version using `--build-arg`

        docker build ./openfortivpn-haproxy \
            -t "jeffre/openfortivpn-haproxy:v1.17.1" \
            --build-arg OPENFORTIVPN_VERSION=v1.17.1


## Configure and deploy docker container
Proxied ports are configured by environment variables with names that start with
`REMOTE_ADDR` and contain a string that is formatted like so: 
`[LOCAL_PORT:]REMOTE_HOST:REMOTE_PORT`. If `LOCAL_PORT:` is omitted then port
1111 will be used.

Openfortivpn configuration can be provided as arguments to this image, a 
mounted config file, or both.


## Examples


### Create a one-time use tunnel to an RDP host
```
docker run --rm -it \
    --device=/dev/ppp \
    --cap-add=NET_ADMIN \
    -p 127.0.0.1:1111:1155 \
    -e REMOTE_ADDR="1155:10.0.0.1:3389" \
    jeffre/openfortivpn-haproxy \
    fortinet.example.com:8443 \
    --username=foo \
    --password=bar \
    --otp=123456
```
Once connected, one would be able to use rdp://127.0.0.1:1111 to get logged in.


### Create a long-running tunnel to both a RDP and SSH host
```
docker run -d \
    --device=/dev/ppp \
    --cap-add=NET_ADMIN \
    -p 127.0.0.1:3389:1111 \
    -e REMOTE_ADDR1="1111:10.0.0.1:3389" \
    -p 127.0.0.1:2222:2222 \
    -e REMOTE_ADDR2="2222:10.0.0.2:22" \
    jeffre/openfortivpn-haproxy \
    fortinet.example.com:8443 \
    --username=foo \
    --password=bar \
    --otp=123456
```
Once connected, one would be able to use rdp://localhost:1111 and `ssh -p 2222 localhost`


### Get a list of openfortivpn options:
```
$ docker run --rm jeffre/openfortivpn-haproxy -h
```


### Using a openfortivpn config file:

Contents of ./config:
```
host = fortinet.example.com
port = 8443
username = foo
password = bar
set-routes = 0
set-dns = 0
```

```
$ docker run --rm -it \
    --device=/dev/ppp \
    --cap-add=NET_ADMIN \
    -p "1111:1111" \
    -e REMOTE_ADDR="1111:10.0.0.1:3389" \
    -v "$(pwd)/config:/etc/openfortivpn/config" \
    jeffre/openfortivpn-haproxy
```


## Running on MacOS
Since /dev/ppp does not exist on MacOS, we will not attempt to bring it in with
the `--device` flag. However, in order to create a ppp device inside the 
container, we will instead need the `--privileged` flag:
```
docker run --rm -it \
    --privileged \
    -p "1111:1111" \
    -e REMOTE_ADDR="10.0.0.1:3389" \
    jeffre/openfortivpn-haproxy \
    fortinet.example.com:8443
```
