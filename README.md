This container runs [openfortivpn](https://github.com/adrienverge/openfortivpn)
and allows you to access your remote network through a simple tcp proxy
provided by [haproxy](https://www.haproxy.org/).

You > Container:1111 > openfortivpn > REMOTE_ADDR

# Build
1. `git clone https://github.com/jeffre/docker-openfortivpn`
2. `cd docker-openfortivpn`
3. `docker build -t yoff/openfortivpn .`

# Run
openfortivpn can be configured by passing arguments to the container, by using
a config file, or both.

haproxy can be configured by settings the `REMOTE_ADDR` environment variable to
a single single destination "address:port".

Example using openfortivpn arguments:
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
To see all openfortivpn command-line options run
`docker run --rm yoff/openfortivpn -h`

Example using openfortivpn config file:


```
$ cat ./config
host = vpn-gateway
port = 8443
username = foo
password = bar
set-routes = 0
set-dns = 0
trusted-cert = e46d4aff08ba6914e64daa85bc6112a422fa7ce16631bff0b592a28556f993db
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
