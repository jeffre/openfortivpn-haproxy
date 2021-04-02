FROM alpine as builder

ARG OPENFORTIVPN_VERSION=v1.16.0

RUN apk update \
    && apk upgrade \
    && apk add --no-cache \
        openssl-dev \
        ppp \
        ca-certificates \
        curl \
    && apk add --no-cache --virtual .build-deps \
        automake \
        autoconf \
        g++ \
        gcc \
        make \
    && mkdir -p "/usr/src/openfortivpn" \
    && cd "/usr/src/openfortivpn" \
    && curl -Ls https://github.com/adrienverge/openfortivpn/archive/${OPENFORTIVPN_VERSION}.tar.gz \
        | tar xz --strip-components 1 \
    && aclocal \
    && autoconf \
    && automake --add-missing \
    && ./configure --prefix=/usr --sysconfdir=/etc \
    && make \
    && make install \
    && apk del .build-deps

FROM alpine

RUN apk add --no-cache \
        ca-certificates \
        openssl \
        ppp \
        curl \
        su-exec \
        bash \
        haproxy \
    && rm -rf /var/cache/apk/*;

WORKDIR /

COPY --from=builder /usr/bin/openfortivpn /usr/bin/openfortivpn
COPY haproxy.cfg /etc/haproxy/haproxy.cfg
COPY docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["openfortivpn"]
