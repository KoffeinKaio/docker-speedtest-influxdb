FROM --platform=linux/arm32/v7 golang:alpine AS build-env

# Set go bin which doesn't appear to be set already.
ENV GOBIN /go/bin

RUN apk update && apk upgrade && \
apk add --no-cache bash git openssh

# Add QEMU
# Download QEMU, see https://github.com/docker/hub-feedback/issues/1261
ENV QEMU_URL https://github.com/balena-io/qemu/releases/download/v3.0.0%2Bresin/qemu-3.0.0+resin-arm.tar.gz
RUN apk add curl && curl -L ${QEMU_URL} | tar zxvf - -C /usr/bin --strip-components 1

# build directories
ADD . /go/src/quadstingray/speedtest-influxdb
WORKDIR /go/src/quadstingray/speedtest-influxdb

# Go dep!
RUN go get -u github.com/golang/dep/...
RUN dep ensure

# Build my app
RUN go build -o speedtestInfluxDB *.go

# final stage
FROM alpine
WORKDIR /app

MAINTAINER QuadStingray <docker-speedtest@quadstingray.com>

ENV INTERVAL=3600 \
    INFLUXDB_USE="true" \
    INFLUXDB_DB="speedtest" \
    INFLUXDB_URL="http://influxdb:8086" \
    INFLUXDB_USER="DEFAULT" \
    INFLUXDB_PWD="DEFAULT" \
    HOST="local" \
    SPEEDTEST_SERVER="" \
    SPEEDTEST_LIST_SERVERS="false" \
    SPEEDTEST_LIST_KEEP_CONTAINER_RUNNING="false" \
    SPEEDTEST_ALGO_TYPE="max" \
    SHOW_EXTERNAL_IP="false"

RUN apk add ca-certificates
COPY --from=build-env /go/src/quadstingray/speedtest-influxdb/speedtestInfluxDB /app/speedtestInfluxDB
ADD run.sh run.sh
CMD sh run.sh
