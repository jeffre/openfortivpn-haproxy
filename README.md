This container does two things. First, it runs
[openfortivpn](https://github.com/adrienverge/openfortivpn) and connects to
your remote network. Second, it routes a local port to a remote address using
[haproxy](https://www.haproxy.org/) for a simple tcp proxy.

`yoff/openfortivpn:1111` > haproxy > openfortivpn > `REMOTE_ADDR`

Thus, supposing `REMOTE_ADDR` was set to `10.0.0.100:3389` and that was the
address of a window host inside a Fortinet firewall, one would be able to use
rdp://localhost:1111 to get logged in.


# Running
openfortivpn can be configured by passing arguments to the container, by using
a config file, or both.

haproxy can be configured by settings the `REMOTE_ADDR` environment variable to
a single single destination "address:port".

### yoff/openfortivpn with command line arguments:
```
docker run --rm -it \
    --device=/dev/ppp \
    --cap-add=NET_ADMIN \
    -p "1111:1111" \
    -e REMOTE_ADDR="10.0.0.1:22" \
    yoff/openfortivpn \
    fortinet.example.com:4443 \
    -u jeffre
```
To see all openfortivpn command-line options run `docker run --rm yoff/openfortivpn -h`


### yoff/openfortivpn with openfortivpn config file:

Contents of ./config:
```
host = vpn-gateway
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
    -e REMOTE_ADDR="10.0.0.1:22" \
    -v "${pwd}/config:/etc/openfortivpn/config" \
    yoff/openfortivpn
```


# Build
1. `git clone https://github.com/jeffre/docker-openfortivpn`
2. `cd docker-openfortivpn`
3. `docker build -t yoff/openfortivpn .`
