FROM ghcr.io/linuxserver/baseimage-alpine:3.22

RUN apk update && apk add grep wget

ENV ARGS=""
ENV DIR=""

COPY kiwix-zim-updater.sh /

ENTRYPOINT /kiwix-zim-updater.sh $ARGS $DIR
