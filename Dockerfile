FROM golang:1-alpine AS build

ARG VERSION="0.7.1"
ARG CHECKSUM="7dc4f876eaea92459d0c8beac71352d3ea24d1fa9dd4ff8b4a9fc46f84135549"

ADD https://github.com/prometheus/consul_exporter/archive/v$VERSION.tar.gz /tmp/consul_exporter.tar.gz

RUN [ "$(sha256sum /tmp/consul_exporter.tar.gz | awk '{print $1}')" = "$CHECKSUM" ] && \
    apk add ca-certificates curl make && \
    tar -C /tmp -xf /tmp/consul_exporter.tar.gz && \
    mkdir -p /go/src/github.com/prometheus && \
    mv /tmp/consul_exporter-$VERSION /go/src/github.com/prometheus/consul_exporter && \
    cd /go/src/github.com/prometheus/consul_exporter && \
      make build

RUN mkdir -p /rootfs/bin && \
      cp /go/src/github.com/prometheus/consul_exporter/consul_exporter /rootfs/bin/ && \
    mkdir -p /rootfs/etc && \
      echo "nogroup:*:10000:nobody" > /rootfs/etc/group && \
      echo "nobody:*:10000:10000:::" > /rootfs/etc/passwd && \
    mkdir -p /rootfs/etc/ssl/certs && \
      cp /etc/ssl/certs/ca-certificates.crt /rootfs/etc/ssl/certs/


FROM scratch

COPY --from=build --chown=10000:10000 /rootfs /

USER 10000:10000
EXPOSE 9107/tcp
ENTRYPOINT ["/bin/consul_exporter"]
