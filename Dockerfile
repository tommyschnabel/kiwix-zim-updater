FROM lscr.io/linuxserver/transmission:latest

RUN apk update && apk add grep wget

COPY kiwix-zim-updater.sh /
COPY root/ /
