# openfortivpn-haproxy
This docker image proxies a tcp port across a Fortinet VPN to remote 
address:port (`REMOTE_ADDR`) using 
[openfortivpn](https://github.com/adrienverge/openfortivpn) and 
[haproxy](https://www.haproxy.org/).


## Create docker image
Clone this repository and then build the image

        git clone https://github.com/jeffre/openfortivpn-haproxy
        docker build openfortivpn-haproxy -t "jeffre/openfortivpn-haproxy:latest"


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
    jeffre/openfortivpn-haproxy \
    fortinet.example.com:8443 \
    --username=foo \
    --password=bar \
    --otp=123456
```
Once connected, one would be able to use rdp://localhost:1111 to get logged in .


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
    -e REMOTE_ADDR="10.0.0.1:3389" \
    -v "$(pwd)/config:/etc/openfortivpn/config" \
    jeffre/openfortivpn-haproxy
```

### Running on MacOS
Since /dev/ppp does not exist on MacOS, we will not attempt to bring it with 
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
