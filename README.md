# nginx-on-alpine

build example:

    docker buildx build --platform linux/amd64,linux/arm64 -t ho600/nginx-on-alpine:python-3.12-XXX  --push .