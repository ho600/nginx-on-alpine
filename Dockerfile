FROM python:3.12-alpine

LABEL maintainer="Amon Ho <hoamon@ho600.com>"

COPY install-nginx-alpine.sh /

RUN sh /install-nginx-alpine.sh

RUN apk add openssl

RUN openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt -subj "/C=TW/ST=Taiwan/L=Nantou/O=ho600 Ltd./CN=localhost"

WORKDIR /