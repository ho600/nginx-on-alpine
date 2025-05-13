FROM python:3.12-alpine

LABEL maintainer="Amon Ho <hoamon@ho600.com>"

COPY install-nginx-alpine.sh /

RUN sh /install-nginx-alpine.sh

WORKDIR /