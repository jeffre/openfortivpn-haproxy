# openfortivpn-haproxy

This docker image proxies traffic across a Fortinet VPN to remote host using
[openfortivpn](https://github.com/adrienverge/openfortivpn)
and ~~[haproxy](https://www.haproxy.org/)~~ 
[socat](http://www.dest-unreach.org/socat/).

## Create docker image

1. Clone this repository

    ```sh
    git clone https://github.com/jeffre/openfortivpn-haproxy
    ```

2. Build the image

    ```sh
    docker build ./openfortivpn-haproxy \
        -t "jeffre/openfortivpn-haproxy:latest"
    ```

    Alternatively, you may specify the openfortivpn version using `--build-arg`

    ```sh
    docker build ./openfortivpn-haproxy \
        -t "jeffre/openfortivpn-haproxy:v1.17.1" \
        --build-arg OPENFORTIVPN_VERSION=v1.17.1
    ```

## Deploy docker container

### Configure forwarded ports

To configure forwarded ports use environment variables with names that *start*
with `PORT_FORWARD` (eg `PORT_FORWARD_SSH`, `PORT_FORWARD_RDP`). Each must
contain a special string obeying one of the following syntaxes:

* `REMOTE_HOST`:`REMOTE_PORT`
* `LOCAL_PORT`:`REMOTE_HOST`:`REMOTE_PORT`
* `PROTOCOL`:`LOCAL_PORT`:`REMOTE_HOST`:`REMOTE_PORT`

| Variable      | Definition                   |
|---------------|------------------------------|
| `REMOTE_HOST` | Public hostname or ip address. Note: The hostname's dns will be resolved externally from the VPN. |
| `REMOTE_PORT` | integer between 1-65535. |
| `LOCAL_PORT`  | integer between 1-65535. If omitted, port 1111 is used. |
| `PROTOCOL`    | Either tcp (default) or udp |

### Configure openfortivpn

Openfortivpn configuration can be provided as command-line arguments to this
image, as a mounted config file, or a combination of both. For details about
openfortivpn configuration run:

```sh
docker run --rm jeffre/openfortivpn-haproxy -h
```

Some common command-line arguments for openfortivpn are:

* `--username=<user>`
* `--password=<password>` although better to omit this and you'll be prompted for it
* `--otp=<opt>` although also better to omit this and you'll be prompted for it
* `--realm=<realm>` if your server requires a realm, as seen as a path on the server URL

## Examples

### Expose a remote RDP service

```sh
docker run --rm -it \
    --device=/dev/ppp \
    --cap-add=NET_ADMIN \
    -p 127.0.0.1:3389:3389 \
    -e PORT_FORWARD="3389:10.0.0.1:3389" \
    jeffre/openfortivpn-haproxy:latest \
    fortinet.example.com:8443 \
    --username=foo \
    --password=bar
```

Once connected, `rdp://127.0.0.1` will be accessible.

### Expose 2 remote services (RDP, SSH)

```sh
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
    --password=bar
```

Once connected, `rdp://localhost:1111` and `ssh://localhost:2222` will both be
accessible.

### Use both a config file and command-line parameters for openfortivpn

Contents of `./config`:

```txt
host = fortinet.example.com
port = 8443
username = foo
password = bar
```

```sh
docker run --rm -it \
    --device=/dev/ppp \
    --cap-add=NET_ADMIN \
    -p "1111:1111" \
    -e PORT_FORWARD="1111:10.0.0.1:3389" \
    -v "$(pwd)/config:/etc/openfortivpn/config" \
    jeffre/openfortivpn-haproxy:latest
```

## Running on macOS

Since `/dev/ppp` does not exist on macOS, we will not attempt to bring it in with
the `--device` flag. However, in order to create a ppp device inside the
container, we will instead need the `--privileged` flag:

```sh
docker run --rm -it \
    --privileged \
    -p "1111:1111" \
    -e PORT_FORWARD="1111:10.0.0.1:3389" \
    jeffre/openfortivpn-haproxy:latest \
    fortinet.example.com:8443 \
    --username=foo
```
