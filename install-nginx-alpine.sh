#! /usr/bin/env sh

# From official Nginx Docker image, as a script to re-use it, removing internal comments

# Standard set up Nginx Alpine
# https://github.com/nginx/docker-nginx/blob/7f1d49f6f222f7e588a9066fd53a0ce43c3466a5/stable/alpine/Dockerfile

export NGINX_VERSION=1.28.0
export NJS_VERSION=0.8.10
export NJS_RELEASE=1
export PKG_RELEASE=1
export DYNPKG_RELEASE=1

set -x \
    && apkArch="$(cat /etc/apk/arch)" \
    && nginxPackages=" \
        nginx=${NGINX_VERSION}-r${PKG_RELEASE} \
        nginx-module-xslt=${NGINX_VERSION}-r${DYNPKG_RELEASE} \
        nginx-module-geoip=${NGINX_VERSION}-r${DYNPKG_RELEASE} \
        nginx-module-image-filter=${NGINX_VERSION}-r${DYNPKG_RELEASE} \
        nginx-module-njs=${NGINX_VERSION}.${NJS_VERSION}-r${NJS_RELEASE} \
    " \
    && apk add --no-cache --virtual .checksum-deps \
        openssl \
    && case "$apkArch" in \
        x86_64|aarch64) \
            apk add -X "https://nginx.org/packages/alpine/v$(egrep -o '^[0-9]+\.[0-9]+' /etc/alpine-release)/main" -u alpine-keys --allow-untrusted --no-cache $nginxPackages \
            ;; \
        *) \
            set -x \
            && tempDir="$(mktemp -d)" \
            && chown nobody:nobody $tempDir \
            && apk add --no-cache --virtual .build-deps \
                gcc \
                libc-dev \
                make \
                openssl-dev \
                pcre2-dev \
                zlib-dev \
                linux-headers \
                libxslt-dev \
                gd-dev \
                geoip-dev \
                libedit-dev \
                bash \
                alpine-sdk \
                findutils \
                curl \
            && su nobody -s /bin/sh -c " \
                export HOME=${tempDir} \
                && cd ${tempDir} \
                && curl -f -L -O https://github.com/nginx/pkg-oss/archive/${NGINX_VERSION}-${PKG_RELEASE}.tar.gz \
                && PKGOSSCHECKSUM=\"517bc18954ccf4efddd51986584ca1f37966833ad342a297e1fe58fd0faf14c5a4dabcb23519dca433878a2927a95d6bea05a6749ee2fa67a33bf24cdc41b1e4 *${NGINX_VERSION}-${PKG_RELEASE}.tar.gz\" \
                && if [ \"\$(openssl sha512 -r ${NGINX_VERSION}-${PKG_RELEASE}.tar.gz)\" = \"\$PKGOSSCHECKSUM\" ]; then \
                    echo \"pkg-oss tarball checksum verification succeeded!\"; \
                else \
                    echo \"pkg-oss tarball checksum verification failed!\"; \
                    exit 1; \
                fi \
                && tar xzvf ${NGINX_VERSION}-${PKG_RELEASE}.tar.gz \
                && cd pkg-oss-${NGINX_VERSION}-${PKG_RELEASE} \
                && cd alpine \
                && make module-geoip module-image-filter module-njs module-xslt \
                && apk index --allow-untrusted -o ${tempDir}/packages/alpine/${apkArch}/APKINDEX.tar.gz ${tempDir}/packages/alpine/${apkArch}/*.apk \
                && abuild-sign -k ${tempDir}/.abuild/abuild-key.rsa ${tempDir}/packages/alpine/${apkArch}/APKINDEX.tar.gz \
                " \
            && cp ${tempDir}/.abuild/abuild-key.rsa.pub /etc/apk/keys/ \
            && apk del --no-network .build-deps \
            && apk add -X ${tempDir}/packages/alpine/ --no-cache $nginxPackages \
            ;; \
    esac \
    && apk del --no-network .checksum-deps \
    && if [ -n "$tempDir" ]; then rm -rf "$tempDir"; fi \
    && if [ -f "/etc/apk/keys/abuild-key.rsa.pub" ]; then rm -f /etc/apk/keys/abuild-key.rsa.pub; fi \
    && apk add --no-cache curl ca-certificates

# Standard set up Nginx finished
