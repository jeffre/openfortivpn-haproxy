# openfortivpn proxy
This docker image proxies a tcp port across a fortivpn gateway to remote 
address:port (`REMOTE_ADDR`) using 
[openfortivpn](https://github.com/adrienverge/openfortivpn) and 
[haproxy](https://www.haproxy.org/).


## Configuration
haproxy configuration is limited to one envrionment variable (`REMOTE_ADDR`)
which should contain a string of either IP:PORT or HOSTNAME:PORT (eg 
10.0.0.1:3389). Note: internal to the docker container, haproxy binds to port
1111.

openfortivpn configuration can be provided as arguments to this image, a 
mounted config file, or both.


## Examples

### Create a one-time use tunnel from your localhost through a fortinet vpn to a remote Windows RDP server
```
docker run --rm -it \
    --device=/dev/ppp \
    --cap-add=NET_ADMIN \
    -p "1111:1111" \
    -e REMOTE_ADDR="10.0.0.1:3389" \
    yoff/openfortivpn \
    fortinet.example.com:8443 \
    --username=foo \
    --password=bar \
    --otp=123456
```
Once connected, one would be able to use rdp://localhost:1111 to get logged in .


### Get a list of openfortivpn options:
```
$ docker run --rm yoff/openfortivpn -h
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
    -e REMOTE_ADDR="10.0.0.1:3389" \
    -v "${pwd}/config:/etc/openfortivpn/config" \
    yoff/openfortivpn
```


## Build
1. `git clone https://github.com/jeffre/openfortivpn`
2. `cd openfortivpn`
3. `docker build -t yoff/openfortivpn .`

